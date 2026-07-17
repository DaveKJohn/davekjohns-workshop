### life-hub-manifest gesynct op v1.5.0 (lens-only-notitie, inbound #69) · Chore · 2026-07-17

Het connector-manifest van life-hub is bijgewerkt na de plugin-update in de consument:
`syncedVersion` van beide plugins (`specialists`, `specialists-lifehub`) van 1.4.1 naar 1.5.0,
`lastChecked` op 2026-07-17 en `status` terug naar `in-sync` (de persona-verversing uit de oude
notitie is uitgevoerd). De nieuwe notitie legt vast dat life-hub het lens-only-model hanteert
voor de vier persona's (01-01, 03-02, 05-05, 05-06) en dat de vier persona-`DRIFTED`-meldingen
van de drift-check daardoor bekende vals-positieven zijn tot inbound-issue
[#69](https://github.com/DaveKJohn/davekjohns-workshop/issues/69) is verwerkt.