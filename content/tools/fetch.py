"""Stage 1b — download public-domain source texts into content/raw/.

    py -m content.tools.fetch --list
    py -m content.tools.fetch --slug ganguli-mahabharata
    py -m content.tools.fetch --all --verify

`raw/` is gitignored: the texts are large and freely re-downloadable. What IS
committed is the sha256 recorded back into `content/sources/registry.jsonl`, so
a build is reproducible without a hundred megabytes of scans in git history —
and so a source silently changing under us is detectable.

Refuses any URL whose domain appears in `content/sources/excluded.jsonl`. That
list is not advisory: vedabase.io is under active copyright and drikpanchang
forbids scraping, and both are named repeatedly in the reference document, so
the refusal is enforced in code rather than left to whoever is running the tool.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import (  # noqa: E402
    RAW_DIR, REPO_ROOT, SOURCES_DIR, excluded_domains, read_jsonl,
)

USER_AGENT = ("AradhyaContentPipeline/1.0 "
              "(offline Hindu-spirituality app; contact: sumerudigitalsm@gmail.com)")
CHUNK = 1 << 16


def registry_path() -> Path:
    return SOURCES_DIR / "registry.jsonl"


def load_registry() -> list[dict]:
    return [o for _l, o in read_jsonl(registry_path())]


def save_registry(rows: list[dict]) -> None:
    with registry_path().open("w", encoding="utf-8", newline="\n") as fh:
        for r in rows:
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")


def blocked(url: str) -> str | None:
    """Reason this URL must not be fetched, or None."""
    if not url:
        return "no URL"
    host = (urllib.parse.urlparse(url).hostname or "").lower()
    for domain, reason in excluded_domains().items():
        bare = domain.lstrip("*.").lower()
        if bare and (host == bare or host.endswith("." + bare)):
            return f"{domain} ({reason})"
    return None


def sha256_of(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        while chunk := fh.read(CHUNK):
            h.update(chunk)
    return f"sha256:{h.hexdigest()}"


def dest_for(slug: str, url: str) -> Path:
    suffix = Path(urllib.parse.urlparse(url).path).suffix or ".txt"
    return RAW_DIR / f"{slug}{suffix}"


def fetch_one(row: dict, *, force: bool = False, timeout: int = 120) -> str:
    slug, url = row["slug"], row.get("source_url") or ""

    why = blocked(url)
    if why:
        return f"REFUSED  {slug:<28} excluded domain: {why}"

    if row.get("source_type") == "reference" and "archive.org" not in url:
        # Reference sources are consulted by a human, not bulk-downloaded.
        # Pulling gitasupersite or Wikipedia wholesale is exactly the thing the
        # sourcing rules forbid.
        return f"skip     {slug:<28} reference-only source, not for bulk download"

    dest = dest_for(slug, url)
    if dest.exists() and not force:
        digest = sha256_of(dest)
        if digest == row.get("checksum"):
            return f"cached   {slug:<28} {dest.name} ({dest.stat().st_size:,} B)"
        return (f"CHANGED  {slug:<28} on-disk checksum differs from the "
                f"registry — re-run with --force to accept")

    RAW_DIR.mkdir(parents=True, exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp, \
                dest.open("wb") as out:
            while chunk := resp.read(CHUNK):
                out.write(chunk)
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        if dest.exists():
            dest.unlink()
        return f"FAILED   {slug:<28} {type(e).__name__}: {e}"

    row["checksum"] = sha256_of(dest)
    row["retrieved_at"] = __import__("time").strftime("%Y-%m-%d")
    return f"fetched  {slug:<28} {dest.name} ({dest.stat().st_size:,} B)"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="Download public-domain sources.")
    ap.add_argument("--slug", help="fetch a single registry entry")
    ap.add_argument("--all", action="store_true", help="fetch every primary source")
    ap.add_argument("--list", action="store_true", help="show what would be fetched")
    ap.add_argument("--verify", action="store_true",
                    help="re-check on-disk checksums against the registry")
    ap.add_argument("--force", action="store_true", help="re-download and re-stamp")
    args = ap.parse_args(argv)

    rows = load_registry()
    by_slug = {r["slug"]: r for r in rows}

    if args.list:
        print(f"{'SLUG':<28}{'TYPE':<11}{'STATUS':<10}URL")
        for r in rows:
            url = r.get("source_url") or ""
            why = blocked(url)
            status = "EXCLUDED" if why else (
                "cached" if dest_for(r["slug"], url).exists() else "not fetched")
            print(f"{r['slug']:<28}{r.get('source_type', ''):<11}{status:<10}{url[:56]}")
        return 0

    if args.verify:
        bad = 0
        for r in rows:
            dest = dest_for(r["slug"], r.get("source_url") or "")
            if not dest.exists():
                continue
            digest = sha256_of(dest)
            ok = digest == r.get("checksum")
            if not ok:
                bad += 1
            print(f"{'ok  ' if ok else 'DIFF'} {r['slug']:<28} {digest[:20]}…")
        print(f"\n{bad} mismatch(es)")
        return 1 if bad else 0

    if args.slug:
        row = by_slug.get(args.slug)
        if not row:
            print(f"no such source: {args.slug}")
            return 1
        targets = [row]
    elif args.all:
        targets = [r for r in rows if r.get("source_type") in ("primary", "secondary")]
    else:
        ap.print_help()
        return 0

    for row in targets:
        print(fetch_one(row, force=args.force))

    save_registry(rows)
    print(f"\nregistry updated: {registry_path().relative_to(REPO_ROOT)}")
    print("raw/ is gitignored; the checksums make the build reproducible.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
