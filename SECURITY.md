# Security policy

This repo ships guardrails (Claude Code hooks and permission settings) that other repos copy. A flaw here can weaken every repo that uses them, so it is treated as a security issue.

## Report a vulnerability

Do not open a public issue. Use a private report:

1. Open [a private security advisory](https://github.com/kaushik-sai/ai-engineering-playbook/security/advisories/new) on this repo.
2. Include the file, the input or command that gets through, what you expected, and what happened.
3. Do not include real secrets. Use fake values that match the pattern.

You can expect an acknowledgement within 5 working days. This is a single-maintainer project, so that is a goal and not a guarantee.

## In scope

- A command that `templates/claude/hooks/Guard-BashCommand.ps1` should block but allows (guardrail bypass).
- A write that `Guard-FileWrite.ps1` should block but allows, including path tricks (`..`, absolute paths, case, symlinks).
- A secret pattern that gets into `.claude/audit/tool-use.jsonl` unredacted, or file contents that get logged.
- Permission rules in `templates/claude/settings.json` that allow more than they say, or a way to edit the settings and hooks from the agent.
- Workflow problems in `.github/workflows/`: unpinned actions, excess `permissions:`, script injection from untrusted input.
- Secrets committed to the repo.

## Out of scope

- Hooks are a safety net, not a sandbox. A determined user with shell access can bypass them; use OS-level sandboxing and least-privilege credentials for that (see `playbook/05-permissions-and-sandboxing.md`).
- Bugs in Claude Code itself: report those to Anthropic.
- Advice in the playbook you disagree with. Open a normal issue.

## Supported versions

There are no numbered releases yet. Only the latest commit on `main` is supported. Fixes land on `main` through a pull request.
