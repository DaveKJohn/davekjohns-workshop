### RepoName-afleiding dekt alle github-URL-vormen (regex verbreed, CI-flakiness weg) · Fix · 2026-07-19

Maakt de RepoName-afleiding (#91) robuust voor álle github-URL-vormen en verhelpt daarmee een
**flaky CI-test**: de git-afleiding-cases faalden intermittent op de windows-runner doordat die een
globale git-`insteadOf` zet die `git@github.com:` naar wisselende vormen herschrijft (kale https,
https met token-userinfo, of `ssh://`) — en `git remote get-url` past die rewrite toe. De regex uit
#91/#92 dekte niet alle vormen, dus soms viel de afleiding terug op VUL-IN en faalde de test.

- **`bootstrap.ps1`**: de derivatie-regex accepteert nu alle gangbare github-vormen —
  `https://`, `ssh://`, `git://` (elk met optionele userinfo) én de scp-achtige `git@github.com:`.
  owner/repo blijft een strikte slug; userinfo wordt niet gevangen (een `evil.com/x@github.com`-spoof
  matcht dus niet).
- **`bootstrap-drift.tests.ps1`**: de git-afleiding-cases draaien met een geneutraliseerde
  global/system git-config (elke case test echt zijn eigen URL-vorm, immuun voor runner-`insteadOf`),
  met een extra `ssh-scheme`-case (`ssh://git@github.com/...`).

Geen gedragswijziging voor consumenten met een gewone origin-URL; puur bredere dekking + een
deterministische testsuite.