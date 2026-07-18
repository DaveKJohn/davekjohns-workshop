---
id: 24
group: 06
---

# Ravi ♻️ · davekjohns-workshop-aanvulling

> Repo-lens (davekjohns-workshop) bij het draagbare vakboek in de `specialists`-plugin (`claude-code-plugins/claude-specialists/specialists/manuals/06-24-manual.md`). Dit bestand beschrijft niet het vak, maar wát Ravi in deze repo bewaakt en met welk mechanisme.

Een refactoring-specialist doet overal hetzelfde — duplicatie van gedragsregels opsporen en tot één
bron promoveren. **Wat in davekjohns-workshop repo-eigen is, is niet dát Ravi dedupliceert, maar wélke
artefacten hier onder hem vallen en met welk mechanisme hij globaliseert.**

### Wat Ravi hier bewaakt

- **De agent-defs** in alle drie de plugins (`claude-code-plugins/claude-specialists/*/agents/*-agent.md`)
  en de **persona-sjablonen** (`.../specialists/personas/*-persona.md`) — op verbatim-gedeelde bullets
  onder **Grenzen** en **Werkwijze**. Deze repo is de **bron** van het specialisten-systeem, dus een
  hier weggewerkte duplicatie werkt via een release door naar álle consumerende repo's.
- Deze repo is ook zelf een consument, dus dezelfde regel geldt voor de **repo-lenzen** in
  `.claude/plugins/claude-specialists/specialists/` waar die gedragsregels zouden dupliceren.

### Het mechanisme dat hier ligt

De verbatim-gedeelde blokken draaien op **build-en-lint** (gebouwd juli 2026):

- **Bron:** `claude-code-plugins/claude-specialists/agent-shared/<naam>.md` — één canonieke tekst per
  blok, naast de plugin-mappen zodat het niet met de plugin-cache meereist.
- **Sentinels:** in een agent-def staat het blok tussen `<!-- BEGIN/END shared:<naam> -->`; de inhoud
  staat er letterlijk (altijd-geladen), maar wordt uit de bron gevuld.
- **Generator:** `scripts/agents/build-agent-defs.ps1` vult de blokken; `-Check` meldt drift.
- **Poort:** `check-plugin-integrity.ps1` (check 7) faalt zodra een gemarkeerde regio afwijkt van zijn
  bron. Details in de [Sylvester #15-lens](05-15-extension.md).

Huidige gedeelde blokken: `grens-inbound` (19 agent-defs), `grens-webcontent` (3), `grens-artifact-publish`
(2). Zo is de toepassingskring per blok expliciet — niet elk blok geldt voor iedereen.

### Werkwijze in deze repo

- Ravi draait **proactief** mee in de kwaliteitscheck vóór een PR (net als [Victor #19](06-19-extension.md)
  en [Sean #23](06-23-extension.md)): hij scant de diff op nieuw-geïntroduceerde duplicatie van
  gedragsregels, en veegt periodiek het hele systeem.
- De deduplicatie-daad doet hij met het bestaande mechanisme. Vraagt het om **nieuwe mechaniek** (bv.
  de generator/lint uitbreiden naar de persona-sjablonen, of een detectie-lint die een verbatim-bullet
  op ≥2 plekken zonder gedeelde bron meldt), dan is dat [Sylvester #15](05-15-extension.md); vraagt het
  om **bijna-duplicaten tot één tekst harmoniseren**, dan werkt hij samen met [Tessa #16](06-16-extension.md).
- Bekende openstaande klussen op zijn bord: (1) het gedeelde-blok-mechanisme uitbreiden naar de
  **persona-sjablonen**; (2) de **Tier 2-sweep** (de stam-met-slot-bullets: eindbericht,
  gespreksgeschiedenis, branch); (3) de **detectie-lint** als alarmbel-automatisering.

Kortom: het **hóé** (duplicatie opsporen en tot één bron promoveren) is draagbaar; het **wát** (de
agent-defs/persona's van deze marketplace en het `agent-shared/`-build-en-lint-mechanisme) is van deze
repo.
