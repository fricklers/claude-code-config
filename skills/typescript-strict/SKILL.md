---
name: typescript-strict
description: Strict TypeScript workflow. Eliminates suppressions, models domain types, proves zero-any in every diff.
---

When this skill is active, follow this 6-step discipline for every TypeScript change:

## 1. Audit Existing Suppressions

Before writing new code, search for tech debt in the affected files:
- `grep -rn "as any\|@ts-ignore\|@ts-expect-error\|// eslint-disable" src/`
- Count and categorize each suppression: fixable now, needs refactor, genuinely unavoidable
- Fix at least one suppression per PR when touching a file that contains them

## 2. Model Domain Types First

Design types before writing logic:
- Define discriminated unions for state: `{ status: 'idle' } | { status: 'loading' } | { status: 'error'; error: AppError } | { status: 'ok'; data: T }`
- Use branded types for IDs: `type UserId = string & { readonly __brand: 'UserId' }`
- Extract shared shapes into a `types/` directory — one file per domain concept
- Prefer `interface` for object shapes, `type` for unions and computed types

## 3. Configure Strictness

Verify `tsconfig.json` has maximum strictness activated:
- `"strict": true` — non-negotiable baseline
- `"noUncheckedIndexedAccess": true` — forces undefined checks on dynamic access
- `"exactOptionalProperties": true` — distinguishes `undefined` from missing
- `"noImplicitOverride": true` — catches accidental method overrides
- If any of these are missing, add them and fix the resulting errors before continuing

## 4. Write Type-Safe Code

Every function and variable must satisfy these constraints:
- **Explicit return types** on all exported functions — no inferred public API
- **No `any`** — use `unknown` and narrow with type guards or `zod` schemas
- **No type assertions** (`as X`) — restructure the code so types flow naturally
- **Readonly by default** — `readonly` arrays, `Readonly<T>` props, `as const` literals

## 5. Validate at Boundaries

External data enters the system untyped — validate it immediately:
- Parse API responses with `zod`, `valibot`, or `io-ts` — never trust `as Response`
- Validate environment variables at startup: `z.object({ DATABASE_URL: z.string().url() }).parse(process.env)`
- Use `satisfies` to check object literals match a type without widening: `const config = { ... } satisfies Config`

## 6. Prove Zero-Any in Diff

Before marking work complete, verify strictness in the changed files:
- Run `npx tsc --noEmit` — zero errors
- Run the linter: `npx eslint --rule '{"@typescript-eslint/no-explicit-any": "error"}' <changed-files>`
- Confirm the diff introduces zero new `any`, `as any`, `@ts-ignore`, or `@ts-expect-error`
- If a suppression is genuinely unavoidable, add a comment explaining exactly why it's safe
