# Release notes — davekjohns-workshop

The release history of the davekjohns-workshop marketplace. A release here is not a deploy but a
**recorded moment**: a git tag that marks the state of the marketplace, with all plugin versions in
lockstep. **No GitHub Releases** are published on purpose — the full notes live below in
`development/<X.Y>/<X.Y.Z>.md`, and the `## Releases` block in
[`CHANGELOG.md`](../CHANGELOG.md) references them. Releases are cut only at Dave's explicit request
via [`scripts/release/cut-release.ps1`](../scripts/release/cut-release.ps1). Each release also
refreshes, per plugin, the `RELEASE.md` card that consumers see (version + short notes, travelling
along with the plugin cache via `claude plugin update`).

## Overview

Grouped by major version, newest first. New releases are added to the current major's table (the
top one).

### 2.x

| Version | Date | Type | Title |
|---|---|---|---|
| [2.0.0](development/2.0/2.0.0.md) | 2026-07-23 | Major | Chapter 1 consolidated (v1.0 -> v1.18) |

### 1.x

| Version | Date | Type | Title |
|---|---|---|---|
| [1.18.0](development/1.18/1.18.0.md) | 2026-07-22 | Minor | Rename-proof lens scaffolds |
| [1.17.0](development/1.17/1.17.0.md) | 2026-07-22 | Minor | E-commerce specialist group (Sergio, Craig, Sean) + Sean-to-Sebastian rename |
| [1.16.0](development/1.16/1.16.0.md) | 2026-07-22 | Minor | ship-pr one-command flow, category-grouped release output, and the post-review doc consistency pass |
| [1.15.1](development/1.15/1.15.1.md) | 2026-07-22 | Patch | Shared Invoke-NativeCapture helper across the release scripts, and a fully-English CHANGELOG and script layer |
| [1.15.0](development/1.15/1.15.0.md) | 2026-07-21 | Minor | English script layer, Shopify dev-first, consumer-fit open-pr/fold, and shared release/check helpers |
| [1.14.0](development/1.14/1.14.0.md) | 2026-07-21 | Minor | Cross-browser and automation-first shared rules, and a leaner, plugin-independent CLAUDE.md |
| [1.13.0](development/1.13/1.13.0.md) | 2026-07-21 | Minor | Consumer release cards, branch-creates-changelog-entry, and English agent-shared block names |
| [1.12.1](development/1.12/1.12.1.md) | 2026-07-20 | Patch | Ship the git/gh stderr-under-Stop sweep to consumers (the open-pr + fold shared-script mirrors from #113) |
| [1.12.0](development/1.12/1.12.0.md) | 2026-07-20 | Minor | Workshop switched to English (phases A-C) and the roster-sync feature (detect, signal, stage recovery); plus the open-pr push-stderr fix and the shared language-directive block |
| [1.11.0](development/1.11/1.11.0.md) | 2026-07-20 | Minor | Quieter session start (only FOUT/DRIFTED signals) and a slimmed-down connectors register without version bookkeeping |
| [1.10.0](development/1.10/1.10.0.md) | 2026-07-19 | Minor | RepoName derivation from the git remote, durable body import, and a not-registered signal for unregistered consumers |
| [1.9.2](development/1.9/1.9.2.md) | 2026-07-19 | Patch | Documentation: specialists-init SKILL.md aligned with the plugin-path/lens-only model (#88) |
| [1.9.1](development/1.9/1.9.1.md) | 2026-07-19 | Patch | Clean-consumer fix: specialists-init scaffolds the script config and open-pr/fold pre-flight (#86) |
| [1.9.0](development/1.9/1.9.0.md) | 2026-07-19 | Minor | Shared workflow scripts (SSOT): repo-config, branch-type source, and plugin mirrors for fold + open-pr |
| [1.8.0](development/1.8/1.8.0.md) | 2026-07-18 | Minor | Adoption layer: bootstrap seeds the plugin path + lens-only |
| [1.7.0](development/1.7/1.7.0.md) | 2026-07-18 | Minor | Ravi + lens migration: repo lenses on the plugin path, personas lens-only |
| [1.6.0](development/1.6/1.6.0.md) | 2026-07-18 | Minor | Shared agent-def blocks from a single source (build-and-lint) |
| [1.5.2](development/1.5/1.5.2.md) | 2026-07-18 | Patch | Persona index line location-independent (source fix inbound #64) |
| [1.5.1](development/1.5/1.5.1.md) | 2026-07-18 | Patch | Lens-only model in the drift check and persona templates; inbound rule in all agent-defs |
| [1.5.0](development/1.5/1.5.0.md) | 2026-07-17 | Minor | Consumer-ready: shareable quickstart, drift noise killed, and the first per-plugin CHANGELOGs |
| [1.4.1](development/1.4/1.4.1.md) | 2026-07-16 | Patch | Version-sorting fix and scaffold follow-up corrections |
| [1.4.0](development/1.4/1.4.0.md) | 2026-07-16 | Minor | Lens scaffolds on adoption and port follow-up corrections |
| [1.3.0](development/1.3/1.3.0.md) | 2026-07-16 | Minor | Inbound route and register sync |
| [1.2.0](development/1.2/1.2.0.md) | 2026-07-16 | Minor | Connectors register and session check |
| [1.1.1](development/1.1/1.1.1.md) | 2026-07-15 | Patch | Security baseline processed: injection guardrail, cleaned-up example paths, and the CI gate |
| [1.1.0](development/1.1/1.1.0.md) | 2026-07-15 | Minor | Sean the Security Engineer + the reload-plugins lesson |
| [1.0.0](development/1.0/1.0.0.md) | 2026-07-14 | Major | First official release |
