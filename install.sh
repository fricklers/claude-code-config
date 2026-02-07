#!/usr/bin/env bash
# claude-code-config installer
# Smart installer with merge support, backup, and interactive/flag-based control
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BACKUP=true
YES=false
DRY_RUN=false
INSTALL_ALL=false
INSTALL_HOOKS=false
INSTALL_SETTINGS=false
INSTALL_AGENTS=false
INSTALL_SKILLS=false
INSTALL_COMMANDS=false
INSTALL_RULES=false
INSTALL_CLAUDE_MD=false
INSTALL_CHECK=false

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  RED='\033[0;31m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  GREEN='' YELLOW='' RED='' BLUE='' BOLD='' NC=''
fi

info()  { echo -e "${BLUE}ℹ${NC} $*"; }
ok()    { echo -e "${GREEN}✓${NC} $*"; }
warn()  { echo -e "${YELLOW}⚠${NC} $*"; }
err()   { echo -e "${RED}✗${NC} $*" >&2; }
bold()  { echo -e "${BOLD}$*${NC}"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --all           Install everything
  --settings      Install settings.json only
  --hooks         Install hooks only
  --agents        Install agents only
  --skills        Install skills only
  --commands      Install commands only
  --rules         Install rules only
  --claude-md     Install CLAUDE.md only
  --check         Check installed skills for staleness (no changes)
  --no-backup     Skip backup of existing files
  --dry-run       Show what would be done without doing it
  -y, --yes       Skip confirmation prompts
  -h, --help      Show this help

Without flags, runs interactive mode.
EOF
  exit 0
}

# Parse arguments
INTERACTIVE=true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)        INSTALL_ALL=true; INTERACTIVE=false ;;
    --settings)   INSTALL_SETTINGS=true; INTERACTIVE=false ;;
    --hooks)      INSTALL_HOOKS=true; INTERACTIVE=false ;;
    --agents)     INSTALL_AGENTS=true; INTERACTIVE=false ;;
    --skills)     INSTALL_SKILLS=true; INTERACTIVE=false ;;
    --commands)   INSTALL_COMMANDS=true; INTERACTIVE=false ;;
    --rules)      INSTALL_RULES=true; INTERACTIVE=false ;;
    --claude-md)  INSTALL_CLAUDE_MD=true; INTERACTIVE=false ;;
    --check)      INSTALL_CHECK=true; INTERACTIVE=false ;;
    --no-backup)  BACKUP=false ;;
    --dry-run)    DRY_RUN=true ;;
    -y|--yes)     YES=true ;;
    -h|--help)    usage ;;
    *)            err "Unknown option: $1"; usage ;;
  esac
  shift
done

if $INSTALL_ALL; then
  INSTALL_SETTINGS=true
  INSTALL_HOOKS=true
  INSTALL_AGENTS=true
  INSTALL_SKILLS=true
  INSTALL_COMMANDS=true
  INSTALL_RULES=true
  INSTALL_CLAUDE_MD=true
fi

# Pre-flight checks
preflight() {
  if ! command -v jq &>/dev/null; then
    err "jq is required but not found. Install it:"
    err "  macOS:  brew install jq"
    err "  Ubuntu: sudo apt install jq"
    err "  Arch:   sudo pacman -S jq"
    exit 1
  fi
}

