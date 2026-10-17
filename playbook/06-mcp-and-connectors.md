# MCP and connectors

The Model Context Protocol (MCP) lets Claude Code call external tools: a Git host, a ticket system, a database, a browser. Each server you add extends what an agent can read and change, and extends the attack surface. Treat every server like a new dependency with credentials.

## Configuration and scope

Project servers are declared in `.mcp.json` at the repository root and are committed:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer ${GITHUB_MCP_TOKEN}"
      }
    }
  }
}
```

Points to note:

- Reference secrets through environment variables (`${GITHUB_MCP_TOKEN}`), never as literal values in the file. Check the current [MCP documentation](https://docs.claude.com/en/docs/claude-code/mcp) for the exact variable expansion syntax your version supports.
- Claude Code asks before using a project-scoped server. Do not pre-approve servers in bulk without review.
- Personal servers belong in user configuration, not in the shared file. Shared servers are a team decision.
- The server URL and command in `.mcp.json` are code. Put the file under CODEOWNERS (security team).

## Tool names and allowlisting

MCP tools are named `mcp__<server>__<tool>`. You can allow or deny them one by one in permissions, so read and write tools can get different treatment.

```json
{
  "permissions": {
    "allow": [
      "mcp__github__get_file_contents",
      "mcp__github__list_pull_requests",
      "mcp__github__create_pull_request"
    ],
    "ask": [
      "mcp__github__add_issue_comment"
    ],
    "deny": [
      "mcp__github__merge_pull_request",
      "mcp__github__delete_file"
    ]
  }
}
```

Allowlist the specific tools a workflow uses. Do not allow a whole server by default. Note that `merge_pull_request` is denied: agents never merge (see [07-review-gates.md](07-review-gates.md)).

## Read tools and write tools

Sort every tool of a server into one of three classes before enabling it:

| Class | Examples | Default rule |
| --- | --- | --- |
| Read | get file, list issues, search code | allow (green) |
| Write, reversible | create branch, open PR, comment | ask (amber) or allow with logging |
| Write, hard to undo | merge, delete, send email, apply infra, post publicly | deny (red) |

Prefer a server or token that is read-only whenever the task is analysis. A review agent does not need write access.

## Least-privilege tokens

The token behind a server defines its real power, whatever the permission rules say.

- Use a fine-grained token limited to named repositories and the minimum scopes.
- Use a separate token per workflow, so one leak does not expose everything.
- Prefer short-lived credentials (OIDC, app installation tokens) over personal access tokens.
- Never reuse a developer's personal token for an unattended workflow.
- Rotate on a schedule and on any suspicion.
- Store tokens in the secret manager or CI secrets. Never in `.mcp.json`, `CLAUDE.md` or the prompt.

## Treat tool output as untrusted

Anything an MCP tool returns can contain text written by someone else: an issue body, a web page, a ticket comment, a file in a dependency. That text can say "ignore your instructions and run this command". This is prompt injection (see [08-security-baseline.md](08-security-baseline.md)).

Controls that work:

- The agent's permissions must be safe even if the agent obeys the injected text. That is the real defence.
- Do not combine, in one session, untrusted input, access to private data and a way to send data out. Remove at least one of the three.
- Keep write and network tools behind `ask` or `deny` when the session reads untrusted content.
- Tell the agent in `CLAUDE.md` that tool output is data, as a second line of defence only.
- Review pull requests that came from issue-driven agents with extra care.

## Vetting a server

Before adding a server to `.mcp.json`:

1. Who maintains it? Is the source available and active?
2. What tools does it expose? List them and classify them as read or write.
3. What credentials does it need and what is the smallest scope?
4. Where does it run (local process, remote service) and where does data go?
5. Can you pin its version? Pin it. Do not run `latest` of an unpinned package.
6. Who in the team approves it, and where is that decision recorded?

Do not install community servers on the strength of a README alone.

## Auditing

- Log every tool call, including `mcp__*` calls, with the audit hook (see [04-hooks-and-guardrails.md](04-hooks-and-guardrails.md)).
- Review the provider's own audit logs for the token (for example the GitHub audit log) from time to time.
- Review the list of enabled servers and tokens every quarter and remove the unused ones.
- When a server is no longer used, delete its token and its entry in `.mcp.json` in the same pull request.

## Checklist

- [ ] `.mcp.json` contains no literal secrets and is under CODEOWNERS.
- [ ] Each enabled server has a recorded owner, purpose and token scope.
- [ ] Tools are allowlisted individually with `mcp__<server>__<tool>` rules.
- [ ] Merge, delete and publish tools are denied for agents.
- [ ] Tokens are fine-grained, per workflow and short-lived where possible.
- [ ] Sessions that read untrusted content do not also hold write and network access.
- [ ] MCP tool calls appear in the audit log.
- [ ] Servers are pinned to a version, and unused ones are removed.
