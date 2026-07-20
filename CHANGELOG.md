# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#contributing--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #111 · Roster-sync SessionStart hook (layer 2 of the feature) · Feat · 2026-07-20

Layer 2 of the roster-sync feature: the detection from layer 1 (#110) now surfaces itself at
session start, so a specialist missing from a consumer's roster is visible right after a plugin
update instead of only when someone happens to run the check.

- **`hooks/roster-sessioncheck.ps1` (new):** a SessionStart hook that runs the mirrored
  `check-roster-sync.ps1` against the current repo and, like `connector-sessioncheck.ps1`, is
  deliberately soft — it surfaces only blocking `[ERROR]` signals (a missing specialist) as a
  compact summary, keeps `[INFO]` (orphans, ignore-list skips, uncached plugins) silent, and always
  exits 0 (a session start never strands here). Read-only.
- **`hooks/hooks.json`:** a second command is added to the existing `SessionStart` (startup) entry,
  so the new hook runs alongside the connector check.
- **`connectors/README.md`:** the named-exception note now covers this second hook.
- **Tests:** `roster-sync.tests.ps1` gains hook cases (missing check script → skipped; an `[ERROR]`
  stub → drift summary + exit 0, never blocking; an `[INFO]`/`[OK]`-only stub → silent in-sync
  message).

Version gate as usual: consumers receive the hook only after a release bump + `claude plugin
update` + session restart. Layer 3 (the semi-automatic `sync-roster` recovery skill) and the full
feature docs follow.

Plugins: specialists

[PR #111](https://github.com/DaveKJohn/davekjohns-workshop/pull/111)

---

### #110 · Roster-sync detection (layer 1 of the feature) · Feat · 2026-07-20

When a plugin release adds a new specialist (e.g. Ravi 06-24), a consumer that updates the plugin
gets no signal that its roster (the specialists table in CLAUDE.md) and its repo lenses now lag
behind — the Ravi and Sean cases were both caught by chance. This is layer 1 of the fix: **detection**.
The SessionStart signaling (layer 2) and the semi-automatic recovery skill (layer 3) follow; full
user-facing docs land with layer 3 when the feature is complete.

- **`scripts/sync/check-roster-sync.ps1` (new, shared):** run from a consumer root, it resolves the
  enabled plugins' agents from the highest-version cache dir, then flags per agent: no roster row
  (`[ERROR]`), no repo-lens (`[ERROR]`), and roster/lens ids with no backing agent or persona
  (`[INFO]` orphan). Same `[OK]/[INFO]/[ERROR]` + exit-code convention and path guardrails as
  `check-connectors.ps1`. Mirrored to the plugin via the shared-scripts pipeline (byte-identical,
  drift-linted).
- **`repo-config.ps1`:** `Get-RosterPath` (default `CLAUDE.md`) tells the check where the roster
  lives; `Get-RosterIgnoredIds` lists agents that are enabled but deliberately have no roster
  row/lens (here: Paula 02-09, Vera 04-11, Gwen 04-12, Cody 04-13 — a documented choice), so the
  workshop's own run is clean. A fresh consumer leaves the ignore-list empty.
- **Tests:** `roster-sync.tests.ps1` (28 asserts, fixture-driven) covers the happy path, a new agent
  missing from the roster, a missing lens, orphans, disabled/uncached plugins, highest-version
  resolution, persona-backing, the `Get-RosterPath` override, the legacy lens path, and the
  ignore-list. `repo-config.tests.ps1` gained asserts for the two new getters.

Layer 1 is not yet wired into any gate — it is a standalone check a consumer can run; the hook
(layer 2) will surface it at session start.

Plugins: specialists

[PR #110](https://github.com/DaveKJohn/davekjohns-workshop/pull/110)

---

### #109 · Shared block for the language directive (Ravi) · Feat · 2026-07-20

Phase B left the closing "respond in the user's language" line verbatim-identical in 19 of the 20
agent defs. Ravi's duplication check recommended promoting it to a single source via the existing
`agent-shared/` mechanism — no new machinery needed, since the generator is line-based.

- **New source `agent-shared/gedrag-taalkeuze.md`** with the canonical line; the 19 identical agent
  defs now carry it between `<!-- BEGIN/END shared:gedrag-taalkeuze -->` sentinels, filled and
  verified by `build-agent-defs.ps1` like the `grens-*` blocks.
- **03-07 (Rebecca) stays local:** its line has a deliberate source-quoting nuance ("...quoting
  sources in another language is fine") — a near-duplicate that Ravi's own rule says not to force-merge.
- **Ravi's lens (06-24)** scope updated: the shared-block circle now names a third category
  (standalone behavior directives outside Boundaries/Working method) and lists `gedrag-taalkeuze`.

Naming note: the new source keeps the Dutch-style name of its `grens-*` siblings for uniformity;
renaming the whole `agent-shared/` set to English is a later-phase consistency item.

Plugins: agent-shared, specialists, specialists-lifehub, specialists-shopify

[PR #109](https://github.com/DaveKJohn/davekjohns-workshop/pull/109)

---

### #108 · Workshop to English — phase C: machine markers, bilingual · Feat · 2026-07-20

The final English-switch phase: the machine-coupled Dutch markers and the consumer-facing output of
the connector tooling are now English, with **bilingual back-compat** so consumers still carrying
the Dutch markers keep working across a plugin-version skew.

- **Slot marker `## Eigen aan deze repo` → `## Specific to this repo`.** `bootstrap.ps1` now writes
  the English scaffold heading; `check-consumer-drift.ps1` splits the portable body on **either**
  language (a legacy Dutch consumer still splits correctly). Docs (root README, connectors README,
  `specialists-init` skill, Chris's lens) follow the English canonical name.
- **Signal token `[FOUT]` → `[ERROR]`.** `check-connectors.ps1` emits `[ERROR]`; the SessionStart
  hook's blocking-signal filter recognizes **both** `[FOUT]` and `[ERROR]` (the plugin cache and the
  workshop checkout can be on different versions).
- **Consumer-facing output is English.** The connector check/drift-check messages and the hook's own
  session-start lines (`no errors`, `signals found …`) — surfaced into every consumer session — are
  translated.
- **PR template → English, `open-pr.ps1` matches both languages.** The three auto-fill strings are
  English in the template; the script still recognizes the Dutch strings so a consumer whose template
  is still Dutch keeps its auto-fill.
- **Tests:** bilingual back-compat is proven — the drift split is tested with both the legacy Dutch
  and the new English slot fixture; the hook test surfaces both a `[FOUT]` and an `[ERROR]` line.
  All seven suites green.

**Deferred to a later phase (D):** the purely internal, non-consumer-facing Dutch code-comments in
the scripts (and old research docs under `research/`). They ship in no consumer-visible surface, so
they carry no urgency; the English switch of everything consumer-facing is complete with this phase.

Plugins: specialists

[PR #108](https://github.com/DaveKJohn/davekjohns-workshop/pull/108)

---

### #107 · open-pr.ps1 survives git push's stderr chatter · Fix · 2026-07-20

`open-pr.ps1` died on the `git push` step: git writes its `remote:` progress to stderr, and under
`$ErrorActionPreference = 'Stop'` PowerShell 5.1 promotes that stderr to a *terminating*
NativeCommandError — aborting the script before the `$LASTEXITCODE` check, even though git itself
exited 0. This surfaced when opening the phase-B PR (#106): the push succeeded but the script
stopped before creating the PR, so the PR had to be opened by hand.

- **`scripts/release/open-pr.ps1`** (+ its plugin mirror via `build-shared-scripts.ps1`): the push
  now runs with `$ErrorActionPreference = 'Continue'`, captures `2>&1`, records `$LASTEXITCODE`,
  restores the preference, and only then judges — the same shape as the #96 fix.
- **`scripts/tests/shared-scripts.tests.ps1`**: a guard proving the mechanism (naive stderr-under-Stop
  is terminating; the capture pattern is not and reads the real exit code) plus a regression guard
  that `open-pr.ps1` keeps the safe push form. The live push against a real remote stays an honest
  test-gap (no remote in the unit suite).
- **`05-15-extension.md`** (Sylvester's lens): the lesson secured next to the #97 `$LASTEXITCODE`
  note — stderr-as-failure under `Stop` is the sibling pitfall.

Plugins: specialists

[PR #107](https://github.com/DaveKJohn/davekjohns-workshop/pull/107)

---

### #106 · Workshop switched to English — phase B: plugin content · Feat · 2026-07-20

Follow-up to phase A (#105): the shipped plugin content itself is now English, so consumers
worldwide read an English team. Covers all three plugins.

- **Translated:** the 20 agent definitions (prose outside the shared sentinel blocks), all 26
  manuals/playbooks, the 4 personas, `agent-shared/` (the canonical shared-bullet source), the
  three core skills + the shopify `start-task` skill, `specialists/scripts/README.md`, and the
  intro paragraphs of the three plugin `CHANGELOG.md` files (release history left as written).
- **Shared blocks regenerated:** `build-agent-defs.ps1` refilled every `<!-- BEGIN/END shared -->`
  region from the translated `agent-shared/`, so the sentinel content is English and byte-in-sync
  in all 20 agent defs.
- **Language directive aligned with the approved policy:** each agent def ended with a hard
  "work in Dutch" instruction. That contradicts the phase-A Language policy (specialists reply in
  the language the user writes in) and the worldwide-sharing goal, so all 20 now read "Respond in
  the language the user addresses you in." This is a behavior change beyond pure translation —
  flagged for review.
- **Slot-heading canon:** the human-readable `## Specific to this repo` section heading is now
  used consistently across manuals, lenses, and CLAUDE.md.

**Deliberately deferred to a later phase (scripts):** the machine-coupled Dutch marker
`## Eigen aan deze repo` still lives in `bootstrap.ps1` (the scaffold it writes),
`check-consumer-drift.ps1` (`Get-PortableBody` splits on it) and its test fixture; likewise the
`[FOUT]`/`[DRIFTED]` signal tokens, the `VUL-IN` scaffold marker, and the three Dutch PR-template
strings `open-pr.ps1` matches. Migrating those to English needs bilingual back-compat for
consumers that still carry the Dutch slot — a dedicated scripts phase. Lint and all seven test
suites pass.

Plugins: agent-shared, specialists, specialists-lifehub, specialists-shopify

[PR #106](https://github.com/DaveKJohn/davekjohns-workshop/pull/106)

---

### #105 · Workshop switched to English — phase A: foundation docs · Feat · 2026-07-20

Dave is sharing the plugin worldwide, so everything living in this repo switches to English
(decision 2026-07-20). History (folded changelog entries, `releases/`) stays as written. In
sessions, specialists reply in the language the user writes in — that policy now lives in
`CLAUDE.md` under "### Language" (replacing "### Taal"). Note: that section is **new policy**
(decided today), not a translation of the old one-line rule.

- **Translated in this phase:** `CLAUDE.md` (the constitution, rules preserved verbatim in
  meaning), the root `README.md`, the family README, `QUICKSTART.md`, the connectors README,
  the `notes` fields of the three connector manifests, both GitHub templates, the specialists
  handbook and all twelve repo lenses.
- **Deliberately left for phase B** (coupled to scripts/tests): the plugin content itself
  (agent defs, manuals, personas, skills, `agent-shared/`), machine-recognized markers
  (`VUL-IN`, the lens-only blockquote, `[FOUT]`/`[DRIFTED]` tokens, the literal
  `## Eigen aan deze repo` slot marker where quoted), script output and the CHANGELOG/releases
  intro texts that the fold/release scripts parse. Same for three literal strings in
  `.github/pull_request_template.md` that `open-pr.ps1` matches for its PR-body auto-fill
  (the description placeholder comment, "Changelog entry-bestand aangemaakt", "Aangevraagd
  door Dave") — caught in security review; in phase B the script learns both languages before
  the template fully switches.
- All internal links and anchors were reconciled after translation; the lint gate (link + anchor
  scan) and all seven test suites pass.

[PR #105](https://github.com/DaveKJohn/davekjohns-workshop/pull/105)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.11.0] - 2026-07-20 — Minor

Zie [releases/development/1.11/1.11.0.md](releases/development/1.11/1.11.0.md) voor de volledige release-notes.

---

### [v1.10.0] - 2026-07-19 — Minor

Zie [releases/development/1.10/1.10.0.md](releases/development/1.10/1.10.0.md) voor de volledige release-notes.

---

### [v1.9.2] - 2026-07-19 — Patch

Zie [releases/development/1.9/1.9.2.md](releases/development/1.9/1.9.2.md) voor de volledige release-notes.

---

### [v1.9.1] - 2026-07-19 — Patch

Zie [releases/development/1.9/1.9.1.md](releases/development/1.9/1.9.1.md) voor de volledige release-notes.

---

### [v1.9.0] - 2026-07-19 — Minor

Zie [releases/development/1.9/1.9.0.md](releases/development/1.9/1.9.0.md) voor de volledige release-notes.

---

### [v1.8.0] - 2026-07-18 — Minor

Zie [releases/development/1.8/1.8.0.md](releases/development/1.8/1.8.0.md) voor de volledige release-notes.

---

### [v1.7.0] - 2026-07-18 — Minor

Zie [releases/development/1.7/1.7.0.md](releases/development/1.7/1.7.0.md) voor de volledige release-notes.

---

### [v1.6.0] - 2026-07-18 — Minor

Zie [releases/development/1.6/1.6.0.md](releases/development/1.6/1.6.0.md) voor de volledige release-notes.

---

### [v1.5.2] - 2026-07-18 — Patch

Zie [releases/development/1.5/1.5.2.md](releases/development/1.5/1.5.2.md) voor de volledige release-notes.

---

### [v1.5.1] - 2026-07-18 — Patch

Zie [releases/development/1.5/1.5.1.md](releases/development/1.5/1.5.1.md) voor de volledige release-notes.

---

### [v1.5.0] - 2026-07-17 — Minor

Zie [releases/development/1.5/1.5.0.md](releases/development/1.5/1.5.0.md) voor de volledige release-notes.

---

### [v1.4.1] - 2026-07-16 — Patch

Zie [releases/development/1.4/1.4.1.md](releases/development/1.4/1.4.1.md) voor de volledige release-notes.

---

### [v1.4.0] - 2026-07-16 — Minor

Zie [releases/development/1.4/1.4.0.md](releases/development/1.4/1.4.0.md) voor de volledige release-notes.

---

### [v1.3.0] - 2026-07-16 — Minor

Zie [releases/development/1.3/1.3.0.md](releases/development/1.3/1.3.0.md) voor de volledige release-notes.

---

### [v1.2.0] - 2026-07-16 — Minor

Zie [releases/development/1.2/1.2.0.md](releases/development/1.2/1.2.0.md) voor de volledige release-notes.

---

### [v1.1.1] - 2026-07-15 — Patch

Zie [releases/development/1.1/1.1.1.md](releases/development/1.1/1.1.1.md) voor de volledige release-notes.

---

### [v1.1.0] - 2026-07-15 — Minor

Zie [releases/development/1.1/1.1.0.md](releases/development/1.1/1.1.0.md) voor de volledige release-notes.

---

### [v1.0.0] - 2026-07-14 — Major

Zie [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) voor de volledige release-notes.
