"""Aradhya original SVG art kit -- the shared drawing primitives.

Every image row in assets/manifest.json is currently a PLACEHOLDER lifted from
the Ishvarvaani reference app, which is the release blocker: validate.py raises
`placeholder-asset` and build.py --strict refuses a release while any row is
still flagged replace_before_ship. This module is the drawing library that
gen_svg_art.py uses to emit OUR OWN artwork for those slots, as SVG.

Deliberately narrow constraints so the output renders identically in a browser,
in flutter_svg, and in any rasteriser:

  * no <text> and no font references -- SVG text needs the font at render time
  * no filters (feGaussianBlur / feTurbulence) -- flutter_svg drops most of them
  * shapes, paths, linear/radial gradients, opacity, transform, clipPath only

Palette is reference/DESIGN-TOKENS.md; the dashed "stitch" is the signature
motif from lib/shared/widgets/stitched_border.dart.
"""

from __future__ import annotations

import math

# --------------------------------------------------------------- palette ---

PAPER = "#FDF8F5"
PAPER_WARM = "#F7ECDC"
PAPER_DEEP = "#F1D9B9"
CREAM = "#FFFEFA"

TERRA = "#A73015"
TERRA_DARK = "#6E1F10"
BROWN = "#983A18"
BARK = "#753F2C"
INK = "#5C3B28"

GOLD = "#C0A062"
GOLD_BRIGHT = "#D4AF37"
GOLD_PALE = "#E8D6A8"

PURPLE = "#5A2EA8"
PURPLE_LT = "#8B6AC7"
ROSE = "#9C2950"
ROSE_LT = "#E07A98"
GREEN = "#25533F"
GREEN_LT = "#5F8C6E"
TEAL = "#7FD9DC"
INDIGO = "#4A4E7C"
SAFFRON = "#FF9F43"
AMBER = "#FDE57E"

# Where seated_figure()'s seat line falls, as a fraction of the `h` it is
# given. Callers that place a pedestal or a companion under the figure must
# measure from top + h * SEAT_T, not top + h -- nothing is drawn below this.
SEAT_T = 0.76

SKIN = "#EFCBA4"
SKIN_SHADE = "#D8AC81"
SKIN_BLUE = "#8CA6C9"  # Krishna / Rama, the traditional blue-dark complexion
STONE = "#E6DBC9"
STONE_SHADE = "#CDBFA6"


# --------------------------------------------------------------- helpers ---


def f(v: float) -> str:
    """Compact number formatting -- keeps the emitted files small."""
    s = f"{v:.2f}"
    if "." in s:
        s = s.rstrip("0").rstrip(".")
    return s if s not in ("", "-0") else "0"


def _hex(c: str) -> tuple[int, int, int]:
    c = c.lstrip("#")
    return int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16)


def shade(c: str, k: float = 0.86) -> str:
    """Darken towards black. The form-shading ramp -- flat fills read as toys."""
    r, g, b = _hex(c)
    return "#%02X%02X%02X" % (int(r * k), int(g * k), int(b * k))


def tint(c: str, k: float = 1.12) -> str:
    """Lighten towards white, for highlights on gold and cloth."""
    r, g, b = _hex(c)
    return "#%02X%02X%02X" % tuple(
        min(255, int(v + (255 - v) * (k - 1.0) * 2.2)) for v in (r, g, b)
    )


def lit(d: str, base: str, dx: float, dy: float, k: float = 0.86) -> str:
    """Give a path volume: the shade beneath, the lit copy offset off it.

    One light, always upper-left, so every mass in a figure agrees. Offsets
    stay small enough that features drawn on top in absolute coordinates do
    not visibly drift.
    """
    return (
        f'<path d="{d}" fill="{shade(base, k)}"/>'
        f'<g transform="translate({f(dx)} {f(dy)})">'
        f'<path d="{d}" fill="{base}"/></g>'
    )


def svg(w: float, h: float, body: str, defs: str = "", title: str = "") -> str:
    out = [
        '<svg xmlns="http://www.w3.org/2000/svg" ',
        f'width="{f(w)}" height="{f(h)}" viewBox="0 0 {f(w)} {f(h)}">',
    ]
    if title:
        out.append(f"<title>{title}</title>")
    if defs:
        out.append(f"<defs>{defs}</defs>")
    out.append(body)
    out.append("</svg>")
    return "".join(out)


def lin(gid: str, c1: str, c2: str, angle: float = 135.0) -> str:
    a = math.radians(angle)
    x1, y1 = 0.5 - math.cos(a) / 2, 0.5 - math.sin(a) / 2
    x2, y2 = 0.5 + math.cos(a) / 2, 0.5 + math.sin(a) / 2
    return (
        f'<linearGradient id="{gid}" x1="{f(x1)}" y1="{f(y1)}" '
        f'x2="{f(x2)}" y2="{f(y2)}">'
        f'<stop offset="0" stop-color="{c1}"/>'
        f'<stop offset="1" stop-color="{c2}"/></linearGradient>'
    )


def lin3(gid: str, c1: str, c2: str, c3: str, angle: float = 135.0) -> str:
    a = math.radians(angle)
    x1, y1 = 0.5 - math.cos(a) / 2, 0.5 - math.sin(a) / 2
    x2, y2 = 0.5 + math.cos(a) / 2, 0.5 + math.sin(a) / 2
    return (
        f'<linearGradient id="{gid}" x1="{f(x1)}" y1="{f(y1)}" '
        f'x2="{f(x2)}" y2="{f(y2)}">'
        f'<stop offset="0" stop-color="{c1}"/>'
        f'<stop offset="0.55" stop-color="{c2}"/>'
        f'<stop offset="1" stop-color="{c3}"/></linearGradient>'
    )


def rad(gid: str, c1: str, c2: str, cx: float = 0.5, cy: float = 0.4,
        r: float = 0.75) -> str:
    return (
        f'<radialGradient id="{gid}" cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}">'
        f'<stop offset="0" stop-color="{c1}"/>'
        f'<stop offset="1" stop-color="{c2}"/></radialGradient>'
    )


def stitch(d: str, color: str = CREAM, width: float = 2.0,
           dash: float = 10.0, gap: float = 8.0, op: float = 0.9) -> str:
    """The signature dashed outline, as a stroke overlay on any path."""
    return (
        f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{f(width)}" '
        f'stroke-linecap="round" stroke-dasharray="{f(dash)} {f(gap)}" '
        f'opacity="{f(op)}"/>'
    )


def rrect(x: float, y: float, w: float, h: float, r: float, fill: str,
          extra: str = "") -> str:
    return (
        f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" '
        f'rx="{f(r)}" fill="{fill}" {extra}/>'
    )


# ------------------------------------------------------------ ornaments ----


def petal_d(cx: float, cy: float, r_in: float, r_out: float,
            spread: float = 0.45) -> str:
    """A petal pointing up, from radius r_in out to r_out around (cx, cy)."""
    mid = (r_in + r_out) / 2
    w = (r_out - r_in) * spread
    return (
        f"M{f(cx)} {f(cy - r_in)}"
        f"Q{f(cx + w)} {f(cy - mid)} {f(cx)} {f(cy - r_out)}"
        f"Q{f(cx - w)} {f(cy - mid)} {f(cx)} {f(cy - r_in)}Z"
    )


def petal_ring(cx: float, cy: float, r_in: float, r_out: float, n: int,
               fill: str, op: float = 1.0, offset: float = 0.0,
               spread: float = 0.45) -> str:
    out = [f'<g fill="{fill}" opacity="{f(op)}">']
    for k in range(n):
        ang = 360.0 * k / n + offset
        out.append(
            f'<g transform="rotate({f(ang)} {f(cx)} {f(cy)})">'
            f'<path d="{petal_d(cx, cy, r_in, r_out, spread)}"/></g>'
        )
    out.append("</g>")
    return "".join(out)


def mandala(cx: float, cy: float, r: float, color: str, op: float = 0.16,
            petals: int = 16) -> str:
    """Concentric petal-ring watermark -- the backdrop of every medallion."""
    parts = [
        petal_ring(cx, cy, r * 0.54, r * 0.99, petals, color, op, 0.0, 0.40),
        petal_ring(cx, cy, r * 0.26, r * 0.56, petals // 2, color, op * 1.25,
                   360.0 / petals, 0.50),
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.52)}" fill="none" '
        f'stroke="{color}" stroke-width="{f(r * 0.012)}" '
        f'opacity="{f(op * 1.6)}"/>',
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.22)}" fill="none" '
        f'stroke="{color}" stroke-width="{f(r * 0.02)}" '
        f'stroke-dasharray="{f(r * 0.07)} {f(r * 0.06)}" '
        f'opacity="{f(op * 1.8)}"/>',
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.07)}" fill="{color}" '
        f'opacity="{f(op * 2.0)}"/>',
    ]
    return "".join(parts)


def lotus(cx: float, base: float, size: float, color: str, dark: str,
          petals: int = 7, arc: float = 150.0) -> str:
    """Front-facing lotus: a fan of petals rising from (cx, base)."""
    out = []
    step = arc / (petals - 1)
    # back row, darker and shorter
    for k in range(petals - 1):
        ang = -arc / 2 + step / 2 + step * k
        out.append(
            f'<g transform="rotate({f(ang)} {f(cx)} {f(base)})">'
            f'<path d="{_base_petal(cx, base, size * 0.78, size * 0.26)}" '
            f'fill="{dark}"/></g>'
        )
    for k in range(petals):
        ang = -arc / 2 + step * k
        out.append(
            f'<g transform="rotate({f(ang)} {f(cx)} {f(base)})">'
            f'<path d="{_base_petal(cx, base, size, size * 0.30)}" '
            f'fill="{color}"/></g>'
        )
    out.append(
        f'<ellipse cx="{f(cx)}" cy="{f(base)}" rx="{f(size * 0.20)}" '
        f'ry="{f(size * 0.12)}" fill="{dark}"/>'
    )
    return "".join(out)


def _base_petal(cx: float, cy: float, length: float, width: float) -> str:
    return (
        f"M{f(cx)} {f(cy)}"
        f"Q{f(cx - width)} {f(cy - length * 0.55)} {f(cx)} {f(cy - length)}"
        f"Q{f(cx + width)} {f(cy - length * 0.55)} {f(cx)} {f(cy)}Z"
    )


def flame(cx: float, tip: float, h: float, outer: str = SAFFRON,
          inner: str = AMBER) -> str:
    w = h * 0.40
    d = (
        f"M{f(cx)} {f(tip)}"
        f"C{f(cx + w)} {f(tip + h * 0.42)} {f(cx + w * 0.72)} {f(tip + h)} "
        f"{f(cx)} {f(tip + h)}"
        f"C{f(cx - w * 0.72)} {f(tip + h)} {f(cx - w)} {f(tip + h * 0.42)} "
        f"{f(cx)} {f(tip)}Z"
    )
    hi = h * 0.52
    wi = hi * 0.38
    d2 = (
        f"M{f(cx)} {f(tip + h * 0.34)}"
        f"C{f(cx + wi)} {f(tip + h * 0.34 + hi * 0.45)} "
        f"{f(cx + wi * 0.7)} {f(tip + h * 0.34 + hi)} {f(cx)} "
        f"{f(tip + h * 0.34 + hi)}"
        f"C{f(cx - wi * 0.7)} {f(tip + h * 0.34 + hi)} "
        f"{f(cx - wi)} {f(tip + h * 0.34 + hi * 0.45)} {f(cx)} "
        f"{f(tip + h * 0.34)}Z"
    )
    return f'<path d="{d}" fill="{outer}"/><path d="{d2}" fill="{inner}"/>'


def diya(cx: float, cy: float, w: float, lit: bool = True) -> str:
    """Clay oil lamp. cy is the rim line; the bowl hangs below it."""
    h = w * 0.46
    bowl = (
        f"M{f(cx - w / 2)} {f(cy)}"
        f"C{f(cx - w / 2)} {f(cy + h * 1.5)} {f(cx + w / 2)} {f(cy + h * 1.5)} "
        f"{f(cx + w / 2)} {f(cy)}Z"
    )
    parts = [
        f'<path d="{bowl}" fill="url(#diyaClay)"/>',
        f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(w / 2)}" '
        f'ry="{f(w * 0.11)}" fill="{BARK}"/>',
        f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(w * 0.40)}" '
        f'ry="{f(w * 0.075)}" fill="{"#F0B44B" if lit else "#8A6A4F"}"/>',
    ]
    if lit:
        parts.append(
            f'<path d="M{f(cx)} {f(cy - w * 0.02)}l{f(w * 0.03)} '
            f'{f(-w * 0.16)}h{f(-w * 0.06)}z" fill="{INK}"/>'
        )
        parts.append(flame(cx, cy - w * 0.72, w * 0.58))
        parts.append(
            f'<ellipse cx="{f(cx)}" cy="{f(cy - w * 0.34)}" '
            f'rx="{f(w * 0.42)}" ry="{f(w * 0.46)}" fill="{AMBER}" '
            f'opacity="0.20"/>'
        )
    else:
        parts.append(
            f'<path d="M{f(cx)} {f(cy - w * 0.02)}l{f(w * 0.03)} '
            f'{f(-w * 0.12)}h{f(-w * 0.06)}z" fill="{INK}" opacity="0.7"/>'
        )
    return "".join(parts)


def bowl(cx: float, cy: float, w: float, fill: str = "url(#brass)",
         rim: str = "#B8862F") -> str:
    h = w * 0.40
    d = (
        f"M{f(cx - w / 2)} {f(cy)}"
        f"C{f(cx - w * 0.46)} {f(cy + h * 1.7)} {f(cx + w * 0.46)} "
        f"{f(cy + h * 1.7)} {f(cx + w / 2)} {f(cy)}Z"
    )
    return (
        f'<path d="{d}" fill="{fill}"/>'
        f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(w / 2)}" '
        f'ry="{f(w * 0.10)}" fill="{rim}"/>'
    )


def temple(cx: float, base: float, h: float, body: str = "#E8B48C",
           roof: str = TERRA, trim: str = GOLD) -> str:
    """Nagara-style shrine: plinth, pillared sanctum, curved shikhara, kalasha."""
    w = h * 0.62
    parts = [
        # plinth
        f'<path d="M{f(cx - w * 0.60)} {f(base)}h{f(w * 1.20)}'
        f'l{f(-w * 0.06)} {f(-h * 0.07)}h{f(-w * 1.08)}z" fill="{trim}"/>',
        # sanctum block
        rrect(cx - w * 0.44, base - h * 0.46, w * 0.88, h * 0.39, h * 0.012,
              body),
        # pillars
        rrect(cx - w * 0.42, base - h * 0.44, w * 0.09, h * 0.36, h * 0.02,
              trim),
        rrect(cx + w * 0.33, base - h * 0.44, w * 0.09, h * 0.36, h * 0.02,
              trim),
        # doorway
        f'<path d="M{f(cx - w * 0.13)} {f(base - h * 0.07)}'
        f'v{f(-h * 0.22)}a{f(w * 0.13)} {f(h * 0.10)} 0 0 1 {f(w * 0.26)} 0'
        f'v{f(h * 0.22)}z" fill="{INK}" opacity="0.55"/>',
        # eave
        f'<path d="M{f(cx - w * 0.52)} {f(base - h * 0.46)}h{f(w * 1.04)}'
        f'l{f(-w * 0.08)} {f(-h * 0.05)}h{f(-w * 0.88)}z" fill="{trim}"/>',
        # shikhara
        f'<path d="M{f(cx - w * 0.42)} {f(base - h * 0.51)}'
        f'C{f(cx - w * 0.34)} {f(base - h * 0.78)} {f(cx - w * 0.14)} '
        f'{f(base - h * 0.86)} {f(cx)} {f(base - h * 0.90)}'
        f'C{f(cx + w * 0.14)} {f(base - h * 0.86)} {f(cx + w * 0.34)} '
        f'{f(base - h * 0.78)} {f(cx + w * 0.42)} {f(base - h * 0.51)}z" '
        f'fill="{roof}"/>',
        # shikhara ribs
        f'<path d="M{f(cx)} {f(base - h * 0.90)}V{f(base - h * 0.51)}" '
        f'stroke="{trim}" stroke-width="{f(h * 0.012)}" opacity="0.8"/>',
        f'<path d="M{f(cx - w * 0.20)} {f(base - h * 0.53)}'
        f'C{f(cx - w * 0.16)} {f(base - h * 0.72)} {f(cx - w * 0.08)} '
        f'{f(base - h * 0.82)} {f(cx - w * 0.02)} {f(base - h * 0.88)}" '
        f'fill="none" stroke="{trim}" stroke-width="{f(h * 0.010)}" '
        f'opacity="0.6"/>',
        f'<path d="M{f(cx + w * 0.20)} {f(base - h * 0.53)}'
        f'C{f(cx + w * 0.16)} {f(base - h * 0.72)} {f(cx + w * 0.08)} '
        f'{f(base - h * 0.82)} {f(cx + w * 0.02)} {f(base - h * 0.88)}" '
        f'fill="none" stroke="{trim}" stroke-width="{f(h * 0.010)}" '
        f'opacity="0.6"/>',
        # amalaka + kalasha finial
        f'<ellipse cx="{f(cx)}" cy="{f(base - h * 0.92)}" '
        f'rx="{f(w * 0.09)}" ry="{f(h * 0.030)}" fill="{trim}"/>',
        f'<path d="M{f(cx - w * 0.035)} {f(base - h * 0.945)}'
        f'q{f(w * 0.035)} {f(-h * 0.055)} {f(w * 0.07)} 0z" fill="{trim}"/>',
        f'<circle cx="{f(cx)}" cy="{f(base - h * 0.975)}" '
        f'r="{f(w * 0.028)}" fill="{trim}"/>',
    ]
    return "".join(parts)


def arch(cx: float, top: float, w: float, h: float, fill: str,
         stroke: str = "none", sw: float = 0.0) -> str:
    """Cusped temple arch (torana) opening -- pointed, with shoulders."""
    hw = w / 2
    d = (
        f"M{f(cx - hw)} {f(top + h)}"
        f"V{f(top + h * 0.44)}"
        f"C{f(cx - hw)} {f(top + h * 0.16)} {f(cx - hw * 0.52)} {f(top)} "
        f"{f(cx)} {f(top)}"
        f"C{f(cx + hw * 0.52)} {f(top)} {f(cx + hw)} {f(top + h * 0.16)} "
        f"{f(cx + hw)} {f(top + h * 0.44)}"
        f"V{f(top + h)}Z"
    )
    s = ""
    if stroke != "none" and sw:
        s = f' stroke="{stroke}" stroke-width="{f(sw)}"'
    return f'<path d="{d}" fill="{fill}"{s}/>'


def bell(cx: float, top: float, h: float, color: str = GOLD,
         dark: str = "#9A7B3C") -> str:
    w = h * 0.72
    return (
        f'<path d="M{f(cx)} {f(top)}v{f(h * 0.14)}" stroke="{dark}" '
        f'stroke-width="{f(h * 0.05)}"/>'
        f'<circle cx="{f(cx)}" cy="{f(top + h * 0.05)}" r="{f(h * 0.07)}" '
        f'fill="none" stroke="{dark}" stroke-width="{f(h * 0.035)}"/>'
        f'<path d="M{f(cx - w * 0.5)} {f(top + h * 0.80)}'
        f'C{f(cx - w * 0.48)} {f(top + h * 0.30)} {f(cx - w * 0.16)} '
        f'{f(top + h * 0.16)} {f(cx)} {f(top + h * 0.16)}'
        f'C{f(cx + w * 0.16)} {f(top + h * 0.16)} {f(cx + w * 0.48)} '
        f'{f(top + h * 0.30)} {f(cx + w * 0.5)} {f(top + h * 0.80)}z" '
        f'fill="{color}"/>'
        f'<ellipse cx="{f(cx)}" cy="{f(top + h * 0.80)}" rx="{f(w * 0.5)}" '
        f'ry="{f(h * 0.07)}" fill="{dark}"/>'
        f'<circle cx="{f(cx)}" cy="{f(top + h * 0.92)}" r="{f(h * 0.075)}" '
        f'fill="{dark}"/>'
    )


