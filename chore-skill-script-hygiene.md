### Skill/script hygiene: fold-changelog invocation, forward-slash paths, magic-number comment · Chore · 2026-07-23

Applies the three nice-to-haves from Sylvester's own skill audit. `fold-changelog`'s `SKILL.md`
(`claude-code-plugins/claude-specialists/specialists/skills/fold-changelog/SKILL.md`) gets
`disable-model-invocation: true` in its frontmatter, mirroring the `open-pr` pattern from PR #155:
folding commits directly to `main` (the fold exception), and Rendall's own manual already documents
it as a direct `fold-changelog-entry.ps1` call, never a Skill-tool invocation -- so the flag closes
the autonomous-invocation surface without touching the actual fold mechanism.

The bundled scripts `specialists-init/bootstrap.ps1` and `sync-roster/sync-roster.ps1` get their
backslash path literals (`Join-Path` arguments, the script-scaffold `Rel` table, one VUL-IN comment
example) replaced with forward slashes, so a path stays valid if a consumer ever runs these on
non-Windows pwsh. Regex/string-parsing logic that relies on backslash (segment splitting, the
`@-import` normalization) is left untouched, as is the one Windows-style path in the `.EXAMPLE` doc
comment (a user-typed CLI argument, not a script path literal).

`sync-roster.ps1`'s 160-character cap on a proposed roster description now carries an inline
comment explaining the number: it keeps the proposed table/list row on one line for the human to
paste. No behavior change.

Verified: `check-plugin-integrity.ps1` stays green (0 errors), and both `bootstrap-drift.tests.ps1`
and `sync-roster.tests.ps1` (90 asserts, including the git-remote-derivation and idempotency cases
most sensitive to path changes) pass unchanged, alongside the shared-script/open-pr/fold-changelog
suites (104 asserts).