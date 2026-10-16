# GateBadge

A pill that shows the state of one review gate: pass, needs-human or blocked.

- Markup: `<span class="gate gate--pass"><span class="gate__dot"></span>pass</span>`; swap the modifier for `gate--human` or `gate--blocked`.
- Always show the word. The dot is a second cue, never the only one.
- Use `label` type, `radius-pill`, the state's `-tint` as background and the state colour as text.
- The consumer provides the gate name next to it (for example "CI: Pester").
