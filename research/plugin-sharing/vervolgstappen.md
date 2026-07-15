# Plugin-sharing-traject — stand & vervolgstappen

> Logboek van de afronding van het marketplace-migratie-traject
> (claude-specialists → davekjohns-workshop). Spiegelt de traject-documentatie in
> smartwatchbanden (`research/plugin-sharing/`). Laatst bijgewerkt: **15 juli 2026**.

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
