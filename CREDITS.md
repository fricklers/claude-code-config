# Credits

This configuration was built by analyzing and learning from the best Claude Code setups in the ecosystem. Attribution and thanks to everyone whose work informed our design:

## Sources

- **[affaan-m/everything-claude-code](https://github.com/AffaanM/everything-claude-code)** (41.2k stars) — Read-only agent constraints, strategic compact concept, breadth of skill categories. We adopted the read-only planner/reviewer pattern and distilled the skill architecture.

- **Boris Cherny** (Claude Code creator) — Simplicity philosophy, auto-format hook pattern, the insight that "giving Claude a way to verify its work = 2-3x quality." His sub-2.5k token CLAUDE.md and 3-line hook proved that less is more.

- **[jarrodwatts/claude-code-config](https://github.com/jarrodwatts/claude-code-config)** (913 stars) — Original inspiration for comment and testing rules structure. Our rules files build on his approach with path-scoped activation.

- **[rohitg00/pro-workflow](https://github.com/rohitg00/awesome-claude-code-workflow)** (477 stars) — The `/handoff` concept for session continuity, scout agent inspiration. We simplified the handoff into a focused command.

- **[ChrisWiles/claude-code-showcase](https://github.com/ChrisWiles/claude-code-showcase)** (5.2k stars) — Main branch protection patterns, skill evaluation methodology, CI/CD integration approaches.

- **[ykdojo/claude-code-tips](https://github.com/ykdojo/claude-code-tips)** (2k stars) — Handoff documents for context management, custom status line tips, the philosophy that proactive compaction beats context overflow.

- **[centminmod/my-claude-code-setup](https://github.com/centminmod/my-claude-code-setup)** (1.8k stars) — Memory bank concepts, multi-LLM orchestration patterns, safety-net plugin inspiration for our `block-dangerous.sh`.

- **[feiskyer/claude-code-settings](https://github.com/feiskyer/claude-code-best-practices)** (1.2k stars) — Deep research orchestration patterns, agent team architecture, multi-model workflows.

- **[hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)** (23k stars) — Ecosystem curation confirming that skill-based, modular architecture is the dominant community pattern.

- **[Matt-Dionis/claude-code-configs](https://github.com/Matt-Dionis/claude-code-configs)** (613 stars) — CLI merger tool concept, zero-dependency philosophy, test-driven approach with 124 tests.

- **[Official Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)** — All hook, settings, agent, skill, and command specifications.

## Design Decisions Informed by Analysis

| What we learned | From whom | What we did |
|----------------|-----------|-------------|
| Read-only agents prevent accidental modifications | affaan-m | Both agents are read-only (Bash, Glob, Grep, Read only) |
| Simplicity beats comprehensiveness for CLAUDE.md | Boris Cherny | ~50 lines, ~800 tokens — every line earned |
| Cost-tiered models save money without quality loss | jarrodwatts, Matt-Dionis | haiku for search, sonnet for review |
| Session continuity is the #1 missing feature | rohitg00, ykdojo | `/handoff` command creates structured continuity docs |
| Hooks enforce better than instructions | Boris Cherny, ChrisWiles | 6 hooks covering safety, linting, and context |
| Zero external deps = zero broken installs | Matt-Dionis | bash + jq only, no npm/pip/cargo |
| Settings.json is the most important file nobody ships | (our analysis) | Complete settings.json with all hooks pre-wired |
