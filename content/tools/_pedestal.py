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
