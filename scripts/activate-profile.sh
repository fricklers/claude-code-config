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

DRY_RUN=false

list_profiles() {
  if [ ! -d "$PROFILES_DIR" ]; then
    echo "Error: profiles/ directory not found at $PROFILES_DIR" >&2
    exit 1
  fi

  bold "Available profiles:"
  echo ""
  local found=false
  for profile_file in "$PROFILES_DIR"/*.json; do
    [ -f "$profile_file" ] || continue
    found=true
    local name
    name=$(basename "$profile_file" .json)
    local desc
    desc=$(jq -r '.description // "(no description)"' "$profile_file")
    local plugins
    plugins=$(jq -r '.enabledPlugins | to_entries | map(select(.value)) | map(.key | gsub("@claude-plugins-official";"")) | join(", ")' "$profile_file")
    echo -e "  ${BOLD}$name${NC}"
    echo "    $desc"
    if [ "$plugins" = "" ]; then
      echo "    plugins: (none beyond base)"
    else
      echo "    plugins: $plugins"
    fi
    echo ""
  done
  if ! $found; then
    echo "  (no profiles found in $PROFILES_DIR)"
  fi
}

show_status() {
  # jq filter: prints each plugin, or "(none)" if enabledPlugins is empty/absent
  local plugin_filter='(.enabledPlugins // {}) | if length == 0 then "  (none)" else to_entries[] | "  \(if .value then "✓" else "✗" end) \(.key | gsub("@claude-plugins-official";""))" end'

  bold "Global plugins ($GLOBAL_SETTINGS):"
  if [ -f "$GLOBAL_SETTINGS" ]; then
    jq -r "$plugin_filter" "$GLOBAL_SETTINGS" 2>/dev/null || echo "  (error reading settings)"
  else
    echo "  (no global settings.json found)"
  fi

  echo ""
  local project_settings=".claude/settings.json"
  bold "Project plugins (.claude/settings.json):"
  if [ -f "$project_settings" ]; then
    jq -r "$plugin_filter" "$project_settings" 2>/dev/null || echo "  (error reading settings)"
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

  if [ "$profile" = "base" ]; then
    warn "The 'base' profile is for global use. Run with --global to apply base plugins to $GLOBAL_SETTINGS."
    warn "Base plugins are already active globally; no project settings needed for base."
    exit 1
  fi

  # Read the profile's plugins
  local new_plugins
  new_plugins=$(jq '.enabledPlugins' "$profile_file")

  # If profile has no additions, skip writing the file entirely
  local plugin_count
  plugin_count=$(jq '.enabledPlugins | length' "$profile_file")
  if [ "$plugin_count" -eq 0 ]; then
    ok "Profile '$profile' has no additions beyond base — no project settings needed."
    info "Base plugins are active globally. Nothing to do."
    return 0
  fi

  local project_settings=".claude/settings.json"

  if $DRY_RUN; then
    local plugin_list
    plugin_list=$(jq -r '.enabledPlugins | keys | map(gsub("@claude-plugins-official";"")) | join(", ")' "$profile_file")
    info "Would write $project_settings with: $plugin_list"
    return 0
  fi

  mkdir -p ".claude"

  # Write atomically (same-dir mktemp + mv = rename, never a partial file)
  local tmp_out
  if [ ! -f "$project_settings" ]; then
    # Create minimal project settings with just the profile plugins
    tmp_out=$(mktemp ".claude/settings.tmp.XXXXXX")
    jq -n --argjson plugins "$new_plugins" '{"enabledPlugins": $plugins}' > "$tmp_out"
    mv "$tmp_out" "$project_settings"
  else
    # Backup existing settings to /tmp/ (not .claude/ to avoid git noise), then
    # replace enabledPlugins with profile additions. Previous profile plugins are cleared.
    local backup="/tmp/claude-settings-backup-$(date +%Y%m%d%H%M%S).json"
    cp "$project_settings" "$backup"
    ok "Backed up: $project_settings → $backup"
    tmp_out=$(mktemp ".claude/settings.tmp.XXXXXX")
    jq --argjson plugins "$new_plugins" '.enabledPlugins = $plugins' "$project_settings" > "$tmp_out"
    mv "$tmp_out" "$project_settings"
  fi

  local plugin_list
  plugin_list=$(jq -r '.enabledPlugins | keys | map(gsub("@claude-plugins-official";"")) | join(", ")' "$profile_file")
  ok "Profile '$profile' applied to project: $plugin_list"
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

  # For global: always start from base + add profile's plugins on top
  if [ ! -f "$PROFILES_DIR/base.json" ]; then
    echo "Error: base profile not found at $PROFILES_DIR/base.json" >&2
    exit 1
  fi
  local base_plugins
  base_plugins=$(jq '.enabledPlugins' "$PROFILES_DIR/base.json")

  local profile_plugins
  profile_plugins=$(jq '.enabledPlugins' "$profile_file")

  # Combine base + profile plugins (base is idempotent when profile=base)
  local merged_plugins
  merged_plugins=$(jq -n --argjson base "$base_plugins" --argjson profile "$profile_plugins" '$base + $profile')

  local plugin_list
  plugin_list=$(jq -r 'keys | map(gsub("@claude-plugins-official";"")) | join(", ")' <<< "$merged_plugins")

  if $DRY_RUN; then
    info "Would update $GLOBAL_SETTINGS enabledPlugins to: $plugin_list"
    return 0
  fi

  # Backup before modifying global settings (go to /tmp/ so they get cleaned up by OS)
  local backup="/tmp/claude-global-settings-backup-$(date +%Y%m%d%H%M%S).json"
  cp "$GLOBAL_SETTINGS" "$backup"
  ok "Backed up: $GLOBAL_SETTINGS → $backup"

  # Write atomically: same-dir mktemp + mv = rename, never a partial file
  local tmp_out
  tmp_out=$(mktemp "$(dirname "$GLOBAL_SETTINGS")/settings.tmp.XXXXXX")
  jq --argjson plugins "$merged_plugins" '.enabledPlugins = $plugins' "$GLOBAL_SETTINGS" > "$tmp_out"
  mv "$tmp_out" "$GLOBAL_SETTINGS"

  ok "Global settings updated with profile '$profile': $plugin_list"
}

# Parse args
GLOBAL=false
PROFILE=""
COMMAND=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)      COMMAND="list" ;;
    --status)    COMMAND="status" ;;
    --global)    GLOBAL=true ;;
    --dry-run)   DRY_RUN=true ;;
    -*)          echo "Error: unknown option: $1" >&2; exit 1 ;;
    *)
      if [ -n "$PROFILE" ]; then
        echo "Error: unexpected argument '$1' (profile '$PROFILE' already specified)" >&2
        exit 1
      fi
      PROFILE="$1"
      ;;
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
    [ -f "$f" ] || continue
    echo "  $(basename "$f" .json)"
  done
  exit 1
fi

if $GLOBAL; then
  apply_globally "$PROFILE"
else
  apply_to_project "$PROFILE"
fi
