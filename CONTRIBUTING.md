# Contributing

This repo is a playbook for AI-driven engineering with Claude Code, plus templates and tested guardrail hooks. Changes go through a pull request. Nobody pushes to `main`, including agents.

## Branches

- `feature/<short-name>` for hooks, templates, scripts and CI.
- `docs/<short-name>` for playbook chapters and scenarios.

Keep a branch to one topic so the diff can be read in one sitting.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat(hooks): block kubectl delete in prod contexts
fix(settings): deny edits to .claude/hooks
docs(playbook): add checklist to chapter 05
chore(ci): bump markdownlint-cli2-action
```

## Pull requests

Fill in every section of the PR template (`.github/pull_request_template.md`): Summary with Before and After, How, Verification, Risk and rollback, AI involvement, and the Checklist. Paste real command output under Verification.

### AI-assisted changes

If an agent wrote or edited any part of the change, fill in the AI involvement section: which agent and mode, what it did, what a human checked, and any untrusted input it read (CI logs, ticket text). A human must read every changed line before asking for review. Say so in the checklist only if it is true.

## Required checks

All jobs in `.github/workflows/playbook-checks.yml` must pass:

| Job | What it checks |
|---|---|
| markdownlint | Markdown style in every `*.md` file |
| links | Relative links and fragments resolve (offline) |
| secrets | gitleaks scan of the full history |
| powershell | PSScriptAnalyzer with zero findings, then Pester |
| json | `jq empty` on every `*.json` file |
| actionlint | Workflow syntax and common mistakes |

Mark these as required status checks in the branch protection or ruleset for `main`.

## Run the checks locally

You need PowerShell 7, Pester 5.7.1, PSScriptAnalyzer 1.24.0 and `jq`.

```powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser
Install-Module PSScriptAnalyzer -RequiredVersion 1.24.0 -Scope CurrentUser
pwsh ./scripts/Invoke-Checks.ps1
```

The script runs the PowerShell lint, the Pester tests and the JSON check. Markdown lint, link check, secret scan and actionlint run in CI. To run markdownlint locally: `npx markdownlint-cli2@0.23.3 "**/*.md" "#node_modules"`.

## Changing guardrails

Changes to `templates/claude/` (settings and hooks) need a test in `tests/hooks.Tests.ps1` for each rule you add or relax, and a review from the code owner. Do not weaken a rule to make an agent task pass.

## Security

Report vulnerabilities privately. See [SECURITY.md](SECURITY.md).
