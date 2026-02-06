#!/usr/bin/env bash
# PostToolUse > Write|Edit — auto-detects and runs project linter on changed file
# Always exits 0 (PostToolUse hooks are informational only)
set -uo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[ -z "$file_path" ] && exit 0
[ ! -f "$file_path" ] && exit 0

dir=$(dirname "$file_path")

# Walk up to find project root (look for package.json or pyproject.toml)
find_project_root() {
  local d="$1"
  while [ "$d" != "/" ]; do
    [ -f "$d/package.json" ] || [ -f "$d/pyproject.toml" ] || [ -f "$d/setup.cfg" ] && echo "$d" && return
    d=$(dirname "$d")
  done
}

root=$(find_project_root "$dir")
[ -z "$root" ] && exit 0

output=""

# JavaScript/TypeScript: check for lint script in package.json
if [ -f "$root/package.json" ]; then
  has_lint=$(jq -r '.scripts.lint // empty' "$root/package.json" 2>/dev/null)
  if [ -n "$has_lint" ]; then
    output=$(cd "$root" && npx eslint --no-error-on-unmatched-pattern "$file_path" 2>&1) || true
  fi
# Python: prefer ruff, fall back to flake8
elif [ -f "$root/pyproject.toml" ] || [ -f "$root/setup.cfg" ]; then
  if command -v ruff &>/dev/null; then
    output=$(ruff check "$file_path" 2>&1) || true
  elif command -v flake8 &>/dev/null; then
    output=$(flake8 "$file_path" 2>&1) || true
  fi
fi

if [ -n "$output" ]; then
  printf '{"additionalContext":"Lint results for %s:\\n%s"}\n' "$file_path" "$output"
fi

exit 0
