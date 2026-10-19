#!/usr/bin/env bash
# Post-install for Arch Linux on the Acer Predator Helios (RTX 5070 Laptop, Intel hybrid graphics).
# Run as the normal user after archinstall (KDE + nvidia-open): bash ~/personal/ia/global/setup-arch.sh
# Safe to run again: every step skips what is already in place.
set -euo pipefail

PERSONAL_DIR="${PERSONAL_DIR:-$HOME/personal}"
GITHUB_USER="Andersonfrfilho"
OWN_REPOSITORIES=(ia transportada ativada battlada ada-technology adatechnology-packages financing-chatbot
  quickcart sakura-bot-oficial supermercado-noemia comandada comandada-docs)
HABBLAUD_REPOSITORY="https://github.com/marmottajr/habblaud.git"

PACMAN_PACKAGES=(
  base-devel git git-lfs github-cli jq ripgrep fd zsh curl wget unzip p7zip python python-pip
  nvidia-open nvidia-utils lib32-nvidia-utils nvidia-settings nvidia-prime cuda cudnn
  docker docker-compose docker-buildx nvidia-container-toolkit
  snapper snap-pac
  steam gamemode lib32-gamemode mangohud
  blender krita obs-studio
)
AUR_PACKAGES=(ollama-cuda visual-studio-code-bin google-chrome linuwu-sense-dkms)

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }

enable_multilib() {
  grep -q '^\[multilib\]' /etc/pacman.conf && return
  sudo sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
}

install_system_packages() {
  log "Pacotes do sistema (pacman)"
  enable_multilib
  sudo pacman -Syu --needed --noconfirm "${PACMAN_PACKAGES[@]}"
}

install_aur_packages() {
  log "Pacotes do AUR (paru)"
  if ! command -v paru >/dev/null; then
    local build_dir; build_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru-bin.git "$build_dir/paru-bin"
    (cd "$build_dir/paru-bin" && makepkg -si --noconfirm)
  fi
  # linuwu-sense replaces PredatorSense (fans, turbo, keyboard RGB); failure here must not stop the rest
  paru -S --needed --noconfirm "${AUR_PACKAGES[@]}" || echo "AVISO: algum pacote do AUR falhou; rode 'paru -S ${AUR_PACKAGES[*]}' de novo"
}

configure_services() {
  log "Serviços: Docker (com GPU), Ollama, snapshots"
  sudo systemctl enable --now docker ollama
  sudo usermod -aG docker "$USER"
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker
  sudo snapper -c root create-config / 2>/dev/null || true
  sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
}

install_developer_tools() {
  log "Node (nvm), Bun, Claude Code, rtk, Railway, graphify"
  if [ ! -d "$HOME/.nvm" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  fi
  export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"
  nvm install --lts && nvm alias default 'lts/*'
  command -v bun >/dev/null || curl -fsSL https://bun.sh/install | bash
  command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash
  command -v rtk >/dev/null || curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | bash
  command -v railway >/dev/null || npm install -g --allow-scripts=@railway/cli @railway/cli
  # skill use-railway e MCP do Railway ficam fora do repositório; exigem login interativo antes
  if railway whoami >/dev/null 2>&1; then
    railway setup agent
  else
    log "Railway sem login: rode 'railway login' e depois 'railway setup agent'"
  fi
  if [ ! -x "$HOME/.local/bin/graphify" ]; then
    python -m venv "$HOME/.local/share/graphify"
    "$HOME/.local/share/graphify/bin/pip" install graphifyy
    ln -sfn "$HOME/.local/share/graphify/bin/graphify" "$HOME/.local/bin/graphify"
  fi
}

configure_shell() {
  log "zsh, oh-my-zsh e aliases"
  [ -d "$HOME/.oh-my-zsh" ] || RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  local marker="# --- ia/global/setup-arch.sh ---"
  grep -qF "$marker" "$HOME/.zshrc" 2>/dev/null && return
  cat >> "$HOME/.zshrc" <<'EOF'
# --- ia/global/setup-arch.sh ---
export NVM_DIR="$HOME/.nvm"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
export BUN_INSTALL="$HOME/.bun"
export PATH="$HOME/.local/bin:$BUN_INSTALL/bin:$PATH"
alias ll='ls -lah'
alias gs='git status -sb'
alias p='cd ~/personal'
alias claude='claude --dangerously-skip-permissions --chrome'
EOF
  [ "$SHELL" = "$(command -v zsh)" ] || chsh -s "$(command -v zsh)"
}

require_github_access() {
  log "Acesso ao GitHub"
  if ! gh auth status >/dev/null 2>&1; then
    echo "Restaure ~/.ssh do backup (chmod 600 ~/.ssh/id_*) e rode: gh auth login"; exit 1
  fi
}

clone_repositories() {
  log "Projetos em $PERSONAL_DIR"
  mkdir -p "$PERSONAL_DIR"
  for repository in "${OWN_REPOSITORIES[@]}"; do
    local target="$PERSONAL_DIR/$repository"
    [ "$repository" = comandada ] && target="$PERSONAL_DIR/comandada/app"
    [ "$repository" = comandada-docs ] && target="$PERSONAL_DIR/comandada"
    [ -d "$target/.git" ] && continue
    mkdir -p "$(dirname "$target")"
    if [ "$repository" = comandada-docs ]; then
      git clone "git@github.com:$GITHUB_USER/$repository.git" "$target.tmp" && cp -rn "$target.tmp/." "$target/" && rm -rf "$target.tmp"
    else
      git clone "git@github.com:$GITHUB_USER/$repository.git" "$target"
    fi
  done
}

install_claude_config() {
  log "Regras, standards e settings do Claude (install.sh)"
  bash "$PERSONAL_DIR/ia/global/install.sh"
  claude plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode || true
  claude plugin install --scope user oh-my-claudecode || true
  claude plugin marketplace add giancarloerra/socraticode || true
  claude plugin install --scope user socraticode@socraticode || true
  "$HOME/.local/bin/graphify" install --platform claude || true
  git -C "$PERSONAL_DIR/ia" checkout -- global/CLAUDE.md
}

start_search_infrastructure() {
  log "SocratiCode: Qdrant na porta 16333 e modelo de embedding"
  sudo docker ps -a --format '{{.Names}}' | grep -qx socraticode-qdrant ||
    sudo docker run -d --name socraticode-qdrant --restart unless-stopped -p 16333:6333 -p 16334:6334 qdrant/qdrant
  ollama pull nomic-embed-text
}

install_habblaud() {
  log "Habblaud (escritório dos agentes em http://localhost:4747)"
  local target="$PERSONAL_DIR/habblaud"
  [ -d "$target/.git" ] || git clone "$HABBLAUD_REPOSITORY" "$target"
  (cd "$target" && npm ci && npm run docker:up && npm run mod:install)
}

main() {
  install_system_packages
  install_aur_packages
  configure_services
  install_developer_tools
  configure_shell
  require_github_access
  clone_repositories
  install_claude_config
  start_search_infrastructure
  install_habblaud
  log "Pronto. Reinicie (driver NVIDIA e grupo docker) e confira: nvidia-smi, docker ps, rtk gain, claude"
}

main "$@"
