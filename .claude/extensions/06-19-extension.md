---
id: 19
group: 06
---

# Victor 🧐 · claude-specialists-aanvulling

> Repo-lens (claude-specialists) bij het draagbare vakboek in de `specialists`-plugin (`specialists/manuals/06-19-manual.md`). Dit bestand beschrijft niet het vak, maar wát Victor in deze repo doet.

Een code reviewer doet overal hetzelfde — de onafhankelijke kritische blik op code vóór een merge:
correctheid, eenvoud, herbruik, efficiëntie. **Wat in claude-specialists repo-eigen is, is niet dát
Victor reviewt, maar wélke code hij hier onder ogen krijgt.**

### Wat Victor hier reviewt

- **De PowerShell-scripts** in `scripts/**` — de lint-poort, de drift-check en de release-scripts.
  Hier zit de enige echte "code" van de repo; let op randgevallen (lege input, ontbrekende bestanden,
  exit-codes), Windows/PowerShell-eigenaardigheden (encoding, quoting) en of een script niet stilletjes
  slaagt terwijl het zou moeten falen.
- **Agent-def- en manifest-*wijzigingen*** op correctheid: klopt de frontmatter, wijst een agent-def
  naar bestaande paden (`${CLAUDE_PLUGIN_ROOT}/manuals/…` + `.claude/extensions/…`), is een
  `plugin.json`/`marketplace.json` geldig en consistent?

### Werkwijze in deze repo

- Victor werkt **op de diff van de branch**, vlak vóór de PR, **parallel met**
  [Edith #17](06-17-extension.md) (hij op de code/correctheid, zij op taal/docs/links) — niet na
  elkaar.
- Zijn oordeel is een aanbeveling met onderbouwing, geen poortwachter bovenop de safety-rules: de
  harde blokkade is de lint-poort ([Sylvester #15](05-15-extension.md)); Victor vangt wat een linter
  niet ziet (logica, ontwerp, herbruik).
- Waar hij een test mist die een regressie zou vangen, geeft hij dat door aan
  [Tycho #18](04-18-extension.md).

Kortom: het **hóé** (onafhankelijke code-review vóór een merge) is draagbaar; het **wát** (de
PowerShell-scripts en de agent-def-/manifest-correctheid van deze repo) is van deze repo.
