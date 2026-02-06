---
description: Comment policy — code should be self-documenting
globs: "*"
---

## Unacceptable Comments
- Restating what the code does: `// increment counter` above `counter++`
- Commented-out code — delete it, git has history
- Obvious comments: `// constructor`, `// returns the result`
- Bare TODOs without context: `// TODO: fix this`

## Acceptable Comments
- **WHY** explanations: business logic rationale, non-obvious constraints
- Warnings about gotchas: "This must run before X because..."
- Links to specs, tickets, or documentation
- BDD-style test descriptions
- Public API documentation (JSDoc, docstrings)

## TODO Format
```
// TODO(username): description — see #123
```
Every TODO must have an owner and a tracking reference. Orphan TODOs become permanent.
