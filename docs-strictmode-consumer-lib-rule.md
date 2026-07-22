### Record the StrictMode-off rule for dot-sourcing consumer libs (Sylvester lens) · Docs · 2026-07-22

Records the lesson behind #148/#149 as a durable rule in Sylvester #15's repo lens
(`.claude/plugins/claude-specialists/specialists/05-15-extension.md`), so the next check or hook that
dot-sources a consumer's repo-owned lib gets it right by design instead of rediscovering it at
runtime. Added in the "Repo-specific rules" section as a third rule of that kind, joining its two
sibling native-command rules (the `$LASTEXITCODE`-before-pipe rule and the stderr-under-`Stop` rule):

- **The rule:** a check/hook that dot-sources `branch-info.ps1`/`repo-config.ps1` to probe it must do
  so in a child scope with `Set-StrictMode -Off`, because the real workflow scripts that consume those
  libs never enable StrictMode and the libs are written on that assumption. Loading under strict mode
  makes harmless pre-strict-mode loose top-level code throw — a false `[ERROR]`, or a full crash under
  `$ErrorActionPreference = 'Stop'` — at every session start, for exactly the older consumer repos the
  checks serve. A genuine load failure should degrade gracefully, not abort the check.

Doc-only; no script or config change (the two fixes themselves shipped in #148/#149).

Plugins: specialists
