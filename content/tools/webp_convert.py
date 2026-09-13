"""Convert assets/images/*.png|jpg to WebP within the size budget.

Full-body deity PNGs (1.4-1.9 MB each) become 1024 px lossy WebP with
alpha; portraits and small icons become 512 px; covers/banners keep their
aspect at <= 1280 px. Each converted row in assets/manifest.json is updated
(path, bytes, w, h) and the source file is removed, so nothing ships twice.

    py -m content.tools.webp_convert [--dry-run]
"""
from __future__ import annotations

import argparse
import json
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
IMG = os.path.join(ROOT, "assets", "images")
MANIFEST = os.path.join(ROOT, "assets", "manifest.json")


def target_for(stem: str, w: int, h: int) -> tuple[int, int]:
    """Max width, quality."""
    if stem.startswith("p") and w <= 600:
        return 512, 84  # portrait avatars
    if w >= 1200 and h >= 1200:
        return 1024, 82  # full-body deities, puja items
    if w > 1280:
        return 1280, 80  # covers and banners
    return w, 84


def convert(path: str, dry: bool) -> tuple[str, int, int, int]:
    stem, _ = os.path.splitext(os.path.basename(path))
    im = Image.open(path)
    w, h = im.size
    max_w, q = target_for(stem, w, h)
    if w > max_w:
        nh = round(h * max_w / w)
        im = im.resize((max_w, nh), Image.LANCZOS)
    has_alpha = im.mode in ("RGBA", "LA") or (im.mode == "P" and "transparency" in im.info)
    im = im.convert("RGBA" if has_alpha else "RGB")
    out = os.path.join(IMG, stem + ".webp")
    if not dry:
        im.save(out, "WEBP", quality=q, method=6, alpha_quality=90 if has_alpha else 100)
    size = os.path.getsize(out) if not dry else 0
    return out, im.size[0], im.size[1], size


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    manifest = json.load(open(MANIFEST, encoding="utf-8"))
    rows = manifest["assets"] if isinstance(manifest, dict) else manifest
    by_path = {r["path"].replace("\\", "/"): r for r in rows}

    before = after = 0
    for name in sorted(os.listdir(IMG)):
        if not name.lower().endswith((".png", ".jpg", ".jpeg")):
            continue
        src = os.path.join(IMG, name)
        before += os.path.getsize(src)
        out, w, h, size = convert(src, args.dry_run)
        after += size
        rel_src = f"assets/images/{name}"
        rel_out = f"assets/images/{os.path.basename(out)}"
        row = by_path.get(rel_src)
        if row is not None:
            row["path"] = rel_out
            row["w"], row["h"], row["bytes"] = w, h, size
        print(f"{name:>22} {os.path.getsize(src)/1e6:5.2f} MB -> {os.path.basename(out):>22} {size/1e6:5.2f} MB  {w}x{h}")
        if not args.dry_run:
            os.remove(src)

    if not args.dry_run:
        json.dump(manifest, open(MANIFEST, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    print(f"\ntotal {before/1e6:.1f} MB -> {after/1e6:.1f} MB")
    if after / 1e6 > 12:
        print("WARNING: images still exceed the 12 MB budget", file=sys.stderr)


if __name__ == "__main__":
    main()
