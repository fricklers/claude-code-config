#!/usr/bin/env bash
# PreToolUse > Bash — blocks genuinely destructive commands
# Exit 0 = allow, Exit 2 = block
set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

[ -z "$command" ] && exit 0

# Normalize: collapse whitespace, lowercase for matching
normalized=$(echo "$command" | tr '[:upper:]' '[:lower:]' | tr -s ' ')

block() {
  echo '{"decision":"block","reason":"'"$1"'"}' >&2
  exit 2
}

# rm with force/recursive flags
echo "$normalized" | grep -qE '\brm\b.*(-rf|-fr|--force|--recursive)' && block "Destructive rm detected"

# git force push
echo "$normalized" | grep -qE '\bgit\s+push\b.*(-f|--force)' && block "Force push blocked"

# git reset --hard
echo "$normalized" | grep -qE '\bgit\s+reset\b.*--hard' && block "git reset --hard blocked"

# git clean -f
echo "$normalized" | grep -qE '\bgit\s+clean\b.*-[a-z]*f' && block "git clean -f blocked"

# git checkout . / git restore . (discard all changes)
echo "$normalized" | grep -qE '\bgit\s+(checkout|restore)\s+\.' && block "Discard all changes blocked"

# chmod 777
echo "$normalized" | grep -qE '\bchmod\s+777\b' && block "chmod 777 blocked"

# Pipe to shell (curl|bash, wget|sh, etc.)
echo "$normalized" | grep -qE '\b(curl|wget)\b.*\|\s*(bash|sh|zsh)' && block "Pipe-to-shell blocked"

# Disk destruction
echo "$normalized" | grep -qE '\b(mkfs|dd\s+if=.*of=/dev)' && block "Disk operation blocked"

exit 0
