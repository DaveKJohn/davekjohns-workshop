### Lens-scaffolds bij adoptie: elke specialist krijgt een leeg VUL-IN-sjabloon · Feat · 2026-07-16

Wens van Dave: bij adoptie moet direct zichtbaar zijn wáár repo-specifieke taken per specialist
worden aangevuld. `bootstrap.ps1` (skill `specialists-init`) zet nu — naast de persona-kopieën —
voor elke subagent van de ingeschakelde plugin(s) een leeg lens-scaffold neer in
`.claude/extensions/<g>-<id>-extension.md`: frontmatter + duidelijke `VUL-IN`-markering, nooit
overschrijvend, werkend in zowel de bron- als de plugin-cache-layout. Een install-hook bestaat
niet en de sessie-hook blijft bewust read-only; het bootstrap-adoptiepad is dus de plek. SKILL.md,
root-README en de bootstrap-testsuite (20 asserts) bewegen mee.