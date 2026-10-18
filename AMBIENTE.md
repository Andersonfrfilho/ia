# Ambiente de trabalho com o Claude — guia de início

Guia para subir o ambiente e começar a usar o Claude Code nesta máquina. Levantado em 2026-10-12;
conferir o que mudar com `claude mcp list` e `~/.claude/settings.json`.

## 1. Pré-requisitos na máquina

| Item | Para quê | Conferir |
|---|---|---|
| Bun | runtime dos apps | `bun --version` |
| Node | ferramentas e MCPs | `node --version` |
| Docker Desktop | infra local dos projetos e Qdrant | `docker ps` |
| Ollama (nativo) | embeddings do SocratiCode | `brew services start ollama` |
| Railway CLI | deploy e infra | `railway whoami` |
| rtk | proxy que economiza tokens de CLI | `rtk gain` |

Se `rtk gain` falhar, pode haver o pacote errado (Rust Type Kit) instalado no lugar.

## 2. Subir a infra de busca (SocratiCode)

O índice semântico de código usa Qdrant e Ollama em modo `external` (o MCP não enxerga o `docker` no PATH).

```bash
brew services start ollama
ollama pull nomic-embed-text
docker start socraticode-qdrant
```

- Qdrant: container `socraticode-qdrant`, porta **16333** (não a 6333 padrão).
- Variáveis ficam no bloco `env` de `~/.claude/settings.json`. Mudança nelas só vale na próxima sessão.
- Primeira vez num projeto: pedir "indexe este projeto" (`codebase_index`). Depois, o Claude usa `codebase_search` antes de `Read`.
- Conferir a infra: `codebase_health` (Qdrant, Ollama e modelo de embedding). Em 2026-10-12 estava tudo OK.
- Ferramentas úteis: `codebase_search` (busca semântica), `codebase_symbol`/`codebase_symbols` (funções e tipos),
  `codebase_impact` (o que quebra se mudar X), `codebase_flow` (fluxo de execução), `codebase_graph_*`
  (dependências e ciclos), `codebase_status` e `codebase_update` (manter o índice em dia), `codebase_watch` (atualiza sozinho).
- Indexar envia o código ao provedor de embeddings; por isso o provedor é o Ollama local, nunca OpenAI/Google.

### Estado do índice em 2026-10-12

| Projeto | Último índice | Situação |
|---|---|---|
| `transportada` | 2026-10-11 | **incompleto** — rodar `codebase_index` para retomar |
| `financiamento-imobiliario-bot` | 2026-10-09 | **incompleto** — idem |
| `quickcart` | 2026-10-04 | **incompleto** — idem |
| `sakura-bot-oficial` | 2026-09-08 | completo, mas defasado |
| `adatechnology-packages` | 2026-08-01 | completo, mas defasado (tem 3 context artifacts) |
| `ada-technology` e demais | — | nunca indexados |

## 2b. Graphify (grafo de conhecimento)

Transforma código, docs e imagens num grafo navegável, com comunidades, nós centrais e trilha de auditoria.
Binário em `~/.local/bin/graphify`; skill em `~/.claude/skills/graphify`.

```text
/graphify                      # pipeline completo na pasta atual (gera HTML interativo)
/graphify <caminho>            # numa pasta específica
/graphify <caminho> --update   # só arquivos novos ou alterados
/graphify <caminho> --mode deep
```

- Saída em `graphify-out/` de cada projeto: HTML interativo, JSON para GraphRAG e `GRAPH_REPORT.md`.
- Já existe `graphify-out/` em `transportada`, `adatechnology-packages`, `adatechnology-packages-quick-replies`,
  `adatechnology-scheduling` e `ada-packages-older`.
- **Regra:** se o projeto tem `graphify-out/`, perguntas sobre arquitetura e relação entre arquivos começam
  pelo grafo, antes de abrir código.
- Graphify = visão estrutural e entre repositórios. SocratiCode = busca semântica e impacto de mudança. Um completa o outro.

