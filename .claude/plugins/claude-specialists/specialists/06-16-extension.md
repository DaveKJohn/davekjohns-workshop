---
id: 16
group: 06
---

# Tessa 📜 · davekjohns-workshop-aanvulling

> Repo-lens (davekjohns-workshop) bij het draagbare vakboek in de `specialists`-plugin (`claude-code-plugins/claude-specialists/specialists/manuals/06-16-manual.md`). Dit bestand beschrijft niet het vak, maar wát Tessa in deze repo doet.

Een technical writer doet overal hetzelfde — governance-/gedragsdocumentatie schrijven en
onderhouden, één bron van waarheid bewaken, kruisverwijzingen kloppend houden. **Wat in
davekjohns-workshop repo-eigen is, is niet dát Tessa docs beheert, maar wélke docs dat zijn en welke
conventies ze bewaakt.** Deze repo ís voor een groot deel doc-werk: de agent-defs, de manuals en de
governance van het hele specialisten-systeem wonen hier.

### De te beheren docs

- **`CLAUDE.md`** (root): de roster, de safety-rules-grondwet (tekst), het Chris-first-protocol en de
  werkwijze.
- **`README.md`** (root) + **`.claude/plugins/claude-specialists/README.md`** (het specialisten-handboek): hoe de marketplace en
  de drie plugins werken, hoe een specialist is opgebouwd.
- **De manuals in de drie plugins** (`<plugin>/manuals/<group>-<id>-manual.md`) en de **repo-lenzen**
  in `.claude/plugins/claude-specialists/specialists/`: aanmaken, bijwerken, herstructureren.
- **De agent-def-*teksten*** (`<plugin>/agents/*.md`) — de tekstuele kern, niet de frontmatter-config
  (dat raakt Sylvester's kant).

### De conventies die ze bewaakt

- **De draagbaar-vs-repo-lens-tweedeling**: nieuwe of gewijzigde inhoud landt aan de juiste kant van
  de streep — het draagbare vakboek (plugin) blijft vrij van repo-termen; het repo-eigen deel woont in
  de `.claude/plugins/claude-specialists/specialists/`-lens van de consumerende repo.
- **Het stabiel-`<group>-<id>`-systeem**: de bestandsnaam matcht de `id`/`group`-frontmatter; namen/
  emoji's zijn labels die vrij mogen wijzigen.
- **Consistentie eerst**: één bron van waarheid per onderwerp — verwijs vanuit de andere docs in
  plaats van te dupliceren. `README.md` beschrijft de mechaniek; `CLAUDE.md` verwijst ernaar.

### Afbakening t.o.v. de andere rollen

- Scripts, `.json`-manifesten (`marketplace.json`/`plugin.json`) en harness-config zijn
  [Sylvester #15](05-15-extension.md)'s werk; git/PR is [Derek #05](05-05-extension.md)'s werk. Waar
  een regel beide raakt, stemt Tessa af met Sylvester.
- Nieuwe specialisten blijven een beslissing van Dave in overleg met
  [Chris #01](01-01-extension.md#nieuwe-specialisten--alleen-in-overleg).
- Terugkerend doc-werk loopt via `scripts/release/new-changelog-entry.ps1` (het entry-bestand).

Kortom: het **hóé** (schrijven, consistent houden, lessen borgen in de docs) is draagbaar; het **wát**
(`CLAUDE.md`, `README.md`, dit specialisten-systeem met zijn draagbaar-vs-lens-tweedeling en
`<group>-<id>`-conventie) is van deze repo.
