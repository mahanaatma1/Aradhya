"""Emit Aradhya's own artwork for every placeholder slot in assets/manifest.json.

    py -m content.tools.gen_svg_art

Writes one SVG per manifest row into assets/art/, plus a self-contained
contact sheet (assets/art/index.html) and the provenance record the
enhancement plan requires (assets/art/provenance.json).

The manifest rows are the worklist: 55 bundled images, every one of them still
licensed PLACEHOLDER-ISHVARVAANI and flagged replace_before_ship, which is what
build.py --strict trips over. Each SVG here targets exactly one of those rows
at exactly its pixel aspect, so the replacement is a like-for-like swap rather
than a redesign of the screens that consume the art.

Nothing is wired into the app by this script -- it only produces artwork. See
the report it prints for the two remaining steps (rasterise or add flutter_svg,
then clear the manifest flags).
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import REPO_ROOT  # noqa: E402
from content.tools.svg_kit import *  # noqa: E402,F401,F403
from content.tools.svg_kit import _ribbon  # noqa: E402 -- `import *` skips it

OUT_DIR = REPO_ROOT / "assets" / "art"
MANIFEST = REPO_ROOT / "assets" / "manifest.json"
GENERATOR = "content/tools/gen_svg_art.py"
ART_LICENSE = "ARADHYA-ORIGINAL"
ART_ARTIST = "Aradhya in-house (vector, script-composed)"


def defs(extra: str = "") -> str:
    """Gradients the primitives reference by id, plus per-asset additions."""
    return (
        lin("diyaClay", "#C98A4A", "#8A5A2B", 100)
        + lin("brass", "#E0A63C", "#B8862F", 100)
        + rad("ladooBall", "#F5B851", "#D98A22", 0.38, 0.32, 0.85)
        + extra
    )


# ============================================================== deities ====
# Iconography per deity: complexion, garments, which attributes go in which
# hand, and the vahana or emblem that identifies them at a glance.

DEITIES: dict[str, dict] = {
    "ganesha": dict(
        head="elephant", arms=4, skin="#F0C9A0", garment=TERRA,
        dhoti="#E8B23C", sash=ROSE_LT, crown=GOLD,
        hands=("modak", "", "trishul", "lotus"), companion="mouse",
        halo_color=GOLD_BRIGHT,
    ),
    "shiva": dict(
        head="jata", arms=4, skin="#CFC6B2", garment="#8E5320",
        dhoti="#C97F26", sash="#2F5D6B", crown=GOLD,
        hands=("", "damaru", "trishul", ""), companion=None,
        halo_color="#5F9BA8",
    ),
    "krishna": dict(
        head="human", arms=2, skin=SKIN_BLUE, garment=SAFFRON,
        dhoti="#E8B23C", sash=SAFFRON, crown=GOLD,
        hands=("flute", ""), companion=None, crest="feather",
        halo_color=GOLD_BRIGHT, garland=True, pose="flute",
    ),
    "ram": dict(
        head="human", arms=2, skin=SKIN_BLUE, garment=GREEN,
        dhoti="#E8C15A", sash=TERRA, crown=GOLD,
        hands=("arrow", "bow"), companion=None, halo_color=GOLD_BRIGHT,
        garland=True,
    ),
    "hanuman": dict(
        head="vanara", arms=2, skin="#E0713F", garment=TERRA,
        dhoti=SAFFRON, sash="#E8C15A", crown=GOLD,
        hands=("gada", ""), companion="tail", halo_color=SAFFRON,
    ),
    "durga": dict(
        head="devi", arms=4, skin="#F2CFA6", garment=TERRA,
        dhoti="#C4203F", sash="#E8C15A", crown=GOLD,
        hands=("lotus", "trishul", "chakra", "conch"), companion="lion",
        halo_color=GOLD_BRIGHT, bodice=True, garland=True,
    ),
    "lakshmi": dict(
        head="devi", arms=4, skin="#F2CFA6", garment=ROSE,
        dhoti="#D8456E", sash="#E8C15A", crown=GOLD,
        hands=("coin", "", "lotus", "lotus"), companion="coins",
        halo_color=GOLD_BRIGHT, bodice=True, garland=True,
    ),
    "saraswati": dict(
        head="devi", arms=4, skin="#F2CFA6", garment=CREAM,
        dhoti="#EFE6D2", sash=TEAL, crown=GOLD,
        hands=("pothi", "mala", "veena", ""), companion="swan",
        halo_color="#CFE6EA", bodice=True,
    ),
    "kartikeya": dict(
        head="human", arms=2, skin="#F0C9A0", garment="#C4203F",
        dhoti="#E8B23C", sash=GREEN_LT, crown=GOLD,
        hands=("spear", ""), companion="peacock", halo_color=GOLD_BRIGHT,
    ),
    "ayyappa": dict(
        head="human", arms=2, skin="#E0B98F", garment="#2E4A7A",
        dhoti="#2E4A7A", sash=SAFFRON, crown=GOLD,
        hands=("bell", "bow"), companion="yogapatta", halo_color=SAFFRON,
    ),
    "dattatreya": dict(
        head="jata", arms=4, skin="#EFCBA4", garment=SAFFRON,
        dhoti=SAFFRON, sash="#E8DCC8", crown=GOLD,
        hands=("damaru", "mala", "trishul", "kalash"), companion="triple",
        halo_color=GOLD_BRIGHT,
    ),
    "meenakshi": dict(
        head="devi", arms=2, skin="#D8A87C", garment=GREEN,
        dhoti="#1F6B4F", sash="#E8C15A", crown=GOLD,
        hands=("parrot", ""), companion="fish", halo_color=GOLD_BRIGHT,
        bodice=True, garland=True,
    ),
}


def companion_art(kind: str | None, cx: float, seat: float, h: float) -> str:
    """Vahana / emblem beside the seat, drawn behind the figure.

    Everything here has to stay inside +-0.47h of cx: the canvas is only a
    little wider than the figure, and a clipped vahana looks like a mistake.
    """
    if kind == "mouse":
        return g_mouse(cx + h * 0.38, seat - h * 0.045, h * 0.20)
    if kind == "lion":
        # on the devi's left, where the maned head clears her forearm; behind
        # the lap it was hidden by the arm and read as a tan blob
        return g_lion(cx + h * 0.28, seat - h * 0.075, h * 0.30)
    if kind == "swan":
        return g_swan(cx + h * 0.38, seat - h * 0.075, h * 0.24)
    if kind == "coins":
        return "".join(
            g_coin(cx + h * (0.30 + 0.06 * i), seat - h * 0.03 + h * 0.02 * i,
                   h * 0.10)
            for i in range(3)
        )
    if kind == "fish":
        return (
            g_fish(cx - h * 0.36, seat - h * 0.07, h * 0.22)
            + g_fish(cx + h * 0.36, seat - h * 0.07, h * 0.22)
        )
    if kind == "peacock":
        return "".join(
            g_feather(cx + h * (0.32 + 0.05 * i), seat - h * 0.20, h * 0.24)
            for i in range(3)
        )
    if kind == "tail":
        # Hanuman's tail: one smooth arc up clear of the left shoulder. Drawn
        # with _ribbon rather than _taper -- a segmented tail kinked visibly at
        # this size, which was the single most cartoonish thing in the set.
        return _ribbon(
            (cx - h * 0.155, seat - h * 0.030),
            (cx - h * 0.440, seat - h * 0.020),
            (cx - h * 0.440, seat - h * 0.460),
            (cx - h * 0.235, seat - h * 0.410),
            h * 0.046, h * 0.013, "#D9652E", 0.80, 40, h * 0.004,
        )
    if kind == "yogapatta":
        # the band that binds Ayyappa's knees in his seated posture
        return (
            f'<path d="M{f(cx - h * 0.30)} {f(seat - h * 0.11)}'
            f'h{f(h * 0.60)}" stroke="{SAFFRON}" '
            f'stroke-width="{f(h * 0.022)}" opacity="0.95"/>'
        )
    if kind == "triple":
        return petal_ring(cx, seat - h * 0.56, h * 0.24, h * 0.30, 3,
                          GOLD_BRIGHT, 0.35, 0.0, 0.55)
    return ""


def build_deity(slug: str, w: float, h: float) -> str:
    """Full-body murti on a carved plinth, transparent background."""
    cfg = DEITIES[slug]
    cx = w / 2
    ped_h = h * 0.150
    seat = h * 0.855           # where the figure's seat meets the plinth
    top = h * 0.055            # headroom for the aureole and the crown finial
    fig_h = (seat - top) / SEAT_T

    body = [
        companion_art(cfg.get("companion"), cx, seat, fig_h),
        seated_figure(
            cx, top, fig_h,
            skin=cfg["skin"], garment=cfg["garment"], dhoti=cfg["dhoti"],
            crown=cfg["crown"], sash=cfg["sash"], head=cfg["head"],
            arms=cfg["arms"], hands=cfg["hands"],
            halo_color=cfg.get("halo_color", GOLD_BRIGHT),
            bodice=cfg.get("bodice", False),
            garland=cfg.get("garland", False),
            pose=cfg.get("pose", ""),
        ),
        pedestal(cx, seat, w * 0.60, ped_h),
    ]
    if cfg.get("crest") == "feather":
        body.append(
            f'<g transform="rotate(-24 {f(cx)} {f(top + fig_h * 0.10)})">'
            + g_feather(cx - fig_h * 0.055, top + fig_h * 0.02, fig_h * 0.26)
            + "</g>"
        )
    # a few marigolds on the plinth edge, the way a shrine is dressed
    for dx in (-0.22, -0.13, 0.13, 0.22):
        body.append(
            f'<circle cx="{f(cx + w * dx)}" cy="{f(seat + ped_h * 0.06)}" '
            f'r="{f(w * 0.018)}" fill="{SAFFRON}"/>'
        )
    return svg(w, h, "".join(body), defs(), f"Aradhya — {slug}")


# ============================================================ portraits ====


def medallion(size: float, inner: str, tint_a: str, tint_b: str) -> str:
    cx = cy = size / 2
    r = size / 2
    return (
        f'<clipPath id="disc"><circle cx="{f(cx)}" cy="{f(cy)}" '
        f'r="{f(r)}"/></clipPath>'
        f'<g clip-path="url(#disc)">'
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="url(#medBg)"/>'
        + mandala(cx, cy, r * 0.94, GOLD_PALE, 0.15, 16)
        + inner
        + "</g>"
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.965)}" fill="none" '
        f'stroke="{TERRA_DARK}" stroke-width="{f(size * 0.045)}"/>'
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.90)}" fill="none" '
        f'stroke="{GOLD}" stroke-width="{f(size * 0.010)}" '
        f'stroke-dasharray="{f(size * 0.030)} {f(size * 0.024)}" '
        f'opacity="0.85"/>'
    )


def build_portrait(slug: str, w: float, h: float) -> str:
    cfg = DEITIES[slug]
    cx = w / 2
    seat = h * 0.870
    top = h * 0.145
    fig_h = (seat - top) / SEAT_T
    inner = (
        companion_art(cfg.get("companion"), cx, seat, fig_h)
        + seated_figure(
            cx, top, fig_h,
            skin=cfg["skin"], garment=cfg["garment"], dhoti=cfg["dhoti"],
            crown=cfg["crown"], sash=cfg["sash"], head=cfg["head"],
            arms=cfg["arms"], hands=cfg["hands"],
            halo_color=cfg.get("halo_color", GOLD_BRIGHT),
            bodice=cfg.get("bodice", False),
            garland=cfg.get("garland", False),
            pose=cfg.get("pose", ""),
        )
    )
    if cfg.get("crest") == "feather":
        inner += (
            f'<g transform="rotate(-24 {f(cx)} {f(top + fig_h * 0.10)})">'
            + g_feather(cx - fig_h * 0.055, top + fig_h * 0.02, fig_h * 0.26)
            + "</g>"
        )
    d = defs(rad("medBg", "#C89A5A", "#5B1B22", 0.5, 0.34, 0.85))
    return svg(w, h, medallion(w, inner, "", ""), d,
               f"Aradhya — {slug} portrait")


def build_portrait_other(w: float, h: float) -> str:
    """Fallback avatar: a shrine, for any deity we have no portrait for."""
    cx = w / 2
    inner = temple(cx, h * 0.86, h * 0.68, "#E9BE96", TERRA, GOLD)
    d = defs(rad("medBg", "#C89A5A", "#5B1B22", 0.5, 0.34, 0.85))
    return svg(w, h, medallion(w, inner, "", ""), d, "Aradhya — shrine")


# ============================================================= emotions ====

EMOTIONS = {
    # (band colour, deep colour, backdrop, petal origin corner)
    "peace": ("#8FDDDF", "#B7EBEC", "#FFFFFF", "bl"),
    "joy": ("#F5C24C", "#FADFA1", "#FFFDF6", "bl"),
    "love": ("#EC9BAF", "#F6C9D3", "#FFFAFB", "br"),
    "faith": ("#EBA84C", "#F6D5A3", "#FFFCF5", "bl"),
    "anger": ("#DE7452", "#EFAE97", "#FFF8F5", "br"),
    "fear": ("#8B93C8", "#C0C5E2", "#F9FAFF", "bl"),
}


def band(ox: float, oy: float, ang: float, length: float, w0: float,
         w1: float, bend: float) -> tuple[str, str]:
    """A sweeping tapered ray. Returns (fill path, centreline for the stitch)."""
    a = math.radians(ang)
    dx, dy = math.cos(a), math.sin(a)
    nx, ny = -dy, dx
    ex, ey = ox + dx * length + nx * bend, oy + dy * length + ny * bend
    mx, my = ox + dx * length * 0.5 + nx * bend * 0.75, \
        oy + dy * length * 0.5 + ny * bend * 0.75
    sl = (ox + nx * w0 / 2, oy + ny * w0 / 2)
    sr = (ox - nx * w0 / 2, oy - ny * w0 / 2)
    el = (ex + nx * w1 / 2, ey + ny * w1 / 2)
    er = (ex - nx * w1 / 2, ey - ny * w1 / 2)
    cl = (mx + nx * w1 * 0.45, my + ny * w1 * 0.45)
    cr = (mx - nx * w1 * 0.45, my - ny * w1 * 0.45)
    d = (
        f"M{f(sl[0])} {f(sl[1])}"
        f"Q{f(cl[0])} {f(cl[1])} {f(el[0])} {f(el[1])}"
        f"L{f(er[0])} {f(er[1])}"
        f"Q{f(cr[0])} {f(cr[1])} {f(sr[0])} {f(sr[1])}Z"
    )
    centre = f"M{f(ox)} {f(oy)}Q{f(mx)} {f(my)} {f(ex)} {f(ey)}"
    return d, centre


def build_emotion(name: str, w: float, h: float) -> str:
    c, c2, bg, corner = EMOTIONS[name]
    right = corner == "br"
    ox = w * (0.90 if right else 0.10)
    oy = h * 1.02
    base = 180.0 if right else 0.0
    body = [f'<rect width="{f(w)}" height="{f(h)}" fill="{bg}"/>']

    spread = [-88, -62, -38, -16, 6]
    for i, off in enumerate(spread):
        ang = base + (-off if right else off) - (90 if not right else -90)
        ang = (base - 90 + off) if not right else (base + 90 - off)
        d, centre = band(
            ox, oy, ang, w * (1.02 + 0.06 * i), w * 0.10,
            w * (0.15 + 0.02 * (i % 3)), w * (0.05 if i % 2 else -0.05),
        )
        body.append(f'<path d="{d}" fill="{c if i % 2 == 0 else c2}"/>')
        body.append(stitch(centre, bg, max(2.0, w * 0.0022), w * 0.016,
                           w * 0.013, 0.75))

    # the lotus the rays open out of
    body.append(lotus(ox, oy - h * 0.02, w * 0.135, c2, c, 7, 168))
    body.append(
        f'<circle cx="{f(ox)}" cy="{f(oy - h * 0.02)}" '
        f'r="{f(w * 0.026)}" fill="{c}"/>'
    )
    return svg(w, h, "".join(body), defs(), f"Aradhya — {name}")


# ===================================================== scripture covers ====


def person(cx: float, base: float, h: float, robe: str, skin: str = SKIN,
           hair: str = INK, lean: float = 0.0) -> str:
    """Flat standing silhouette, the register the reference covers are drawn in."""
    hr = h * 0.105
    return (
        f'<g transform="rotate({f(lean)} {f(cx)} {f(base)})">'
        f'<path d="M{f(cx - h * 0.115)} {f(base)}'
        f'C{f(cx - h * 0.115)} {f(base - h * 0.52)} {f(cx - h * 0.085)} '
        f'{f(base - h * 0.72)} {f(cx)} {f(base - h * 0.76)}'
        f'C{f(cx + h * 0.085)} {f(base - h * 0.72)} {f(cx + h * 0.115)} '
        f'{f(base - h * 0.52)} {f(cx + h * 0.115)} {f(base)}z" fill="{robe}"/>'
        f'<circle cx="{f(cx)}" cy="{f(base - h * 0.88)}" r="{f(hr)}" '
        f'fill="{skin}"/>'
        f'<path d="M{f(cx - hr)} {f(base - h * 0.90)}'
        f'a{f(hr)} {f(hr)} 0 0 1 {f(hr * 2)} 0'
        f'q{f(-hr * 0.2)} {f(hr * 0.55)} {f(-hr * 2)} 0z" fill="{hair}"/>'
        f"</g>"
    )


def tree(cx: float, base: float, h: float, trunk: str = "#B98A63",
         leaf: str = "#C9A47C") -> str:
    return (
        f'<rect x="{f(cx - h * 0.035)}" y="{f(base - h * 0.68)}" '
        f'width="{f(h * 0.07)}" height="{f(h * 0.68)}" fill="{trunk}"/>'
        f'<circle cx="{f(cx)}" cy="{f(base - h * 0.78)}" r="{f(h * 0.20)}" '
        f'fill="{leaf}"/>'
        f'<circle cx="{f(cx - h * 0.16)}" cy="{f(base - h * 0.66)}" '
        f'r="{f(h * 0.14)}" fill="{leaf}"/>'
        f'<circle cx="{f(cx + h * 0.16)}" cy="{f(base - h * 0.68)}" '
        f'r="{f(h * 0.15)}" fill="{leaf}"/>'
    )


def wheel(cx: float, cy: float, r: float, color: str, sw: float) -> str:
    spokes = []
    for k in range(12):
        a = math.radians(360.0 * k / 12)
        spokes.append(
            f'<path d="M{f(cx)} {f(cy)}L{f(cx + math.cos(a) * r * 0.86)} '
            f'{f(cy + math.sin(a) * r * 0.86)}"/>'
        )
    return (
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="none" '
        f'stroke="{color}" stroke-width="{f(sw)}"/>'
        f'<g stroke="{color}" stroke-width="{f(sw * 0.45)}">'
        + "".join(spokes)
        + "</g>"
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.16)}" '
        f'fill="{color}"/>'
    )


def build_cover_ramayana(w: float, h: float) -> str:
    """Rama, Sita and the golden deer in the Dandaka forest."""
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" fill="#F6EBDC"/>',
        f'<circle cx="{f(w * 0.78)}" cy="{f(h * 0.20)}" r="{f(h * 0.13)}" '
        f'fill="#EFD9B8"/>',
        tree(w * 0.13, h * 0.92, h * 0.95, "#A97A55", "#C69C74"),
        tree(w * 0.42, h * 0.88, h * 0.80, "#B98A63", "#D3AC85"),
        tree(w * 0.66, h * 0.86, h * 0.70, "#C79A72", "#DDBA95"),
        # ground
        f'<path d="M0 {f(h)}V{f(h * 0.86)}'
        f'C{f(w * 0.30)} {f(h * 0.80)} {f(w * 0.70)} {f(h * 0.83)} {f(w)} '
        f'{f(h * 0.78)}V{f(h)}z" fill="#B4855E"/>',
        f'<path d="M0 {f(h)}V{f(h * 0.94)}'
        f'C{f(w * 0.35)} {f(h * 0.90)} {f(w * 0.72)} {f(h * 0.94)} {f(w)} '
        f'{f(h * 0.90)}V{f(h)}z" fill="#8E6544"/>',
        person(w * 0.27, h * 0.90, h * 0.52, "#C39098", SKIN, INK),
        person(w * 0.40, h * 0.90, h * 0.58, "#5B7BA6", SKIN_BLUE, INK),
        # Rama's bow
        g_bow(w * 0.50, h * 0.62, h * 0.44, "#7A5A38", "#EFE0C6"),
        # the golden deer
        f'<g fill="#D2A33C">'
        f'<ellipse cx="{f(w * 0.71)}" cy="{f(h * 0.74)}" '
        f'rx="{f(h * 0.085)}" ry="{f(h * 0.055)}"/>'
        f'<rect x="{f(w * 0.665)}" y="{f(h * 0.775)}" '
        f'width="{f(h * 0.018)}" height="{f(h * 0.10)}"/>'
        f'<rect x="{f(w * 0.70)}" y="{f(h * 0.775)}" '
        f'width="{f(h * 0.018)}" height="{f(h * 0.10)}"/>'
        f'<rect x="{f(w * 0.745)}" y="{f(h * 0.775)}" '
        f'width="{f(h * 0.018)}" height="{f(h * 0.10)}"/>'
        f'<path d="M{f(w * 0.775)} {f(h * 0.72)}'
        f'l{f(h * 0.055)} {f(-h * 0.10)}l{f(h * 0.03)} {f(h * 0.02)}'
        f'l{f(-h * 0.045)} {f(h * 0.10)}z"/>'
        f'<ellipse cx="{f(w * 0.84)}" cy="{f(h * 0.60)}" '
        f'rx="{f(h * 0.032)}" ry="{f(h * 0.026)}"/>'
        f"</g>"
        f'<g stroke="#D2A33C" stroke-width="{f(h * 0.012)}" fill="none" '
        f'stroke-linecap="round">'
        f'<path d="M{f(w * 0.83)} {f(h * 0.575)}l{f(-h * 0.03)} '
        f'{f(-h * 0.075)}m0 0l{f(-h * 0.035)} {f(h * 0.02)}'
        f'm{f(h * 0.035)} {f(-h * 0.02)}l{f(h * 0.015)} {f(-h * 0.04)}"/>'
        f'<path d="M{f(w * 0.86)} {f(h * 0.575)}l{f(h * 0.03)} '
        f'{f(-h * 0.075)}m0 0l{f(h * 0.035)} {f(h * 0.02)}'
        f'm{f(-h * 0.035)} {f(-h * 0.02)}l{f(-h * 0.015)} {f(-h * 0.04)}"/>'
        f"</g>",
        # birds
        f'<g stroke="#9C7A5A" stroke-width="{f(h * 0.008)}" fill="none" '
        f'stroke-linecap="round">'
        f'<path d="M{f(w * 0.60)} {f(h * 0.29)}q{f(h * 0.02)} '
        f'{f(-h * 0.02)} {f(h * 0.04)} 0"/>'
        f'<path d="M{f(w * 0.66)} {f(h * 0.25)}q{f(h * 0.02)} '
        f'{f(-h * 0.02)} {f(h * 0.04)} 0"/>'
        f"</g>",
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — Ramayana")


def build_cover_gita(w: float, h: float) -> str:
    """Krishna and Arjuna at the chariot, before the first arrow."""
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" fill="url(#gitaSky)"/>',
        f'<circle cx="{f(w * 0.50)}" cy="{f(h * 0.30)}" r="{f(h * 0.22)}" '
        f'fill="#F3D9A4" opacity="0.85"/>',
        petal_ring(w * 0.50, h * 0.30, h * 0.23, h * 0.30, 24, "#EDC98A",
                   0.55),
        f'<path d="M0 {f(h)}V{f(h * 0.80)}'
        f'C{f(w * 0.35)} {f(h * 0.74)} {f(w * 0.68)} {f(h * 0.79)} {f(w)} '
        f'{f(h * 0.74)}V{f(h)}z" fill="#C8A277"/>',
        f'<path d="M0 {f(h)}V{f(h * 0.90)}'
        f'C{f(w * 0.40)} {f(h * 0.85)} {f(w * 0.75)} {f(h * 0.90)} {f(w)} '
        f'{f(h * 0.86)}V{f(h)}z" fill="#9C7850"/>',
        # chariot deck + wheel
        f'<path d="M{f(w * 0.18)} {f(h * 0.86)}h{f(w * 0.50)}'
        f'l{f(-w * 0.05)} {f(-h * 0.10)}h{f(-w * 0.40)}z" fill="#8A5A2B"/>',
        wheel(w * 0.30, h * 0.80, h * 0.145, "#7A4A22", h * 0.024),
        person(w * 0.545, h * 0.76, h * 0.46, "#5B7BA6", SKIN_BLUE, INK),
        person(w * 0.40, h * 0.76, h * 0.42, "#C9975A", SKIN, INK),
        g_bow(w * 0.34, h * 0.60, h * 0.34, "#6E4A28", "#EFE0C6"),
        g_flute(w * 0.60, h * 0.60, h * 0.20),
        # banner
        f'<path d="M{f(w * 0.72)} {f(h * 0.86)}V{f(h * 0.34)}" '
        f'stroke="#7A4A22" stroke-width="{f(h * 0.014)}"/>',
        f'<path d="M{f(w * 0.72)} {f(h * 0.36)}h{f(w * 0.16)}'
        f'l{f(-w * 0.045)} {f(h * 0.055)}h{f(-w * 0.115)}z" '
        f'fill="{TERRA}"/>',
    ]
    d = defs(lin3("gitaSky", "#FBF0DC", "#F6E4C6", "#EFD6AE", 100))
    return svg(w, h, "".join(body), d, "Aradhya — Bhagavad Gita")


def build_cover_mahabharata(w: float, h: float) -> str:
    """Kurukshetra: two armies, two banners, one wheel between them."""
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" fill="url(#mbSky)"/>',
        f'<circle cx="{f(w * 0.50)}" cy="{f(h * 0.26)}" r="{f(h * 0.115)}" '
        f'fill="#E9B98C" opacity="0.9"/>',
        # distant ranks, as a toothed silhouette
        f'<path d="M0 {f(h * 0.62)}' + "".join(
            f"l{f(w * 0.02)} {f(-h * 0.03)}l{f(w * 0.02)} {f(h * 0.03)}"
            for _ in range(25)
        ) + f'V{f(h * 0.70)}H0z" fill="#B98A63" opacity="0.55"/>',
        f'<path d="M0 {f(h)}V{f(h * 0.68)}H{f(w)}V{f(h)}z" fill="#C69C74"/>',
        f'<path d="M0 {f(h)}V{f(h * 0.84)}'
        f'C{f(w * 0.35)} {f(h * 0.79)} {f(w * 0.70)} {f(h * 0.85)} {f(w)} '
        f'{f(h * 0.80)}V{f(h)}z" fill="#966E48"/>',
        wheel(w * 0.50, h * 0.60, h * 0.175, "#7A4A22", h * 0.026),
        # crossed bow and mace behind the wheel
        f'<g transform="rotate(-32 {f(w * 0.50)} {f(h * 0.60)})">'
        + g_gada(w * 0.50, h * 0.60, h * 0.44)
        + "</g>"
        f'<g transform="rotate(28 {f(w * 0.50)} {f(h * 0.60)})">'
        + g_bow(w * 0.50, h * 0.60, h * 0.50, "#6E4A28", "#EFE0C6")
        + "</g>",
        # banners
        f'<g stroke="#7A4A22" stroke-width="{f(h * 0.011)}">'
        f'<path d="M{f(w * 0.17)} {f(h * 0.80)}V{f(h * 0.34)}"/>'
        f'<path d="M{f(w * 0.83)} {f(h * 0.80)}V{f(h * 0.34)}"/>'
        f"</g>"
        f'<path d="M{f(w * 0.17)} {f(h * 0.36)}h{f(w * 0.12)}'
        f'l{f(-w * 0.035)} {f(h * 0.05)}h{f(-w * 0.085)}z" fill="{TERRA}"/>'
        f'<path d="M{f(w * 0.83)} {f(h * 0.36)}h{f(-w * 0.12)}'
        f'l{f(w * 0.035)} {f(h * 0.05)}h{f(w * 0.085)}z" fill="{GREEN}"/>',
    ]
    d = defs(lin3("mbSky", "#F7E9D2", "#F0D9B4", "#E4C characters", 100)
             .replace("#E4C characters", "#E4C59A"))
    return svg(w, h, "".join(body), d, "Aradhya — Mahabharata")


def build_cover_upanishads(w: float, h: float) -> str:
    """A teacher, two students, one lamp -- upa-ni-shad, sitting down near."""
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" fill="#F7EEDD"/>',
        tree(w * 0.50, h * 0.80, h * 1.05, "#A97A55", "#C2A07C"),
        f'<path d="M0 {f(h)}V{f(h * 0.80)}H{f(w)}V{f(h)}z" fill="#C9A882"/>',
        f'<path d="M0 {f(h)}V{f(h * 0.90)}H{f(w)}V{f(h)}z" fill="#A5825C"/>',
        # teacher, seated: a low dome plus a head
        f'<path d="M{f(w * 0.38)} {f(h * 0.80)}'
        f'C{f(w * 0.38)} {f(h * 0.62)} {f(w * 0.62)} {f(h * 0.62)} '
        f'{f(w * 0.62)} {f(h * 0.80)}z" fill="#D9713F"/>',
        f'<circle cx="{f(w * 0.50)}" cy="{f(h * 0.585)}" '
        f'r="{f(h * 0.048)}" fill="{SKIN}"/>',
        f'<path d="M{f(w * 0.46)} {f(h * 0.555)}'
        f'a{f(h * 0.048)} {f(h * 0.048)} 0 0 1 {f(h * 0.096)} 0z" '
        f'fill="#E8E2D6"/>',
        petal_ring(w * 0.50, h * 0.585, h * 0.075, h * 0.115, 14,
                   GOLD_BRIGHT, 0.30),
        # students
        f'<path d="M{f(w * 0.18)} {f(h * 0.82)}'
        f'C{f(w * 0.18)} {f(h * 0.70)} {f(w * 0.32)} {f(h * 0.70)} '
        f'{f(w * 0.32)} {f(h * 0.82)}z" fill="#8A9C7A"/>',
        f'<circle cx="{f(w * 0.25)}" cy="{f(h * 0.675)}" '
        f'r="{f(h * 0.036)}" fill="{SKIN}"/>',
        f'<path d="M{f(w * 0.68)} {f(h * 0.82)}'
        f'C{f(w * 0.68)} {f(h * 0.70)} {f(w * 0.82)} {f(h * 0.70)} '
        f'{f(w * 0.82)} {f(h * 0.82)}z" fill="#9C8AA6"/>',
        f'<circle cx="{f(w * 0.75)}" cy="{f(h * 0.675)}" '
        f'r="{f(h * 0.036)}" fill="{SKIN}"/>',
        diya(w * 0.50, h * 0.845, h * 0.10, True),
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — Upanishads")


def build_cover_aartis(w: float, h: float) -> str:
    """The aarti thali, mid-circle, with the temple bells above it."""
    cx = w * 0.50
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" fill="url(#aartiBg)"/>',
        petal_ring(cx, h * 0.56, h * 0.30, h * 0.46, 20, GOLD_BRIGHT, 0.20),
        # hanging bells
        bell(w * 0.20, h * 0.06, h * 0.30),
        bell(w * 0.80, h * 0.06, h * 0.30),
        # thali
        f'<ellipse cx="{f(cx)}" cy="{f(h * 0.70)}" rx="{f(w * 0.26)}" '
        f'ry="{f(h * 0.075)}" fill="url(#brass)"/>',
        f'<ellipse cx="{f(cx)}" cy="{f(h * 0.685)}" rx="{f(w * 0.21)}" '
        f'ry="{f(h * 0.055)}" fill="#C98A2E"/>',
        flame(cx - w * 0.10, h * 0.50, h * 0.16),
        flame(cx, h * 0.44, h * 0.21),
        flame(cx + w * 0.10, h * 0.50, h * 0.16),
        # hands cupping the thali
        f'<path d="M{f(cx - w * 0.30)} {f(h * 0.98)}'
        f'C{f(cx - w * 0.30)} {f(h * 0.80)} {f(cx - w * 0.20)} '
        f'{f(h * 0.74)} {f(cx - w * 0.10)} {f(h * 0.76)}'
        f'L{f(cx - w * 0.13)} {f(h * 0.98)}z" fill="{SKIN}"/>',
        f'<path d="M{f(cx + w * 0.30)} {f(h * 0.98)}'
        f'C{f(cx + w * 0.30)} {f(h * 0.80)} {f(cx + w * 0.20)} '
        f'{f(h * 0.74)} {f(cx + w * 0.10)} {f(h * 0.76)}'
        f'L{f(cx + w * 0.13)} {f(h * 0.98)}z" fill="{SKIN}"/>',
    ]
    d = defs(rad("aartiBg", "#FDF2DE", "#E9CFA4", 0.5, 0.45, 0.8))
    return svg(w, h, "".join(body), d, "Aradhya — Aartis")


def build_cover_mantras(w: float, h: float) -> str:
    """A mala and the widening rings of a repeated sound."""
    cx, cy = w * 0.50, h * 0.50
    rings = "".join(
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(h * (0.16 + 0.075 * i))}" '
        f'fill="none" stroke="{TERRA}" stroke-width="{f(h * 0.008)}" '
        f'opacity="{f(0.42 - 0.06 * i)}" '
        f'stroke-dasharray="{f(h * 0.03)} {f(h * 0.022)}"/>'
        for i in range(5)
    )
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" fill="url(#mantraBg)"/>',
        rings,
        g_mala(cx, cy, h * 0.62, "#8A5A3B"),
        lotus(cx, cy + h * 0.10, h * 0.15, ROSE_LT, ROSE, 7, 160),
    ]
    d = defs(rad("mantraBg", "#FDF6E8", "#EBD6B4", 0.5, 0.44, 0.8))
    return svg(w, h, "".join(body), d, "Aradhya — Mantras")


# ============================================================ puja items ====


def build_bhog(w: float, h: float) -> str:
    """Fruit offering. Small object on a tall transparent canvas, as before."""
    cx, cy = w * 0.50, h * 0.50
    bw = w * 0.42
    body = [
        f'<ellipse cx="{f(cx)}" cy="{f(cy + bw * 0.50)}" '
        f'rx="{f(bw * 0.55)}" ry="{f(bw * 0.09)}" fill="{INK}" '
        f'opacity="0.10"/>',
        # fruit behind the rim
        f'<circle cx="{f(cx - bw * 0.20)}" cy="{f(cy - bw * 0.10)}" '
        f'r="{f(bw * 0.17)}" fill="#C4453A"/>',
        f'<circle cx="{f(cx + bw * 0.04)}" cy="{f(cy - bw * 0.16)}" '
        f'r="{f(bw * 0.16)}" fill="#8FA855"/>',
        f'<circle cx="{f(cx + bw * 0.24)}" cy="{f(cy - bw * 0.08)}" '
        f'r="{f(bw * 0.15)}" fill="#D98A2B"/>',
        f'<path d="M{f(cx - bw * 0.40)} {f(cy - bw * 0.02)}'
        f'C{f(cx - bw * 0.46)} {f(cy - bw * 0.30)} {f(cx - bw * 0.10)} '
        f'{f(cy - bw * 0.42)} {f(cx + bw * 0.02)} {f(cy - bw * 0.30)}'
        f'C{f(cx - bw * 0.10)} {f(cy - bw * 0.28)} {f(cx - bw * 0.30)} '
        f'{f(cy - bw * 0.14)} {f(cx - bw * 0.28)} {f(cy)}z" '
        f'fill="#E8C452"/>',
        f'<path d="M{f(cx - bw * 0.02)} {f(cy - bw * 0.36)}'
        f'l{f(bw * 0.03)} {f(-bw * 0.06)}" stroke="{GREEN}" '
        f'stroke-width="{f(bw * 0.03)}"/>',
        bowl(cx, cy, bw),
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — bhog")


def build_ladoo(w: float, h: float) -> str:
    cx, cy = w * 0.50, h * 0.52
    bw = w * 0.52
    body = [
        f'<ellipse cx="{f(cx)}" cy="{f(cy + bw * 0.50)}" '
        f'rx="{f(bw * 0.55)}" ry="{f(bw * 0.08)}" fill="{INK}" '
        f'opacity="0.10"/>',
        g_ladoo(cx - bw * 0.22, cy - bw * 0.12, bw * 0.44),
        g_ladoo(cx + bw * 0.22, cy - bw * 0.12, bw * 0.44),
        g_ladoo(cx, cy - bw * 0.24, bw * 0.46),
        bowl(cx, cy, bw),
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — ladoo")


def build_pladoo(w: float, h: float) -> str:
    body = [g_ladoo(w * 0.50, h * 0.50, w * 1.6)]
    return svg(w, h, "".join(body), defs(), "Aradhya — ladoo icon")


def build_diya(w: float, h: float, lit: bool) -> str:
    cx, cy = w * 0.50, h * 0.52
    body = [
        f'<ellipse cx="{f(cx)}" cy="{f(cy + w * 0.30)}" rx="{f(w * 0.30)}" '
        f'ry="{f(w * 0.045)}" fill="{INK}" opacity="0.10"/>',
        diya(cx, cy, w * 0.52, lit),
    ]
    return svg(w, h, "".join(body), defs(),
               f"Aradhya — diya {'lit' if lit else 'unlit'}")


def build_virtual_puja(w: float, h: float) -> str:
    """A devotee at the home shrine -- the Mandir tab's own picture."""
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" fill="#F6EBDA"/>',
        # niche
        arch(w * 0.34, h * 0.10, w * 0.52, h * 0.72, "#7C9B86"),
        arch(w * 0.34, h * 0.14, w * 0.44, h * 0.66, "#F2E6D2"),
        # right-hand shrine wall
        f'<rect x="{f(w * 0.70)}" y="0" width="{f(w * 0.30)}" '
        f'height="{f(h)}" fill="#C4553A"/>',
        f'<rect x="{f(w * 0.90)}" y="0" width="{f(w * 0.10)}" '
        f'height="{f(h)}" fill="#8FA8C4"/>',
        # altar
        f'<rect x="{f(w * 0.66)}" y="{f(h * 0.62)}" width="{f(w * 0.30)}" '
        f'height="{f(h * 0.38)}" fill="#E0A63C"/>',
        f'<rect x="{f(w * 0.70)}" y="{f(h * 0.40)}" width="{f(w * 0.22)}" '
        f'height="{f(h * 0.22)}" fill="#C98A2E"/>',
        bell(w * 0.80, h * 0.10, h * 0.16),
        diya(w * 0.80, h * 0.585, w * 0.14, True),
        # devotee, hands joined
        f'<path d="M{f(w * 0.28)} {f(h)}'
        f'C{f(w * 0.24)} {f(h * 0.66)} {f(w * 0.34)} {f(h * 0.52)} '
        f'{f(w * 0.44)} {f(h * 0.52)}'
        f'C{f(w * 0.52)} {f(h * 0.52)} {f(w * 0.56)} {f(h * 0.74)} '
        f'{f(w * 0.55)} {f(h)}z" fill="#D2705A"/>',
        f'<path d="M{f(w * 0.30)} {f(h)}'
        f'C{f(w * 0.28)} {f(h * 0.72)} {f(w * 0.36)} {f(h * 0.60)} '
        f'{f(w * 0.44)} {f(h * 0.58)}L{f(w * 0.46)} {f(h)}z" '
        f'fill="#E08A6E" opacity="0.85"/>',
        f'<circle cx="{f(w * 0.43)}" cy="{f(h * 0.42)}" '
        f'r="{f(h * 0.075)}" fill="#D8A87C"/>',
        f'<path d="M{f(w * 0.36)} {f(h * 0.40)}'
        f'a{f(h * 0.075)} {f(h * 0.075)} 0 0 1 {f(h * 0.15)} 0'
        f'q{f(-h * 0.02)} {f(h * 0.05)} {f(-h * 0.15)} 0z" fill="{INK}"/>',
        f'<circle cx="{f(w * 0.365)}" cy="{f(h * 0.375)}" '
        f'r="{f(h * 0.032)}" fill="{INK}"/>',
        # joined palms
        f'<path d="M{f(w * 0.52)} {f(h * 0.60)}'
        f'l{f(h * 0.055)} {f(-h * 0.12)}l{f(h * 0.03)} {f(h * 0.02)}'
        f'l{f(-h * 0.05)} {f(h * 0.12)}z" fill="#D8A87C"/>',
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — virtual puja")


