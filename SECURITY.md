# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it through
[GitHub's private vulnerability reporting](https://github.com/fricklers/claude-code-config/security/advisories/new).

**Do not open a public issue for security vulnerabilities.**

## What to Expect

- **Acknowledgment** within 48 hours of your report
- **Status update** within 7 days with an assessment and remediation plan
- **Fix or disclosure** within 30 days, depending on severity

## Scope

Security-relevant components in this project:

- **`install.sh`** — executes shell commands, copies files to `~/.claude/`
- **`hooks/*.sh`** — hook scripts that run automatically during Claude Code sessions

Vulnerabilities of interest include command injection, path traversal, unintended file
overwrites, and any way a crafted input could cause the scripts to execute arbitrary code.

## Out of Scope

- The `settings.json` configuration itself (declarative, no code execution)
- Markdown files (`CLAUDE.md`, agents, skills, commands, rules)