def kalash(cx: float, base: float, h: float, pot: str = GOLD,
           leaf: str = GREEN_LT) -> str:
    w = h * 0.78
    return (
        f'<path d="M{f(cx - w * 0.30)} {f(base - h * 0.60)}'
        f'C{f(cx - w * 0.56)} {f(base - h * 0.44)} {f(cx - w * 0.46)} '
        f'{f(base)} {f(cx)} {f(base)}'
        f'C{f(cx + w * 0.46)} {f(base)} {f(cx + w * 0.56)} '
        f'{f(base - h * 0.44)} {f(cx + w * 0.30)} {f(base - h * 0.60)}z" '
        f'fill="{pot}"/>'
        f'<rect x="{f(cx - w * 0.34)}" y="{f(base - h * 0.68)}" '
        f'width="{f(w * 0.68)}" height="{f(h * 0.10)}" rx="{f(h * 0.03)}" '
        f'fill="#9A7B3C"/>'
        f'<path d="M{f(cx)} {f(base - h * 0.70)}'
        f'q{f(-w * 0.34)} {f(-h * 0.10)} {f(-w * 0.30)} {f(-h * 0.30)}'
        f'q{f(w * 0.26)} {f(h * 0.02)} {f(w * 0.30)} {f(h * 0.30)}z" '
        f'fill="{leaf}"/>'
        f'<path d="M{f(cx)} {f(base - h * 0.70)}'
        f'q{f(w * 0.34)} {f(-h * 0.10)} {f(w * 0.30)} {f(-h * 0.30)}'
        f'q{f(-w * 0.26)} {f(h * 0.02)} {f(-w * 0.30)} {f(h * 0.30)}z" '
        f'fill="{leaf}"/>'
        f'<circle cx="{f(cx)}" cy="{f(base - h * 1.02)}" r="{f(w * 0.15)}" '
        f'fill="{BARK}"/>'
    )


# ------------------------------------------------------- attribute glyphs --
# Each glyph draws centred on (cx, cy) inside a box of side `s`.


def g_trishul(cx: float, cy: float, s: float, color: str = GOLD) -> str:
    """Trishula: three leaf blades on a bound shaft, lit down its left edge."""
    sw = s * 0.062
    tip = cy - s * 0.50
    frame = (
        f'<path d="M{f(cx)} {f(tip)}V{f(cy + s * 0.50)}"/>'
        f'<path d="M{f(cx - s * 0.22)} {f(tip + s * 0.30)}'
        f'V{f(tip + s * 0.10)}"/>'
        f'<path d="M{f(cx + s * 0.22)} {f(tip + s * 0.30)}'
        f'V{f(tip + s * 0.10)}"/>'
        f'<path d="M{f(cx - s * 0.22)} {f(tip + s * 0.30)}'
        f'Q{f(cx)} {f(tip + s * 0.42)} {f(cx + s * 0.22)} '
        f'{f(tip + s * 0.30)}"/>'
    )
    blade = (
        lambda bx, by, bs:
        lit(
            f"M{f(bx)} {f(by - bs)}"
            f"C{f(bx + bs * 0.42)} {f(by - bs * 0.62)} "
            f"{f(bx + bs * 0.32)} {f(by - bs * 0.18)} {f(bx)} {f(by)}"
            f"C{f(bx - bs * 0.32)} {f(by - bs * 0.18)} "
            f"{f(bx - bs * 0.42)} {f(by - bs * 0.62)} {f(bx)} {f(by - bs)}Z",
            GOLD_PALE, -bs * 0.05, -bs * 0.05, 0.78,
        )
    )
    return (
        f'<g stroke="{shade(color, 0.76)}" stroke-width="{f(sw * 1.34)}" '
        f'stroke-linecap="round" fill="none">{frame}</g>'
        f'<g stroke="{color}" stroke-width="{f(sw)}" stroke-linecap="round" '
        f'fill="none">{frame}</g>'
        f'<path d="M{f(cx - s * 0.010)} {f(tip + s * 0.06)}'
        f'V{f(cy + s * 0.46)}" stroke="{tint(color, 1.30)}" '
        f'stroke-width="{f(sw * 0.22)}" opacity="0.65"/>'
        + blade(cx, tip + s * 0.02, s * 0.15)
        + blade(cx - s * 0.22, tip + s * 0.13, s * 0.12)
        + blade(cx + s * 0.22, tip + s * 0.13, s * 0.12)
        # binding where the prongs meet the shaft
        + rrect(cx - s * 0.048, tip + s * 0.40, s * 0.096, s * 0.052,
                s * 0.022, shade(color, 0.74))
        + f'<circle cx="{f(cx)}" cy="{f(tip + s * 0.426)}" '
          f'r="{f(s * 0.020)}" fill="{TERRA}"/>'
    )


def g_damaru(cx: float, cy: float, s: float, color: str = "#C98A3E") -> str:
    """Shiva's drum: two heads, a bound waist, two knotted strikers.

    Warm wood by default -- the pale cream it used to be vanished against ash
    skin and cream cloth.
    """
    body = (
        f"M{f(cx - s * 0.28)} {f(cy - s * 0.32)}"
        f"C{f(cx - s * 0.16)} {f(cy - s * 0.12)} {f(cx - s * 0.16)} "
        f"{f(cy + s * 0.12)} {f(cx - s * 0.28)} {f(cy + s * 0.32)}"
        f"L{f(cx + s * 0.28)} {f(cy + s * 0.32)}"
        f"C{f(cx + s * 0.16)} {f(cy + s * 0.12)} {f(cx + s * 0.16)} "
        f"{f(cy - s * 0.12)} {f(cx + s * 0.28)} {f(cy - s * 0.32)}Z"
    )
    return (
        lit(body, color, -s * 0.014, -s * 0.014, 0.80)
        # the two skin heads, pale against the wood
        + f'<g fill="{CREAM}">'
          f'<ellipse cx="{f(cx)}" cy="{f(cy - s * 0.32)}" '
          f'rx="{f(s * 0.28)}" ry="{f(s * 0.055)}"/>'
          f'<ellipse cx="{f(cx)}" cy="{f(cy + s * 0.32)}" '
          f'rx="{f(s * 0.28)}" ry="{f(s * 0.055)}"/>'
          f"</g>"
        + f'<g fill="none" stroke="{shade(color, 0.70)}" '
          f'stroke-width="{f(s * 0.024)}" opacity="0.7">'
          f'<ellipse cx="{f(cx)}" cy="{f(cy - s * 0.32)}" '
          f'rx="{f(s * 0.28)}" ry="{f(s * 0.055)}"/>'
          f'<ellipse cx="{f(cx)}" cy="{f(cy + s * 0.32)}" '
          f'rx="{f(s * 0.28)}" ry="{f(s * 0.055)}"/>'
          f"</g>"
        # binding at the waist
        + f'<path d="M{f(cx - s * 0.17)} {f(cy)}h{f(s * 0.34)}" '
          f'stroke="{TERRA}" stroke-width="{f(s * 0.075)}" '
          f'stroke-linecap="round"/>'
        + f'<path d="M{f(cx - s * 0.15)} {f(cy - s * 0.018)}'
          f'h{f(s * 0.30)}" stroke="{ROSE_LT}" '
          f'stroke-width="{f(s * 0.020)}" opacity="0.8"/>'
        # the strikers, swung out on their cords
        + f'<g fill="none" stroke="{TERRA_DARK}" '
          f'stroke-width="{f(s * 0.018)}" opacity="0.8">'
          f'<path d="M{f(cx - s * 0.15)} {f(cy)}'
          f'Q{f(cx - s * 0.34)} {f(cy + s * 0.06)} {f(cx - s * 0.40)} '
          f'{f(cy + s * 0.20)}"/>'
          f'<path d="M{f(cx + s * 0.15)} {f(cy)}'
          f'Q{f(cx + s * 0.34)} {f(cy + s * 0.06)} {f(cx + s * 0.40)} '
          f'{f(cy + s * 0.20)}"/>'
          f"</g>"
        + f'<g fill="{GOLD}">'
          f'<circle cx="{f(cx - s * 0.40)}" cy="{f(cy + s * 0.23)}" '
          f'r="{f(s * 0.048)}"/>'
          f'<circle cx="{f(cx + s * 0.40)}" cy="{f(cy + s * 0.23)}" '
          f'r="{f(s * 0.048)}"/>'
          f"</g>"
    )


def g_gada(cx: float, cy: float, s: float, color: str = GOLD) -> str:
    """Hanuman's mace: a shaft that tapers into collars under a lobed head.

    Drawn slim -- at hand scale a fat club covers the arm holding it.
    """
    shaft, hy = "#A8843F", cy - s * 0.28
    hr = s * 0.135
    return (
        # shaft, narrowing towards the grip
        f'<path d="M{f(cx - s * 0.034)} {f(cy - s * 0.20)}'
        f'L{f(cx + s * 0.034)} {f(cy - s * 0.20)}'
        f'L{f(cx + s * 0.026)} {f(cy + s * 0.46)}'
        f'L{f(cx - s * 0.026)} {f(cy + s * 0.46)}Z" '
        f'fill="{shade(shaft, 0.82)}"/>'
        f'<path d="M{f(cx - s * 0.022)} {f(cy - s * 0.20)}'
        f'L{f(cx + s * 0.010)} {f(cy - s * 0.20)}'
        f'L{f(cx + s * 0.006)} {f(cy + s * 0.46)}'
        f'L{f(cx - s * 0.018)} {f(cy + s * 0.46)}Z" '
        f'fill="{tint(shaft, 1.24)}" opacity="0.8"/>'
        # butt knob
        + f'<ellipse cx="{f(cx)}" cy="{f(cy + s * 0.48)}" '
          f'rx="{f(s * 0.048)}" ry="{f(s * 0.034)}" fill="{shade(color, 0.8)}"/>'
        # two collars where the head is seated
        + rrect(cx - s * 0.058, cy - s * 0.175, s * 0.116, s * 0.036,
                s * 0.016, shade(color, 0.78))
        + rrect(cx - s * 0.050, cy - s * 0.128, s * 0.100, s * 0.030,
                s * 0.014, shade(color, 0.84))
        # head: a lobed sphere, shaded on the right
        + f'<circle cx="{f(cx)}" cy="{f(hy)}" r="{f(hr)}" '
          f'fill="{shade(color, 0.76)}"/>'
        + petal_ring(cx, hy, hr * 0.52, hr * 1.16, 8, shade(color, 0.84),
                     1.0, 22.5, 0.55)
        + f'<circle cx="{f(cx - hr * 0.10)}" cy="{f(hy - hr * 0.10)}" '
          f'r="{f(hr * 0.86)}" fill="{color}"/>'
          f'<path d="M{f(cx + hr * 0.10)} {f(hy - hr * 0.60)}'
          f'a{f(hr * 0.80)} {f(hr * 0.80)} 0 0 1 0 {f(hr * 1.40)}" '
          f'fill="none" stroke="{shade(color, 0.80)}" '
          f'stroke-width="{f(hr * 0.26)}" opacity="0.6"/>'
          f'<circle cx="{f(cx - hr * 0.30)}" cy="{f(hy - hr * 0.34)}" '
          f'r="{f(hr * 0.24)}" fill="{tint(color, 1.34)}" opacity="0.75"/>'
        # finial
        + f'<path d="M{f(cx)} {f(hy - hr * 1.62)}'
          f'l{f(hr * 0.20)} {f(hr * 0.34)}h{f(-hr * 0.40)}Z" '
          f'fill="{GOLD_PALE}"/>'
          f'<rect x="{f(cx - hr * 0.11)}" y="{f(hy - hr * 1.30)}" '
          f'width="{f(hr * 0.22)}" height="{f(hr * 0.26)}" '
          f'rx="{f(hr * 0.06)}" fill="{shade(color, 0.8)}"/>'
    )


def g_bow(cx: float, cy: float, s: float, color: str = "#8A6A3F",
          string: str = CREAM) -> str:
    """Kodanda: a recurve limb with horn nocks and a bound grip."""
    limb = (
        f"M{f(cx + s * 0.02)} {f(cy - s * 0.50)}"
        f"C{f(cx + s * 0.30)} {f(cy - s * 0.40)} {f(cx + s * 0.40)} "
        f"{f(cy - s * 0.16)} {f(cx + s * 0.40)} {f(cy)}"
        f"C{f(cx + s * 0.40)} {f(cy + s * 0.16)} {f(cx + s * 0.30)} "
        f"{f(cy + s * 0.40)} {f(cx + s * 0.02)} {f(cy + s * 0.50)}"
    )
    return (
        f'<path d="{limb}" fill="none" stroke="{shade(color, 0.76)}" '
        f'stroke-width="{f(s * 0.070)}" stroke-linecap="round"/>'
        f'<path d="{limb}" fill="none" stroke="{color}" '
        f'stroke-width="{f(s * 0.048)}" stroke-linecap="round"/>'
        f'<path d="{limb}" fill="none" stroke="{tint(color, 1.30)}" '
        f'stroke-width="{f(s * 0.014)}" stroke-linecap="round" '
        f'opacity="0.6"/>'
        # gold bindings along the limb, and the grip
        + "".join(
            f'<path d="M{f(cx + s * 0.30)} {f(cy + s * dy)}'
            f'l{f(s * 0.10)} {f(s * 0.012)}" stroke="{GOLD}" '
            f'stroke-width="{f(s * 0.028)}" stroke-linecap="round"/>'
            for dy in (-0.30, 0.30)
        )
        + rrect(cx + s * 0.360, cy - s * 0.075, s * 0.078, s * 0.150,
                s * 0.030, GOLD)
        + f'<path d="M{f(cx + s * 0.02)} {f(cy - s * 0.50)}'
          f'V{f(cy + s * 0.50)}" stroke="{shade(string, 0.80)}" '
          f'stroke-width="{f(s * 0.020)}"/>'
          f'<path d="M{f(cx + s * 0.016)} {f(cy - s * 0.50)}'
          f'V{f(cy + s * 0.50)}" stroke="{string}" '
          f'stroke-width="{f(s * 0.010)}"/>'
        # horn nocks
        + "".join(
            f'<circle cx="{f(cx + s * 0.02)}" cy="{f(cy + s * dy)}" '
            f'r="{f(s * 0.032)}" fill="{GOLD_PALE}"/>'
            for dy in (-0.50, 0.50)
        )
    )


def g_arrow(cx: float, cy: float, s: float, color: str = "#8A6A3F") -> str:
    """One shaft: leaf head, bound foreshaft, fletching, nock."""
    return (
        f'<path d="M{f(cx)} {f(cy - s * 0.42)}V{f(cy + s * 0.48)}" '
        f'stroke="{shade(color, 0.78)}" stroke-width="{f(s * 0.038)}"/>'
        f'<path d="M{f(cx - s * 0.006)} {f(cy - s * 0.42)}'
        f'V{f(cy + s * 0.48)}" stroke="{tint(color, 1.22)}" '
        f'stroke-width="{f(s * 0.014)}" opacity="0.7"/>'
        # leaf-shaped head
        + lit(
            f"M{f(cx)} {f(cy - s * 0.56)}"
            f"C{f(cx + s * 0.052)} {f(cy - s * 0.46)} {f(cx + s * 0.048)} "
            f"{f(cy - s * 0.36)} {f(cx)} {f(cy - s * 0.30)}"
            f"C{f(cx - s * 0.048)} {f(cy - s * 0.36)} {f(cx - s * 0.052)} "
            f"{f(cy - s * 0.46)} {f(cx)} {f(cy - s * 0.56)}Z",
            GOLD_PALE, -s * 0.006, -s * 0.006, 0.80,
        )
        + f'<path d="M{f(cx - s * 0.026)} {f(cy - s * 0.30)}'
          f'h{f(s * 0.052)}" stroke="{GOLD}" stroke-width="{f(s * 0.026)}" '
          f'stroke-linecap="round"/>'
        # fletching, two vanes
        + "".join(
            f'<path d="M{f(cx)} {f(cy + s * 0.22)}'
            f'C{f(cx + sx * s * 0.070)} {f(cy + s * 0.26)} '
            f'{f(cx + sx * s * 0.070)} {f(cy + s * 0.38)} '
            f'{f(cx)} {f(cy + s * 0.42)}Z" fill="{CREAM}" opacity="0.92"/>'
            f'<path d="M{f(cx)} {f(cy + s * 0.22)}'
            f'C{f(cx + sx * s * 0.070)} {f(cy + s * 0.26)} '
            f'{f(cx + sx * s * 0.070)} {f(cy + s * 0.38)} '
            f'{f(cx)} {f(cy + s * 0.42)}" fill="none" stroke="{ROSE}" '
            f'stroke-width="{f(s * 0.012)}" opacity="0.55"/>'
            for sx in (-1, 1)
        )
        + f'<circle cx="{f(cx)}" cy="{f(cy + s * 0.48)}" '
          f'r="{f(s * 0.024)}" fill="{GOLD}"/>'
    )


def g_flute(cx: float, cy: float, s: float, color: str = "#D9B382",
            tilt: float = -22.0) -> str:
    """Bansuri, tilted the way it lies when it is held to the lips.

    `tilt` lets a caller lay it along the line between two hands instead of
    accepting the default rake.
    """
    hw = s * 0.052
    return (
        f'<g transform="rotate({f(tilt)} {f(cx)} {f(cy)})">'
        # body: a shade pass under a lit copy, so it reads as a round tube
        + rrect(cx - s * 0.50, cy - hw, s, hw * 2, hw, shade(color, 0.78))
        + rrect(cx - s * 0.50, cy - hw, s, hw * 1.55, hw * 0.8, color)
        + f'<path d="M{f(cx - s * 0.46)} {f(cy - hw * 0.48)}'
          f'h{f(s * 0.92)}" stroke="{tint(color, 1.22)}" '
          f'stroke-width="{f(hw * 0.46)}" opacity="0.85" '
          f'stroke-linecap="round"/>'
        # finger holes, each a shaded pit
        + "".join(
            f'<circle cx="{f(cx + s * dx)}" cy="{f(cy + hw * 0.06)}" '
            f'r="{f(s * 0.026)}" fill="{shade(color, 0.52)}"/>'
            for dx in (-0.22, -0.08, 0.06, 0.20, 0.32)
        )
        + f'<circle cx="{f(cx - s * 0.38)}" cy="{f(cy + hw * 0.06)}" '
          f'r="{f(s * 0.030)}" fill="{shade(color, 0.44)}"/>'
        # gold bindings at both ends
        + f'<g fill="{GOLD}">'
          f'<rect x="{f(cx - s * 0.50)}" y="{f(cy - hw * 1.15)}" '
          f'width="{f(s * 0.045)}" height="{f(hw * 2.30)}" '
          f'rx="{f(hw * 0.35)}"/>'
          f'<rect x="{f(cx + s * 0.455)}" y="{f(cy - hw * 1.15)}" '
          f'width="{f(s * 0.045)}" height="{f(hw * 2.30)}" '
          f'rx="{f(hw * 0.35)}"/>'
          f"</g>"
        + f'<path d="M{f(cx + s * 0.50)} {f(cy)}q{f(s * 0.05)} '
          f'{f(s * 0.10)} {f(s * 0.02)} {f(s * 0.16)}" fill="none" '
          f'stroke="{ROSE}" stroke-width="{f(s * 0.020)}" opacity="0.75"/>'
        + "</g>"
    )