# ================================================================ badges ====


def badge_frame(size: float, fill: str, edge: str) -> str:
    pad = size * 0.085
    return (
        rrect(pad, pad, size - pad * 2, size - pad * 2, size * 0.22, fill,
              f'stroke="{edge}" stroke-width="{f(size * 0.055)}"')
        + stitch(
            f"M{f(pad * 2.1)} {f(pad * 1.5)}"
            f"h{f(size - pad * 4.2)}"
            f"a{f(size * 0.14)} {f(size * 0.14)} 0 0 1 {f(size * 0.14)} "
            f"{f(size * 0.14)}"
            f"v{f(size - pad * 3.0 - size * 0.28)}"
            f"a{f(size * 0.14)} {f(size * 0.14)} 0 0 1 {f(-size * 0.14)} "
            f"{f(size * 0.14)}"
            f"h{f(-(size - pad * 4.2))}"
            f"a{f(size * 0.14)} {f(size * 0.14)} 0 0 1 {f(-size * 0.14)} "
            f"{f(-size * 0.14)}"
            f"v{f(-(size - pad * 3.0 - size * 0.28))}"
            f"a{f(size * 0.14)} {f(size * 0.14)} 0 0 1 {f(size * 0.14)} "
            f"{f(-size * 0.14)}z",
            edge, size * 0.010, size * 0.035, size * 0.030, 0.55,
        )
    )