confirm() {
  $YES && return 0
  local prompt="$1"
  read -r -p "$(echo -e "${YELLOW}?${NC} ${prompt} [Y/n] ")" answer
  [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
}

backup_file() {
  local file="$1"
  if [ -f "$file" ] && $BACKUP; then
    local backup
    backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
    if $DRY_RUN; then
      info "Would backup: $file → $backup"
    else
      cp "$file" "$backup"
      ok "Backed up: $file → $backup"
    fi
  fi
}

copy_file() {
  local src="$1" dest="$2"
  local dest_dir
  dest_dir=$(dirname "$dest")

  if $DRY_RUN; then
    info "Would copy: $src → $dest"
    return
  fi

  mkdir -p "$dest_dir"
  backup_file "$dest"
  cp "$src" "$dest"
  ok "Installed: $dest"
}

# Smart settings.json merge: union permission arrays, append hook groups
merge_settings() {
  local src="$1" dest="$2"

  if [ ! -f "$dest" ]; then
    copy_file "$src" "$dest"
    return
  fi

  if $DRY_RUN; then
    info "Would merge: $src → $dest"
    return
  fi

  backup_file "$dest"

  # Merge using jq: union permissions, combine hooks
  local merged
  merged=$(jq -s '
    def union_arrays: [.[0][], .[1][]] | unique;

    # Start with existing config
    .[0] as $existing | .[1] as $new |

    # Merge permissions
    ($existing.permissions.allow // []) as $ea |
    ($new.permissions.allow // []) as $na |
    ($existing.permissions.deny // []) as $ed |
    ($new.permissions.deny // []) as $nd |

    # Merge hooks by appending new hook groups
    ($existing.hooks // {}) as $eh |
    ($new.hooks // {}) as $nh |

    $existing * $new |
    .permissions.allow = ([$ea[], $na[]] | unique) |
    .permissions.deny = ([$ed[], $nd[]] | unique) |
    .hooks = ($eh * $nh)
  ' "$dest" "$src")

  echo "$merged" | jq '.' > "$dest"
  ok "Merged settings: $dest"
}

# Interactive mode
interactive_menu() {
  echo ""
  bold "claude-code-config installer"
  echo "Target: $CLAUDE_DIR"
  echo ""

  local categories=(
    "settings:settings.json — permissions, hooks, all config"
    "claude-md:CLAUDE.md — coding instructions"
    "hooks:hooks/ — 6 hook scripts (safety, linting, git context)"
    "agents:agents/ — explorer (haiku) + reviewer (sonnet)"
    "skills:skills/ — rigorous-coding, debug, ship-it, scaffold, supabase-postgres"
    "commands:commands/ — /handoff, /review, /debug"
    "rules:rules/ — comment policy + testing conventions + language examples"
  )

  echo "Select what to install:"
  echo ""
  local i=1
  for cat in "${categories[@]}"; do
    local name="${cat%%:*}"
    local desc="${cat#*:}"
    echo "  $i) $desc"
    ((i++))
  done
  echo ""
  echo "  a) Install everything"
  echo "  q) Quit"
  echo ""

  read -r -p "$(echo -e "${YELLOW}?${NC} Choose (comma-separated, e.g., 1,2,3 or a): ")" choices

  case "$choices" in
    q|Q) echo "Cancelled."; exit 0 ;;
    a|A) INSTALL_ALL=true; INSTALL_SETTINGS=true; INSTALL_HOOKS=true; INSTALL_AGENTS=true
          INSTALL_SKILLS=true; INSTALL_COMMANDS=true; INSTALL_RULES=true; INSTALL_CLAUDE_MD=true ;;
    *)
      IFS=',' read -ra selected <<< "$choices"
      for s in "${selected[@]}"; do
        s=$(echo "$s" | tr -d ' ')
        case "$s" in
          1) INSTALL_SETTINGS=true ;;
          2) INSTALL_CLAUDE_MD=true ;;
          3) INSTALL_HOOKS=true ;;
          4) INSTALL_AGENTS=true ;;
          5) INSTALL_SKILLS=true ;;
          6) INSTALL_COMMANDS=true ;;
          7) INSTALL_RULES=true ;;
          *) warn "Unknown selection: $s" ;;
        esac
      done
      ;;
  esac
}

# Install functions
install_settings() {
  info "Installing settings.json..."
  merge_settings "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
}

install_claude_md() {
  info "Installing CLAUDE.md..."
  copy_file "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
}

