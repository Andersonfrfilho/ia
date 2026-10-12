# API Standards

## REST Design

- Resources are nouns, never verbs: `/leads`, `/users/:id/payments`
- HTTP verbs carry the action: `GET` read, `POST` create, `PUT` replace, `PATCH` update, `DELETE` remove
- Plural resource names: `/leads` not `/lead`
- Nested resources only when the child cannot exist without the parent: `/users/:id/addresses`
- Max 2 levels of nesting — flatten anything deeper

## Status Codes

| Situation | Code |
|---|---|
| Success with body | 200 |
| Created | 201 |
| Success no body | 204 |
| Bad input (validation) | 400 |
| Not authenticated | 401 |
| Not authorized | 403 |
| Not found | 404 |
| Conflict (duplicate) | 409 |
| Unprocessable entity | 422 |
| Internal error | 500 |

## Request & Response Shape

- Request bodies: `camelCase` JSON
- Response bodies: always wrap in a consistent envelope

```ts
// Success
{ "data": { ... } }

// List
{ "data": [...], "pagination": { "total": 100, "page": 1, "perPage": 20 } }

// Error
{ "error": { "code": "LEAD_NOT_FOUND", "message": "Lead with id 123 not found" } }
```

- Never expose internal field names, stack traces, or DB errors in responses

## Validation

- Validate every request at the boundary — reject invalid input with `400` before it touches domain logic
- Return all validation errors at once, not the first one found
- Error `code` must be a stable string constant (machine-readable) — `message` is human-readable

## Versioning

- Version in the URL path: `/v1/leads`, `/v2/leads`
- Never break existing versions — add a new version
- Deprecation: add `Deprecation` header with sunset date before removing

## Pagination

- Cursor-based pagination for large collections
- Offset-based only for small, user-facing lists
- Always cap `perPage` at a maximum (100 is usually enough)

## Authentication

- Bearer token in `Authorization` header — never in query params or body
- Short-lived access tokens + refresh tokens
- Validate token on every request — no trusted sessions server-side

## Idempotency

- `GET`, `PUT`, `DELETE` must be idempotent
- `POST` that creates resources must accept an idempotency key header
- Return `200` (not `201`) when an idempotent `POST` finds an existing resource

## Rate Limiting

- Return `429 Too Many Requests` with `Retry-After` header
- Rate limit per authenticated user, not per IP

## Documentation

- Every endpoint documented with: method, path, auth required, request schema, response schema, error codes
- Keep docs in sync with the implementation — if they diverge, the implementation wins

### Scalar is the reference UI

**Serve API docs with [Scalar](https://github.com/scalar/scalar), never Swagger UI or Redoc.** It is
one `<script>` tag over an OpenAPI document — no build step — and it is far more readable, with
search that works and a layout that survives a phone screen, which is where someone checks a
contract mid-incident.

```html
<script id="api-reference" data-url="/v1/openapi.json"></script>
<script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
```

- **The OpenAPI document is generated from the route definitions**, never hand-written in parallel.
  Docs maintained by hand drift, and wrong docs still answer 200 — nothing fails to reveal it. If
  the framework cannot derive it, declare routes as data and derive both from that.
- **Test that every route appears in the document.** The failure mode is a documented path that no
  route serves, and it is invisible without an assertion.
- CDN script is fine for a dev-only docs route; add `@scalar/api-reference` as a dependency when the
  page must work offline or in production.
- Serve the docs route **outside production only**, unless the API is public by design — publishing
  the whole surface to unauthenticated callers hands over the route map.
