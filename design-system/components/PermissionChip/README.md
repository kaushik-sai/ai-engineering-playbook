# PermissionChip

A chip that pairs a Claude Code permission rule with its decision: allow, ask or deny.

- Markup: `<span class="perm perm--deny"><b>deny</b><code>Read(./.env)</code></span>`; modifiers `perm--allow`, `perm--ask`, `perm--deny`.
- The rule is `code` type in `ink`; the decision word is `label` type in the state colour on the state's `-tint`.
- Use it in tables of rules and in diagrams. Order lists deny first, then ask, then allow, because that is the order Claude Code evaluates them.
