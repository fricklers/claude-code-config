---
description: Testing conventions
globs:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/test_*"
  - "**/*_test.*"
  - "**/tests/**"
  - "**/__tests__/**"
---

## Structure
Use Arrange-Act-Assert (Given-When-Then) in every test:
1. **Arrange**: Set up test data and dependencies
2. **Act**: Call the function under test
3. **Assert**: Verify the result

## Naming
Descriptive names that state the behavior:
- Good: `rejects expired tokens`, `returns empty array when no results`
- Bad: `test_3`, `it works`, `handles edge case`

## Coverage
Every unit should have tests for:
- **Happy path**: Normal, expected usage
- **Error cases**: Invalid input, network failures, missing data
- **Edge cases**: Empty, null, zero, boundary values

## Rules
- One logical assertion per test (multiple `expect` calls are fine if they verify one behavior)
- Mock external dependencies (network, database, file system) — never the unit under test
- Tests must be deterministic — no reliance on timing, ordering, or external state
- Keep test data minimal — only include what's relevant to the behavior being tested
- Don't test implementation details — test behavior and contracts
