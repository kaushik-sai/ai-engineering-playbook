# Scenarios

Six production-style use cases that put the playbook to work. Each one is a service on GitHub (PowerShell 7 or containers), built through Azure Pipelines or GitHub Actions, deployed with Terraform on Azure, tracked in Jira. The company is generic. Names such as `orders-svc` and `PLAT-342` are examples.

Every scenario has the same sections: situation, trigger, who does what, flow, guardrails, review gates, failure modes, metrics, a try-it block and a checklist. These scenarios are recommended designs. They were written from the playbook and have not all been run end to end.

| Scenario | Risk level | Maturity level ([playbook](../playbook/10-maturity-model.md)) | Key gate |
| --- | --- | --- | --- |
| [01 New repo bootstrap](01-new-repo-bootstrap.md) | Low | 1 Assisted | Human reviews `.claude/`, `.github/` and CODEOWNERS before the ruleset is enabled |
| [02 Ticket to PR](02-ticket-to-pr.md) | Medium | 2 Guarded | Human approves the brief, then reads the whole diff and merges |
| [03 CI fix loop](03-ci-fix-loop.md) | Medium | 3 Orchestrated | Attempt limit, and no edit to checks, tests or workflows |
| [04 Dependency upgrade](04-dependency-upgrade.md) | Medium | 2 Guarded | SHA-256 verified and changelog read, then a staged rollout |
| [05 IaC change review](05-iac-change-review.md) | High | 3 Orchestrated | Deny on protected destroys, human approval, agent never applies |
| [06 Incident triage](06-incident-triage.md) | High | 3 Orchestrated | Read-only identity, and a human runs every mitigation |

## How to read the table

- Risk level is the damage a wrong result can do if nobody catches it: low is a rework, medium is a bad merge that review should catch, high is production or infrastructure impact.
- Maturity level is the lowest level of the harness (settings, hooks, review gates, audit) where the scenario is safe to run. Check your repo against the model before you start.
- Key gate is the one control that must not be removed.

## Shared setup

All scenarios assume the files from [templates](../templates/README.md): `CLAUDE.md`, the reviewer agents, the PR template, and the settings and hooks under `templates/claude/`. Review gate states are pass, needs-human and blocked, defined in [review gates](../playbook/07-review-gates.md).

## Checklist

- [ ] The repo has the template files from `templates/` in place.
- [ ] You know which maturity level your repo is at before choosing a scenario.
- [ ] Each scenario you adopt has an owner and a metric you actually read.
- [ ] You adapted the examples (names, tickets, resource types) to your own system.
