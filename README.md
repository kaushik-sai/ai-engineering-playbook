# ai-engineering-playbook

[![playbook-checks](https://github.com/kaushik-sai/ai-engineering-playbook/actions/workflows/playbook-checks.yml/badge.svg?branch=main)](https://github.com/kaushik-sai/ai-engineering-playbook/actions/workflows/playbook-checks.yml)

A playbook for AI-driven engineering with Claude Code: how to build a harness around an agent so it can do real work in production repos without being trusted blindly.

It has three parts:

- **Standards**: eleven short chapters on the harness (context, skills, subagents, hooks, permissions, MCP, review gates, security, observability, maturity).
- **Templates**: files you copy into a repo: `CLAUDE.md`, a permissions and hooks `settings.json`, three tested PowerShell hooks, two reviewer subagents, an orchestrate skill, briefs and a PR template.
- **Scenarios**: six production-style use cases, from bootstrapping a repo to triaging an incident, each with its flow, guardrails, gates and failure modes.

An interactive version with diagrams, a permission simulator and a gate walkthrough is published as an Artifact (see [Interactive playbook](#interactive-playbook)).

| Part | Where |
| --- | --- |
| Principles and standards | [playbook/](playbook/) |
| Use-case scenarios | [scenarios/](scenarios/README.md) |
| Copy-in templates | [templates/](templates/README.md) |
| Hook tests | [tests/hooks.Tests.ps1](tests/hooks.Tests.ps1) |
| Shared design system (Harness) | [design-system/](design-system/README.md) |
| Interactive playbook source | [site/playbook.html](site/playbook.html) |
| Design, runbook | [DESIGN.md](DESIGN.md), [RUNBOOK.md](RUNBOOK.md) |
| Decisions, evidence | [docs/DECISIONS.md](docs/DECISIONS.md), [docs/EVIDENCE.md](docs/EVIDENCE.md) |

## Read it in this order

1. [Principles](playbook/00-principles.md), then [Harness anatomy](playbook/01-harness-anatomy.md).
2. [Maturity model](playbook/10-maturity-model.md): find the level your repo is at.
3. The chapters for the next level up.
4. A scenario at or below your level, from the [scenario index](scenarios/README.md).

| Chapter | Topic |
| --- | --- |
| [00](playbook/00-principles.md) | Principles of harness engineering |
| [01](playbook/01-harness-anatomy.md) | Harness anatomy: the layers and who owns each |
| [02](playbook/02-context-and-memory.md) | Context and memory: `CLAUDE.md` |
| [03](playbook/03-skills-subagents-orchestration.md) | Skills, subagents and the orchestrate workflow |
| [04](playbook/04-hooks-and-guardrails.md) | Hooks and guardrails |
| [05](playbook/05-permissions-and-sandboxing.md) | Permissions and sandboxing |
| [06](playbook/06-mcp-and-connectors.md) | MCP servers and connectors |
| [07](playbook/07-review-gates.md) | Review gates |
| [08](playbook/08-security-baseline.md) | Security baseline and threat model |
| [09](playbook/09-observability-and-cost.md) | Observability and cost |
| [10](playbook/10-maturity-model.md) | Maturity model |

## Adopt it in a repo (PowerShell)

The fastest start is a new repo from [governed-repo-template](https://github.com/kaushik-sai/governed-repo-template), which already carries these files. For an existing repo, copy the templates in:

```powershell
$playbook = 'C:\src\ai-engineering-playbook'
$repo     = 'C:\src\orders-svc'

New-Item -ItemType Directory -Force "$repo\.claude\hooks", "$repo\.claude\agents", "$repo\.claude\skills", "$repo\.github" | Out-Null
Copy-Item "$playbook\templates\claude\settings.json"   "$repo\.claude\settings.json"
Copy-Item "$playbook\templates\claude\hooks\*.ps1"      "$repo\.claude\hooks\"
Copy-Item "$playbook\templates\agents\*.md"             "$repo\.claude\agents\"
Copy-Item "$playbook\templates\skills\orchestrate"      "$repo\.claude\skills\" -Recurse
Copy-Item "$playbook\templates\github\pull_request_template.md" "$repo\.github\"
if (-not (Test-Path "$repo\CLAUDE.md")) { Copy-Item "$playbook\templates\CLAUDE.md" "$repo\CLAUDE.md" }
Add-Content "$repo\.gitignore" '.claude/audit/'
```

Then edit `CLAUDE.md` for the repo's real commands, review `settings.json` with the team, and add `.claude/` to `CODEOWNERS`. [Scenario 01](scenarios/01-new-repo-bootstrap.md) walks through the rest (branch protection, required checks).

For an automated flow from a Jira ticket to a reviewed PR, see [agentic-devops-workflow](https://github.com/kaushik-sai/agentic-devops-workflow) and [scenario 02](scenarios/02-ticket-to-pr.md).

## Prerequisites

| Tool | Version used | Needed for |
| --- | --- | --- |
| Claude Code | current | using the templates |
| PowerShell | 7.4+ (tests ran on 7.4.6) | the hooks and their tests |
| Pester | 5.7.1 | hook tests |
| PSScriptAnalyzer | 1.24.0 | lint |
| Node.js | 20+ | markdownlint (`npx markdownlint-cli2`) |
| Python | 3.10+ | rebuilding `design-system/tokens.css` |

## Run the checks

```powershell
pwsh ./scripts/Invoke-Checks.ps1
```

This runs the same checks as CI: markdownlint, PSScriptAnalyzer, Pester and the JSON and token checks. CI also runs a link check, a secret scan (gitleaks) and actionlint. See [RUNBOOK.md](RUNBOOK.md).

## Interactive playbook

The page in [site/playbook.html](site/playbook.html) is published as a private Claude Artifact (link in [docs/EVIDENCE.md](docs/EVIDENCE.md)). It has the harness diagram, a permission and hook simulator, the orchestrate router, a review gate walkthrough, the scenario library and a maturity self-check. It uses the [Harness design system](design-system/README.md).

## Status

Verified here: lint, hook tests and checks listed in [docs/EVIDENCE.md](docs/EVIDENCE.md). Not verified: the scenarios end to end in a real team. They are recommended designs and say so.

## License

[MIT](LICENSE).
