# Observability and cost

You cannot tell whether a harness works by how it feels. Measure outcomes (did the work land?), quality (did it need rework?) and cost (what did it take?). Keep the measures few, cheap to collect and hard to game.

## What to measure

| Metric | Question it answers | Source |
| --- | --- | --- |
| PR lead time | How long from first commit to merge? | Git host API |
| Agent PR acceptance rate | What share of agent PRs are merged without being closed? | Git host API, label `agent` |
| CI pass on first push | Does the agent hand over work that passes checks? | CI run history |
| Review rounds | How many times did a human request changes? | PR review events |
| Tokens and cost per merged PR | What does a landed change cost? | Headless JSON output, token weather |
| Hook block counts | How often do guards fire, and for which rule? | Audit log (JSONL) |
| Rework after merge | Reverts and follow-up fixes within a week | Git history |
| Time in `needs-human` | Where do humans become the bottleneck? | PR timeline |

Read them as a set. A falling lead time with a falling acceptance rate means speed is being bought with rework. Do not set individual targets on them, because people then optimise the number instead of the work. These are recommendations. This repository does not ship a metrics pipeline.

## Live views: the two project mods

This project loads two local mods through `CLAUDE_CODE_PLUGIN_DIRS`. They give a live view while you work.

| Mod | Command | Shows |
| --- | --- | --- |
| agents panel | `/agents-panel` | A pane listing subagents and their status while an orchestrated task runs |
| token weather | `/tokens` | Context fill, rate-limit windows and session cost |

Use the agents panel to spot a stuck or idle subagent early. Use token weather to see context filling up before quality drops, and to read the cost of the session as it grows. Both are for the person at the keyboard. They do not replace durable records in CI and the audit log.

## Audit log

The `Write-AuditLog.ps1` hook ([04-hooks-and-guardrails.md](04-hooks-and-guardrails.md)) appends one JSON line per tool call. Count guard blocks and tool use from it:

```powershell
Get-Content .claude/audit/tool-use.jsonl |
  ForEach-Object { $_ | ConvertFrom-Json } |
  Group-Object tool_name |
  Sort-Object Count -Descending |
  Select-Object Count, Name
```

The log path and field names are defined by the hook script in [templates/claude/hooks/](../templates/claude/hooks/Write-AuditLog.ps1). Adjust the query above to match it. Do not put secrets or file contents in audit lines, and restrict who can read the file.

## Headless runs and JSON output

In CI, run Claude Code non-interactively and keep the machine-readable result:

```bash
claude -p "Fix the failing test in tests/api and open no PR" \
  --output-format json \
  --max-turns 12 \
  --allowedTools "Read,Edit,Bash(npm run test:*)" \
  > claude-result.json
```

- `--output-format json` returns a single JSON result. `stream-json` emits events as they happen.
- Store the JSON as a CI artifact. Fields such as cost and turn count in it feed your cost per PR metric. Check the current [SDK documentation](https://docs.claude.com/en/docs/claude-code/sdk) for the exact field names in your version.
- Never print the API key. It lives in the secret store as `ANTHROPIC_API_KEY`.

## Budgets per task

A budget turns a runaway into a visible stop.

| Budget | How |
| --- | --- |
| Turns | `--max-turns` on every headless run |
| Wall-clock time | CI job `timeout-minutes` |
| Model and effort | Set per subagent from the table in [03-skills-subagents-orchestration.md](03-skills-subagents-orchestration.md) |
| Context | New session per task, delegate searches to subagents |
| Spend | Alert on cost per run and per day; cap at the provider where possible |

Starting points (recommendations, tune with your data): a small fix gets 10 to 15 turns, a feature on a branch 30 to 40. If a run hits the limit, a human looks at why before raising it.

## Cost levers

1. Use the cheapest model that does the job (haiku for lookups, sonnet for specified work).
2. Keep `CLAUDE.md` short, since it is paid for on every session.
3. Give precise briefs, so the agent does not explore blindly.
4. Stop on repeated failure instead of looping.
5. Cache-friendly habits: keep stable context first and avoid re-pasting large files.

## Reviewing the numbers

Hold a short monthly review. Look at the trend lines, three of the worst agent PRs and the top guard blocks. Each review should end with one change to the harness: a new rule, a sharper brief or a removed rule that only caused noise.

## Checklist

- [ ] Agent PRs carry a label so acceptance rate can be computed.
- [ ] Every headless run sets `--max-turns` and a CI timeout.
- [ ] JSON output of headless runs is stored as a CI artifact.
- [ ] The audit log is written, rotated and access-controlled.
- [ ] A query for guard block counts exists and has been run.
- [ ] The agents panel and token weather mods load in a fresh checkout.
- [ ] A cost alert exists at the provider or in CI.
- [ ] There is a monthly metrics review with an owner.
