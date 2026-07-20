# Release notes — davekjohns-workshop

De release-historie van de davekjohns-workshop-marketplace. Een release is hier geen deploy maar een
**vastgelegd moment**: een git-tag die de staat van de marketplace markeert, met alle plugin-versies in
lockstep. Er worden bewust **geen GitHub Releases** gepubliceerd — de volledige notes staan
hieronder in `development/<X.Y>/<X.Y.Z>.md` en het `## Releases`-blok in
[`CHANGELOG.md`](../CHANGELOG.md) verwijst ernaar. Releases worden alleen op Dave's expliciete verzoek
gesneden via [`scripts/release/cut-release.ps1`](../scripts/release/cut-release.ps1).

## Overzicht

| Versie | Datum | Type | Titel |
|---|---|---|---|
| [1.12.1](development/1.12/1.12.1.md) | 2026-07-20 | Patch | Ship the git/gh stderr-under-Stop sweep to consumers (the open-pr + fold shared-script mirrors from #113) |
| [1.12.0](development/1.12/1.12.0.md) | 2026-07-20 | Minor | Workshop switched to English (phases A-C) and the roster-sync feature (detect, signal, stage recovery); plus the open-pr push-stderr fix and the shared language-directive block |
| [1.11.0](development/1.11/1.11.0.md) | 2026-07-20 | Minor | Stillere sessiestart (alleen FOUT/DRIFTED) en een afgeslankt connectors-register zonder versie-boekhouding |
| [1.10.0](development/1.10/1.10.0.md) | 2026-07-19 | Minor | RepoName-afleiding uit de git-remote, durabele body-import en een niet-geregistreerd-signaal voor onregistreerde consumenten |
| [1.9.2](development/1.9/1.9.2.md) | 2026-07-19 | Patch | Documentatie: specialists-init SKILL.md uitgelijnd met het plugin-pad/lens-only-model (#88) |
| [1.9.1](development/1.9/1.9.1.md) | 2026-07-19 | Patch | Schone-consument-fix: specialists-init scaffoldt de script-config en open-pr/fold pre-flighten (#86) |
| [1.9.0](development/1.9/1.9.0.md) | 2026-07-19 | Minor | Gedeelde workflow-scripts (SSOT): repo-config, branch-type-bron en plugin-spiegels voor fold + open-pr |
| [1.8.0](development/1.8/1.8.0.md) | 2026-07-18 | Minor | Adoptie-laag: bootstrap seedt het plugin-pad + lens-only |
| [1.7.0](development/1.7/1.7.0.md) | 2026-07-18 | Minor | Ravi + lens-migratie: repo-lenzen op het plugin-pad, persona's lens-only |
| [1.6.0](development/1.6/1.6.0.md) | 2026-07-18 | Minor | Gedeelde agent-def-blokken uit een enkele bron (build-en-lint) |
| [1.5.2](development/1.5/1.5.2.md) | 2026-07-18 | Patch | Persona-indexregel locatie-onafhankelijk (bron-fix inbound #64) |
| [1.5.1](development/1.5/1.5.1.md) | 2026-07-18 | Patch | Lens-only-model in de drift-check en persona-sjablonen; inbound-regel in alle agent-defs |
| [1.5.0](development/1.5/1.5.0.md) | 2026-07-17 | Minor | Consumenten-klaar: deelbare quickstart, drift-ruis gedood en de eerste per-plugin CHANGELOGs |
| [1.4.1](development/1.4/1.4.1.md) | 2026-07-16 | Patch | Versie-sortering-fix en scaffold-nacorrecties |
| [1.4.0](development/1.4/1.4.0.md) | 2026-07-16 | Minor | Lens-scaffolds bij adoptie en poort-nacorrecties |
| [1.3.0](development/1.3/1.3.0.md) | 2026-07-16 | Minor | Inbound-route en register-sync |
| [1.2.0](development/1.2/1.2.0.md) | 2026-07-16 | Minor | Connectors-register en sessie-check |
| [1.1.1](development/1.1/1.1.1.md) | 2026-07-15 | Patch | Security-nulmeting verwerkt: injection-guardrail, opgeschoonde voorbeeldpaden en de CI-poort |
| [1.1.0](development/1.1/1.1.0.md) | 2026-07-15 | Minor | Sean de Security Engineer + de reload-plugins-les |
| [1.0.0](development/1.0/1.0.0.md) | 2026-07-14 | Major | Eerste officiele release |