#!/usr/bin/env bash
# SessionStart > startup — injects git context at session start
# Only fires in git repos; silent exit otherwise
set -uo pipefail

input=$(cat)
session_type=$(echo "$input" | jq -r '.session_type // "new"')

# Only inject on new sessions, not resume/clear/compact
[ "$session_type" != "new" ] && exit 0

# Must be in a git repo
git rev-parse --git-dir &>/dev/null || exit 0

branch=$(git branch --show-current 2>/dev/null || echo "detached")
log=$(git log --oneline -5 2>/dev/null || echo "no commits")
status=$(git status --short 2>/dev/null || echo "")
stash=$(git stash list 2>/dev/null || echo "")

context="Git context:\\n"
context+="Branch: $branch\\n"
context+="Recent commits:\\n$log\\n"

if [ -n "$status" ]; then
  context+="Working tree:\\n$status\\n"
else
  context+="Working tree: clean\\n"
fi

if [ -n "$stash" ]; then
  context+="Stashes:\\n$stash"
fi

echo "{\"additionalContext\":\"$context\"}"
exit 0
