# claude-specialists — de specialisten-familie

De eerste product-familie van [davekjohns-workshop](../../README.md): het **Claude-Specialists-systeem**,
ontworpen door Dave (DaveKJohn). In plaats van één generieke Claude werk je met een **team van
gespecialiseerde Claudes** onder één Chief of Staff: elke opdracht wordt geclassificeerd en bezorgd
bij de specialist (subagent) met het juiste vakboek — een DevOps-engineer voor branches en PR's, een
technical writer voor docs, een eindredacteur voor de laatste blik, enzovoort.

Deze map bevat **drie plugins** die samen dat systeem vormen. Een consumerende repo schakelt ze via
de marketplace **per stuk** aan of uit.

## De drie sub-plugins — wat is het verschil?

| Plugin | Wat het is | Voor wie |
|---|---|---|
| [`specialists/`](specialists/) | **De gedeelde kern (groep 1).** Tien repo-neutrale specialisten die in élke repo hetzelfde werken (o.a. onderzoek, systeembeheer, technical writing, eindredactie, code-review, testen). Draagt daarnaast de persona-sjablonen van de hoofdloop (Chris/Derek/Rendall) en de bootstrap-skill `specialists-init`. | **Elke** consumerende repo — dit is de basis, altijd inschakelen. |
| [`specialists-lifehub/`](specialists-lifehub/) | **Domein-groep 2.** Vijf specialisten voor een persoonlijke informatie-hub / brain-gebaseerde kennisrepo (Astrid, Fiona, Hugo, Ian, Onyx). Bewust domein-gekleurd: ze kennen hun repo en teamgenoten bij naam. | Alleen een life-hub-achtige repo. |
| [`specialists-shopify/`](specialists-shopify/) | **Domein-groep 3.** Drie specialisten voor een Shopify-store-repo (Liam · Liquid, Sandra · webshopbeheer, Steven · configuratie) plus de domein-skill `start-task`. Eveneens bewust domein-gekleurd. | Alleen een Shopify-repo (bv. smartwatchbanden). |

Kort: **`specialists` is het fundament; de andere twee zijn optionele domein-uitbreidingen** waarvan
een repo er hooguit één nodig heeft. De kern is repo-neutraal geschreven (geen repo-namen, paden of
scriptnamen — die context komt uit de repo-lens van de consument); de domein-groepen noemen hun
domein juist expliciet, want alleen een passende repo schakelt ze in.

## Aanroep

Na inschakelen zijn de specialisten aanroepbaar met de **plugin-naam als namespace**:
`@specialists:<naam>`, `@specialists-lifehub:<naam>` of `@specialists-shopify:<naam>`.

## Meer weten?

Hoe een repo deze plugins consumeert (marketplace-source, `enabledPlugins`), hoe het gesplitste
manual-model werkt en hoe het bootstrap-adoptiepad (`specialists-init`) een verse repo op gang helpt,
staat in de [root-README](../../README.md) van de werkplaats.
