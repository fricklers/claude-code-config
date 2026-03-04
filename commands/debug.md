---
name: debug
description: "Investigate a bug. Usage: /debug [description]. Without arguments, looks at recent errors or test failures."
---

Investigate and fix a bug using hypothesis-driven debugging.

**If arguments were provided:** Start investigating the described bug.
**If no arguments:** Look at the most recent error — check terminal output, test failures (`npm test`, `pytest`, etc.), or the last error in the project's log files.

## Process

1. Search the codebase for relevant code paths, error messages, and related tests.

2. Follow a systematic approach:
   - **Reproduce** — Confirm the bug. Run the failing test or trigger the error.
   - **Hypothesize** — List 3+ possible causes. Don't fix yet.
   - **Isolate** — Binary search to narrow scope.
   - **Verify** — Test top hypothesis. If wrong, try the next.
   - **Fix** — Smallest change that resolves the root cause.
   - **Prevent** — Write a regression test.

3. After fixing, run the full test suite to confirm no regressions.

Report your findings with exact file paths, line numbers, and the root cause explanation.