def g_feather(cx: float, cy: float, s: float) -> str:
    """Peacock feather -- Krishna's crown mark."""
    return (
        f'<path d="M{f(cx)} {f(cy + s * 0.50)}V{f(cy - s * 0.10)}" '
        f'stroke="{GREEN_LT}" stroke-width="{f(s * 0.035)}"/>'
        f'<ellipse cx="{f(cx)}" cy="{f(cy - s * 0.24)}" rx="{f(s * 0.20)}" '
        f'ry="{f(s * 0.28)}" fill="#2E7D8C"/>'
        f'<ellipse cx="{f(cx)}" cy="{f(cy - s * 0.24)}" rx="{f(s * 0.12)}" '
        f'ry="{f(s * 0.17)}" fill="#1F5F86"/>'
        f'<ellipse cx="{f(cx)}" cy="{f(cy - s * 0.22)}" rx="{f(s * 0.055)}" '
        f'ry="{f(s * 0.085)}" fill="{GOLD_BRIGHT}"/>'
    )


def g_veena(cx: float, cy: float, s: float) -> str:
    return (
        f'<g transform="rotate(-30 {f(cx)} {f(cy)})">'
        f'<rect x="{f(cx - s * 0.44)}" y="{f(cy - s * 0.045)}" '
        f'width="{f(s * 0.78)}" height="{f(s * 0.09)}" rx="{f(s * 0.04)}" '
        f'fill="#8A6A3F"/>'
        f'<circle cx="{f(cx + s * 0.36)}" cy="{f(cy)}" r="{f(s * 0.19)}" '
        f'fill="#C08A4A"/>'
        f'<circle cx="{f(cx + s * 0.36)}" cy="{f(cy)}" r="{f(s * 0.07)}" '
        f'fill="{BARK}"/>'
        f'<circle cx="{f(cx - s * 0.44)}" cy="{f(cy)}" r="{f(s * 0.09)}" '
        f'fill="#C08A4A"/>'
        f'<path d="M{f(cx - s * 0.40)} {f(cy - s * 0.02)}'
        f'H{f(cx + s * 0.34)}" stroke="{CREAM}" '
        f'stroke-width="{f(s * 0.014)}"/>'
        f"</g>"
    )


def g_pothi(cx: float, cy: float, s: float) -> str:
    """Palm-leaf manuscript."""
    return (
        f'<g transform="rotate(-8 {f(cx)} {f(cy)})">'
        f'<rect x="{f(cx - s * 0.34)}" y="{f(cy - s * 0.20)}" '
        f'width="{f(s * 0.68)}" height="{f(s * 0.40)}" rx="{f(s * 0.03)}" '
        f'fill="#E3C089"/>'
        f'<rect x="{f(cx - s * 0.34)}" y="{f(cy - s * 0.20)}" '
        f'width="{f(s * 0.68)}" height="{f(s * 0.07)}" rx="{f(s * 0.03)}" '
        f'fill="{TERRA}"/>'
        f'<g stroke="{BARK}" stroke-width="{f(s * 0.018)}" opacity="0.65">'
        f'<path d="M{f(cx - s * 0.24)} {f(cy)}h{f(s * 0.48)}"/>'
        f'<path d="M{f(cx - s * 0.24)} {f(cy + s * 0.08)}h{f(s * 0.36)}"/>'
        f"</g>"
        f'<path d="M{f(cx)} {f(cy - s * 0.22)}v{f(s * 0.44)}" '
        f'stroke="{GOLD}" stroke-width="{f(s * 0.022)}"/>'
        f"</g>"
    )


def g_conch(cx: float, cy: float, s: float) -> str:
    return (
        f'<path d="M{f(cx - s * 0.34)} {f(cy + s * 0.30)}'
        f'C{f(cx - s * 0.42)} {f(cy - s * 0.06)} {f(cx - s * 0.10)} '
        f'{f(cy - s * 0.36)} {f(cx + s * 0.16)} {f(cy - s * 0.30)}'
        f'C{f(cx + s * 0.40)} {f(cy - s * 0.24)} {f(cx + s * 0.36)} '
        f'{f(cy + s * 0.16)} {f(cx + s * 0.06)} {f(cy + s * 0.32)}z" '
        f'fill="{CREAM}"/>'
        f'<path d="M{f(cx - s * 0.16)} {f(cy + s * 0.22)}'
        f'C{f(cx - s * 0.14)} {f(cy - s * 0.06)} {f(cx)} {f(cy - s * 0.20)} '
        f'{f(cx + s * 0.14)} {f(cy - s * 0.18)}" fill="none" '
        f'stroke="{STONE_SHADE}" stroke-width="{f(s * 0.028)}"/>'
    )


def g_chakra(cx: float, cy: float, s: float, color: str = GOLD) -> str:
    r = s * 0.40
    spokes = []
    for k in range(8):
        a = math.radians(360.0 * k / 8)
        spokes.append(
            f'<path d="M{f(cx + math.cos(a) * r * 0.28)} '
            f'{f(cy + math.sin(a) * r * 0.28)}'
            f'L{f(cx + math.cos(a) * r * 0.86)} '
            f'{f(cy + math.sin(a) * r * 0.86)}"/>'
        )
    return (
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="none" '
        f'stroke="{color}" stroke-width="{f(s * 0.09)}"/>'
        f'<g stroke="{color}" stroke-width="{f(s * 0.045)}">'
        + "".join(spokes)
        + f"</g>"
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(s * 0.07)}" '
        f'fill="{color}"/>'
    )


def g_spear(cx: float, cy: float, s: float, color: str = GOLD) -> str:
    """Vel -- Kartikeya's leaf-bladed spear, with a socket and a ferrule."""
    return (
        f'<path d="M{f(cx)} {f(cy - s * 0.16)}V{f(cy + s * 0.52)}" '
        f'stroke="{shade("#A8843F", 0.82)}" stroke-width="{f(s * 0.052)}" '
        f'stroke-linecap="round"/>'
        f'<path d="M{f(cx - s * 0.010)} {f(cy - s * 0.14)}'
        f'V{f(cy + s * 0.48)}" stroke="{tint("#A8843F", 1.26)}" '
        f'stroke-width="{f(s * 0.016)}" opacity="0.7"/>'
        + lit(
            f"M{f(cx)} {f(cy - s * 0.54)}"
            f"C{f(cx + s * 0.16)} {f(cy - s * 0.38)} {f(cx + s * 0.11)} "
            f"{f(cy - s * 0.18)} {f(cx)} {f(cy - s * 0.12)}"
            f"C{f(cx - s * 0.11)} {f(cy - s * 0.18)} {f(cx - s * 0.16)} "
            f"{f(cy - s * 0.38)} {f(cx)} {f(cy - s * 0.54)}Z",
            color, -s * 0.008, -s * 0.008, 0.78,
        )
        + f'<path d="M{f(cx)} {f(cy - s * 0.50)}V{f(cy - s * 0.16)}" '
          f'stroke="{shade(color, 0.72)}" stroke-width="{f(s * 0.012)}" '
          f'opacity="0.7"/>'
        + rrect(cx - s * 0.036, cy - s * 0.166, s * 0.072, s * 0.058,
                s * 0.022, shade(color, 0.76))
        + f'<ellipse cx="{f(cx)}" cy="{f(cy + s * 0.535)}" '
          f'rx="{f(s * 0.030)}" ry="{f(s * 0.022)}" fill="{color}"/>'
    )


def g_mala(cx: float, cy: float, s: float, bead: str = "#8A5A3B") -> str:
    """Japa mala -- a ring of beads with the sumeru bead at the bottom."""
    r = s * 0.36
    out = []
    for k in range(24):
        a = math.radians(360.0 * k / 24 - 90)
        out.append(
            f'<circle cx="{f(cx + math.cos(a) * r)}" '
            f'cy="{f(cy + math.sin(a) * r)}" r="{f(s * 0.052)}"/>'
        )
    return (
        f'<g fill="{bead}">' + "".join(out) + "</g>"
        f'<circle cx="{f(cx)}" cy="{f(cy + r)}" r="{f(s * 0.085)}" '
        f'fill="{TERRA}"/>'
    )


def g_coin(cx: float, cy: float, s: float) -> str:
    return (
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(s * 0.42)}" '
        f'fill="{GOLD_BRIGHT}"/>'
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(s * 0.42)}" fill="none" '
        f'stroke="#9A7B3C" stroke-width="{f(s * 0.05)}"/>'
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(s * 0.22)}" fill="none" '
        f'stroke="#9A7B3C" stroke-width="{f(s * 0.04)}" '
        f'stroke-dasharray="{f(s * 0.09)} {f(s * 0.07)}"/>'
    )


def g_modak(cx: float, cy: float, s: float) -> str:
    return (
        f'<path d="M{f(cx - s * 0.30)} {f(cy + s * 0.26)}'
        f'C{f(cx - s * 0.26)} {f(cy - s * 0.16)} {f(cx - s * 0.08)} '
        f'{f(cy - s * 0.34)} {f(cx)} {f(cy - s * 0.42)}'
        f'C{f(cx + s * 0.08)} {f(cy - s * 0.34)} {f(cx + s * 0.26)} '
        f'{f(cy - s * 0.16)} {f(cx + s * 0.30)} {f(cy + s * 0.26)}z" '
        f'fill="#F3D9A8"/>'
        f'<ellipse cx="{f(cx)}" cy="{f(cy + s * 0.26)}" rx="{f(s * 0.30)}" '
        f'ry="{f(s * 0.07)}" fill="#E3C089"/>'
    )


def g_ladoo(cx: float, cy: float, s: float) -> str:
    dots = []
    for dx, dy in ((-0.14, -0.10), (0.10, -0.16), (0.16, 0.06),
                   (-0.06, 0.14), (0.0, -0.02), (-0.20, 0.04)):
        dots.append(
            f'<circle cx="{f(cx + s * dx)}" cy="{f(cy + s * dy)}" '
            f'r="{f(s * 0.035)}"/>'
        )
    return (
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(s * 0.40)}" '
        f'fill="url(#ladooBall)"/>'
        f'<g fill="#C9761E" opacity="0.55">' + "".join(dots) + "</g>"
    )


def g_swan(cx: float, cy: float, s: float) -> str:
    return (
        f'<ellipse cx="{f(cx)}" cy="{f(cy + s * 0.16)}" rx="{f(s * 0.34)}" '
        f'ry="{f(s * 0.20)}" fill="{CREAM}"/>'
        f'<path d="M{f(cx + s * 0.10)} {f(cy + s * 0.06)}'
        f'C{f(cx + s * 0.30)} {f(cy - s * 0.02)} {f(cx + s * 0.30)} '
        f'{f(cy - s * 0.32)} {f(cx + s * 0.14)} {f(cy - s * 0.34)}" '
        f'fill="none" stroke="{CREAM}" stroke-width="{f(s * 0.10)}" '
        f'stroke-linecap="round"/>'
        f'<path d="M{f(cx + s * 0.08)} {f(cy - s * 0.34)}'
        f'l{f(-s * 0.14)} {f(s * 0.05)}l{f(s * 0.13)} {f(s * 0.05)}z" '
        f'fill="{SAFFRON}"/>'
        f'<circle cx="{f(cx + s * 0.15)}" cy="{f(cy - s * 0.36)}" '
        f'r="{f(s * 0.022)}" fill="{INK}"/>'
        f'<path d="M{f(cx - s * 0.22)} {f(cy + s * 0.10)}'
        f'q{f(s * 0.22)} {f(-s * 0.14)} {f(s * 0.34)} {f(s * 0.06)}" '
        f'fill="none" stroke="{STONE_SHADE}" stroke-width="{f(s * 0.03)}"/>'
    )


def g_parrot(cx: float, cy: float, s: float) -> str:
    return (
        f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(s * 0.22)}" '
        f'ry="{f(s * 0.30)}" fill="#5FA05A"/>'
        f'<path d="M{f(cx + s * 0.06)} {f(cy + s * 0.24)}'
        f'l{f(s * 0.20)} {f(s * 0.26)}l{f(-s * 0.22)} {f(-s * 0.08)}z" '
        f'fill="#3F7C46"/>'
        f'<circle cx="{f(cx)}" cy="{f(cy - s * 0.30)}" r="{f(s * 0.15)}" '
        f'fill="#6FB566"/>'
        f'<path d="M{f(cx + s * 0.11)} {f(cy - s * 0.33)}'
        f'q{f(s * 0.14)} {f(s * 0.04)} {f(-s * 0.01)} {f(s * 0.14)}z" '
        f'fill="{TERRA}"/>'
        f'<circle cx="{f(cx + s * 0.05)}" cy="{f(cy - s * 0.34)}" '
        f'r="{f(s * 0.022)}" fill="{INK}"/>'
    )


def g_fish(cx: float, cy: float, s: float, color: str = "#C9A227") -> str:
    return (
        f'<path d="M{f(cx - s * 0.34)} {f(cy)}'
        f'C{f(cx - s * 0.16)} {f(cy - s * 0.22)} {f(cx + s * 0.14)} '
        f'{f(cy - s * 0.20)} {f(cx + s * 0.28)} {f(cy)}'
        f'C{f(cx + s * 0.14)} {f(cy + s * 0.20)} {f(cx - s * 0.16)} '
        f'{f(cy + s * 0.22)} {f(cx - s * 0.34)} {f(cy)}z" fill="{color}"/>'
        f'<path d="M{f(cx + s * 0.26)} {f(cy)}l{f(s * 0.16)} {f(-s * 0.14)}'
        f'v{f(s * 0.28)}z" fill="{color}"/>'
        f'<circle cx="{f(cx - s * 0.20)}" cy="{f(cy - s * 0.02)}" '
        f'r="{f(s * 0.025)}" fill="{INK}"/>'
    )


def _lobed_ring(cx: float, cy: float, r: float, bulge: float, n: int,
                phase: float = 0.0) -> str:
    """A closed scalloped outline: n soft lobes swelling from r out to bulge.

    Returns just the path data, so a caller can run it through lit(). Unlike
    petal_ring the lobes touch, which is the difference between fur and petals.
    """
    step = 2 * math.pi / n
    # a quadratic's apex sits at (P0 + 2C + P2)/4, so solve for the control
    # radius that puts the crown of each lobe exactly on `bulge`
    cr = 2 * bulge - r * math.cos(step / 2)
    pts = [(cx + math.cos(phase + step * i) * r,
            cy + math.sin(phase + step * i) * r) for i in range(n)]
    d = f"M{f(pts[0][0])} {f(pts[0][1])}"
    for i in range(n):
        am = phase + step * (i + 0.5)
        nx, ny = pts[(i + 1) % n]
        d += (f"Q{f(cx + math.cos(am) * cr)} {f(cy + math.sin(am) * cr)} "
              f"{f(nx)} {f(ny)}")
    return d + "Z"


def g_lion(cx: float, cy: float, s: float) -> str:
    """Durga's vahana, seated in profile facing the viewer's right.

    Kept compact and modelled: at deity scale only the maned head and the
    forequarter clear the lap, so those carry the shading.
    """
    u = s
    hx, hy, hr = cx + s * 0.30, cy - s * 0.20, s * 0.150
    body, dark, light = "#D99A45", "#B8752A", "#F0BE72"
    mass = (
        f"M{f(cx - u * 0.46)} {f(cy + u * 0.06)}"
        f"C{f(cx - u * 0.50)} {f(cy - u * 0.26)} {f(cx - u * 0.16)} "
        f"{f(cy - u * 0.34)} {f(cx + u * 0.10)} {f(cy - u * 0.30)}"
        f"C{f(cx + u * 0.30)} {f(cy - u * 0.26)} {f(cx + u * 0.34)} "
        f"{f(cy + u * 0.12)} {f(cx + u * 0.30)} {f(cy + u * 0.34)}"
        f"L{f(cx - u * 0.34)} {f(cy + u * 0.34)}"
        f"C{f(cx - u * 0.46)} {f(cy + u * 0.30)} {f(cx - u * 0.46)} "
        f"{f(cy + u * 0.18)} {f(cx - u * 0.46)} {f(cy + u * 0.06)}Z"
    )
    return (
        # tail sweeping up behind the haunch
        _taper(
            [(cx - u * 0.42, cy + u * 0.12), (cx - u * 0.62, cy + u * 0.06),
             (cx - u * 0.70, cy - u * 0.12), (cx - u * 0.62, cy - u * 0.30),
             (cx - u * 0.48, cy - u * 0.38)],
            [u * 0.060, u * 0.050, u * 0.042, u * 0.034, u * 0.028],
            body, 0.82,
        )
        + petal_ring(cx - u * 0.47, cy - u * 0.42, u * 0.010, u * 0.075, 6,
                     dark, 0.95)
        # haunch + back + chest as one modelled mass
        + lit(mass, body, -u * 0.014, -u * 0.012, 0.84)
        + f'<path d="M{f(cx - u * 0.40)} {f(cy - u * 0.24)}'
          f'C{f(cx - u * 0.14)} {f(cy - u * 0.32)} {f(cx + u * 0.12)} '
          f'{f(cy - u * 0.30)} {f(cx + u * 0.28)} {f(cy - u * 0.18)}" '
          f'fill="none" stroke="{light}" stroke-width="{f(u * 0.030)}" '
          f'opacity="0.7" stroke-linecap="round"/>'
        + f'<path d="M{f(cx - u * 0.44)} {f(cy + u * 0.02)}'
          f'C{f(cx - u * 0.34)} {f(cy + u * 0.20)} {f(cx - u * 0.20)} '
          f'{f(cy + u * 0.30)} {f(cx - u * 0.06)} {f(cy + u * 0.33)}" '
          f'fill="none" stroke="{dark}" stroke-width="{f(u * 0.026)}" '
          f'opacity="0.5" stroke-linecap="round"/>'
        # foreleg and paws
        + f'<g fill="{body}" stroke="{dark}" stroke-opacity="0.5" '
          f'stroke-width="{f(u * 0.010)}">'
          f'<rect x="{f(cx + u * 0.16)}" y="{f(cy + u * 0.04)}" '
          f'width="{f(u * 0.10)}" height="{f(u * 0.34)}" '
          f'rx="{f(u * 0.045)}"/>'
          f'<ellipse cx="{f(cx + u * 0.23)}" cy="{f(cy + u * 0.38)}" '
          f'rx="{f(u * 0.095)}" ry="{f(u * 0.055)}"/>'
          f'<ellipse cx="{f(cx - u * 0.28)}" cy="{f(cy + u * 0.36)}" '
          f'rx="{f(u * 0.110)}" ry="{f(u * 0.060)}"/>'
          f"</g>"
        + f'<g stroke="{dark}" stroke-width="{f(u * 0.009)}" opacity="0.55" '
          f'fill="none">'
          f'<path d="M{f(cx + u * 0.185)} {f(cy + u * 0.375)}'
          f'v{f(u * 0.028)}"/>'
          f'<path d="M{f(cx + u * 0.230)} {f(cy + u * 0.372)}'
          f'v{f(u * 0.030)}"/>'
          f'<path d="M{f(cx + u * 0.275)} {f(cy + u * 0.375)}'
          f'v{f(u * 0.028)}"/>'
          f"</g>"
        # mane: two lobed courses, the outer darker. Petal rings were tried here
        # first and the spikes made the whole animal read as a marigold; a
        # scalloped silhouette reads as fur at this size.
        + lit(_lobed_ring(hx, hy, hr * 1.40, hr * 1.86, 11, 0.14), dark,
              -hr * 0.05, -hr * 0.05, 0.80)
        + lit(_lobed_ring(hx, hy, hr * 1.14, hr * 1.50, 9, -0.20), "#CE8A38",
              -hr * 0.04, -hr * 0.04, 0.84)
        + f'<circle cx="{f(hx)}" cy="{f(hy)}" r="{f(hr)}" '
          f'fill="{shade(light, 0.86)}"/>'
          f'<circle cx="{f(hx - hr * 0.10)}" cy="{f(hy - hr * 0.10)}" '
          f'r="{f(hr * 0.94)}" fill="{light}"/>'
        # muzzle, nose, mouth
        + f'<ellipse cx="{f(hx + hr * 0.58)}" cy="{f(hy + hr * 0.38)}" '
          f'rx="{f(hr * 0.54)}" ry="{f(hr * 0.42)}" '
          f'fill="{shade("#F7D7A4", 0.92)}"/>'
          f'<ellipse cx="{f(hx + hr * 0.54)}" cy="{f(hy + hr * 0.34)}" '
          f'rx="{f(hr * 0.48)}" ry="{f(hr * 0.36)}" fill="#F7D7A4"/>'
          f'<path d="M{f(hx + hr * 0.86)} {f(hy + hr * 0.16)}'
          f'q{f(hr * 0.20)} {f(hr * 0.10)} {f(hr * 0.04)} {f(hr * 0.24)}z" '
          f'fill="{INK}" opacity="0.85"/>'
          f'<path d="M{f(hx + hr * 0.34)} {f(hy + hr * 0.68)}'
          f'q{f(hr * 0.28)} {f(hr * 0.20)} {f(hr * 0.58)} {f(-hr * 0.04)}" '
          f'fill="none" stroke="{INK}" stroke-width="{f(hr * 0.065)}" '
          f'opacity="0.5" stroke-linecap="round"/>'
        + _eye(hx + hr * 0.30, hy - hr * 0.12, hr * 1.24, u * 0.008)
        # ear
        + f'<circle cx="{f(hx - hr * 0.36)}" cy="{f(hy - hr * 0.88)}" '
          f'r="{f(hr * 0.25)}" fill="{shade(light, 0.90)}"/>'
          f'<circle cx="{f(hx - hr * 0.34)}" cy="{f(hy - hr * 0.86)}" '
          f'r="{f(hr * 0.15)}" fill="{dark}" opacity="0.7"/>'
    )

