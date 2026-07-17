# Dossier — Consumenten-quickstart: "zo sluit je jouw repo aan"

> Werkbriefing voor deze branch. Opgesteld 2026-07-17 (Tessa #16, op aanwijzing van Dave).
> Dit dossier verdwijnt weer zodra het werk is afgerond en gemergd.

## Wat moet er gebeuren

[Tessa #16](../.claude/extensions/06-16-extension.md) schrijft één korte, zelfstandige
quickstart-pagina gericht op iemand die het specialisten-systeem **níét gebouwd heeft** — een
collega die zijn eigen repo wil aansluiten. Inhoud, in deze volgorde:

1. **Wat je krijgt** — in twee alinea's: het specialisten-team, de Chief of Staff, de draagbare
   vakboeken; met verwijzing naar de [familie-README](../claude-code-plugins/claude-specialists/README.md)
   voor de drie sub-plugins.
2. **Aansluiten in drie stappen** — (a) de marketplace-source `DaveKJohn/davekjohns-workshop` +
   de `specialists`-plugin aanzetten in `.claude/settings.json` (concreet config-voorbeeld);
   (b) de bootstrap-skill `specialists-init` draaien (het additieve `bootstrap.ps1`-pad, zie
   [`README.md` › Adoptie](../README.md#adoptie-het-bootstrap-pad)); (c) checken dat Chris laadt.
3. **Hoe je bijblijft** — updates komen via releases (`claude plugin update` vergelijkt
   versienummers); de per-plugin `CHANGELOG.md` reist mee in de cache en vertelt wat er voor jouw
   plugin veranderde.
4. **Hoe je iets terugmeldt** — de inbound-route: een issue met label `inbound` op deze repo;
   repo-eigen aanvullingen horen in je eigen `.claude/extensions/`-lens, niet in de kern.

**Plaats (keuze bij uitvoering):** een eigen doc (bv.
`claude-code-plugins/claude-specialists/QUICKSTART.md`) waarnaar de root-README en familie-README
linken, óf een sectie in de familie-README zelf. Criterium: één URL die je een collega kunt sturen.
Geen inhoud dupliceren die al in de READMEs staat — de quickstart is de rode draad met links, niet
een derde uitleg. Daarna leest [Edith #17](../.claude/extensions/06-17-extension.md) de nieuwe
pagina na (vooral: klopt elke link, en is hij te volgen zónder voorkennis?).

## Waarom

- De adoptie-kennis is nu verspreid over de root-README, de familie-README en de
  `specialists-init`-skill — voor de bouwer prima te vinden, voor een buitenstaander een drempel.
- Dave wil de plugins delen met collega's; de repo is er technisch klaar voor (publiek, stabiele
  release-lijn, bootstrap-pad), maar er is geen pagina die een nieuwkomer bij de hand neemt.
- Eén deelbare quickstart maakt het verschil tussen "kijk zelf maar in de repo" en "volg deze drie
  stappen" — en verlaagt ook de support-last op Dave zelf.

## Klaar wanneer

- [ ] De quickstart-pagina bestaat, op één vindbare plek, en is te volgen zonder voorkennis.
- [ ] Root-README en familie-README verwijzen ernaar (zonder inhoud te dupliceren).
- [ ] Edith heeft hem nagelezen (links, taal, volgbaarheid).
- [ ] Dit dossier is opgeruimd.