## 2c. RTK (economia de tokens)

Proxy de CLI que filtra a saída de comandos de shell. Versão 0.33.1 em `~/.local/bin/rtk`.

- O hook `~/.claude/hooks/rtk-rewrite.sh` reescreve os comandos sozinho: `git status` vira `rtk git status`, sem custo extra.
- Meta-comandos que se usam direto: `rtk gain` (economia acumulada), `rtk gain --history`, `rtk discover`
  (comandos que escaparam do filtro) e `rtk proxy <cmd>` (comando cru, para depurar).
- Medido em 2026-10-12: 202.946 comandos, 148 milhões de tokens economizados (29,7%).
  Os maiores ganhos vêm de `rtk read`, `ps aux`, `ls` e `grep`.
- Se `rtk gain` falhar, o binário pode ser o pacote errado (Rust Type Kit). Conferir com `which rtk`.
- Atenção: a saída filtrada pode omitir linhas. Quando um resultado parecer incompleto, repetir com `rtk proxy`.

## 3. Onde ficam os projetos

Tudo em `~/Documents/personal/`, que já está em `permissions.additionalDirectories`.

**Principais:** `sakura-bot-oficial`, `transportada`, `financiamento-imobiliario-bot`, `ada-technology`,
`adatechnology-packages`, `quickcart`.

**Outros:** `cryptoada`, `domestic` (congelado), `transportada-mobile`, `adatechnology-scheduling`,
`audio-transcriber`, `phaser`, `Battle-Square`, `supermercado-noemia`, `pai-presente`, e as
pastas `fin-bot-*`. Pastas `*-wt` são worktrees.

> `domestic` é só o diretório padrão do app. **Diga sempre qual projeto é o alvo** na primeira mensagem.

Cada produto sobe a própria infra por `docker-compose.yml` na raiz e `Makefile` (`make` abstrai os comandos).
Hoje há containers de `cryptoada` (Keycloak, Postgres, Mailpit) e `transportada` (Keycloak, MinIO, RabbitMQ,
Postgres, Mailpit) — as portas locais ficam em `docker ps`.

## 4. O que o Claude já carrega sozinho

Em `~/.claude/`:

- `CLAUDE.md`: importa `RTK.md`, `standards/*` e o `CLAUDE-omc.md`.
- `standards/`: código, TypeScript, React, Node, APIs.
- `rules/rules/`: arquitetura (`code-standart.md`), `security.md`, `model-economy.md`, `omc-sessions.md`,
  `railway-projects.md`, `whatsapp-cloud-api.md`, `conversation-flow.md`, e pastas `backend/`, `frontend/`,
  `infrastructure/`, `packages/`.
- `hooks/rtk-rewrite.sh`: reescreve comandos de shell para `rtk` (transparente).
- `commands/fiscal-provider.md` e a skill `fiscal-provider`.

Modelo padrão: `opus`, esforço `low`.

## 5. Plugins, MCPs e skills

**Plugins ativos:** `oh-my-claudecode` (orquestração), `socraticode` (busca semântica),
`unreal-engine-skills-for-claude-code`.

**MCPs:** context7 (docs de biblioteca), github, linear, figma, railway, sentry, sequential-thinking,
duckduckgo, Docs, Drive, Chrome e o navegador embutido.

**Skills que mais importam aqui:** `adatechnology-ui` (telas do `@adatechnology/conversations-ui`),
`use-railway`, `tlc-spec-driven` (specs), `graphify`, `fiscal-provider`, e as do OMC
(`autopilot`, `ralph`, `team`, `ralplan`, `cancel`).

## 6. Como trabalhar com o Claude

1. **Abra a sessão no projeto certo** e diga o alvo e o objetivo.
2. **Specs primeiro** para trabalho grande (`specs/NNN-nome/` com `spec.md`, `plan.md`, `tasks.md`).
   A spec fechada termina com um prompt pronto de `/oh-my-claudecode:autopilot`.
