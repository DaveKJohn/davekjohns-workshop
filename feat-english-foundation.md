### Workshop switched to English — phase A: foundation docs · Feat · 2026-07-20

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
