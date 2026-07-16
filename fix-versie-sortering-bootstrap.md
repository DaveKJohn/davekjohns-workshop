### Nacorrecties van Victor en Edith op de lens-scaffolds · Fix · 2026-07-16

Nacorrecties op de in v1.4.0 uitgebrachte lens-scaffolds. Van Victor: de versie-sortering in de
cache-layout sorteert nu semantisch via `[version]` (een string-sort zette 1.9.0 boven 1.10.0),
mét een cache-layout-regressietest (1.9.0 naast 1.10.0), een waarschuwing bij een ongeldige
plugin-slug en een verhelderende comment over de dubbele rol van `$parent`. Van Edith: het
"1b."-lijstitem in SKILL.md rendert niet als lijstitem (hernummerd naar 1–4), een onvolledige zin
hersteld, de scaffold-H1 volgt nu de bestaande lens-titelconventie (middot via `[char]0x00B7`,
ASCII-regel), en "lens-sjabloon"/"leeg" zijn geharmoniseerd naar "lege lens-scaffold".