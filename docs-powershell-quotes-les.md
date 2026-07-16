### Quote-les geborgd: geen dubbele aanhalingstekens in native argumenten · Docs · 2026-07-16

Geleerde les van 16 juli vastgelegd in Dereks lens (`.claude/extensions/05-05-extension.md`, nieuwe
sectie "De quote-les"): PowerShell 5.1 verminkt dubbele aanhalingstekens in argumenten voor native
commando's (`git`, `gh`) — een `"` in een commit-message laat `git commit -m` afketsen. Werkwijze:
inline argumenten vrij van `"` houden, of de tekst via een bestand doorgeven (`git commit -F`,
`gh … --body-file`). De bestaande PR-body-vermelding verwijst nu naar deze sectie.