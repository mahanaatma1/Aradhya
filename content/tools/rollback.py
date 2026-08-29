"""Stage 4b — restore assets from a retained build snapshot (CM-04).

    py -m content.tools.rollback --list          show retained snapshots
    py -m content.tools.rollback <stamp>         restore that snapshot
    py -m content.tools.rollback --previous      restore the one before CURRENT

A bad build is one command to undo. `build.py` retains every build's key
artifacts under `content/builds/<date>_<sha>/` (see `write_build_snapshot`);
this reads one of those directories back into place.

Restoring `gyan.sqlite` alone is not enough on its own -- `manifest.json`
must move with it (an asset a newer manifest expects but an older DB doesn't
reference, or vice versa, is exactly the kind of mismatch a snapshot exists
to prevent), so this always restores the matched set together, never a
single file from a snapshot.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import CONTENT_DIR, GYAN_DB, REPO_ROOT  # noqa: E402

BUILDS_DIR = REPO_ROOT / "content" / "builds"
BUILDS_CURRENT_FILE = BUILDS_DIR / "CURRENT"

# Where each retained file goes back to.
_RESTORE_TARGETS = {
    "gyan.sqlite": GYAN_DB,
    "manifest.json": REPO_ROOT / "assets" / "manifest.json",
    "content_snapshot.json": CONTENT_DIR / "build" / "content_snapshot.json",
    "report.html": CONTENT_DIR / "build" / "report.html",
}


def list_snapshots() -> list[str]:
    if not BUILDS_DIR.is_dir():
        return []
    return sorted(p.name for p in BUILDS_DIR.iterdir()
                  if p.is_dir() and (p / "checksums.json").exists())


def _verify(snap_dir: Path) -> bool:
    """Refuses to restore from a snapshot whose files don't match their own
    recorded checksum -- a corrupted or partially-written snapshot must not
    silently become the new live state."""
    import hashlib
    data = json.loads((snap_dir / "checksums.json").read_text(encoding="utf-8"))
    for name, expected in data.get("sha256", {}).items():
        f = snap_dir / name
        if not f.exists():
            print(f"  MISSING: {name}")
            return False
        h = hashlib.sha256()
        with f.open("rb") as fh:
            for chunk in iter(lambda: fh.read(1 << 20), b""):
                h.update(chunk)
        if h.hexdigest() != expected:
            print(f"  CHECKSUM MISMATCH: {name}")
            return False
    return True


def restore(stamp: str) -> int:
    snap_dir = BUILDS_DIR / stamp
    if not snap_dir.is_dir():
        print(f"error: no snapshot at {snap_dir.relative_to(REPO_ROOT)}")
        print(f"available: {', '.join(list_snapshots()) or '(none)'}")
        return 1
    checksums = snap_dir / "checksums.json"
    if not checksums.exists():
        print(f"error: {snap_dir.relative_to(REPO_ROOT)} has no checksums.json "
              "-- not a build.py snapshot")
        return 1

    print(f"verifying {stamp}...")
    if not _verify(snap_dir):
        print("refusing to restore: snapshot failed its own checksum")
        return 1

    import shutil
    restored = []
    for name, dst in _RESTORE_TARGETS.items():
        src = snap_dir / name
        if not src.exists():
            continue  # this snapshot's build didn't produce this file
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        restored.append(name)

    print(f"restored: {', '.join(restored)}")
    print(f"from {snap_dir.relative_to(REPO_ROOT)}")
    print("\nRebuild the Dart asset version stamp still requires a real "
          "build.py run against this content -- rollback restores the "
          "SHIPPED artifacts, it does not re-run the pipeline.")
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("stamp", nargs="?", help="snapshot directory name, e.g. 2026-08-29_a1b2c3d")
    ap.add_argument("--list", action="store_true", help="show retained snapshots")
    ap.add_argument("--previous", action="store_true",
                     help="restore the snapshot named in content/builds/CURRENT")
    args = ap.parse_args(argv)

    if args.list:
        snaps = list_snapshots()
        if not snaps:
            print("no retained snapshots yet -- run content.tools.build first")
            return 0
        current = (BUILDS_CURRENT_FILE.read_text(encoding="utf-8").strip()
                   if BUILDS_CURRENT_FILE.exists() else None)
        for s in snaps:
            mark = "  <- CURRENT" if s == current else ""
            print(f"  {s}{mark}")
        return 0

    if args.previous:
        if not BUILDS_CURRENT_FILE.exists():
            print("error: content/builds/CURRENT does not exist yet")
            return 1
        return restore(BUILDS_CURRENT_FILE.read_text(encoding="utf-8").strip())

    if not args.stamp:
        ap.print_help()
        return 1
    return restore(args.stamp)


if __name__ == "__main__":
    raise SystemExit(main())
