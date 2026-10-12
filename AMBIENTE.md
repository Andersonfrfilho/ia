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
