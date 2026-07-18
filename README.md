# IA rules

Repositório de regras e estudos para assistentes de desenvolvimento.

## Codex

As regras globais versionadas ficam em [`codex/AGENTS.md`](codex/AGENTS.md).
Para ativá-las na máquina:

```bash
mkdir -p ~/.codex
ln -sfn ~/.claude/rules/codex/AGENTS.md ~/.codex/AGENTS.md
```

As regras locais de cada projeto têm precedência sobre os padrões globais.

A stack Ada vigente usa Bun (`Bun.serve`, baseado internamente em
uWebSockets), PostgreSQL/Drizzle, workers Bun e React/Vite. As regras detalhadas
ficam em `rules/backend/` e `rules/frontend/`.