3. **Modelo por fase** (`model-economy.md`): `haiku` para mecânico com aceite por comando, `sonnet` para decisão local,
   `opus` só para arquitetura. O Claude para e pede `/model <x>` quando a fase pede outro.
4. **Gates por task:** typecheck (`tsc --noEmit`), testes (`make check`/`make validate`) e commit isolado.
5. **Fechar modos OMC** ao terminar (`/oh-my-claudecode:cancel`). A palavra "autopilot" numa mensagem não é ordem de executar.
6. **Navegador:** verificar UI por texto (`read_page`, `get_page_text`, console, rede). Screenshot só como prova final, uma vez.
7. **Contexto:** não reler arquivo já lido; usar `offset`/`limit`; varreduras amplas vão para o agente `Explore`.

## 7. Deploy (Railway)

- Workspace **AdA Technology** (`42450f5c-a76c-40d9-b77f-cc627906ead1`); conferir com `railway list`.
- Ambientes: `staging`/`production` ou `<prefixo>-staging`/`<prefixo>-production`.
- Bancos com nome padrão (`Postgres`, `Redis`, `MySQL`, `MongoDB`).
- Depois do primeiro deploy, o projeto deve aparecer em Infra → Custos no painel da Ada.
- Fora do Railway: parar e perguntar antes.
- Cadeia de release: pacotes → npm → produtos → deploy; staging→main é merge commit.

## 8. Segurança (resumo)

Nunca logar PII; segredo só em env validada; segredo que apareceu em terminal/log está queimado e deve ser rotacionado;
`VITE_*` é público. Detalhes em `~/.claude/rules/rules/security.md`.

## 9. Checklist de início do dia

```bash
docker ps                      # infra de cada projeto e socraticode-qdrant no ar
brew services list | grep ollama
railway whoami
rtk gain
```

Depois: abrir a sessão no projeto, dizer o alvo, e confirmar que o índice do SocratiCode está atualizado
(`codebase_status`).

## 10. Problemas conhecidos

- SocratiCode "Docker is not available": o modo tem de ser `external` (seção 2).
- `railway run` quebra com CLI desatualizado: atualizar o `railway`.
- `bun link` de pacote local: bumpar a versão, senão o TS usa a cópia antiga.
- `drizzle-kit` 1.x quebra o deploy das migrations do user-module: manter o formato clássico.
- Stop hook bloqueando sessão alheia: pode ser estado OMC de outra janela; ver `omc-sessions.md`.

## 11. Montar o ambiente em outro computador (Windows)

> Escrito a partir do ambiente macOS. Os passos de Windows **não foram testados**; corrigir aqui quando validar.

**Recomendação: usar WSL2 (Ubuntu).** Claude Code, hooks em bash (`rtk-rewrite.sh`), `Makefile` e os caminhos
`~/.claude` funcionam como no Mac, e este guia vale quase inteiro. Só o Docker Desktop e o Ollama ficam no Windows.

### 11.1 Ordem de instalação

1. WSL2 com Ubuntu (`wsl --install` no PowerShell como administrador) e reiniciar.
2. Docker Desktop com a integração WSL2 ligada para a distro.
3. Ollama para Windows (instalador oficial). Ele escuta em `http://localhost:11434`, que o WSL2 enxerga.
   Depois: `ollama pull nomic-embed-text`.
4. Dentro do WSL: Git, Node, Bun, Railway CLI, Claude Code e o `rtk`.
   Equivalentes ao Mac: `brew` vira `apt` ou o instalador de cada ferramenta.
5. Chave SSH no GitHub (o repositório de regras usa o remoto `git@github.com`).

### 11.2 Trazer as regras

```bash
git clone git@github.com:Andersonfrfilho/ia.git ~/.claude/rules
mkdir -p ~/.codex && ln -sfn ~/.claude/rules/codex/AGENTS.md ~/.codex/AGENTS.md
```

### 11.3 O que este repositório NÃO traz (recriar à mão)

