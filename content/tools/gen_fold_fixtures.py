"""Regenerate test/fixtures/fold_fixtures.json — the golden contract between
this pipeline's folding and the app's lib/features/search/search_fold.dart.

    py -m content.tools.gen_fold_fixtures      (from the repo root)

Run this ONLY when the folding rules intentionally change. The Dart golden test
(test/search_fold_test.dart) will then fail until search_fold.dart is updated to
match, which is exactly the intended safety net: the search index and the app
must never disagree about what a token folds to.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

# Allow `py content/tools/gen_fold_fixtures.py` as well as `-m`.
if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from content.tools.common import REPO_ROOT, fold_variants, slugify, tokenize  # noqa: E402

WORDS = [
    "Kṛṣṇa", "Krishna", "krsna", "कृष्ण",
    "Śiva", "Shiva", "शिव",
    "Viṣṇu", "Vishnu", "विष्णु",
    "Hanumān", "Hanuman", "हनुमान",
    "Brahmāstra", "Brahmastra", "ब्रह्मास्त्र",
    "Rāma", "Rama", "राम",
    "Gaṇeśa", "Ganesha", "गणेश",
    "Durgā", "दुर्गा", "Lakṣmī", "Sarasvatī",
    "Kurukṣetra", "Ayodhyā", "Naimiṣāraṇya",
    "Vasiṣṭha", "Viśvāmitra", "Aṅgiras", "Bṛhaspati",
    "Ṛgveda", "Upaniṣad", "Bhagavad Gītā", "Mahābhārata", "Rāmāyaṇa", "Purāṇa",
    "yajña", "mokṣa", "dharma", "karma",
    "Ekādaśī", "एकादशी", "Jyotiṣa", "Āyurveda", "Śūlba",
    "Trishula", "Triśūla", "OM", "ॐ",
    "Navi Mumbai", "Mumbai", "Kedārnāth", "Somnāth",
    "", "  ", "123", "a",
]

PHRASES = [
    "Kṛṣṇa and Arjuna at Kurukṣetra",
    "श्री हनुमान चालीसा",
    "The Song Celestial, tr. Sir Edwin Arnold",
]


def main() -> int:
    payload = {
        "_comment": (
            "Golden contract between content/tools/common.py (Python, build time) "
            "and lib/features/search/search_fold.dart (Dart, runtime). "
            "Regenerate with: py content/tools/gen_fold_fixtures.py "
            "Any change here means the search index and the app disagree."
        ),
        "foldVariants": {w: fold_variants(w) for w in WORDS},
        "slugify": {w: slugify(w) for w in WORDS if w.strip()},
        "tokenize": {p: tokenize(p) for p in PHRASES},
    }
    out = REPO_ROOT / "test" / "fixtures" / "fold_fixtures.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {out.relative_to(REPO_ROOT)} "
          f"({len(WORDS)} words, {len(PHRASES)} phrases)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
