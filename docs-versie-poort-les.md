### Versie-poort-les: zonder bump geen plugin-update bij consumenten · Docs · 2026-07-15

Geleerde les van de v1.1.0-release geborgd in `README.md` (Versiebeheer) en Rendalls lens
(`.claude/extensions/05-06-extension.md`): het `version`-nummer in `plugin.json` is niet alleen een
marker maar de **update-poort** — `claude plugin update` vergelijkt uitsluitend versienummers, dus
gemergde wijzigingen bereiken consumenten (en deze zelf-consumerende repo) pas na een bump. Werk dat
moet propageren, vraagt dus om een release (op Dave's expliciete verzoek, zoals altijd).