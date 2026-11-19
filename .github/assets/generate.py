"""Generate the README's SVG components in dark and light variants.

Run: python3 .github/assets/generate.py  (writes the SVGs beside this file)
"""
import sys
from pathlib import Path

OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent
OUT.mkdir(parents=True, exist_ok=True)

THEMES = {
    "dark": dict(bg="#141413", panel="#1f1e1b", border="#33312c", text="#f0eee6",
                 muted="#9c9a92", accent="#d97757", accent2="#e8b07a", ok="#9ccc85",
                 dot="#f0eee6", dot_op="0.07", glow_op="0.20", shadow="#000000"),
    "light": dict(bg="#faf9f5", panel="#ffffff", border="#e3dfd3", text="#1f1e1b",
                  muted="#6b6962", accent="#c2603f", accent2="#b5793a", ok="#4d7c3a",
                  dot="#1f1e1b", dot_op="0.08", glow_op="0.14", shadow="#8a7f6a"),
}

SERIF = "'Iowan Old Style','Palatino Linotype',Palatino,Georgia,serif"
SANS = "'Avenir Next','Segoe UI','Helvetica Neue',sans-serif"
MONO = "'JetBrains Mono','SF Mono',Menlo,Consolas,'Courier New',monospace"


def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def svg(w, h, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" '
            f'width="{w}" height="{h}">\n{body}\n</svg>\n')


