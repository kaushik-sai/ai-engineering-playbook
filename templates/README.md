# Templates

Copy-ready files for a target repo. Each one is a starting point: read it, adjust the placeholders, and review it like code before you commit it. The guardrail files (settings and hooks) change what an agent is allowed to do, so they need a human review.

| Template | What it is | Copy to in the target repo |
| --- | --- | --- |
| [CLAUDE.md](CLAUDE.md) | Starter memory file: commands, layout, conventions, do and do not, review rules | `CLAUDE.md` |
| [briefs/refined-brief.md](briefs/refined-brief.md) | Structured brief that turns a raw request into checkable requirements | `.claude/skills/orchestrate/references/brief-template.md` |
| [briefs/subagent-brief.md](briefs/subagent-brief.md) | Brief for a subagent, with file ownership and bounded verification | `.claude/skills/orchestrate/references/subagent-brief.md` |
| [skills/orchestrate/SKILL.md](skills/orchestrate/SKILL.md) | The refine, plan, delegate, verify, report workflow, with the model and effort table | `.claude/skills/orchestrate/SKILL.md` |
| [agents/code-reviewer.md](agents/code-reviewer.md) | Read-only subagent for correctness and test review | `.claude/agents/code-reviewer.md` |
| [agents/security-reviewer.md](agents/security-reviewer.md) | Read-only subagent for secrets, injection, supply chain and IaC review | `.claude/agents/security-reviewer.md` |
| [github/pull_request_template.md](github/pull_request_template.md) | PR description with verification, rollback and AI involvement sections | `.github/pull_request_template.md` |
| [claude/settings.json](claude/settings.json) | Permissions (allow, ask, deny) and hook wiring | `.claude/settings.json` |
| [claude/hooks/Guard-BashCommand.ps1](claude/hooks/Guard-BashCommand.ps1) | PreToolUse hook for Bash: blocks dangerous commands | `.claude/hooks/Guard-BashCommand.ps1` |
| [claude/hooks/Guard-FileWrite.ps1](claude/hooks/Guard-FileWrite.ps1) | PreToolUse hook for Write, Edit and MultiEdit: blocks protected paths | `.claude/hooks/Guard-FileWrite.ps1` |
| [claude/hooks/Write-AuditLog.ps1](claude/hooks/Write-AuditLog.ps1) | PostToolUse hook: appends a JSONL audit record per tool call | `.claude/hooks/Write-AuditLog.ps1` |

## How to apply them

```powershell
$target = 'C:\src\my-service'
Copy-Item templates/CLAUDE.md $target/CLAUDE.md
New-Item -ItemType Directory -Force "$target/.claude/agents", "$target/.claude/hooks", "$target/.github" | Out-Null
Copy-Item templates/agents/*.md "$target/.claude/agents/"
Copy-Item templates/claude/settings.json "$target/.claude/settings.json"
Copy-Item templates/claude/hooks/*.ps1 "$target/.claude/hooks/"
Copy-Item templates/github/pull_request_template.md "$target/.github/pull_request_template.md"
```

Or start from [governed-repo-template](https://github.com/kaushik-sai/governed-repo-template), which already contains these files wired together.

## Notes

- The hooks and settings use `$CLAUDE_PROJECT_DIR`, so they work from any working directory in the project.
- Add `.claude/settings.local.json` and `CLAUDE.local.md` to `.gitignore`. They are for personal overrides.
- The scenarios in [../scenarios/README.md](../scenarios/README.md) show these templates in use.
- Set a managed policy (`managed-settings.json`) if you need rules a developer cannot override. See [the permissions chapter](../playbook/05-permissions-and-sandboxing.md).

## Checklist

- [ ] Every placeholder in CLAUDE.md was replaced.
- [ ] A human reviewed settings.json and the hook scripts before the first commit.
- [ ] The hooks run on the developer machine and on the CI runner (`pwsh` is installed).
- [ ] The reviewer agents appear in `/agents` in Claude Code.
- [ ] The PR template shows up when a new PR is opened.
