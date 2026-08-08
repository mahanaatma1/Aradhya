"""Generate / refresh assets/manifest.json.

    py -m content.tools.gen_asset_manifest

Why this exists: the bundled artwork is the app's top release blocker, and
until now the only record of that was a comment in lib/shared/reference_art.dart.
A comment cannot fail a build. This manifest can:

    validate.py  -> every image has a manifest row, every row has a licence,
                    every entities.image_asset resolves
    build.py --strict -> refuses to produce a release build while ANY row is
                    still flagged replace_before_ship

It also gives the art-replacement effort a worklist with exact pixel sizes.

Re-running preserves hand-edited fields (licence, artist, source_url, and the
replace_before_ship flag) and only refreshes the mechanical ones (bytes, w, h).
Clearing a flag is a human decision and must never be undone by a script.
"""

from __future__ import annotations

import json
import struct
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import REPO_ROOT  # noqa: E402

MANIFEST = REPO_ROOT / "assets" / "manifest.json"
IMAGE_DIRS = ["assets/images", "assets/icon"]
EXTS = {".png", ".jpg", ".jpeg", ".webp"}

# The bundled art was extracted from the third-party Ishvarvaani app as a
# development placeholder. reference_art.dart:4-6 flags it; this makes it data.
PLACEHOLDER_LICENSE = "PLACEHOLDER-ISHVARVAANI"


def image_size(path: Path) -> tuple[int | None, int | None]:
    """Read pixel dimensions from the file header. Avoids a Pillow dependency
    for what is a handful of bytes per format."""
    try:
        data = path.read_bytes()[:32]
    except OSError:
        return (None, None)

    if data[:8] == b"\x89PNG\r\n\x1a\n" and len(data) >= 24:
        w, h = struct.unpack(">II", data[16:24])
        return (w, h)

    if data[:2] == b"\xff\xd8":  # JPEG: walk the segment chain
        try:
            raw = path.read_bytes()
            i = 2
            while i < len(raw) - 9:
                if raw[i] != 0xFF:
                    i += 1
                    continue
                marker = raw[i + 1]
                if marker in (0xC0, 0xC1, 0xC2, 0xC3):
                    h, w = struct.unpack(">HH", raw[i + 5:i + 9])
                    return (w, h)
                seg = struct.unpack(">H", raw[i + 2:i + 4])[0]
                i += 2 + seg
        except (struct.error, IndexError):
            pass

    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return (None, None)  # several sub-formats; not worth parsing here

    return (None, None)


def categorise(name: str) -> tuple[str, str | None]:
    """(category, subject_slug) inferred from the filename convention."""
    stem = Path(name).stem.lower()

    emotions = {"anger", "faith", "fear", "joy", "love", "peace", "grief"}
    scriptures = {"bhagavadgita", "ramayana", "mahabharata", "upanishads",
                  "aartis", "mantras"}
    puja = {"bhog", "ladoo", "pladoo", "ondiya", "offdiya", "vitual", "diya"}
    badges = {"japa_badge", "quiz_badge", "streak_badge"}
    backgrounds = {"quiz_bg", "quote_bg", "pan", "pp_bg", "pt_bg", "wall"}
    brand = {"logo", "hor", "icon", "icon_foreground", "lotus", "currency",
             "mandala"}

    if stem in emotions:
        return ("emotion", stem)
    if stem in scriptures:
        return ("scripture_cover", stem)
    if stem in puja:
        return ("puja_item", stem)
    if stem in badges:
        return ("badge", stem)
    if stem in backgrounds:
        return ("background", stem)
    if stem in brand:
        return ("brand", stem)
    if stem.startswith("p") and len(stem) > 1:
        return ("deity_portrait", stem[1:])
    return ("deity", stem)


def main() -> int:
    existing: dict[str, dict] = {}
    if MANIFEST.exists():
        try:
            doc = json.loads(MANIFEST.read_text(encoding="utf-8"))
            existing = {a["path"]: a for a in doc.get("assets", [])}
        except (json.JSONDecodeError, KeyError):
            print("warning: existing manifest unreadable; regenerating")

    assets: list[dict] = []
    for d in IMAGE_DIRS:
        base = REPO_ROOT / d
        if not base.is_dir():
            continue
        for path in sorted(base.iterdir()):
            if path.suffix.lower() not in EXTS:
                continue
            rel = f"{d}/{path.name}"
            category, subject = categorise(path.name)
            w, h = image_size(path)

            prev = existing.get(rel, {})
            assets.append({
                "id": f"{category}_{subject or path.stem}".replace("-", "_"),
                "path": rel,
                "category": category,
                "subject_slug": subject,
                "w": w,
                "h": h,
                "bytes": path.stat().st_size,
                # Human-owned fields: never overwritten once set.
                "license": prev.get("license", PLACEHOLDER_LICENSE),
                "source_url": prev.get("source_url"),
                "artist": prev.get("artist"),
                "version": prev.get("version", 1),
                "replace_before_ship": prev.get(
                    "replace_before_ship",
                    prev.get("license", PLACEHOLDER_LICENSE) == PLACEHOLDER_LICENSE),
            })

    blocked = [a for a in assets if a["replace_before_ship"]]
    payload = {
        "_comment": (
            "Refresh with: py -m content.tools.gen_asset_manifest. "
            "Mechanical fields (w/h/bytes) are regenerated; license, artist, "
            "source_url and replace_before_ship are hand-owned and preserved. "
            "build.py --strict refuses a release while any row is still "
            "flagged replace_before_ship."
        ),
        "assets": assets,
    }
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8")

    by_cat: dict[str, int] = {}
    for a in assets:
        by_cat[a["category"]] = by_cat.get(a["category"], 0) + 1

    total_mb = sum(a["bytes"] for a in assets) / (1024 * 1024)
    print(f"wrote {MANIFEST.relative_to(REPO_ROOT)}: "
          f"{len(assets)} assets, {total_mb:.1f} MB")
    for cat, n in sorted(by_cat.items()):
        print(f"  {cat:<18} {n}")
    print(f"\n  RELEASE BLOCKED BY {len(blocked)} placeholder asset(s) "
          f"(build.py --strict will refuse)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
