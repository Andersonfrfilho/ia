# TypeScript Standards

## Types

- Never use `any` — use `unknown` + type guards or explicit types
- Prefer `type` over `interface` unless the type needs to be extended/merged
- Always type function return values explicitly
- Use `readonly` for properties that should not be mutated
- Use `as const` for literal objects and arrays that are configuration

```ts
// correct
type UserId = string;
type CreateUserInput = {
  readonly name: string;
  readonly email: string;
};

// wrong
interface CreateUserInput {
  name: any;
  email: any;
}
```

## Generics

- Name generics descriptively when context is not obvious: `TEntity`, `TResponse`, `TInput`
- Single-letter generics only for truly generic utilities (`T`, `K`, `V`)

## Enums

- Prefer `const` objects with `as const` over TypeScript `enum`
- Use string values for readability in logs and APIs

```ts
// correct
const LeadStatus = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
} as const;
type LeadStatus = (typeof LeadStatus)[keyof typeof LeadStatus];

// wrong
enum LeadStatus { PENDING, APPROVED, REJECTED }
```

## Nullability

- Prefer `undefined` over `null` (use `null` only at API/DB boundaries)
- Use optional chaining `?.` and nullish coalescing `??` — never `||` for defaults
- Never use non-null assertion `!` unless you can prove the value is defined

## Type Guards

- Write explicit type guards for `unknown` values coming from external sources
- Use `zod` or similar for runtime validation at boundaries

```ts
function isApiError(value: unknown): value is ApiError {
  return typeof value === 'object' && value !== null && 'message' in value;
}
```

## Generics on Functions

- Infer generics when possible — only specify when inference fails
- Avoid overengineering with deeply nested generic constraints

## tsconfig

- `strict: true` always
- `noUncheckedIndexedAccess: true` for safer array/object access
- `exactOptionalPropertyTypes: true` to distinguish `undefined` from missing keys
