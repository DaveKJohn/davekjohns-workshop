# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

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
