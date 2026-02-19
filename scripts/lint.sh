#!/usr/bin/env bash
# Run the same checks that CI runs locally.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v shellcheck &>/dev/null; then
  echo "Error: shellcheck is required. Install with: brew install shellcheck" >&2
  exit 1
fi

echo "Running shellcheck..."
# Collect targets via find so empty hook/script dirs don't expand to a literal glob pattern
shellcheck_targets=("$REPO_DIR/install.sh")
while IFS= read -r f; do
  shellcheck_targets+=("$f")
done < <(find "$REPO_DIR/hooks" "$REPO_DIR/scripts" -name '*.sh' -type f 2>/dev/null | sort)
shellcheck "${shellcheck_targets[@]}"
echo "shellcheck passed."

if command -v jq &>/dev/null; then
  echo "Validating JSON..."
  jq empty "$REPO_DIR/vendored.json"
  echo "JSON valid."
fi
