# .claude/

Het thuis van het **Claude Specialists**-systeem *zoals deze repo het zelf consumeert*, plus het
harnas waarin het draait. Dit document is zowel de plattegrond van deze map als het
**specialisten-handboek** — Chris' naslagwerk bij twijfel. Het legt drie dingen vast: (1) de
**lay-out** van `.claude/` zelf; (2) **hoe een specialist is opgebouwd** — als persona of subagent, de
tweedeling van elke manual, en het stabiel-id-systeem; en (3) **hoe de specialisten hier onderling
georganiseerd zijn**. Het is **geen vervanging** van de safety-rules of de routing.

> **Deze repo is een buitenbeentje.** davekjohns-workshop is de werkplaats-marketplace van Dave;
> het specialisten-systeem woont hier als eerste product-familie in `claude-code-plugins/claude-specialists/`
> (zie [`../README.md`](../README.md)) — en de repo consumeert dat systeem hier
> ook zélf, via de `specialists`-plugin (groep 1). Het team hier is daarom klein en toegespitst op het
> onderhoud van dít product (agent-defs, manuals, docs, tooling), niet het brede team van een
> content-repo.

- De grondwet blijft [`../CLAUDE.md#safety-rules`](../CLAUDE.md#safety-rules).
- **Chris blijft elke opdracht aannemen en routeren** — zie zijn vaste ritueel in
  [`extensions/01-01-extension.md`](extensions/01-01-extension.md).

## Lay-out van deze map

- **`extensions/`** — de **repo-laag** van het specialisten-systeem: één bestand per specialist,
  `<group>-<id>-extension.md`. Er zijn twee soorten:
  - **Subagent-lens** — voor de specialisten die als subagent uit de `specialists`-plugin komen
    (Sylvester, Tessa, Edith, Victor, Tycho): alleen het `## Eigen aan deze repo`-deel, dat het
    draagbare vakboek in de plugin aanvult met de context van déze repo. De subagent leest
    plugin-vakboek + deze lens samen; de agent-def verwijst naar beide.
  - **Persona-manual** — voor de persona-only specialisten (Chris, Derek, Rendall), die in het
    hoofdgesprek draaien i.p.v. als subagent. De main-loop leest geen plugin-bestanden, dus hier
    staat hun **volledige** manual en wordt Chris hiervandaan auto-geladen
    (`@.claude/extensions/01-01-extension.md` onderaan `../CLAUDE.md`). De **draagbare body** van elke
    persona heeft wél een canonieke bron in de plugin — `claude-code-plugins/claude-specialists/specialists/personas/<group>-<id>-persona.md`
    — die de bootstrap-skill `specialists-init` bij adoptie naar `.claude/extensions/` kopieert; dit
    lokale bestand is dus een (met drift-lint bewaakte) kopie van die bron, aangevuld met de repo-lens.
- **Subagent-definities — uit de eigen `specialists`-plugin, niet lokaal.** De compacte, uitvoerbare
  vorm van een specialist (`<group>-<id>-agent.md`) bewaart deze repo **niet** in een lokale
  `.claude/agents/`-map: ze komen uit de `specialists`-plugin van deze marketplace zelf, ingeschakeld
  via [`settings.json`](settings.json) en aanroepbaar als `@specialists:<naam>`.
- **`settings.json`** — de harness-config: `extraKnownMarketplaces` (de `github`-source
  `DaveKJohn/davekjohns-workshop` — de repo wijst naar zichzelf) + `enabledPlugins`
  (`specialists@davekjohns-workshop`). [Sylvester #15](extensions/05-15-extension.md)'s domein.

## Hoe een specialist is opgebouwd

### Persona of subagent — één specialist, twee representaties

1. **Vakboek + repo-lens.** Het volledige, draagbare vakboek (craft, harde regels, toon) woont in de
   marketplace-plugin (`<plugin>/manuals/<group>-<id>-manual.md`); de repo-specifieke aanvulling staat
   lokaal in `.claude/extensions/<group>-<id>-extension.md`. Voor een **persona-only** specialist
   (die in het hoofdgesprek draait) staat de vólledige manual juist lokaal in `extensions/` — hij kan
   niet uit een plugin geladen worden.
2. **Agent-definitie** — `<group>-<id>-agent.md`, hier afkomstig uit de `specialists`-plugin. Dit is de
   compacte, uitvoerbare vorm (eigen context-venster, ingeperkte tools, eigen model) die de specialist
   tot een échte, parallel-aanroepbare subagent maakt. Ze **verwijst naar** het plugin-vakboek + de
   repo-lens en herhaalt de regels niet — zo blijft er één bron van waarheid.

**Regels:** bestaan beide, dan is de **manual leidend**; de agent-def is de uitvoerbare verkorting.
Een vakregel wijzig je in de manual; de agent-def alleen als de operationele kern of tool-set
verandert. Het *principe* en de manuals horen bij [Tessa #16](extensions/06-16-extension.md); de
agent-def-config (frontmatter, tools, model) bij [Sylvester #15](extensions/05-15-extension.md).
**Chris blijft een persona** — hij is de enige die Dave iets kan **vrágen**.

### Elke manual: draagbaar vak en repo-eigen slot

Elk vakboek is in tweeën opgebouwd, en die twee helften wonen fysiek apart:

1. **De body — het draagbare vak** (in de plugin-manual): het beroep generiek, zónder repo-termen
   ("hoofdbranch" i.p.v. `main`, geen concrete scriptnamen, geen `#id`-verwijzingen).
2. **`## Eigen aan deze repo (davekjohns-workshop)` — het repo-eigen slot** (de lens in `extensions/`):
   álles wat repo-specifiek is. Vaste opbouw: cursieve lens-regel → kernclaim → repo-secties → een
   "**hóé** (draagbaar) vs. **wát** (repo-eigen)"-slot.

[Tessa #16](extensions/06-16-extension.md) bewaakt deze tweedeling bij elke wijziging.

### Stabiel id + group — de bestandsnaam is `<group>-<id>`

Elke specialist heeft een vast, numeriek **`id`** (permanente identiteit, verandert nooit) en zit in
een **group** (organisatie-eenheid: **01 = Leiding, 02 = Staf, 03+ = teams**). De repo-laag heet
`<group>-<id>-extension.md`; het draagbare vakboek `<group>-<id>-manual.md` en de agent-def
`<group>-<id>-agent.md` wonen in de plugin. **Naam, emoji en titel zijn labels** — die mogen vrij
wijzigen; bestandsnaam en linkpaden hangen aan `id`/`group`, niet aan de naam. **De lint-poort bewaakt
het** ([Sylvester #15](extensions/05-15-extension.md)): elke bestandsnaam matcht de frontmatter
(`id:` én `group:`).

## Het team hier

Klein en onderhoud-gericht. Chris leidt; de rest voert uit.

```
[group 01] Chris 🧭 #01  (Chief of Staff — orchestrator, persona)
│
├─ [group 03] Rebecca 🔬 #07  (research specialist)
├─ [group 04] Tycho 🧪 #18  (test engineer)
├─ [group 05] Derek 🐙 #05 (DevOps, persona) · Rendall 🎬 #06 (release, persona) · Sylvester ⚙️ #15 (systeembeheer)
└─ [group 06] Tessa 📜 #16 (technical writer) · Edith 🔍 #17 (eindredacteur) · Victor 🧐 #19 (code reviewer) · Sean 🛡️ #23 (security engineer)
```

## Index van de aanwezige extensions

Het volledige roster + de routing staat in [`../CLAUDE.md`](../CLAUDE.md#het-team-roster--routing);
onderstaande lijst is puur navigatie naar de repo-extensies zelf.

| # | Specialist | Repo-extensie | Agent-def |
|---|---|---|---|
| 01 | Chris 🧭 — Chief of Staff | [`extensions/01-01-extension.md`](extensions/01-01-extension.md) | — (persona-only) |
| 05 | Derek 🐙 — DevOps Engineer | [`extensions/05-05-extension.md`](extensions/05-05-extension.md) | — (persona-only) |
| 06 | Rendall 🎬 — Release Manager | [`extensions/05-06-extension.md`](extensions/05-06-extension.md) | — (persona-only) |
| 07 | Rebecca 🔬 — Research Specialist | [`extensions/03-07-extension.md`](extensions/03-07-extension.md) | `@specialists:rebecca` |
| 15 | Sylvester ⚙️ — Systeembeheerder | [`extensions/05-15-extension.md`](extensions/05-15-extension.md) | `@specialists:sylvester` |
| 16 | Tessa 📜 — Technical Writer | [`extensions/06-16-extension.md`](extensions/06-16-extension.md) | `@specialists:tessa` |
| 17 | Edith 🔍 — Eindredacteur | [`extensions/06-17-extension.md`](extensions/06-17-extension.md) | `@specialists:edith` |
| 18 | Tycho 🧪 — Test Engineer | [`extensions/04-18-extension.md`](extensions/04-18-extension.md) | `@specialists:tycho` |
| 19 | Victor 🧐 — Code Reviewer | [`extensions/06-19-extension.md`](extensions/06-19-extension.md) | `@specialists:victor` |
| 23 | Sean 🛡️ — Security Engineer | [`extensions/06-23-extension.md`](extensions/06-23-extension.md) | `@specialists:sean` |

De rest van de `specialists`-plugin (Paula #09, Vera #11, Gwen #12, Cody #13) is óók
ingeschakeld en aanroepbaar als `@specialists:<naam>`, maar heeft in deze repo zelden werk en dus
(nog) geen repo-lens. Duikt zulk werk op, dan schrijft [Tessa #16](extensions/06-16-extension.md)
eerst de lens. De domein-plugins `specialists-lifehub` en `specialists-shopify` staan hier **uit** —
deze repo is geen life-hub-achtige of Shopify-repo.

## Deze indeling verandert mee

Het team en de teamindeling komen **in overleg met Dave** tot stand en kunnen wijzigen — precies zoals
nieuwe specialisten alleen in overleg ontstaan (zie
[Chris #01](extensions/01-01-extension.md#nieuwe-specialisten--alleen-in-overleg)). Wijzigt de
indeling, dan werkt Tessa dit document bij.
