# Changelog

The history of the davekjohns-workshop marketplace: under **Pull Requests** every merged branch
with its PR, under **Releases** the recorded versions. How the mechanism works (entry files,
folding) is described in [`README.md`](README.md#contributing--changelog--pr-workflow).

## Pull Requests

Everything merged to `main` since the last release — newest at the top, one block per pull
request.

### #152 · Group the releases overview by major version · Docs · 2026-07-23

Groups the `releases/README.md` overview table by major version (`### 2.x`, `### 1.x`, newest
first), each group its own table, now that `v2.0.0` is a natural dividing point — the flat 27-row
list was getting long. The `2.x` table sits at the top with the same English header
(`| Version | Date | Type | Title |`), so `cut-release.ps1`'s row insertion (which targets the
first matching header) keeps landing new minor/patch rows in the current-major table without a
behavior change; verified by simulating a `2.1.0` insertion. `cut-release.ps1` gets a clarifying
comment documenting that layout assumption and that a brand-new major starts its top section
manually first (a deliberate milestone moment). Doc + comment only; no functional change.

[PR #152](https://github.com/DaveKJohn/davekjohns-workshop/pull/152)

---

## Releases

The recorded versions of the marketplace — newest at the top. Each release bumps all plugin
versions in lockstep and references the full notes in `releases/development/`.

### [v2.0.0] - 2026-07-23 — Major

See [releases/development/2.0/2.0.0.md](releases/development/2.0/2.0.0.md) for the full release notes.

---

### [v1.18.0] - 2026-07-22 — Minor

See [releases/development/1.18/1.18.0.md](releases/development/1.18/1.18.0.md) for the full release notes.

---

### [v1.17.0] - 2026-07-22 — Minor

See [releases/development/1.17/1.17.0.md](releases/development/1.17/1.17.0.md) for the full release notes.

---

### [v1.16.0] - 2026-07-22 — Minor

See [releases/development/1.16/1.16.0.md](releases/development/1.16/1.16.0.md) for the full release notes.

---

### [v1.15.1] - 2026-07-22 — Patch

See [releases/development/1.15/1.15.1.md](releases/development/1.15/1.15.1.md) for the full release notes.

---

### [v1.15.0] - 2026-07-21 — Minor

See [releases/development/1.15/1.15.0.md](releases/development/1.15/1.15.0.md) for the full release notes.

---

### [v1.14.0] - 2026-07-21 — Minor

See [releases/development/1.14/1.14.0.md](releases/development/1.14/1.14.0.md) for the full release notes.

---

### [v1.13.0] - 2026-07-21 — Minor

See [releases/development/1.13/1.13.0.md](releases/development/1.13/1.13.0.md) for the full release notes.

---

### [v1.12.1] - 2026-07-20 — Patch

See [releases/development/1.12/1.12.1.md](releases/development/1.12/1.12.1.md) for the full release notes.

---

### [v1.12.0] - 2026-07-20 — Minor

See [releases/development/1.12/1.12.0.md](releases/development/1.12/1.12.0.md) for the full release notes.

---

### [v1.11.0] - 2026-07-20 — Minor

See [releases/development/1.11/1.11.0.md](releases/development/1.11/1.11.0.md) for the full release notes.

---

### [v1.10.0] - 2026-07-19 — Minor

See [releases/development/1.10/1.10.0.md](releases/development/1.10/1.10.0.md) for the full release notes.

---

### [v1.9.2] - 2026-07-19 — Patch

See [releases/development/1.9/1.9.2.md](releases/development/1.9/1.9.2.md) for the full release notes.

---

### [v1.9.1] - 2026-07-19 — Patch

See [releases/development/1.9/1.9.1.md](releases/development/1.9/1.9.1.md) for the full release notes.

---

### [v1.9.0] - 2026-07-19 — Minor

See [releases/development/1.9/1.9.0.md](releases/development/1.9/1.9.0.md) for the full release notes.

---

### [v1.8.0] - 2026-07-18 — Minor

See [releases/development/1.8/1.8.0.md](releases/development/1.8/1.8.0.md) for the full release notes.

---

### [v1.7.0] - 2026-07-18 — Minor

See [releases/development/1.7/1.7.0.md](releases/development/1.7/1.7.0.md) for the full release notes.

---

### [v1.6.0] - 2026-07-18 — Minor

See [releases/development/1.6/1.6.0.md](releases/development/1.6/1.6.0.md) for the full release notes.

---

### [v1.5.2] - 2026-07-18 — Patch

See [releases/development/1.5/1.5.2.md](releases/development/1.5/1.5.2.md) for the full release notes.

---

### [v1.5.1] - 2026-07-18 — Patch

See [releases/development/1.5/1.5.1.md](releases/development/1.5/1.5.1.md) for the full release notes.

---

### [v1.5.0] - 2026-07-17 — Minor

See [releases/development/1.5/1.5.0.md](releases/development/1.5/1.5.0.md) for the full release notes.

---

### [v1.4.1] - 2026-07-16 — Patch

See [releases/development/1.4/1.4.1.md](releases/development/1.4/1.4.1.md) for the full release notes.

---

### [v1.4.0] - 2026-07-16 — Minor

See [releases/development/1.4/1.4.0.md](releases/development/1.4/1.4.0.md) for the full release notes.

---

### [v1.3.0] - 2026-07-16 — Minor

See [releases/development/1.3/1.3.0.md](releases/development/1.3/1.3.0.md) for the full release notes.

---

### [v1.2.0] - 2026-07-16 — Minor

See [releases/development/1.2/1.2.0.md](releases/development/1.2/1.2.0.md) for the full release notes.

---

### [v1.1.1] - 2026-07-15 — Patch

See [releases/development/1.1/1.1.1.md](releases/development/1.1/1.1.1.md) for the full release notes.

---

### [v1.1.0] - 2026-07-15 — Minor

See [releases/development/1.1/1.1.0.md](releases/development/1.1/1.1.0.md) for the full release notes.

---

### [v1.0.0] - 2026-07-14 — Major

See [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) for the full release notes.
