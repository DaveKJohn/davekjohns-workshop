### Parallel-les geborgd: pull voor de fold, fold met -Branch, nooit dezelfde branch op twee machines · Docs · 2026-07-16

Geleerde les van 16 juli (PR #46 en #47 kruisten elkaar: Dave mergde parallel vanaf een andere
machine) vastgelegd in twee lenzen. Bij Derek (`05-05-extension.md`, branch- & repo-hygiëne):
verschillende branches parallel mergen is veilig, maar nooit dezelfde branch op twee machines en
verse `git pull` vóór elke nieuwe branch en fold. Bij Rendall (`05-06-extension.md`,
fold-levenscyclus stap 2): bij parallel werken folden mét `-Branch <naam>` — zonder die parameter
vouwt het script óók entries van de andere machine mee — en een geweigerde fold-push is onschuldig:
pull en opnieuw.