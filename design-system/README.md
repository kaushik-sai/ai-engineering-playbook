# Harness design system

The shared tokens and patterns for every page this project publishes: the playbook site, the governed repo template docs and the agentic DevOps workflow dashboards.

- Live reference (private until shared): [Harness design system artifact](https://claude.ai/artifact/KSq8da4H2a456BWntVJbpH)
- Source of truth: [tokens.json](tokens.json). [tokens.css](tokens.css) is generated from it.

## Files

| File | What it is |
|---|---|
| `tokens.json` | Colours (light and dark), type, spacing, radius, shadow, each with a usage note |
| `tokens.css` | CSS custom properties for both themes plus one class per type style. Generated |
| `build_tokens.py` | Builds `tokens.css` and inlines it into `site/playbook.html`. `--check` fails when either is stale (run in CI) |
| `components/GateBadge/` | Pill for a review gate state: pass, needs-human, blocked |
| `components/PermissionChip/` | Chip for a permission rule and its decision: allow, ask, deny |

## Use it

1. Paste `tokens.css` at the top of the page's `<style>`.
2. Load the fonts:

   ```html
   <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Archivo:wght@600..800&family=IBM+Plex+Sans:wght@400;600&family=JetBrains+Mono:wght@400;600&display=swap">
   ```

3. Set `body { background: var(--surface-000); color: var(--ink); font-family: var(--font-sans); }`.
4. Use tokens for every colour. No hex values in component rules.

## Rules that matter

- State colours carry meaning: `allow` is green (pass), `ask` is amber (needs-human), `deny` is red (blocked). Always show the word too.
- `accent` (cobalt) is the only interactive hue. `webbing` (safety orange) is for large display and covers only.
- Borders, not shadows. 16px minimum gutter. Every text pair meets 4.5:1 in both themes (checked when the tokens were made).

## Change it

1. Edit `tokens.json`.
2. Run `python3 design-system/build_tokens.py`.
3. Open a PR. CI runs the `--check` mode, so a stale `tokens.css` fails the build.
