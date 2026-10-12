# Code Standards

## Naming

- **Every identifier is in English** — files, folders, functions, variables, types, constants, keys, asset names. Text the end user reads, comments and specs may stay in the product language (pt-BR); code names never do. A codebase that mixes languages forces every reader to guess which one a name is in
- Full descriptive words only — no abbreviations, no diminutives, no single-letter names
- Variables and functions: `camelCase`
- Classes, types, interfaces: `PascalCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Booleans: prefix with `is`, `has`, `can`, `should` (`isLoading`, `hasError`)
- Event handlers: prefix with `handle` (`handleSubmit`, `handleUserClick`)
- Functions: verb + noun (`fetchLeadById`, `calculateMonthlyPayment`)

## Functions

- Max 3 parameters — beyond that, receive an options object
- Single responsibility — one function does one thing
- Pure by default; isolate side effects at system boundaries
- No function longer than 40 lines — split it
- Prefer early returns over nested `if`

```ts
// correct
function validateEmail(email: string): boolean {
  if (!email.includes('@')) return false;
  if (email.length < 5) return false;
  return true;
}

// wrong
function validateEmail(email: string): boolean {
  if (email.includes('@')) {
    if (email.length >= 5) {
      return true;
    }
  }
  return false;
}
```

## Comments

- Only when the WHY is non-obvious (hidden constraint, subtle invariant, workaround for a specific bug)
- One short line max — no block comments
- Never describe WHAT the code does — well-named identifiers already do that
- Never reference the task, fix, or issue number in code comments (belongs in the commit message)

## Imports

- Group order: 1) node built-ins, 2) external libs, 3) internal `@/`, 4) relative `./`
- One blank line between groups
- Named exports only — no default exports

## Error Handling

- Validate only at system boundaries (user input, external API responses)
- Throw early, recover at the boundary — don't swallow errors silently
- Never add fallbacks or error handling for states that cannot happen
- Use typed errors when possible

## File Organization

- One concept per file — no god files
- File name matches the primary export name
- Keep files under 200 lines — if longer, split by responsibility
