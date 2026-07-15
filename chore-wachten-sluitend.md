### CI-poort op GitHub + lint-containment + testbare manifest-afleiding · Chore · 2026-07-15

De "maak de wachten sluitend"-beweging, in drie delen: (1) **CI op GitHub**
(`.github/workflows/ci.yml`): de lint-poort + alle testsuites draaien nu bij elke PR en elke push
naar `main` — ook een PR buiten `open-pr.ps1` om komt langs de wacht. (2) **Containment in de
lint-poort**: een `plugins[].source` die buiten de repo wijst is nu een lint-error (Sean's advies,
doorgetrokken van `cut-release.ps1` naar `check-plugin-integrity.ps1`). (3) **`Get-PluginManifests`
testbaar gemaakt**: de pure kern is verhuisd naar `release-lib.ps1` (`Get-PluginManifestPaths`) en
afgedekt met 7 nieuwe asserts in `release-lib.tests.ps1`; het script houdt alleen de IO. Na de
review-rij aangescherpt: least-privilege `permissions` op de workflow (Sean), een expliciete
absolute-pad-melding en de pluginnaam terug in de manifest-foutmelding (Victor), en de CI-poort
opgenomen in `CLAUDE.md`/Sylvesters lens (Edith). Bekende test-gap: de gespiegelde
containment-check in de lint-poort zelf heeft nog geen negatieve fixture-test (Tycho-vervolg).