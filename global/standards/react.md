# React Standards

## Component Structure

- One component per file — file name matches component name in `PascalCase`
- Props type named `<ComponentName>Props` in the same file
- Order inside a component: types → hooks → derived state → handlers → return

```tsx
type UserCardProps = {
  userId: string;
  onSelect: (userId: string) => void;
};

function UserCard({ userId, onSelect }: UserCardProps) {
  const { data: user } = useUser(userId);
  const displayName = user?.name ?? 'Unknown';

  function handleClick() {
    onSelect(userId);
  }

  return <div onClick={handleClick}>{displayName}</div>;
}
```

## Naming

- Components: `PascalCase`
- Hooks: `use` prefix + descriptive name (`useLeadList`, `usePaymentCalculation`)
- Event handlers: `handle` prefix (`handleSubmit`, `handlePageChange`)

## State

- Prefer derived state over `useState` — compute from existing state when possible
- Never store in state what can be derived from props or other state
- Use `useReducer` when state transitions are complex or interdependent

## Effects

- `useEffect` only for syncing with external systems (DOM, timers, subscriptions)
- Never use `useEffect` to transform data — derive it during render
- Always clean up subscriptions, timers, and event listeners
- Include all dependencies in the deps array — no eslint-disable for exhaustive-deps

## Performance

- Memoize (`useMemo`, `useCallback`, `memo`) only when profiling proves it's needed
- Never premature optimization — measure first
- Use `React.lazy` + `Suspense` for route-level code splitting

## Patterns

- Prefer composition over prop drilling beyond 2 levels — use context or state manager
- Never pass more than 5 props — extract a sub-component or use a config object
- Avoid render props — prefer hooks
- Compound components for complex UI with shared state

## Accessibility

- Interactive elements must be keyboard accessible
- Images must have `alt` text
- Use semantic HTML elements (`button`, `nav`, `main`, `article`) over generic `div`

## No

- No inline styles — use CSS modules, utility classes, or styled-components
- No `index.tsx` as a component file name — name it after the component
- No `React.FC` type — type props directly and let TypeScript infer the return