| Item | Onde fica no Mac | Como resolver |
|---|---|---|
| `CLAUDE.md`, `RTK.md`, `CLAUDE-omc.md` | `~/.claude/` | copiar do Mac |
| `standards/` (5 arquivos) | `~/.claude/standards/` | copiar do Mac |
| `settings.json` (modelo, hooks, plugins, `env` do SocratiCode) | `~/.claude/` | copiar e **revisar caminhos**; não versionar se tiver segredo |
| `hooks/rtk-rewrite.sh`, `commands/`, `skills/` | `~/.claude/` | copiar do Mac |
| Memória do Claude | `~/.claude/projects/*/memory/` | opcional; copiar a pasta |
| Plugins `oh-my-claudecode`, `socraticode`, Unreal | `~/.claude/plugins/` | reinstalar pelo marketplace |
| Tokens (GitHub, Railway, Linear, Figma, Sentry) | login de cada serviço | autenticar de novo; **nunca copiar token por chat ou commit** |

### 11.4 SocratiCode no novo computador

1. Subir o Qdrant: `docker run -d --name socraticode-qdrant --restart unless-stopped -p 16333:6333 -p 16334:6334 qdrant/qdrant`.
2. Conferir no `env` do `settings.json`: `QDRANT_MODE=external`, `QDRANT_PORT=16333`, `OLLAMA_MODE=external`,
   `OLLAMA_URL=http://localhost:11434`, `EMBEDDING_PROVIDER=ollama`.
3. Abrir uma sessão nova e rodar `codebase_health`; depois `codebase_index` em cada projeto. O índice não é copiado: é refeito.

### 11.5 Projetos

Clonar os seis principais em `~/Documents/personal/` (ou no caminho equivalente dentro do WSL, nunca em `/mnt/c`,
que deixa Bun, Docker e watchers muito lentos) e adicionar a pasta em `permissions.additionalDirectories`.

### 11.6 Validação final

```bash
docker ps && ollama list && railway whoami && rtk gain && bun --version
```

Em uma sessão: `codebase_health` com tudo `[OK]`, e um pedido simples para confirmar que o Claude lê `CLAUDE.md` e as rules.

## 12. Arquivos globais versionados (`global/`)

Este repositório guarda `CLAUDE.md`, `RTK.md`, `CLAUDE-omc.md`, `standards/` e `hooks/` em `global/`.
Num computador novo, depois do `git clone` da seção 11.2:

```bash
bash ~/.claude/rules/global/install.sh
```

O script cria links em `~/.claude` e guarda o que já existia como `*.bak`.
Editar em `~/.claude/...` edita o arquivo do repositório; é só commitar.
O `settings.json` final **não** é versionado (pode conter segredos e caminhos da máquina), mas o que é comum vem de
`global/settings.base.json` (modelo, esforço, `env` do SocratiCode) e `global/settings.linux.json` (hook do RTK, só bash).
O `install.sh` (Linux/WSL) e o `install.ps1` (Windows) mesclam esses arquivos no `settings.json` local e acrescentam
o `additionalDirectories` da máquina. Rodar de novo é seguro.
O `CLAUDE-omc.md` é gerado pelo `omc-setup`; se o plugin o regenerar, o link continua valendo.

## 13. Retomar no outro computador as branches de trabalho do `transportada`

Levantado em 2026-10-12. Estas nove branches existiam **só** no computador do Mac; foram enviadas ao `origin`
com o mesmo nome (sem tocar em `staging` nem `main`; só `staging` e `main` disparam deploy). As datas e contagens
abaixo são daquele dia — conferir de novo com `git fetch` antes de agir.

```bash
cd ~/Documents/personal/transportada
git fetch origin
git worktree add ../transportada-wt/spec-264 -b work/spec-264 origin/work/spec-264   # uma por branch
```

