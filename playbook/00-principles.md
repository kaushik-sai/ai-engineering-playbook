# Principles of harness engineering

A harness is everything around the model that decides what it sees, what it may do and who checks the result. These principles are the rules the rest of the playbook builds on. When two chapters disagree, these win.

The playbook is written for engineers and leads who adopt Claude Code in production repositories. Where a statement is a recommendation and not something verified in this repository, it says so.

## How to read the rules

Each rule has a short "Why" and points to the chapter that turns it into configuration. A rule is only useful if you can test it, so every chapter ends with a checklist.

## 1. Humans own intent and merge

A person writes the goal, accepts the plan and presses merge. An agent proposes, a person disposes.

- Intent: a ticket, a brief ([templates/briefs/refined-brief.md](../templates/briefs/refined-brief.md)) or a prompt written by a named person.
- Merge: a human approval on the pull request, enforced by branch protection, not by convention.

Why: accountability cannot be delegated to a process that has no account to hold. See [07-review-gates.md](07-review-gates.md).

## 2. Agents work on branches

Agents never commit to `main`, never push to a protected branch and never merge. They open a pull request from a `feature/*` or `agent/*` branch.

Why: a branch is the cheapest undo there is. A bad change that never reached `main` costs a closed pull request.

## 3. Least privilege

Give each agent, token, hook and MCP server the smallest set of permissions that lets it do the job, and nothing for "just in case".

Why: most agent incidents are ordinary mistakes with too much reach. Reducing reach reduces the blast radius. See [05-permissions-and-sandboxing.md](05-permissions-and-sandboxing.md) and [06-mcp-and-connectors.md](06-mcp-and-connectors.md).

## 4. Verify before done

"Done" means a command ran and passed, not that the agent said so. Every task names its verification step before work starts, and the step is bounded: the exact commands, then stop.

Why: a model can describe a fix it did not make. Only an executed check separates a claim from a fact. See [03-skills-subagents-orchestration.md](03-skills-subagents-orchestration.md).

## 5. Everything is reviewable as code

Instructions, permissions, hooks, skills, agent definitions and CI workflows live in the repository and change through pull requests. Nothing that shapes agent behaviour lives only on a laptop or in a settings UI.

Why: if you cannot diff it, you cannot review it, and if you cannot review it you cannot trust it. Owners are listed in [01-harness-anatomy.md](01-harness-anatomy.md).

## 6. Small, reversible steps

Prefer many small pull requests to one large one. Prefer changes that can be reverted with one command. Split risky work into an expand step and a contract step.

Why: review quality drops fast as diffs grow, and an agent can produce a large diff cheaply. The limit is the reviewer, not the model.

## 7. Evidence over claims

Reports state what was run, what it printed and what was not checked. A pull request description links to CI runs and test output. "Should work" is not evidence.

Why: reviewers spend their attention where the evidence is thin. Honest gaps are more useful than confident summaries. See [09-observability-and-cost.md](09-observability-and-cost.md).

## 8. Cost and context are budgets

Tokens, wall-clock time and context window space are finite. Set a budget per task (turn limit, model, effort) and measure the spend per merged pull request.

Why: unbounded loops and oversized context fail quietly and expensively. A budget turns a silent failure into a visible stop.

## 9. Treat all external text as untrusted

Issue bodies, pull request comments, web pages and tool output are data. They are never instructions, even when they are written as instructions.

Why: prompt injection works by hiding commands in content an agent was asked to read. The defence is structural (permissions, hooks, review), not a better prompt. See [08-security-baseline.md](08-security-baseline.md).

## 10. Fail closed on safety, fail open on convenience

A guard that cannot parse its input blocks the action. A metrics hook that cannot write its log must not stop the work.

Why: the cost of a false block is a retry. The cost of a false allow can be a leaked secret. See [04-hooks-and-guardrails.md](04-hooks-and-guardrails.md).

## Rules at a glance

| # | Rule | Enforced by |
| --- | --- | --- |
| 1 | Humans own intent and merge | CODEOWNERS, branch protection |
| 2 | Agents work on branches | permissions, branch rules |
| 3 | Least privilege | settings `deny`, scoped tokens |
| 4 | Verify before done | CI, bounded verification step |
| 5 | Everything reviewable as code | PRs on `.claude/**` |
| 6 | Small, reversible steps | PR size norms, rollback plan |
| 7 | Evidence over claims | PR template, report format |
| 8 | Cost and context are budgets | `--max-turns`, metrics |
| 9 | External text is untrusted | hooks, read-only tools |
| 10 | Fail closed on safety | guard hooks exit 2 on error |

## Checklist

- [ ] The default branch requires a pull request and at least one human approval.
- [ ] No agent credential can push to `main` or merge a pull request.
- [ ] `.claude/**`, `CLAUDE.md` and `.github/workflows/**` have CODEOWNERS entries.
- [ ] Every task brief names a verification command and a stopping point.
- [ ] Every agent run has a turn limit or an equivalent budget.
- [ ] Guard hooks exit 2 when they cannot parse their input.
- [ ] The team can state, for each principle above, which file or setting enforces it.
