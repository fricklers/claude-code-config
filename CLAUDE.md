# Instructions

## Approach
- Read existing code, tests, and patterns before proposing any changes
- For non-trivial tasks, use Plan Mode — iterate on the plan before implementing
- For multi-step tasks, create todos upfront — mark each in_progress then completed, one at a time
- When exploring unfamiliar code, use 3+ parallel search strategies (Grep content, Glob filenames, git log for history)
- Use subagents for investigation and research — keep the main conversation for implementation
- When a request has multiple valid interpretations, ask one clarifying question before proceeding

## Code Quality
- Never suppress type errors (`as any`, `@ts-ignore`, `# type: ignore` or equivalents)
- Match the existing codebase's patterns, conventions, and style — reuse before reinventing
- Handle error cases explicitly, not just the happy path — every external call can fail
- Delete dead code completely — never comment it out
- Prefer self-documenting code over comments — comments explain WHY, not WHAT
- Don't add features, refactoring, or improvements beyond what was asked

## Verification
- After making changes, run the project's linter and tests
- Check that the build succeeds before declaring work complete
- When verification fails, fix the issue and re-verify — don't just report the failure
- Give yourself feedback loops: run the code, check the output, iterate

## Git
- Never commit unless explicitly asked
- Never force-push
- Never run destructive git commands (reset --hard, clean -f, checkout .) without explicit request
- Write commit messages that explain WHY the change was made, not just what changed
- Review your own diff before committing

## Context Management
- Each conversation should focus on one task or related set of tasks
- When context is growing long, create a handoff document (/handoff) before starting fresh
- Delegate large investigations to subagents rather than filling the main context
- When resuming work, read the relevant files and any handoff docs before diving in

## Problem Solving
- When stuck, step back and reconsider the approach rather than trying the same thing repeatedly
- If a fix requires changing more than 3 files, verify the approach before implementing
- When debugging, form a hypothesis first, then verify it — don't change code randomly
- Check if the project has existing utilities or patterns before writing new code

## Communication
- Start working immediately — no "Sure!", "Great question!", or preamble
- Be direct and concise — output is displayed in a terminal
- When something seems wrong, say so directly with reasoning and suggest an alternative
- Don't summarize what you did unless asked
- When reporting errors, include the actual error message and file:line location

## Inclusive Language
- Avoid "enable/disable" — use "activate/deactivate", "turn on/turn off", or "allow/block"
- Avoid "whitelist/blacklist" — use "allowlist/blocklist"
- Avoid "master/slave" — use "primary/replica"
- Avoid "sanity check" — use "confidence check"
- Avoid "dummy" — use "placeholder"
