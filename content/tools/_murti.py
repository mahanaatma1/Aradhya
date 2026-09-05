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
    """Bajubandh: a jewelled band lying across a limb pointing at (ax, ay)."""
    ang = math.degrees(math.atan2(ay - y, ax - x))
    return (
        f'<g transform="rotate({f(ang)} {f(x)} {f(y)})">'
        f'<rect x="{f(x - w * 0.22)}" y="{f(y - w * 0.62)}" '
        f'width="{f(w * 0.44)}" height="{f(w * 1.24)}" rx="{f(w * 0.14)}" '
        f'fill="{shade(gold, 0.80)}"/>'
        f'<rect x="{f(x - w * 0.15)}" y="{f(y - w * 0.60)}" '
        f'width="{f(w * 0.30)}" height="{f(w * 1.20)}" rx="{f(w * 0.12)}" '
        f'fill="{gold}"/>'
        f'<rect x="{f(x - w * 0.13)}" y="{f(y - w * 0.56)}" '
        f'width="{f(w * 0.09)}" height="{f(w * 1.12)}" rx="{f(w * 0.05)}" '
        f'fill="{tint(gold, 1.30)}" opacity="0.7"/>'
        f"</g>"
        + _jewel(x, y, w * 0.20)
    )


def _bangles(x: float, y: float, ax: float, ay: float, w: float,
             gold: str = GOLD) -> str:
    """Two thin kangan at the wrist rather than one thick cuff."""
    ang = math.degrees(math.atan2(ay - y, ax - x))
    dx = math.cos(math.radians(ang)) * w * 0.34
    dy = math.sin(math.radians(ang)) * w * 0.34
    bands = []
    for k in (0, 1):
        bx, by = x - dx * k, y - dy * k
        bands.append(
            f'<g transform="rotate({f(ang)} {f(bx)} {f(by)})">'
            f'<rect x="{f(bx - w * 0.075)}" y="{f(by - w * 0.60)}" '
            f'width="{f(w * 0.15)}" height="{f(w * 1.20)}" '
            f'rx="{f(w * 0.07)}" fill="{shade(gold, 0.82)}"/>'
            f'<rect x="{f(bx - w * 0.055)}" y="{f(by - w * 0.56)}" '
            f'width="{f(w * 0.11)}" height="{f(w * 1.12)}" '
            f'rx="{f(w * 0.055)}" fill="{gold}"/>'
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
    """One upturned sole, the way padmasana presents the feet."""
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
        + f'<ellipse cx="{f(x + s * 0.10)}" cy="{f(y + s * 0.02)}" '
          f'rx="{f(s * 0.58)}" ry="{f(s * 0.28)}" '
          f'fill="{tint(skin, 1.14)}" opacity="0.8"/>'
        + f'<g fill="{skin}" stroke="{shade(skin, 0.74)}" '
          f'stroke-width="{f(lw * 0.9)}">'
        + "".join(  # toes, largest inboard
            f'<ellipse cx="{f(x - s * (0.74 - 0.055 * k))}" '
            f'cy="{f(y - s * (0.26 - 0.14 * k))}" '
            f'rx="{f(s * (0.150 - 0.018 * k))}" '
            f'ry="{f(s * (0.122 - 0.014 * k))}"/>'
            for k in range(5)
        )
        + "</g>"
        + _ol(body, lw * 0.9, 0.16)
        + f'<circle cx="{f(x + s * 0.16)}" cy="{f(y + s * 0.02)}" '
          f'r="{f(s * 0.12)}" fill="{TERRA}" opacity="0.45"/>'
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
        lower = [
            ((cx + h * 0.152, y(0.362)), (cx + h * 0.234, y(0.470)),
             (cx + h * 0.112, y(0.336)), (cx + h * 0.092, y(0.312))),
            ((cx - h * 0.152, y(0.362)), (cx - h * 0.236, y(0.482)),
             (cx - h * 0.140, y(0.352)), (cx - h * 0.118, y(0.330))),
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

    # ---- what the hands hold
    if pose == "flute":
        parts.append(
            f'<g transform="rotate(-11 {f(cx)} {f(y(0.318))})">'
            + lit(
                f"M{f(cx - h * 0.158)} {f(y(0.304))}"
                f"h{f(h * 0.336)}v{f(h * 0.026)}h{f(-h * 0.336)}Z",
                "#DCB884", -h * 0.002, -h * 0.002, 0.78,
            )
            + f'<circle cx="{f(cx + h * 0.176)}" cy="{f(y(0.317))}" '
              f'r="{f(h * 0.014)}" fill="{shade("#DCB884", 0.84)}"/>'
            + "".join(
                f'<circle cx="{f(cx + h * dx)}" cy="{f(y(0.318))}" '
                f'r="{f(h * 0.007)}" fill="{BARK}"/>'
                for dx in (0.014, 0.058, 0.102, 0.146)
            )
            + f'<path d="M{f(cx - h * 0.150)} {f(y(0.306))}'
              f'h{f(h * 0.320)}" stroke="{tint("#DCB884", 1.25)}" '
              f'stroke-width="{f(h * 0.005)}" opacity="0.8"/>'
            + "</g>"
        )
    for i, (hx, hy) in enumerate(hand_pts):
        name = hands[i] if i < len(hands) else ""
        if name in TALL_ATTRS:
            # drawn first so the palm closes over the shaft; in a lower hand it
            # stands like a staff, rising past the shoulder
            if i < 2:
                parts.append(glyph(name, hx, hy - h * 0.255, h * 0.60))
            else:
                parts.append(glyph(name, hx, hy - h * 0.045, h * 0.50))
            parts.append(_hand(hx, hy, hand_r, skin, lw))
            continue
        parts.append(_hand(hx, hy, hand_r, skin, lw, open_palm=not name))
        if name:
            parts.append(
                glyph(name, hx, hy - h * 0.088,
                      h * (0.180 if i >= 2 else 0.170))
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
    """Gajamukha: domed skull, fanned ears, a modelled tapering trunk."""
    R = r * 1.14
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
        lit(ear, shade(skin, 0.93), -R * 0.03, -R * 0.03, 0.84)
        + f'<path d="{inner}" fill="{tint(skin, 1.10)}" opacity="0.85"/>'
        + f'<path d="{inner}" fill="none" stroke="{d}" '
          f'stroke-width="{f(lw * 1.2)}" opacity="0.4"/>'
        + f'<path d="{ear}" fill="none" stroke="{shade(GOLD, 0.82)}" '
          f'stroke-width="{f(R * 0.058)}" opacity="0.85"/>'
          f'<path d="{ear}" fill="none" stroke="{GOLD}" '
          f'stroke-width="{f(R * 0.036)}" opacity="0.95"/>'
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
        # trunk, curling to the viewer's left
        + _taper(
            [(cx + R * 0.04, cy + R * 0.44), (cx + R * 0.00, cy + R * 1.02),
             (cx - R * 0.22, cy + R * 1.44), (cx - R * 0.33, cy + R * 1.82),
             (cx - R * 0.12, cy + R * 2.00)],
            [R * 0.50, R * 0.43, R * 0.35, R * 0.26, R * 0.17], skin, 0.82,
        )
        + f'<g stroke="{d}" stroke-width="{f(lw * 1.4)}" opacity="0.32" '
          f'fill="none" stroke-linecap="round">'
          f'<path d="M{f(cx - R * 0.16)} {f(cy + R * 0.84)}'
          f'q{f(R * 0.20)} {f(R * 0.16)} {f(R * 0.38)} 0"/>'
          f'<path d="M{f(cx - R * 0.25)} {f(cy + R * 1.16)}'
          f'q{f(R * 0.18)} {f(R * 0.16)} {f(R * 0.34)} {f(-R * 0.02)}"/>'
          f'<path d="M{f(cx - R * 0.35)} {f(cy + R * 1.48)}'
          f'q{f(R * 0.14)} {f(R * 0.14)} {f(R * 0.26)} {f(-R * 0.04)}"/>'
          f"</g>"
        # tusks: the right one broken, as Ekadanta
        + lit(
            f"M{f(cx - R * 0.48)} {f(cy + R * 0.54)}"
            f"C{f(cx - R * 0.66)} {f(cy + R * 0.94)} {f(cx - R * 0.52)} "
            f"{f(cy + R * 1.20)} {f(cx - R * 0.44)} {f(cy + R * 1.24)}"
            f"C{f(cx - R * 0.28)} {f(cy + R * 0.94)} {f(cx - R * 0.28)} "
            f"{f(cy + R * 0.70)} {f(cx - R * 0.30)} {f(cy + R * 0.54)}Z",
            CREAM, -R * 0.02, -R * 0.02, 0.84,
        )
        + lit(
            f"M{f(cx + R * 0.48)} {f(cy + R * 0.54)}"
            f"C{f(cx + R * 0.60)} {f(cy + R * 0.76)} {f(cx + R * 0.56)} "
            f"{f(cy + R * 0.88)} {f(cx + R * 0.50)} {f(cy + R * 0.90)}"
            f"C{f(cx + R * 0.38)} {f(cy + R * 0.76)} {f(cx + R * 0.34)} "
            f"{f(cy + R * 0.66)} {f(cx + R * 0.32)} {f(cy + R * 0.54)}Z",
            CREAM, -R * 0.02, -R * 0.02, 0.84,
        )
        + _eye(cx - R * 0.40, cy + R * 0.06, R * 0.84, lw)
        + _eye(cx + R * 0.40, cy + R * 0.06, R * 0.84, lw)
        + _brow(cx - R * 0.40, cy - R * 0.20, R * 0.84, -1)
        + _brow(cx + R * 0.40, cy - R * 0.20, R * 0.84, 1)
        + _tilak(cx, cy - R * 0.54, R * 0.26)
        + _kundala(cx - R * 1.30, cy + R * 0.70, R * 0.26)
        + _kundala(cx + R * 1.30, cy + R * 0.70, R * 0.26)
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
