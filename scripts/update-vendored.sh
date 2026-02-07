#!/usr/bin/env bash
# Update vendored skills from upstream repos
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
TMPDIR=""

cleanup() {
  if [ -n "$TMPDIR" ] && [ -d "$TMPDIR" ]; then
    rm -rf "$TMPDIR"
  fi
}
trap cleanup EXIT

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
  path=$(jq -r ".skills[$i].path" "$VENDORED_JSON")

  if [ -n "$FILTER_NAME" ] && [ "$name" != "$FILTER_NAME" ]; then
    continue
  fi

  echo "Updating $name from $repo..."

  TMPDIR=$(mktemp -d)
  if ! git clone --depth=1 --branch "$branch" "$repo" "$TMPDIR/repo" 2>/dev/null; then
    echo -e "  ${RED}[ERROR]${NC} Failed to clone $repo" >&2
    rm -rf "$TMPDIR"
    TMPDIR=""
    continue
  fi

  upstream_path="$TMPDIR/repo/$path"
  if [ ! -d "$upstream_path" ]; then
    echo -e "  ${RED}[ERROR]${NC} Path $path not found in upstream repo" >&2
    rm -rf "$TMPDIR"
    TMPDIR=""
    continue
  fi

  local_path="$REPO_DIR/skills/$name"
  rm -rf "$local_path"
  cp -r "$upstream_path" "$local_path"

  # Get the cloned commit hash
  new_commit=$(git -C "$TMPDIR/repo" rev-parse HEAD)

  # Extract version from SKILL.md frontmatter
  new_version=""
  if [ -f "$local_path/SKILL.md" ]; then
    new_version=$(sed -n 's/^[[:space:]]*version:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/p' "$local_path/SKILL.md" | head -1)
  fi

  # Update vendored.json
  vendored_update=$(jq --arg idx "$i" --arg commit "$new_commit" --arg version "$new_version" '
    .skills[($idx | tonumber)].commit = $commit |
    if $version != "" then .skills[($idx | tonumber)].version = $version else . end
  ' "$VENDORED_JSON")
  echo "$vendored_update" > "$VENDORED_JSON"

  rm -rf "$TMPDIR"
  TMPDIR=""

  echo -e "  ${GREEN}[OK]${NC} Updated $name to $new_commit${new_version:+ (v$new_version)}"
done

if [ -n "$FILTER_NAME" ]; then
  # Verify the requested skill was found
  found=$(jq -r --arg name "$FILTER_NAME" '.skills[] | select(.name == $name) | .name' "$VENDORED_JSON")
  if [ -z "$found" ]; then
    echo -e "${RED}Skill '$FILTER_NAME' not found in vendored.json${NC}" >&2
    exit 1
  fi
fi