def build_badge_quiz(w: float, h: float) -> str:
    body = [
        badge_frame(w, "#F7BCD4", "#7B2A4E"),
        petal_ring(w * 0.50, h * 0.50, w * 0.16, w * 0.34, 12, "#E68CAE",
                   0.45),
        g_pothi(w * 0.50, h * 0.56, w * 0.62),
        flame(w * 0.50, h * 0.16, h * 0.17, "#E0567F", "#F7BCD4"),
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — quiz badge")


def build_badge_japa(w: float, h: float) -> str:
    body = [
        badge_frame(w, "#FBE3B0", "#8A5A2B"),
        g_mala(w * 0.50, h * 0.50, w * 0.86),
        lotus(w * 0.50, h * 0.60, w * 0.20, "#E0A63C", "#B8862F", 7, 160),
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — japa badge")


def build_badge_streak(w: float, h: float) -> str:
    ticks = "".join(
        f'<rect x="{f(w * (0.28 + 0.11 * i))}" y="{f(h * 0.72)}" '
        f'width="{f(w * 0.07)}" height="{f(h * 0.09)}" '
        f'rx="{f(w * 0.018)}" fill="{TERRA_DARK if i < 3 else "#E8B9A6"}"/>'
        for i in range(4)
    )
    body = [
        badge_frame(w, "#F8C9A8", "#8E2E14"),
        flame(w * 0.50, h * 0.22, h * 0.44, "#D9542B", "#F6C25A"),
        ticks,
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — streak badge")


# =========================================================== backgrounds ====


def build_quiz_bg(w: float, h: float) -> str:
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" fill="url(#qbg)"/>',
        mandala(w * 0.50, h * 0.24, w * 0.52, TERRA, 0.075, 20),
        petal_ring(w * 0.50, h * 0.24, w * 0.54, w * 0.66, 28, GOLD, 0.10),
        f'<g opacity="0.5">'
        + lotus(w * 0.12, h * 1.02, w * 0.30, "#EBD3AE", "#DCBE93", 7, 160)
        + lotus(w * 0.88, h * 1.02, w * 0.30, "#EBD3AE", "#DCBE93", 7, 160)
        + "</g>",
        stitch(
            f"M0 {f(h * 0.62)}C{f(w * 0.35)} {f(h * 0.56)} {f(w * 0.70)} "
            f"{f(h * 0.66)} {f(w)} {f(h * 0.60)}",
            GOLD, w * 0.004, w * 0.028, w * 0.022, 0.55,
        ),
        stitch(
            f"M0 {f(h * 0.70)}C{f(w * 0.35)} {f(h * 0.64)} {f(w * 0.70)} "
            f"{f(h * 0.74)} {f(w)} {f(h * 0.68)}",
            TERRA, w * 0.003, w * 0.022, w * 0.020, 0.30,
        ),
    ]
    d = defs(lin3("qbg", "#FDF8F5", "#F7ECDC", "#F1D9B9", 110))
    return svg(w, h, "".join(body), d, "Aradhya — quiz background")


def build_quote_bg(w: float, h: float) -> str:
    blobs = "".join(
        f'<ellipse cx="{f(w * cx)}" cy="{f(h * cy)}" rx="{f(w * rx)}" '
        f'ry="{f(h * ry)}" fill="{c}" opacity="{f(op)}"/>'
        for cx, cy, rx, ry, c, op in (
            (0.18, 0.22, 0.30, 0.42, "#F3E3C6", 0.55),
            (0.78, 0.30, 0.28, 0.40, "#F6E9D2", 0.60),
            (0.50, 0.84, 0.42, 0.34, "#EFDCBB", 0.45),
        )
    )
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" fill="#F6E8CC"/>',
        blobs,
        petal_ring(w * 0.06, h * 0.08, w * 0.03, w * 0.10, 8, GOLD, 0.20),
        petal_ring(w * 0.94, h * 0.92, w * 0.03, w * 0.10, 8, GOLD, 0.20),
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — quote paper")


def build_pan(w: float, h: float) -> str:
    """Panchang tile: an almanac page under a rising sun."""
    cells = []
    palette = ["#E4B33C", "#D9703C", "#EFD9AE", "#C4553A", "#E9C98A"]
    for r in range(4):
        for c in range(5):
            cells.append(
                f'<rect x="{f(w * (0.20 + c * 0.125))}" '
                f'y="{f(h * (0.46 + r * 0.115))}" width="{f(w * 0.10)}" '
                f'height="{f(h * 0.09)}" rx="{f(w * 0.014)}" '
                f'fill="{palette[(r * 5 + c) % 5]}"/>'
            )
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" rx="{f(w * 0.18)}" '
        f'fill="#F6E4C4"/>',
        f'<circle cx="{f(w * 0.50)}" cy="{f(h * 0.30)}" r="{f(w * 0.16)}" '
        f'fill="#E8B33C"/>',
        petal_ring(w * 0.50, h * 0.30, w * 0.17, w * 0.26, 12, "#E8B33C",
                   0.75),
        rrect(w * 0.14, h * 0.30, w * 0.72, h * 0.58, w * 0.07, "#FBF2E0"),
        rrect(w * 0.14, h * 0.30, w * 0.72, h * 0.13, w * 0.07, TERRA),
        f'<circle cx="{f(w * 0.50)}" cy="{f(h * 0.245)}" '
        f'r="{f(w * 0.055)}" fill="none" stroke="{GOLD}" '
        f'stroke-width="{f(w * 0.028)}"/>',
        "".join(cells),
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — panchang tile")


def build_hor(w: float, h: float) -> str:
    """Zodiac wheel: twelve rashi houses around a gold centre."""
    cx, cy, r = w * 0.50, h * 0.50, w * 0.46
    secs = []
    for k in range(12):
        a0 = math.radians(360.0 * k / 12 - 90)
        a1 = math.radians(360.0 * (k + 1) / 12 - 90)
        x0, y0 = cx + math.cos(a0) * r, cy + math.sin(a0) * r
        x1, y1 = cx + math.cos(a1) * r, cy + math.sin(a1) * r
        fill = "#4A5A8C" if k % 2 == 0 else "#B8452E"
        secs.append(
            f'<path d="M{f(cx)} {f(cy)}L{f(x0)} {f(y0)}'
            f'A{f(r)} {f(r)} 0 0 1 {f(x1)} {f(y1)}z" fill="{fill}"/>'
        )
        am = (a0 + a1) / 2
        mx, my = cx + math.cos(am) * r * 0.72, cy + math.sin(am) * r * 0.72
        secs.append(
            f'<circle cx="{f(mx)}" cy="{f(my)}" r="{f(r * 0.075)}" '
            f'fill="{GOLD_PALE}" opacity="0.9"/>'
        )
    body = [
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 1.06)}" '
        f'fill="#F3E4C6"/>',
        "".join(secs),
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.44)}" '
        f'fill="#F3E4C6"/>',
        petal_ring(cx, cy, r * 0.16, r * 0.42, 8, "#B8452E", 0.85),
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.13)}" '
        f'fill="{GOLD_BRIGHT}"/>',
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="none" '
        f'stroke="{TERRA_DARK}" stroke-width="{f(w * 0.030)}"/>',
        f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r * 0.44)}" fill="none" '
        f'stroke="{TERRA_DARK}" stroke-width="{f(w * 0.018)}"/>',
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — zodiac wheel")