Depois de buscar: `bun install --frozen-lockfile`, e **rebasear sobre `origin/staging`** antes de continuar
(`git fetch && git rebase origin/staging`), seguido de `bun run typecheck`. Spec, ADR e migration colidem com as de
outras sessões: conferir o número em `origin/staging` e rodar `db:generate` esperando `no_changes` antes de publicar.

| Branch | À frente / atrás de `staging` | O que é e o que falta |
|---|---|---|
| `work/spec-264` | 10 / 0 | Áudio e transcrição na visão do participante (contrato T0.1 e revisão T1.8). Já está sobre `staging`. ⚠️ O worktree no Mac (`transportada-wt/spec-260`) tem **14 arquivos não commitados** que **não estão no remoto**: commitar lá antes de sair do Mac, ou esse trecho se perde. |
| `work/spec-248` | 13 / 335 | Retorno à contratante: schema e integração da migration (T3.1 e T3.2). Rebase pesado: regenerar a migration e o snapshot sobre o schema atual. Um arquivo não commitado no worktree do Mac. |
| `work/spec-251` | 15 / 353 | Emissor Nacional: levantamento, modelo por task e contratos herdados da 250 (T0.1). Quase só documentação. |
| `work/spec-239` | 110 / 826 | A maior. A exigência da ocorrência chega na rua; a spec virou a 245 e depois a 246. Cerca de 60 desses commits não têm o mesmo assunto em `staging`, mas a 246 já foi publicada: **antes de rebasear, comparar com `staging` o que realmente falta.** |
| `work/spec-235` | 34 / 1174 | O ajudante é um perfil. Painel e API já estão em `staging` desde 2026-10-03; faltam cerca de 12 commits de documentação e a colisão do número 235. |
| `work/259-lista-de-viagens-ocupacao-e-lucro` | 20 / 166 | Ocupação e lucro na lista de viagens. A API foi promovida (PR #158); sobram só as evidências da T3.3 e do gate final T4.2. |
| `work/spec-247`, `work/spec-247-dec`, `work/spec-247-fe` | 39 / 25 / 46 | A devolução soma os itens. O conteúdo já está em `staging`; faltam só commits de `prettier` no `evidence.md`. Candidatas a descarte depois de conferir. |

### O que ficou de fora de propósito

- Branches cujo conteúdo já está em `staging` ou `main` foram apagadas no Mac (SHAs guardados em
  `branch-shas-backup*.txt` na pasta de rascunho da sessão, que **não** vai para o outro computador).
- Continuam **só no Mac**, sem cópia no remoto: `work/spec-211`, `work/spec-165`, `work/spec-145-detalhe-da-viagem`,
  `work/reconcile-spec-145`, `work/openapi`, `work/spec-150`, os `wip/spec-133` a `wip/spec-146` e os `salvo/stash-*`.
  Se algum for necessário no outro computador, enviar do Mac com `git push origin <branch>` primeiro.
- Trabalho **não commitado** nunca viaja pelo git: conferir `git status` em cada worktree do Mac antes de trocar de máquina.

## 14. Windows + WSL: um perfil só (regra)

**Regra:** o Claude no Windows e o Claude no WSL (Ubuntu) são **um único ambiente lógico**. Nada pode existir só de um
lado. Duplicar ou editar configuração direto num dos perfis (`C:\Users\<user>\.claude` ou `~/.claude` no Ubuntu) faz os
dois se desalinharem, e o problema só aparece depois (ferramenta que funciona num lado e não no outro).

1. **Fonte única:** este repositório (`ia`). Regras, `standards/`, `CLAUDE.md`, `hooks/` e os `settings.*.json` mudam
   **só aqui**, por commit. Nunca editar `~/.claude/settings.json`, `CLAUDE.md` ou `rules/` à mão.
2. **Uma pasta física, no Linux** (desde 2026-10-17, ver §14.1b): `~/personal` é pasta real no disco do Ubuntu.
   O Windows enxerga por `\\wsl.localhost\Ubuntu\home\miyazaki\personal`. Existe **um** clone do `ia`; não clonar outro.
3. **Depois de mudar o repositório**, rodar o instalador **dos dois lados**: `bash ~/personal/ia/global/install.sh`
   (Ubuntu) e, num PowerShell **como administrador** (symlink para UNC exige elevação),
   `pwsh -File \\wsl.localhost\Ubuntu\home\miyazaki\personal\ia\global\install.ps1`.
4. **Mesma lista de plugins e ferramentas nos dois lados.** Instalou ou removeu plugin, MCP ou ferramenta de um lado?
   Faça o mesmo no outro no mesmo momento. Conferir com `claude plugin list` nos dois.
5. **Única diferença permitida:** o hook do RTK existe só no Linux (`settings.linux.json`), porque o `rtk` é um binário
   Linux e o hook é bash. Qualquer outra diferença é bug.
6. **Não se sincroniza (é por perfil):** login do `claude`, histórico, `plugins/` instalados, tokens (`gh`, `railway`,
   MCPs). Refazer o login em cada lado; **nunca copiar token**.

### 14.1 Instalação feita em 2026-10-12 (referência)

| Item | Ubuntu (WSL) | Windows |
|---|---|---|
| Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash`, PATH em `~/.local/bin` | `winget` (Anthropic.ClaudeCode) |
| Node / Bun | nvm (Node LTS) + `curl -fsSL https://bun.sh/install \| bash` | `winget install OpenJS.NodeJS.LTS` e `Oven-sh.Bun` |
| Railway CLI | `npm install -g @railway/cli` | `npm install -g @railway/cli` |
| `rtk` | script oficial de `rtk-ai/rtk` em `~/.local/bin`; conferir com `rtk gain` | não usado (hook é bash) |
| Ollama | usa o do Windows via `localhost` (rede espelhada) | `winget install Ollama.Ollama` + `ollama pull nomic-embed-text` |
| Qdrant | usa o do Docker Desktop via `localhost:16333` | `docker run` da seção 11.4 |
| OMC | `claude plugin marketplace add https://github.com/Yeachan-Heo/oh-my-claudecode` e `claude plugin install --scope user oh-my-claudecode` | idem |
| SocratiCode | `claude plugin marketplace add giancarloerra/socraticode` e `claude plugin install --scope user socraticode@socraticode` | idem |
| Graphify (2026-10-17) | `python3 -m venv ~/.local/share/graphify && ~/.local/share/graphify/bin/pip install graphifyy` (dois "y"; oficial é graphify.com), link em `~/.local/bin/graphify`, depois `graphify install --platform claude` e `git checkout global/CLAUDE.md` no `ia` (o instalador grava caminho da máquina e apaga o import do OMC) | não usado |

### 14.1b Projetos moram no Linux (regra, 2026-10-17)

O Claude roda só no Ubuntu; o do PowerShell não é usado. Por isso, em 2026-10-17, **todos os projetos foram movidos para
o disco do Linux** (`~/personal/<projeto>`), e os worktrees para `~/personal/<projeto>-wt/` (único caminho; nunca `~/<projeto>-wt/` nem projeto direto em `~`).

- **Exceção: projetos Unreal** (`Battle-Square` e qualquer `*.uproject`) ficam em `C:\Users\<user>\Documentos\personal\`.
  O Unreal Editor e o build (Visual Studio/UBT) são Windows e quebram via `\\wsl.localhost`. O Claude os lê por `/mnt/c/...`.
- A cópia antiga em `C:\Users\<user>\Documentos\personal\` ficou como **backup** da migração. Não trabalhar nela; apagar
  depois de validar (cada projeto com `bun install` e testes passando no Linux).
- `.env`/`.env.test` dos worktrees são links para os arquivos do repositório principal, já no Linux.
- O disco do WSL (`.vhdx`) **não tem backup** do Windows/OneDrive: o backup é o git. Dar push com frequência; `.env` guardado fora.
- Projeto novo: `git clone` direto em `~/personal/`, nunca em `/mnt/c`.
- Medido em 2026-10-16 (transportada): no Linux, 3250 testes do painel em 2 s e o `tsc` da API em 40 s; em `/mnt/c` a mesma
  suíte estourava o tempo limite e as integrações levavam horas.

### 14.2 Armadilhas encontradas

- **Rede do WSL:** por padrão o Ubuntu não enxerga `localhost` do Windows. `C:\Users\<user>\.wslconfig` com
  `[wsl2]` e `networkingMode=mirrored`, depois `wsl --shutdown`. Sem isso, Ollama e Qdrant ficam inalcançáveis do WSL.
- **PATH fixo no `.zshrc`/`.bashrc`:** uma linha `export PATH="/home/...:..."` literal depois do nvm/bun apaga o Node, o
  Bun e o `railway`. Usar sempre `export PATH="$HOME/.local/bin:$PATH"`.
- **Plugin OMC sem Bun:** instalado com `bun` fora do PATH, o OMC não instala as dependências. Garantir Bun no PATH e
  reinstalar o plugin.
- **SocratiCode no Windows sem Node:** o MCP roda por `npx`; sem Node ele não carrega. Node é pré-requisito dos dois lados.
- **`docker` no Ubuntu:** exige "WSL integration" ligada para a distro no Docker Desktop.
- **Login por navegador:** `railway login` redireciona para `127.0.0.1` e pode mostrar "conexão recusada" no fim; o login
  costuma concluir mesmo assim (conferir com `railway whoami`). Alternativa: `railway login --browserless`.
  No `gh`, o fluxo de código de dispositivo funciona sem abrir navegador no WSL.
- **Teclado:** se o Windows volta para o layout US, deixar só `pt-BR` ABNT2 na lista de idiomas e copiar as
  configurações de região para a tela de boas-vindas.
- **Abrir terminal no Ubuntu:** usar o Windows Terminal (perfil Ubuntu como padrão). Ao rodar `claude`, abrir a partir da
  pasta do projeto, não da home.

### 14.3 Indexar projetos no SocratiCode (feito em 2026-10-12)

Resultado: `quickcart` 2.576 chunks, `ativada` 8.959, `financing-chatbot` 10.714, `adatechnology-packages` 9.294,
`ada-technology` 1.810, `transportada` 304.611 (99 min). Watchers ativos; o índice se atualiza com as mudanças.

- **O índice é chaveado pelo caminho resolvido.** No Ubuntu, `~/personal` é link para `/mnt/c/Users/<user>/Documentos/personal`,
  e o índice usa o caminho `/mnt/c/...`. Abrir o mesmo projeto por `~/personal/<projeto>` ou por `C:\...` não encontra o
  índice e cria outro (duplicado no Qdrant). **Regra (desde 2026-10-17):** indexar e consultar pelo caminho `/home/miyazaki/personal/...`; os índices antigos em `/mnt/c/...` são órfãos e saem com `codebase_remove`.
- **`QDRANT_URL` é obrigatório** em `QDRANT_MODE=external` (só `QDRANT_PORT` não basta). Está em `global/settings.base.json`.
- **Não indexar com `claude -p`.** O indexador roda dentro do servidor MCP e morre quando a sessão termina; o `sleep` no
  Bash é bloqueado e a sessão curta deixa o índice incompleto (o `financing-chatbot` parou em 720 chunks após 8 tentativas).
  Falhas repetidas de conexão ainda gravam `~/.claude/mcp-needs-auth-cache.json`, e o Claude ignora o MCP por 15 min
  (apagar o conteúdo do arquivo destrava).
- **Use o script** `global/tools/socraticode-index.mjs`, que fala direto com o MCP e espera até terminar:

```bash
node ~/personal/ia/global/tools/socraticode-index.mjs /mnt/c/Users/ander/Documentos/personal quickcart transportada
```

  Retoma de onde parou. O `transportada` é longo; rodar em segundo plano.
