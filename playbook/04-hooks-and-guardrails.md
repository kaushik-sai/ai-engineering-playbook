# Hooks and guardrails

Hooks are commands the harness runs at fixed points in a session. Unlike `CLAUDE.md`, a hook does not depend on the model choosing to comply. A `PreToolUse` hook can stop a tool call before it runs.

## Hook events

| Event | When | Can block | Typical use |
| --- | --- | --- | --- |
| `PreToolUse` | Before a tool runs | Yes (exit 2) | Guard shell commands and file writes |
| `PostToolUse` | After a tool succeeds | No (tool already ran) | Audit log, formatter, test run |
| `UserPromptSubmit` | When you send a prompt | Yes | Add context, reject prompts with secrets |
| `Notification` | When Claude needs attention | No | Desktop or chat alert |
| `Stop` | When the main agent finishes | Yes (can ask it to continue) | Final checks before "done" |
| `SubagentStop` | When a subagent finishes | Yes | Check subagent output |
| `PreCompact` | Before context compaction | No | Save state |
| `SessionStart` | Session begins or resumes | No | Load context, set up environment |
| `SessionEnd` | Session ends | No | Cleanup, flush logs |

## Configuration

Hooks live in settings files. The matcher is a regex on the tool name. An empty string or `*` matches all tools.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "pwsh -NoProfile -File \"$CLAUDE_PROJECT_DIR/.claude/hooks/Guard-BashCommand.ps1\"",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

`$CLAUDE_PROJECT_DIR` is set for hook commands. The full working configuration is [templates/claude/settings.json](../templates/claude/settings.json).

## The exit-code contract

The hook receives JSON on stdin: `session_id`, `transcript_path`, `cwd`, `hook_event_name`, `tool_name`, `tool_input` and, for `PostToolUse`, `tool_response`.

| Exit code | Meaning |
| --- | --- |
| 0 | Proceed |
| 2 | Block. Stderr is shown to Claude as the reason |
| Any other non-zero | Non-blocking error. The action proceeds |

The last row matters: a crash with exit 1 does not block. A guard must catch its own errors and turn them into exit 2.

## The three reference hooks

All three are PowerShell 7 scripts in [templates/claude/hooks/](../templates/claude/hooks/Guard-BashCommand.ps1).

| Hook | Event and matcher | What it does |
| --- | --- | --- |
| [Guard-BashCommand.ps1](../templates/claude/hooks/Guard-BashCommand.ps1) | `PreToolUse`, `Bash` | Blocks destructive or exfiltrating shell commands |
| [Guard-FileWrite.ps1](../templates/claude/hooks/Guard-FileWrite.ps1) | `PreToolUse`, `Write\|Edit\|MultiEdit` | Blocks writes to secret files and content that looks like a secret |
| [Write-AuditLog.ps1](../templates/claude/hooks/Write-AuditLog.ps1) | `PostToolUse`, all tools | Appends one JSON line per tool call to an audit log |

The audit log is JSONL: one object per line, easy to append and to query with `jq` or `ConvertFrom-Json`. Counting the guard blocks in it is a metric (see [09-observability-and-cost.md](09-observability-and-cost.md)).

## Fail closed or fail open

| Hook | On parse error or internal error | Reason |
| --- | --- | --- |
| Guard-BashCommand.ps1 | Fail closed: exit 2 | A false block costs a retry. A false allow can cost data |
| Guard-FileWrite.ps1 | Fail closed: exit 2 | Same |
| Write-AuditLog.ps1 | Fail open: exit 0 | A logging problem must not stop engineering work |

A script can only fail closed while it runs. If `pwsh` is missing, or the script crashes before its own error handling, Claude Code sees a non-zero exit other than 2 and treats it as a non-blocking error: the tool call goes ahead. The template closes that gap in `settings.json` by wrapping each guard as `pwsh ... || exit 2`, so any failure to run the guard blocks the call. The wrapper cannot help when a hook hits its `timeout`. Assume a timed-out hook does not block (check your Claude Code version), keep guards fast, and treat a timeout as an incident.

Failing open for the audit hook has a cost: a gap in the log. Alert if the log stops growing during active sessions (a recommendation, not implemented in this repository).

## Limits of pattern-based guards

A guard that matches command text is a safety net, not a security boundary. A determined or manipulated agent can write a command that a regex misses. Treat guards as one layer on top of permissions and a sandbox (see [05-permissions-and-sandboxing.md](05-permissions-and-sandboxing.md)). Keep deny patterns narrow and well tested so they do not train people to disable them.

## Hooks are code

Hooks run with your user's permissions. A malicious or buggy hook can do anything you can.

- Test them. The reference tests are in [tests/hooks.Tests.ps1](../tests/hooks.Tests.ps1) and run with Pester. Each guard has cases for allowed input, blocked input and malformed input.
- Review them. Put `.claude/hooks/**` and the `hooks` section of settings under CODEOWNERS with the security team as owner.
- Pin and sign nothing implicitly: never download a hook script at run time.

## Failure modes

| Problem | Symptom | Fix |
| --- | --- | --- |
| Slow hook | Every tool call lags | Set `timeout`, avoid network calls, avoid heavy startup |
| Fail-open guard | Malformed input slips through | Wrap in try/catch and exit 2 |
| Over-broad pattern | Legitimate work blocked | Add a test case, narrow the pattern |
| Hook not firing | Matcher typo | Test the matcher regex against tool names |
| Output flood | Noisy stderr | Print one clear reason line |
| Missing PowerShell | Hook errors with a non-blocking code | Check `pwsh` on every runner and image |

Keep block messages short and actionable: say what was blocked and what to do instead.

## Checklist

- [ ] Guard-BashCommand.ps1 and Guard-FileWrite.ps1 are wired as `PreToolUse` hooks in `.claude/settings.json`.
- [ ] Write-AuditLog.ps1 is wired as a `PostToolUse` hook for all tools.
- [ ] Both guards exit 2 on malformed JSON input (tested).
- [ ] Every hook has a `timeout` set.
- [ ] The Pester suite in `tests/hooks.Tests.ps1` passes in CI.
- [ ] `.claude/hooks/**` is covered by CODEOWNERS.
- [ ] The audit log path is outside the workspace or git-ignored, and not world-readable.
- [ ] The team understands that guards are a safety net on top of permissions, not a replacement.