def g_mouse(cx: float, cy: float, s: float) -> str:
    """Mushaka -- Ganesha's vahana."""
    return (
        f'<ellipse cx="{f(cx)}" cy="{f(cy)}" rx="{f(s * 0.30)}" '
        f'ry="{f(s * 0.20)}" fill="#9C9A93"/>'
        f'<circle cx="{f(cx - s * 0.26)}" cy="{f(cy - s * 0.04)}" '
        f'r="{f(s * 0.13)}" fill="#ADABA3"/>'
        f'<circle cx="{f(cx - s * 0.20)}" cy="{f(cy - s * 0.16)}" '
        f'r="{f(s * 0.08)}" fill="#C6BFB4"/>'
        f'<circle cx="{f(cx - s * 0.33)}" cy="{f(cy - s * 0.05)}" '
        f'r="{f(s * 0.02)}" fill="{INK}"/>'
        f'<path d="M{f(cx + s * 0.28)} {f(cy)}'
        f'q{f(s * 0.20)} {f(s * 0.04)} {f(s * 0.14)} {f(-s * 0.18)}" '
        f'fill="none" stroke="#9C9A93" stroke-width="{f(s * 0.035)}"/>'
    )


GLYPHS = {
    "trishul": g_trishul,
    "damaru": g_damaru,
    "gada": g_gada,
    "bow": g_bow,
    "arrow": g_arrow,
    "flute": g_flute,
    "feather": g_feather,
    "veena": g_veena,
    "pothi": g_pothi,
    "conch": g_conch,
    "chakra": g_chakra,
    "spear": g_spear,
    "mala": g_mala,
    "coin": g_coin,
    "modak": g_modak,
    "ladoo": g_ladoo,
    "swan": g_swan,
    "parrot": g_parrot,
    "fish": g_fish,
    "lion": g_lion,
    "mouse": g_mouse,
    "kalash": lambda cx, cy, s: kalash(cx, cy + s * 0.42, s * 0.72),
    "bell": lambda cx, cy, s: bell(cx, cy - s * 0.45, s * 0.90),
    "lotus": lambda cx, cy, s: lotus(cx, cy + s * 0.30, s * 0.52,
                                     ROSE_LT, ROSE, 7, 150),
}


def glyph(name: str, cx: float, cy: float, s: float) -> str:
    fn = GLYPHS.get(name)
    return fn(cx, cy, s) if fn else ""


# ------------------------------------------------------- the seated murti --
# Proportions are fractions of `h`, the crown-finial-tip to seat-line distance,
# so a caller positions a figure purely by its bounding box.
#
# House rules for the figure, so twelve deities read as one body of work:
#   * one light, upper-left. Every mass gets a shade pass under a lit copy
#     (see lit()), so nothing is a flat silhouette.
#   * definition lines are INK at low opacity, never black outlines.
#   * ornament is layered -- choker, haar, armlet, two bangles, belt clasp --
#     because a single necklace on bare skin is what makes flat art look thin.

TALL_ATTRS = {"trishul", "gada", "bow", "spear", "arrow"}
# these have a handedness -- flip them when they sit in a left hand
ASYM_ATTRS = {"bow"}


def _ol(d: str, width: float, op: float = 0.20) -> str:
    """Definition line. Without it, skin arms vanish into a skin torso."""
    return (
        f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{f(width)}" '
        f'opacity="{f(op)}" stroke-linejoin="round" stroke-linecap="round"/>'
    )


def _taper(pts: list[tuple[float, float]], ws: list[float], color: str,
           shade_k: float = 0.0) -> str:
    """A limb, trunk or tail: overlapping round-capped segments that narrow."""
    out = []
    if shade_k:
        for i in range(len(pts) - 1):
            (x0, y0), (x1, y1) = pts[i], pts[i + 1]
            out.append(
                f'<path d="M{f(x0)} {f(y0)}L{f(x1)} {f(y1)}" fill="none" '
                f'stroke="{shade(color, shade_k)}" '
                f'stroke-width="{f((ws[i] + ws[i + 1]) / 2)}" '
                f'stroke-linecap="round"/>'
            )
        out.append(
            f'<g transform="translate({f(-ws[0] * 0.10)} '
            f'{f(-ws[0] * 0.10)})">'
        )
    for i in range(len(pts) - 1):
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        out.append(
            f'<path d="M{f(x0)} {f(y0)}L{f(x1)} {f(y1)}" fill="none" '
            f'stroke="{color}" stroke-width="{f((ws[i] + ws[i + 1]) / 2)}" '
            f'stroke-linecap="round"/>'
        )
    if shade_k:
        out.append("</g>")
    return "".join(out)


def _ribbon(p0: tuple[float, float], c1: tuple[float, float],
            c2: tuple[float, float], p3: tuple[float, float],
            w0: float, w1: float, color: str, k: float = 0.80,
            samples: int = 28, edge: float = 0.0) -> str:
    """A smooth tapering band along one cubic -- tails, trunks, scarves.

    _taper() draws straight segments, which kink visibly at large sizes; this
    walks the curve and offsets along the normal instead, so the silhouette
    stays smooth however sharply the spine turns.

    Pass `edge` to outline it: a trunk crossing a face of the same colour needs
    a contour line, or the two masses merge into one silhouette.
    """
    left: list[tuple[float, float]] = []
    right: list[tuple[float, float]] = []
    for i in range(samples + 1):
        t = i / samples
        u = 1.0 - t
        x = (u ** 3 * p0[0] + 3 * u * u * t * c1[0]
             + 3 * u * t * t * c2[0] + t ** 3 * p3[0])
        y = (u ** 3 * p0[1] + 3 * u * u * t * c1[1]
             + 3 * u * t * t * c2[1] + t ** 3 * p3[1])
        dx = (3 * u * u * (c1[0] - p0[0]) + 6 * u * t * (c2[0] - c1[0])
              + 3 * t * t * (p3[0] - c2[0]))
        dy = (3 * u * u * (c1[1] - p0[1]) + 6 * u * t * (c2[1] - c1[1])
              + 3 * t * t * (p3[1] - c2[1]))
        ln = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / ln, dx / ln
        hw = (w0 + (w1 - w0) * t ** 0.9) / 2
        left.append((x + nx * hw, y + ny * hw))
        right.append((x - nx * hw, y - ny * hw))
    d = (
        "M" + "L".join(f"{f(x)} {f(y)}" for x, y in left)
        + "L" + "L".join(f"{f(x)} {f(y)}" for x, y in reversed(right)) + "Z"
    )
    return (
        lit(d, color, -w0 * 0.10, -w0 * 0.10, k)
        + f'<circle cx="{f(p3[0])}" cy="{f(p3[1])}" r="{f(w1 * 0.5)}" '
          f'fill="{color}"/>'
        + (_ol(d, edge, 0.26) if edge else "")
    )


def _jewel(cx: float, cy: float, r: float, stone: str = TERRA) -> str:
    """Cabochon in a gold bezel -- the unit every ornament is built from."""
    return (
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" '
        f'fill="{shade(GOLD, 0.72)}"/>'
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.74)}" '
        f'fill="{stone}"/>'
        f'<circle cx="{f(cx - r * 0.24)}" cy="{f(cy - r * 0.26)}" '
        f'r="{f(r * 0.22)}" fill="{CREAM}" opacity="0.55"/>'
    )


def _armlet(x: float, y: float, ax: float, ay: float, w: float,
            gold: str = GOLD) -> str:
    """Bajubandh: a slim jewelled band lying across a limb towards (ax, ay)."""
    ang = math.degrees(math.atan2(ay - y, ax - x))
    return (
        f'<g transform="rotate({f(ang)} {f(x)} {f(y)})">'
        f'<rect x="{f(x - w * 0.150)}" y="{f(y - w * 0.60)}" '
        f'width="{f(w * 0.300)}" height="{f(w * 1.20)}" rx="{f(w * 0.11)}" '
        f'fill="{shade(gold, 0.86)}"/>'
        f'<rect x="{f(x - w * 0.115)}" y="{f(y - w * 0.58)}" '
        f'width="{f(w * 0.230)}" height="{f(w * 1.16)}" rx="{f(w * 0.10)}" '
        f'fill="{gold}"/>'
        f'<rect x="{f(x - w * 0.095)}" y="{f(y - w * 0.54)}" '
        f'width="{f(w * 0.070)}" height="{f(w * 1.08)}" rx="{f(w * 0.04)}" '
        f'fill="{tint(gold, 1.32)}" opacity="0.7"/>'
        f"</g>"
        + _jewel(x, y, w * 0.155)
    )


def _bangles(x: float, y: float, ax: float, ay: float, w: float,
             gold: str = GOLD) -> str:
    """Two thin kangan at the wrist rather than one thick cuff."""
    ang = math.degrees(math.atan2(ay - y, ax - x))
    dx = math.cos(math.radians(ang)) * w * 0.32
    dy = math.sin(math.radians(ang)) * w * 0.32
    bands = []
    for k in (0, 1):
        bx, by = x - dx * k, y - dy * k
        bands.append(
            f'<g transform="rotate({f(ang)} {f(bx)} {f(by)})">'
            f'<rect x="{f(bx - w * 0.058)}" y="{f(by - w * 0.60)}" '
            f'width="{f(w * 0.116)}" height="{f(w * 1.20)}" '
            f'rx="{f(w * 0.055)}" fill="{shade(gold, 0.86)}"/>'
            f'<rect x="{f(bx - w * 0.040)}" y="{f(by - w * 0.56)}" '
            f'width="{f(w * 0.080)}" height="{f(w * 1.12)}" '
            f'rx="{f(w * 0.040)}" fill="{gold}"/>'
            f"</g>"
        )
    return "".join(bands)


def _arm(sh: tuple[float, float], el: tuple[float, float],
         wr: tuple[float, float], w_up: float, w_fore: float,
         skin: str, lw: float, gold: str = GOLD) -> str:
    """Shoulder -> elbow -> wrist, shaded on its lower edge and ornamented."""
    off = w_up * 0.13
    segs = ((sh, el, w_up), (el, wr, w_fore))
    out = []
    for (x0, y0), (x1, y1), w in segs:  # shade pass
        out.append(
            f'<path d="M{f(x0)} {f(y0)}L{f(x1)} {f(y1)}" fill="none" '
            f'stroke="{shade(skin, 0.84)}" stroke-width="{f(w)}" '
            f'stroke-linecap="round"/>'
        )
    out.append(f'<g transform="translate({f(-off)} {f(-off * 0.7)})">')
    for (x0, y0), (x1, y1), w in segs:  # lit pass
        out.append(
            f'<path d="M{f(x0)} {f(y0)}L{f(x1)} {f(y1)}" fill="none" '
            f'stroke="{skin}" stroke-width="{f(w * 0.94)}" '
            f'stroke-linecap="round"/>'
        )
    out.append("</g>")
    mx = sh[0] * 0.42 + el[0] * 0.58
    my = sh[1] * 0.42 + el[1] * 0.58
    out.append(_armlet(mx, my, el[0], el[1], w_up, gold))
    out.append(_bangles(wr[0], wr[1], el[0], el[1], w_fore, gold))
    return "".join(out)


def _hand(x: float, y: float, r: float, skin: str, lw: float,
          open_palm: bool = False) -> str:
    """A palm with a thumb and four fingers -- a disc reads as a mitten."""
    palm = (
        f"M{f(x - r * 0.70)} {f(y + r * 0.30)}"
        f"C{f(x - r * 0.84)} {f(y - r * 0.34)} {f(x - r * 0.52)} "
        f"{f(y - r * 1.04)} {f(x - r * 0.04)} {f(y - r * 1.08)}"
        f"C{f(x + r * 0.52)} {f(y - r * 1.12)} {f(x + r * 0.84)} "
        f"{f(y - r * 0.30)} {f(x + r * 0.62)} {f(y + r * 0.44)}"
        f"C{f(x + r * 0.44)} {f(y + r * 1.02)} {f(x - r * 0.46)} "
        f"{f(y + r * 1.00)} {f(x - r * 0.70)} {f(y + r * 0.30)}Z"
    )
    out = [
        lit(palm, skin, -r * 0.09, -r * 0.07, 0.84),
        lit(  # thumb
            f"M{f(x - r * 0.62)} {f(y - r * 0.16)}"
            f"C{f(x - r * 1.02)} {f(y - r * 0.10)} {f(x - r * 1.10)} "
            f"{f(y + r * 0.44)} {f(x - r * 0.78)} {f(y + r * 0.58)}"
            f"C{f(x - r * 0.58)} {f(y + r * 0.64)} {f(x - r * 0.48)} "
            f"{f(y + r * 0.30)} {f(x - r * 0.52)} {f(y - r * 0.02)}Z",
            skin, -r * 0.07, -r * 0.06, 0.80,
        ),
        _ol(palm, lw * 0.9, 0.16),
    ]
    if open_palm:
        out.append(
            f'<g fill="none" stroke="{shade(skin, 0.76)}" '
            f'stroke-width="{f(lw * 1.3)}" stroke-linecap="round" '
            f'opacity="0.75">'
            + "".join(
                f'<path d="M{f(x + r * dx)} {f(y - r * 0.92)}'
                f'v{f(r * 0.52)}"/>'
                for dx in (-0.36, -0.06, 0.24, 0.50)
            )
            + f'<path d="M{f(x - r * 0.40)} {f(y + r * 0.16)}'
              f'q{f(r * 0.40)} {f(r * 0.20)} {f(r * 0.78)} {f(-r * 0.06)}"/>'
            + "</g>"
        )
    return "".join(out)


def _foot(x: float, y: float, s: float, tilt: float, skin: str,
          lw: float) -> str:
    """One upturned sole, the way padmasana presents the feet.

    Deliberately low-contrast: a bright sole on a dark hem reads as an object
    lying on the lap rather than as part of the figure.
    """
    body = (
        f"M{f(x - s * 0.92)} {f(y - s * 0.10)}"
        f"C{f(x - s * 1.02)} {f(y + s * 0.34)} {f(x - s * 0.50)} "
        f"{f(y + s * 0.54)} {f(x + s * 0.16)} {f(y + s * 0.50)}"
        f"C{f(x + s * 0.78)} {f(y + s * 0.46)} {f(x + s * 1.00)} "
        f"{f(y + s * 0.16)} {f(x + s * 0.94)} {f(y - s * 0.14)}"
        f"C{f(x + s * 0.86)} {f(y - s * 0.48)} {f(x - s * 0.60)} "
        f"{f(y - s * 0.52)} {f(x - s * 0.92)} {f(y - s * 0.10)}Z"
    )
    return (
        f'<g transform="rotate({f(tilt)} {f(x)} {f(y)})">'
        + lit(body, skin, -s * 0.05, -s * 0.05, 0.86)
        # the arch of the sole, only a shade lighter than the foot
        + f'<ellipse cx="{f(x + s * 0.12)}" cy="{f(y + s * 0.04)}" '
          f'rx="{f(s * 0.52)}" ry="{f(s * 0.24)}" '
          f'fill="{tint(skin, 1.07)}" opacity="0.7"/>'
        + f'<g fill="{tint(skin, 1.04)}" stroke="{shade(skin, 0.82)}" '
          f'stroke-width="{f(lw * 0.7)}" stroke-opacity="0.7">'
        + "".join(  # toes, largest inboard
            f'<ellipse cx="{f(x - s * (0.72 - 0.052 * k))}" '
            f'cy="{f(y - s * (0.24 - 0.132 * k))}" '
            f'rx="{f(s * (0.130 - 0.016 * k))}" '
            f'ry="{f(s * (0.108 - 0.013 * k))}"/>'
            for k in range(5)
        )
        + "</g>"
        + _ol(body, lw * 0.9, 0.14)
        + f'<circle cx="{f(x + s * 0.16)}" cy="{f(y + s * 0.04)}" '
          f'r="{f(s * 0.10)}" fill="{TERRA}" opacity="0.32"/>'
        + "</g>"
    )


def _beads(d: str, thread: str, bead: str, tw: float, bw: float,
           gap: float) -> str:
    """A strung line -- round dashes on a thin thread read as beads."""
    return (
        f'<path d="{d}" fill="none" stroke="{thread}" '
        f'stroke-width="{f(tw)}" opacity="0.9"/>'
        f'<path d="{d}" fill="none" stroke="{shade(bead, 0.78)}" '
        f'stroke-width="{f(bw)}" stroke-linecap="round" '
        f'stroke-dasharray="{f(bw * 0.06)} {f(gap)}"/>'
        f'<path d="{d}" fill="none" stroke="{bead}" '
        f'stroke-width="{f(bw * 0.72)}" stroke-linecap="round" '
        f'stroke-dasharray="{f(bw * 0.06)} {f(gap)}"/>'
    )


