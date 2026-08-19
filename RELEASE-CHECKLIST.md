# Release checklist

Run top to bottom. Anything unticked is a blocker unless it says otherwise.

---

## 1. The content DB and the index must be rebuilt together

**This is the one that will bite.** The search index and the related-content
edges live in `gyan.sqlite`, but roughly half of what they point at lives in
`content.sqlite`. Rebuild one without the other and every legacy search result
deep-links to the wrong row — silently, with no error anywhere.

```powershell
py -m content.tools.validate --strict
py -m content.tools.build --strict
flutter test
```

- [ ] `validate --strict` exits 0
- [ ] `build --strict` completes — it refuses unverified content and any asset
      still flagged `replace_before_ship`
- [ ] `gyan.meta.indexed_content_version` equals `content.sqlite`'s
      `meta.content_version` (build fails on mismatch; check the log said so)
- [ ] `test/db_version_test.dart` passes — proves both DBs agree with the Dart
      constants that gate the asset copy

> If `content.sqlite` changed at all, `gyan.sqlite` **must** be rebuilt. There
> is no partial path.

## 2. Automated gates

- [ ] `flutter analyze lib/` clean
- [ ] `flutter test` green
- [ ] `test/gyan_modules_test.dart` — every `GyanModule.route` resolves, and no
      module marked `shipped: false` has a live route
- [ ] `test/search_fold_test.dart` — the Dart fold still matches `common.py`
- [ ] `content/build/report.html` shows zero broken relations, zero duplicate
      aliases, zero manifest-missing assets

## 3. Things only a running app can prove

`sweph` falls back to a lower-precision ephemeris under `flutter test`, so the
Swiss Ephemeris path is **only** verifiable on a device. Deploy via
`C:\Android\platform-tools\adb.exe`.

- [ ] Kundli and Milan produce the same positions as before the release
- [ ] Panchang for today matches an independent almanac
- [ ] Festival dates resolve for two different locations, and the Explorer
      agrees with the Panchang screen for the same day
- [ ] A festival reminder actually fires (Android OEM battery policies are the
      usual reason it does not)

## 4. Upgrade, not just install

- [ ] Install the previous build, then upgrade over it
- [ ] Japa history, habit days, bookmarks and visited temples all survive
- [ ] Kill the app mid-migration and reopen — it re-runs cleanly
- [ ] Legacy prefs keys still exist afterwards (they are deleted in a later
      release, not this one)

## 5. Content honesty

These are the promises the app makes about itself. Each is enforced somewhere,
but check them in-product too.

- [ ] Every Vedic Science topic renders its caution panel
- [ ] Every Ask answer shows a source, and a nonsense question returns the
      explicit not-sure state rather than a guess
- [ ] No Dharma choice shows a tick, a cross or a score
- [ ] Festivals that cannot be resolved say so instead of showing a date
- [ ] Source chips render on temples and on all Gyan content

## 6. Related rails — spot-check before every release

Sanskrit epithets collide badly, and a wrong recommendation is far more visible
to a user than a missing one. Open each and confirm nothing in the rail is
wrong:

- [ ] **Hanuman** — Chalisa, his temples, Hanuman Jayanti
- [ ] **Shiva** — Shiv Chalisa, Mahamrityunjaya, Maha Shivratri, jyotirlingas
- [ ] **Durga** — Durga Chalisa, both Navratris, her temples
- [ ] **Krishna** — Janmashtami, Govardhan Puja, his temples
- [ ] Nothing generic (`devi`, `mata`, `bhagwan`) has wired one deity's content
      onto another

## 7. Personalization

- [ ] With `interest_signals` empty, every screen is fully usable
- [ ] **Reset personalization** empties the table, not just the view
- [ ] Nothing is hidden or made unreachable by it — ordering only

## 8. Privacy

- [ ] Journal entries, reading progress and interest signals never leave the
      device
- [ ] The privacy policy says so
- [ ] No network permission is required for any feature to work

## 9. Install, upgrade and failure paths

Every one of these needs hardware. None can be verified by `flutter test`.

- [ ] **Offline** — Wi-Fi and data OFF: search, scriptures, panchang, kundli,
      temples, gyan, journal, sadhana, mandir all work
- [ ] **Fresh install** — uninstall, install, first launch, DB extraction, home
- [ ] **Upgrade** — user data survives: journal, japa, habits, bookmarks,
      reading progress, temple visits, interest signals
- [ ] **Interrupted extraction** — kill the app mid-copy, reopen, recovers
      cleanly (the version marker is written last so the copy re-runs)
- [ ] **Low storage** — a clear "not enough storage" message, never a crash
- [ ] **Screen sizes** — small, normal, large, tablet. Hindi overflows first
- [ ] **Accessibility** — font scaling, contrast, touch targets, TalkBack basics
- [ ] **AAB size** measured against the budget, not just the APK

## 10. Content did not silently shrink

- [ ] `py -m content.tools.content_diff` reports no losses
- [ ] `flutter test test/content_integrity_test.dart` passes

---

## Release gate — the blockers that are not code

These are tracked as RG-01..RG-04 in the build plan and **none of them is
fixed by shipping more features**.

- [ ] **RG-01** `assets/db/content.sqlite` replaced with our own content — the
      Ishvarvaani dev fixture is gone
- [ ] **RG-02** `meta.data_source` no longer says "DEV FIXTURE"
- [ ] **RG-03** All 52 placeholder images replaced; zero manifest rows with
      `replace_before_ship: true`
- [ ] **RG-04** `reference/ishvarvaani-apk/base.apk` and the reference DBs are
      out of the shipped tree, and ideally out of git history
- [ ] **RG-06** The generated `SOURCES.md` attribution block is rendered in the
      About screen — required for Play compliance as well as for honesty

> Universal Search makes the fixture content **more** prominent, not less.
> Nothing in the feature work makes RG-01 worse except by raising its
> visibility, and nothing in it makes RG-01 better either.
