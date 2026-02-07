---
name: debug
description: Hypothesis-driven debugging discipline. Forces scientific method instead of random code changes.
---

When this skill is active, follow this 6-step discipline for every debugging session:

## 1. Reproduce

Confirm the bug exists and is deterministic. Get:
- The exact error message and stack trace
- Steps to trigger it reliably
- Expected behavior vs actual behavior
- Environment details (browser, Node version, OS) if relevant

If you can't reproduce it, you can't fix it. Don't guess — find the trigger first.

## 2. Hypothesize

List 3+ possible causes, ranked by likelihood. For each hypothesis:
- State what would need to be true for this to be the cause
- State what evidence would confirm or rule it out
- Do NOT write any fix code yet

## 3. Isolate

Narrow the scope to one module or function using binary search:
- Add targeted logging at boundaries (input/output of suspected functions)
- Comment out code paths to identify which branch causes the failure
- Use git bisect if the bug was introduced recently
- Reduce the reproduction case to the smallest possible input

## 4. Verify

Test the top hypothesis:
- If confirmed, proceed to step 5
- If disproven, cross it off and test the next hypothesis
- If all hypotheses fail, return to step 2 with new information from isolation

## 5. Fix

Apply the smallest change that resolves the root cause:
- Fix the cause, not the symptom
- No drive-by refactors — only touch what's necessary
- If the fix is more than 10 lines, pause and verify the approach
- Confirm the original reproduction case now passes

## 6. Prevent

- Write a regression test that fails without the fix and passes with it
- Search the codebase for the same pattern — if the bug exists here, it likely exists elsewhere
- If the root cause was a missing validation or error path, add it at the boundary where it should have been caught