def _prabhavali(cx: float, cy: float, r: float, color: str) -> str:
    """The aureole: flame course, petal course, disc, beaded ring."""
    return (
        petal_ring(cx, cy, r * 1.00, r * 1.20, 40, shade(color, 0.80), 0.45,
                   4.5, 0.30)
        + petal_ring(cx, cy, r * 0.98, r * 1.13, 20, color, 0.80, 0.0, 0.42)
        + f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="{color}" '
          f'opacity="0.22"/>'
          f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.70)}" '
          f'fill="{tint(color, 1.22)}" opacity="0.28"/>'
          f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="none" '
          f'stroke="{color}" stroke-width="{f(r * 0.046)}" opacity="0.9"/>'
          f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.895)}" fill="none" '
          f'stroke="{GOLD_PALE}" stroke-width="{f(r * 0.050)}" '
          f'stroke-linecap="round" stroke-dasharray="{f(r * 0.004)} '
          f'{f(r * 0.112)}" opacity="0.85"/>'
          f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.952)}" fill="none" '
          f'stroke="{CREAM}" stroke-width="{f(r * 0.015)}" opacity="0.5"/>'
    )


def seated_figure(cx: float, top: float, h: float, *,
                  skin: str = SKIN,
                  garment: str = TERRA,
                  dhoti: str = "#E0A83C",
                  crown: str = GOLD,
                  sash: str = ROSE_LT,
                  head: str = "human",
                  arms: int = 2,
                  hands: tuple[str, ...] = (),
                  halo: bool = True,
                  halo_color: str = GOLD_BRIGHT,
                  bodice: bool = False,
                  garland: bool = False,
                  pose: str = "") -> str:
    """A deity seated in padmasana, drawn flat but modelled.

    `top` is the tip of the crown finial and `h` the distance from there to the
    seat line (SEAT_T), so callers position the figure by its bounding box.
    `hands` fills hand slots in order lower-right, lower-left, upper-right,
    upper-left (viewer's side); any name from GLYPHS works, and the long
    weapons in TALL_ATTRS are gripped through the palm -- standing like a staff
    in a lower hand, raised in an upper one.
    """
    y = lambda t: top + h * t  # noqa: E731 -- local shorthand, reads better
    lw = h * 0.0055
    parts: list[str] = []

    head_cy, head_r = y(0.205), h * 0.085
    skin_d = shade(skin, 0.84)

    if halo:
        parts.append(_prabhavali(cx, head_cy, h * 0.215, halo_color))

    # ---- the lap: dhoti draped over crossed legs, knees out to the sides
    lap = (
        f"M{f(cx - h * 0.122)} {f(y(0.560))}"
        f"C{f(cx - h * 0.200)} {f(y(0.575))} {f(cx - h * 0.268)} "
        f"{f(y(0.615))} {f(cx - h * 0.272)} {f(y(0.690))}"
        f"C{f(cx - h * 0.274)} {f(y(0.736))} {f(cx - h * 0.240)} "
        f"{f(y(0.760))} {f(cx - h * 0.180)} {f(y(0.760))}"
        f"L{f(cx + h * 0.180)} {f(y(0.760))}"
        f"C{f(cx + h * 0.240)} {f(y(0.760))} {f(cx + h * 0.274)} "
        f"{f(y(0.736))} {f(cx + h * 0.272)} {f(y(0.690))}"
        f"C{f(cx + h * 0.268)} {f(y(0.615))} {f(cx + h * 0.200)} "
        f"{f(y(0.575))} {f(cx + h * 0.122)} {f(y(0.560))}Z"
    )
    parts.append(lit(lap, dhoti, -h * 0.006, -h * 0.005, 0.82))
    # cloth breaking over each knee
    for sx in (-1, 1):
        parts.append(
            f'<path d="M{f(cx + sx * h * 0.272)} {f(y(0.664))}'
            f'C{f(cx + sx * h * 0.226)} {f(y(0.648))} '
            f'{f(cx + sx * h * 0.180)} {f(y(0.678))} '
            f'{f(cx + sx * h * 0.166)} {f(y(0.732))}'
            f'C{f(cx + sx * h * 0.214)} {f(y(0.758))} '
            f'{f(cx + sx * h * 0.268)} {f(y(0.742))} '
            f'{f(cx + sx * h * 0.274)} {f(y(0.700))}Z" '
            f'fill="{tint(dhoti, 1.14)}" opacity="0.5"/>'
        )
    # pleat fan: a dark fold with a lit edge beside it
    parts.append(
        '<g fill="none" stroke-linecap="round">'
        + "".join(
            f'<path d="M{f(cx + h * dx * 0.34)} {f(y(0.582))}'
            f'C{f(cx + h * dx * 0.74)} {f(y(0.662))} {f(cx + h * dx)} '
            f'{f(y(0.700))} {f(cx + h * dx)} {f(y(0.752))}" '
            f'stroke="{shade(dhoti, 0.76)}" stroke-width="{f(lw * 1.5)}" '
            f'opacity="0.5"/>'
            f'<path d="M{f(cx + h * dx * 0.34 + h * 0.008)} {f(y(0.582))}'
            f'C{f(cx + h * dx * 0.74 + h * 0.008)} {f(y(0.662))} '
            f'{f(cx + h * dx + h * 0.008)} {f(y(0.700))} '
            f'{f(cx + h * dx + h * 0.008)} {f(y(0.752))}" '
            f'stroke="{tint(dhoti, 1.18)}" stroke-width="{f(lw)}" '
            f'opacity="0.42"/>'
            for dx in (-0.148, -0.074, 0.0, 0.074, 0.148)
        )
        + "</g>"
    )
    # hem: gold band with a woven dash inside it
    hem = (
        f"M{f(cx - h * 0.272)} {f(y(0.688))}"
        f"C{f(cx - h * 0.274)} {f(y(0.736))} {f(cx - h * 0.240)} "
        f"{f(y(0.760))} {f(cx - h * 0.180)} {f(y(0.760))}"
        f"L{f(cx + h * 0.180)} {f(y(0.760))}"
        f"C{f(cx + h * 0.240)} {f(y(0.760))} {f(cx + h * 0.274)} "
        f"{f(y(0.736))} {f(cx + h * 0.272)} {f(y(0.688))}"
    )
    parts.append(
        f'<path d="{hem}" fill="none" stroke="{shade(GOLD, 0.82)}" '
        f'stroke-width="{f(h * 0.020)}"/>'
        f'<path d="{hem}" fill="none" stroke="{GOLD}" '
        f'stroke-width="{f(h * 0.015)}"/>'
        f'<path d="{hem}" fill="none" stroke="{GOLD_PALE}" '
        f'stroke-width="{f(h * 0.005)}" '
        f'stroke-dasharray="{f(h * 0.011)} {f(h * 0.009)}" opacity="0.9"/>'
    )
    parts.append(_ol(lap, lw * 1.3))
    parts.append(_foot(cx - h * 0.070, y(0.638), h * 0.068, -13, skin, lw))
    parts.append(_foot(cx + h * 0.070, y(0.620), h * 0.068, 13, skin, lw))

    # ---- torso, widest at the shoulders
    torso = (
        f"M{f(cx - h * 0.122)} {f(y(0.570))}"
        f"C{f(cx - h * 0.140)} {f(y(0.500))} {f(cx - h * 0.178)} "
        f"{f(y(0.430))} {f(cx - h * 0.170)} {f(y(0.372))}"
        f"C{f(cx - h * 0.150)} {f(y(0.330))} {f(cx - h * 0.060)} "
        f"{f(y(0.312))} {f(cx)} {f(y(0.312))}"
        f"C{f(cx + h * 0.060)} {f(y(0.312))} {f(cx + h * 0.150)} "
        f"{f(y(0.330))} {f(cx + h * 0.170)} {f(y(0.372))}"
        f"C{f(cx + h * 0.178)} {f(y(0.430))} {f(cx + h * 0.140)} "
        f"{f(y(0.500))} {f(cx + h * 0.122)} {f(y(0.570))}Z"
    )
    parts.append(lit(torso, skin, -h * 0.007, -h * 0.005, 0.86))

    if bodice:
        top_cloth = (
            f"M{f(cx - h * 0.170)} {f(y(0.372))}"
            f"C{f(cx - h * 0.150)} {f(y(0.330))} {f(cx - h * 0.060)} "
            f"{f(y(0.312))} {f(cx)} {f(y(0.312))}"
            f"C{f(cx + h * 0.060)} {f(y(0.312))} {f(cx + h * 0.150)} "
            f"{f(y(0.330))} {f(cx + h * 0.170)} {f(y(0.372))}"
            f"C{f(cx + h * 0.176)} {f(y(0.412))} {f(cx + h * 0.170)} "
            f"{f(y(0.452))} {f(cx + h * 0.160)} {f(y(0.482))}"
            f"C{f(cx + h * 0.070)} {f(y(0.502))} {f(cx - h * 0.070)} "
            f"{f(y(0.502))} {f(cx - h * 0.160)} {f(y(0.482))}"
            f"C{f(cx - h * 0.170)} {f(y(0.452))} {f(cx - h * 0.176)} "
            f"{f(y(0.412))} {f(cx - h * 0.170)} {f(y(0.372))}Z"
        )
        parts.append(lit(top_cloth, garment, -h * 0.005, -h * 0.004, 0.82))
        neck_v = (
            f"M{f(cx - h * 0.058)} {f(y(0.315))}"
            f"C{f(cx - h * 0.050)} {f(y(0.386))} {f(cx + h * 0.050)} "
            f"{f(y(0.386))} {f(cx + h * 0.058)} {f(y(0.315))}"
        )
        parts.append(
            f'<path d="{neck_v}Z" fill="{skin}"/>'
            f'<path d="{neck_v}" fill="none" '
            f'stroke="{shade(garment, 0.74)}" stroke-width="{f(lw * 1.4)}"/>'
            # choli hem trim and two soft folds
            f'<path d="M{f(cx - h * 0.160)} {f(y(0.482))}'
            f'C{f(cx - h * 0.070)} {f(y(0.502))} {f(cx + h * 0.070)} '
            f'{f(y(0.502))} {f(cx + h * 0.160)} {f(y(0.482))}" fill="none" '
            f'stroke="{GOLD}" stroke-width="{f(h * 0.009)}" opacity="0.9"/>'
            f'<g fill="none" stroke="{shade(garment, 0.72)}" '
            f'stroke-width="{f(lw * 1.3)}" opacity="0.5" '
            f'stroke-linecap="round">'
            f'<path d="M{f(cx - h * 0.112)} {f(y(0.398))}'
            f'q{f(h * 0.020)} {f(h * 0.044)} {f(-h * 0.004)} '
            f'{f(h * 0.080)}"/>'
            f'<path d="M{f(cx + h * 0.112)} {f(y(0.398))}'
            f'q{f(-h * 0.020)} {f(h * 0.044)} {f(h * 0.004)} '
            f'{f(h * 0.080)}"/>'
            f"</g>"
        )
        parts.append(_ol(top_cloth, lw))
    else:
        # bare chest: pectorals, sternum, navel, and the sacred thread
        thread = (
            f"M{f(cx - h * 0.124)} {f(y(0.348))}"
            f"C{f(cx - h * 0.062)} {f(y(0.466))} {f(cx + h * 0.030)} "
            f"{f(y(0.518))} {f(cx + h * 0.112)} {f(y(0.552))}"
        )
        parts.append(
            f'<g fill="none" stroke="{skin_d}" stroke-linecap="round">'
            f'<path d="M{f(cx - h * 0.112)} {f(y(0.392))}'
            f'C{f(cx - h * 0.084)} {f(y(0.446))} {f(cx - h * 0.020)} '
            f'{f(y(0.450))} {f(cx - h * 0.004)} {f(y(0.414))}" '
            f'stroke-width="{f(lw * 1.7)}" opacity="0.75"/>'
            f'<path d="M{f(cx + h * 0.112)} {f(y(0.392))}'
            f'C{f(cx + h * 0.084)} {f(y(0.446))} {f(cx + h * 0.020)} '
            f'{f(y(0.450))} {f(cx + h * 0.004)} {f(y(0.414))}" '
            f'stroke-width="{f(lw * 1.7)}" opacity="0.75"/>'
            f'<path d="M{f(cx)} {f(y(0.420))}V{f(y(0.478))}" '
            f'stroke-width="{f(lw * 1.2)}" opacity="0.5"/>'
            f'<path d="M{f(cx - h * 0.052)} {f(y(0.514))}'
            f'q{f(h * 0.052)} {f(h * 0.026)} {f(h * 0.104)} 0" '
            f'stroke-width="{f(lw * 1.2)}" opacity="0.45"/>'
            f"</g>"
            f'<ellipse cx="{f(cx)}" cy="{f(y(0.508))}" rx="{f(h * 0.010)}" '
            f'ry="{f(h * 0.008)}" fill="{skin_d}"/>'
            f'<path d="{thread}" fill="none" '
            f'stroke="{shade(CREAM, 0.86)}" stroke-width="{f(h * 0.010)}"/>'
            f'<path d="{thread}" fill="none" stroke="{CREAM}" '
            f'stroke-width="{f(h * 0.006)}"/>'
        )

    # ---- angavastram over the left shoulder, across the chest
    sash_d = (
        f"M{f(cx - h * 0.178)} {f(y(0.348))}"
        f"C{f(cx - h * 0.122)} {f(y(0.452))} {f(cx - h * 0.010)} "
        f"{f(y(0.520))} {f(cx + h * 0.096)} {f(y(0.566))}"
        f"L{f(cx + h * 0.152)} {f(y(0.556))}"
        f"C{f(cx + h * 0.040)} {f(y(0.500))} {f(cx - h * 0.062)} "
        f"{f(y(0.436))} {f(cx - h * 0.110)} {f(y(0.334))}Z"
    )
    parts.append(lit(sash_d, sash, -h * 0.004, -h * 0.003, 0.80))
    parts.append(
        f'<path d="M{f(cx - h * 0.150)} {f(y(0.352))}'
        f'C{f(cx - h * 0.092)} {f(y(0.454))} {f(cx + h * 0.004)} '
        f'{f(y(0.514))} {f(cx + h * 0.110)} {f(y(0.556))}" fill="none" '
        f'stroke="{GOLD}" stroke-width="{f(h * 0.006)}" opacity="0.7"/>'
    )
    # the fold of it falling over the left shoulder
    parts.append(
        lit(
            f"M{f(cx - h * 0.178)} {f(y(0.346))}"
            f"C{f(cx - h * 0.230)} {f(y(0.382))} {f(cx - h * 0.238)} "
            f"{f(y(0.462))} {f(cx - h * 0.206)} {f(y(0.522))}"
            f"C{f(cx - h * 0.188)} {f(y(0.470))} {f(cx - h * 0.160)} "
            f"{f(y(0.408))} {f(cx - h * 0.132)} {f(y(0.366))}Z",
            sash, -h * 0.003, -h * 0.003, 0.74,
        )
    )
    # ---- waist belt with a clasp
    parts.append(
        rrect(cx - h * 0.132, y(0.550), h * 0.264, h * 0.044, h * 0.016,
              shade(garment, 0.78))
        + rrect(cx - h * 0.130, y(0.550), h * 0.260, h * 0.036, h * 0.014,
                garment)
        + f'<path d="M{f(cx - h * 0.130)} {f(y(0.557))}h{f(h * 0.260)}" '
          f'stroke="{GOLD}" stroke-width="{f(h * 0.005)}" opacity="0.85"/>'
          f'<path d="M{f(cx - h * 0.130)} {f(y(0.585))}h{f(h * 0.260)}" '
          f'stroke="{GOLD}" stroke-width="{f(h * 0.005)}" opacity="0.65"/>'
        + _jewel(cx, y(0.571), h * 0.018, GOLD_BRIGHT)
    )

    # ---- arms
    w_up, w_fore = h * 0.060, h * 0.049
    hand_r = h * 0.040
    lower = [
        ((cx + h * 0.152, y(0.362)), (cx + h * 0.230, y(0.494)),
         (cx + h * 0.204, y(0.606)), (cx + h * 0.210, y(0.640))),
        ((cx - h * 0.152, y(0.362)), (cx - h * 0.230, y(0.494)),
         (cx - h * 0.204, y(0.606)), (cx - h * 0.210, y(0.640))),
    ]
    if pose == "flute":
        # venugopala: elbows out at shoulder height, forearms rising inward so
        # the bansuri crosses the lip line -- not the chest, where it read as a
        # stick lying on the belt
        lower = [
            ((cx + h * 0.152, y(0.372)), (cx + h * 0.226, y(0.372)),
             (cx + h * 0.172, y(0.300)), (cx + h * 0.128, y(0.278))),
            ((cx - h * 0.152, y(0.372)), (cx - h * 0.214, y(0.336)),
             (cx - h * 0.158, y(0.262)), (cx - h * 0.120, y(0.240))),
        ]
    upper = [
        ((cx + h * 0.148, y(0.352)), (cx + h * 0.250, y(0.406)),
         (cx + h * 0.272, y(0.306)), (cx + h * 0.278, y(0.282))),
        ((cx - h * 0.148, y(0.352)), (cx - h * 0.250, y(0.406)),
         (cx - h * 0.272, y(0.306)), (cx - h * 0.278, y(0.282))),
    ]
    limbs = lower + (upper if arms >= 4 else [])
    for sh, el, wr, _hp in limbs:
        parts.append(_arm(sh, el, wr, w_up, w_fore, skin, lw, crown))
    hand_pts = [hp for _s, _e, _w, hp in limbs]

    # ---- neck + head
    neck = (
        f"M{f(cx - h * 0.034)} {f(y(0.262))}"
        f"C{f(cx - h * 0.036)} {f(y(0.316))} {f(cx - h * 0.052)} "
        f"{f(y(0.336))} {f(cx - h * 0.062)} {f(y(0.344))}"
        f"L{f(cx + h * 0.062)} {f(y(0.344))}"
        f"C{f(cx + h * 0.052)} {f(y(0.336))} {f(cx + h * 0.036)} "
        f"{f(y(0.316))} {f(cx + h * 0.034)} {f(y(0.262))}Z"
    )
    parts.append(lit(neck, skin, -h * 0.005, -h * 0.004, 0.80))
    parts.append(  # the three throat lines
        f'<g fill="none" stroke="{skin_d}" stroke-linecap="round" '
        f'opacity="0.55">'
        f'<path d="M{f(cx - h * 0.032)} {f(y(0.290))}'
        f'q{f(h * 0.032)} {f(h * 0.020)} {f(h * 0.064)} 0" '
        f'stroke-width="{f(lw * 1.3)}"/>'
        f'<path d="M{f(cx - h * 0.028)} {f(y(0.308))}'
        f'q{f(h * 0.028)} {f(h * 0.018)} {f(h * 0.056)} 0" '
        f'stroke-width="{f(lw * 1.1)}"/>'
        f"</g>"
    )

    if head == "elephant":
        parts.append(_head_elephant(cx, head_cy, head_r, skin, lw))
    elif head == "vanara":
        parts.append(_head_vanara(cx, head_cy, head_r, lw))
    else:
        parts.append(_head_human(cx, head_cy, head_r, skin, lw, head))

    if head == "jata":
        parts.append(_jata(cx, head_cy, head_r, lw))
    else:
        parts.append(
            _mukut(cx, y(0.004), head_cy - head_r * 0.88,
                   head_r * (1.30 if head == "elephant" else 1.0), crown, lw)
        )

    # ---- ornament: choker, haar with a pendant, optional flower garland
    parts.append(
        f'<path d="M{f(cx - h * 0.058)} {f(y(0.334))}'
        f'Q{f(cx)} {f(y(0.372))} {f(cx + h * 0.058)} {f(y(0.334))}" '
        f'fill="none" stroke="{shade(crown, 0.78)}" '
        f'stroke-width="{f(h * 0.016)}" stroke-linecap="round"/>'
        f'<path d="M{f(cx - h * 0.058)} {f(y(0.332))}'
        f'Q{f(cx)} {f(y(0.370))} {f(cx + h * 0.058)} {f(y(0.332))}" '
        f'fill="none" stroke="{crown}" stroke-width="{f(h * 0.011)}" '
        f'stroke-linecap="round"/>'
        + _beads(
            f"M{f(cx - h * 0.100)} {f(y(0.344))}"
            f"Q{f(cx)} {f(y(0.436))} {f(cx + h * 0.100)} {f(y(0.344))}",
            shade(crown, 0.8), GOLD_PALE, h * 0.005, h * 0.014, h * 0.017,
        )
        + _jewel(cx, y(0.428), h * 0.020)
    )
    if garland:
        parts.append(_beads(
            f"M{f(cx - h * 0.142)} {f(y(0.344))}"
            f"C{f(cx - h * 0.156)} {f(y(0.470))} {f(cx - h * 0.060)} "
            f"{f(y(0.548))} {f(cx)} {f(y(0.548))}"
            f"C{f(cx + h * 0.060)} {f(y(0.548))} {f(cx + h * 0.156)} "
            f"{f(y(0.470))} {f(cx + h * 0.142)} {f(y(0.344))}",
            GREEN_LT, SAFFRON, h * 0.006, h * 0.026, h * 0.038,
        ))

    # ---- the trunk goes on last, over the choker and the haar
    if head == "elephant":
        parts.append(_gajamukha_front(cx, head_cy, head_r, skin, lw))

    # ---- what the hands hold
    if pose == "flute":
        # laid along the line between the two hands, which puts it across the
        # lips; drawn before them so the fingers close over it
        parts.append(g_flute(cx + h * 0.004, y(0.258), h * 0.388, "#DCB884",
                             8.7))
    for i, (hx, hy) in enumerate(hand_pts):
        name = hands[i] if i < len(hands) else ""
        if name == "flute" and pose == "flute":
            parts.append(_hand(hx, hy, hand_r, skin, lw))
            continue
        if name in TALL_ATTRS:
            # drawn first so the palm closes over the shaft; in a lower hand it
            # stands like a staff rising to the shoulder, pushed a little
            # outboard so the shaft clears the forearm
            out = h * 0.020 * (1 if hx > cx else -1)
            gx = hx + out
            gy = hy - (h * 0.150 if i < 2 else h * 0.020)
            art = glyph(name, gx, gy, h * (0.36 if i < 2 else 0.36))
            if name in ASYM_ATTRS and hx < cx:
                # the bow bellies towards +x; held on the left it would curve
                # back across the chest, so flip it about its own axis
                art = (f'<g transform="scale(-1 1) translate({f(-2 * gx)} 0)">'
                       f"{art}</g>")
            parts.append(art)
            parts.append(_hand(hx, hy, hand_r, skin, lw))
            continue
        parts.append(_hand(hx, hy, hand_r, skin, lw, open_palm=not name))
        if name:
            parts.append(
                glyph(name, hx, hy - h * 0.085,
                      h * (0.160 if i >= 2 else 0.155))
            )

    return "".join(parts)


