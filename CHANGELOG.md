# Changelog

De geschiedenis van de davekjohns-workshop-marketplace: onder **Pull Requests** elke gemergde branch
met zijn PR, onder **Releases** de vastgelegde versies. Hoe het mechanisme werkt (entry-bestanden,
folden) staat in [`README.md`](README.md#bijdragen--changelog--pr-workflow).

## Pull Requests

Alles wat sinds de laatste release naar `main` is gemergd — nieuwste bovenaan, één blok per pull
request.

### #99 · Sessiestart-hook meldt alleen nog blokkerende signalen — INFO blijft stil · Feat · 2026-07-20

De SessionStart-hook toonde bij elke sessiestart óók de `[INFO]`-signalen uit de connectors-check:
registeradministratie over de sync-stand van consumenten (manifest achter op de bronversie, een
niet-geregistreerde extension). Die stand leeft vaak op een andere machine of bij een andere
gebruiker, en ook waar hij hier bij te werken is, is het administratie op eigen tempo — geen
sessiestart-werk. Het schaalt bovendien niet naarmate meer repo's de plugin installeren (wens
Dave).

- **`connector-sessioncheck.ps1`**: het signaalfilter is beperkt tot `[FOUT]`/`[DRIFTED]` — alleen
  wat hier en nu oplosbaar is bereikt de sessie-context. De OK-melding is daarop aangepast
  ("geen fouten"). `[INFO]` blijft volledig zichtbaar bij een bewuste run van
  `scripts/sync/check-connectors.ps1` in de workshop; aan de check zelf verandert niets.
- **`connectors.tests.ps1`**: nieuwe stub-case borgt dat INFO-regels nooit als sessie-alert
  doorlekken; de bestaande schone-stub-case volgt de nieuwe OK-melding.
- **`connectors/README.md`**: de sessie-check-doctrine beschrijft de FOUT/INFO-scheiding.

Let op de versie-poort: consumenten (en de workshop zelf, die zichzelf consumeert) draaien de
nieuwe hook pas na een release-bump + `claude plugin update` + sessie-herstart.

Plugins: specialists

Plugins: specialists

