#!/usr/bin/env bash
# claude-code-config installer
# Smart installer with merge support, backup, and interactive/flag-based control
# Supports lazy-fetching vendored skills from GitHub at pinned commits
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
INSTALL_VENDORED=false
INSTALL_SKILL_NAME=""
INSTALL_LIST_VENDORED=false
INSTALL_PROJECT_SKILLS=false
ACTIVATE_PROFILE=""
ACTIVATE_PROFILE_GLOBAL=false

# Colors (turned off if not a terminal)
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
  --all              Install everything (custom skills only, no network fetch)
  --settings         Install settings.json only
  --hooks            Install hooks only
  --agents           Install agents only
  --skills           Install custom skills only (from skills/)
  --commands         Install commands only
  --rules            Install rules only
  --claude-md        Install CLAUDE.md only
  --vendored         Fetch + install ALL vendored skills from GitHub
  --skill <name>     Fetch + install one vendored skill by name
  --list-vendored    List available vendored skills with install status
  --project-skills   Fetch vendored skills declared in .claude/vendored-skills.json
  --check            Check installed skills for staleness (no changes)
  --profile <name>   Activate plugin profile for current project (see profiles/)
  --profile-global <name>  Activate plugin profile globally in ~/.claude/settings.json
  --list-profiles    List available plugin profiles
  --no-backup        Skip backup of existing files
  --dry-run          Show what would be done without doing it
  -y, --yes          Skip confirmation prompts
  -h, --help         Show this help

Without flags, runs interactive mode.
EOF
  exit 0
}

# Parse arguments
INTERACTIVE=true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)             INSTALL_ALL=true; INTERACTIVE=false ;;
    --settings)        INSTALL_SETTINGS=true; INTERACTIVE=false ;;
    --hooks)           INSTALL_HOOKS=true; INTERACTIVE=false ;;
    --agents)          INSTALL_AGENTS=true; INTERACTIVE=false ;;
    --skills)          INSTALL_SKILLS=true; INTERACTIVE=false ;;
    --commands)        INSTALL_COMMANDS=true; INTERACTIVE=false ;;
    --rules)           INSTALL_RULES=true; INTERACTIVE=false ;;
    --claude-md)       INSTALL_CLAUDE_MD=true; INTERACTIVE=false ;;
    --vendored)        INSTALL_VENDORED=true; INTERACTIVE=false ;;
    --skill)
      shift
      if [[ $# -eq 0 ]]; then
        err "--skill requires a skill name"
        exit 1
      fi
      INSTALL_SKILL_NAME="$1"
      INTERACTIVE=false
      ;;
    --list-vendored)   INSTALL_LIST_VENDORED=true; INTERACTIVE=false ;;
    --project-skills)  INSTALL_PROJECT_SKILLS=true; INTERACTIVE=false ;;
    --profile)
      shift
      if [[ $# -eq 0 ]]; then err "--profile requires a profile name"; exit 1; fi
      ACTIVATE_PROFILE="$1"; INTERACTIVE=false ;;
    --profile-global)
      shift
      if [[ $# -eq 0 ]]; then err "--profile-global requires a profile name"; exit 1; fi
      ACTIVATE_PROFILE="$1"; ACTIVATE_PROFILE_GLOBAL=true; INTERACTIVE=false ;;
    --list-profiles)
      "$SCRIPT_DIR/scripts/activate-profile.sh" --list; exit $? ;;
    --check)           INSTALL_CHECK=true; INTERACTIVE=false ;;
    --no-backup)       BACKUP=false ;;
    --dry-run)         DRY_RUN=true ;;
    -y|--yes)          YES=true ;;
    -h|--help)         usage ;;
    *)                 err "Unknown option: $1"; err "Run '$(basename "$0") --help' for usage."; exit 1 ;;
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
  if [ ! -f "$VENDORED_JSON" ]; then
    err "vendored.json not found at $VENDORED_JSON"
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

  # Merge using jq: union permissions, combine hooks, take new enabledPlugins as authoritative
  # enabledPlugins is NOT merged — the repo's settings.json defines the base plugin set exactly.
  # Use activate-profile.sh to add project-specific plugins on top.
  # Write atomically: same-dir mktemp + mv = rename, never a partial file.
  local tmp_out
  tmp_out=$(mktemp "$(dirname "$dest")/settings.tmp.XXXXXX")
  jq -s '
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
    .hooks = ($eh * $nh) |
    # enabledPlugins: take new file as authoritative so --settings resets to base profile
    if $new.enabledPlugins then .enabledPlugins = $new.enabledPlugins else . end
  ' "$dest" "$src" > "$tmp_out"
  mv "$tmp_out" "$dest"
  ok "Merged settings: $dest"
}

