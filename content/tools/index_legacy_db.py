"""One-off: add the missing indexes to the bundled assets/db/content.sqlite.

    py -m content.tools.index_legacy_db

The shipped database has **zero** non-autoindex indexes. Two of them matter a
lot at the sizes involved:

    scripture_sections.book_id   27,890 rows -- every chapter open is a scan
    cities.name                   4,276 rows -- every keystroke in the birth-
                                                place picker is a scan

This CANNOT be done at runtime: the app opens the file with
`openReadOnlyDatabase`, so `CREATE INDEX` is impossible on device. It has to be
baked into the asset, which then needs a version bump so installed copies get
refreshed.

The script is idempotent (`IF NOT EXISTS`) and bumps `meta.content_version`
plus `ContentDatabase.assetVersion` together, so test/db_version_test.dart
stays green.
"""

from __future__ import annotations

import re
import sqlite3
import sys
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import LEGACY_DB, REPO_ROOT  # noqa: E402

DART_DB_FILE = REPO_ROOT / "lib" / "core" / "db" / "content_database.dart"

INDEXES = [
    # Chapter/verse paging: scripture_repository queries by book_id constantly.
    ("ix_sections_book",
     "CREATE INDEX IF NOT EXISTS ix_sections_book "
     "ON scripture_sections(book_id, order_no)"),
    # Birth-place picker.
    ("ix_cities_name",
     "CREATE INDEX IF NOT EXISTS ix_cities_name ON cities(name)"),
    # Book lists per scripture.
    ("ix_books_scripture",
     "CREATE INDEX IF NOT EXISTS ix_books_scripture "
     "ON scripture_books(scripture_id, order_no)"),
    # Deity filter chips on the devotional lists.
    ("ix_aartis_deity", "CREATE INDEX IF NOT EXISTS ix_aartis_deity ON aartis(deity)"),
    ("ix_chalisas_deity",
     "CREATE INDEX IF NOT EXISTS ix_chalisas_deity ON chalisas(deity)"),
    ("ix_mantras_deity",
     "CREATE INDEX IF NOT EXISTS ix_mantras_deity ON mantras(deity)"),
    # Temple directory filters.
    ("ix_temples_deity", "CREATE INDEX IF NOT EXISTS ix_temples_deity ON temples(deity_en)"),
    ("ix_temples_state", "CREATE INDEX IF NOT EXISTS ix_temples_state ON temples(state)"),
]


def bump(version: str) -> str:
    """0.4.0-devfixture-native -> 0.4.1-devfixture-native"""
    m = re.match(r"^(\d+)\.(\d+)\.(\d+)(.*)$", version)
    if not m:
        return version + "+indexed"
    major, minor, patch, suffix = m.groups()
    return f"{major}.{minor}.{int(patch) + 1}{suffix}"


def main() -> int:
    if not LEGACY_DB.exists():
        print(f"error: {LEGACY_DB} not found")
        return 1

    db = sqlite3.connect(LEGACY_DB)
    try:
        before = db.execute(
            "SELECT count(*) FROM sqlite_master WHERE type='index' "
            "AND name NOT LIKE 'sqlite_autoindex%'").fetchone()[0]

        tables = {r[0] for r in db.execute(
            "SELECT name FROM sqlite_master WHERE type='table'")}

        created = []
        for name, sql in INDEXES:
            table = sql.split(" ON ")[1].split("(")[0].strip()
            if table not in tables:
                print(f"  skip {name}: no table '{table}'")
                continue
            db.execute(sql)
            created.append(name)

        meta = dict(db.execute("SELECT key, value FROM meta"))
        old_version = meta.get("content_version", "0.4.0-devfixture-native")
        new_version = bump(old_version) if created else old_version

        if created:
            db.execute("INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)",
                       ("content_version", new_version))
            db.execute("INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)",
                       ("indexes_added", ",".join(created)))
        db.commit()

        # A WAL file cannot be opened read-only on device, and VACUUM keeps the
        # asset from growing after the index build.
        db.execute("PRAGMA journal_mode=DELETE")
        db.commit()
        db.isolation_level = None
        db.execute("VACUUM")

        ok = db.execute("PRAGMA integrity_check").fetchone()[0]
        after = db.execute(
            "SELECT count(*) FROM sqlite_master WHERE type='index' "
            "AND name NOT LIKE 'sqlite_autoindex%'").fetchone()[0]
    finally:
        db.close()

    if ok != "ok":
        print(f"integrity_check FAILED: {ok}")
        return 1

    # Keep the Dart const in step or db_version_test.dart goes red.
    if created and DART_DB_FILE.exists():
        src = DART_DB_FILE.read_text(encoding="utf-8")
        new_src = re.sub(
            r"(static const assetVersion\s*=\s*')[^']*(')",
            rf"\g<1>{new_version}\g<2>", src, count=1)
        if new_src != src:
            DART_DB_FILE.write_text(new_src, encoding="utf-8")
            print(f"  updated ContentDatabase.assetVersion -> {new_version}")

    size_mb = LEGACY_DB.stat().st_size / (1024 * 1024)
    print(f"\nindexes: {before} -> {after}  ({len(created)} created)")
    print(f"version: {old_version} -> {new_version}")
    print(f"size:    {size_mb:.2f} MB   integrity: {ok}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
