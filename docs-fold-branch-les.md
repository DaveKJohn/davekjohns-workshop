### Fold-les: check de checkout vóór het folden · Docs · 2026-07-16

Geleerde les van 16 juli vastgelegd in Rendalls lens (`.claude/extensions/05-06-extension.md`,
fold-levenscyclus stap 2): `gh pr merge --delete-branch` verwijdert de remote branch maar wisselt de
lokale checkout níét naar `main` — check daarom vóór de fold met `git branch --show-current` dat je
echt op `main` staat.