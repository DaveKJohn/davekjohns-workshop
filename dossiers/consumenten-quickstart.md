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

- [x] De quickstart-pagina bestaat, op één vindbare plek, en is te volgen zonder voorkennis —
      geworden: [`QUICKSTART.md`](../claude-code-plugins/claude-specialists/QUICKSTART.md) naast de
      familie-README (één deelbare URL).
- [x] Root-README en familie-README verwijzen ernaar (zonder inhoud te dupliceren).
- [x] Edith heeft hem nagelezen (links, taal, volgbaarheid) — drie punten gevonden en verwerkt
      (accent-typo, rolomschrijving PR/merge, stappen-telling t.o.v. de root-README); alle links
      handmatig geverifieerd en kloppend.
- [ ] Dit dossier is opgeruimd (na de merge).

**Doorgegeven observatie (Edith, voor Sylvester):** de dode-links-scan van
`check-plugin-integrity.ps1` dekt de familie-README en `QUICKSTART.md` niet — zelfde dekkingsgat
als eerder genoteerd voor de per-plugin CHANGELOGs in
[`review-herkansing-61.md`](review-herkansing-61.md) (geparkeerd punt Edith #5); bij het dichten
graag in één beweging meenemen.
