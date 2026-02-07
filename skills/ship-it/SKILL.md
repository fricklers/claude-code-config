---
name: ship-it
description: Pre-deployment verification protocol. Checklist to run before declaring work complete.
---

When this skill is active, run through this checklist before declaring any work "done":

## 1. Tests Pass

- All tests green — `npm test`, `pytest`, `cargo test`, or equivalent
- No skipped tests without an explanation in the skip message
- New code has corresponding test coverage

## 2. Types Check

- `tsc --noEmit` / `mypy --strict` / `cargo check` / equivalent — zero errors
- No suppressed type errors (`as any`, `@ts-ignore`, `# type: ignore`) without a comment explaining why

## 3. Lint Clean

- Zero warnings from the project's linter
- Fix or explicitly suppress with an inline justification
- Run autoformat if the project uses one (`prettier`, `black`, `rustfmt`)

## 4. No Debug Artifacts

Search the diff for:
- `console.log` / `console.debug` (that aren't intentional logging)
- `debugger` statements
- `print(` used for debugging (not logging)
- `TODO` without a tracking reference (issue number or owner)
- `FIXME` — these should be resolved, not shipped
- Hardcoded `localhost` URLs or test credentials

## 5. Environment Variables

- All new env vars documented in `.env.example` or equivalent
- No hardcoded secrets, API keys, or connection strings in source
- Defaults are sensible (or absent, forcing explicit configuration)

## 6. Migrations

If database schema changed:
- Migration is reversible (has a `down` / rollback)
- Tested the rollback path
- RLS policies updated for new tables/columns
- No destructive changes (column drops, renames) in the same deploy that removes code using them

## 7. Bundle and Dependencies

- No unexpected new dependencies — justify each addition
- Check bundle size impact if frontend (`npx vite-bundle-analyzer` or equivalent)
- Lock file updated and committed

## 8. Manual Smoke Test

Describe 3 things to verify manually:
1. The primary happy path works end-to-end
2. An error case is handled gracefully
3. The feature works after a page refresh / restart
