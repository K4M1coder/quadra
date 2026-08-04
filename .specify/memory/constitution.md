<!--
SYNC IMPACT REPORT — v1.1.0
===========================
Version change: 1.0.0 → 1.1.0
Nature du changement: MINOR — un article ajouté, portée de deux articles élargie

Principes ajoutés:
  - Art. 23 — La chaîne d'abord, le local en attendant

Principes modifiés:
  - Art. 8  — renvoi ajouté vers l'Art. 23 (ordre de mise en place des portes et
              régime applicable tant qu'elles n'existent pas)
  - Art. 14 — renvoi ajouté vers l'Art. 23 (les portes locales font foi seules en
              l'absence de CI)

Principes retirés: aucun

Raison du bump MINOR (et non MAJOR): aucun article n'est retiré ni redéfini de façon
incompatible. Le régime local de l'Art. 23 ne desserre pas la porte de l'Art. 8 — il
nomme où elle s'exécute tant que la chaîne n'existe pas, ce que l'Art. 14 postulait
déjà par l'équivalence « hooks locaux ≡ CI ».

Artefacts dépendants propagés dans le même changement (Art. 13):
  - specs/001-socle-compose-moteurs-caddy/plan.md — ligne Art. 23 au Constitution Check
  - specs/002-observabilite-de-base/plan.md — idem
  - specs/003-socle-qualite-ci/plan.md — idem
  - specs/004..021/plan.md — SANS OBJET : ces 18 fichiers sont des copies non remplies
    de .specify/templates/plan-template.md ; leur Constitution Check sera évalué au
    premier /speckit-plan, contre la v1.1.0.

