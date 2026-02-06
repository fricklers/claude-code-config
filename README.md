# claude-code-config

**The config that respects your intelligence.**

17 files. Every piece earns its place. Nothing is filler. The only config that ships a complete, documented `settings.json` with all hooks pre-wired. Zero external dependencies beyond `jq`. Each hook is under 40 lines of bash.

We analyzed [10 major Claude Code configurations](#credits) across the ecosystem — from the 41k-star everything-configs to Claude Code's creator's own setup. Most configs suffer from massive context overhead, broken plugin dependencies, and passive documentation masquerading as skills. This is the opposite.

## Quick Start

**Interactive install** (pick what you want):
```bash
git clone https://github.com/fricklers/claude-code-config.git
cd claude-code-config
./install.sh
```

**Install everything:**
```bash
./install.sh --all -y
```

**Manual** (copy individual files to `~/.claude/`):
```bash
cp settings.json ~/.claude/settings.json
cp CLAUDE.md ~/.claude/CLAUDE.md
cp -r hooks/ ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

### Requirements

- `jq` — the only dependency
  - macOS: `brew install jq`
  - Ubuntu: `sudo apt install jq`

## What's Included

| File | Target | Description |
|------|--------|-------------|
| `settings.json` | `~/.claude/settings.json` | Permissions, hooks, security rules — the one file everyone needs |
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | ~50 lines of coding instructions — every line addresses a real failure mode |
| `hooks/block-dangerous.sh` | `~/.claude/hooks/` | Blocks `rm -rf`, force push, `chmod 777`, pipe-to-shell, disk ops |
| `hooks/protect-secrets.sh` | `~/.claude/hooks/` | Blocks reading `.env`, keys, certs, SSH keys, credential files |
| `hooks/confirm-commit.sh` | `~/.claude/hooks/` | Escalates `git commit`/`push` to user confirmation |
| `hooks/auto-lint.sh` | `~/.claude/hooks/` | Auto-detects and runs project linter (eslint/ruff/flake8) on changed files |
| `hooks/inject-context.sh` | `~/.claude/hooks/` | Injects git branch, recent commits, and working tree status at session start |
| `hooks/check-todos.sh` | `~/.claude/hooks/` | Blocks Claude from stopping with incomplete todos |
| `agents/explorer.md` | `~/.claude/agents/` | haiku-powered, read-only — fast codebase search with parallel strategies |
| `agents/reviewer.md` | `~/.claude/agents/` | sonnet-powered, read-only — code review (bugs, security, perf, coverage) |
| `skills/rigorous-coding/SKILL.md` | `~/.claude/skills/` | 8-step before/during/after coding discipline |
| `commands/handoff.md` | `~/.claude/commands/` | `/handoff` — creates session continuity document for resuming later |
| `commands/review.md` | `~/.claude/commands/` | `/review [file]` — code review using the reviewer agent |
| `rules/comments.md` | `~/.claude/rules/` | Comment policy: self-documenting code, no commented-out code, TODO format |
| `rules/testing.md` | `~/.claude/rules/` | AAA structure, descriptive names, happy+error+edge coverage |
| `rules/examples/typescript.md` | *(not auto-installed)* | TypeScript conventions — copy to project's `.claude/rules/` |
| `rules/examples/python.md` | *(not auto-installed)* | Python conventions — copy to project's `.claude/rules/` |

## Hook Reference

| Script | Event | Matcher | Blocking? | What it does |
|--------|-------|---------|-----------|-------------|
| `block-dangerous.sh` | PreToolUse | Bash | Yes (exit 2) | Blocks destructive commands (rm -rf, force push, chmod 777, etc.) |
| `protect-secrets.sh` | PreToolUse | Read | Yes (deny) | Blocks reading .env, keys, certs, SSH keys |
| `confirm-commit.sh` | PreToolUse | Bash | Ask | Escalates git commit/push to user confirmation |
| `auto-lint.sh` | PostToolUse | Write\|Edit | No (informational) | Runs project linter, reports issues as context |
| `inject-context.sh` | SessionStart | startup | No (informational) | Injects git branch, commits, working tree status |
| `check-todos.sh` | Stop | — | Yes (block) | Blocks if there are incomplete todos |

## How to Customize

### Add project-specific settings

Create `.claude/settings.json` in your project root. Project settings merge with global settings:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm test *)",
      "Bash(npm run *)"
    ]
  }
}
```

### Add framework-specific rules

Copy from examples or create your own in your project's `.claude/rules/`:

```bash
mkdir -p .claude/rules
cp ~/claude-code-config/rules/examples/typescript.md .claude/rules/
```

### Add test-on-write hook

Test commands differ per project, so this isn't in global settings. Add to your project's `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "cd $(git rev-parse --show-toplevel) && npm test --silent 2>&1 | tail -20",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

### Write your own hooks

Every hook follows the same pattern:
1. Read JSON from stdin with `jq`
2. Apply logic
3. Exit with the right code (0 = allow, 2 = block) or output a JSON decision

```bash
#!/usr/bin/env bash
set -euo pipefail
input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')
# Your logic here
exit 0
```

## Philosophy

**Why 17 files, not 100?**

Claude Code's creator uses a CLAUDE.md under 2,500 tokens. His most important hook is 3 lines. His insight: **"Give Claude a way to verify its work = 2-3x quality."** The simpler the config, the more reliably Claude follows it.

Every skill, agent, and rule in your config consumes context budget. A 27-skill config with 200-line CLAUDE.md means Claude is processing thousands of tokens of instructions before it even starts your task. Most of those instructions are passive documentation that doesn't change behavior.

Our design principles:
- **If it doesn't change Claude's behavior, it doesn't belong in the config**
- **Hooks > instructions** — enforced guardrails beat polite requests
- **Cost-tiered agents** — haiku for search ($), sonnet for review ($$), no reason to run Opus for file search
- **Zero external dependencies** — no npm packages, no Python scripts, no MCP plugins to install
- **Every hook is auditable in seconds** — bash + jq, no transpilation, no runtime

## Credits

See [CREDITS.md](CREDITS.md) for full attribution to the 10+ configurations and sources we learned from.

## License

[MIT](LICENSE)
