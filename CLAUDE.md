# CLAUDE.md

This repo is a playbook (Markdown), a set of copy-in templates, three PowerShell hooks with Pester tests, and a design system. There is no service to run.

## Commands

- All checks: `pwsh ./scripts/Invoke-Checks.ps1`
- Markdown lint only: `npx --yes markdownlint-cli2@0.23.3 "**/*.md" "#node_modules"`
- Hook tests only: `pwsh -c "Invoke-Pester ./tests -Output Detailed"`
- Rebuild design tokens: `python3 design-system/build_tokens.py` (CI runs `--check`)

## Conventions

- Plain, short sentences. No marketing tone, no emojis, no em dashes.
- One H1 per file. Every playbook chapter and scenario ends with `## Checklist`.
- Tables use `| --- |` separators. Fenced code always has a language.
- Say what is verified and what is a recommendation. Evidence goes in `docs/EVIDENCE.md`, choices in `docs/DECISIONS.md` (numbered: Question | Decision | Why).
- Scenario sections are fixed: Situation, Trigger, Who does what, Flow, Guardrails, Review gates, Failure modes and responses, Metrics, Try it, Checklist.
- Hook scripts: rules as data at the top, fail closed on bad input, zero PSScriptAnalyzer findings, a Pester case per rule.

## Do not

- Do not edit `templates/claude/` hooks or settings without adding or updating a test in `tests/hooks.Tests.ps1`.
- Do not hand-edit `design-system/tokens.css`. Edit `tokens.json` and rebuild.
- Do not copy code or names from employer repositories.
- Do not commit to `main`. Branch as `docs/*` or `feature/*` and open a PR.
