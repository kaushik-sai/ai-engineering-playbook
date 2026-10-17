# Context and memory

`CLAUDE.md` is the standing briefing every session starts with. It is the cheapest control in the harness and the easiest to let rot. This chapter covers what belongs in it, what does not, and how to keep it true.

## The memory files

| File | Scope | Committed |
| --- | --- | --- |
| `./CLAUDE.md` | Project, shared by the team | Yes |
| `./CLAUDE.local.md` | Personal notes for this project | No (git-ignored) |
| `~/.claude/CLAUDE.md` | Your preferences in every project | No |
| `<subdir>/CLAUDE.md` | Rules for one part of the tree | Yes |

A starting template for a target repo is [templates/CLAUDE.md](../templates/CLAUDE.md).

## What goes in

Keep to things the model cannot work out by reading the code, and that matter on most tasks:

- Build, test, lint and run commands, exactly as typed.
- Conventions that are not obvious: branch names, commit format, error handling style.
- Do and don't rules that protect something: "never edit `migrations/` by hand", "do not touch `infra/prod/`".
- Where things live, in one line each: "API handlers: `src/api/`".
- The verification step expected before a task counts as done.
- Pointers to deeper docs, not copies of them.

## What stays out

- Secrets, tokens, internal hostnames and customer data. `CLAUDE.md` is committed and sent to the model.
- Anything a linter or formatter already enforces. Let the tool say it.
- Long style guides, API references and architecture essays. Link or import them.
- Instructions that must always hold. Use permissions or hooks (see [05-permissions-and-sandboxing.md](05-permissions-and-sandboxing.md)).
- Task-specific plans. Those belong in a brief or a ticket.
- Temporary notes. They outlive their usefulness and mislead later sessions.

## Size budget

Everything in `CLAUDE.md` is loaded into context on every session. It competes with the code and the task for space.

- Target: under about 150 lines for the root file. This is a recommendation, not a measured limit.
- Short imperative lines beat paragraphs.
- If a section is only relevant to one directory, move it to that directory's `CLAUDE.md`.
- If a section is long and rarely needed, move it to a doc and import or link it.

## Imports

A line starting with `@` imports another file:

```markdown
@docs/architecture.md
@.claude/conventions/errors.md
```

Use imports to keep the root file short while keeping detail close to the code. Imported files count toward context too, so import only what most sessions need.

## Per-directory files

Put a `CLAUDE.md` inside a directory when its rules differ from the rest of the repository. Typical cases: an `infra/` folder with plan-before-apply rules, a `frontend/` folder with different test commands, a `legacy/` folder with a "do not refactor" rule.

## Example excerpt

```markdown
# Project: devops-svc

## Commands
- Test: `pwsh -File scripts/Invoke-Tests.ps1`
- Lint: `Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning`
- Plan infra: `terraform -chdir=terraform plan -out=tfplan`

## Conventions
- Branches: `feature/<ticket>-<slug>`. Commits end with `(#<pr>)`.
- PowerShell: approved verbs only, `Set-StrictMode -Version Latest`.
- Every behaviour change needs a Pester test.

## Rules
- Never run `terraform apply`. A human applies after plan review.
- Do not edit `.github/workflows/` or `.claude/` without being asked.
- Do not read or write `.env*` or `secrets/`.

## Done means
- Tests and lint pass, and the output is quoted in the PR description.
- Anything not verified is listed under "Not verified".
```

## Keeping it true

A stale `CLAUDE.md` is worse than none, because the model trusts it.

1. Put `CLAUDE.md` under CODEOWNERS. A change needs review like code.
2. Add a line to the PR template: "Did this change a command or convention in `CLAUDE.md`?" (see [templates/github/pull_request_template.md](../templates/github/pull_request_template.md)).
3. When an agent makes the same mistake twice, add one line to the file. When a line has not mattered for a while, remove it.
4. Run the commands listed in `CLAUDE.md` in CI at least occasionally, so a broken command shows up as a failure.
5. Review the file whenever the build system, test runner or branch policy changes.

## Context hygiene during a session

- Start a fresh session for an unrelated task.
- Delegate broad searches to a subagent so the results stay out of the main context (see [03-skills-subagents-orchestration.md](03-skills-subagents-orchestration.md)).
- Ask for summaries of long outputs instead of pasting them in.
- Watch context fill. The token weather mod (`/tokens`) shows it live (see [09-observability-and-cost.md](09-observability-and-cost.md)).

## Checklist

- [ ] The root `CLAUDE.md` exists, is committed and is under about 150 lines.
- [ ] Every command in it runs as written on a clean checkout.
- [ ] It contains no secrets, tokens or personal data.
- [ ] Hard rules in it are also enforced by a permission or hook.
- [ ] `CLAUDE.local.md` is git-ignored.
- [ ] `CLAUDE.md` has a CODEOWNERS entry.
- [ ] The PR template asks whether `CLAUDE.md` needs an update.
- [ ] Directory-specific rules live in that directory's `CLAUDE.md`.