# ------------------------------------------------------------------ heads --


def _eye(cx: float, cy: float, r: float, lw: float) -> str:
    """Elongated almond with a kajal lid -- the biggest single tell of quality.

    `r` is the head radius the eye belongs to, not the eye's own size.
    """
    ew, eh = r * 0.27, r * 0.125
    lid = (
        f"M{f(cx - ew)} {f(cy + eh * 0.20)}"
        f"C{f(cx - ew * 0.62)} {f(cy - eh * 1.30)} {f(cx + ew * 0.56)} "
        f"{f(cy - eh * 1.34)} {f(cx + ew)} {f(cy - eh * 0.18)}"
    )
    almond = (
        lid
        + f"C{f(cx + ew * 0.54)} {f(cy + eh * 0.94)} {f(cx - ew * 0.54)} "
          f"{f(cy + eh * 1.00)} {f(cx - ew)} {f(cy + eh * 0.20)}Z"
    )
    return (
        f'<path d="{almond}" fill="{CREAM}"/>'
        f'<circle cx="{f(cx + ew * 0.06)}" cy="{f(cy - eh * 0.08)}" '
        f'r="{f(eh * 0.80)}" fill="#43301F"/>'
        f'<circle cx="{f(cx + ew * 0.06)}" cy="{f(cy - eh * 0.08)}" '
        f'r="{f(eh * 0.38)}" fill="{INK}"/>'
        f'<circle cx="{f(cx - ew * 0.13)}" cy="{f(cy - eh * 0.48)}" '
        f'r="{f(eh * 0.22)}" fill="{CREAM}" opacity="0.85"/>'
        # upper lid, thick, extended past the outer corner as kajal
        f'<path d="{lid}" fill="none" stroke="{INK}" '
        f'stroke-width="{f(r * 0.036)}" stroke-linecap="round"/>'
        f'<path d="M{f(cx + ew * 0.86)} {f(cy - eh * 0.40)}'
        f'q{f(ew * 0.34)} {f(eh * 0.10)} {f(ew * 0.44)} {f(eh * 0.44)}" '
        f'fill="none" stroke="{INK}" stroke-width="{f(r * 0.024)}" '
        f'stroke-linecap="round"/>'
        # lower lash line, thin
        f'<path d="M{f(cx - ew * 0.92)} {f(cy + eh * 0.30)}'
        f'C{f(cx - ew * 0.50)} {f(cy + eh * 0.98)} {f(cx + ew * 0.52)} '
        f'{f(cy + eh * 0.92)} {f(cx + ew * 0.94)} {f(cy - eh * 0.10)}" '
        f'fill="none" stroke="{INK}" stroke-width="{f(r * 0.016)}" '
        f'opacity="0.7" stroke-linecap="round"/>'
    )


def _brow(cx: float, cy: float, r: float, sx: int) -> str:
    """Tapered brow -- thick at the inner end, fining off to the temple."""
    return (
        f'<path d="M{f(cx - sx * r * 0.13)} {f(cy + r * 0.035)}'
        f'C{f(cx + sx * r * 0.02)} {f(cy - r * 0.055)} '
        f'{f(cx + sx * r * 0.19)} {f(cy - r * 0.045)} '
        f'{f(cx + sx * r * 0.30)} {f(cy + r * 0.020)}'
        f'C{f(cx + sx * r * 0.17)} {f(cy - r * 0.005)} '
        f'{f(cx + sx * r * 0.01)} {f(cy + r * 0.012)} '
        f'{f(cx - sx * r * 0.13)} {f(cy + r * 0.035)}Z" fill="{INK}"/>'
    )


def _mouth(cx: float, cy: float, r: float) -> str:
    """Cupid's bow above, fuller lower lip, a single highlight."""
    w = r * 0.20
    upper = (
        f"M{f(cx - w)} {f(cy)}"
        f"C{f(cx - w * 0.62)} {f(cy - r * 0.052)} {f(cx - w * 0.22)} "
        f"{f(cy - r * 0.044)} {f(cx)} {f(cy - r * 0.010)}"
        f"C{f(cx + w * 0.22)} {f(cy - r * 0.044)} {f(cx + w * 0.62)} "
        f"{f(cy - r * 0.052)} {f(cx + w)} {f(cy)}"
        f"C{f(cx + w * 0.52)} {f(cy + r * 0.026)} {f(cx - w * 0.52)} "
        f"{f(cy + r * 0.026)} {f(cx - w)} {f(cy)}Z"
    )
    lower = (
        f"M{f(cx - w * 0.90)} {f(cy + r * 0.010)}"
        f"C{f(cx - w * 0.50)} {f(cy + r * 0.110)} {f(cx + w * 0.50)} "
        f"{f(cy + r * 0.110)} {f(cx + w * 0.90)} {f(cy + r * 0.010)}"
        f"C{f(cx + w * 0.44)} {f(cy + r * 0.042)} {f(cx - w * 0.44)} "
        f"{f(cy + r * 0.042)} {f(cx - w * 0.90)} {f(cy + r * 0.010)}Z"
    )
    return (
        f'<path d="{lower}" fill="#C0604A"/>'
        f'<path d="{upper}" fill="#A0453A"/>'
        f'<path d="M{f(cx - w * 0.86)} {f(cy + r * 0.008)}'
        f'q{f(w * 0.86)} {f(r * 0.034)} {f(w * 1.72)} 0" fill="none" '
        f'stroke="#7E3129" stroke-width="{f(r * 0.015)}" opacity="0.8" '
        f'stroke-linecap="round"/>'
        f'<path d="M{f(cx - w * 0.34)} {f(cy + r * 0.068)}'
        f'q{f(w * 0.34)} {f(r * 0.022)} {f(w * 0.68)} 0" fill="none" '
        f'stroke="{CREAM}" stroke-width="{f(r * 0.017)}" opacity="0.4" '
        f'stroke-linecap="round"/>'
    )


def _nose(cx: float, cy: float, r: float, skin: str) -> str:
    """Bridge shadow, wings, nostrils -- no outline, just the shaded side."""
    d = shade(skin, 0.80)
    return (
        f'<path d="M{f(cx - r * 0.028)} {f(cy - r * 0.150)}'
        f'C{f(cx - r * 0.094)} {f(cy + r * 0.060)} {f(cx - r * 0.112)} '
        f'{f(cy + r * 0.160)} {f(cx - r * 0.050)} {f(cy + r * 0.226)}" '
        f'fill="none" stroke="{d}" stroke-width="{f(r * 0.044)}" '
        f'stroke-linecap="round" opacity="0.8"/>'
        f'<path d="M{f(cx - r * 0.104)} {f(cy + r * 0.224)}'
        f'C{f(cx - r * 0.038)} {f(cy + r * 0.288)} {f(cx + r * 0.038)} '
        f'{f(cy + r * 0.288)} {f(cx + r * 0.104)} {f(cy + r * 0.224)}" '
        f'fill="none" stroke="{d}" stroke-width="{f(r * 0.032)}" '
        f'stroke-linecap="round" opacity="0.65"/>'
        f'<g fill="{shade(skin, 0.58)}">'
        f'<ellipse cx="{f(cx - r * 0.078)}" cy="{f(cy + r * 0.240)}" '
        f'rx="{f(r * 0.028)}" ry="{f(r * 0.019)}"/>'
        f'<ellipse cx="{f(cx + r * 0.078)}" cy="{f(cy + r * 0.240)}" '
        f'rx="{f(r * 0.028)}" ry="{f(r * 0.019)}"/>'
        f"</g>"
        f'<path d="M{f(cx + r * 0.028)} {f(cy + r * 0.140)}'
        f'q{f(r * 0.024)} {f(r * 0.048)} 0 {f(r * 0.076)}" fill="none" '
        f'stroke="{tint(skin, 1.22)}" stroke-width="{f(r * 0.028)}" '
        f'opacity="0.55" stroke-linecap="round"/>'
    )


def _ear(cx: float, cy: float, r: float, sx: int, skin: str,
         lw: float) -> str:
    shell = (
        f"M{f(cx)} {f(cy - r * 0.20)}"
        f"C{f(cx + sx * r * 0.19)} {f(cy - r * 0.26)} "
        f"{f(cx + sx * r * 0.21)} {f(cy + r * 0.16)} "
        f"{f(cx + sx * r * 0.06)} {f(cy + r * 0.26)}"
        f"C{f(cx - sx * r * 0.04)} {f(cy + r * 0.32)} "
        f"{f(cx - sx * r * 0.06)} {f(cy + r * 0.06)} "
        f"{f(cx)} {f(cy - r * 0.20)}Z"
    )
    return (
        lit(shell, skin, -r * 0.02, -r * 0.02, 0.86)
        + f'<path d="M{f(cx + sx * r * 0.03)} {f(cy - r * 0.10)}'
          f'C{f(cx + sx * r * 0.13)} {f(cy - r * 0.10)} '
          f'{f(cx + sx * r * 0.12)} {f(cy + r * 0.10)} '
          f'{f(cx + sx * r * 0.03)} {f(cy + r * 0.15)}" fill="none" '
          f'stroke="{shade(skin, 0.74)}" stroke-width="{f(lw * 1.2)}" '
          f'opacity="0.75"/>'
    )


def _kundala(cx: float, cy: float, r: float, gold: str = GOLD) -> str:
    """Makara kundala: a ring with a jewelled drop."""
    return (
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.46)}" fill="none" '
        f'stroke="{shade(gold, 0.78)}" stroke-width="{f(r * 0.30)}"/>'
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.44)}" fill="none" '
        f'stroke="{gold}" stroke-width="{f(r * 0.20)}"/>'
        + lit(
            f"M{f(cx)} {f(cy + r * 0.34)}"
            f"C{f(cx + r * 0.50)} {f(cy + r * 0.62)} {f(cx + r * 0.32)} "
            f"{f(cy + r * 1.24)} {f(cx)} {f(cy + r * 1.34)}"
            f"C{f(cx - r * 0.32)} {f(cy + r * 1.24)} {f(cx - r * 0.50)} "
            f"{f(cy + r * 0.62)} {f(cx)} {f(cy + r * 0.34)}Z",
            gold, -r * 0.05, -r * 0.04, 0.76,
        )
        + _jewel(cx, cy + r * 0.86, r * 0.22)
    )


def _tilak(cx: float, cy: float, r: float, color: str = TERRA) -> str:
    """Urdhva pundra: a slim flame of sandal paste, with a bindu."""
    return (
        f'<path d="M{f(cx)} {f(cy - r * 0.10)}'
        f'C{f(cx + r * 0.26)} {f(cy + r * 0.32)} {f(cx + r * 0.16)} '
        f'{f(cy + r * 0.76)} {f(cx)} {f(cy + r * 0.94)}'
        f'C{f(cx - r * 0.16)} {f(cy + r * 0.76)} {f(cx - r * 0.26)} '
        f'{f(cy + r * 0.32)} {f(cx)} {f(cy - r * 0.10)}Z" fill="{color}"/>'
        f'<circle cx="{f(cx)}" cy="{f(cy + r * 0.30)}" r="{f(r * 0.12)}" '
        f'fill="{tint(color, 1.5)}" opacity="0.5"/>'
    )


def _head_human(cx: float, cy: float, r: float, skin: str, lw: float,
                variant: str = "human") -> str:
    """Oval face with a jaw, modelled features, and hair that frames it."""
    face = (
        f"M{f(cx)} {f(cy - r * 0.98)}"
        f"C{f(cx + r * 0.60)} {f(cy - r * 0.98)} {f(cx + r * 0.90)} "
        f"{f(cy - r * 0.52)} {f(cx + r * 0.88)} {f(cy - r * 0.02)}"
        f"C{f(cx + r * 0.86)} {f(cy + r * 0.44)} {f(cx + r * 0.52)} "
        f"{f(cy + r * 0.96)} {f(cx)} {f(cy + r * 1.06)}"
        f"C{f(cx - r * 0.52)} {f(cy + r * 0.96)} {f(cx - r * 0.86)} "
        f"{f(cy + r * 0.44)} {f(cx - r * 0.88)} {f(cy - r * 0.02)}"
        f"C{f(cx - r * 0.90)} {f(cy - r * 0.52)} {f(cx - r * 0.60)} "
        f"{f(cy - r * 0.98)} {f(cx)} {f(cy - r * 0.98)}Z"
    )
    # the hair sits high off the brow: a low hairline is what read as a band
    hair = (
        f"M{f(cx - r * 0.92)} {f(cy - r * 0.06)}"
        f"C{f(cx - r * 1.02)} {f(cy - r * 0.72)} {f(cx - r * 0.60)} "
        f"{f(cy - r * 1.24)} {f(cx)} {f(cy - r * 1.24)}"
        f"C{f(cx + r * 0.60)} {f(cy - r * 1.24)} {f(cx + r * 1.02)} "
        f"{f(cy - r * 0.72)} {f(cx + r * 0.92)} {f(cy - r * 0.06)}"
        f"C{f(cx + r * 0.86)} {f(cy - r * 0.42)} {f(cx + r * 0.58)} "
        f"{f(cy - r * 0.68)} {f(cx + r * 0.30)} {f(cy - r * 0.72)}"
        f"C{f(cx + r * 0.12)} {f(cy - r * 0.74)} {f(cx + r * 0.06)} "
        f"{f(cy - r * 0.66)} {f(cx)} {f(cy - r * 0.64)}"
        f"C{f(cx - r * 0.06)} {f(cy - r * 0.66)} {f(cx - r * 0.12)} "
        f"{f(cy - r * 0.74)} {f(cx - r * 0.30)} {f(cy - r * 0.72)}"
        f"C{f(cx - r * 0.58)} {f(cy - r * 0.68)} {f(cx - r * 0.86)} "
        f"{f(cy - r * 0.42)} {f(cx - r * 0.92)} {f(cy - r * 0.06)}Z"
    )
    parts = [
        # hair mass behind the head
        f'<path d="M{f(cx)} {f(cy - r * 1.22)}'
        f'C{f(cx + r * 0.78)} {f(cy - r * 1.22)} {f(cx + r * 1.02)} '
        f'{f(cy - r * 0.42)} {f(cx + r * 0.94)} {f(cy + r * 0.26)}'
        f'C{f(cx + r * 0.50)} {f(cy + r * 0.06)} {f(cx - r * 0.50)} '
        f'{f(cy + r * 0.06)} {f(cx - r * 0.94)} {f(cy + r * 0.26)}'
        f'C{f(cx - r * 1.02)} {f(cy - r * 0.42)} {f(cx - r * 0.78)} '
        f'{f(cy - r * 1.22)} {f(cx)} {f(cy - r * 1.22)}Z" '
        f'fill="{shade(INK, 0.74)}"/>',
        _ear(cx - r * 0.86, cy + r * 0.06, r, -1, skin, lw),
        _ear(cx + r * 0.86, cy + r * 0.06, r, 1, skin, lw),
        lit(face, skin, -r * 0.045, -r * 0.035, 0.86),
        # the shaded cheek and jaw on the far side of the light
        f'<path d="M{f(cx + r * 0.84)} {f(cy - r * 0.06)}'
        f'C{f(cx + r * 0.80)} {f(cy + r * 0.40)} {f(cx + r * 0.50)} '
        f'{f(cy + r * 0.86)} {f(cx + r * 0.06)} {f(cy + r * 1.02)}'
        f'C{f(cx + r * 0.46)} {f(cy + r * 0.78)} {f(cx + r * 0.68)} '
        f'{f(cy + r * 0.40)} {f(cx + r * 0.72)} {f(cy - r * 0.04)}Z" '
        f'fill="{shade(skin, 0.88)}" opacity="0.75"/>',
        f'<ellipse cx="{f(cx - r * 0.52)}" cy="{f(cy + r * 0.34)}" '
        f'rx="{f(r * 0.20)}" ry="{f(r * 0.12)}" fill="{TERRA}" '
        f'opacity="0.10"/>',
        f'<ellipse cx="{f(cx + r * 0.52)}" cy="{f(cy + r * 0.34)}" '
        f'rx="{f(r * 0.20)}" ry="{f(r * 0.12)}" fill="{TERRA}" '
        f'opacity="0.10"/>',
        f'<path d="{hair}" fill="{INK}"/>',
        # a sheen following the hairline
        f'<path d="M{f(cx - r * 0.74)} {f(cy - r * 0.50)}'
        f'C{f(cx - r * 0.56)} {f(cy - r * 0.86)} {f(cx - r * 0.24)} '
        f'{f(cy - r * 1.02)} {f(cx)} {f(cy - r * 1.02)}" fill="none" '
        f'stroke="{tint(INK, 1.35)}" stroke-width="{f(r * 0.052)}" '
        f'opacity="0.4" stroke-linecap="round"/>',
        _ol(face, lw * 0.9, 0.13),
        _eye(cx - r * 0.38, cy + r * 0.02, r, lw),
        _eye(cx + r * 0.38, cy + r * 0.02, r, lw),
        _brow(cx - r * 0.38, cy - r * 0.24, r, -1),
        _brow(cx + r * 0.38, cy - r * 0.24, r, 1),
        _nose(cx, cy + r * 0.10, r, skin),
        _mouth(cx, cy + r * 0.62, r),
        f'<path d="M{f(cx - r * 0.10)} {f(cy + r * 0.80)}'
        f'q{f(r * 0.10)} {f(r * 0.05)} {f(r * 0.20)} 0" fill="none" '
        f'stroke="{shade(skin, 0.82)}" stroke-width="{f(lw * 1.1)}" '
        f'opacity="0.55" stroke-linecap="round"/>',
        _kundala(cx - r * 0.90, cy + r * 0.34, r * 0.30),
        _kundala(cx + r * 0.90, cy + r * 0.34, r * 0.30),
    ]
    if variant == "devi":
        parts.insert(1, (
            # bun above the parting, long locks falling beside the neck
            f'<circle cx="{f(cx)}" cy="{f(cy - r * 1.24)}" '
            f'r="{f(r * 0.40)}" fill="{shade(INK, 0.82)}"/>'
            f'<path d="M{f(cx - r * 0.90)} {f(cy - r * 0.20)}'
            f'C{f(cx - r * 1.14)} {f(cy + r * 0.40)} {f(cx - r * 1.02)} '
            f'{f(cy + r * 1.10)} {f(cx - r * 0.78)} {f(cy + r * 1.42)}'
            f'C{f(cx - r * 0.56)} {f(cy + r * 1.10)} {f(cx - r * 0.60)} '
            f'{f(cy + r * 0.40)} {f(cx - r * 0.68)} {f(cy - r * 0.10)}Z" '
            f'fill="{INK}"/>'
            f'<path d="M{f(cx + r * 0.90)} {f(cy - r * 0.20)}'
            f'C{f(cx + r * 1.14)} {f(cy + r * 0.40)} {f(cx + r * 1.02)} '
            f'{f(cy + r * 1.10)} {f(cx + r * 0.78)} {f(cy + r * 1.42)}'
            f'C{f(cx + r * 0.56)} {f(cy + r * 1.10)} {f(cx + r * 0.60)} '
            f'{f(cy + r * 0.40)} {f(cx + r * 0.68)} {f(cy - r * 0.10)}Z" '
            f'fill="{INK}"/>'
        ))
        parts.append(
            f'<path d="M{f(cx)} {f(cy - r * 1.00)}v{f(r * 0.30)}" '
            f'stroke="{tint(INK, 1.4)}" stroke-width="{f(r * 0.032)}" '
            f'opacity="0.55"/>'
            + _jewel(cx, cy - r * 0.90, r * 0.10, TERRA)
            + f'<circle cx="{f(cx)}" cy="{f(cy - r * 0.36)}" '
              f'r="{f(r * 0.070)}" fill="{TERRA}"/>'
              f'<circle cx="{f(cx - r * 0.21)}" cy="{f(cy + r * 0.28)}" '
              f'r="{f(r * 0.080)}" fill="none" stroke="{GOLD}" '
              f'stroke-width="{f(r * 0.038)}"/>'
        )
    else:
        parts.append(_tilak(cx, cy - r * 0.58, r * 0.28))
    return "".join(parts)


