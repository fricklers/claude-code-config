# Contributing

## Submitting Changes

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes
4. Open a pull request against `main`

## Code Standards

### Shell Scripts

- Start every script with `set -euo pipefail`
- Use `jq` for JSON manipulation — no `sed`/`awk` hacks on JSON
- No external dependencies beyond coreutils, `jq`, and standard POSIX tools
- Run `shellcheck` on your scripts before submitting

### JSON

- `settings.json` must validate against its declared `$schema`
- Use `jq .` to format JSON consistently

### General

- Match the existing codebase's patterns and conventions
- Handle error cases explicitly — every external call can fail
- Delete dead code completely; never comment it out
- Keep it minimal — every file must earn its place

## Inclusive Language

This project follows inclusive language guidelines. See the
[Inclusive Language section of CLAUDE.md](CLAUDE.md#inclusive-language) for the full list.

## Commit Messages

Write commit messages that explain **why** the change was made, not just what changed.

## CI

Pull requests are checked by CI, which runs:

- `shellcheck` on all `.sh` files
- JSON schema validation on `settings.json`

Make sure both pass before requesting review.