# --- Vendored skill fetch infrastructure ---

VENDORED_JSON="$SCRIPT_DIR/vendored.json"

# Extract a field from vendored.json for a given skill name
vendored_field() {
  local skill_name="$1" field="$2"
  jq -r --arg name "$skill_name" '.skills[] | select(.name == $name) | .'"$field" "$VENDORED_JSON"
}

# Check if a skill name exists in vendored.json
is_vendored_skill() {
  local skill_name="$1"
  jq -e --arg name "$skill_name" '.skills[] | select(.name == $name)' "$VENDORED_JSON" &>/dev/null
}

# Get all vendored skill names
vendored_skill_names() {
  jq -r '.skills[].name' "$VENDORED_JSON"
}

# Convert repo URL to GitHub owner/repo format
# "https://github.com/warpdotdev/oz-skills.git" -> "warpdotdev/oz-skills"
repo_to_github() {
  local repo="$1"
  echo "$repo" | sed -E 's|https://github.com/||; s|\.git$||'
}

# Download a GitHub tarball to a temp file
# Returns the path to the downloaded tarball
download_tarball() {
  local github_repo="$1" commit="$2" dest_file="$3"
  local url="https://api.github.com/repos/${github_repo}/tarball/${commit}"
  local http_code

  local curl_args=(-fsSL --max-time 120 -o "$dest_file" -w "%{http_code}")
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    curl_args+=(-H "Authorization: token $GITHUB_TOKEN")
  fi

  http_code=$(curl "${curl_args[@]}" "$url" 2>/dev/null) || true

  if [ ! -f "$dest_file" ] || [ ! -s "$dest_file" ]; then
    if [ "${http_code:-}" = "403" ]; then
      err "Rate limited by GitHub API (HTTP 403)."
      err "Set GITHUB_TOKEN to authenticate: export GITHUB_TOKEN=ghp_..."
      return 1
    fi
    err "Failed to download tarball from $url (HTTP ${http_code:-unknown})"
    return 1
  fi
  return 0
}

# Extract a skill's files from a tarball into the target directory
# Tarball contents are under a dynamic prefix like "owner-repo-shortsha/"
extract_skill_from_tarball() {
  local tarball="$1" skill_path="$2" dest_dir="$3"
  local tmp_extract
  tmp_extract=$(mktemp -d)

  # Extract the tarball
  tar xzf "$tarball" -C "$tmp_extract" 2>/dev/null || {
    err "Failed to extract tarball"
    rm -rf "$tmp_extract"
    return 1
  }

  # Find the top-level directory (dynamic prefix)
  local prefix
  prefix=$(basename "$(find "$tmp_extract" -mindepth 1 -maxdepth 1 -type d -print -quit)")

  local source_dir="$tmp_extract/$prefix/$skill_path"
  if [ ! -d "$source_dir" ]; then
    err "Skill path '$skill_path' not found in tarball"
    rm -rf "$tmp_extract"
    return 1
  fi

  # Atomically install: stage in sibling temp dir, swap, then clean up
  local tmp_dest
  tmp_dest=$(mktemp -d)
  cp -R "$source_dir/." "$tmp_dest/"

  mkdir -p "$(dirname "$dest_dir")"
  # Stage to a sibling of dest_dir (same filesystem) for safe rename
  local staged="${dest_dir}.new.$$"
  mv "$tmp_dest" "$staged" || {
    err "Failed to stage skill to $staged"
    rm -rf "$tmp_dest" "$staged" 2>/dev/null
    return 1
  }
  # Safe swap: rename old out of the way, rename new into place, delete old
  if [ -d "$dest_dir" ]; then
    local old_backup="${dest_dir}.old.$$"
    mv "$dest_dir" "$old_backup"
    mv "$staged" "$dest_dir"
    rm -rf "$old_backup"
  else
    mv "$staged" "$dest_dir"
  fi

  rm -rf "$tmp_extract"
  return 0
}

