"""Build tokens.css from tokens.json, and inline it into site/playbook.html (stdlib only).

Usage: python3 design-system/build_tokens.py [--check]
--check exits 1 when tokens.css or the page's inlined copy is out of date, for CI.
"""
import json
import re
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
PAGE = HERE.parent / "site" / "playbook.html"
MARK = re.compile(r"(/\* tokens:start[^*]*\*/\n)(.*?)(/\* tokens:end \*/)", re.S)


def css_block(selector, decls, indent=""):
    body = "\n".join(f"{indent}  {k}: {v};" for k, v in decls)
    return f"{indent}{selector} {{\n{body}\n{indent}}}"


def build(tokens):
    themes = [t["id"] for t in tokens["color"]["themes"]]
    first, dark = themes[0], "dark"

    def per_theme(family, theme):
        out = []
        for t in tokens.get(family, {}).get("tokens", []):
            v = t["value"]
            out.append((f"--{t['name']}", v if isinstance(v, str) else v.get(theme, v[first])))
        return out

    base = per_theme("color", first) + per_theme("shadow", first)
    for fam in ("spacing", "radius"):
        base += [(f"--{t['name']}", t["value"]) for t in tokens[fam]["tokens"]]
    base += [(f"--font-{k}", v) for k, v in tokens["type"]["families"].items()]
    dark_decls = per_theme("color", dark) + per_theme("shadow", dark) + [("color-scheme", "dark")]

    styles = []
    for group in tokens["type"]["groups"]:
        for s in group["styles"]:
            fam = s.get("family", group["family"])
            decls = [("font-family", f"var(--font-{fam})"), ("font-size", s["fontSize"]),
                     ("line-height", s["lineHeight"]), ("font-weight", str(s["fontWeight"]))]
            if "letterSpacing" in s:
                decls.append(("letter-spacing", s["letterSpacing"]))
            styles.append(css_block(f".{s['name']}", decls))

    parts = [
        f"/* {tokens['name']} tokens v{tokens['version']}. Generated from tokens.json by build_tokens.py. Do not edit by hand. */",
        css_block(":root", base),
        "@media (prefers-color-scheme: dark) {\n" + css_block(':root:not([data-theme="light"])', dark_decls, "  ") + "\n}",
        css_block(':root[data-theme="dark"]', dark_decls),
        "\n\n".join(styles),
    ]
    return "\n\n".join(parts) + "\n"


def inline(page, css):
    if not MARK.search(page):
        raise SystemExit("tokens:start / tokens:end markers not found in site/playbook.html")
    return MARK.sub(lambda m: m.group(1) + css + m.group(3), page, count=1)


def main():
    tokens = json.loads((HERE / "tokens.json").read_text(encoding="utf-8"))
    css = build(tokens)
    target = HERE / "tokens.css"
    page = PAGE.read_text(encoding="utf-8") if PAGE.exists() else None
    if "--check" in sys.argv:
        stale = []
        if not target.exists() or target.read_text(encoding="utf-8") != css:
            stale.append("design-system/tokens.css")
        if page is not None and inline(page, css) != page:
            stale.append("site/playbook.html")
        if stale:
            print("out of date: " + ", ".join(stale) + ". Run python3 design-system/build_tokens.py")
            return 1
        print("tokens.css and site/playbook.html are up to date")
        return 0
    target.write_text(css, encoding="utf-8")
    print(f"wrote {target}")
    if page is not None:
        PAGE.write_text(inline(page, css), encoding="utf-8")
        print(f"inlined tokens into {PAGE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
