---
name: rigorous-coding
description: Assumption-first coding discipline. Activates structured before/during/after workflow for writing correct, testable code.
---

When this skill is active, follow this 8-step discipline for every code change:

## Before Writing Code

1. **State assumptions** — What are the inputs? What external state exists? What output is expected? Write these down (as comments or in your reasoning) before writing a single line.

2. **Identify edge cases** — For every input, consider: null/undefined, empty string/array, zero, negative numbers, boundary values (max int, empty object), concurrent access, partial failures.

3. **Ask: under what conditions does this NOT work?** — Network failures, missing files, permission errors, malformed input, unexpected types. If you can name a failure mode, handle it.

## While Writing Code

4. **Handle errors explicitly** — Every external call (network, file system, database, subprocess) can fail. Use try/catch, Result types, or error returns — never assume success.

5. **Never suppress type errors** — No `as any`, `@ts-ignore`, `# type: ignore`, `// @ts-expect-error` without a comment explaining exactly why it's safe. If the types don't fit, the code is wrong.

6. **Write testable code** — Pure functions where possible. Inject dependencies rather than importing globals. Separate I/O from logic. If it's hard to test, it's probably hard to maintain.

## After Writing Code

7. **Run tests and linter** — Before declaring the work complete, verify it passes. If tests fail, fix them. If the linter complains, fix it. Don't ship known failures.

8. **Write tests** — Cover three categories:
   - **Happy path**: the normal, expected usage
   - **Error cases**: what happens when things go wrong
   - **Edge cases**: the boundary conditions from step 2
