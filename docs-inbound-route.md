### Inbound-route geformaliseerd: issue met label inbound voor kern-verbeterpunten uit connectors · Docs · 2026-07-16

De vaste inbound-route vastgelegd in de connectors-doctrine: ontdekt een sessie in een
consumerende repo kern-verbeterpunten, dan bouwt die niet zelf maar opent een issue op deze repo
met het label `inbound` (nieuw issue-sjabloon `.github/ISSUE_TEMPLATE/inbound-verbeterpunt.md`;
label aangemaakt op GitHub). De workshop verwerkt via de normale keten en de consument haalt het
via de release-bump + plugin-update terug; een tijdelijke lens-notitie is de enige legitieme
overbrugging.