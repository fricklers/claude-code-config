#!/usr/bin/env bash
# PreToolUse > Read — blocks reading sensitive files
# Outputs JSON permissionDecision on match
set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

[ -z "$file_path" ] && exit 0

basename=$(basename "$file_path")

deny() {
  echo '{"permissionDecision":"deny","reason":"'"$1"'"}'
  exit 0
}

# .env files
case "$basename" in
  .env.local) deny "Blocked: secret file $basename" ;;
  .env|.env.*) deny "Blocked: secret file $basename" ;;
esac

# Key and certificate files
case "$basename" in
  *.pem|*.key|*.p12|*.pfx) deny "Blocked: certificate/key file $basename" ;;
esac

# Credential files
case "$basename" in
  credentials.json|service-account*.json) deny "Blocked: credential file $basename" ;;
  id_rsa|id_rsa.pub|id_ed25519|id_ed25519.pub) deny "Blocked: SSH key $basename" ;;
esac

# Path-based blocks
case "$file_path" in
  */secrets/*|*/.ssh/*) deny "Blocked: sensitive directory in path" ;;
esac

exit 0
