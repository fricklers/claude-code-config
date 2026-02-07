---
description: React + Vite + TypeScript conventions
globs:
  - "**/*.tsx"
  - "**/*.jsx"
---

## Components

- Function components only — no class components
- One component per file for non-trivial components, co-locate styles and tests
- Name files after the component: `UserProfile.tsx` exports `UserProfile`
- Prefer composition over prop drilling — use children and render props

## Hooks

- Extract custom hooks for reusable stateful logic (`useAuth`, `useDebounce`)
- Follow Rules of Hooks — no conditional or nested hook calls
- `useCallback` and `useMemo` only when profiling shows a performance need
- Custom hooks return objects (not arrays) when there are 3+ return values

## State

- Lift state to the lowest common ancestor that needs it
- URL state for anything that should be shareable or bookmarkable
- Server state belongs in TanStack Query (React Query) — not `useState` + `useEffect`
- Form state: controlled components for simple forms, React Hook Form for complex

## Performance

- Lazy-load routes with `React.lazy` + `Suspense`
- Avoid prop drilling — prefer composition or context for deeply nested data
- Use `React.memo` only after measuring — premature memoization adds complexity
- Key lists by stable unique IDs, never by array index

## Vite-Specific

- Use `import.meta.env.VITE_*` for environment variables (not `process.env`)
- Configure path aliases in `vite.config.ts` and `tsconfig.json` together
- Use `import.meta.hot` for HMR-aware code when needed
