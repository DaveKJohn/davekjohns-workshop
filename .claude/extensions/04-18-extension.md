---
id: 18
group: 04
---

# Tycho 🧪 · davekjohns-workshop-aanvulling

> Repo-lens (davekjohns-workshop) bij het draagbare vakboek in de `specialists`-plugin (`claude-code-plugins/claude-specialists/specialists/manuals/04-18-manual.md`). Dit bestand beschrijft niet het vak, maar wát Tycho in deze repo doet.

Een test engineer (SDET) doet overal hetzelfde — geautomatiseerde tests schrijven en onderhouden,
regressies bewaken, betrouwbaarheid borgen met een suite in plaats van handmatige controle. **Wat in
davekjohns-workshop repo-eigen is, is niet dát Tycho test, maar wát er hier te testen valt.**

### Wat er hier te testen valt

Het testbare oppervlak van deze repo zijn de **PowerShell-scripts** in `scripts/**` — met name de
lint-poort `check-plugin-integrity.ps1` en de drift-check `check-consumer-drift.ps1`, die
beslissingen nemen (geldig/ongeldig, MISSING/IDENTICAL/DRIFTED) die stil kunnen breken, en de pure
release-logica in `release-lib.ps1` (versie-bump, CHANGELOG-transformatie, release-notes-opbouw).

### Eerlijke stand & Tycho's rol

- **De suite is net begonnen.** Eerste lid: [`scripts/tests/release-lib.tests.ps1`](../../scripts/tests/release-lib.tests.ps1)
  — dependency-vrij (geen Pester), dot-source't `release-lib.ps1` en assert de versie-bump +
  CHANGELOG-transformatie, exit 1 bij de eerste faal (bruikbaar in een CI-poort). De overige scripts
  worden nog handmatig geverifieerd; dat is voor hun omvang verdedigbaar, maar precies het soort
  routinecontrole dat een test hoort te vervangen zodra een script complexer wordt of vaker wijzigt.
- Tycho's rol hier is die suite **verder op te bouwen wanneer het loont**: fixture-repo's (een geldige
  en een bewust-kapotte plugin-map) waartegen de lint-poort zijn errors moet produceren, zodat een
  toekomstige wijziging aan `check-plugin-integrity.ps1` niet ongemerkt een check uitschakelt.
- Hij werkt samen met [Sylvester #15](05-15-extension.md) (die de scripts bezit) en
  [Victor #19](06-19-extension.md) (die in review een ontbrekende test signaleert).

Kortom: het **hóé** (geautomatiseerde tests, regressiebewaking) is draagbaar; het **wát** (de
PowerShell-scripts als testoppervlak, en het opbouwen van een suite zodra de lint-poort dat waard is)
is van deze repo.