# Write metadata file for a vendored skill
write_vendored_meta() {
  local skill_name="$1" dest_dir="$2"
  local repo commit installed_at
  repo=$(vendored_field "$skill_name" "repo")
  commit=$(vendored_field "$skill_name" "commit")
  installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # Use jq to construct JSON so special characters in values don't corrupt the file
  jq -n \
    --arg name "$skill_name" \
    --arg repo "$repo" \
    --arg commit "$commit" \
    --arg installed_at "$installed_at" \
    '{"name": $name, "repo": $repo, "commit": $commit, "installed_at": $installed_at}' \
    > "$dest_dir/.vendored-meta.json"
}

# Check if a vendored skill is already installed at the correct commit
vendored_skill_up_to_date() {
  local skill_name="$1"
  local installed_dir="$CLAUDE_DIR/skills/$skill_name"
  local meta_file="$installed_dir/.vendored-meta.json"

  if [ ! -f "$meta_file" ]; then
    return 1
  fi

  local installed_commit expected_commit
  installed_commit=$(jq -r '.commit' "$meta_file" 2>/dev/null)
  expected_commit=$(vendored_field "$skill_name" "commit")

  [ "$installed_commit" = "$expected_commit" ]
}

# Fetch and install a single vendored skill
fetch_skill() {
  local skill_name="$1"

  if ! is_vendored_skill "$skill_name"; then
    err "Unknown vendored skill: $skill_name"
    err "Run --list-vendored to see available skills."
    return 1
  fi

  if vendored_skill_up_to_date "$skill_name"; then
    local commit
    commit=$(vendored_field "$skill_name" "commit")
    echo -e "  ${GREEN}[OK]${NC} $skill_name — already at ${commit:0:7}"
    return 0
  fi

  local repo skill_path commit github_repo
  repo=$(vendored_field "$skill_name" "repo")
  skill_path=$(vendored_field "$skill_name" "path")
  commit=$(vendored_field "$skill_name" "commit")
  github_repo=$(repo_to_github "$repo")

  if $DRY_RUN; then
    info "Would fetch: $skill_name from $github_repo@${commit:0:7}"
    return 0
  fi

  local tarball
  tarball=$(mktemp)

  if ! download_tarball "$github_repo" "$commit" "$tarball"; then
    rm -f "$tarball"
    return 1
  fi

  local dest_dir="$CLAUDE_DIR/skills/$skill_name"
  if ! extract_skill_from_tarball "$tarball" "$skill_path" "$dest_dir"; then
    rm -f "$tarball"
    return 1
  fi

  write_vendored_meta "$skill_name" "$dest_dir"
  rm -f "$tarball"
  ok "$skill_name — fetched from $github_repo@${commit:0:7}"
  return 0
}

# Fetch all vendored skills, batched by repo+commit to minimize downloads
# Uses temp files for grouping (bash 3.x compatible, no associative arrays)
fetch_vendored_batch() {
  local skill_names=("$@")
  local succeeded=0 failed=0 skipped=0

  # Group skills by repo+commit using a temp file
  # Each line: "github_repo|commit|skill_name|skill_path"
  local batch_file
  batch_file=$(mktemp)

  for skill_name in "${skill_names[@]}"; do
    if ! is_vendored_skill "$skill_name"; then
      err "Unknown vendored skill: $skill_name"
      failed=$((failed + 1))
      continue
    fi

    if vendored_skill_up_to_date "$skill_name"; then
      local commit
      commit=$(vendored_field "$skill_name" "commit")
      echo -e "  ${GREEN}[OK]${NC} $skill_name — already at ${commit:0:7}"
      skipped=$((skipped + 1))
      continue
    fi

    local repo skill_path commit github_repo
    repo=$(vendored_field "$skill_name" "repo")
    skill_path=$(vendored_field "$skill_name" "path")
    commit=$(vendored_field "$skill_name" "commit")
    github_repo=$(repo_to_github "$repo")

    echo "${github_repo}|${commit}|${skill_name}|${skill_path}" >> "$batch_file"
  done

  # Get unique repo+commit pairs
  local unique_keys
  unique_keys=$(cut -d'|' -f1,2 "$batch_file" 2>/dev/null | sort -u)

  while IFS= read -r key; do
    [ -z "$key" ] && continue
    local github_repo="${key%%|*}"
    local commit="${key#*|}"

    if $DRY_RUN; then
      while IFS='|' read -r _gr _cm name _path; do
        info "Would fetch: $name from $github_repo@${commit:0:7}"
      done < <(awk -F'|' -v r="$github_repo" -v c="$commit" '$1 == r && $2 == c' "$batch_file")
      continue
    fi

    info "Downloading $github_repo@${commit:0:7}..."
    local tarball
    tarball=$(mktemp)

    if ! download_tarball "$github_repo" "$commit" "$tarball"; then
      rm -f "$tarball"
      while IFS='|' read -r _gr _cm name _path; do
        err "$name — download failed"
        failed=$((failed + 1))
      done < <(awk -F'|' -v r="$github_repo" -v c="$commit" '$1 == r && $2 == c' "$batch_file")
      continue
    fi

    while IFS='|' read -r _gr _cm name path; do
      local dest_dir="$CLAUDE_DIR/skills/$name"

      if extract_skill_from_tarball "$tarball" "$path" "$dest_dir"; then
        write_vendored_meta "$name" "$dest_dir"
        ok "$name — installed from $github_repo@${commit:0:7}"
        succeeded=$((succeeded + 1))
      else
        err "$name — extraction failed"
        failed=$((failed + 1))
      fi
    done < <(awk -F'|' -v r="$github_repo" -v c="$commit" '$1 == r && $2 == c' "$batch_file")

    rm -f "$tarball"
  done <<< "$unique_keys"

  rm -f "$batch_file"

  echo ""
  if [ $failed -gt 0 ]; then
    warn "Vendored skills: $succeeded installed, $skipped up-to-date, $failed failed"
    return 1
  else
    ok "Vendored skills: $succeeded installed, $skipped up-to-date"
  fi
}

