---
description: Python conventions
globs:
  - "**/*.py"
---

## Types
- Use type hints on all function signatures (parameters and return types)
- Use `from __future__ import annotations` for forward references
- Prefer `collections.abc` types (`Sequence`, `Mapping`) over concrete types in signatures
- Use `TypeVar` and `Generic` for reusable typed containers

## Patterns
- Use dataclasses or Pydantic models over plain dicts for structured data
- Prefer `pathlib.Path` over `os.path` for file operations
- Use context managers (`with`) for resource management — files, connections, locks
- Use `enum.Enum` for fixed sets of values, not string constants

## Error Handling
- Create domain-specific exception hierarchies: `class AppError(Exception): ...`
- Catch specific exceptions, never bare `except:` or `except Exception:`
- Use `raise ... from err` to preserve the exception chain
- Validate at boundaries (public APIs, user input), trust internal code

## Async
- Use `asyncio` consistently — don't mix sync and async I/O
- Use `asyncio.gather` for independent async operations
- Use `asyncio.TaskGroup` (3.11+) for structured concurrency
- Always set timeouts on external calls: `asyncio.wait_for(coro, timeout=10)`
