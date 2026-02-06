---
name: review
description: "Review code changes. Usage: /review [file-or-dir]. Without arguments, reviews current git diff."
---

Review code for bugs, security issues, performance problems, and missing test coverage.

**If arguments were provided:** Review the specified files or directory.
**If no arguments:** Review the current `git diff` (staged and unstaged changes).

Use the reviewer agent to perform the review. For each finding, categorize as:
- **Critical**: Bugs, security vulnerabilities, data loss risks
- **Warning**: Performance issues, missing error handling
- **Suggestion**: Style, naming, simplification

Include file path, line number, and a concrete fix suggestion for each finding. At the end, give an overall assessment: ship it, fix criticals first, or needs rework.
