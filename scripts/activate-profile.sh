#!/usr/bin/env bash
# Activate a plugin profile for a project or globally.
#
# Usage:
#   ./scripts/activate-profile.sh <profile>              # apply to current project
#   ./scripts/activate-profile.sh <profile> --global     # apply base + profile to ~/.claude/settings.json
#   ./scripts/activate-profile.sh --global base          # reset global to base plugins only
#   ./scripts/activate-profile.sh --list                 # list available profiles
#   ./scripts/activate-profile.sh --status               # show active plugins in current project + global
#
# Profiles live in profiles/ next to this script.
# Base plugins are always active globally; profile additions go in .claude/settings.json
# of the current project (or globally with --global).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILES_DIR="$REPO_DIR/profiles"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
GLOBAL_SETTINGS="$CLAUDE_DIR/settings.json"

# Colors
if [ -t 1 ]; then
  GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
  GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

info() { echo -e "${BLUE}ℹ${NC} $*"; }
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
bold() { echo -e "${BOLD}$*${NC}"; }

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq" >&2
  exit 1
fi

list_profiles() {
  bold "Available profiles:"
  echo ""
  for profile_file in "$PROFILES_DIR"/*.json; do
    local name
    name=$(basename "$profile_file" .json)
    local desc
    desc=$(jq -r '.description // "(no description)"' "$profile_file")
    local plugins
    plugins=$(jq -r '.enabledPlugins | keys | map(gsub("@claude-plugins-official";"")) | join(", ")' "$profile_file")
    echo -e "  ${BOLD}$name${NC}"
    echo "    $desc"
    if [ "$plugins" = "" ]; then
      echo "    plugins: (none beyond base)"
    else
      echo "    plugins: $plugins"
    fi
    echo ""
  done
}

show_status() {
  bold "Global plugins (~/.claude/settings.json):"
  if [ -f "$GLOBAL_SETTINGS" ]; then
    jq -r '.enabledPlugins // {} | to_entries[] | "  \(if .value then "✓" else "✗" end) \(.key | gsub("@claude-plugins-official";""))"' "$GLOBAL_SETTINGS" 2>/dev/null || echo "  (none)"
  else
    echo "  (no global settings.json found)"
  fi

  echo ""
  local project_settings=".claude/settings.json"
  bold "Project plugins (.claude/settings.json):"
  if [ -f "$project_settings" ]; then
    jq -r '.enabledPlugins // {} | to_entries[] | "  \(if .value then "✓" else "✗" end) \(.key | gsub("@claude-plugins-official";""))"' "$project_settings" 2>/dev/null || echo "  (none)"
  else
    echo "  (no project settings.json found — using global only)"
  fi
}

apply_to_project() {
  local profile="$1"
  local profile_file="$PROFILES_DIR/${profile}.json"

  if [ ! -f "$profile_file" ]; then
    echo "Error: profile '$profile' not found. Run --list to see available profiles." >&2
    exit 1
  fi

  local project_settings=".claude/settings.json"
  mkdir -p ".claude"

  # Read the profile's plugins
  local new_plugins
  new_plugins=$(jq '.enabledPlugins' "$profile_file")

  if [ ! -f "$project_settings" ]; then
    # Create minimal project settings with just the profile plugins
    jq -n --argjson plugins "$new_plugins" '{"enabledPlugins": $plugins}' > "$project_settings"
  else
    # Merge: keep existing project settings, replace enabledPlugins with profile
    # Plugins from a previous profile are cleared; only this profile's additions remain
    local updated
    updated=$(jq --argjson plugins "$new_plugins" '.enabledPlugins = $plugins' "$project_settings")
    echo "$updated" > "$project_settings"
  fi

  local plugin_list
  plugin_list=$(jq -r '.enabledPlugins | keys | map(gsub("@claude-plugins-official";"")) | join(", ")' "$profile_file")

  if [ -z "$plugin_list" ]; then
    ok "Profile '$profile' applied to project (no additions beyond base)"
  else
    ok "Profile '$profile' applied to project: $plugin_list"
  fi
  info "Base plugins remain active from global settings."
  info "Project settings: $(pwd)/$project_settings"
}

apply_globally() {
  local profile="$1"
  local profile_file="$PROFILES_DIR/${profile}.json"

  if [ ! -f "$profile_file" ]; then
    echo "Error: profile '$profile' not found. Run --list to see available profiles." >&2
    exit 1
  fi

  if [ ! -f "$GLOBAL_SETTINGS" ]; then
    echo "Error: global settings.json not found at $GLOBAL_SETTINGS" >&2
    exit 1
  fi

  # For global: merge base enabledPlugins with profile enabledPlugins
  local base_plugins
  base_plugins=$(jq '.enabledPlugins' "$PROFILES_DIR/base.json")

  local profile_plugins
  profile_plugins=$(jq '.enabledPlugins' "$profile_file")

  # Combine base + profile plugins
  local merged_plugins
  merged_plugins=$(jq -n --argjson base "$base_plugins" --argjson profile "$profile_plugins" '$base + $profile')

  local updated
  updated=$(jq --argjson plugins "$merged_plugins" '.enabledPlugins = $plugins' "$GLOBAL_SETTINGS")
  echo "$updated" > "$GLOBAL_SETTINGS"

  local plugin_list
  plugin_list=$(jq -r 'keys | map(gsub("@claude-plugins-official";"")) | join(", ")' <<< "$merged_plugins")
  ok "Global settings updated with profile '$profile': $plugin_list"
}

# Parse args
GLOBAL=false
PROFILE=""
COMMAND=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)   COMMAND="list" ;;
    --status) COMMAND="status" ;;
    --global) GLOBAL=true ;;
    -*)       echo "Unknown option: $1" >&2; exit 1 ;;
    *)        PROFILE="$1" ;;
  esac
  shift
done

case "$COMMAND" in
  list)   list_profiles; exit 0 ;;
  status) show_status; exit 0 ;;
esac

if [ -z "$PROFILE" ]; then
  echo "Usage: $(basename "$0") <profile> [--global]"
  echo "       $(basename "$0") --list"
  echo "       $(basename "$0") --status"
  echo ""
  echo "Available profiles:"
  for f in "$PROFILES_DIR"/*.json; do
    echo "  $(basename "$f" .json)"
  done
  exit 1
fi

if $GLOBAL; then
  apply_globally "$PROFILE"
else
  apply_to_project "$PROFILE"
fi
