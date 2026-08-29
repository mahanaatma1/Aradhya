# Curation gate (CM-03)

AI-generated content must never reach the database without a human reading
it against the source it cites. That rule is enforced physically, by folder,
not left as a habit someone has to remember:

```
content/curation/
  inbox/       AI-generated candidates. NEVER built from.
  approved/    a human read it against the cited source. Built from.
  rejected/    kept, with a reason, so the same bad row is not regenerated
```

- `content/tools/extract.py --promote` reads `approved/` only — `load_curation()`
  globs `curation/approved/*.jsonl` exclusively. A file sitting anywhere else
  in `curation/` is invisible to promotion, on purpose.
- `content/tools/validate.py`'s `check_curation_gate` fails the build if the
  three subfolders don't exist, or if a `.jsonl` file is left at the top
  level of `curation/` instead of inside one of them — that's the "invisible
  to promote" state, caught as a named error instead of a silent no-op.

## Workflow

1. A candidate entry (AI-drafted or hand-written) is written to
   `curation/inbox/<name>.jsonl`.
2. A human fetches the cited source and checks the claim against it directly
   — not against a secondary summary of the source.
3. If it holds up: move the file (or the entry) to `curation/approved/`.
   `extract.py --promote` will pick it up on the next run.
4. If it doesn't: move it to `curation/rejected/` with a one-line reason in
   the file or its filename, so nobody regenerates the same wrong claim
   later without knowing it was already tried and rejected.

A curation entry with no `sources` is refused by `extract.py` itself,
regardless of which folder it's in — see that file's own docstring.
