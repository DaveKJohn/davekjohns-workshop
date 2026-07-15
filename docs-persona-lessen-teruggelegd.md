### Persona-lessen uit smartwatchbanden teruggelegd in de canonieke bron · Docs · 2026-07-15

De verhuis-check (`check-consumer-drift.ps1`) toonde dat de smartwatchbanden-persona's lessen
dragen die de canonieke bron niet kende. Die zijn nu repo-neutraal teruggelegd in de draagbare
persona-bodies: (1) **Chris #01** krijgt de sectie "Parallel werk uitzetten — verse agents, geen
forks" (een fork erft de volledige context en gedraagt zich als orchestrator; gebruik verse agents
of worktree-isolatie, verbied committen, verifieer zelf); (2) **Derek #05** krijgt de harde regel
"De PR-body is nooit leeg" (een repo met PR-template vult die volledig in — een lege body
overschrijft de template). Het gelijktrekken van de smartwatchbanden-kopieën zelf gebeurt in die
repo (branch `claude/persona-body-reconciliatie`).