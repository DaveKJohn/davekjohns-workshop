# Quickstart — zo sluit je jouw repo aan

Deze pagina is voor wie het Claude-Specialists-systeem **niet** gebouwd heeft: een collega met een
eigen repo die met het specialisten-team wil werken. Alles hieronder is de rode draad — de diepere
uitleg staat achter de links en wordt hier bewust niet herhaald.

## Wat je krijgt

In plaats van één generieke Claude werk je met een **team van gespecialiseerde Claudes onder één
Chief of Staff (Chris)**: elke opdracht wordt geclassificeerd en bezorgd bij de specialist met het
juiste vakboek — een DevOps-engineer voor branches en PR's, een technical writer voor docs, een
eindredacteur en code/security-reviewers voor de onafhankelijke laatste blik vóór een PR of merge. Jouw repo houdt zelf
de regie: de governance (jouw `CLAUDE.md`, jouw safety-regels) blijft van jou; de plugins leveren
alleen het team en zijn vakboeken.

Het systeem bestaat uit **drie plugins**: de repo-neutrale kern `specialists` (groep 1 — altijd
inschakelen) en twee optionele domein-groepen. Wélke specialisten in welke plugin zitten en voor wie
ze bedoeld zijn, staat in de [familie-README](README.md).

## Aansluiten in drie stappen

**Stap 1 — schakel de plugins in.** Zet in `.claude/settings.json` van jouw repo de marketplace-source
en de gewenste plugins (de kern altijd; een domein-groep alleen als jouw repo dat domein heeft):

```jsonc
// .claude/settings.json (jouw repo)
"extraKnownMarketplaces": {
  "davekjohns-workshop": {
    "source": { "source": "github", "repo": "DaveKJohn/davekjohns-workshop" }
  }
},
"enabledPlugins": {
  "specialists@davekjohns-workshop": true
}
```

Deze repo is publiek, dus de source is zonder GitHub-authenticatie te lezen; Claude Code clonet en
cachet hem zelf. **Herstart daarna je Claude Code-sessie** — pas dan zijn de plugins (en de skill
uit stap 2) beschikbaar.

**Stap 2 — draai de bootstrap-skill.** Roep in de nieuwe sessie `specialists-init` aan. Die zet —
puur additief, zonder iets te overschrijven — de persona-kopieën (waaronder Chris) in
`.claude/extensions/`, een lege repo-lens-scaffold per specialist, de Chris-import in jouw
`CLAUDE.md`, en een voorstel voor safety-instellingen (`settings.suggested.jsonc`, ter eigen
beoordeling). De details van dit pad staan in de
[root-README › Adoptie](../../README.md#adoptie-het-bootstrap-pad) — die telt de stappen daar als
"stap 0" (het inschakelen hierboven) en "stap 1" (de skill).

**Stap 3 — herstart en controleer.** Start opnieuw en check dat Chris het woord neemt (elke beurt
opent met een afzender-kopregel zoals `🧭 Chris — intake & routing`). Vul daarna in je eigen tempo de
repo-lenzen in `.claude/extensions/` in: dáár vertel je per specialist wat hij in jouw repo bedient.
De werker-specialisten zijn direct aanroepbaar als `@specialists:<naam>`.

## Bijblijven

Updates bereiken je via **releases**: `claude plugin update` vergelijkt uitsluitend versienummers,
dus je krijgt wijzigingen zodra de werkplaats een nieuwe versie heeft gesneden — niet eerder. Elke
plugin draagt een eigen `CHANGELOG.md` die met de plugin-cache meereist en per release vertelt wat
er voor díe plugin veranderde; de volledige geschiedenis staat in de werkplaats zelf
([`CHANGELOG.md`](../../CHANGELOG.md) en [`releases/`](../../releases/README.md)).

## Iets terugmelden of verbeteren

- **Verbeterpunt aan de gedeelde kern** (een agent-def, vakboek, persona of skill): bouw het niet
  lokaal om, maar meld het als issue op deze repo met het label `inbound` — daar staat een
  [issue-sjabloon](../../.github/ISSUE_TEMPLATE/inbound-verbeterpunt.md) voor klaar. De werkplaats
  verwerkt het via zijn eigen keten, en de verbetering komt via een release bij álle consumenten
  terug.
- **Repo-eigen aanvullingen** horen in jouw eigen repo-lenzen (`.claude/extensions/`) — die zijn van
  jou en reizen niet mee met de plugin.
