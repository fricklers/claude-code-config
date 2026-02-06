---
description: TypeScript conventions
globs:
  - "**/*.ts"
  - "**/*.tsx"
---

## Types
- Use explicit return types on exported functions
- Prefer `interface` over `type` for object shapes (interfaces are extendable and give better error messages)
- Use `unknown` over `any` — narrow with type guards
- Use discriminated unions for state: `{ status: 'loading' } | { status: 'error'; error: Error } | { status: 'ok'; data: T }`

## Patterns
- Use `const` by default, `let` only when mutation is needed, never `var`
- Prefer `readonly` arrays and properties when mutation isn't required
- Use optional chaining (`?.`) and nullish coalescing (`??`) over manual checks
- Prefer `Map`/`Set` over plain objects for dynamic key collections

## Error Handling
- Use custom error classes for domain-specific errors
- Always include the original error as `cause`: `throw new AppError('msg', { cause: err })`
- Use `Result<T, E>` pattern for operations that can fail expectedly (parsing, validation)

## Async
- Always handle promise rejections — no floating promises
- Use `Promise.all` for independent async operations, not sequential `await`
- Prefer `AbortController` for cancellation over custom mechanisms
