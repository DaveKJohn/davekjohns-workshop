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
3. **Restant van de map-hernoem (bijgewerkt 15 juli 2026):** de checkout-map is inmiddels
   hernoemd naar `...\DaveKJohn\davekjohns-workshop`, maar er hangt nog een **verweesd
   plugin-record** aan het oude pad `...\DaveKJohn\claude-specialists` (`specialists`
   v1.1.0, zichtbaar via `claude plugin list --json` → `projectPath`). Opruimen via
   `/plugin` in een interactieve sessie — niet blind via de CLI, zie de scope-les
   hieronder.

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
