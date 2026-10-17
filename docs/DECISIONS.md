# Decisions

Ambiguities and the call made, one line each.

## Scope and format

| # | Question | Decision | Why |
| --- | --- | --- | --- |
| 1 | What is the playbook's source of truth | Markdown in this repo; the Artifact page is a view of it | Markdown diffs and reviews like code; the page can be rebuilt from it |
| 2 | Where the interactive version lives | One static HTML page (`site/playbook.html`) published as a private Claude Artifact | No hosting to run; the page has no data of its own, so private-by-default is safe |
| 3 | Repo visibility | Created private | Safer default; the owner can make it public. No secrets are in it either way |
| 4 | License | MIT | Matches a portfolio repo meant to be reused |
| 5 | Shell for scripts and hooks | PowerShell 7 | The owner's main shell; runs on Windows, Linux and the GitHub Ubuntu runner |
| 6 | How the playbook relates to the sibling repos | It is the standard; [governed-repo-template](https://github.com/kaushik-sai/governed-repo-template) and [agentic-devops-workflow](https://github.com/kaushik-sai/agentic-devops-workflow) build from it and link back | One place to change a rule |

## Guardrails

| # | Question | Decision | Why |
| --- | --- | --- | --- |
| 7 | Fail open or closed on unparseable hook input | Guard hooks fail closed (exit 2); the audit hook never blocks | A guard that lets bad input through is not a guard; a broken audit line should not stop work |
| 8 | Rules in permissions or in hooks | Both: `deny` rules for clear cases, hooks for what a prefix rule cannot see (push target, pipes, file content) | Two layers catch different mistakes; neither alone is enough |
| 9 | Can the agent edit its own guardrails | No: denied in settings and blocked by `Guard-FileWrite` | Otherwise every other control can be switched off from inside a session |
| 10 | Default permission mode | `default`, with `disableBypassPermissionsMode` set to `disable` | Unknown actions prompt a person; bypass is for isolated sandboxes only (chapter 05) |
| 11 | Push policy | `git push` is ask; force push and push to `main` or `master` are blocked; `--force-with-lease` allowed on feature branches | Agents work on branches; history on main is shared |
| 12 | Infrastructure | `terraform apply` and `destroy` denied and blocked; `plan` allowed | Real infrastructure changes need a person (scenario 05) |
| 13 | Audit log contents | Tool name, session, a short redacted summary; never file contents | Useful for metrics and incidents without becoming a secret store |
| 14 | Where the audit log goes | `.claude/audit/tool-use.jsonl`, git-ignored | Local by default; chapter 09 says how to ship it centrally at level 4 |

## Checks and supply chain

| # | Question | Decision | Why |
| --- | --- | --- | --- |
| 15 | CI platform | GitHub Actions | The repo lives on GitHub and the checks are public on each PR |
| 16 | Pinning | Actions pinned by full commit SHA with a version comment; Pester 5.7.1, PSScriptAnalyzer 1.24.0, markdownlint-cli2 0.23.3, actionlint 1.7.7 with SHA-256 check | Floating tags can change under you |
| 17 | Link check scope | Offline: relative links and fragments only | The gate should not fail because an outside site is slow; sibling repos may still be private |
| 18 | Secret scan | gitleaks on full history; the only allowlisted file is the hook test, which builds fake secrets from parts | Tests need secret-shaped input without committing a real-looking secret |
| 19 | markdownlint rules off | MD013 (line length), MD033 (inline HTML), MD041, MD060 (table column style) | Long prose lines and `<placeholder>` text are intended; tables use one compact style |
| 20 | Dependency updates | Dependabot for GitHub Actions, weekly | Keeps SHA pins current through reviewed PRs |

## Design system

| # | Question | Decision | Why |
| --- | --- | --- | --- |
| 21 | Build a design system or reuse one | Build a small one ("Harness"), published as a Design System artifact and as files | No existing system in the project; the three repos' pages should look like one product |
| 22 | State colours | allow / pass green, ask / needs-human amber, deny / blocked red, each with a tint and always with the word | The colours encode the control model, and the word keeps it readable without colour |
| 23 | Fonts | Archivo (display), IBM Plex Sans (body), JetBrains Mono (code), all Google Fonts | Free, hosted where Artifacts allow, distinct from default stacks |
| 24 | Keep the page and tokens in sync | `build_tokens.py` inlines `tokens.css` into the page; CI runs `--check` | A stale copy fails the build instead of drifting |
| 25 | Token build language | Python standard library | Runs on any CI runner with no install; there is no PowerShell module to wrap |

## Content

| # | Question | Decision | Why |
| --- | --- | --- | --- |
| 26 | Scenario examples | A generic company (`orders-svc`, `PLAT-342`) on GitHub, Azure Pipelines or Actions, Terraform on Azure, Jira | Close to real work without copying any employer's code or names |
| 27 | Unverified advice | Marked as a recommendation in the text | Readers act on it; they need to know what was run |
| 28 | Hook and permission order | Docs and page say hooks run first, then rules, and either can stop a call | Matches how Claude Code applies `PreToolUse` before the permission check |