install_hooks() {
  info "Installing hooks..."
  for hook in "$SCRIPT_DIR"/hooks/*.sh; do
    local name
    name=$(basename "$hook")
    copy_file "$hook" "$CLAUDE_DIR/hooks/$name"
    if ! $DRY_RUN; then
      chmod +x "$CLAUDE_DIR/hooks/$name"
    fi
  done
}

install_agents() {
  info "Installing agents..."
  for agent in "$SCRIPT_DIR"/agents/*.md; do
    local name
    name=$(basename "$agent")
    copy_file "$agent" "$CLAUDE_DIR/agents/$name"
  done
}

install_skills() {
  info "Installing skills..."
  for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    local name
    name=$(basename "$skill_dir")
    if [ -f "$skill_dir/SKILL.md" ]; then
      copy_file "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$name/SKILL.md"
      # Copy additional skill files (AGENTS.md, README.md, etc.)
      for extra in "$skill_dir"*.md; do
        [ "$(basename "$extra")" = "SKILL.md" ] && continue
        [ -f "$extra" ] || continue
        copy_file "$extra" "$CLAUDE_DIR/skills/$name/$(basename "$extra")"
      done
      # Copy references directory if present
      if [ -d "$skill_dir/references" ]; then
        for ref in "$skill_dir"/references/*.md; do
          [ -f "$ref" ] || continue
          copy_file "$ref" "$CLAUDE_DIR/skills/$name/references/$(basename "$ref")"
        done
      fi
    fi
  done
}

install_commands() {
  info "Installing commands..."
  for cmd in "$SCRIPT_DIR"/commands/*.md; do
    local name
    name=$(basename "$cmd")
    copy_file "$cmd" "$CLAUDE_DIR/commands/$name"
  done
}

install_rules() {
  info "Installing rules..."
  for rule in "$SCRIPT_DIR"/rules/*.md; do
    local name
    name=$(basename "$rule")
    copy_file "$rule" "$CLAUDE_DIR/rules/$name"
  done
  echo ""
  info "Language/stack rules (rules/examples/) are NOT auto-installed."
  info "Copy them to your project's .claude/rules/ as needed:"
  for example in "$SCRIPT_DIR"/rules/examples/*.md; do
    [ -f "$example" ] || continue
    info "  cp $SCRIPT_DIR/rules/examples/$(basename "$example") .claude/rules/"
  done
}

# Check installed skills for staleness
check_skills() {
  info "Skills status ($CLAUDE_DIR/skills/):"
  for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    local name
    name=$(basename "$skill_dir")
    local installed_dir="$CLAUDE_DIR/skills/$name"

    if [ ! -d "$installed_dir" ]; then
      echo -e "  ${YELLOW}[MISSING]${NC} $name — not installed"
      continue
    fi

    local repo_hash installed_hash
    repo_hash=$(find "$skill_dir" -type f | sort | xargs shasum 2>/dev/null | shasum | awk '{print $1}')
    installed_hash=$(find "$installed_dir" -type f | sort | xargs shasum 2>/dev/null | shasum | awk '{print $1}')

    if [ "$repo_hash" = "$installed_hash" ]; then
      echo -e "  ${GREEN}[OK]${NC}      $name"
    else
      echo -e "  ${YELLOW}[STALE]${NC}   $name — installed differs from repo"
    fi
  done
}

# Post-install validation
validate() {
  local errors=0

  if [ -f "$CLAUDE_DIR/settings.json" ]; then
    if ! jq empty "$CLAUDE_DIR/settings.json" 2>/dev/null; then
      err "settings.json is not valid JSON!"
      ((errors++))
    else
      ok "settings.json is valid JSON"
    fi
  fi

  for hook in "$CLAUDE_DIR"/hooks/*.sh; do
    [ -f "$hook" ] || continue
    if [ ! -x "$hook" ]; then
      err "$hook is not executable"
      ((errors++))
    fi
  done

  if [ $errors -eq 0 ]; then
    ok "All validations passed"
  else
    err "$errors validation error(s) found"
  fi
}

# Main
main() {
  preflight

  if $INSTALL_CHECK; then
    check_skills
    exit 0
  fi

  if $INTERACTIVE; then
    interactive_menu
  fi

  # Check if anything was selected
  if ! $INSTALL_SETTINGS && ! $INSTALL_CLAUDE_MD && ! $INSTALL_HOOKS && \
     ! $INSTALL_AGENTS && ! $INSTALL_SKILLS && ! $INSTALL_COMMANDS && ! $INSTALL_RULES; then
    warn "Nothing selected to install."
    exit 0
  fi

  echo ""
  if ! $DRY_RUN; then
    confirm "Install to $CLAUDE_DIR?" || { echo "Cancelled."; exit 0; }
  fi
  echo ""

  if $INSTALL_SETTINGS; then install_settings; fi
  if $INSTALL_CLAUDE_MD; then install_claude_md; fi
  if $INSTALL_HOOKS; then install_hooks; fi
  if $INSTALL_AGENTS; then install_agents; fi
  if $INSTALL_SKILLS; then install_skills; fi
  if $INSTALL_COMMANDS; then install_commands; fi
  if $INSTALL_RULES; then install_rules; fi

  if ! $DRY_RUN; then
    echo ""
    validate
  fi

  echo ""
  bold "Done!"
  if $DRY_RUN; then info "(Dry run — no files were modified)"; fi
}

main