# List all vendored skills with install status
list_vendored() {
  bold "Vendored skills (from vendored.json):"
  echo ""
  while IFS= read -r skill_name; do
    local installed_dir="$CLAUDE_DIR/skills/$skill_name"
    local meta_file="$installed_dir/.vendored-meta.json"
    local expected_commit
    expected_commit=$(vendored_field "$skill_name" "commit")

    if [ ! -d "$installed_dir" ]; then
      echo -e "  ${YELLOW}[MISSING]${NC}  $skill_name"
    elif [ ! -f "$meta_file" ]; then
      echo -e "  ${YELLOW}[NO META]${NC} $skill_name — installed but no metadata"
    else
      local installed_commit
      installed_commit=$(jq -r '.commit' "$meta_file" 2>/dev/null)
      if [ "$installed_commit" = "$expected_commit" ]; then
        echo -e "  ${GREEN}[OK]${NC}       $skill_name — at ${installed_commit:0:7}"
      else
        echo -e "  ${YELLOW}[STALE]${NC}    $skill_name — installed ${installed_commit:0:7}, pinned ${expected_commit:0:7}"
      fi
    fi
  done < <(vendored_skill_names)
}

# Install vendored skills declared in a project's .claude/vendored-skills.json
install_project_skills() {
  local project_file=".claude/vendored-skills.json"

  if [ ! -f "$project_file" ]; then
    err "No $project_file found in current directory."
    err "Create one with: { \"skills\": [\"ci-fix\", \"create-pull-request\"] }"
    exit 1
  fi

  local skill_list
  skill_list=$(jq -r '.skills[]' "$project_file" 2>/dev/null) || {
    err "Invalid JSON in $project_file"
    exit 1
  }

  if [ -z "$skill_list" ]; then
    warn "No skills listed in $project_file"
    return
  fi

  info "Fetching vendored skills from $project_file..."
  local names=()
  while IFS= read -r name; do
    names+=("$name")
  done <<< "$skill_list"

  fetch_vendored_batch "${names[@]}"
}

# --- End vendored skill fetch infrastructure ---

