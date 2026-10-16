# Permissions and sandboxing

Permissions are enforced by the harness, outside the model. They decide which tool calls run without asking, which need a person and which never run. Sandboxing limits what a tool call can reach even when it is allowed.

## The allow, ask, deny model

| Rule list | Colour | Meaning |
| --- | --- | --- |
| `allow` | green | Runs without a prompt |
| `ask` | amber | Prompts a person each time |
| `deny` | red | Never runs |

Precedence: deny wins over ask, and ask wins over allow. If a call matches no rule, the default mode decides.

```json
{
  "permissions": {
    "allow": [
      "Read(./src/**)",
      "Edit(./src/**)",
      "Bash(npm run test:*)",
      "Bash(git diff:*)"
    ],
    "ask": [
      "Bash(git push:*)",
      "WebFetch(domain:docs.claude.com)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./secrets/**)",
      "Bash(curl:*)",
      "Bash(terraform apply:*)"
    ],
    "defaultMode": "default"
  }
}
```

Rule examples: `Bash(npm run test:*)`, `Read(./.env)`, `Edit(./src/**)`, `WebFetch(domain:example.com)` and `mcp__github__create_pull_request`. The working policy is [templates/claude/settings.json](../templates/claude/settings.json).

A note on Bash rules: prefix matching on command strings is convenient but not a security boundary. Pair deny rules with a guard hook (see [04-hooks-and-guardrails.md](04-hooks-and-guardrails.md)) and a sandbox.

## Default modes

`defaultMode` is one of `default`, `acceptEdits`, `plan` or `bypassPermissions`.

| Mode | Behaviour |
| --- | --- |
| `default` | Asks for anything not explicitly allowed |
| `acceptEdits` | Auto-accepts file edits, still asks for other actions |
| `plan` | Read-only planning, no edits or commands |
| `bypassPermissions` | Skips permission prompts. Dangerous |

Recommended mode per environment (a recommendation for this playbook):

| Environment | Mode | Notes |
| --- | --- | --- |
| Laptop, daily work | `default` or `acceptEdits` | Keep `ask` for push and network |
| Laptop, exploring a design | `plan` | No writes |
| CI (headless) | `default` with a tight `--allowedTools` list | No human to ask, so allow only what the job needs |
| Cloud sandbox (ephemeral, no secrets, restricted egress) | `acceptEdits`; `bypassPermissions` only here if at all | Isolation is the control |

## Never bypass outside a sandbox

Never run `bypassPermissions` on a machine that holds credentials, source you cannot lose or network access to internal systems. Use it only inside an isolated, disposable environment: a container or VM with no secrets mounted, no access to production and restricted outbound network.

Block it elsewhere:

```json
{
  "permissions": {
    "disableBypassPermissionsMode": "disable"
  }
}
```

Set this in project settings and, better, in managed settings so individuals cannot override it.

## Managed settings for organisation policy

`managed-settings.json` has the highest precedence and cannot be overridden by user or project files. Use it for rules that apply everywhere:

- `disableBypassPermissionsMode`.
- A baseline `deny` list: secret paths, destructive commands, direct production tooling.
- Required hooks for audit logging.
- An allowlist of MCP servers (see [06-mcp-and-connectors.md](06-mcp-and-connectors.md)).

Where the file lives depends on the operating system. Check the current [settings documentation](https://docs.claude.com/en/docs/claude-code/settings) for the path on your platform, and deploy it with your device management tool. Whether managed policy is in effect for a given machine is something to verify, not assume.

## Network egress control

Data leaves a machine over the network, so control the network:

- Deny `curl`, `wget` and similar in `permissions.deny`, and allow `WebFetch` by domain only.
- In CI and cloud sandboxes, restrict outbound traffic at the firewall or proxy to a short allowlist: the package registry, the Git host, the model API.
- Log denied egress attempts.

Settings rules and hooks can be bypassed by a creative command. Egress control at the network layer cannot.

## Containers and devcontainers

A devcontainer or container gives you a repeatable, disposable workspace:

- Mount only the repository, not your home directory.
- Run as a non-root user. Drop capabilities. No Docker socket.
- Pass no long-lived credentials. Use short-lived tokens scoped to the task.
- Rebuild from a pinned image digest.
- Keep `.claude/settings.json` in the repo so the container inherits it.

This playbook does not ship a devcontainer definition. Treat the list above as requirements for one.

## Checklist

- [ ] `.claude/settings.json` exists, is committed and has explicit `allow`, `ask` and `deny` lists.
- [ ] `deny` covers `.env*`, `secrets/**` and destructive or exfiltrating commands.
- [ ] `defaultMode` is not `bypassPermissions` in any committed file.
- [ ] `disableBypassPermissionsMode` is set to `disable` in managed settings.
- [ ] CI jobs use a minimal `--allowedTools` list and `--max-turns`.
- [ ] Outbound network in CI and cloud sandboxes is limited to a named allowlist.
- [ ] Any use of `bypassPermissions` happens only in a disposable container with no secrets.
- [ ] Settings changes are reviewed through CODEOWNERS.
