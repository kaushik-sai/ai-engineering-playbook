# Evidence

What was run for this version, on 2026-10-16, in a Linux cloud container (no Windows machine). Everything not listed here is not verified.

- Repo: [kaushik-sai/ai-engineering-playbook](https://github.com/kaushik-sai/ai-engineering-playbook) (private)
- Interactive playbook (private Artifact): [Harness Engineering Playbook](https://claude.ai/artifact/YTeMPHEDXST1JYaRVUBFeb)
- Design system (private Artifact): [Harness](https://claude.ai/artifact/KSq8da4H2a456BWntVJbpH)

Both Artifacts are private until the owner shares them from the page's Share menu.

## Local checks

| Check | Tool and version | Result |
| --- | --- | --- |
| Markdown lint | markdownlint-cli2 0.23.3, repo config | 0 issues in 37 files |
| PowerShell lint | PSScriptAnalyzer 1.24.0 (from its GitHub release `.nupkg`, SHA-256 `e86c97d44bb1bc8a1de35e753b85ea1d938f6f9f881639a181507e079bca4556`) | 0 findings over `templates/`, `tests/`, `scripts/` |
| Hook tests | `tests/hooks.Tests.ps1` with a minimal Pester stand-in, on PowerShell 7.4.6 | 118 passed, 0 failed, about 37 s |
| Workflow lint | actionlint 1.7.7 (SHA-256 `023070a287cd8cccd71515fedc843f1985bf96c436b7effaecce67290e7e0757`) | clean |
| Internal links | lychee 0.18.1, `--offline --include-fragments` | 0 broken links |
| JSON | `jq empty` on every `*.json` | all valid |
| Design tokens | `python3 design-system/build_tokens.py --check` | up to date |
| Token contrast | WCAG ratio script over the text and background pairs in `tokens.json` | every text pair 4.5:1 or better in light and dark; `webbing` is 3.54:1 in light and is limited to large display |

PowerShell 7.4.6 came from the GitHub release tarball, checked against the release's `hashes.sha256` (`6f6015203c47806c5cc444c19d8ed019695e610fbd948154264bf9ca8e157561`).

## Not verified locally, and why

- **Real Pester 5.7.1.** The PowerShell Gallery and nuget.org are blocked from this container, so the tests ran under a small stand-in runner that implements the `Describe`, `It`, `BeforeAll` and `Should` forms the file uses. The first run under real Pester is the `powershell` job in CI on the first PR.
- **gitleaks and markdownlint-cli2-action.** Run only in CI.
- **Hooks inside a live Claude Code session.** The tests pipe hook JSON into each script the way Claude Code does; the scripts were not wired into a running session here.
- **Windows.** The hooks and tests use only cross-platform PowerShell, but they ran on Linux only.
- **Scenarios end to end.** They are recommended designs. Each scenario file says so.

## Security review of the hooks

A separate review pass (read-only, 17 probes) found 3 high and 6 medium issues in the first version of the hooks. All were fixed test first (34 new or changed cases failed before the fix):

| Finding | Fix |
| --- | --- |
| Bash could edit the guardrails (`sed -i ... .claude/hooks/...`) | New rules `modify-guardrails` and `write-git-dir` |
| `.env` could be read or sent outside the verb list (`curl --data-binary @.env`) | Secret path matched anywhere in the command |
| A guard that fails to start (no `pwsh`, crash) did not block | `settings.json` wraps each guard so a failed start exits 2 |
| `rm -rf` hidden behind `bash -c`, `sudo`, `xargs`; `Remove-Item -r -fo` | Delete check scans every token |
| `/usr/bin/git push --force` | Any token ending in `git` or `git.exe` counts as git |
| `env` after a newline | Multi-line matching |
| False positives on `password: process.env...`, `Select-Object -Skip`, `cp .env.example .env` | Narrowed patterns, with allow tests |

Known limits left as they are: a hook that times out does not block; `cp` of a guardrail file is blocked even when it only copies it out; the audit redaction of `-p <value>` also hides harmless values such as `mkdir -p build`.

## Interactive page

Rendered with Chromium (Playwright 1.56.1) at 1280 px light and 390 px dark:

- no horizontal page scroll and no console errors at either width;
- 17 simulator inputs gave the expected verdict, for example `git push --force origin main` blocked, `git status` runs, `git push origin feature/x` needs-human, `curl --data-binary @.env ...` blocked, `Edit .claude/settings.json` blocked.

## CI

Not run yet. The first PR run of `playbook-checks` is the first CI evidence and will be recorded here.