# Interactive mode
interactive_menu() {
  echo ""
  bold "claude-code-config installer"
  echo "Target: $CLAUDE_DIR"
  echo ""

  local custom_count
  custom_count=$(find "$SCRIPT_DIR"/skills/ -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  local vendored_count
  vendored_count=$(jq '.skills | length' "$VENDORED_JSON")

  local categories=(
    "settings:settings.json — permissions, hooks, all config"
    "claude-md:CLAUDE.md — coding instructions"
    "hooks:hooks/ — 6 hook scripts (safety, linting, git context)"
    "agents:agents/ — explorer, reviewer, tester, security-reviewer, tech-docs-writer"
    "skills:skills/ — $custom_count custom skills (coding, debug, languages, frameworks)"
    "commands:commands/ — /handoff, /review, /debug"
    "rules:rules/ — comment policy + testing conventions + language examples"
    "vendored:vendored skills — $vendored_count skills fetched from GitHub (ci-fix, mcp-builder, ...)"
  )

  echo "Select what to install:"
  echo ""
  local i=1
  for cat in "${categories[@]}"; do
    local name="${cat%%:*}"
    local desc="${cat#*:}"
    echo "  $i) $desc"
    i=$((i + 1))
  done
  echo ""
  echo "  a) Install everything (custom only, no network fetch)"
  echo "  p) Activate plugin profile (interactive)"
  echo "  q) Quit"
  echo ""

  read -r -p "$(echo -e "${YELLOW}?${NC} Choose (comma-separated, e.g., 1,2,3 or a): ")" choices

  case "$choices" in
    q|Q) echo "Cancelled."; exit 0 ;;
    p|P)
      "$SCRIPT_DIR/scripts/activate-profile.sh" --list
      echo ""
      read -r -p "$(echo -e "${YELLOW}?${NC} Profile name (or 'q' to cancel): ")" chosen_profile
      if [[ "$chosen_profile" == "q" || -z "$chosen_profile" ]]; then echo "Cancelled."; exit 0; fi
      read -r -p "$(echo -e "${YELLOW}?${NC} Apply globally? [y/N] ")" global_choice
      local dry_flag=""
      $DRY_RUN && dry_flag="--dry-run"
      if [[ "$global_choice" =~ ^[Yy] ]]; then
        "$SCRIPT_DIR/scripts/activate-profile.sh" "$chosen_profile" --global $dry_flag
      else
        "$SCRIPT_DIR/scripts/activate-profile.sh" "$chosen_profile" $dry_flag
      fi
      exit $?
      ;;
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
          8) INSTALL_VENDORED=true ;;
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
    [ -f "$hook" ] || continue
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
    [ -f "$agent" ] || continue
    local name
    name=$(basename "$agent")
    copy_file "$agent" "$CLAUDE_DIR/agents/$name"
  done
}

install_skills() {
  info "Installing custom skills..."
  for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    local name
    name=$(basename "$skill_dir")
    if [ -f "$skill_dir/SKILL.md" ]; then
      copy_file "$skill_dir/SKILL.md" "$CLAUDE_DIR/skills/$name/SKILL.md"
      for extra in "$skill_dir/"*.md; do
        [ "$(basename "$extra")" = "SKILL.md" ] && continue
        [ -f "$extra" ] || continue
        copy_file "$extra" "$CLAUDE_DIR/skills/$name/$(basename "$extra")"
      done
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
    [ -f "$cmd" ] || continue
    local name
    name=$(basename "$cmd")
    copy_file "$cmd" "$CLAUDE_DIR/commands/$name"
  done
}

install_rules() {
  info "Installing rules..."
  for rule in "$SCRIPT_DIR"/rules/*.md; do
    [ -f "$rule" ] || continue
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
  # Check custom skills (file hash comparison)
  info "Custom skills status ($CLAUDE_DIR/skills/):"
  local has_custom=false
  for skill_dir in "$SCRIPT_DIR"/skills/*/; do
    [ -d "$skill_dir" ] || continue
    has_custom=true
    local name
    name=$(basename "$skill_dir")
    local installed_dir="$CLAUDE_DIR/skills/$name"

    if [ ! -d "$installed_dir" ]; then
      echo -e "  ${YELLOW}[MISSING]${NC} $name — not installed"
      continue
    fi

    local repo_hash installed_hash
    repo_hash=$(cd "$skill_dir" && find . -type f -not -name '.vendored-meta.json' | sort | xargs shasum 2>/dev/null | shasum | awk '{print $1}')
    installed_hash=$(cd "$installed_dir" && find . -type f -not -name '.vendored-meta.json' | sort | xargs shasum 2>/dev/null | shasum | awk '{print $1}')

    if [ "$repo_hash" = "$installed_hash" ]; then
      echo -e "  ${GREEN}[OK]${NC}      $name"
    else
      echo -e "  ${YELLOW}[STALE]${NC}   $name — installed differs from repo"
    fi
  done
  if ! $has_custom; then
    echo "  (none)"
  fi

  # Check vendored skills (commit hash comparison, no network needed)
  echo ""
  info "Vendored skills status (commit comparison):"
  while IFS= read -r skill_name; do
    local installed_dir="$CLAUDE_DIR/skills/$skill_name"
    local meta_file="$installed_dir/.vendored-meta.json"
    local expected_commit
    expected_commit=$(vendored_field "$skill_name" "commit")

    if [ ! -d "$installed_dir" ]; then
      echo -e "  ${YELLOW}[MISSING]${NC} $skill_name — not installed (run --vendored to fetch)"
      continue
    fi

    if [ ! -f "$meta_file" ]; then
      echo -e "  ${YELLOW}[NO META]${NC} $skill_name — installed but missing metadata"
      continue
    fi

    local installed_commit
    installed_commit=$(jq -r '.commit' "$meta_file" 2>/dev/null)
    if [ "$installed_commit" = "$expected_commit" ]; then
      echo -e "  ${GREEN}[OK]${NC}      $skill_name — at ${installed_commit:0:7}"
    else
      echo -e "  ${YELLOW}[STALE]${NC}   $skill_name — installed ${installed_commit:0:7}, pinned ${expected_commit:0:7}"
    fi
  done < <(vendored_skill_names)
}

