# Node.js Standards

## Module System

- Use ESM (`import`/`export`) — never CommonJS `require` in new code
- Named exports only — no default exports

## Async

- Always `async/await` — no raw `.then()/.catch()` chains
- Handle `async` errors with `try/catch` at the boundary, not inside every function
- Never `await` inside a loop — use `Promise.all` for parallel work

```ts
// correct
const results = await Promise.all(userIds.map(fetchUser));

// wrong
for (const userId of userIds) {
  const user = await fetchUser(userId);
}
```

## Environment Variables

- Access env vars only through a validated config module — never `process.env.X` scattered in code
- Validate all required env vars at startup with a schema (zod or similar)
- Never hardcode secrets or URLs — always environment-configurable

```ts
// config/environment.ts
import { z } from 'zod';

const environmentSchema = z.object({
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(['development', 'production', 'test']),
});

export const environment = environmentSchema.parse(process.env);
```

## Error Handling

- Define typed error classes for domain errors
- Errors from external systems (DB, HTTP) must be caught and converted to domain errors at the adapter layer
- Never let unhandled promise rejections propagate — handle at the top level

## Logging

- Structured logs only (JSON) — never `console.log` in production code
- Log levels: `error` for failures, `warn` for unexpected-but-recoverable, `info` for key lifecycle events, `debug` for tracing
- Never log sensitive data (passwords, tokens, PII)
- Include correlation IDs in all log entries for traceability

## Process

- Graceful shutdown: listen for `SIGTERM`/`SIGINT`, drain connections, then exit
- Never `process.exit()` outside the shutdown handler
- Always set a timeout on shutdown to force-exit if drain takes too long

## Security

- Validate all input at the boundary (HTTP request body, query params, env vars)
- Sanitize data before writing to DB or sending to external services
- Use parameterized queries — never string-concatenated SQL
- Set `NODE_ENV=production` in deployed environments
