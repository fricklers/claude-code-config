#!/usr/bin/env bash
# Stop hook — blocks if there are incomplete todos
# Uses stop_hook_active for loop prevention
set -uo pipefail

input=$(cat)

# Loop prevention: if stop_hook_active is true, always allow stop
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active // false')
[ "$stop_hook_active" = "true" ] && exit 0

# Check for incomplete todos in the transcript
# The transcript contains tool calls — look for TodoWrite with pending items
transcript=$(echo "$input" | jq -r '.transcript // empty')
[ -z "$transcript" ] && exit 0

# Look for todo indicators in recent context
has_pending=$(echo "$input" | jq -r '
  [.transcript[]? |
   select(.role == "assistant") |
   .content[]? |
   select(.type == "text") |
   .text // empty |
   select(test("- \\[ \\]|status.*pending|in_progress"; "i"))
  ] | length
' 2>/dev/null || echo "0")

if [ "$has_pending" -gt 0 ]; then
  echo '{"decision":"block","reason":"There appear to be incomplete todos. Please review and complete pending tasks before stopping, or acknowledge they are intentionally deferred."}'
  exit 0
fi

exit 0
