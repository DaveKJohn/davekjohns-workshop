### Lint-poort: specialisten-systeem-integriteit (id-uniek, agent-def<->manual-paring) + code-spans overslaan bij link-scan · Feat · 2026-07-14

Punt 2 uit het consistentie-onderzoek: de bron-repo van het specialisten-systeem hoort minstens zo
streng te controleren als een consument. Nieuwe **check 6** in
[`check-plugin-integrity.ps1`](scripts/lint/check-plugin-integrity.ps1): per plugin is elk
`<group>-<id>` uniek over de agent-defs, heeft elke agent-def een geldige `name:` (Claude
Code-aanroepnaam) plus een bijbehorende `manuals/<g>-<id>-manual.md` die hij ook noemt, en heeft elke
manual omgekeerd een agent-def (geen wees-manual). Overgenomen uit life-hub's lint-brain, aangepast op
de plugin-topologie (de roster→lens-koppeling wordt al door de dode-link-scan gedekt; de
`## Eigen aan deze repo`-tweedeling zit hier tussen twee bestanden en is dus niet als within-file-check
overgenomen).

Onderweg een **latente bug** in de link/anchor-scan gevonden en gefixt: de scan behandelde
link-achtige tekst binnen inline-/fenced-code als echte links. Daardoor werd een illustratief
voorbeeld in een changelog-entry (via de fold-commit, zonder lint-gate, op master beland) ten onrechte
als kapotte anchor gemeld. De scan slaat code-spans nu over.