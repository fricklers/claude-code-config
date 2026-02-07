---
name: python-modern
description: Modern Python project workflow. Uses uv, pyproject.toml, ruff, mypy, src layout, and pytest.
---

When this skill is active, follow this 7-step discipline for Python projects:

## 1. Project Structure

Use the src layout with `pyproject.toml` as the single config file:
- `src/<package>/` for source code, `tests/` at the root
- `pyproject.toml` for all metadata, dependencies, and tool config — no `setup.py`, `setup.cfg`, or `requirements.txt`
- `py.typed` marker in the package root for PEP 561 type stub discovery
- `.python-version` file pinning the minimum supported version

## 2. Dependency Management with uv

Use `uv` for fast, reproducible dependency management:
- `uv init` for new projects, `uv add <pkg>` for dependencies
- `uv add --dev pytest ruff mypy` for dev dependencies
- `uv lock` to generate a lockfile, `uv sync` to install from it
- Pin Python version: `uv python pin 3.12`

## 3. Type Everything

Apply type hints systematically:
- All function signatures: parameters and return types — no exceptions
- Use `from __future__ import annotations` at the top of every file
- Prefer `collections.abc` types (`Sequence`, `Mapping`) over concrete types in public signatures
- Use `dataclasses` or Pydantic `BaseModel` for structured data — never raw dicts for domain objects

## 4. Configure Ruff

Set up ruff in `pyproject.toml` for linting and formatting:
```toml
[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "SIM", "TCH", "RUF"]
```
- Run `uv run ruff check --fix .` before every commit
- Run `uv run ruff format .` for consistent formatting
- Fix all violations — no `# noqa` unless the rule is genuinely inapplicable

## 5. Configure Mypy

Set up mypy for strict type checking in `pyproject.toml`:
```toml
[tool.mypy]
strict = true
warn_return_any = true
warn_unreachable = true
```
- Run `uv run mypy src/` — zero errors required
- For third-party packages without stubs, add specific `[[tool.mypy.overrides]]` instead of blanket ignores
- Never use `# type: ignore` without a specific error code: `# type: ignore[override]`

## 6. Write Tests with pytest

Structure tests to mirror the source layout:
- `tests/test_<module>.py` for each source module
- Use `pytest` fixtures for setup/teardown, `conftest.py` for shared fixtures
- Use `pytest.mark.parametrize` for multiple input cases
- Run with `uv run pytest -x --tb=short` — stop on first failure during development

## 7. Verify the Full Pipeline

Before marking work complete, run the full verification chain:
- `uv run ruff check .` — zero lint errors
- `uv run ruff format --check .` — formatting matches
- `uv run mypy src/` — zero type errors
- `uv run pytest` — all tests pass
- If any step fails, fix and re-run the entire chain
