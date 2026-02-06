#!/usr/bin/env bash
# PreToolUse > Bash — escalates git commit/push to user confirmation
# Uses "ask" decision so user sees a confirmation dialog
set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

[ -z "$command" ] && exit 0

normalized=$(echo "$command" | tr '[:upper:]' '[:lower:]' | tr -s ' ')

ask() {
  echo '{"decision":"ask","reason":"'"$1"'"}'
  exit 0
}

# git commit (any form)
echo "$normalized" | grep -qE '\bgit\s+commit\b' && ask "Git commit detected — confirm?"

# git push (non-force, since force is blocked by block-dangerous.sh)
echo "$normalized" | grep -qE '\bgit\s+push\b' && ask "Git push detected — confirm?"

exit 0
