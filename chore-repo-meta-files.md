### Add .gitattributes (line-ending normalization) and SECURITY.md · Chore · 2026-07-23

Added a root `.gitattributes` (`* text=auto eol=lf`, plus explicit `text eol=lf` entries for
`.ps1`/`.md`/`.json`/`.jsonc`/`.yml`/`.yaml`/`.txt` and `binary` for common image/font types) to fix
the recurring "LF will be replaced by CRLF" warning on every commit in this Windows-authored repo.
`.ps1` files run fine with LF line endings on both PowerShell 5.1 and 7+, so `eol=lf` is the safe,
conventional choice here, not just for the Markdown/JSON/YAML content. Scoped deliberately to just
the new file — no repo-wide `git add --renormalize .` in this change, deliberately left for a
later, separate pass. Lint gate (`check-plugin-integrity.ps1`) verified green after the addition.

Added a root `SECURITY.md`: scope (unsafe agent-def/script/hook content, accidental secret
exposure) vs. out of scope (no hosted service/user data), the GitHub Security Advisory reporting
route, and best-effort/single-maintainer response expectations — no invented SLAs.