def _head_elephant(cx: float, cy: float, r: float, skin: str,
                   lw: float) -> str:
    """Gajamukha: domed skull, fanned ears, eyes. No trunk -- that is a
    separate late layer, because the necklace and sash are drawn after the head
    and were cutting the trunk off at the chin. See _gajamukha_front()."""
    R = r * 1.22
    d = shade(skin, 0.80)
    ear = (
        f"M{f(cx - R * 0.62)} {f(cy - R * 0.54)}"
        f"C{f(cx - R * 1.30)} {f(cy - R * 0.88)} {f(cx - R * 1.82)} "
        f"{f(cy - R * 0.16)} {f(cx - R * 1.56)} {f(cy + R * 0.56)}"
        f"C{f(cx - R * 1.38)} {f(cy + R * 1.04)} {f(cx - R * 0.84)} "
        f"{f(cy + R * 1.00)} {f(cx - R * 0.56)} {f(cy + R * 0.64)}Z"
    )
    inner = (
        f"M{f(cx - R * 0.66)} {f(cy - R * 0.30)}"
        f"C{f(cx - R * 1.14)} {f(cy - R * 0.54)} {f(cx - R * 1.48)} "
        f"{f(cy - R * 0.04)} {f(cx - R * 1.30)} {f(cy + R * 0.48)}"
        f"C{f(cx - R * 1.16)} {f(cy + R * 0.80)} {f(cx - R * 0.84)} "
        f"{f(cy + R * 0.76)} {f(cx - R * 0.62)} {f(cy + R * 0.50)}Z"
    )
    skull = (
        f"M{f(cx)} {f(cy - R * 1.06)}"
        f"C{f(cx + R * 0.72)} {f(cy - R * 1.06)} {f(cx + R * 1.00)} "
        f"{f(cy - R * 0.48)} {f(cx + R * 0.96)} {f(cy + R * 0.08)}"
        f"C{f(cx + R * 0.92)} {f(cy + R * 0.48)} {f(cx + R * 0.60)} "
        f"{f(cy + R * 0.80)} {f(cx + R * 0.34)} {f(cy + R * 0.86)}"
        f"L{f(cx - R * 0.34)} {f(cy + R * 0.86)}"
        f"C{f(cx - R * 0.60)} {f(cy + R * 0.80)} {f(cx - R * 0.92)} "
        f"{f(cy + R * 0.48)} {f(cx - R * 0.96)} {f(cy + R * 0.08)}"
        f"C{f(cx - R * 1.00)} {f(cy - R * 0.48)} {f(cx - R * 0.72)} "
        f"{f(cy - R * 1.06)} {f(cx)} {f(cy - R * 1.06)}Z"
    )
    ear_art = (
        lit(ear, shade(skin, 0.86), -R * 0.03, -R * 0.03, 0.84)
        # the canal is the darkest thing on the head; without that the ear was
        # a pale cloud the same value as the cheek
        + f'<path d="{inner}" fill="{shade(skin, 0.72)}" opacity="0.9"/>'
        + f'<path d="{inner}" fill="none" stroke="{shade(skin, 0.58)}" '
          f'stroke-width="{f(lw * 1.6)}" opacity="0.55"/>'
        + f'<path d="{ear}" fill="none" stroke="{shade(GOLD, 0.72)}" '
          f'stroke-width="{f(R * 0.062)}" opacity="0.95"/>'
          f'<path d="{ear}" fill="none" stroke="{GOLD}" '
          f'stroke-width="{f(R * 0.034)}" opacity="1"/>'
          f'<path d="{ear}" fill="none" stroke="{GOLD_PALE}" '
          f'stroke-width="{f(R * 0.012)}" opacity="0.8"/>'
    )
    return (
        ear_art
        + f'<g transform="scale(-1 1) translate({f(-2 * cx)} 0)">'
        + ear_art + "</g>"
        + lit(skull, skin, -R * 0.04, -R * 0.03, 0.86)
        # brow dome catching the light, and the shaded far cheek
        + f'<path d="M{f(cx - R * 0.72)} {f(cy - R * 0.28)}'
          f'C{f(cx - R * 0.60)} {f(cy - R * 0.88)} {f(cx + R * 0.60)} '
          f'{f(cy - R * 0.88)} {f(cx + R * 0.72)} {f(cy - R * 0.28)}'
          f'C{f(cx + R * 0.40)} {f(cy - R * 0.50)} {f(cx - R * 0.40)} '
          f'{f(cy - R * 0.50)} {f(cx - R * 0.72)} {f(cy - R * 0.28)}Z" '
          f'fill="{tint(skin, 1.12)}" opacity="0.6"/>'
        + f'<path d="M{f(cx + R * 0.92)} {f(cy - R * 0.08)}'
          f'C{f(cx + R * 0.88)} {f(cy + R * 0.40)} {f(cx + R * 0.60)} '
          f'{f(cy + R * 0.78)} {f(cx + R * 0.34)} {f(cy + R * 0.86)}'
          f'C{f(cx + R * 0.62)} {f(cy + R * 0.62)} {f(cx + R * 0.76)} '
          f'{f(cy + R * 0.30)} {f(cx + R * 0.78)} {f(cy - R * 0.06)}Z" '
          f'fill="{d}" opacity="0.5"/>'
        # trunk and tusks are NOT drawn here -- see _gajamukha_front()
        + _eye(cx - R * 0.40, cy + R * 0.06, R * 0.84, lw)
        + _eye(cx + R * 0.40, cy + R * 0.06, R * 0.84, lw)
        + _brow(cx - R * 0.40, cy - R * 0.20, R * 0.84, -1)
        + _brow(cx + R * 0.40, cy - R * 0.20, R * 0.84, 1)
        + _tilak(cx, cy - R * 0.54, R * 0.26)
        + _kundala(cx - R * 1.30, cy + R * 0.70, R * 0.26)
        + _kundala(cx + R * 1.30, cy + R * 0.70, R * 0.26)
    )


def _gajamukha_front(cx: float, cy: float, r: float, skin: str,
                     lw: float) -> str:
    """The trunk and tusks, drawn over the necklace and sash.

    Split out of _head_elephant because seated_figure lays the ornament on
    after the head: drawn in place, the trunk was clipped at the chin by the
    haar and Ganesha read as a bald man. The wrinkle rings are placed by
    walking the same cubic the ribbon follows, so they always sit square across
    it however the curl is retuned.
    """
    R = r * 1.22
    p0 = (cx + R * 0.02, cy + R * 0.30)
    c1 = (cx - R * 0.30, cy + R * 1.00)
    c2 = (cx - R * 0.78, cy + R * 1.50)
    p3 = (cx - R * 0.06, cy + R * 1.74)
    w0, w1 = R * 0.46, R * 0.13

    def at(t: float) -> tuple[float, float, float, float, float]:
        u = 1.0 - t
        x = (u ** 3 * p0[0] + 3 * u * u * t * c1[0]
             + 3 * u * t * t * c2[0] + t ** 3 * p3[0])
        y = (u ** 3 * p0[1] + 3 * u * u * t * c1[1]
             + 3 * u * t * t * c2[1] + t ** 3 * p3[1])
        dx = (3 * u * u * (c1[0] - p0[0]) + 6 * u * t * (c2[0] - c1[0])
              + 3 * t * t * (p3[0] - c2[0]))
        dy = (3 * u * u * (c1[1] - p0[1]) + 6 * u * t * (c2[1] - c1[1])
              + 3 * t * t * (p3[1] - c2[1]))
        ln = math.hypot(dx, dy) or 1.0
        hw = (w0 + (w1 - w0) * t ** 0.9) / 2
        return x, y, -dy / ln, dx / ln, hw

    rings = []
    for t in (0.20, 0.36, 0.52, 0.68, 0.84):
        x, y, nx, ny, hw = at(t)
        # a shallow arc from one flank to the other, bowed along the trunk
        bx, by = -ny * hw * 0.42, nx * hw * 0.42
        rings.append(
            f'<path d="M{f(x - nx * hw * 0.86)} {f(y - ny * hw * 0.86)}'
            f'Q{f(x + bx)} {f(y + by)} '
            f'{f(x + nx * hw * 0.86)} {f(y + ny * hw * 0.86)}"/>'
        )
    # the tip flare, so the trunk ends in a lip rather than a stump
    tx, ty, tnx, tny, thw = at(1.0)
    return (
        _ribbon(p0, c1, c2, p3, w0, w1, skin, 0.82, 40, lw * 2.2)
        + f'<g fill="none" stroke="{shade(skin, 0.66)}" '
          f'stroke-width="{f(lw * 1.5)}" opacity="0.42" '
          f'stroke-linecap="round">' + "".join(rings) + "</g>"
        + f'<ellipse cx="{f(tx + tnx * thw * 0.30)}" '
          f'cy="{f(ty + tny * thw * 0.30)}" rx="{f(thw * 0.92)}" '
          f'ry="{f(thw * 0.62)}" fill="{shade(skin, 0.90)}" '
          f'transform="rotate(-24 {f(tx)} {f(ty)})"/>'
        # tusks, over the trunk: long, curving out and forward
        + "".join(
            lit(
                f"M{f(cx + sx * R * 0.30)} {f(cy + R * 0.60)}"
                f"C{f(cx + sx * R * 0.40)} {f(cy + R * 0.98)} "
                f"{f(cx + sx * R * 0.62)} {f(cy + R * 1.22)} "
                f"{f(cx + sx * R * 0.80)} {f(cy + R * 1.30)}"
                f"C{f(cx + sx * R * 0.62)} {f(cy + R * 1.08)} "
                f"{f(cx + sx * R * 0.54)} {f(cy + R * 0.84)} "
                f"{f(cx + sx * R * 0.52)} {f(cy + R * 0.58)}Z",
                CREAM, -R * 0.018, -R * 0.018, 0.86,
            )
            for sx in (-1, 1)
        )
        # a gold cap on the left tusk -- the traditional dressing of Ekadanta
        + f'<path d="M{f(cx - R * 0.33)} {f(cy + R * 0.70)}'
          f'Q{f(cx - R * 0.42)} {f(cy + R * 0.76)} {f(cx - R * 0.53)} '
          f'{f(cy + R * 0.70)}" fill="none" stroke="{GOLD}" '
          f'stroke-width="{f(R * 0.048)}" stroke-linecap="round"/>'
    )


def _head_vanara(cx: float, cy: float, r: float, lw: float) -> str:
    """Hanuman: a sindoor-red vanara face, resolute, not grinning."""
    face, muzzle = "#D0561F", "#EDA070"
    skull = (
        f"M{f(cx)} {f(cy - r * 1.00)}"
        f"C{f(cx + r * 0.70)} {f(cy - r * 1.00)} {f(cx + r * 0.98)} "
        f"{f(cy - r * 0.44)} {f(cx + r * 0.92)} {f(cy + r * 0.10)}"
        f"C{f(cx + r * 0.86)} {f(cy + r * 0.62)} {f(cx + r * 0.48)} "
        f"{f(cy + r * 0.98)} {f(cx)} {f(cy + r * 1.02)}"
        f"C{f(cx - r * 0.48)} {f(cy + r * 0.98)} {f(cx - r * 0.86)} "
        f"{f(cy + r * 0.62)} {f(cx - r * 0.92)} {f(cy + r * 0.10)}"
        f"C{f(cx - r * 0.98)} {f(cy - r * 0.44)} {f(cx - r * 0.70)} "
        f"{f(cy - r * 1.00)} {f(cx)} {f(cy - r * 1.00)}Z"
    )
    return (
        "".join(  # ears
            "<g>"
            + lit(
                f"M{f(cx + sx * r * 0.86)} {f(cy - r * 0.30)}"
                f"C{f(cx + sx * r * 1.26)} {f(cy - r * 0.34)} "
                f"{f(cx + sx * r * 1.32)} {f(cy + r * 0.28)} "
                f"{f(cx + sx * r * 0.94)} {f(cy + r * 0.32)}Z",
                face, -r * 0.03, -r * 0.03, 0.84,
            )
            + f'<path d="M{f(cx + sx * r * 0.94)} {f(cy - r * 0.18)}'
              f'C{f(cx + sx * r * 1.14)} {f(cy - r * 0.18)} '
              f'{f(cx + sx * r * 1.16)} {f(cy + r * 0.14)} '
              f'{f(cx + sx * r * 0.98)} {f(cy + r * 0.18)}" fill="none" '
              f'stroke="{muzzle}" stroke-width="{f(lw * 1.6)}" '
              f'opacity="0.75"/></g>'
            for sx in (-1, 1)
        )
        + lit(skull, face, -r * 0.04, -r * 0.03, 0.84)
        # brow ridge
        + f'<path d="M{f(cx - r * 0.80)} {f(cy - r * 0.16)}'
          f'C{f(cx - r * 0.56)} {f(cy - r * 0.64)} {f(cx + r * 0.56)} '
          f'{f(cy - r * 0.64)} {f(cx + r * 0.80)} {f(cy - r * 0.16)}'
          f'C{f(cx + r * 0.50)} {f(cy - r * 0.40)} {f(cx - r * 0.50)} '
          f'{f(cy - r * 0.40)} {f(cx - r * 0.80)} {f(cy - r * 0.16)}Z" '
          f'fill="{shade(face, 0.80)}"/>'
        # cheek fur tufts
        + "".join(
            f'<path d="M{f(cx + sx * r * 0.66)} {f(cy + r * 0.16)}'
            f'l{f(sx * r * 0.26)} {f(-r * 0.08)}'
            f'l{f(-sx * r * 0.06)} {f(r * 0.18)}'
            f'l{f(sx * r * 0.22)} {f(r * 0.02)}'
            f'l{f(-sx * r * 0.14)} {f(r * 0.18)}Z" '
            f'fill="{tint(face, 1.14)}" opacity="0.6"/>'
            for sx in (-1, 1)
        )
        # muzzle
        + lit(
            f"M{f(cx - r * 0.62)} {f(cy + r * 0.34)}"
            f"C{f(cx - r * 0.68)} {f(cy + r * 0.76)} {f(cx - r * 0.34)} "
            f"{f(cy + r * 0.98)} {f(cx)} {f(cy + r * 0.98)}"
            f"C{f(cx + r * 0.34)} {f(cy + r * 0.98)} {f(cx + r * 0.68)} "
            f"{f(cy + r * 0.76)} {f(cx + r * 0.62)} {f(cy + r * 0.34)}"
            f"C{f(cx + r * 0.34)} {f(cy + r * 0.18)} {f(cx - r * 0.34)} "
            f"{f(cy + r * 0.18)} {f(cx - r * 0.62)} {f(cy + r * 0.34)}Z",
            muzzle, -r * 0.03, -r * 0.03, 0.86,
        )
        + _eye(cx - r * 0.34, cy - r * 0.02, r * 0.90, lw)
        + _eye(cx + r * 0.34, cy - r * 0.02, r * 0.90, lw)
        + _brow(cx - r * 0.36, cy - r * 0.28, r * 0.90, -1)
        + _brow(cx + r * 0.36, cy - r * 0.28, r * 0.90, 1)
        # nostrils, a level mouth
        + f'<g fill="{shade(muzzle, 0.55)}">'
          f'<ellipse cx="{f(cx - r * 0.15)}" cy="{f(cy + r * 0.42)}" '
          f'rx="{f(r * 0.066)}" ry="{f(r * 0.044)}"/>'
          f'<ellipse cx="{f(cx + r * 0.15)}" cy="{f(cy + r * 0.42)}" '
          f'rx="{f(r * 0.066)}" ry="{f(r * 0.044)}"/>'
          f"</g>"
          f'<path d="M{f(cx - r * 0.28)} {f(cy + r * 0.72)}'
          f'q{f(r * 0.28)} {f(r * 0.09)} {f(r * 0.56)} 0" fill="none" '
          f'stroke="{shade(muzzle, 0.50)}" stroke-width="{f(r * 0.050)}" '
          f'stroke-linecap="round"/>'
          f'<path d="M{f(cx)} {f(cy + r * 0.50)}v{f(r * 0.22)}" fill="none" '
          f'stroke="{shade(muzzle, 0.62)}" stroke-width="{f(r * 0.028)}" '
          f'opacity="0.65"/>'
        + _kundala(cx - r * 1.08, cy + r * 0.46, r * 0.26)
        + _kundala(cx + r * 1.08, cy + r * 0.46, r * 0.26)
        + _tilak(cx, cy - r * 0.72, r * 0.26, CREAM)
    )


