### Shopify-domeingroep: 3 manuals naar specialists-shopify/manuals/, agent-defs naar plugin + repo-extensie Â· Feat Â· 2026-07-14

Sluitstuk van het gesplitste manual-model: de laatste domeingroep `specialists-shopify` (Liam, Sandra, Steven) volgt nu ook. Enkele consument (smartwatchbanden), dus geen reconciliatie â€” het draagbare deel is repo-neutraal gemaakt (Shopify-domeincontext behouden; de specifieke store naar de repo-lens).

- `specialists-shopify/manuals/{04-20,05-21,05-22}-manual.md` â€” nieuw: de 3 draagbare vakboeken (Liam ðŸ’§ Liquid Developer, Sandra ðŸ›ï¸ Webshopbeheerder, Steven ðŸ—‚ï¸ Configuratiebeheerder).
- `specialists-shopify/agents/*.md` (3) â€” vakboek-verwijzing naar `${CLAUDE_PLUGIN_ROOT}/manuals/<g-i>-manual.md` + `.claude/extensions/<g-i>-extension.md`; de nagelopen kruisverwijzing naar de style-guide gerepoint naar `.claude/extensions/04-12-extension.md`.

De repo-lenzen + het opruimen van de lokale manuals zitten in de smartwatchbanden-PR. Hiermee is het gesplitste model voor alle drie de plugins doorgevoerd.