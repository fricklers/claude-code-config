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

jq -n \
  --arg branch "$branch" \
  --arg log "$log" \
  --arg status "$status" \
  --arg stash "$stash" \
  '{"additionalContext": (
    "Git context:\nBranch: \($branch)\nRecent commits:\n\($log)\n" +
    (if ($status | length) > 0 then "Working tree:\n\($status)\n" else "Working tree: clean\n" end) +
    (if ($stash | length) > 0 then "Stashes:\n\($stash)" else "" end)
  )}'
exit 0
