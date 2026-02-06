---
name: handoff
description: Create a session continuity document for resuming work later
---

Create a file called `HANDOFF.md` in the current working directory with the following structure. Fill in each section based on our conversation so far:

```markdown
# Handoff

## Completed
- [List what was accomplished this session, with specific files changed]

## In Progress
- [List anything started but not finished, with current state and what remains]

## Next Steps
1. [Ordered by priority — what should be done next]
2. [Be specific: "Add error handling to src/api/auth.ts:parseToken" not "improve error handling"]

## Decisions Made
- [Key technical decisions and WHY they were made]
- [Include alternatives that were considered and rejected]

## Gotchas
- [Unexpected behavior, quirks, or traps discovered during this session]
- [Include workarounds if any were needed]

## Resume Command
```
claude "Read HANDOFF.md and continue from where we left off"
```
```

After creating the file, confirm the path and summarize the key items.
