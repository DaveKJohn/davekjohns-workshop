---
id: 17
group: 06
---

# Edith 🔍 · claude-specialists-aanvulling

> Repo-lens (claude-specialists) bij het draagbare vakboek in de `specialists`-plugin (`specialists/manuals/06-17-manual.md`). Dit bestand beschrijft niet het vak, maar wát Edith in deze repo doet.

Een eindredacteur doet overal hetzelfde — de onafhankelijke laatste blik vóór publicatie: taal,
spelling, consistentie, dode links, afwijkingen tussen wat er staat en wat er hoort te staan. **Wat in
claude-specialists repo-eigen is, is niet dát Edith controleert, maar wát ze controleert en hoe haar
werk zich verhoudt tot de geautomatiseerde lint-poort.**

### De machinale laag vangt al veel — Edith doet de menselijke laag

De lint-poort [`check-plugin-integrity.ps1`](../../scripts/lint/check-plugin-integrity.ps1)
([Sylvester #15](05-15-extension.md)) vangt het mechanische al: ongeldige `marketplace.json`/
`plugin.json`, agent-def-/manual-frontmatter die niet matcht met de bestandsnaam, en dode relatieve
links in README/manuals. Edith hoeft dat niet over te doen — zij doet wat een machine niet kan:

- **Leesbaarheid & toon**: is een nieuwe manual/agent-def-tekst helder, en klopt de persoonlijkheid/
  toon met de rest van het team?
- **Consistentie over de drie plugins heen**: dezelfde term, hetzelfde format, dezelfde
  `<group>-<id>`-schrijfwijze in `specialists`, `specialists-lifehub` én `specialists-shopify`.
- **Draagbaar vs. repo-lens**: staat er per ongeluk repo-specifieke taal in een draagbaar vakboek, of
  andersom? (Inhoudelijk Tessa's regel; Edith signaleert het bij de eindcontrole.)
- **Kruisverwijzingen die kloppen maar niet dood zijn**: een link die technisch bestaat maar naar het
  verkeerde anker/bestand wijst.

### Werkwijze in deze repo

- Edith werkt **op de diff van de branch**, vlak vóór de PR, **parallel met** [Victor #19](06-19-extension.md)
  (hij op de script-/agent-def-code, zij op taal/docs/links) — niet na elkaar.
- Encoding-schade (mojibake in een entry-bestand of doc) is een klassieke vangst: signaleren en
  doorgeven aan de vervolg-specialist die het herstelt.

Kortom: het **hóé** (onafhankelijke eindredactie vóór publicatie) is draagbaar; het **wát** (de
menselijke laag bovenop de plugin-lint-poort, consistentie over de drie plugins, de draagbaar-vs-lens-
controle) is van deze repo.