# Post-install validation
validate() {
  local errors=0

  if [ -f "$CLAUDE_DIR/settings.json" ]; then
    if ! jq empty "$CLAUDE_DIR/settings.json" 2>/dev/null; then
      err "settings.json is not valid JSON!"
      errors=$((errors + 1))
    else
      ok "settings.json is valid JSON"
    fi
  fi

  for hook in "$CLAUDE_DIR"/hooks/*.sh; do
    [ -f "$hook" ] || continue
    if [ ! -x "$hook" ]; then
      err "$hook is not executable"
      errors=$((errors + 1))
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
  # Profile activation doesn't need vendored.json — handle before preflight
  if [ -n "$ACTIVATE_PROFILE" ]; then
    if ! command -v jq &>/dev/null; then
      err "jq is required but not found. Install it: brew install jq"
      exit 1
    fi
    local dry_flag=""
    $DRY_RUN && dry_flag="--dry-run"
    if $ACTIVATE_PROFILE_GLOBAL; then
      "$SCRIPT_DIR/scripts/activate-profile.sh" "$ACTIVATE_PROFILE" --global $dry_flag
    else
      "$SCRIPT_DIR/scripts/activate-profile.sh" "$ACTIVATE_PROFILE" $dry_flag
    fi
    exit $?
  fi

  preflight

  if $INSTALL_CHECK; then
    check_skills
    exit 0
  fi

  if $INSTALL_LIST_VENDORED; then
    list_vendored
    exit 0
  fi

  # Handle single skill fetch
  if [ -n "$INSTALL_SKILL_NAME" ]; then
    info "Fetching vendored skill: $INSTALL_SKILL_NAME..."
    if ! $DRY_RUN; then
      confirm "Fetch $INSTALL_SKILL_NAME from GitHub?" || { echo "Cancelled."; exit 0; }
    fi
    fetch_skill "$INSTALL_SKILL_NAME"
    exit $?
  fi

  # Handle project-level vendored skills
  if $INSTALL_PROJECT_SKILLS; then
    if ! $DRY_RUN; then
      confirm "Fetch project vendored skills from GitHub?" || { echo "Cancelled."; exit 0; }
    fi
    install_project_skills
    exit $?
  fi

  if $INTERACTIVE; then
    interactive_menu
  fi

  # Determine if we have anything to do
  local has_local=false has_vendored=false
  if $INSTALL_SETTINGS || $INSTALL_CLAUDE_MD || $INSTALL_HOOKS || \
     $INSTALL_AGENTS || $INSTALL_SKILLS || $INSTALL_COMMANDS || $INSTALL_RULES; then
    has_local=true
  fi
  if $INSTALL_VENDORED; then
    has_vendored=true
  fi

  if ! $has_local && ! $has_vendored; then
    warn "Nothing selected to install."
    exit 0
  fi

  # Install local components
  if $has_local; then
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
  fi

  # Fetch vendored skills
  if $has_vendored; then
    echo ""
    local do_fetch=true
    if ! $DRY_RUN; then
      confirm "Fetch all vendored skills from GitHub?" || do_fetch=false
    fi
    if $do_fetch; then
      echo ""
      info "Fetching vendored skills..."
      local all_vendored=()
      while IFS= read -r name; do
        all_vendored+=("$name")
      done < <(vendored_skill_names)
      fetch_vendored_batch "${all_vendored[@]}"
    else
      info "Skipping vendored skills."
    fi
  fi

  echo ""
  bold "Done!"
  if $DRY_RUN; then info "(Dry run — no files were modified)"; fi
}

main
