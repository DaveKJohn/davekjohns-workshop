### Fold-les geborgd: check `git branch --show-current` vóór het folden · Docs · 2026-07-16

Geleerde les van 16 juli vastgelegd in Rendalls lens (`.claude/extensions/05-06-extension.md`,
fold-levenscyclus stap 2): `gh pr merge --delete-branch` belooft ook de lokale branch op te ruimen,
maar kan de lokale checkout op de gemergde branch laten staan — check daarom vóór de fold met
`git branch --show-current` dat je écht op `main` staat.
