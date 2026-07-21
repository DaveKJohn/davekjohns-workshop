# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#contributing--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #122 · Slim down CLAUDE.md: system description moves to plugin READMEs, CLAUDE.md references them · Docs · 2026-07-21

`CLAUDE.md` is made plugin-independent where the described content already lives elsewhere: the
special-case blockquote, the "who does what" intro, the loading-strategy paragraph, the workshop
identity paragraph, and the full repo-layout bullet list are shortened to a sentence or two with a
pointer to the root `README.md` (new `### Repo layout` subsection, merged into "What lives here and
what doesn't") or the family README. The "lazy" trait paragraph is shortened and now points to the
`README.md` "Shared agent-def blocks" section instead of repeating the mechanism inline. All Safety
rules, General working practices, the safety implementation, the header rule, the roster/routing
table, the "repo consumes itself" caveat, and the `@`-imports are untouched. The `## The Claude
Specialists — who does what` heading text and its "Loading strategy" sentence that Nolan's lens
(`06-25-extension.md`) cites are kept verbatim so that citation and anchor stay intact.

[PR #122](https://github.com/DaveKJohn/davekjohns-workshop/pull/122)

---

### #121 · Make the automation-first (lazy) rule a plugin-owned shared block, like inbound-behaviour · Feat · 2026-07-21

The automation-first ("stay lazy") behavioral rule is now plugin-owned via a new shared block,
`claude-code-plugins/claude-specialists/agent-shared/laziness-automation.md`, wired into the
subagent agent-defs via `<!-- BEGIN/END shared:... -->` sentinels — the same circle as
`shared:inbound-behaviour` — so the rule travels along to consuming repos instead of living only
in this repo's own `CLAUDE.md`. The per-specialist "X is lazy" examples in the manuals stay in
place as elaboration; `CLAUDE.md`'s own "Shared trait — all of them incredibly lazy" paragraph
remains as the governance narrative for the main loop (Chris and the main-loop personas, who carry
no agent-shared blocks), with a light note added that it is the same rule carried by every
specialist's shared playbook, not a second canonical copy.

Plugins: agent-shared, specialists, specialists-lifehub, specialists-shopify

[PR #121](https://github.com/DaveKJohn/davekjohns-workshop/pull/121)

---

### #120 · Cross-browser compatibility as a standard rule for the browser-facing builders · Feat · 2026-07-21

New shared behavioral rule for the browser-facing builders: what they build must work in all major
browsers (Chrome, Firefox, Safari, Edge), not only the one they happened to preview in. Landed as a
new canonical source block, `claude-code-plugins/claude-specialists/agent-shared/browser-compatibility.md`,
carried into the agent defs of the four specialists who share it — Gwen #12 (Front-End Designer),
Liam #20 (Liquid Developer), Cody #13 (App Developer), Vera #11 (Data Analyst) — via the existing
`agent-shared/` sentinel mechanism, plus a matching prose paragraph in each of their portable
manuals (`04-12-manual.md`, `specialists-shopify/manuals/04-20-manual.md`, `04-13-manual.md`,
`04-11-manual.md`) describing the cross-browser check in that specialist's own context.

Plugins: agent-shared, specialists, specialists-shopify

[PR #120](https://github.com/DaveKJohn/davekjohns-workshop/pull/120)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.13.0] - 2026-07-21 — Minor

Zie [releases/development/1.13/1.13.0.md](releases/development/1.13/1.13.0.md) voor de volledige release-notes.

---

### [v1.12.1] - 2026-07-20 — Patch

Zie [releases/development/1.12/1.12.1.md](releases/development/1.12/1.12.1.md) voor de volledige release-notes.

---

### [v1.12.0] - 2026-07-20 — Minor

Zie [releases/development/1.12/1.12.0.md](releases/development/1.12/1.12.0.md) voor de volledige release-notes.

---

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
