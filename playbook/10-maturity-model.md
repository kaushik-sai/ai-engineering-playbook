# Maturity model

Use this model to place a team honestly and choose the next step. Each level adds controls, and each level needs evidence you can show. A team is at the highest level for which all the evidence exists. Claiming a level without the evidence does not count.

## The five levels

| Level | Name | In one line |
| --- | --- | --- |
| 0 | Ad hoc chat | People paste code into a chat and copy results back |
| 1 | Assisted | Claude Code runs in the repo with a shared `CLAUDE.md` |
| 2 | Guarded | Settings, hooks and review gates make unsafe actions hard |
| 3 | Orchestrated | Skills, subagents and headless CI run repeatable workflows |
| 4 | Governed at scale | Org policy, metrics, audit and a scenario library |

## Capabilities, controls and evidence

| Level | Capabilities | Controls | Evidence needed to claim it |
| --- | --- | --- | --- |
| 0 Ad hoc chat | Suggestions, snippets, explanations | None beyond personal care | None. This is the starting point |
| 1 Assisted | Agent reads and edits the repo; runs tests | Shared `CLAUDE.md` ([02-context-and-memory.md](02-context-and-memory.md)); work on branches; human PR review | `CLAUDE.md` committed and reviewed; branch protection on `main` |
| 2 Guarded | Same, with safe defaults | Committed `.claude/settings.json` with allow/ask/deny; guard and audit hooks tested in CI; secret scan and SAST required; CODEOWNERS on harness files | Settings and hooks in repo; Pester tests green; required checks listed in branch protection; a blocked-command demonstration |
| 3 Orchestrated | Multi-step work in parallel; CI-run agents | Orchestrate skill; reviewer subagents with read-only tools; headless runs with `--max-turns` and minimal `--allowedTools`; briefs and report format | Skill and agents in repo; a headless workflow with pinned actions; sample briefs and reports; agent PRs labelled |
| 4 Governed at scale | Many repos and teams on one standard | Managed settings with `disableBypassPermissionsMode`; MCP allowlist; metrics and monthly review; incident process; shared scenario library | Managed policy deployed and verified on sample machines; metrics dashboard with at least a quarter of data; an incident exercise record; scenarios in use |

## How to assess

Go level by level from the bottom. For each, ask for the evidence, not for an opinion. Open the file, run the check, read the log.

1. Pick a repo, not a team. Different repos can be at different levels.
2. Walk the evidence column. Mark each item present, partial or missing.
3. The level is the highest one with no missing items.
4. Write the gap list for the next level. Pick the two items with most risk reduction.
5. Re-assess every quarter.

## Moving up

- **0 to 1.** Write a short `CLAUDE.md` from [templates/CLAUDE.md](../templates/CLAUDE.md). Turn on branch protection. Agree that agents open PRs and people merge.
- **1 to 2.** Add [templates/claude/settings.json](../templates/claude/settings.json) and the three hooks ([04-hooks-and-guardrails.md](04-hooks-and-guardrails.md)). Add CI secret scan, SAST and hook tests. Add CODEOWNERS for harness files ([07-review-gates.md](07-review-gates.md)).
- **2 to 3.** Add the orchestrate skill and reviewer subagents ([03-skills-subagents-orchestration.md](03-skills-subagents-orchestration.md)). Run the first headless workflow with strict limits, starting with a low-risk task like [scenarios/03-ci-fix-loop.md](../scenarios/03-ci-fix-loop.md).
- **3 to 4.** Deploy managed settings ([05-permissions-and-sandboxing.md](05-permissions-and-sandboxing.md)). Vet MCP servers ([06-mcp-and-connectors.md](06-mcp-and-connectors.md)). Start the metrics and monthly review ([09-observability-and-cost.md](09-observability-and-cost.md)). Run an incident exercise ([08-security-baseline.md](08-security-baseline.md)).

Do not skip levels. A headless agent at level 3 without level 2 controls is the riskiest setup in this model.

## Scenarios by level

The scenarios in [scenarios/](../scenarios/README.md) are worked examples. Suggested entry points:

| Scenario | Fits from level |
| --- | --- |
| [01 New repo bootstrap](../scenarios/01-new-repo-bootstrap.md) | 1 |
| [02 Ticket to PR](../scenarios/02-ticket-to-pr.md) | 2 |
| [03 CI fix loop](../scenarios/03-ci-fix-loop.md) | 3 |
| [04 Dependency upgrade](../scenarios/04-dependency-upgrade.md) | 3 |
| [05 IaC change review](../scenarios/05-iac-change-review.md) | 3 |
| [06 Incident triage](../scenarios/06-incident-triage.md) | 3 (read-only), 4 (full process) |

The two sibling repositories put this into practice: [governed-repo-template](https://github.com/kaushik-sai/governed-repo-template) (level 2 starting point) and [agentic-devops-workflow](https://github.com/kaushik-sai/agentic-devops-workflow) (level 3 automation).

## Common traps

- **Level inflation.** The team says level 3 because someone ran a skill once. Ask for the workflow file and a merged PR it produced.
- **Policy on paper.** A rule in a wiki is not a control. If no setting, hook or branch rule enforces it, it is level 1 at best.
- **Tools without owners.** Hooks and settings that nobody reviews drift. Ownership in CODEOWNERS is part of the evidence.
- **Skipping the human gate to go faster.** Review is the bottleneck by design. Raise its quality with smaller PRs and better evidence, not by removing it.
- **Measuring too early.** Metrics in [09-observability-and-cost.md](09-observability-and-cost.md) need a few weeks of data before they mean anything.

## Example assessment

A repo has a committed `CLAUDE.md`, branch protection and a settings file with deny rules. The hooks exist but have no tests, and CODEOWNERS does not cover `.claude/`. Result: level 1. The gap list for level 2 is: add Pester tests for the hooks, add CODEOWNERS entries and make the secret scan a required check. Three items, each checkable in an afternoon.

## What this model does not claim

The levels are a planning tool made for this playbook. They are not an industry standard or a certification, and no numbers here have been benchmarked. Adapt them to your risk.

## Checklist

- [ ] Each repo has a recorded current level with a link to the evidence.
- [ ] The evidence for the claimed level was checked by someone other than its author.
- [ ] A gap list exists for the next level, with owners.
- [ ] No repo runs headless agents without level 2 controls.
- [ ] The assessment is repeated at least every quarter.
- [ ] At least one scenario from the library has been run end to end at the claimed level.
