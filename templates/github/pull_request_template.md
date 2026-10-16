# Pull request template

Copy this file to `.github/pull_request_template.md` in the target repo. Delete this heading and this line in the copy.

## Summary

- Ticket: PROJ-123 (link)
- Before: what the behaviour or code was.
- After: what it is now.

## How

Short description of the approach and why it was chosen over the alternatives. Name the files that matter most.

## Verification

Commands you ran and the results. Paste real output, not "tests pass".

```powershell
pwsh ./scripts/Invoke-Checks.ps1
```

| Check | Result |
| --- | --- |
| Unit tests | e.g. 42 passed, 0 failed |
| Lint | e.g. 0 findings |
| Not verified | what could only be checked in CI or after deploy |

## Risk and rollback

- Risk level: low / medium / high, and why.
- Blast radius: what breaks if this is wrong.
- Rollback: the exact steps (revert commit, redeploy previous image tag, restore state).

## AI involvement

- Agent used: none / Claude Code (give the mode, for example interactive or headless).
- What the agent did: drafted code, wrote tests, summarised a plan.
- What a human checked: read the full diff, ran the checks locally, reviewed security-sensitive files.
- Untrusted input the agent read (CI logs, ticket text), if any.

## Checklist

- [ ] The diff is small enough to review in one sitting.
- [ ] Tests cover the change and none were skipped or disabled.
- [ ] No secrets, tokens or personal data in the diff or the PR text.
- [ ] Docs and CLAUDE.md are updated if behaviour or commands changed.
- [ ] A human has read every changed line, including generated ones.
- [ ] Required reviewers from CODEOWNERS are requested.