# ================================================================= brand ====


def brand_mark(cx: float, cy: float, s: float, shadow: bool = True) -> str:
    """The Aradhya mark: one brush stroke that reads as flame and as petal,
    carrying the stitched line that runs through the whole identity."""
    outer = (
        f"M{f(cx - s * 0.30)} {f(cy + s * 0.42)}"
        f"C{f(cx - s * 0.40)} {f(cy - s * 0.02)} {f(cx - s * 0.14)} "
        f"{f(cy - s * 0.30)} {f(cx)} {f(cy - s * 0.50)}"
        f"C{f(cx + s * 0.14)} {f(cy - s * 0.30)} {f(cx + s * 0.40)} "
        f"{f(cy - s * 0.02)} {f(cx + s * 0.30)} {f(cy + s * 0.42)}"
    )
    inner = (
        f"M{f(cx - s * 0.13)} {f(cy + s * 0.40)}"
        f"C{f(cx - s * 0.19)} {f(cy + s * 0.12)} {f(cx - s * 0.06)} "
        f"{f(cy - s * 0.04)} {f(cx)} {f(cy - s * 0.16)}"
        f"C{f(cx + s * 0.06)} {f(cy - s * 0.04)} {f(cx + s * 0.19)} "
        f"{f(cy + s * 0.12)} {f(cx + s * 0.13)} {f(cy + s * 0.40)}"
    )
    base = (
        f"M{f(cx - s * 0.34)} {f(cy + s * 0.46)}"
        f"Q{f(cx)} {f(cy + s * 0.62)} {f(cx + s * 0.34)} {f(cy + s * 0.46)}"
    )
    sw_o, sw_i = s * 0.155, s * 0.085
    out = []
    if shadow:
        out.append(
            f'<g transform="translate({f(s * 0.022)} {f(s * 0.026)})" '
            f'stroke="{TERRA_DARK}" fill="none" stroke-linecap="round">'
            f'<path d="{outer}" stroke-width="{f(sw_o)}"/>'
            f'<path d="{inner}" stroke-width="{f(sw_i)}"/>'
            f'<path d="{base}" stroke-width="{f(sw_i)}"/>'
            f"</g>"
        )
    out.append(
        f'<g stroke="{TERRA}" fill="none" stroke-linecap="round">'
        f'<path d="{outer}" stroke-width="{f(sw_o)}"/>'
        f'<path d="{inner}" stroke-width="{f(sw_i)}"/>'
        f'<path d="{base}" stroke-width="{f(sw_i)}"/>'
        f"</g>"
    )
    out.append(stitch(outer, "#FBE9C8", s * 0.017, s * 0.055, s * 0.042, 0.95))
    out.append(stitch(inner, "#FBE9C8", s * 0.012, s * 0.040, s * 0.032, 0.9))
    out.append(
        f'<circle cx="{f(cx)}" cy="{f(cy - s * 0.62)}" r="{f(s * 0.072)}" '
        f'fill="{TERRA}"/>'
        f'<circle cx="{f(cx)}" cy="{f(cy - s * 0.62)}" r="{f(s * 0.030)}" '
        f'fill="none" stroke="#FBE9C8" stroke-width="{f(s * 0.014)}" '
        f'stroke-dasharray="{f(s * 0.030)} {f(s * 0.024)}"/>'
    )
    return "".join(out)