def banner(t):
    W, H = 840, 300
    tx, ty, tw, th = 432, 36, 380, 236
    cycle = 10.0
    lines = [
        ("cmd", "./setup.sh --check"),
        ("head", "Files"),
        ("ok", "~/.claude/CLAUDE.md"),
        ("ok", "~/.claude/hooks/block_onedrive.sh"),
        ("head", "Settings"),
        ("ok", "listing budget and OneDrive hook"),
        ("head", "Plugins"),
        ("ok", "megapowers@megapowers"),
        ("head", "MCP servers"),
        ("ok", "microsoft-learn"),
    ]
    x0, y0, step = tx + 18, ty + 52, 16.5
    out = []
    for i, (kind, s) in enumerate(lines):
        y = y0 + i * step
        if kind == "cmd":
            out.append(
                f'<clipPath id="type"><rect x="{x0}" y="{y-12}" width="0" height="16">'
                f'<animate attributeName="width" values="0;0;200;200" keyTimes="0;0.04;0.13;1" '
                f'dur="{cycle}s" repeatCount="indefinite"/></rect></clipPath>'
                f'<text x="{x0}" y="{y}" font-family="{MONO}" font-size="11.5" fill="{t["accent"]}">$</text>'
                f'<text x="{x0+14}" y="{y}" font-family="{MONO}" font-size="11.5" fill="{t["text"]}" '
                f'clip-path="url(#type)">{esc(s)}</text>')
            continue
        start = 0.17 + (i - 1) * 0.055
        kt = f"0;{start:.3f};{start+0.01:.3f};0.94;1"
        anim = (f'<animate attributeName="opacity" values="0;0;1;1;0" keyTimes="{kt}" '
                f'dur="{cycle}s" repeatCount="indefinite"/>')
        if kind == "head":
            out.append(f'<g>{anim}<text x="{x0}" y="{y}" font-family="{MONO}" font-size="11.5" '
                       f'fill="{t["muted"]}">{esc(s)}</text></g>')
        else:
            out.append(f'<g>{anim}<text x="{x0+16}" y="{y}" font-family="{MONO}" font-size="11.5" '
                       f'fill="{t["ok"]}">ok</text><text x="{x0+56}" y="{y}" font-family="{MONO}" '
                       f'font-size="11.5" fill="{t["text"]}">{esc(s)}</text></g>')
    cy = y0 + len(lines) * step
    out.append(f'<rect x="{x0}" y="{cy-10}" width="7" height="13" fill="{t["accent"]}">'
               f'<animate attributeName="opacity" values="1;0" dur="1s" calcMode="discrete" '
               f'repeatCount="indefinite"/></rect>')
    term_lines = "\n  ".join(out)

    return svg(W, H, f'''  <defs>
    <pattern id="dots" width="18" height="18" patternUnits="userSpaceOnUse">
      <circle cx="2" cy="2" r="1" fill="{t["dot"]}" fill-opacity="{t["dot_op"]}"/>
    </pattern>
    <filter id="blur" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="50"/></filter>
    <filter id="shadow" x="-10%" y="-10%" width="120%" height="130%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="{t["shadow"]}" flood-opacity="0.28"/>
    </filter>
    <linearGradient id="shine" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="{t["accent"]}"/>
      <stop offset="0.5" stop-color="{t["accent2"]}"/>
      <stop offset="1" stop-color="{t["accent"]}"/>
      <animate attributeName="x1" values="0;-1;0" dur="6s" repeatCount="indefinite"/>
      <animate attributeName="x2" values="1;0;1" dur="6s" repeatCount="indefinite"/>
    </linearGradient>
    <clipPath id="card"><rect width="{W}" height="{H}" rx="18"/></clipPath>
  </defs>
  <g clip-path="url(#card)">
    <rect width="{W}" height="{H}" fill="{t["bg"]}"/>
    <rect width="{W}" height="{H}" fill="url(#dots)"/>
    <ellipse cx="150" cy="290" rx="190" ry="130" fill="{t["accent"]}" opacity="{t["glow_op"]}" filter="url(#blur)">
      <animate attributeName="cx" values="150;210;120;150" dur="12s" repeatCount="indefinite"/>
    </ellipse>
    <ellipse cx="760" cy="20" rx="160" ry="110" fill="{t["accent2"]}" opacity="{t["glow_op"]}" filter="url(#blur)">
      <animate attributeName="cy" values="20;60;20" dur="9s" repeatCount="indefinite"/>
    </ellipse>
  </g>
  <rect x="0.5" y="0.5" width="{W-1}" height="{H-1}" rx="18" fill="none" stroke="{t["border"]}"/>

  <text x="48" y="86" font-family="{MONO}" font-size="12" letter-spacing="1.5" fill="{t["accent"]}">~/.claude  ⇄  git</text>
  <text x="44" y="150" font-family="{SERIF}" font-size="60" font-weight="700" letter-spacing="-1" fill="{t["text"]}">AI-<tspan fill="url(#shine)">Tooling</tspan></text>
  <rect x="48" y="170" width="64" height="3" rx="1.5" fill="{t["accent"]}">
    <animate attributeName="width" values="64;150;64" dur="5s" repeatCount="indefinite"/>
  </rect>
  <text font-family="{SANS}" font-size="16" fill="{t["muted"]}">
    <tspan x="48" y="208">Prompts, instructions and skills for Claude,</tspan>
    <tspan x="48" y="230">kept in git and synced to the live apps.</tspan>
  </text>
  <text x="48" y="266" font-family="{MONO}" font-size="11.5" fill="{t["muted"]}">setup <tspan fill="{t["accent"]}">·</tspan> check <tspan fill="{t["accent"]}">·</tspan> repair</text>

  <g filter="url(#shadow)">
    <rect x="{tx}" y="{ty}" width="{tw}" height="{th}" rx="12" fill="{t["panel"]}" stroke="{t["border"]}"/>
  </g>
  <line x1="{tx}" y1="{ty+28}" x2="{tx+tw}" y2="{ty+28}" stroke="{t["border"]}"/>
  <circle cx="{tx+18}" cy="{ty+14}" r="4.5" fill="{t["accent"]}"/>
  <circle cx="{tx+33}" cy="{ty+14}" r="4.5" fill="{t["accent2"]}"/>
  <circle cx="{tx+48}" cy="{ty+14}" r="4.5" fill="{t["border"]}"/>
  <text x="{tx+tw/2}" y="{ty+18}" text-anchor="middle" font-family="{MONO}" font-size="10.5" fill="{t["muted"]}">zsh — AI-Tooling</text>
  {term_lines}''')


