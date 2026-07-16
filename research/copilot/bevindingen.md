# GitHub Copilot op davekjohns-workshop — onderzoeksbevindingen

> Onderzoek van Rebecca 🔬 #07, 16 juli 2026, in opdracht van Dave: wat is GitHub Copilot anno nu,
> en hoe is het inzetbaar op deze repo? De concrete vervolgstappen staan in het
> [werkplan van 16 juli](../plugin-sharing/vervolgstappen.md#werkplan-16-juli-2026) (stappen 8–10).
>
> **Uitkomst (16 juli 2026): geparkeerd.** De door Dave goedgekeurde proef met de coding agent
> (de "merget"-fix als testcase, issue #42) strandde op de licentie-check: beide accounts
> (`DaveKJohn` en `davekokbwj`) hebben **Copilot Free**, en de coding agent + automatische code
> review vereisen een betaald plan. Daarmee zijn ook de open punten (b) en (c) hieronder
> beantwoord: het toewijzende account heeft inderdaad zelf een plan nodig (de CLI-toewijzing als
> `davekokbwj` faalde met *"Copilot agent is not enabled in this repository"* en de Copilot-bot
> ontbrak in de assignable actors), en Dave heeft geen betaald plan — en besloot niet te upgraden.
> Dit dossier blijft liggen tot dat besluit ooit wijzigt.

## Het productpalet (juli 2026)

GitHub Copilot is een familie van producten, niet meer alleen code completion:

- **Code completion / Copilot Chat** — de klassieke IDE-suggesties en chat; kern van elk plan.
  ([GitHub Docs — Features](https://docs.github.com/en/copilot/get-started/features))
- **Copilot coding agent** ("cloud agent") — een autonome agent die op een issue wordt gezet
  ("assign to Copilot"), zelf een branch aanmaakt én **meteen een draft-PR opent** die hij bijwerkt
  tot hij klaar is. Draait in een GitHub-Actions-omgeving, max. 59 minuten per sessie. Sinds 2026 met
  modelkeuze, zelf-review vóór de PR en ingebouwde security-scanning.
  ([coding agent 101](https://github.blog/ai-and-ml/github-copilot/github-copilot-coding-agent-101-getting-started-with-agentic-workflows-on-github/) ·
  [about coding agent](https://docs.github.com/copilot/concepts/agents/coding-agent/about-coding-agent) ·
  [what's new 2026](https://github.blog/ai-and-ml/github-copilot/whats-new-with-github-copilot-coding-agent/))
- **Copilot code review** — automatische of on-demand PR-reviews, in te stellen via een repo-ruleset;
  werkt op elke PR ongeacht of de PR-auteur zelf een licentie heeft, en leest sinds juni 2026 ook
  `AGENTS.md`-instructiebestanden.
  ([code review](https://docs.github.com/en/copilot/concepts/agents/code-review) ·
  [configure automatic review](https://docs.github.com/en/copilot/how-tos/copilot-on-github/set-up-copilot/configure-automatic-review) ·
  [AGENTS.md-support](https://github.blog/changelog/2026-06-18-copilot-code-review-agents-md-support-and-ui-improvements/))
- **Copilot CLI** — terminal-agent; sinds 2 juli 2026 ook bruikbaar binnen GitHub Actions met het
  ingebouwde `GITHUB_TOKEN`. ([copilot-cli](https://github.com/github/copilot-cli))
- **Repository-instructiebestanden** — `.github/copilot-instructions.md`, sinds augustus 2025 ook
  `AGENTS.md` (root of genest) en pad-specifieke `*.instructions.md`. Opvallend: de coding agent
  leest ook **`CLAUDE.md`** als instructiebron — een deel van onze grondwet werkt dus al "gratis" door.
  ([custom instructions](https://docs.github.com/copilot/customizing-copilot/adding-custom-instructions-for-github-copilot) ·
  [AGENTS.md-changelog](https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/))
- **Custom agents** (`.github/agents/`) en **Copilot Spaces** — nieuw resp. context-containers; geen
  fit voor deze repo (te vroeg / dupliceert het eigen specialists-systeem).
- **Ruleset-bypass voor de coding agent** — kan sinds november 2025, maar alleen voor regels als
  commit-signing; **branch protection en required status checks (de CI-poort) blijven onverkort
  gelden, ook voor de agent**.
  ([bypass-changelog](https://github.blog/changelog/2025-11-13-configure-copilot-coding-agent-as-a-bypass-actor-for-rulesets/))

## Beschikbaarheid & kosten voor deze situatie

- Deze repo is een **persoonlijke, publieke repo** — het gaat dus om individuele plannen, geen
  Business/Enterprise. **Copilot Free** dekt alleen basis-chat/completions; de **coding agent en
  automatische code review vereisen een betaald plan** (Pro $10/mnd of Pro+ $39/mnd).
  ([plans](https://docs.github.com/en/copilot/get-started/plans) ·
  [individual plans](https://docs.github.com/en/copilot/concepts/billing/individual-plans))
- **Actions-minuten blijven gratis op publieke repo's**, ook voor Copilot code review — de
  Actions-minuten-heffing per 1 juni 2026 geldt alleen voor private repo's.
  ([changelog](https://github.blog/changelog/2026-04-27-github-copilot-code-review-will-start-consuming-github-actions-minutes-on-june-1-2026/))
- De coding agent wordt per account beheerd (Copilot settings → Cloud agent → Repository access) en
  staat **standaard aan** voor alle repo's zodra een betaald plan actief is.
  ([access management](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/access-management))
- **Open einden (praktijkproef of vraag aan Dave sneller dan deskresearch):** (a) het exacte
  billing-model is per 1 juni 2026 in overgang van "premium requests" naar per-token **AI Credits** —
  bronnen lopen uiteen in actualiteit
  ([usage-based billing](https://github.blog/news-insights/company-news/github-copilot-is-moving-to-usage-based-billing/));
  (b) of het write-account (`davekokbwj`) een eigen licentie nodig heeft om een issue aan Copilot toe
  te wijzen; (c) of Dave momenteel al een betaald Copilot-plan heeft.

## Inzet-opties en aanbevelingen

| Optie | Wat | Aanbeveling |
|---|---|---|
| **A. Copilot code review** als extra automatische reviewer op PR's | Via repo-ruleset "Automatically request Copilot code review"; vult Victor/Edith/Sean aan met een vierde, onafhankelijke blik | **Later** — eerst één bewuste proef op een kleine PR; meerwaarde en quotum-kosten wegen t.o.v. het bestaande reviewteam |
| **B. Coding agent** voor kleine klusjes (bv. de "merget"-fix) | Issue toewijzen aan Copilot → agent maakt branch + opent **zelf meteen een draft-PR** | **Beslissing bij Dave** — botst per ontwerp met de harde regel "een PR alléén op Dave's woord"; alleen inzetbaar als Dave "issue toewijzen aan Copilot" expliciet laat gelden als zíjn PR-akkoord voor die ene taak |
| **C. `.github/copilot-instructions.md`** die de grondwet spiegelt | Korte, repo-neutrale samenvatting van de kernregels (branch+PR op Dave's woord, lint-poort, publiek → geen secrets) | **Doen** — laag risico, geen PR-botsing; let wel: een instructiebestand is een richtlijn, geen technische poort |
| D. Copilot CLI in Actions, Spaces, custom agents | — | **Niet/later** — geen bestaande behoefte resp. te vroeg |

## Risico's en aandachtspunten

1. **De PR-regel is de kernbotsing** — alleen optie B raakt die direct; A en C voegen enkel
   advies/context toe aan PR's die via de bestaande weg zijn geopend.
2. **Publiek-repo-regel blijft overeind** — geen enkele optie vraagt om iets vertrouwelijks; een
   instructiebestand blijft net zo repo-neutraal als de agent-defs.
3. **Ruleset-les geldt ook hier** — de coding agent ooit als bypass-actor voor `main-ci-poort`
   instellen: niet doen zonder de `current_user_can_bypass`-verificatie uit de
   [ruleset-les](../plugin-sharing/vervolgstappen.md#geleerde-lessen). Vooralsnog onnodig: de
   CI-checks blijven sowieso afdwingbaar voor de agent.
4. **Copilot-PR's lopen buiten het specialists-systeem** — wordt de coding agent ooit ingezet, dan
   moet de specialist-review (Victor/Edith/Sean) als expliciete extra stap op de Copilot-PR worden
   toegevoegd, niet stilzwijgend overgeslagen.