def build_logo(w: float, h: float) -> str:
    return svg(w, h, brand_mark(w * 0.50, h * 0.52, w * 0.62), defs(),
               "Aradhya — logo")


def build_icon(w: float, h: float) -> str:
    body = [
        f'<rect width="{f(w)}" height="{f(h)}" fill="#FBEFDD"/>',
        petal_ring(w * 0.50, h * 0.50, w * 0.40, w * 0.52, 24, GOLD, 0.22),
        brand_mark(w * 0.50, h * 0.52, w * 0.50),
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — app icon")


def build_icon_foreground(w: float, h: float) -> str:
    # Adaptive icons crop to the middle ~66%; keep the mark inside that.
    return svg(w, h, brand_mark(w * 0.50, h * 0.50, w * 0.36), defs(),
               "Aradhya — adaptive foreground")


def build_lotus(w: float, h: float) -> str:
    cx = w * 0.50
    body = [
        petal_ring(cx, h * 0.56, w * 0.20, w * 0.44, 16, "#F0C6B4", 0.55),
        lotus(cx, h * 0.74, w * 0.40, "#D8567A", ROSE, 9, 168),
        lotus(cx, h * 0.74, w * 0.24, "#F2A0B6", "#D8567A", 5, 130),
        f'<ellipse cx="{f(cx)}" cy="{f(h * 0.745)}" rx="{f(w * 0.075)}" '
        f'ry="{f(w * 0.045)}" fill="{GOLD_BRIGHT}"/>',
        f'<path d="M{f(cx - w * 0.30)} {f(h * 0.80)}'
        f'Q{f(cx)} {f(h * 0.86)} {f(cx + w * 0.30)} {f(h * 0.80)}" '
        f'fill="none" stroke="{GREEN_LT}" stroke-width="{f(w * 0.022)}" '
        f'stroke-linecap="round"/>',
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — lotus")


def build_currency(w: float, h: float) -> str:
    """Kamal, the app's points token (the currency was renamed from Chandan)."""
    cx, cy = w * 0.50, h * 0.56
    body = [
        g_coin(cx - w * 0.20, cy + h * 0.10, w * 0.34),
        g_coin(cx + w * 0.20, cy + h * 0.10, w * 0.34),
        g_coin(cx, cy + h * 0.02, w * 0.40),
        lotus(cx, cy + h * 0.06, h * 0.42, "#E0708F", ROSE, 7, 158),
        f'<ellipse cx="{f(cx)}" cy="{f(cy + h * 0.06)}" '
        f'rx="{f(w * 0.045)}" ry="{f(h * 0.035)}" fill="{GOLD_BRIGHT}"/>',
    ]
    return svg(w, h, "".join(body), defs(), "Aradhya — Kamal token")


# ================================================================ registry ==

def _deity_specs() -> list[dict]:
    out = []
    for slug in DEITIES:
        out.append(dict(
            id=f"deity_{slug}", target=f"assets/images/{slug}.png",
            category="deity", subject=slug,
            build=lambda w, h, s=slug: build_deity(s, w, h),
        ))
        out.append(dict(
            id=f"deity_portrait_{slug}", target=f"assets/images/p{slug}.png",
            category="deity_portrait", subject=slug,
            build=lambda w, h, s=slug: build_portrait(s, w, h),
        ))
    return out


SPECS: list[dict] = _deity_specs() + [
    dict(id="deity_portrait_other", target="assets/images/pother.png",
         category="deity_portrait", subject="other",
         build=build_portrait_other),
    # emotions
    *[dict(id=f"emotion_{e}", target=f"assets/images/{e}.png",
           category="emotion", subject=e,
           build=lambda w, h, e=e: build_emotion(e, w, h))
      for e in EMOTIONS],
    # scripture covers
    dict(id="scripture_cover_ramayana", target="assets/images/ramayana.jpg",
         category="scripture_cover", subject="ramayana",
         build=build_cover_ramayana),
    dict(id="scripture_cover_bhagavadgita",
         target="assets/images/bhagavadgita.jpg",
         category="scripture_cover", subject="bhagavadgita",
         build=build_cover_gita),
    dict(id="scripture_cover_mahabharata",
         target="assets/images/mahabharata.jpg",
         category="scripture_cover", subject="mahabharata",
         build=build_cover_mahabharata),
    dict(id="scripture_cover_upanishads",
         target="assets/images/upanishads.jpg",
         category="scripture_cover", subject="upanishads",
         build=build_cover_upanishads),
    dict(id="scripture_cover_aartis", target="assets/images/aartis.jpg",
         category="scripture_cover", subject="aartis",
         build=build_cover_aartis),
    dict(id="scripture_cover_mantras", target="assets/images/mantras.jpg",
         category="scripture_cover", subject="mantras",
         build=build_cover_mantras),
    # puja items
    dict(id="puja_item_bhog", target="assets/images/bhog.png",
         category="puja_item", subject="bhog", build=build_bhog),
    dict(id="puja_item_ladoo", target="assets/images/ladoo.png",
         category="puja_item", subject="ladoo", build=build_ladoo),
    dict(id="puja_item_pladoo", target="assets/images/pladoo.png",
         category="puja_item", subject="pladoo", build=build_pladoo),
    dict(id="puja_item_ondiya", target="assets/images/ondiya.png",
         category="puja_item", subject="ondiya",
         build=lambda w, h: build_diya(w, h, True)),
    dict(id="puja_item_offdiya", target="assets/images/offdiya.png",
         category="puja_item", subject="offdiya",
         build=lambda w, h: build_diya(w, h, False)),
    dict(id="puja_item_vitual", target="assets/images/vitual.png",
         category="puja_item", subject="vitual", build=build_virtual_puja),
    # badges
    dict(id="badge_quiz_badge", target="assets/images/quiz_badge.png",
         category="badge", subject="quiz_badge", build=build_badge_quiz),
    dict(id="badge_japa_badge", target="assets/images/japa_badge.png",
         category="badge", subject="japa_badge", build=build_badge_japa),
    dict(id="badge_streak_badge", target="assets/images/streak_badge.png",
         category="badge", subject="streak_badge", build=build_badge_streak),
    # backgrounds
    dict(id="background_quiz_bg", target="assets/images/quiz_bg.jpg",
         category="background", subject="quiz_bg", build=build_quiz_bg),
    dict(id="background_quote_bg", target="assets/images/quote_bg.png",
         category="background", subject="quote_bg", build=build_quote_bg),
    dict(id="background_pan", target="assets/images/pan.png",
         category="background", subject="pan", build=build_pan),
    # brand
    dict(id="brand_hor", target="assets/images/hor.png",
         category="brand", subject="hor", build=build_hor),
    dict(id="brand_logo", target="assets/images/logo.png",
         category="brand", subject="logo", build=build_logo),
    dict(id="brand_currency", target="assets/images/currency.png",
         category="brand", subject="currency", build=build_currency),
    dict(id="brand_icon", target="assets/icon/icon.png",
         category="brand", subject="icon", build=build_icon),
    dict(id="brand_icon_foreground", target="assets/icon/icon_foreground.png",
         category="brand", subject="icon_foreground",
         build=build_icon_foreground),
    dict(id="brand_lotus", target="assets/icon/lotus.png",
         category="brand", subject="lotus", build=build_lotus),
]


CATEGORY_ORDER = ["brand", "deity", "deity_portrait", "scripture_cover",
                  "emotion", "puja_item", "badge", "background"]
CATEGORY_TITLE = {
    "brand": "Brand & app icon",
    "deity": "Deity murtis (Mandir idol, transparent)",
    "deity_portrait": "Deity avatars (pickers, chips)",
    "scripture_cover": "Scripture covers",
    "emotion": "Story emotion banners",
    "puja_item": "Puja offerings",
    "badge": "Engage & Learn badges",
    "background": "Backgrounds & tiles",
}


def sheet(rows: list[dict]) -> str:
    """Self-contained contact sheet -- the SVGs are inlined, so it renders
    anywhere without a server or the asset files beside it."""
    by_cat: dict[str, list[dict]] = {}
    for r in rows:
        by_cat.setdefault(r["category"], []).append(r)

    out = [
        "<!doctype html><meta charset='utf-8'>",
        "<title>Aradhya — original art kit</title>",
        "<style>",
        "*{box-sizing:border-box}",
        "body{margin:0;padding:32px 28px 64px;background:#FDF8F5;",
        "color:#5C3B28;font:15px/1.5 'Inter',system-ui,sans-serif}",
        "h1{font:600 26px/1.25 Georgia,serif;color:#A73015;margin:0 0 6px}",
        ".sub{color:#8A6A55;margin:0 0 28px;max-width:70ch}",
        "h2{font:600 15px/1 Georgia,serif;color:#983A18;margin:34px 0 14px;",
        "padding-bottom:8px;border-bottom:1.5px dashed #C0A062}",
        ".grid{display:grid;gap:16px;",
        "grid-template-columns:repeat(auto-fill,minmax(160px,1fr))}",
        ".card{background:#fff;border:1px solid #EADFCF;border-radius:14px;",
        "padding:10px;box-shadow:0 1px 3px rgba(92,59,40,.08)}",
        ".art{display:flex;align-items:center;justify-content:center;",
        "height:150px;border-radius:9px;overflow:hidden;",
        "background:repeating-conic-gradient(#F6EFE6 0% 25%,#FFF 0% 50%)",
        " 0 0/16px 16px}",
        ".art svg{max-width:100%;max-height:100%;height:auto;width:auto}",
        ".n{margin:9px 2px 0;font:600 12px/1.3 'Inter',sans-serif}",
        ".t{margin:2px;font:11px/1.35 ui-monospace,monospace;color:#9A8571;",
        "word-break:break-all}",
        "</style>",
        "<h1>Aradhya — original art kit</h1>",
        f"<p class='sub'>{len(rows)} original SVGs, one per row of "
        "assets/manifest.json, drawn to replace the "
        "PLACEHOLDER-ISHVARVAANI art that <code>build.py --strict</code> "
        "refuses to ship. Checkerboard = transparent. Each caption gives the "
        "asset slot it replaces.</p>",
    ]
    for cat in CATEGORY_ORDER:
        items = by_cat.get(cat, [])
        if not items:
            continue
        out.append(f"<h2>{CATEGORY_TITLE[cat]} — {len(items)}</h2>")
        out.append("<div class='grid'>")
        for r in items:
            out.append(
                f"<div class='card'><div class='art'>{r['svg']}</div>"
                f"<p class='n'>{r['subject']}</p>"
                f"<p class='t'>{r['target']}</p></div>"
            )
        out.append("</div>")
    return "\n".join(out)


def main() -> int:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    dims = {a["path"]: (a["w"], a["h"]) for a in manifest["assets"]}

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rows: list[dict] = []
    missing: list[str] = []

    for spec in SPECS:
        target = spec["target"]
        if target not in dims:
            missing.append(target)
            continue
        w, h = dims[target]
        if not w or not h:
            w, h = 1024, 1024
        markup = spec["build"](float(w), float(h))
        name = Path(target).stem + ".svg"
        (OUT_DIR / name).write_text(markup, encoding="utf-8")
        rows.append(dict(
            id=spec["id"], svg_path=f"assets/art/{name}", target=target,
            category=spec["category"], subject=spec["subject"],
            w=w, h=h, bytes=len(markup.encode("utf-8")), svg=markup,
        ))

    (OUT_DIR / "index.html").write_text(sheet(rows), encoding="utf-8")

    prov = {
        "_comment": (
            "Provenance for Aradhya's own artwork. These SVGs replace the "
            "PLACEHOLDER-ISHVARVAANI rows in assets/manifest.json. They are "
            "composed by a script in this repo, not generated by an image "
            "model and not derived from any third-party artwork, so there is "
            "no upstream licence to carry. Regenerate with "
            "`py -m content.tools.gen_svg_art`."
        ),
        "generator": GENERATOR,
        "generator_kind": "deterministic vector composition (no image model)",
        "license": ART_LICENSE,
        "artist": ART_ARTIST,
        "assets": [
            {k: r[k] for k in
             ("id", "svg_path", "target", "category", "subject", "w", "h",
              "bytes")}
            for r in rows
        ],
    }
    (OUT_DIR / "provenance.json").write_text(
        json.dumps(prov, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )

    covered = {r["target"] for r in rows}
    uncovered = [a["path"] for a in manifest["assets"]
                 if a["path"] not in covered]

    print(f"wrote {len(rows)} SVGs to assets/art/")
    for cat in CATEGORY_ORDER:
        n = sum(1 for r in rows if r["category"] == cat)
        if n:
            print(f"  {cat:<16} {n}")
    total = sum(r["bytes"] for r in rows)
    print(f"  total {total / 1024:.0f} KB  "
          f"(the placeholders they replace are ~9 MB)")
    print("  contact sheet: assets/art/index.html")
    print("  provenance:    assets/art/provenance.json")
    if missing:
        print(f"WARNING: {len(missing)} specs had no manifest row: {missing}")
    if uncovered:
        print(f"WARNING: {len(uncovered)} manifest rows have no art yet: "
              f"{uncovered}")
    else:
        print("every manifest row now has an original SVG")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
