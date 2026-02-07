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

Design types before writing logic — types are the specification:
- **Sketch the type graph** on paper or in comments before coding: which types reference which?
- Use branded types for IDs: `type UserId = string & { readonly __brand: 'UserId' }`
- Extract shared shapes into a `types/` directory — one file per domain concept
- Run `npx tsc --noEmit` after each type change to catch cascading breakage early

## 3. Configure Strictness

Verify `tsconfig.json` has maximum strictness activated:
- `"strict": true` — non-negotiable baseline
- `"noUncheckedIndexedAccess": true` — forces undefined checks on dynamic access
- `"exactOptionalProperties": true` — distinguishes `undefined` from missing
- `"noImplicitOverride": true` — catches accidental method overrides
- If any of these are missing, add them and fix the resulting errors before continuing

## 4. Eliminate Escape Hatches

Systematically remove every type-safety bypass in the code you touch:
- **Audit `any`**: search for `any` in changed files — replace each with a specific type or `unknown` + guard
- **Audit assertions**: search for `as X` — restructure data flow so the cast is unnecessary
- **Audit suppressions**: search for `@ts-ignore` / `@ts-expect-error` — fix the underlying type error
- **Track progress**: count remaining escape hatches before and after — the number must go down

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
- If any check fails, fix the issue and re-run the entire chain
