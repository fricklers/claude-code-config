#!/usr/bin/env bash
# Check vendored skills against upstream for staleness
# Exit 0 = all up-to-date, Exit 1 = updates available
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENDORED_JSON="$REPO_DIR/vendored.json"

# Colors (deactivated if not a terminal)
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  RED='\033[0;31m'
  NC='\033[0m'
else
  GREEN='' YELLOW='' RED='' NC=''
fi

if [ ! -f "$VENDORED_JSON" ]; then
  echo -e "${RED}vendored.json not found at $VENDORED_JSON${NC}" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "jq is required but not found" >&2
  exit 1
fi

has_updates=false
count=$(jq '.skills | length' "$VENDORED_JSON")

for i in $(seq 0 $((count - 1))); do
  name=$(jq -r ".skills[$i].name" "$VENDORED_JSON")
  repo=$(jq -r ".skills[$i].repo" "$VENDORED_JSON")
  branch=$(jq -r ".skills[$i].branch" "$VENDORED_JSON")
  pinned=$(jq -r ".skills[$i].commit" "$VENDORED_JSON")

  upstream=$(git ls-remote "$repo" "refs/heads/$branch" 2>/dev/null | awk '{print $1}')

  if [ -z "$upstream" ]; then
    echo -e "  ${RED}[ERROR]${NC}  $name — could not reach $repo"
    continue
  fi

  if [ "$upstream" = "$pinned" ]; then
    echo -e "  ${GREEN}[OK]${NC}      $name — pinned at upstream HEAD ($pinned)"
  else
    echo -e "  ${YELLOW}[UPDATE]${NC}  $name — pinned $pinned, upstream $upstream"
    has_updates=true
  fi
done

if $has_updates; then
  exit 1
fi
