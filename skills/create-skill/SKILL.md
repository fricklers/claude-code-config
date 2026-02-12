---
name: create-skill
description: Creates a new Claude Code skill. Use when the user wants to make a new skill, slash command, or teach Claude a new workflow.
disable-model-invocation: true
argument-hint: [skill-name]
---

Create a new skill called `$ARGUMENTS`. Follow these steps in order:

## 1. Clarify intent

Ask the user one question: **What should this skill do?** Get a one-sentence answer. Don't over-plan.

## 2. Decide scope

Pick the right storage location based on the answer:

| Location | Path | Use when |
|----------|------|----------|
| Personal | `~/.claude/skills/<name>/SKILL.md` | General-purpose, works across all projects |
| Project | `.claude/skills/<name>/SKILL.md` | Specific to this repo |

Default to personal unless the skill is clearly project-specific.

## 3. Create SKILL.md

Create the directory and write `SKILL.md` with this structure:

```yaml
---
name: <skill-name>
description: <one line — what it does and when Claude should use it>
---
```

Follow these rules for the content:
- **Keep it under 80 lines** — if it needs more, use supporting files
- **Use numbered steps** for task workflows, bullet points for reference knowledge
- **Be specific** — "Run `npm test`" not "run the tests"
- **No preamble** — start with the first actionable instruction
- Match the tone and structure of existing skills in this repo

### Frontmatter decisions

- Set `disable-model-invocation: true` to block auto-invocation when the skill has side effects (deploys, sends messages, modifies external state)
- Set `user-invocable: false` to hide from the `/` menu when it's background knowledge Claude should apply automatically
- Add `context: fork` if it runs an independent task that doesn't need conversation history
- Otherwise, use defaults (both user and Claude can invoke it)

## 4. Test it

Verify the skill works:
1. Check the file is valid YAML frontmatter + markdown
2. Ask Claude "What skills are available?" and confirm it appears
3. Invoke it with `/skill-name` and confirm it behaves as expected

## 5. Done

Tell the user:
- The skill path
- How to invoke it: `/skill-name` or let Claude auto-invoke
- How to edit it later: just edit the `SKILL.md` file directly
