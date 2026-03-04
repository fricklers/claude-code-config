#!/usr/bin/env bash
# Update vendored skill commit hashes in vendored.json from upstream repos
# Only updates the JSON metadata — does NOT copy skill files into the repo.
# Skill files are fetched on demand via install.sh --vendored.
# Usage: update-vendored.sh [skill-name]  (default: update all)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDORED_JSON="$REPO_DIR/vendored.json"

# Colors (deactivated if not a terminal)
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  GREEN='' RED='' NC=''
fi

FILTER_NAME="${1:-}"

if [ ! -f "$VENDORED_JSON" ]; then
  echo -e "${RED}vendored.json not found at $VENDORED_JSON${NC}" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "jq is required but not found" >&2
  exit 1
fi

count=$(jq '.skills | length' "$VENDORED_JSON")

for i in $(seq 0 $((count - 1))); do
  name=$(jq -r ".skills[$i].name" "$VENDORED_JSON")
  repo=$(jq -r ".skills[$i].repo" "$VENDORED_JSON")
  branch=$(jq -r ".skills[$i].branch" "$VENDORED_JSON")

  if [ -n "$FILTER_NAME" ] && [ "$name" != "$FILTER_NAME" ]; then
    continue
  fi

  echo "Checking $name from $repo..."

  # Get latest commit hash from upstream without cloning
  new_commit=$(git ls-remote "$repo" "refs/heads/$branch" 2>/dev/null | awk '{print $1}')
  if [ -z "$new_commit" ]; then
    echo -e "  ${RED}[ERROR]${NC} Failed to get latest commit from $repo" >&2
    continue
  fi

  old_commit=$(jq -r ".skills[$i].commit" "$VENDORED_JSON")
  if [ "$new_commit" = "$old_commit" ]; then
    echo -e "  ${GREEN}[OK]${NC} $name — already at ${new_commit:0:7}"
    continue
  fi

  # Update vendored.json with new commit hash (atomic write)
  tmp_out=$(mktemp "$(dirname "$VENDORED_JSON")/vendored.tmp.XXXXXX")
  jq --arg idx "$i" --arg commit "$new_commit" '
    .skills[($idx | tonumber)].commit = $commit
  ' "$VENDORED_JSON" > "$tmp_out" || { rm -f "$tmp_out"; echo -e "  ${RED}[ERROR]${NC} Failed to update JSON" >&2; continue; }
  mv "$tmp_out" "$VENDORED_JSON"

  echo -e "  ${GREEN}[OK]${NC} Updated $name: ${old_commit:0:7} → ${new_commit:0:7}"
done

if [ -n "$FILTER_NAME" ]; then
  found=$(jq -r --arg name "$FILTER_NAME" '.skills[] | select(.name == $name) | .name' "$VENDORED_JSON")
  if [ -z "$found" ]; then
    echo -e "${RED}Skill '$FILTER_NAME' not found in vendored.json${NC}" >&2
    exit 1
  fi
fi
