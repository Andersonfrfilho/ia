---
paths:
  - "**/.claude/rules/README.md"
---

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

O baseline de segurança transversal (LGPD, OWASP Top 10:2025, ASVS 5.0, supply
chain) fica em [`rules/security.md`](rules/security.md) e é bloqueante em code
review.

Capacidades reutilizáveis entre produtos (WhatsApp, fiscal, etc.) seguem o
padrão de módulos plugáveis em
[`rules/packages/pluggable-module.md`](rules/packages/pluggable-module.md).
