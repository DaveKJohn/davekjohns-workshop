---
name: start-task
description: Start een nieuwe taak — maakt de git-branch én het bijbehorende onzichtbare preview-thema aan via scripts/task/start-task.ps1. Handmatig aanroepen als "/specialists-shopify:start-task <prefix>/<korte-naam>", bv. /specialists-shopify:start-task feat/size-chart-popup. Dunne wrapper; de branch-/thema-creatie zelf blijft deterministisch in het script.
disable-model-invocation: true
---

# start-task — nieuwe branch + preview-thema

Dunne UX-wrapper over `scripts/task/start-task.ps1` (in de repo-root). Het script doet het echte, **deterministische** werk — vanaf `main` een branch `<prefix>/<korte-naam>` aanmaken én een gelijknamig **unpublished** preview-thema, het thema-id onthouden in de git-config, en de preview-URL's per markt printen. Deze skill vervangt het script niet; hij roept het handig aan met het meegegeven argument.

## Argument

De branchnaam in kebab-case: `<prefix>/<korte-naam>`, bv. `feat/size-chart-popup` of `fix/cart-totals`. Geldige prefixes staan in Derek's branch-tabel (`.claude/manuals/05-05-manual.md`); classificeer naar wát er verandert (o.a. `feat/`, `fix/`, `style/`, `liquid/`, `gtm/`, `tooling/`, `config/`, `manual/`, `research/`, `extension/`).

## Stappen

1. **Geen argument meegegeven?** → vraag eerst welke branchnaam gewenst is. Niet gokken.
2. **Poortwachters:** controleer dat je op `main` staat met een schone working tree, en dat de pre-task-sync deze sessie is gedaan (het script takt af van de huidige `main`).
3. **Draai het script** via PowerShell — plain, zonder stderr-redirect (de Shopify-CLI schrijft voortgang naar stderr):
   ```powershell
   scripts/task/start-task.ps1 -Name "$ARGUMENTS"
   ```
4. Het script **valideert de prefix zelf** en weigert een ongeldige naam, de `sync/`-prefix en `final`. Bij een fout: los op volgens de melding, verzin geen alternatief.
5. **Na succes** print het script de preview-URL's per markt — geef die door aan de gebruiker.

## Grenzen

- Preview-actie: het thema is `unpublished` en raakt het live thema niet.
- Raak `main` of live niet aan buiten wat het script doet.
