### Repo hernoemd naar `davekjohns-workshop` + plugins verhuisd naar `claude-code-plugins/claude-specialists/` · Chore · 2026-07-15

De repo heet voortaan **`davekjohns-workshop`**: de werkplaats van Dave (DaveKJohn) waar al zijn
Claude-Code-plugins worden gebouwd — de naam maakt expliciet dat dit systeem door een mens is
ontworpen (het oude repo-niveau `claude-specialists` las alsof het door Claude zelf gemaakt was).
De repo is daarmee geen standalone specialisten-marketplace meer, maar de bredere plugin-werkplaats;
het Claude-Specialists-systeem is de eerste product-familie.

- **Nieuwe structuur `claude-code-plugins/claude-specialists/`** — `claude-code-plugins/` is het
  thuis van alle plugin-families; daarbinnen huisvest de familiemap `claude-specialists/` de drie
  plugins (`specialists`, `specialists-lifehub`, `specialists-shopify`). `marketplace.json`-sources,
  drift-check en tests wijzen mee. Plugin-namen en aanroep-namespaces (`@specialists:<naam>`)
  zijn **ongewijzigd**.
- **Marketplace-identiteit** — `marketplace.json`: `name` → `davekjohns-workshop`, beschrijving en
  `owner` benoemen Dave expliciet als ontwerper.
- **Alle repo-verwijzingen mee** — `.claude/settings.json` (source + `enabledPlugins`-sleutels),
  `open-pr.ps1`/`fold-changelog-entry.ps1` (`--repo`), de bootstrap-skill-instructies, en de
  intro's/structuursecties van `CLAUDE.md`, `README.md`, `.claude/README.md`, `releases/README.md`
  en de repo-lenzen.
- **Nieuwe familie-README + ontdubbeling** — `claude-code-plugins/claude-specialists/README.md`
  legt uit wat het specialisten-systeem doet en wat het verschil is tussen de drie sub-plugins
  (gedeelde kern vs. domein-groepen). De root-`README.md` is daarop ontdubbeld (de
  drie-groepen-tabel en de aanroep-sectie zijn vervangen door een `## De plugin-families`-sectie die
  naar de familie-README verwijst) en `CLAUDE.md` verwijst nu naar de juiste README per onderwerp.
- **Lint-fix (persona-links)** — persona-sjablonen linken relatief aan hun *bestemming*
  (`.claude/extensions/` van een consument); door de diepere bronlocatie viel de toevallige
  bron-resolutie weg. `check-plugin-integrity.ps1` valideert persona-links nu expliciet alsof ze op
  die bestemming staan.

**Voor consumerende repo's (breaking):** werk in `.claude/settings.json` de marketplace-source bij
naar `DaveKJohn/davekjohns-workshop` en hernoem de `enabledPlugins`-sleutels naar
`<plugin>@davekjohns-workshop`. Historische records (`releases/`, gevouwen entries) zijn bewust
ongewijzigd. Beide testsuites en de lint-poort zijn groen.
