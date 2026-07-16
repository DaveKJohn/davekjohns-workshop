# Plugin-sharing-traject — stand & vervolgstappen

> Logboek van de afronding van het marketplace-migratie-traject
> (claude-specialists → davekjohns-workshop). Spiegelt de traject-documentatie in
> smartwatchbanden (`research/plugin-sharing/`). Laatst bijgewerkt: **16 juli 2026**.

## Stand van zaken (geverifieerd 15 juli 2026)

Beide consumerende repo's zijn over op de `davekjohns-workshop`-marketplace
(github-source `DaveKJohn/davekjohns-workshop`):

| Consument | Status | Bewijs |
|---|---|---|
| **smartwatchbanden** | ✅ Over | swb PR #185; rooktest geslaagd — 13 specialist-agents geladen uit de plugin-cache (10× `specialists`, 3× `specialists-shopify`) |
| **life-hub** | ✅ Over | commit `ade7d4b` ("config: marketplace hernoemd naar davekjohns-workshop"); `specialists` + `specialists-lifehub` ingeschakeld; drift-check vanuit dit repo: exit 0 (18 agent-defs MISSING = gemigreerd, persona's IDENTICAL) |

Dit repo zelf: drie plugins (`specialists`, `specialists-lifehub`, `specialists-shopify`),
alle **v1.1.1** (lockstep); `check-plugin-integrity.ps1` groen; de repo consumeert zichzelf via de
github-source (zie [`CLAUDE.md`](../../CLAUDE.md)).

## Vervolgstappen

1. **Oude `claude-specialists`-marketplace-kloon opruimen** — nu beide consumenten over
   zijn, is de blokkade weg. Handmatige actie van Dave, op **beide machines** (beide
   Windows-profielen):
   `/plugin marketplace remove claude-specialists`
   De kloon staat in `~/.claude/plugins/cache/claude-specialists/`.
2. **Borging in smartwatchbanden** — de migratie-afronding (rooktest, stale
   `.in_use`-marker-les: sessie-herstart was de fix) daar vastleggen in
   `research/plugin-sharing/README.md`; staat nu alleen in swb-sessiegeheugen.
3. ✅ **Restant van de map-hernoem — afgerond (15 juli 2026):** de checkout-map is hernoemd
   naar `...\DaveKJohn\davekjohns-workshop` en het verweesde plugin-record aan het oude pad
   `...\DaveKJohn\claude-specialists` is opgeruimd — niet via `/plugin` of de CLI, maar
   chirurgisch via de administratie zelf, zie de record-les hieronder. De twee cache-mappen
   waar geen record meer naar verwijst (`cache/davekjohns-workshop/specialists/1.0.0` en `1.1.0`)
   zijn ná de sessie-herstart verwijderd (15 juli 2026): hun `.in_use`-markers waren leeg
   (geen sessie hield ze meer vast — zie de marker-structuur-les hieronder) en de nieuwe
   sessie draaide geverifieerd op v1.1.1 (`claude plugin list --json`, `projectPath`-check).

## Werkplan 16 juli 2026

Opgesteld na de eindbalans van 15 juli: alle drie de werkbomen schoon, drift-check exit 0,
maar de domein-plugins staan nog op v1.0.0 tegenover de v1.1.1-bron (geverifieerd via
`claude plugin list --json`). Volgorde: eerst de consumenten
bijwerken, dan de opruim- en fix-klusjes, en afsluiten met een hercheck.

1. **smartwatchbanden — `specialists-shopify` naar v1.1.1.** Vanuit de swb-repo (scope-les!):
   vooraf én achteraf `claude plugin list --json` (het `projectPath`-veld), bijwerken via
   `claude plugin install -s project`, daarna sessie-herstart en `git status` checken
   (de install kan line-endings van `.claude/settings.json` herschrijven).
2. **life-hub — kern-record verifiëren + `specialists-lifehub` naar v1.1.1.** Eerst vanuit
   life-hub met `claude plugin list --json` checken of er een record voor de
   `specialists`-kern bestaat (op de werkplaats-machine is er alleen een record van de
   domein-plugin zichtbaar); daarna dezelfde update-werkwijze als bij swb.
3. **life-hub — persona-drift bekijken.** De extensions van Chris (01-01) en Derek (05-05)
   wijken daar af van de canonieke persona-bodies (drift-check 15 juli, informatief). Bepalen:
   lokale verbetering die eerst terug naar de bron moet (wijzigingen landen altijd eerst in
   davekjohns-workshop), of bewuste repo-eigen afwijking die de bron niet raakt.
4. **Beide machines — oude `claude-specialists`-marketplace-kloon verwijderen.** Vervolgstap 1
   hierboven: `/plugin marketplace remove claude-specialists` — handmatige actie van Dave.
5. **smartwatchbanden — borging + oude records opruimen.** Vervolgstap 2 hierboven: de
   migratie-afronding vastleggen in swb's `research/plugin-sharing/README.md`, en daarnaast
   de twee uitgeschakelde v0.1.0-records van swb's oude eigen marketplace
   (`specialists@smartwatchbanden`, `swb-specialists@smartwatchbanden`) + de bijbehorende
   cache-map opruimen volgens de record-les-werkwijze hieronder.
6. ✅ **davekjohns-workshop — de "merget"-fix in de gedeelde agent-defs — afgerond (16 juli 2026):**
   via PR #44 hersteld op alle **drie** de vindplaatsen — `06-19-agent.md`, `06-23-agent.md` én
   `06-19-manual.md` (de derde kwam boven bij het opzetten van issue #42, dat bij de merge
   automatisch is gesloten). Let op: deze gedeelde agent-defs bereiken de consumenten pas ná een
   release-bump.
7. **Sluitstuk — hercheck vanuit de werkplaats.** Drift-check tegen beide consumenten en
   `claude plugin list --json` — alles hoort dan op v1.1.1 te staan zonder drift.

### Stand na de eind-hercheck van 16 juli 2026

Stap 7 is op 16 juli een eerste keer gedraaid vanuit de werkplaats (drift-checks + plugin-lijst).
Het structurele werk blijkt gezond; wat rest is uitsluitend het geplande consumenten-handwerk:

- ✅ **Drift-checks beide exit 0**: alle 19 agent-defs MISSING (= gemigreerd) in life-hub én
  smartwatchbanden, nul drift, nul dode kopieën; bij swb zijn ook alle drie de persona's IDENTICAL.
- ✅ **`specialists`-kern op v1.1.1** bij smartwatchbanden en de werkplaats zelf.
- ⏳ **Stap 1 en 2 blijven open**: `specialists-shopify` (swb) en `specialists-lifehub` (life-hub)
  staan nog op v1.0.0, en er is nog steeds geen record van de `specialists`-kern voor life-hub.
- ⏳ **Stap 3 blijft open**: de persona-drift in life-hub is er nog — Chris (01-01) en Derek (05-05)
  DRIFTED (informatief), Rendall (05-06) gelijk aan de bron.
- ⏳ **Stap 5 blijft open**: de twee oude v0.1.0-records van swb's eigen marketplace staan nog in de
  administratie.
- ✳️ **Stap 4 is op de werkplaats-machine al (deels) gebeurd**: de oude
  `claude-specialists`-kloon staat daar niet meer in de plugin-cache; de tweede machine is vanaf
  hier niet controleerbaar en moet Dave zelf nalopen.
- ⚠️ **Observatie voor bij stappen 1–2**: beide domein-plugin-records tonen vanuit de werkplaats
  `enabled: false`. Mogelijk een kijk-artefact (zie de scope-les hieronder: de project-context van
  de plugin-commando's is van buitenaf onbetrouwbaar) — dubbelcheck vanuit de doel-repo's zelf of
  de domein-plugins daar echt nog aanstaan.

Na het uitvoeren van stappen 1, 2, 3 en 5 wordt de hercheck herhaald als échte eindstreep.

Toegevoegd 16 juli, na het Copilot-onderzoek van Rebecca #07 (volledige bevindingen + bronnen in
[`research/copilot/bevindingen.md`](../copilot/bevindingen.md)) — en **diezelfde dag geparkeerd**:
de proef met de coding agent (stap 10, door Dave goedgekeurd met de "merget"-fix als testcase,
issue #42) strandde op de licentie-check — beide accounts (`DaveKJohn` én `davekokbwj`) blijken
**Copilot Free** te hebben, en de coding agent en automatische code review vereisen een betaald
plan. Dave besloot niet te upgraden; Copilot blijft voorlopig liggen. De uitkomst per stap:

8. ⏸️ **`.github/copilot-instructions.md` opstellen** — geparkeerd samen met de rest: zonder
   Copilot-gebruik is er niets dat het bestand leest. Wordt Copilot ooit alsnog geactiveerd, dan is
   dit de eerste stap (laag risico; werk voor Tessa; de coding agent leest `CLAUDE.md` zelf óók al
   als instructiebron).
9. ⏸️ **Proef Copilot code review** — geparkeerd: vereist een betaald plan (Actions-minuten zouden
   op deze publieke repo wél gratis zijn). Pas relevant ná een eventuele upgrade.
10. ⏸️ **Coding agent** — besloten én geparkeerd (16 juli 2026): Dave keurde de proef goed
    ("issue toewijzen aan Copilot" geldt als zijn PR-akkoord voor die ene taak) en issue #42 stond
    klaar, maar de toewijzing faalt zonder betaald plan op het toewijzende account. Dave upgradet
    niet; de "merget"-fix (stap 6) loopt gewoon via de eigen specialist-keten.

## Geleerde lessen

- **Stale `.in_use`-marker** op een oud marketplace-pad kan verhinderen dat agents laden;
  een sessie-herstart is de fix (swb-rooktest, 15 juli 2026).
- **Context-overdrachten verouderen snel:** de swb-overdracht van 15 juli meldde life-hub
  nog als openstaand, terwijl die dezelfde dag al gemigreerd en gecommit bleek. Verifieer
  een overdracht altijd tegen de actuele repo-staat vóór je erop routeert.
- **Scope-les: `claude plugin update -s project` filtert níét op de werkdirectory** (15 juli
  2026, update naar v1.1.1): vanuit deze repo gedraaid werkte het commando het project-record
  van *smartwatchbanden* bij, niet dat van de huidige map. `claude plugin list` toont
  bovendien zonder `--json` niet bij wélk project een record hoort. Werkwijze voortaan:
  (1) controleer vooraf én achteraf met `claude plugin list --json` (het
  `projectPath`-veld); (2) gebruik `claude plugin install -s project` vanuit de
  doel-repo om het record van dát project aan te maken of bij te werken; (3) een nieuwe
  versie laadt pas na een sessie-herstart. Let op: de install kan de line-endings van
  `.claude/settings.json` herschrijven zonder inhoudswijziging — check `git status` na
  afloop.
- **Record-les: een verweesd plugin-record ruim je preciezer op via de administratie dan
  via `/plugin` of de CLI** (15 juli 2026). De installatie-records wonen in
  `~/.claude/plugins/installed_plugins.json`, per record identificeerbaar aan het
  `projectPath`-veld — daar kun je exact het bedoelde record verwijderen, terwijl
  `claude plugin uninstall -s project` dezelfde vage project-doelbepaling heeft als het
  update-commando uit de scope-les hierboven. Veilige volgorde: (1) verifieer dat het `projectPath` echt niet
  meer bestaat (`Test-Path`); (2) maak een backup van het JSON-bestand; (3) verwijder
  alleen dat record; (4) valideer de JSON en controleer met `claude plugin list --json`.
- **Marker-structuur-les: de `.in_use`-marker is geen bestand maar een máp** (15 juli 2026,
  cache-opruiming na de v1.1.1-herstart). In die map schrijft elke sessie die de versie
  gebruikt een eigen PID-bestand (bestandsnaam = het proces-id, inhoud `{"pid":N}`); bij
  het afsluiten van de sessie verdwijnt het weer. "Is deze cache-versie nog in gebruik?"
  check je dus **niet** met een file-lock-test — een map kun je nooit als bestand openen,
  dus die test geeft altijd vals alarm "vergrendeld" — maar simpelweg door in de map te
  kijken: **leeg = vrij** (veilig te verwijderen), en staat er wél een PID-bestand, dan
  vertelt de PID exact wélke sessie de versie gebruikt (te herleiden via de proceslijst,
  bv. `Get-Process -Id <pid>`).
- **Ruleset-verificatie-les: het `bypass_actors`-veld van een GitHub-ruleset is alleen
  zichtbaar voor repo-admins** (15 juli 2026, instellen van de ruleset `main-ci-poort`).
  Vraagt een niet-admin-account de ruleset op via de API, dan lijkt de bypass-list leeg
  terwijl hij gevuld is — een kijk-artefact dat tot de onterechte conclusie "de bypass
  ontbreekt" leidde. Verifieer een ruleset daarom altijd als het account dat daadwerkelijk
  gaat pushen, via het veld `current_user_can_bypass` (`"always"` = gedekt, `"never"` =
  geblokkeerd): dat veld beantwoordt de vraag die er echt toe doet, onafhankelijk van wie
  de bypass-list mag zien.
- **Write-bypass-kanttekening: de bypass-list van `main-ci-poort` bevat bewust ook de
  Write-rol** (15 juli 2026). Nodig omdat de directe fold-/release-commits op `main` als
  werk-account `davekokbwj` worden gepusht, dat op deze persoonlijke repo geen admin kán
  zijn (alleen eigenaar + collaborators met write). Veilig zolang `davekokbwj` de enige
  collaborator is — maar krijgt de repo ooit externe collaborators, dan kan élke
  write-collaborator de checks passeren en moet deze bypass opnieuw bekeken worden.
