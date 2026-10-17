# Runbook

Day-to-day tasks for maintaining the playbook.

## Run all checks locally

```powershell
pwsh ./scripts/Invoke-Checks.ps1
```

Expected: every step reports success and the script exits 0. CI runs the same checks plus link check, gitleaks and actionlint.

## Change a guardrail (settings or a hook)

1. Branch: `git switch -c feature/guard-<what>`.
2. Write the failing Pester case first in `tests/hooks.Tests.ps1`.
3. Change the rule list at the top of the hook script, or the rule in `templates/claude/settings.json`.
4. Run `pwsh ./scripts/Invoke-Checks.ps1`.
5. Update the simulator rules in `site/playbook.html` (search for `RULES`) so the page matches.
6. Open a PR. `CODEOWNERS` requires the owner's review for `templates/claude/`, `tests/` and `.github/`.

## Add a scenario

1. Copy the section list from any file in `scenarios/` (the sections are fixed, see `CLAUDE.md`).
2. Add a row to `scenarios/README.md` with risk level, maturity level and key gate.
3. Add a card to the `SCENARIOS` list in `site/playbook.html`.
4. Say in the file what has and has not been run for real.

## Change the design system

1. Edit `design-system/tokens.json`.
2. Run `python3 design-system/build_tokens.py`.
3. The script also inlines `tokens.css` into `site/playbook.html` between the `tokens:start` and `tokens:end` comments. Commit both.
4. Copy `design-system/` to the project's shared `design-system/` folder so the sibling repos pick it up.

## Republish the interactive page

The page is a Claude Artifact built from `site/playbook.html`. Republish it from a Claude session with the Artifact tool, using the same artifact URL (in `docs/EVIDENCE.md`) so the link stays the same. The artifact is private until it is shared from its Share menu.

## When CI fails

| Job | Usual cause | Fix |
| --- | --- | --- |
| markdownlint | Table separator style, missing code language, two blank lines | Run `npx --yes markdownlint-cli2@0.23.3 --fix "**/*.md" "#node_modules"` and review the diff |
| links | A renamed file | Fix the relative link; never add the path to an ignore list to get green |
| secrets | A real secret, or a test fixture that looks like one | Real: rotate it first, then remove it. Fixture: build it from parts at runtime, as the Pester tests do |
| powershell | A ScriptAnalyzer finding or a failing test | Fix the code. Never skip or disable a test |
| tokens | `tokens.css` is stale | Run the build script and commit the result |
| actionlint | Workflow syntax | Fix the workflow. Keep actions pinned by full SHA |
