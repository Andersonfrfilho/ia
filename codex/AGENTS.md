# Global Codex rules

## Precedence

- The nearest project `AGENTS.md`, constitution, specification, and task rules
  override these global defaults whenever they conflict.
- Do not silently combine incompatible stacks or architecture rules. Follow the
  project decision and call out the conflict.
- Never infer production deployment, destructive migrations, secret handling,
  or external publication from a request to review, plan, or test.

## Required standards

Before changing code, read the general standard and only the standards relevant
to the task:

- General:
  `/Users/anderson.filho/.claude/standards/code-standards.md`
- TypeScript:
  `/Users/anderson.filho/.claude/standards/typescript.md`
- React:
  `/Users/anderson.filho/.claude/standards/react.md`
- Node.js:
  `/Users/anderson.filho/.claude/standards/nodejs.md`
- APIs:
  `/Users/anderson.filho/.claude/standards/apis.md`

Do not load every standard for a documentation-only or unrelated task.

## Token-efficient shell work

- Read `/Users/anderson.filho/.claude/RTK.md` before substantial shell-based
  repository work.
- Use `rtk` when it preserves the evidence needed for the task; use the raw
  command when filtering would hide relevant diagnostics.
- Prefer `rg` and `rg --files` for search.

## Spec-driven development

- Work on one identified task from the active feature `tasks.md`.
- Do not implement while the active spec contains `[NEEDS CLARIFICATION]`.
- Write applicable acceptance or contract tests before implementation.
- Record expensive or hard-to-reverse architectural decisions in an ADR.
- Every task must state dependencies, verification commands, success criteria,
  and the recommended model.
- A task is not complete without proportional typecheck, lint, tests, and
  recorded evidence.

## Model economy

- Codex Luna (`gpt-5.6-luna`, low): short documentation and repetitive,
  mechanical edits.
- Codex Terra (`gpt-5.6-terra`, medium): normal implementation, CRUD, UI,
  straightforward tests, and reversible migrations.
- Codex Sol (`gpt-5.6-sol`, high): architecture, security, authentication,
  fiscal behavior, concurrency, cryptography, critical migrations, and release
  review.
- Free/economic models, when available: read-only exploration, inventory,
  summaries, first spec drafts, and bounded predictable tests.
- Plan with the smallest sufficient context. Escalate after two equivalent
  failures instead of repeating the same attempt.
- Before implementing high-risk work with a cheaper model than recommended,
  stop and tell the user which model the task requires. Read-only review and
  planning may continue while documenting the recommendation.

## Security and multi-tenancy defaults

- Never log or commit passwords, tokens, private keys, certificates, or
  sensitive fiscal payloads.
- Derive tenant/company identity from authenticated context, never from a
  freely supplied client field.
- Use precise decimal representations for money.
- Require transactions, constraints, and idempotency at concurrency and
  external-effect boundaries.

## Graphify

- When the user explicitly invokes `/graphify`, read and follow
  `/Users/anderson.filho/.agents/skills/graphify/SKILL.md` before doing anything
  else.
