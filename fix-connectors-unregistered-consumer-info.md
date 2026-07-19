### Onregistreerde consument krijgt niet-geregistreerd-signaal in de connectors-sessiecheck · Fix · 2026-07-19

Dicht een kern-gat in de connectors-sessiecheck dat aan het licht kwam toen een verse consument
(djcylow-react) de specialists-plugin adopteerde: een consument die **niet** in het connectors-register
staat kreeg toch de geruststellende melding "alle connectors in sync met de workshop-bron" — het
tegenovergestelde signaal van de bedoeling.

- **`scripts/sync/check-connectors.ps1`**: de `-OnlyConsumer`-zonder-match-tak gebruikte een kale
  `Write-Host` die niet als info-signaal telde (`$script:infos` bleef 0), waardoor de SessionStart-hook
  in de "in sync"-tak viel. Vervangen door `Write-Info`, zodat de regel `[INFO]` tagt en meetelt. Een
  onregistreerde consument toont nu "niet-geregistreerd: geen manifest voor deze consument in het
  register." — één info-signaal, exit 0 (de sessiestart blijft zacht, nooit een blokkade).
- **`scripts/tests/connectors.tests.ps1`**: testcase (5c) toegevoegd die de `-OnlyConsumer`-zonder-manifest-tak
  dekt — assert op het `[INFO]`-signaal, "1 info-signaal" en exit 0.