Régime dégradé courant (consignation exigée par l'Art. 23 lui-même):
  - Ni chaîne d'intégration, ni dépôt distant à ce jour. Les portes s'exécutent en
    local et font foi ; les fusions se font en --no-ff sur la topologie
    NNN-slug → dev → test → master.
  - Condition de sortie : implémentation de S03 (jalon produit M0).

TODO différés: aucun.

HISTORIQUE
==========
Version change: (template non ratifié) → 1.0.0
Nature du changement: ratification initiale (première adoption)

Principes ajoutés (22, aucun préexistant):
  - Art. 1  — Les données restent sur site
  - Art. 2  — L'humain interactif d'abord
  - Art. 3  — Consentement explicite
  - Art. 4  — Tout est tracé, rien n'est falsifiable
  - Art. 5  — Le serveur décide, jamais l'UI
  - Art. 6  — Réutiliser, ne jamais forker
  - Art. 7  — La spec avant le code
  - Art. 8  — La qualité est mécanique
  - Art. 9  — La simplicité — opérable par un seul, lisible par un seul
  - Art. 10 — Tests d'abord, couverture mesurée
  - Art. 11 — Rien ne flotte : tout est épinglé
  - Art. 12 — Langage ubiquitaire
  - Art. 13 — Doc et changelog dans le même changement
  - Art. 14 — Histoire atomique, hooks = CI
  - Art. 15 — Boucles agentiques bornées
  - Art. 16 — La revue trie, n'abandonne jamais
  - Art. 17 — Le code modèle le domaine (DDD)
  - Art. 18 — Des modules SOLID derrière des contrats
  - Art. 19 — Une connaissance, un seul endroit (DRY)
  - Art. 20 — Rien avant le jalon qui l'exige (YAGNI)
  - Art. 21 — Sécurité du code, en continu
  - Art. 22 — L'état de l'art avant d'implémenter

Principes modifiés/renommés: aucun (première adoption)
Principes retirés: aucun

Sections ajoutées:
  - « Socle de contrôle & portes de qualité » (occupe [SECTION_2_NAME])
  - « Méthode de réalisation & profondeur des jalons » (occupe [SECTION_3_NAME])
  - « Governance » (procédure d'amendement, versionnement SemVer, contrôle de conformité)

Sections retirées: aucune

Écarts assumés par rapport au template:
  - Le template prévoit 5 emplacements de principes ; le projet en exige 22. La hiérarchie de
    titres (## Core Principles / ### <principe>) est préservée à l'identique.
  - Rédaction en français : imposée par l'Art. 12 (langage ubiquitaire) — le vocabulaire normatif
    du domaine (lane, fit, hot-swap, confirm-and-warn, canari…) est fixé en français.

Artefacts dépendants à propager:
  - .specify/templates/plan-template.md — la section « Constitution Check » de chaque plan évalue
    les 22 articles, porte franchie AVANT la génération des tâches.
  - CONSTITUTION.md à la racine du repo — copie de référence injectée dans le prompt système des
    agents. À produire par la spec S01 (socle repo).

TODO différés: aucun. Toutes les valeurs sont fournies.
-->

# Constitution Quadra

Ce texte prévaut sur toute spec, tout plan, toute tâche et toute décision de conception. Il est
chargé dans le contexte de chaque agent IA avant tout travail, accepté par chaque humain qui
contribue, et vérifié à chaque revue : un livrable qui viole un article est refusé, quel que soit
son intérêt technique. Il ne se modifie que par décision explicite du mainteneur, tracée dans
l'audit du repo — jamais par commodité.

## Core Principles

### Art. 1 — Les données restent sur site

Aucun prompt, aucune réponse, aucune métadonnée d'usage NE DOIT quitter l'infrastructure. La seule
sortie réseau autorisée en production est le téléchargement de modèles depuis Hugging Face. Aucune
télémétrie, jamais.

*Rationale* : la confidentialité est la raison d'être d'une plateforme auto-hébergée ; une seule
fuite annule la proposition de valeur entière.

### Art. 2 — L'humain interactif d'abord

Aucun agent, aucun batch, aucune tâche de fond NE DOIT dégrader l'expérience d'un humain qui attend
une réponse. La lane P0 préempte tout ; tout mécanisme nouveau DOIT prouver qu'il respecte cette
préséance.

*Rationale* : un agent peut attendre, un humain devant son écran abandonne — la préséance doit être
structurelle, pas une politesse.

### Art. 3 — Consentement explicite

Rien de coûteux ou d'irréversible sans confirmation informée : téléchargement = confirm-and-warn,
offload = opt-in par job, stockage des prompts = opt-in par clé, suppression = rôle admin. Le
silence vaut refus.

### Art. 4 — Tout est tracé, rien n'est falsifiable

Chaque requête EST métrée, chaque action sensible auditable (hash chaîné, append-only). Un composant
qui ne peut pas rendre compte de ce qu'il fait N'ENTRE PAS en production.

### Art. 5 — Le serveur décide, jamais l'UI

Toute permission (RBAC), toute limite, toute validation EST appliquée côté serveur ; l'UI ne fait
que refléter. Aucun secret en clair — ni en base, ni en log, ni en métrique.

*Rationale* : une UI est contournable par construction ; une règle qui n'existe que dans l'UI
n'existe pas.

### Art. 6 — Réutiliser, ne jamais forker

Les moteurs et briques upstream SONT consommés tels quels, derrière des contrats (drivers) qui les
rendent remplaçables. Le code custom EST limité au plan de contrôle ; chaque design emprunté cite sa
source.

### Art. 7 — La spec avant le code

Aucune ligne de code sans spec et contrat figés ; aucun dépassement de la profondeur du jalon
courant. Tout écart découvert en implémentant remonte dans le document — le document est la vérité.

### Art. 8 — La qualité est mécanique

La qualité n'est pas une intention : c'est une suite de portes mécaniques franchies dans l'ordre, et
rien NE FUSIONNE tant qu'une porte est rouge :

1. pre-commit (lint, format, scan de secrets)
2. CI : types stricts, pyramide de tests et couverture aux seuils de l'Art. 10, sécurité (Art. 21)
3. build d'images épinglées (Art. 11)
4. e2e + charge sur compose éphémère
5. canari GPU 3 avant bascule

Chaque critère d'acceptation EST prouvé par une tâche `[TEST]` tracée critère→preuve. Trois chemins
exigent EN PLUS une revue humaine : **auth**, **facturation**, **proxy streaming**.

L'ordre de mise en place de ces portes, et le régime applicable tant qu'elles n'existent pas,
relèvent de l'Art. 23.

### Art. 9 — La simplicité — opérable par un seul, lisible par un seul

Chaque ajout DOIT rester opérable par une seule personne : versions épinglées, rollback en une
commande, pas de K8s sous 3 machines, pas de brique dont la maintenance excède sa valeur. En cas de
doute : ne pas ajouter. Au niveau du code : entre deux conceptions qui satisfont les critères
d'acceptation, la plus simple gagne — la complexité se justifie par un critère mesurable, jamais par
une élégance ou une généralité supposée ; lisible par un seul dev, debuggable à 2 h du matin.

### Art. 10 — Tests d'abord, couverture mesurée

Cycle OBLIGATOIRE pour tout comportement : 1. écrire le test depuis le critère d'acceptation de la
spec · 2. le voir échouer (rouge — la preuve qu'il teste quelque chose) · 3. implémenter le minimum
qui passe au vert · 4. refactorer sous tests verts, sans changer le comportement.

La pyramide complète est due, chaque niveau à sa place dans la CI : unitaires (fonctions pures :
fit, coût, Elo) · intégration (Postgres/Redis éphémères, testcontainers) · contrat (SDK OpenAI réels
contre `/v1`, client généré jamais écrit à la main) · e2e (parcours UI playwright sur compose
éphémère + moteur factice) · charge (k6 : bursts agents, anti-starvation P0) · sécurité (bandit,
audits de dépendances) · golden files (facturation au centime) · générés (matrice RBAC depuis
`permissions.yaml`) · résilience (coupure/reprise, kill worker, restauration de sauvegarde).

Couverture ≥ 90 % sur le cœur (auth, quotas, accounting), ≥ 70 % ailleurs, mesurée par l'outillage —
un chiffre annoncé sans sortie capturée est une opinion, pas une couverture.

### Art. 11 — Rien ne flotte : tout est épinglé

Toute image, dépendance ou action CI EST épinglée sur un tag exact ou un digest — jamais `:latest`,
jamais une branche, jamais un intervalle ouvert.

*Rationale* : l'épinglage n'est pas de l'hygiène — c'est la condition du canari GPU 3 et du rollback
en une commande.

### Art. 12 — Langage ubiquitaire

Le vocabulaire du domaine EST fixé par le document de référence et employé tel quel dans les specs,
le code, l'API, la base et l'UI : lane (jamais « priorité »), fit (fits/tight/won't fit), hot-swap,
TTL, quant, driver, géré/attaché, confirm-and-warn, canari. Renommer un terme est un amendement, pas
un refactoring. Le glossaire normatif du projet fait foi.

### Art. 13 — Doc et changelog dans le même changement

Tout changement de comportement visible (option, route, métrique, flag) MET À JOUR la documentation
et le CHANGELOG (SemVer + Keep a Changelog) dans le même changement. Un changement fusionné sans sa
doc est incomplet — pas « à documenter plus tard ».

### Art. 14 — Histoire atomique, hooks = CI

Commits conventionnels et atomiques : un changement logique, un état qui fonctionne, un message qui
dit pourquoi. Les hooks locaux exécutent EXACTEMENT les portes de la CI — un commit vert en local
prédit une CI verte. Désactiver une porte pour faire passer un commit n'est pas une mitigation,
c'est une faute. En l'absence de CI, les portes locales font foi seules (Art. 23).

### Art. 15 — Boucles agentiques bornées

Tout workflow agentique récurrent ou long — dans le produit comme sur le repo — DÉCLARE une
condition d'arrêt explicite ou une cadence de contrôle, journalise ses actions pour l'audit, et
N'EXÉCUTE aucune opération destructive ou difficilement réversible sans autorisation préalable
capturée dans la spec qui le gouverne.

*Rationale* : une boucle sans arrêt sur 4 GPUs ne se remarque pas — elle se facture.

### Art. 16 — La revue trie, n'abandonne jamais

Tout changement non trivial EST revu avant fusion — par un humain, ou par une passe agentique
indépendante hors du chemin du risque (Art. 8). Chaque constat est corrigé ou explicitement accepté
avec sa raison, tracé — rien n'est silencieusement ignoré. Une porte rouge arrête le fil : maquiller
un échec est une faute de gouvernance, pas un raccourci.

### Art. 17 — Le code modèle le domaine (DDD)

Entités, états et relations VIENNENT de la taxonomie et des machines à états ; le code les modélise
telles quelles, avec le vocabulaire de l'Art. 12. Un concept absent de la taxonomie s'y ajoute
d'abord (amendement), il ne naît jamais dans le code.

### Art. 18 — Des modules SOLID derrière des contrats

Chaque module a une responsabilité unique et s'étend sans se modifier : on ajoute un moteur en
écrivant un driver, jamais en touchant le superviseur. Les dépendances pointent vers des
abstractions (contrat driver, OpenAPI, topics `/ws`) — remplacer une implémentation ne casse aucun
appelant.

### Art. 19 — Une connaissance, un seul endroit (DRY)

Toute vérité a une source unique qui génère le reste : le contrat OpenAPI génère le client
TypeScript, `permissions.yaml` génère la matrice de tests, le glossaire fixe les labels UI.
Dupliquer une règle à la main crée deux versions qui divergeront — c'est la définition du bug futur.

### Art. 20 — Rien avant le jalon qui l'exige (YAGNI)

On N'IMPLÉMENTE ni champ, ni option, ni abstraction « pour plus tard » — le périmètre est celui de
la spec, la profondeur celle du jalon courant (Art. 7). Un besoin futur pressenti se note dans la
spec concernée — il ne se code pas par anticipation.

### Art. 21 — Sécurité du code, en continu

Revue de sécurité mécanique à chaque commit : bandit, pip-audit / npm audit, aucun secret en dur
(scan pré-commit), entrées validées aux frontières (Pydantic aux routes, jamais de SQL construit),
dépendances auditées en continu (l'épinglage relève de l'Art. 11). Une vulnérabilité connue sans
correctif upstream se documente et s'isole — jamais silencieusement acceptée.

### Art. 22 — L'état de l'art avant d'implémenter

Avant toute spec et toute implémentation non triviale : vérifier ce qui existe (outils,
bibliothèques, designs), comparer aux pratiques actuelles, et consigner dans la spec ce qui est
réutilisé, imité ou écarté, avec la raison. Implémenter sans avoir regardé l'existant viole l'Art. 6
par ignorance — la veille fait partie du travail, pas du luxe.

### Art. 23 — La chaîne d'abord, le local en attendant

La chaîne d'intégration et de déploiement EST mise en place au plus tôt : sa construction PRIME sur
toute fonctionnalité métier, car sans elle la definition of done n'est pas mécaniquement vérifiable
et la délégation aux agents (Art. 8) retombe sur du jugement.

**Dès qu'elle existe, son usage est OBLIGATOIRE et exclusif** : aucun changement n'entre sans l'avoir
traversée, aucune porte n'est contournée, aucune fusion ne se fait hors d'elle. Il en va de même du
dépôt distant dès qu'il existe : la fusion passe par la forge et ses protections de branche — jamais
par un merge local.

**En son absence, tout s'exécute EN LOCAL et fait foi** : les portes locales (style, typage, tests,
couverture, sécurité) sont exécutées avant chaque validation et leur sortie capturée EST la
definition of done ; sans dépôt distant, le versionnement et les fusions se font en local.

La topologie de fusion EST fixe : les branches de développement portent le nommage Spec Kit
(`NNN-slug`) et n'entrent dans `dev` que par demande de fusion ; `dev` promeut vers `test`, où la
chaîne s'exécute intégralement ; `test` promeut vers `master`, qui reste stable par construction. Les
portes de rang 1 à 3 gardent l'entrée dans `dev` ; les portes 4 et 5, qui n'existent qu'à distance,
gardent la promotion de `test`. Aucune promotion ne saute un maillon, et aucun commit direct
n'atterrit sur `test` ni sur `master`.

Ce régime dégradé EST transitoire, assumé et consigné dans le dépôt. Il n'est jamais un état cible :
il cesse à l'instant où la chaîne ou la forge existe, et sa persistance au-delà du jalon qui la
prévoit est un constat de revue (Art. 16), pas une habitude.

*Rationale* : une porte qui n'existe pas encore ne dispense pas de la franchir — elle déplace
seulement où on la franchit. Nommer le régime dégradé et le borner dans le temps empêche les deux
dérives symétriques : attendre la CI pour se donner des critères, et s'habituer au local une fois la
CI disponible.

## Socle de contrôle & portes de qualité

Les portes de l'Art. 8 sont outillées, jamais déclaratives. La configuration est versionnée :
`pyproject.toml` · `.pre-commit-config.yaml` · `eslint.config.js` · `playwright.config.ts` ·
`Makefile` · `ci.yaml`.

**Backend Python** — ruff (lint + format) · mypy `--strict` sur le plan de contrôle · pytest +
pytest-cov · pytest-asyncio (gateway, streaming, `/ws`) · testcontainers (Postgres/Redis
éphémères) · `alembic check`.

**Frontend React** — TypeScript strict + vite · eslint (flat config) + prettier · vitest +
testing-library · playwright (e2e des parcours) · openapi-typescript (client généré depuis le
contrat — jamais écrit à la main, Art. 19).

**Qualité transverse** — pre-commit sur tout le lint · conventional commits + changelog généré ·
seuils de couverture bloquants (Art. 10) · matrice RBAC pytest générée depuis `permissions.yaml` ·
k6 (bursts agents, 500 req parallèles) · bandit + pip-audit / npm audit.

**Build & versions** — uv (lockfile Python reproductible) · Docker multi-stage, image gateway
< 300 MB · compose build + healthchecks (démo = prod) · tags image semver + sha, rollback = re-tag ·
Makefile `lint / test / e2e / build / up`.

**Règles d'exécution non négociables** :

- La CI NE TOUCHE JAMAIS un GPU. Les tests d'intégration tournent contre un **moteur factice**
  (serveur OpenAI simulé : latence, streaming, erreurs injectables) ; les vrais moteurs ne sont
  exercés qu'au canari.
- **Definition of done d'une tâche** : lint + types propres, tests écrits et verts, couverture au
  seuil, contrat OpenAPI inchangé ou versionné. C'est le critère mécanique qui permet de déléguer
  les tâches aux agents IA et de ne relire à la main que auth, facturation et proxy streaming.

## Méthode de réalisation & profondeur des jalons

**Le contrat avant la spec, la spec avant le code.** Chaque feature commence par sa spec (ce qu'elle
fait, pour qui, avec quels critères d'acceptation mesurables) et ses contrats (routes OpenAPI,
tables, métriques, événements `/ws`) écrits avant l'implémentation. Le plan traduit la spec en
étapes ordonnées avec la stack et les consignes ; les tâches découpent le plan en unités confiables
à un agent IA, chacune testable isolément.

**Cycle d'une spec** : 1. rédiger la spec (feature + critères) — humain · 2. figer les contrats
(OpenAPI, tables, métriques) — humain · 3. dériver le plan (étapes, stack, consignes) — humain +
agent · 4. découper en tâches → agents en parallèle · 5. CI (lint, types, tests, couverture) ·
6. revue de l'interface, pas de chaque ligne · 7. canari GPU 3 → bascule.

**Règles de découpage** :

- Une spec = une feature livrable seule ; jamais deux specs en vol pour un agent.
- Un critère d'acceptation non testable EST reformulé.
- Une tâche = < 1 jour d'agent, entrée/sortie explicites.
- Tout écart au plan pendant l'implémentation remonte dans la spec — le document reste la vérité.

**Phases et jalons sont deux axes distincts** : la *phase* dit dans quel ordre on construit
(contrainte de dépendances, vue ingénierie) ; le *jalon produit* dit ce qu'on livre et jusqu'à
quelle profondeur (vue produit). Les jalons internes J1–J4 appartiennent à une spec ; les jalons
produit M0–M4 sont trans-specs et **limitent la profondeur** de chaque spec. On ne dépasse JAMAIS la
profondeur du jalon courant (Art. 7, Art. 20) ; sans deadline, c'est la sortie des tâches `[TEST]`
qui déclenche le jalon suivant.

## Governance

**Autorité** — Cette constitution prévaut sur toute spec, tout plan, toute tâche et toute décision
de conception. Elle vit dans le repo (`CONSTITUTION.md`, dont ce fichier est la source), est
injectée dans le prompt système de chaque agent, acceptée par chaque humain, et référencée par la
definition of done.

**Aucun article n'est négociable** — aucune dérogation ponctuelle, dans aucune spec, pour aucun
article. Faire évoluer un article exige un amendement, jamais une exception. La section
« Complexity Tracking » d'un plan sert à justifier une complexité technique, jamais à contourner un
article.

**Versionnement (SemVer)** :

- **MAJOR** — retrait ou redéfinition d'un article.
- **MINOR** — nouvel article ou élargissement matériel de la portée d'un article existant.
- **PATCH** — clarification, reformulation ou correction sans effet sémantique.

**Procédure d'amendement** — un amendement est proposé par écrit avec sa raison, décidé
explicitement par le mainteneur, tracé dans l'audit du repo, et appliqué **via l'outil de
gouvernance** (`/speckit-constitution`) — jamais par édition manuelle. Le changement embarque son
rapport d'impact (Sync Impact Report) et propage aux artefacts dépendants **dans le même
changement** (Art. 13).

**Contrôle de conformité** — chaque plan de spec porte une porte « Constitution Check » évaluée
**avant** la génération des tâches, et re-vérifiée après la conception détaillée. Une porte rouge
arrête le fil (Art. 16). Toute revue — humaine ou agentique — vérifie la conformité article par
article ; un livrable qui viole un article est refusé, quel que soit son intérêt technique.

**Guidance runtime** — `agent.md` (usage de Spec Kit dans ce dépôt) et ce fichier sont chargés par
tout agent avant travail. Le document produit de référence (`Quadra Document Complet.html`) reste la
source de vérité fonctionnelle : taxonomie des entités, glossaire normatif, machines à états et
matrice RBAC.

**Version**: 1.1.0 | **Ratified**: 2026-08-01 | **Last Amended**: 2026-08-04