def flow(t):
    W, H = 840, 230
    nodes = [  # x, title, line1, line2, highlight
        (20, "Live apps", "~/.claude", "desktop app · claude.ai", False),
        (325, "This repo", "the copies, in git", "Claude/ · setup.sh", True),
        (630, "Cloud sessions", "claude.ai/code", "env setup script", False),
    ]
    y, w, h = 72, 190, 96
    parts = []
    for x, title, l1, l2, hi in nodes:
        if hi:
            parts.append(f'<rect x="{x-6}" y="{y-6}" width="{w+12}" height="{h+12}" rx="16" fill="{t["accent"]}" '
                         f'filter="url(#glow)"><animate attributeName="opacity" values="0.15;0.4;0.15" dur="4s" '
                         f'repeatCount="indefinite"/></rect>')
        stroke = t["accent"] if hi else t["border"]
        parts.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="{t["panel"]}" stroke="{stroke}" '
            f'stroke-width="{1.5 if hi else 1}"/>'
            f'<text x="{x+20}" y="{y+36}" font-family="{SERIF}" font-size="19" font-weight="700" fill="{t["text"]}">{title}</text>'
            f'<text x="{x+20}" y="{y+60}" font-family="{MONO}" font-size="11" fill="{t["muted"]}">{esc(l1)}</text>'
            f'<text x="{x+20}" y="{y+78}" font-family="{MONO}" font-size="11" fill="{t["muted"]}">{esc(l2)}</text>')

    def edge(d, label_x, label_y, label):
        return (f'<path d="{d}" fill="none" stroke="{t["accent"]}" stroke-width="1.6" stroke-dasharray="5 6" '
                f'marker-end="url(#arrow)"><animate attributeName="stroke-dashoffset" values="22;0" dur="1.2s" '
                f'repeatCount="indefinite"/></path>'
                f'<text x="{label_x}" y="{label_y}" text-anchor="middle" font-family="{MONO}" font-size="11" '
                f'fill="{t["text"]}">{esc(label)}</text>')

    parts.append(edge("M 210 96 C 245 40, 285 40, 318 92", 267, 46, "copy back, commit"))
    parts.append(edge("M 325 146 C 290 204, 250 204, 217 150", 267, 208, "./setup.sh"))
    parts.append(edge("M 515 120 L 622 120", 572, 108, "--cloud"))
    parts.append(f'<text x="572" y="138" text-anchor="middle" font-family="{SANS}" font-size="11" '
                 f'fill="{t["muted"]}">paste weekly</text>')
    body = "\n  ".join(parts)
    return svg(W, H, f'''  <defs>
    <filter id="glow" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="10"/></filter>
    <marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M 0 0 L 10 5 L 0 10 z" fill="{t["accent"]}"/>
    </marker>
  </defs>
  {body}''')


def coverage(t):
    W, H = 840, 236
    tiles = [
        ("¶", "CLAUDE.md", "global instructions"),
        ("#!", "Hooks", "block_onedrive.sh"),
        ("✦", "Skills", "~/.claude/skills/"),
        ("{}", "Settings", "skill budget, OneDrive hook"),
        ("++", "Plugins", "4 plugins, 2 marketplaces"),
        ("⇄", "MCP server", "microsoft-learn"),
    ]
    tw, th, gap, mx = 256, 100, 16, 20
    parts = []
    for i, (glyph, title, sub) in enumerate(tiles):
        x = mx + (i % 3) * (tw + gap)
        y = 10 + (i // 3) * (th + gap)
        parts.append(
            f'<rect x="{x}" y="{y}" width="{tw}" height="{th}" rx="12" fill="{t["panel"]}" stroke="{t["border"]}"/>'
            f'<rect x="{x}" y="{y}" width="{tw}" height="{th}" rx="12" fill="none" stroke="{t["accent"]}" '
            f'stroke-width="1.5" opacity="0"><animate attributeName="opacity" values="0;0;1;0;0" '
            f'keyTimes="0;{i/7:.3f};{i/7+0.095:.3f};{i/7+0.19:.3f};1" dur="8.4s" repeatCount="indefinite"/></rect>'
            f'<text x="{x+22}" y="{y+56}" font-family="{MONO}" font-size="22" font-weight="700" '
            f'fill="{t["accent"]}">{esc(glyph)}</text>'
            f'<text x="{x+66}" y="{y+45}" font-family="{SERIF}" font-size="18" font-weight="700" '
            f'fill="{t["text"]}">{esc(title)}</text>'
            f'<text x="{x+66}" y="{y+68}" font-family="{MONO}" font-size="11" fill="{t["muted"]}">{esc(sub)}</text>')
    return svg(W, H, "  " + "\n  ".join(parts))


def divider(t):
    W, H = 840, 24
    return svg(W, H, f'''  <defs>
    <linearGradient id="fade" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stop-color="{t["accent"]}" stop-opacity="0"/>
      <stop offset="0.5" stop-color="{t["accent"]}" stop-opacity="0.7"/>
      <stop offset="1" stop-color="{t["accent"]}" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <rect x="0" y="11.5" width="{W}" height="1" fill="url(#fade)"/>
  <rect x="414" y="6" width="12" height="12" fill="{t["bg"]}" stroke="{t["accent"]}" transform="rotate(45 420 12)">
    <animate attributeName="opacity" values="0.5;1;0.5" dur="4s" repeatCount="indefinite"/>
  </rect>''')


for name, fn in [("banner", banner), ("flow", flow), ("coverage", coverage), ("divider", divider)]:
    for theme, t in THEMES.items():
        (OUT / f"{name}-{theme}.svg").write_text(fn(t), encoding="utf-8")
print("ok")
