# Changelog — specialists

Consumer-facing history of this plugin: per release, the changes that touched this plugin.
Automatically appended by `cut-release.ps1` of the marketplace repo (davekjohns-workshop); the full
workshop history lives there in `CHANGELOG.md` and `releases/`.

## v1.11.0 — 2026-07-20

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

[PR #99](https://github.com/DaveKJohn/davekjohns-workshop/pull/99)

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

[PR #94](https://github.com/DaveKJohn/davekjohns-workshop/pull/94)

---

## v1.10.0 — 2026-07-19

### #92 · Bootstrap schrijft een durabel, versie-loos body-importpad · Fix · 2026-07-19

Dicht een durability-gat dat een acceptatietest van consument djcylow-react aan het licht bracht
(Gat C): bij een user-scope install schreef de `specialists-init`-bootstrap een **versie-gepind**
body-importpad in `CLAUDE.md`
(`@~/.claude/plugins/cache/<marketplace>/<plugin>/<versie>/personas/01-01-persona.md`). De cache is
ephemeer — na een plugin-update wordt de oude versie-map opgeruimd (~7 dagen), waarna de `@`-import
naar een niet-bestaand pad wijst en de **body van de orchestrator (Chris) stil niet meer laadt**.

- **`bootstrap.ps1`**: nieuwe `Get-DurablePersonaDir` vertaalt een cache-pad
  (`…/plugins/cache/<marketplace>/…`) naar de versie-loze marketplaces-clone
  (`…/plugins/marketplaces/<marketplace>/…`) — het durabele anker dat een update overleeft (git-pull,
  pad verandert niet). De marketplace-naam wordt uit het cache-pad gerecupereerd; de clone wordt
  geverifieerd (bestaat, bevat de plugin-personas met `01-01-persona.md`) vóór hij wordt gebruikt.
  Bij elke twijfel terugval op het oorspronkelijke pad — geen regressie voor de source/marketplaces-
  layout (de bron die zichzelf consumeert verandert niet). De feitelijke *read* blijft de cache;
  alleen het geschreven pad wordt durabel.
- **Onderbouwing (research)**: `@`-imports in `CLAUDE.md` kennen géén variabele-expansie
  (`${CLAUDE_PLUGIN_ROOT}` e.d. werken daar niet), dus een vast versie-loos pad is de enige route.
- **`bootstrap-drift.tests.ps1`**: case (2c) toegevoegd die de user-scope layout nabootst
  (`plugins/cache/<mp>/…` naast een `plugins/marketplaces/<mp>/`-clone) en assert dat de geschreven
  `@`-import naar de clone wijst, niet naar de versie-gepinde cache.

Meegenomen robuustheidsfix aan de RepoName-afleiding (#91), aan het licht gekomen doordat CI-runners
een globale git-`insteadOf` zetten die `git@github.com:` naar een https-URL **mét token-userinfo**
herschrijft (`git remote get-url` past dat toe):

- **`bootstrap.ps1`**: de derivatie-regex tolereert nu optionele userinfo in de https-vorm
  (`https://<userinfo>@github.com/owner/repo`); de userinfo wordt bewust niet gevangen — alleen
  owner/repo, streng gevalideerd. Zo leidt ook een consument met credentials in de origin-URL correct af.
- **`bootstrap-drift.tests.ps1`**: de git-afleiding-cases draaien nu met een geneutraliseerde
  global/system git-config (zodat de ssh-case echt SSH test, immuun voor runner-`insteadOf`), plus een
  expliciete `https-cred`-case die de userinfo-tolerantie vastlegt.

[PR #92](https://github.com/DaveKJohn/davekjohns-workshop/pull/92)

---

### #91 · Bootstrap leidt RepoName automatisch af uit de git-remote · Feat · 2026-07-19

Ergonomie-verbetering aan het `specialists-init`-bootstrap-adoptiepad (Gat B): een verse consument
hoeft de repo-naam niet langer met de hand in te vullen.

- **`bootstrap.ps1` (sectie 1c)**: nieuwe `Get-DerivedRepoName` leidt `owner/repo` af uit
  `git remote get-url origin` van de consument en vult daarmee `$script:RepoName` in de neergezette
  `scripts/repo-config.ps1`-scaffold, in plaats van de `VUL-IN/repo`-placeholder. Ondersteunt de
  HTTPS- én SSH-vorm en stript het `.git`-suffix.
- **Guardrails (advies Sean)**: de remote-URL is externe input die in een geschreven `.ps1` én in
  `gh --repo` belandt — daarom een verankerde regex, owner/repo beperkt tot een strikte slug, alleen
  `github.com`, en bij elke twijfel (niet-github host, geen remote, git niet beschikbaar) terugval op
  de `VUL-IN`-placeholder. De git-aanroep zit in een `try/catch` + `2>$null`/`$LASTEXITCODE` en laat
  de bootstrap nooit crashen (blijft additief, exit 0). `Get-LintScript` en de branch-prefix-tabel
  blijven bewust VUL-IN — die zijn niet af te leiden.
- **Schonere scaffold-kop + slotrapport**: de kop van de repo-config-scaffold en stap 2 van het
  bootstrap-rapport melden nu wat er nog handmatig moet als RepoName al is afgeleid.
- **`bootstrap-drift.tests.ps1`**: cases toegevoegd voor de afleiding (HTTPS + SSH → afgeleid, geen
  VUL-IN op de RepoName-regel) en de terugval (niet-github host + geen remote → `VUL-IN/repo`).

[PR #91](https://github.com/DaveKJohn/davekjohns-workshop/pull/91)

---

## v1.9.2 — 2026-07-19

### #88 · specialists-init SKILL.md beschrijft het plugin-pad/lens-only-model (was: oude .claude/extensions-kopie) · Docs · 2026-07-19

Corrigeert een bestaande doc-drift in `specialists-init/SKILL.md`: de skill-tekst beschreef het
oude adoptiemodel (persona-bodykopie naar `.claude/extensions/`), terwijl `bootstrap.ps1` allang het
huidige model hanteert — **lens-only** repo-lenzen op het **plugin-pad**
`.claude/plugins/<familie>/<plugin>/`, met de draagbare body via een `@`-import uit de plugin-install,
en **twee** `@`-imports onderaan `CLAUDE.md` (body + lens).

- Frontmatter-`description`, de "Wat de skill doet"-stappen (persona-lenzen, lens-scaffolds, de
  @-imports) en de "Afronden"/"Belangrijk"-secties volgen nu het feitelijke bootstrap-gedrag.
- Puur documentatie: geen script- of gedragswijziging. De opgekomen drift was gesignaleerd tijdens
  de #86-fix en is bewust apart opgepakt.

[PR #88](https://github.com/DaveKJohn/davekjohns-workshop/pull/88)

---

## v1.9.1 — 2026-07-19

### #87 · specialists-init scaffoldt repo-config + branch-info; open-pr/fold pre-flighten (schone consument) · Fix · 2026-07-19

Dicht het script-afhankelijkheden-gat van de gedeelde workflow-skills op een schone consument (inbound
[#86](https://github.com/DaveKJohn/davekjohns-workshop/issues/86), vervolg op [#81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81)).
`open-pr`/`fold` leunen op twee repo-eigen bestanden in de consument-root (`scripts/repo-config.ps1` +
`scripts/lib/branch-info.ps1`) die de bootstrap niet neerzette — bij een eerste install liep dat op een
rauwe dot-source-fout.

- **Bootstrap-scaffold:** `specialists-init/bootstrap.ps1` zet beide bestanden nu additief als
  `VUL-IN`-scaffold neer (nooit overschrijven), met een **lege** branch-prefix-tabel — de taxonomie is
  per repo anders en wordt bewust niet meegebakken.
- **Pre-flight:** `open-pr` (beide bestanden) en `fold` (alleen `repo-config`) checken vóór de
  dot-source op aanwezigheid én op niet-ingevulde `VUL-IN`-placeholders, en stoppen anders met een
  duidelijke wegwijzer i.p.v. een rauwe fout. De spiegels zijn via de generator opnieuw gegenereerd.
- **Tests:** bootstrap-drift dekt de scaffold + idempotentie; shared-scripts dekt het pre-flight-gedrag
  van beide bron-scripts.
- **Docs:** de skill-teksten (`specialists-init`, `open-pr`, `fold-changelog`) en de plugin-scripts-README
  volgen het nieuwe gedrag; de fold-vereisten corrigeren meteen dat fold géén `branch-info` gebruikt.

[PR #87](https://github.com/DaveKJohn/davekjohns-workshop/pull/87)

---

## v1.9.0 — 2026-07-19

### #85 · Fase 2: open-pr gedeeld als plugin-spiegel (lint-gate via repo-config) · Feat · 2026-07-19

Tweede stap van Fase 2 uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81): `open-pr.ps1` wordt gedeeld met consumenten als plugin-spiegel, met dezelfde mechaniek als de fold-pilot.

- **`open-pr.ps1` dual-context** gemaakt (repo-root via `${CLAUDE_PROJECT_DIR}` of git-root); `repo-config` + `branch-info` uit de repo-root i.p.v. `$PSScriptRoot`.
- **Lint-gate geparametriseerd:** het repo-specifieke lint-script komt nu uit `Get-LintScript` in `repo-config` (workshop: `check-plugin-integrity`; een consument kan zijn eigen lint opgeven). De test-poort blijft conventie (`scripts/tests/*.tests.ps1`). Gate-meldingen zijn generiek gemaakt.
- **Spiegel + skill:** `open-pr` geregistreerd in `shared-scripts-lib.ps1`, spiegel gegenereerd, en een consument-skill `open-pr` toegevoegd.
- **Tests/docs:** `repo-config.tests.ps1` dekt `Get-LintScript`; `shared-scripts.tests.ps1` borgt dual-context voor álle gedeelde scripts; de README-statustabel bijgewerkt.

Daarmee zijn beide Fase 2-doelscripts (`fold` + `open-pr`) gedeeld; `branch-info`/`repo-config` blijven bewust per repo lokaal (CI-pin + repo-data).

[PR #85](https://github.com/DaveKJohn/davekjohns-workshop/pull/85)

---

### #84 · Fase 2-pilot: fold-changelog gedeeld als plugin-spiegel (SSOT voor consumenten) · Feat · 2026-07-19

Eerste stap van Fase 2 uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81): `fold-changelog-entry.ps1` wordt gedeeld met consumenten als plugin-spiegel — geen verhuizing, de workshop houdt zijn eigen testbare root-kopie.

- **Dual-context repo-root** in `fold-changelog-entry.ps1`: lost de repo-root op via `${CLAUDE_PROJECT_DIR}` (consument die de spiegel draait) of de git-root (workshop). Dezelfde file werkt in beide locaties; `repo-config` wordt uit de repo-root geladen i.p.v. `$PSScriptRoot`.
- **Spiegel-mechaniek** naar het bestaande `build-agent-defs`-patroon: `scripts/lib/shared-scripts-lib.ps1` (register), `scripts/sync/build-shared-scripts.ps1` (generator met `-Check`), en een drift-lint-sectie in `check-plugin-integrity.ps1` die bewaakt dat de plugin-spiegel LF-identiek blijft aan de bron.
- **Consument-skill** `fold-changelog` draait de spiegel via `${CLAUDE_PLUGIN_ROOT}` — het enige door de docs bevestigde mechaniek voor mens én Claude.
- **Tests:** nieuwe suite `shared-scripts.tests.ps1` (register-contract, in-sync-invariant, dual-context-borging, `-Check`-poort).
- **Docs:** `specialists/scripts/README.md` herschreven naar de werkende spiegel-mechaniek + statusoverzicht.

`open-pr` volgt als losse stap (de lint/test-gate moet eerst via `repo-config` geparametriseerd worden).

[PR #84](https://github.com/DaveKJohn/davekjohns-workshop/pull/84)

---

### #83 · Plugin-scripts-README: Fase 2-realiteit corrigeren (branch-info CI-pin + bin/-gaten) · Docs · 2026-07-19

Corrigeert twee onjuistheden in `claude-code-plugins/claude-specialists/specialists/scripts/README.md` die in #82 zelf ontstonden:

- **`branch-info.ps1` kan niet mee naar de plugin.** De README suggereerde dat dat kon zodra `open-pr.ps1` meeverhuist, maar dezelfde PR (#82) liet `release-lib.ps1` `branch-info` dot-sourcen; `release-lib` draait in CI vanaf een kale checkout, waardoor `branch-info` nu ook door CI aan de root is vastgeklonken.
- **De `bin/`-aanroepkeuze is niet settled.** `bin/` staat op de PATH van de Bash-tool (niet de PowerShell-tool), een mens kan het niet direct aanroepen, en Windows `.ps1`-als-kaal-commando + `${CLAUDE_PROJECT_DIR}`-beschikbaarheid zijn ongedocumenteerd. Een skill is het enige bevestigde alternatief. De README verwijst nu naar het Fase 2-addendum op [#81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81).

[PR #83](https://github.com/DaveKJohn/davekjohns-workshop/pull/83)

---

### #82 · Centraliseer workflow-scripts (SSOT): repo-config + type-bron + plugin-scripts-fundament · Feat · 2026-07-18

Eerste stappen op het SSOT-pad uit [issue #81](https://github.com/DaveKJohn/davekjohns-workshop/issues/81) (inbound van life-hub), zonder big-bang:

**Fase 0 (repo-lokaal, CI-veilig):**
- Nieuw `scripts/repo-config.ps1` als enige bron voor repo-data (`Get-RepoName`, `Get-RepoBlobUrl`). De repo-naam-hardcode is weg uit `open-pr.ps1` (1x), `fold-changelog-entry.ps1` (2x) en `cut-release.ps1` (blob-URL geinjecteerd i.p.v. de literal-default in `release-lib.ps1`).
- DRY-lek gedicht: de branch-typen (Feat/Fix/Docs/Chore) hebben nu een enige bron in `branch-info.ps1` via `Get-BranchTypes`; `release-lib.ps1` leest die i.p.v. een eigen `$catOrder`-kopie.

**Fase 1 (alleen structuur):**
- Nieuwe map `claude-code-plugins/claude-specialists/specialists/scripts/` met een README als toekomstig SSOT-thuis; de lint-parse-scan (`check-plugin-integrity.ps1`) bewaakt die map nu mee. Er is bewust nog geen script verhuisd (aanroep-mechaniek volgt later).

**Tests:** nieuwe suites `branch-info.tests.ps1` (incl. het type-SSOT-contract) en `repo-config.tests.ps1`.

[PR #82](https://github.com/DaveKJohn/davekjohns-workshop/pull/82)

---

## v1.8.0 — 2026-07-18

### #80 · Bootstrap seedt plugin-pad + lens-only (adoptie-laag) · Feat · 2026-07-18

De laatste stap om het plugin-pad + lens-only-model écht overal de standaard te maken: de
**adoptie-laag**. `bootstrap.ps1` (de `specialists-init`-skill) seedt een verse consument nu op het
**plugin-pad** met **lens-only** persona-lenzen — precies wat deze repo en life-hub al hebben — i.p.v.
het legacy-pad met volledige body-kopieën.

- **`bootstrap.ps1`** zet de lenzen op `.claude/plugins/<familie>/<plugin>/` (familie + plugin
  afgeleid uit het install-pad, met fallback voor de versie-cache-layout). De persona-lenzen zijn
  **lens-only**: alleen de lens-only-kop + het VUL-IN-repo-lens-slot, géén body-kopie. `CLAUDE.md`
  krijgt **twee** `@`-imports voor Chris: zijn draagbare body uit de plugin-install
  (`@~/.claude/plugins/marketplaces/<marketplace>/.../01-01-persona.md`) én zijn repo-lens.
- **Regressietests** (`bootstrap-drift.tests.ps1`) herschreven: plugin-pad, lens-only, de twee
  imports, de versie-cache-fallback en de behouden legacy-body-drift-vergelijking (30 asserts).
- **Docs** (`QUICKSTART.md`, `connectors/README.md`) bijgewerkt naar het plugin-pad + lens-only-model.

De body laadt runtime uit de plugin-install; dat `~`-import-pad is (net als bij life-hub) niet volledig
via de fixture-tests af te dwingen — de tests dekken de pad-/lens-only-structuur, het live `@`-import-
gedrag is bewezen doordat life-hub het draait. Lint + alle testsuites groen.

[PR #80](https://github.com/DaveKJohn/davekjohns-workshop/pull/80)

---

## v1.7.0 — 2026-07-18

### #77 · Repo-lenzen naar het plugin-pad als standaard (primair + legacy-fallback) · Feat · 2026-07-18

De repo-lenzen van deze repo verhuizen van het legacy-pad (`.claude/extensions/`) naar het
**plugin-pad** (`.claude/plugins/claude-specialists/specialists/`) — de nieuwe standaard-locatie
(pariteit met life-hub). Om de andere consumerende repo's (life-hub, smartwatchbanden) niet te breken,
verwijst het gedeelde contract voortaan naar het **plugin-pad als primair, met het legacy-pad als
fallback** — een repo die nog op legacy staat blijft dus gewoon werken.

**Deze repo:**
- De 11 lenzen (incl. Ravi 06-24) + het handboek verplaatst naar het plugin-pad, met de relatieve
  link-diepte bijgesteld (2 → 4 niveaus). De 5 lege stubs (Paula/Bianca/Vera/Gwen/Cody) opgeruimd.
- De `@`-import onderaan `CLAUDE.md` → plugin-pad. Alle doc-verwijzingen (`CLAUDE.md`, `README.md`,
  het handboek) → plugin-pad. De persona-lens-index-regels naar locatie-onafhankelijke platte tekst.
- `check-plugin-integrity.ps1` scant nu de lenzen op het plugin-pad **én** het legacy-pad.

**Het gedeelde contract (raakt alle repo's, via de volgende release):**
- De ~20 agent-defs en de ~20 manuals verwijzen subagents nu naar het plugin-pad (primair) met het
  legacy-pad als fallback. De generieke lens-mention in het gedeelde `grens-inbound`-blok idem.

**Bewust uitgesteld (blijft werken via de fallback):** de **adoptie-laag** — `bootstrap.ps1` seedt
nieuwe consumenten nog op het legacy-pad, en `QUICKSTART.md` / `connectors/README.md` beschrijven dat
zo. Dat volledig omzetten (incl. de bootstrap-tests) is een aparte vervolgstap; tot die tijd landt een
verse consument op legacy en werkt hij via de fallback.

Lint en alle testsuites groen. De `## Releases`-CHANGELOG-entries zijn als historisch record ongemoeid
gelaten.

[PR #77](https://github.com/DaveKJohn/davekjohns-workshop/pull/77)

---

### #76 · Persona-sjabloon-intro's gededupliceerd (Ravi's eerste klus) · Chore · 2026-07-18

Ravi's eerste opdracht: de persona-sjablonen op duplicatie scannen. Bevinding — er zijn **geen
verbatim-gedeelde gedragsbullets** over de vier persona's (Chris, Bianca, Derek, Rendall); de
gedragsregels zijn bewust rol-geformuleerd (rol-nuance, niet harmoniseren). De énige verbatim-duplicatie
was het **intro-uitleg-commentaar** — een grotendeels identieke herhaling van het gesplitste model dat
`README.md` al vastlegt, en dat (in een HTML-commentaar) het gedeelde-blok-mechanisme sowieso niet kan
gebruiken.

Actie: het intro-commentaar in de vier sjablonen ingekort tot een korte verwijzing naar `README.md`,
met behoud van de rol-specifieke eerste regel. Netto ~33 regels boilerplate weg, en minder ruis die een
lens-only consument via de `@`-import meelaadt (sluit aan op de #69-schoonmaak). Het commentaar staat
boven de H1, dus `Get-PortableBody` raakt het niet — geen drift-regressie.

Conclusie voor de toekomst: het sentinel-mechanisme uitbreiden naar persona's heeft nú geen payload
(geen deelbaar body-blok); dat wacht tot een verbatim-gedeelde persona-bullet daadwerkelijk opduikt.

[PR #76](https://github.com/DaveKJohn/davekjohns-workshop/pull/76)

---

### #75 · Ravi (refactoring-specialist / DRY-bewaker) toegevoegd aan het team · Feat · 2026-07-18

Een nieuw teamlid in de `specialists`-plugin (groep 06, de vóór-de-merge-bewakers): **Ravi ♻️
#06-24**, de refactoring-specialist. Zijn vak is *single source of truth*: hij is de staande
verantwoordelijke voor duplicatie van **gedragsregels** (grenzen/werkwijzen) over agent-defs en
persona's. Zodra dezelfde regel op ≥2 plekken staat, slaat hij alarm en promoveert die tot één
gedeelde bron — beschikbaar voor de kring die de regel deelt, **niet** automatisch voor iedereen.

- **`specialists/agents/06-24-agent.md`** — de subagent-def (`@specialists:ravi`), die zelf het
  gedeelde `grens-inbound`-blok via sentinels gebruikt (dogfooding).
- **`specialists/manuals/06-24-manual.md`** — het draagbare vakboek, met "globaal = beschikbaar voor
  een deel, niet automatisch voor iedereen" als harde regel.
- **`.claude/extensions/06-24-extension.md`** — de repo-lens: wat Ravi hier bewaakt (de agent-defs +
  persona's van deze marketplace) en het `agent-shared/`-build-en-lint-mechanisme dat hij bedient.
- **Roster ingehaakt** in `CLAUDE.md`, Chris' routingtabel + twee ketens (parallelle
  kwaliteitscheck vóór PR én een eigen "duplicatie globaliseren"-keten), en het
  specialisten-handboek (`.claude/README.md`) + de root-README.

Ravi's eerste openstaande klussen: het gedeelde-blok-mechanisme uitbreiden naar de persona-sjablonen,
de Tier 2-sweep (eindbericht/gespreksgeschiedenis/branch), en een detectie-lint als
alarmbel-automatisering. Doel: het project zo klein en efficiënt mogelijk houden.

[PR #75](https://github.com/DaveKJohn/davekjohns-workshop/pull/75)

---

## v1.6.0 — 2026-07-18

### #74 · Gedeelde agent-def-blokken uit een enkele bron (build-en-lint) · Feat · 2026-07-18

Verbatim-gedeelde bullets onder **Grenzen** — de inbound-regel (19/19 agent-defs), de
webcontent-regel (3) en de Artifact-publiceer-regel (2) — werden tot nu toe in elke agent-def
handmatig gedupliceerd; één regel wijzigen betekende tot 19 bestanden aanraken. Ze komen nu uit
**één bron**, ingevuld door een generator en bewaakt door de lint-poort.

- **`claude-code-plugins/claude-specialists/agent-shared/<naam>.md`** — de canonieke bron van elk
  gedeeld blok (naast de plugin-mappen, zodat het niet met de plugin-cache meereist).
- **In de agent-defs** verschijnt elk blok tussen `<!-- BEGIN/END shared:<naam> -->`-sentinels. De
  inhoud staat er letterlijk (altijd-geladen, self-contained — Claude Code kent geen native
  transclusie in een agent-def), maar is als gegenereerd gemarkeerd.
- **`scripts/agents/build-agent-defs.ps1`** (+ `scripts/lib/agent-shared-lib.ps1`) — vult elke
  gemarkeerde regio uit zijn bron. Wijzig het bronbestand → draai het script → alle agent-defs bij.
  `-Check` meldt drift zonder te schrijven.
- **`check-plugin-integrity.ps1` (check 7)** faalt zodra een gemarkeerde regio afwijkt van zijn bron
  (hand-edit binnen de sentinels of een vergeten rebuild) — dezelfde poort die `open-pr.ps1` en CI
  al draaien.
- Regressietests in `scripts/tests/agent-shared.tests.ps1` (10 asserts) dekken de expansie, de
  drift-detectie, een BEGIN-zonder-END, een onbekend blok en de repo-in-sync-smoke.

De 19 agent-defs zijn puur omwikkeld met sentinels — nul inhoudelijke wijziging. Aanpassen van een
gedeelde grens kost voortaan één edit + één build in plaats van 19 handmatige wijzigingen.

[PR #74](https://github.com/DaveKJohn/davekjohns-workshop/pull/74)

---

## v1.5.2 — 2026-07-18

### #73 · Persona-indexregel locatie-onafhankelijk (bron-fix inbound #64) · Fix · 2026-07-18

De indexregel onder de titel van de vier persona-sjablonen (`01-01`, `03-02`, `05-05`, `05-06`) droeg een pad-diepte-afhankelijke markdown-link naar de repo-CLAUDE.md (`](../../CLAUDE.md)`). Die diepte klopt alleen op het legacy-pad (2 niveaus); op het plugin-pad (4 niveaus) was het een dode link, waardoor de draagbare body daar nooit byte-identiek aan de bron kon zijn.

- **De indexregel is nu platte tekst** (`Index: de repo-CLAUDE.md · …`), locatie-onafhankelijk. Een consument neemt de body op elk pad byte-identiek over — geen dode link meer.
- **De link-diepte-normalisatie in `check-consumer-drift.ps1` (`Get-PortableBody`) is verwijderd**, want overbodig geworden: er is geen pad-afhankelijke link meer om te normaliseren. Dit ruimt de workaround uit PR #68 (v1.5.0) op ten gunste van een bron-fix.
- De regressietests zijn navenant bijgewerkt: de twee normalisatie-tests zijn vervangen door één guard die borgt dat de indexregel geen pad-diepte-link meer draagt.

Dit is de bron-oplossing voor inbound life-hub [#64](https://github.com/DaveKJohn/davekjohns-workshop/issues/64): PR #68 doodde het vals-positieve `DRIFTED`-signaal aan de check-kant, deze wijziging neemt de wortel weg. Consumenten laten bij de volgende sync de link in hun indexregel vallen.

[PR #73](https://github.com/DaveKJohn/davekjohns-workshop/pull/73)

---

## v1.5.1 — 2026-07-18

### #72 · Persona-sjablonen en drift-check kennen het lens-only-model · Fix · 2026-07-18

Twee samenhangende punten uit inbound life-hub [#69](https://github.com/DaveKJohn/davekjohns-workshop/issues/69), beide gevolg van het lens-only-model dat een consument geen body-kopie meer laat bewaren:

- **Het `## Eigen aan deze repo (VUL-IN)`-slot is uit de vier persona-sjablonen gehaald** (`01-01`, `03-02`, `05-05`, `05-06`). Bij een consument die de body rechtstreeks importeert (lens-only) laadde dat slot — een bootstrap-instructie, geen persona-inhoud — als ruis mee in elke sessie. De sjabloon-intro-comments zijn navenant bijgewerkt.
- **`bootstrap.ps1` genereert het VUL-IN-slot nu zelf** bij het kopiëren van een persona, in plaats van het uit het sjabloon over te nemen — zo houdt een verse consument een duidelijke plek voor de repo-lens (DRY met de lens-scaffolds van stap 1b).
- **`check-consumer-drift.ps1` kent het lens-only-model.** Een consument-extension die met de `> Repo-lens (lens-only persona)`-blockquote opent, heeft per definitie geen body-kopie; de check meldt die nu als `LENS-ONLY` in plaats van de vals-positieve `DRIFTED`. Zo betekent een `DRIFTED`-melding weer altijd een écht werkpunt.

De regressietests in `scripts/tests/bootstrap-drift.tests.ps1` borgen dat het sjabloon schoon is, dat de bootstrap zelf een VUL-IN-slot toevoegt (geen drift-regressie op een verse kopie) en dat een lens-only extension als `LENS-ONLY` wordt gerapporteerd.

[PR #72](https://github.com/DaveKJohn/davekjohns-workshop/pull/72)

---

### #71 · Inbound-regel toegevoegd aan alle agent-defs · Docs · 2026-07-17

Elk van de 19 agent-defs in de drie plugins (`specialists`, `specialists-lifehub`,
`specialists-shopify`) heeft nu een eigen bullet in zijn **Grenzen**-sectie die de
inbound-route benoemt: verbeterpunten aan de gedeelde kern (de eigen agent-def en vakboek,
die van collega's, en alle andere onderdelen die de plugin draagt) bouwt een specialist
niet lokaal om; hij meldt ze via de vaste, afgesproken route — een issue met het label
`inbound` op de bron-repo van de plugin (het issue-sjabloon staat er al klaar), generiek
beschreven en zonder repo-eigen, persoonlijke of gevoelige details uit de eigen repo.
Werkt hij al in de bron-repo zelf, dan volgt hij daar gewoon de normale keten. Repo-eigen
aanvullingen horen in de repo-lens. Zo kent ook een rechtstreeks aangeroepen
werker-subagent deze regel, niet alleen Chris' persona-body en de QUICKSTART. De
formulering is na twee correctierondes (Edith's eindredactie: generieke plugin-onderdelen
+ collega's-agent-defs; Sean's security-review: standing-route-framing + de
anonimiseringscaveat) tot deze definitieve tekst gekomen.

[PR #71](https://github.com/DaveKJohn/davekjohns-workshop/pull/71)

---

## v1.5.0 — 2026-07-17

### #66 · Chris sluit af zonder vaste slotformule · Docs · 2026-07-17

Op verzoek van Dave: de vaste afsluitvraag ("hoe kan ik verder van dienst zijn?") is uit stap 6 van Chris' ritueel gehaald — die werd eentonig. Chris vat nog steeds samen en mag een concrete volgende stap noemen, maar sluit af zonder standaard slotformule. Aangepast in beide bronnen: de repo-lens (`.claude/extensions/01-01-extension.md`) en het canonieke persona-sjabloon in de plugin (`personas/01-01-persona.md`).

[PR #66](https://github.com/DaveKJohn/davekjohns-workshop/pull/66)

---

### #61 · Per-plugin CHANGELOGs: consument-gerichte release-geschiedenis die meereist · Feat · 2026-07-16

Elke plugin draagt nu een eigen `CHANGELOG.md` die met de plugin-cache meereist: de
consument-gerichte selectie uit de werkplaats-geschiedenis. De fold leidt per entry automatisch
een `Plugins:`-regel af uit de PR-bestanden (`gh pr view --json files`; de `connectors/`-map telt
niet mee), en `cut-release.ps1` schrijft bij elke release per plugin de rakende entries bij —
nieuwste bovenaan, met root-relatieve links herschreven naar absolute GitHub-URLs zodat ze in een
consument-cache blijven werken. Vier nieuwe pure functies in `release-lib.ps1` met twaalf nieuwe
asserts (50 totaal); drie seed-CHANGELOGs; Rendall's lens en het root-README beschrijven het
mechaniek. De root-`CHANGELOG.md` en `releases/` blijven de volledige werkplaats-geschiedenis.

[PR #61](https://github.com/DaveKJohn/davekjohns-workshop/pull/61)