def _mukut(cx: float, tip: float, base: float, r: float, color: str,
           lw: float) -> str:
    """Kirita mukuta in three courses: jewelled patta, lobed tier, tall dome.

    `tip` is the top of the finial and `base` the line where it meets the brow,
    so a taller head just gets a taller crown without new numbers.
    """
    ch = base - tip
    w = r * 2.02
    dk, hi = shade(color, 0.78), tint(color, 1.34)

    dome = (
        f"M{f(cx - w * 0.42)} {f(base - ch * 0.02)}"
        f"C{f(cx - w * 0.44)} {f(tip + ch * 0.52)} {f(cx - w * 0.28)} "
        f"{f(tip + ch * 0.30)} {f(cx - w * 0.18)} {f(tip + ch * 0.25)}"
        f"C{f(cx - w * 0.14)} {f(tip + ch * 0.15)} {f(cx - w * 0.07)} "
        f"{f(tip + ch * 0.13)} {f(cx)} {f(tip + ch * 0.10)}"
        f"C{f(cx + w * 0.07)} {f(tip + ch * 0.13)} {f(cx + w * 0.14)} "
        f"{f(tip + ch * 0.15)} {f(cx + w * 0.18)} {f(tip + ch * 0.25)}"
        f"C{f(cx + w * 0.28)} {f(tip + ch * 0.30)} {f(cx + w * 0.44)} "
        f"{f(tip + ch * 0.52)} {f(cx + w * 0.42)} {f(base - ch * 0.02)}Z"
    )
    lobes = [
        f"M{f(cx + w * 0.185 * k - w * 0.095)} {f(base - ch * 0.10)}"
        f"C{f(cx + w * 0.185 * k - w * 0.095)} {f(base - ch * 0.42)} "
        f"{f(cx + w * 0.185 * k + w * 0.095)} {f(base - ch * 0.42)} "
        f"{f(cx + w * 0.185 * k + w * 0.095)} {f(base - ch * 0.10)}Z"
        for k in (-2, -1, 0, 1, 2)
    ]
    return (
        # side ribbons, behind everything
        "".join(
            lit(
                f"M{f(cx + sx * w * 0.42)} {f(base - ch * 0.10)}"
                f"C{f(cx + sx * w * 0.68)} {f(base + ch * 0.06)} "
                f"{f(cx + sx * w * 0.60)} {f(base + ch * 0.44)} "
                f"{f(cx + sx * w * 0.40)} {f(base + ch * 0.56)}"
                f"C{f(cx + sx * w * 0.48)} {f(base + ch * 0.28)} "
                f"{f(cx + sx * w * 0.48)} {f(base + ch * 0.06)} "
                f"{f(cx + sx * w * 0.34)} {f(base - ch * 0.06)}Z",
                color, -ch * 0.02, -ch * 0.02, 0.74,
            )
            for sx in (-1, 1)
        )
        + lit(dome, color, -ch * 0.022, -ch * 0.018, 0.76)
        # ribs on the dome, and one lit edge
        + f'<g fill="none" stroke="{dk}" stroke-width="{f(ch * 0.020)}" '
          f'opacity="0.6">'
          f'<path d="M{f(cx - w * 0.15)} {f(base - ch * 0.06)}'
          f'C{f(cx - w * 0.19)} {f(tip + ch * 0.46)} {f(cx - w * 0.10)} '
          f'{f(tip + ch * 0.26)} {f(cx - w * 0.05)} {f(tip + ch * 0.16)}"/>'
          f'<path d="M{f(cx + w * 0.15)} {f(base - ch * 0.06)}'
          f'C{f(cx + w * 0.19)} {f(tip + ch * 0.46)} {f(cx + w * 0.10)} '
          f'{f(tip + ch * 0.26)} {f(cx + w * 0.05)} {f(tip + ch * 0.16)}"/>'
          f"</g>"
          f'<path d="M{f(cx - w * 0.29)} {f(base - ch * 0.08)}'
          f'C{f(cx - w * 0.31)} {f(tip + ch * 0.54)} {f(cx - w * 0.19)} '
          f'{f(tip + ch * 0.34)} {f(cx - w * 0.12)} {f(tip + ch * 0.22)}" '
          f'fill="none" stroke="{hi}" stroke-width="{f(ch * 0.018)}" '
          f'opacity="0.6"/>'
        # lobed course
        + "".join(
            f'<path d="{d}" fill="{dk}"/>'
            f'<g transform="translate({f(-ch * 0.013)} {f(-ch * 0.013)})">'
            f'<path d="{d}" fill="{color}"/></g>'
            for d in lobes
        )
        # forehead band (patta)
        + rrect(cx - w * 0.55, base - ch * 0.11, w * 1.10, ch * 0.23,
                ch * 0.07, dk)
        + rrect(cx - w * 0.545, base - ch * 0.11, w * 1.09, ch * 0.18,
                ch * 0.06, color)
        + f'<path d="M{f(cx - w * 0.52)} {f(base - ch * 0.072)}'
          f'h{f(w * 1.04)}" stroke="{hi}" stroke-width="{f(ch * 0.018)}" '
          f'opacity="0.55"/>'
        + "".join(
            _jewel(cx + w * 0.212 * k, base - ch * 0.012,
                   ch * (0.058 if k else 0.074))
            for k in (-2, -1, 0, 1, 2)
        )
        # beaded lower edge
        + f'<path d="M{f(cx - w * 0.51)} {f(base + ch * 0.078)}'
          f'h{f(w * 1.02)}" stroke="{GOLD_PALE}" '
          f'stroke-width="{f(ch * 0.034)}" stroke-linecap="round" '
          f'stroke-dasharray="{f(ch * 0.004)} {f(ch * 0.055)}"/>'
        # central jewel, then the kalasha finial
        + _jewel(cx, tip + ch * 0.44, ch * 0.100, TERRA)
        + lit(
            f"M{f(cx - ch * 0.072)} {f(tip + ch * 0.135)}"
            f"C{f(cx - ch * 0.072)} {f(tip + ch * 0.030)} "
            f"{f(cx + ch * 0.072)} {f(tip + ch * 0.030)} "
            f"{f(cx + ch * 0.072)} {f(tip + ch * 0.135)}Z",
            color, -ch * 0.012, -ch * 0.010, 0.76,
        )
        + f'<circle cx="{f(cx)}" cy="{f(tip + ch * 0.030)}" '
          f'r="{f(ch * 0.048)}" fill="{GOLD_PALE}"/>'
          f'<circle cx="{f(cx - ch * 0.013)}" cy="{f(tip + ch * 0.018)}" '
          f'r="{f(ch * 0.018)}" fill="{CREAM}" opacity="0.8"/>'
    )


def _jata(cx: float, cy: float, r: float, lw: float) -> str:
    """Matted hair piled high, bound in gold, with moon and Ganga -- Shiva."""
    pile = (
        f"M{f(cx - r * 1.02)} {f(cy - r * 0.60)}"
        f"C{f(cx - r * 1.26)} {f(cy - r * 1.46)} {f(cx - r * 0.74)} "
        f"{f(cy - r * 2.20)} {f(cx)} {f(cy - r * 2.24)}"
        f"C{f(cx + r * 0.74)} {f(cy - r * 2.20)} {f(cx + r * 1.26)} "
        f"{f(cy - r * 1.46)} {f(cx + r * 1.02)} {f(cy - r * 0.60)}"
        f"C{f(cx + r * 0.50)} {f(cy - r * 1.00)} {f(cx - r * 0.50)} "
        f"{f(cy - r * 1.00)} {f(cx - r * 1.02)} {f(cy - r * 0.60)}Z"
    )
    coil = "#6E4A34"
    moon = (
        f"M{f(cx - r * 0.66)} {f(cy - r * 2.04)}"
        f"a{f(r * 0.44)} {f(r * 0.44)} 0 1 0 {f(r * 0.46)} {f(r * 0.26)}"
        f"a{f(r * 0.34)} {f(r * 0.34)} 0 1 1 {f(-r * 0.46)} {f(-r * 0.26)}z"
    )
    ganga = (
        f"M{f(cx + r * 0.36)} {f(cy - r * 2.04)}"
        f"C{f(cx + r * 0.80)} {f(cy - r * 1.78)} {f(cx + r * 0.64)} "
        f"{f(cy - r * 1.30)} {f(cx + r * 0.30)} {f(cy - r * 1.16)}"
    )
    return (
        lit(pile, coil, -r * 0.04, -r * 0.04, 0.72)
        + f'<g fill="none" stroke="{tint(coil, 1.22)}" '
          f'stroke-width="{f(r * 0.066)}" stroke-linecap="round" '
          f'opacity="0.7">'
          f'<path d="M{f(cx - r * 0.74)} {f(cy - r * 0.84)}'
          f'C{f(cx - r * 0.96)} {f(cy - r * 1.44)} {f(cx - r * 0.50)} '
          f'{f(cy - r * 1.86)} {f(cx - r * 0.14)} {f(cy - r * 1.92)}"/>'
          f'<path d="M{f(cx + r * 0.74)} {f(cy - r * 0.84)}'
          f'C{f(cx + r * 0.96)} {f(cy - r * 1.44)} {f(cx + r * 0.50)} '
          f'{f(cy - r * 1.86)} {f(cx + r * 0.14)} {f(cy - r * 1.92)}"/>'
          f'<path d="M{f(cx - r * 0.34)} {f(cy - r * 1.04)}'
          f'C{f(cx - r * 0.14)} {f(cy - r * 1.42)} {f(cx + r * 0.20)} '
          f'{f(cy - r * 1.42)} {f(cx + r * 0.36)} {f(cy - r * 1.06)}"/>'
          f'<path d="M{f(cx - r * 0.52)} {f(cy - r * 1.62)}'
          f'C{f(cx - r * 0.24)} {f(cy - r * 1.84)} {f(cx + r * 0.24)} '
          f'{f(cy - r * 1.84)} {f(cx + r * 0.52)} {f(cy - r * 1.62)}"/>'
          f"</g>"
        # gold fillet binding the pile
        + f'<path d="M{f(cx - r * 0.96)} {f(cy - r * 0.74)}'
          f'C{f(cx - r * 0.50)} {f(cy - r * 1.04)} {f(cx + r * 0.50)} '
          f'{f(cy - r * 1.04)} {f(cx + r * 0.96)} {f(cy - r * 0.74)}" '
          f'fill="none" stroke="{shade(GOLD, 0.8)}" '
          f'stroke-width="{f(r * 0.086)}"/>'
          f'<path d="M{f(cx - r * 0.96)} {f(cy - r * 0.76)}'
          f'C{f(cx - r * 0.50)} {f(cy - r * 1.06)} {f(cx + r * 0.50)} '
          f'{f(cy - r * 1.06)} {f(cx + r * 0.96)} {f(cy - r * 0.76)}" '
          f'fill="none" stroke="{GOLD}" stroke-width="{f(r * 0.054)}"/>'
        + _jewel(cx, cy - r * 0.96, r * 0.13)
        + f'<path d="{moon}" fill="{CREAM}"/>'
          f'<path d="{moon}" fill="none" stroke="{GOLD_PALE}" '
          f'stroke-width="{f(r * 0.028)}" opacity="0.8"/>'
        + f'<path d="{ganga}" fill="none" stroke="{TEAL}" '
          f'stroke-width="{f(r * 0.096)}" stroke-linecap="round"/>'
          f'<path d="{ganga}" fill="none" stroke="{CREAM}" '
          f'stroke-width="{f(r * 0.030)}" opacity="0.65" '
          f'stroke-linecap="round"/>'
        # third eye and the three lines of vibhuti
        + f'<path d="M{f(cx - r * 0.19)} {f(cy - r * 0.56)}'
          f'q{f(r * 0.19)} {f(-r * 0.12)} {f(r * 0.38)} 0'
          f'q{f(-r * 0.19)} {f(r * 0.12)} {f(-r * 0.38)} 0z" '
          f'fill="{TERRA}"/>'
          f'<g stroke="{CREAM}" stroke-linecap="round">'
          f'<path d="M{f(cx - r * 0.44)} {f(cy - r * 0.42)}h{f(r * 0.88)}" '
          f'stroke-width="{f(r * 0.048)}" opacity="0.9"/>'
          f'<path d="M{f(cx - r * 0.40)} {f(cy - r * 0.30)}h{f(r * 0.80)}" '
          f'stroke-width="{f(r * 0.036)}" opacity="0.7"/>'
          f"</g>"
        # rudraksha at the throat
        + _beads(
            f"M{f(cx - r * 0.72)} {f(cy + r * 1.12)}"
            f"Q{f(cx)} {f(cy + r * 1.62)} {f(cx + r * 0.72)} "
            f"{f(cy + r * 1.12)}",
            "#5A3A28", "#8A5636", r * 0.05, r * 0.17, r * 0.23,
        )
    )


# ------------------------------------------------------------- the plinth --


def _petal_row(x0: float, x1: float, y: float, n: int, bulge: float,
               up: bool, depth: float, fill: str, lw: float) -> str:
    """A padma-pitha course: n lobes along x0..x1, bulging up or down.

    Each lobe is modelled -- a shaded seam on its right, a lit crown on its
    left -- so the course reads as carved stone rather than a scalloped strip.
    """
    rx = (x1 - x0) / (2 * n)
    sweep = 1 if up else 0
    arcs = "".join(
        f"a{f(rx)} {f(bulge)} 0 0 {sweep} {f(2 * rx)} 0" for _ in range(n)
    )
    dep = depth if up else -depth
    d = f"M{f(x0)} {f(y)}{arcs}L{f(x1)} {f(y + dep)}L{f(x0)} {f(y + dep)}Z"
    lobes = []
    for k in range(n):
        lx = x0 + 2 * rx * k
        # the shaded flank of each petal, on the side away from the light
        lobes.append(
            f'<path d="M{f(lx + rx * 1.00)} {f(y - (bulge if up else 0))}'
            f'C{f(lx + rx * 1.62)} {f(y - (bulge * 0.62 if up else 0))} '
            f'{f(lx + rx * 2.00)} {f(y + dep * 0.30)} '
            f'{f(lx + rx * 2.00)} {f(y + dep * 0.92)}'
            f'L{f(lx + rx * 1.30)} {f(y + dep * 0.92)}Z" '
            f'fill="{shade(fill, 0.88)}" opacity="0.85"/>'
        )
        lobes.append(
            f'<path d="M{f(lx + rx * 0.22)} {f(y + dep * 0.10)}'
            f'C{f(lx + rx * 0.42)} {f(y - (bulge * 0.72 if up else 0))} '
            f'{f(lx + rx * 0.80)} {f(y - (bulge * 0.86 if up else 0))} '
            f'{f(lx + rx * 1.02)} {f(y - (bulge * 0.94 if up else 0))}" '
            f'fill="none" stroke="{tint(fill, 1.20)}" '
            f'stroke-width="{f(lw * 1.6)}" opacity="0.7" '
            f'stroke-linecap="round"/>'
        )
    seams = "".join(
        f'<path d="M{f(x0 + 2 * rx * (k + 1))} {f(y)}v{f(dep * 0.60)}"/>'
        for k in range(n - 1)
    )
    return (
        f'<path d="{d}" fill="{fill}"/>'
        + "".join(lobes)
        + f'<g fill="none" stroke="{INK}" stroke-width="{f(lw)}" '
          f'opacity="0.14">{seams}</g>'
        + f'<path d="M{f(x0)} {f(y)}{arcs}" fill="none" stroke="{INK}" '
          f'stroke-width="{f(lw)}" opacity="0.18"/>'
    )


def pedestal(cx: float, top: float, w: float, h: float) -> str:
    """Lotus plinth (padma pitha): petal course, waist, petal course, base.

    `top` is the seat line, so the upper petals close over the figure's hem --
    the murti sits *in* the lotus rather than balancing on a box.
    """
    lw = h * 0.020
    y_up = top + h * 0.26
    y_lo = top + h * 0.72
    return (
        # upward-turned petals cradling the seat
        _petal_row(cx - w * 0.470, cx + w * 0.470, y_up, 7, h * 0.30, True,
                   h * 0.14, STONE, lw)
        # fillet over them, with a lit top edge
        + rrect(cx - w * 0.490, y_up + h * 0.10, w * 0.980, h * 0.09,
                h * 0.03, STONE_SHADE)
        + f'<path d="M{f(cx - w * 0.470)} {f(y_up + h * 0.122)}'
          f'h{f(w * 0.940)}" stroke="{tint(STONE, 1.24)}" '
          f'stroke-width="{f(h * 0.020)}" opacity="0.6"/>'
        # waist course, shaded at its right and under the fillet
        + rrect(cx - w * 0.400, y_up + h * 0.17, w * 0.800, h * 0.30,
                h * 0.02, shade("#D6C6AC", 0.90))
        + rrect(cx - w * 0.400, y_up + h * 0.17, w * 0.760, h * 0.30,
                h * 0.02, "#D6C6AC")
        + f'<path d="M{f(cx - w * 0.390)} {f(y_up + h * 0.195)}'
          f'h{f(w * 0.740)}" stroke="{shade("#D6C6AC", 0.84)}" '
          f'stroke-width="{f(h * 0.030)}" opacity="0.55"/>'
        # pilasters
        + f'<g stroke="{GOLD}" stroke-width="{f(h * 0.020)}" opacity="0.5" '
          f'fill="none">'
          f'<path d="M{f(cx - w * 0.330)} {f(y_up + h * 0.20)}'
          f'v{f(h * 0.24)}"/>'
          f'<path d="M{f(cx + w * 0.330)} {f(y_up + h * 0.20)}'
          f'v{f(h * 0.24)}"/>'
          f"</g>"
        # rosette at the centre of the waist
        + petal_ring(cx, y_up + h * 0.32, w * 0.038, w * 0.110, 8,
                     shade(GOLD, 0.82), 0.6)
        + petal_ring(cx, y_up + h * 0.32, w * 0.034, w * 0.100, 8, GOLD, 0.75,
                     0.0, 0.48)
        + f'<circle cx="{f(cx)}" cy="{f(y_up + h * 0.32)}" '
          f'r="{f(w * 0.028)}" fill="{GOLD_PALE}" opacity="0.9"/>'
        # downward-turned petals
        + _petal_row(cx - w * 0.470, cx + w * 0.470, y_lo, 7, h * 0.24, False,
                     h * 0.09, STONE, lw)
        # base slab, with a lit top and a gold reglet
        + rrect(cx - w * 0.500, y_lo + h * 0.10, w, h * 0.18, h * 0.035,
                STONE_SHADE)
        + f'<path d="M{f(cx - w * 0.480)} {f(y_lo + h * 0.118)}'
          f'h{f(w * 0.960)}" stroke="{tint(STONE, 1.20)}" '
          f'stroke-width="{f(h * 0.018)}" opacity="0.55"/>'
        + f'<path d="M{f(cx - w * 0.500)} {f(y_lo + h * 0.165)}'
          f'h{f(w)}" stroke="{GOLD}" stroke-width="{f(h * 0.014)}" '
          f'opacity="0.45"/>'
        + f'<path d="M{f(cx - w * 0.500)} {f(y_lo + h * 0.252)}'
          f'h{f(w)}" stroke="{shade(STONE_SHADE, 0.86)}" '
          f'stroke-width="{f(h * 0.022)}" opacity="0.6"/>'
    )
