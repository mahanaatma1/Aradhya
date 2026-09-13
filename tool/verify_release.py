"""Release gate: run after `flutter build appbundle --release`.

Fails when the merged release manifest gained android.permission.INTERNET
(the app is offline by contract), when the AAB or the image assets exceed
their budgets, or when any manifest.json row lacks provenance.
"""
from __future__ import annotations

import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AAB_LIMIT_MB = 55
IMAGES_LIMIT_MB = 12
REQUIRED = ("license", "tool", "model", "prompt", "generated_at", "human_reviewed")


def fail(msg: str) -> None:
    print("FAIL:", msg)
    sys.exit(1)


def main() -> None:
    pattern = "build/app/intermediates/merged_manifest*/release/**/AndroidManifest.xml"
    manifests = glob.glob(os.path.join(ROOT, pattern), recursive=True)
    if not manifests:
        fail("no merged release manifest found - build the release first")
    for m in manifests:
        if re.search(r"android\.permission\.INTERNET", open(m, encoding="utf-8").read()):
            fail(f"INTERNET permission present in {m}")

    aabs = glob.glob(os.path.join(ROOT, "build/app/outputs/bundle/release/*.aab"))
    if aabs:
        mb = os.path.getsize(aabs[0]) / 1e6
        print(f"AAB {mb:.1f} MB")
        if mb > AAB_LIMIT_MB:
            fail(f"AAB {mb:.1f} MB exceeds {AAB_LIMIT_MB} MB")

    img_dir = os.path.join(ROOT, "assets/images")
    total = sum(
        os.path.getsize(os.path.join(img_dir, f))
        for f in os.listdir(img_dir)
        if os.path.isfile(os.path.join(img_dir, f))
    )
    print(f"images {total / 1e6:.1f} MB")
    if total / 1e6 > IMAGES_LIMIT_MB:
        fail(f"images {total / 1e6:.1f} MB exceed {IMAGES_LIMIT_MB} MB")

    mp = os.path.join(ROOT, "assets/manifest.json")
    if os.path.exists(mp):
        rows = json.load(open(mp, encoding="utf-8"))
        if isinstance(rows, dict):
            rows = rows.get("assets", rows.get("images", []))
        for r in rows:
            missing = [k for k in REQUIRED if k not in r]
            if missing or r.get("replace_before_ship"):
                fail(f"manifest row {r.get('id')} missing {missing} or still replace_before_ship")

    print("OK")


if __name__ == "__main__":
    main()
