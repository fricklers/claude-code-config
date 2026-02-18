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
shellcheck "$REPO_DIR/install.sh" "$REPO_DIR/hooks"/*.sh "$REPO_DIR/scripts"/*.sh
echo "shellcheck passed."

if command -v jq &>/dev/null; then
  echo "Validating JSON..."
  jq empty "$REPO_DIR/vendored.json"
  echo "JSON valid."
fi
