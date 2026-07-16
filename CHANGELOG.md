# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #46 · Persona-sjabloon voor Bianca (Biograaf, #02) · Feat · 2026-07-16

De vier persona-only hoofdloop-rollen zijn nu compleet gespiegeld in de `specialists`-plugin: naast Chris/Derek/Rendall krijgt ook Bianca haar draagbare persona-sjabloon (`personas/03-02-persona.md`). De body is letterlijk overgenomen uit haar consument-manual, zodat bron en kopie in lijn zijn; de index-blockquote en het repo-lens-slot volgen het draagbare sjabloon-format. De drie sjabloon-opsommingen in `README.md` + `CLAUDE.md` noemen Bianca nu mee — de workshop-roster bewust niet, want zij is geen marketplace-onderhouder maar puur een sjabloon-bron voor consumenten. Aanleiding: een consistentie-audit in life-hub vond dat Bianca als enige van de vier persona-only rollen geen plugin-spiegel had. check-plugin-integrity: 0 errors.

[PR #46](https://github.com/DaveKJohn/davekjohns-workshop/pull/46)

---

### #45 · Slotwoord toegevoegd aan het Copilot-dossier · Docs · 2026-07-16

Slotwoord toegevoegd aan `research/copilot/bevindingen.md`: waarom Copilot deze repo weinig
toevoegt — de specialisten zijn een werkwijze (governance + vakwerk, synchroon onder Dave's regie),
Copilot een platform-actor die vooral asynchrone capaciteit en een externe reviewstem zou brengen.
Met het besluit niet te upgraden mist de repo gemak, geen kwaliteit.

[PR #45](https://github.com/DaveKJohn/davekjohns-workshop/pull/45)

---

### #44 · Merget-fix: foutieve vervoeging hersteld in agent-defs en manual · Fix · 2026-07-16

De foutieve vervoeging "merget" vervangen door "mergt" op alle drie de vindplaatsen:
`06-19-agent.md`, `06-23-agent.md` én `06-19-manual.md` (de derde vindplaats kwam boven bij het
opzetten van issue #42). Vondst van Edith (15 juli 2026); werkplan-stap 6, sluit issue #42. Let op:
de gedeelde agent-defs bereiken consumenten pas ná een release-bump.

[PR #44](https://github.com/DaveKJohn/davekjohns-workshop/pull/44)

---

### #43 · Copilot-dossier geparkeerd: geen betaald plan, geen upgrade · Docs · 2026-07-16

Uitkomst van de Copilot-proef vastgelegd: de coding-agent-testcase (issue #42) strandde op de
licentie-check — beide accounts hebben Copilot Free en Dave besloot niet te upgraden. Werkplan-
stappen 8–10 in `research/plugin-sharing/vervolgstappen.md` zijn geparkeerd en de uitkomst is
(incl. de beantwoorde open punten b en c) toegevoegd aan `research/copilot/bevindingen.md`. De
"merget"-fix (stap 6) loopt gewoon via de eigen specialist-keten.

[PR #43](https://github.com/DaveKJohn/davekjohns-workshop/pull/43)

---

### #41 · Taalfix in de quote-les na eindredactie · Fix · 2026-07-16

Twee taalpunten van Edith in de quote-les (`.claude/extensions/05-05-extension.md`) hersteld, die
na de merge van PR #40 binnenkwamen: congruentie ("tekst die ze écht nodig hebben" i.p.v. "heeft")
en de huisstijl-imperatief ("houd" i.p.v. "hou").

[PR #41](https://github.com/DaveKJohn/davekjohns-workshop/pull/41)

---

### #40 · Quote-les geborgd: geen dubbele aanhalingstekens in native argumenten · Docs · 2026-07-16

Geleerde les van 16 juli vastgelegd in Dereks lens (`.claude/extensions/05-05-extension.md`, nieuwe
sectie "De quote-les"): PowerShell 5.1 verminkt dubbele aanhalingstekens in argumenten voor native
commando's (`git`, `gh`) — een `"` in een commit-message laat `git commit -m` afketsen. Werkwijze:
inline argumenten vrij van `"` houden, of de tekst via een bestand doorgeven (`git commit -F`,
`gh … --body-file`). De bestaande PR-body-vermelding verwijst nu naar deze sectie.

[PR #40](https://github.com/DaveKJohn/davekjohns-workshop/pull/40)

---

### #39 · Fold-les geborgd: check `git branch --show-current` vóór het folden · Docs · 2026-07-16

Geleerde les van 16 juli vastgelegd in Rendalls lens (`.claude/extensions/05-06-extension.md`,
fold-levenscyclus stap 2): `gh pr merge --delete-branch` belooft ook de lokale branch op te ruimen,
maar kan de lokale checkout op de gemergde branch laten staan — check daarom vóór de fold met
`git branch --show-current` dat je écht op `main` staat.

[PR #39](https://github.com/DaveKJohn/davekjohns-workshop/pull/39)

---

### #38 · Copilot-onderzoek in het werkplan + repo-lens voor Rebecca · Docs · 2026-07-16

Copilot-onderzoek van Rebecca #07 vastgelegd in `research/copilot/bevindingen.md` (productpalet
juli 2026, kosten, inzet-opties A/B/C met aanbevelingen) en als stappen 8–10 toegevoegd aan het
werkplan van 16 juli in `research/plugin-sharing/vervolgstappen.md`. Rebecca kreeg daarbij — conform
de handboek-regel — haar eerste repo-lens (`.claude/extensions/03-07-extension.md`); roster,
routingtabel en handboek-index zijn daarop bijgewerkt.

[PR #38](https://github.com/DaveKJohn/davekjohns-workshop/pull/38)

---

### #37 · Werkplan 16 juli vastgelegd: v1.1.1-uitrol naar de consumenten + opruim- en fix-klusjes · Docs · 2026-07-15

Na de eindbalans van 15 juli (werkbomen schoon, drift-check exit 0, maar de domein-plugins nog op
v1.0.0 tegenover de v1.1.1-bron) is in `research/plugin-sharing/vervolgstappen.md` een **werkplan
voor 16 juli** vastgelegd, in volgorde: de domein-plugin van smartwatchbanden naar v1.1.1 (volgens
de scope-les-werkwijze), in life-hub eerst het kern-record verifiëren en daarna de domein-plugin
naar v1.1.1, de persona-drift in life-hub beoordelen, de oude `claude-specialists`-kloon op beide
machines verwijderen, de swb-borging + opruiming van de oude v0.1.0-records, de "merget"-fix in
twee gedeelde agent-defs, en een afsluitende hercheck vanuit de werkplaats.

[PR #37](https://github.com/DaveKJohn/davekjohns-workshop/pull/37)

---

### #36 · Ruleset-lessen geborgd: bypass-zichtbaarheid en de Write-bypass van main-ci-poort · Docs · 2026-07-15

Twee lessen uit het instellen van de repo-ruleset `main-ci-poort` (de CI-check `lint-en-tests` als
required status check op `main`) geborgd in `research/plugin-sharing/vervolgstappen.md`: de
**ruleset-verificatie-les** (het `bypass_actors`-veld is alleen zichtbaar voor repo-admins — een
niet-admin-account ziet een gevulde bypass-list als leeg; verifieer daarom als het account dat gaat
pushen, via `current_user_can_bypass`) en de **Write-bypass-kanttekening** (de Write-rol staat bewust
in de bypass-list omdat werk-account `davekokbwj` op een persoonlijke repo geen admin kan zijn;
veilig zolang er geen externe collaborators zijn, daarna herzien). Daarnaast is de ruleset zelf als
blijvende staat vastgelegd in Sylvesters repo-lens (`.claude/extensions/05-15-extension.md`), bij de
CI-poort-beschrijving.

[PR #36](https://github.com/DaveKJohn/davekjohns-workshop/pull/36)

---

### #35 · Marker-structuur-les geborgd: .in_use is een map met PID-bestanden · Docs · 2026-07-15

Geleerde les uit de cache-opruiming na de v1.1.1-herstart geborgd in
`research/plugin-sharing/vervolgstappen.md`: de `.in_use`-marker van een plugin-cache-versie is geen
bestand maar een **map**, waarin elke gebruikende sessie een eigen PID-bestand (`{"pid":N}`)
schrijft. In-gebruik-zijn check je dus niet met een file-lock-test (die geeft op een map altijd vals
alarm), maar door in de map te kijken: leeg = vrij, en een aanwezig PID-bestand wijst exact de
gebruikende sessie aan. Daarnaast is vervolgstap 3 geactualiseerd: de twee verweesde cache-mappen
(`specialists/1.0.0` en `1.1.0`) zijn na de sessie-herstart daadwerkelijk verwijderd, met de
v1.1.1-verificatie erbij vermeld.

[PR #35](https://github.com/DaveKJohn/davekjohns-workshop/pull/35)

---

### #34 · Record-les geborgd: verweesd plugin-record chirurgisch opgeruimd · Docs · 2026-07-15

`research/plugin-sharing/vervolgstappen.md` bijgewerkt na het opruimen van het verweesde
plugin-record: vervolgstap 3 is afgevinkt (map-hernoem + record-opruiming afgerond; de twee
cache-mappen waar geen record meer naar verwijst wachten op een sessie-herstart) en er is een
**record-les** geborgd bij de geleerde lessen: een verweesd record ruim je preciezer op via
`~/.claude/plugins/installed_plugins.json` (identificeerbaar aan `projectPath`) dan via `/plugin` of
`claude plugin uninstall`, dat dezelfde vage project-doelbepaling heeft als het update-commando uit
de eerder geborgde scope-les — met de veilige volgorde
(pad-verificatie, backup, chirurgische verwijdering, JSON-validatie + `list --json`-check).

[PR #34](https://github.com/DaveKJohn/davekjohns-workshop/pull/34)

---

### #33 · CLI-scope-les geborgd: plugin update filtert niet op werkdirectory · Docs · 2026-07-15

Geleerde les uit de v1.1.1-plugin-update geborgd in `research/plugin-sharing/vervolgstappen.md`:
`claude plugin update -s project` filtert níét op de werkdirectory (vanuit deze repo gedraaid werkte
het commando het record van smartwatchbanden bij) en `claude plugin list` toont zonder `--json` niet bij welk
project een record hoort. De vastgelegde werkwijze: controleren met `claude plugin list --json`
(`projectPath`), bijwerken via `claude plugin install -s project` vanuit de doel-repo, en herstarten
om de nieuwe versie te laden. Daarnaast is vervolgstap 3 geactualiseerd (de map-hernoem is gebeurd;
er resteert een verweesd plugin-record op het oude pad) en de plugin-versie-vermelding bijgewerkt
naar v1.1.1.

[PR #33](https://github.com/DaveKJohn/davekjohns-workshop/pull/33)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

### [v1.1.1] - 2026-07-15 — Patch

Zie [releases/development/1.1/1.1.1.md](releases/development/1.1/1.1.1.md) voor de volledige release-notes.

---

### [v1.1.0] - 2026-07-15 — Minor

Zie [releases/development/1.1/1.1.0.md](releases/development/1.1/1.1.0.md) voor de volledige release-notes.

---

### [v1.0.0] - 2026-07-14 — Major

Zie [releases/development/1.0/1.0.0.md](releases/development/1.0/1.0.0.md) voor de volledige release-notes.
