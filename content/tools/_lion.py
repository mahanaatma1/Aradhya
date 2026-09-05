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
        # mane: two courses, the outer darker
        + petal_ring(hx, hy, hr * 0.94, hr * 2.00, 15, dark, 0.95, 12.0, 0.40)
        + petal_ring(hx, hy, hr * 0.90, hr * 1.62, 13, "#CE8A38", 0.95, 0.0,
                     0.48)
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