[PR #99](https://github.com/DaveKJohn/davekjohns-workshop/pull/99)

---

### #98 · swb gesynct naar v1.10.0 -- manifest bijgewerkt · Chore · 2026-07-20

De connector `davekokbwj/smartwatchbanden` is op deze machine via `claude plugin update` naar v1.10.0 gehaald (machine-record op v1.10.0, content-drift 0). Het register liep administratief achter: `syncedVersion` stond voor beide plugins (`specialists` en `specialists-shopify`) nog op v1.4.1. Bijgewerkt naar v1.10.0, `status` van `attentie` naar `in-sync`, `lastChecked` naar 2026-07-20 en de verlopen ATTENTIE-notitie opgeschoond.

[PR #98](https://github.com/DaveKJohn/davekjohns-workshop/pull/98)

---

### #97 · PowerShell-exitcode-valkuil geborgd in Sylvester's repo-lens · Docs · 2026-07-19

Legt de scriptregel vast die de flaky CI-jacht (#94/#95/#96) opleverde, zodat een vierde herhaling
wordt voorkomen.

- **`05-15-extension.md` (Repo-eigen regels):** bullet toegevoegd — `$LASTEXITCODE` altijd lezen
  vóór je een native command (bv. `git`) door een cmdlet pipt. `& git … | Select-Object -First 1`
  breekt de upstream vroegtijdig af, wat de exitcode timing-afhankelijk op non-nul kan zetten en zo een
  niet-deterministisch rode CI inbouwt. De regel: eerst de volledige output vangen, meteen
  `$code = $LASTEXITCODE` vastleggen, en pas daarna filteren op de vaste array. Geldt voor elke
  `scripts/**/*.ps1` die een native command aanroept.

Borgt de les uit #96 op een draagbare plek (de docs, niet alleen het geheugen).

[PR #97](https://github.com/DaveKJohn/davekjohns-workshop/pull/97)

---

### #93 · Canoniek marketplace-kanaal gedocumenteerd (oude claude-specialists-naam is een redirect) · Docs · 2026-07-19

Legt de marketplace-kanaal-strategie vast, na een inbound-bevinding uit de djcylow-react-acceptatietest
van v1.10.0: een consument zag op het `claude-specialists`-kanaal stil de oude v1.9.2.

- **Bevinding (geen codegat):** `DaveKJohn/claude-specialists` is **geen aparte repo** maar de oude
  naam van deze repo — een GitHub-rename-redirect naar `DaveKJohn/davekjohns-workshop`
  (`git ls-remote` op de oude naam geeft de actuele `HEAD`, v1.10.0). De "1.9.2 op dat kanaal" was een
  **verouderde lokale marketplace-clone**, geen achterlopende bron. Route "mirror v1.10.0 naar
  claude-specialists" is dus niet van toepassing — het is dezelfde repo.
- **`README.md` (Consumptie):** notitie toegevoegd dat `davekjohns-workshop` het enige canonieke
  kanaal is, dat de oude `claude-specialists`-naam via redirect naar dezelfde repo wijst (geen tweede
  bron), en dat een oude lokale registratie kan achterlopen — bij te werken met een marketplace-update
  of opnieuw toe te voegen onder de canonieke naam. Een verse install gebruikt altijd
  `DaveKJohn/davekjohns-workshop`.

Geen open issues om te sluiten; v1.10.0 dekt #90, #91 (incl. userinfo-tolerantie) en #92 aantoonbaar
af (in een echte consument geverifieerd).

[PR #93](https://github.com/DaveKJohn/davekjohns-workshop/pull/93)

---

### #96 · RepoName-afleiding immuun voor de pipeline-exitcode-race (echte kern-oorzaak CI-flakiness) · Fix · 2026-07-19

De git-afleiding in de bootstrap bleef na #94 en #95 nog **niet-deterministisch** rood op CI (de
ssh-cases faalden soms, soms niet): dezelfde code, dezelfde omgeving, wisselend resultaat. De kern-
oorzaak is nu gevonden en weggenomen.

- **Oorzaak:** `Get-DerivedRepoName` las de origin als
  `& git ... config --get remote.origin.url | Select-Object -First 1`. Die pipe breekt de upstream
  (git) vroegtijdig af zodra de eerste regel binnen is; als git op dat moment nog niet netjes is
  afgesloten, wordt het proces met een **non-nul exitcode** beeindigd — puur timing-afhankelijk. Die
  flaky `$LASTEXITCODE` liet de exitcode-guard soms `$null` teruggeven, waarna de scaffold op VUL-IN
  bleef staan en de drift-test faalde. Een byte-exacte probe won de race consequent; de echte
  bootstrap soms niet — vandaar het "onverklaarbare" verschil.
- **`bootstrap.ps1`**: de git-aanroep en `Select-Object -First 1` zijn ontkoppeld. Eerst wordt de
  volledige output gevangen, dan meteen `$LASTEXITCODE` in `$code` vastgelegd, en pas daarna volgt
  `Select-Object` op de vaste array. Zo kan de pipeline-afbraak de exitcode niet meer corrumperen.
- **Gevolg:** de afleiding is nu deterministisch — de exitcode weerspiegelt uitsluitend git zelf,
  onafhankelijk van pipeline-timing.

Rondt de jacht af die in #94 en #95 begon; sluit de flaky-blokker onder PR #93.

Plugins: specialists

[PR #96](https://github.com/DaveKJohn/davekjohns-workshop/pull/96)

---

### #95 · Bootstrap leest de origin rauw via git config (immuun voor insteadOf, CI stabiel) · Fix · 2026-07-19

Verhelpt de kern-oorzaak van de flaky RepoName-afleiding-test (opvolger van #94): de bootstrap las de
origin via `git remote get-url`, dat **`insteadOf`-herschrijvingen toepast**. CI-runners (en sommige
dev-machines) zetten zulke regels globaal, en welke vorm ze produceren (kale https, token-https,
`ssh://`) verschilt per run — waardoor de afleiding intermittent op VUL-IN terugviel en de test soms
faalde. De brede regex (#94) verzachtte dat maar nam de onvoorspelbaarheid niet weg.

- **`bootstrap.ps1`**: leest de origin nu via `git config --get remote.origin.url`, dat de **rauwe**
  opgeslagen URL teruggeeft en `insteadOf` volledig negeert — exact wat de consument configureerde,
  immuun voor de git-config van de machine.
- **`bootstrap-drift.tests.ps1`**: de flaky git-config-isolatie (lege global/system) is verwijderd
  (niet meer nodig); de zes afleiding-cases blijven. Bewezen: de suite slaagt nu ook onder een actief
  vijandige `insteadOf` die `git@github.com:`/`ssh://` naar een token-https herschrijft.

Geen gedragswijziging voor consumenten met een gewone origin; puur een deterministische, machine-
onafhankelijke afleiding.

Plugins: specialists

[PR #95](https://github.com/DaveKJohn/davekjohns-workshop/pull/95)

---

### #94 · RepoName-afleiding dekt alle github-URL-vormen (regex verbreed, CI-flakiness weg) · Fix · 2026-07-19

Maakt de RepoName-afleiding (#91) robuust voor álle github-URL-vormen en verhelpt daarmee een
**flaky CI-test**: de git-afleiding-cases faalden intermittent op de windows-runner doordat die een
globale git-`insteadOf` zet die `git@github.com:` naar wisselende vormen herschrijft (kale https,
https met token-userinfo, of `ssh://`) — en `git remote get-url` past die rewrite toe. De regex uit
#91/#92 dekte niet alle vormen, dus soms viel de afleiding terug op VUL-IN en faalde de test.

- **`bootstrap.ps1`**: de derivatie-regex accepteert nu alle gangbare github-vormen —
  `https://`, `ssh://`, `git://` (elk met optionele userinfo) én de scp-achtige `git@github.com:`.
  owner/repo blijft een strikte slug; userinfo wordt niet gevangen (een `evil.com/x@github.com`-spoof
  matcht dus niet).
- **`bootstrap-drift.tests.ps1`**: de git-afleiding-cases draaien met een geneutraliseerde
  global/system git-config (elke case test echt zijn eigen URL-vorm, immuun voor runner-`insteadOf`),
  met een extra `ssh-scheme`-case (`ssh://git@github.com/...`).

Geen gedragswijziging voor consumenten met een gewone origin-URL; puur bredere dekking + een
deterministische testsuite.

Plugins: specialists

[PR #94](https://github.com/DaveKJohn/davekjohns-workshop/pull/94)

---

## Releases

De vastgelegde versies van de marketplace — nieuwste bovenaan. Elke release bumpt alle
plugin-versies in lockstep en verwijst naar de volledige notes in `releases/development/`.

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
