# Implementation Plan: S03 — Socle qualité & CI

**Branch**: `003-socle-qualite-ci` | **Date**: 2026-08-05 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-socle-qualite-ci/spec.md`

## Summary

Rendre la **definition of done mécanique** avant la première ligne de code métier : portes locales,
chaîne d'intégration ordonnée, seuils de couverture bloquants, topologie de fusion gardée, et un
**moteur d'inférence factice** qui permet de tout tester sans GPU.

**Approche technique** : deux versants outillés séparément (plan de contrôle et interface) mais
**un seul ordre de portes** et **un seul jeu de seuils**, définis une fois. L'équivalence entre les
portes locales et celles de la chaîne est obtenue par **définition unique** — les cibles du `Makefile`
(`9b`) sont l'unique surface d'invocation, que la configuration locale et la définition de chaîne
consomment toutes deux — et non par un mécanisme de comparaison (SC-005). Le moteur factice est un
**paquet distribuable**, pas un fichier de test : il sera consommé par S04 à S20.

**Point de vigilance principal** : la couverture. Atteindre 90 % avec des tests qui n'assertent rien
satisferait la lettre de l'Art. 10 en violant son esprit. Le plan traite le seuil comme **nécessaire
mais non suffisant** — le cycle rouge → vert reste dû pour tout comportement.

## Technical Context

**Language/Version** : **Python 3.12** (plan de contrôle) · **TypeScript strict** (interface).
S03 ne livre aucun code métier : elle livre de la **configuration outillée** et **un composant
réutilisable** (le moteur factice).

**Primary Dependencies** — versions retenues épinglées par verrou de dépendances (Art. 11). Chaque
ligne est sourcée par `9b` (socle de contrôle des développements) ou par la fiche `9h` ; aucune
dépendance n'est ajoutée hors de ces deux sources. Aucune n'est concernée par une décision D1–D6 de
la veille.

| Versant | Rôle | Composant | Source |
| --- | --- | --- | --- |
| Plan de contrôle | lint + format | ruff — **porte de style** (FR-001) | `9b`, `9h` |
| | typage strict | mypy `--strict` (FR-003) | `9b`, `9h` |
| | tests + couverture | pytest · pytest-cov · pytest-asyncio — **seuils bloquants** (FR-015, FR-024) | `9b`, `9h` |
| | bases éphémères | testcontainers (FR-022) | `9b` |
| | cohérence des migrations | `alembic check` — **porte** (FR-028) | `9b` |
| Interface | lint + format | eslint (flat config) · prettier — **second versant** (FR-005) | `9b`, `9h` |
| | tests de composants | vitest · testing-library (FR-005) | `9b`, `9h` |
| | bout en bout | playwright — niveau *bout en bout* (FR-021) | `9b`, `9h` |
| Transverse | portes locales | pre-commit — refus **avant envoi**, le fichier en cause étant nommé (FR-001, FR-006) | `9b`, `9h` |
| | convention de commits | conventional commits, `scope` = spec (FR-004) | `9b`, `10b` |
| | charge | k6 — **porte** de l'étape 6 (FR-027) | `9b`, Art. 8 porte 4 |
| | sécurité | bandit · pip-audit · npm audit — la dépendance ou le motif est **nommé** (FR-018) | `9b` |
| | épinglage de la définition de chaîne | contrôle de références flottantes (FR-026) | Art. 11 |
| | garde de topologie de fusion | contrôle local de branche courante (FR-029) | Art. 23 |
| Build | verrou reproductible | uv | `9b` |
| | images | construction multi-étapes, étiquetage reproductible (FR-019), **image du plan de contrôle < 300 Mo** | `9b` |

Les deux contrôles sans outil nommé — épinglage de la définition de chaîne, garde de topologie — sont
**postérieurs au document de référence** : ils viennent de l'Art. 11 (« toute image, dépendance ou
action CI EST épinglée ») et de l'Art. 23 (topologie de fusion fixe). Ils sont donc spécifiés par leur
effet, sans désigner d'outil que le document ne nomme pas.

**Storage** : aucun stockage propre. Les tests d'intégration démarrent des **bases éphémères**
(FR-022), créées et détruites par le test lui-même, sans instance partagée.

**Testing** : S03 **est** l'outillage de test. Sa propre preuve (réf. `9h` T10) vérifie qu'une porte
refuse un fichier non conforme, que la chaîne échoue sous les seuils, et que le moteur factice
reproduit flux, latence et erreurs — c'est la procédure automatisée exigée par **FR-025**.

**Target Platform** : machines de développement et agents d'exécution de la chaîne, **sans GPU**.
C'est une **contrainte d'architecture**, pas une limitation temporaire.

**Performance Goals** : un état vert local doit prédire un état vert distant (Art. 14) — c'est la
seule propriété visée, et elle se vérifie par la définition unique des portes, non par une durée.
**Aucune cible de durée n'est fixée** : ni `9b`, ni `9h`, ni la constitution n'en donnent, et le plan
n'en invente pas.

**Constraints** :

- **La chaîne d'intégration ne touche jamais un GPU** (FR-016, Art. 8). Les vrais moteurs ne sont
  exercés qu'au canari.
- **Seuils bloquants** (FR-015) : **≥ 90 %** sur le cœur (authentification, quotas, comptabilité),
  **≥ 70 %** ailleurs — mesurés par l'outillage, jamais annoncés.
- **Ordre des portes imposé** (FR-013) : style/format → typage → tests + couverture → sécurité →
  construction d'images → **bout en bout et charge**. Le dernier maillon est une porte unique
  (Art. 8 porte 4 ; `9b` « e2e + k6 »). **Une seule porte rouge suffit à bloquer la fusion**
  (FR-014) : il n'existe pas de contournement.
- **Définition de la chaîne épinglée** au même titre que ce qu'elle produit : aucune action, aucun
  outil, aucune image consommée sur `:latest`, sur une branche ou sur un intervalle ouvert (FR-026,
  Art. 11). FR-019 couvre les images **construites**, FR-026 les briques **consommées**.
- **Topologie de fusion fixe** : `NNN-slug` → `dev` → `test` → `master` ; aucun commit direct sur
  `test` ni sur `master`, aucune promotion qui saute un maillon (FR-029, Art. 23).
- **Usage obligatoire et exclusif de la chaîne dès qu'elle existe** ; en son absence, les portes
  locales font foi seules et leur sortie capturée EST la definition of done (FR-030, Art. 23).
- **Toute la configuration de portes est versionnée** — désactiver une porte doit se voir en revue.

**Scale/Scope** : 2 versants outillés (FR-005) · **6 étapes de chaîne** (la 6ᵉ portant bout en bout **et**
charge) · **5 des 9 niveaux de la pyramide posés à M0** — unitaires, intégration sur bases éphémères,
bout en bout, charge, sécurité (FR-021) ; les 4 autres sont rendus exécutables par les specs qui les
produisent (contrat → S04 · fichiers de référence → S08 · tests générés → S13 · résilience → S19–S21)
· 1 moteur factice distribuable · **6 fichiers de configuration versionnés** par `9b`.

### Décisions issues de la veille — **arbitrées**

Référence : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md), §7. Elle n'est pas dupliquée ici
(Art. 19).

- **Aucune décision D1–D6 ne couvre S03 en propre.** D1 et D2 portent sur l'infrastructure déployée
  (S01, S02) ; D3–D6 sur S09, S16, S18, S04. S03 n'épingle que des outils de développement, dont les
  versions vivent dans les verrous de dépendances.
- **Conséquence indirecte de D1** : les **bases éphémères** des tests d'intégration doivent utiliser
  **les mêmes majeures** que celles retenues en production (base relationnelle 18.x, cache 8.x).
  Tester contre une majeure antérieure ferait passer des tests qui échoueraient en production —
  c'est le seul point où D1 touche S03.
- **La veille est muette sur la plateforme d'hébergement du dépôt et sur l'exécuteur de la chaîne.**
  C'est la source de l'ARBITRAGE 1 : rien dans le projet ne permet de choisir à la place du
  mainteneur, et ce plan ne choisit pas.

## Constitution Check

*GATE : à franchir avant la génération des tâches. Ré-évalué après la conception détaillée.*

| Art. | Exigence | Statut | Comment S03 s'y conforme |
| --- | --- | --- | --- |
| 1 | Données sur site | ➖ | S03 ne manipule aucune donnée d'usage. Les audits de dépendances interrogent des registres publics — flux d'outillage, hors production. |
| 2 | Humain interactif d'abord | ➖ | Aucun ordonnancement. |
| 3 | Consentement explicite | ➖ | Aucune action coûteuse ni irréversible. |
| 4 | Tout est tracé | ➖ | L'article porte sur le **métrage des requêtes** et l'**audit à hash chaîné** des actions sensibles : S03 n'en produit aucun — ni requête servie, ni acteur, ni chaîne d'audit. La capture des sorties d'outillage relève de l'Art. 10, ligne ci-dessous. |
| 5 | Le serveur décide | ➖ | Aucune permission. |
| 6 | Réutiliser, ne jamais forker | ✅ | Outils consommés tels quels. Le moteur factice **simule** le contrat d'inférence, il ne forke aucun moteur. |
| 7 | La spec avant le code | ✅ | Spec S03 figée et validée avant ce plan ; aucune étape ne dépasse la profondeur de **M0** (`9e` : « S03 complet »). |
| 8 | Qualité mécanique | ✅ | **Article central.** S03 outille les portes **1 à 4** dans l'ordre, **charge comprise** (porte 4 : « e2e + charge sur compose éphémère »), avec blocage de fusion ; la porte 5 (canari GPU) reste hors chaîne. Les **trois chemins** à revue humaine — auth, facturation, proxy streaming — sont rendus visibles dans le processus. |
| 9 | Simplicité | ✅ | Un seul ordre de portes, un seul jeu de seuils, un seul moteur factice, une seule surface d'invocation — pas de variante par versant. |
| 10 | Tests d'abord | ✅ | **Article central.** Les **5 niveaux posables à M0** sont outillés (FR-021) ; les 4 autres sont rendus exécutables par les specs qui les produisent, sans anticipation (Art. 20). Les seuils sont **mesurés** par l'outillage et leurs sorties **capturées** — « un chiffre **annoncé** sans sortie capturée est une opinion, **pas une couverture** » (FR-015, FR-024). La preuve (réf. `9h` T10) est écrite rouge avant les portes (FR-025). |
| 11 | Rien ne flotte | ✅ | Trois épinglages, pas un : verrou de dépendances reproductible ; images construites étiquetées version + empreinte (FR-019), condition du retour arrière ; **briques consommées par la chaîne** — actions, outils, images — épinglées par tag exact ou empreinte, un référencement flottant faisant échouer la chaîne (FR-026, SC-011). |
| 12 | Langage ubiquitaire | ✅ | Nommage des tests et des étapes aligné sur le vocabulaire du domaine ; les identifiants de `10b` sont employés tels quels — `lane` dans `k6/<lane>-<scénario>.js`, `scope` = spec dans les messages de validation. |
| 13 | Doc et changelog | ✅ | Convention de commits → journal des modifications généré (Keep a Changelog, `10b`). |
| 14 | Histoire atomique, hooks = CI | ✅ | **Article central.** FR-002 : portes locales ≡ portes de la chaîne pour les rangs 1 à 3, obtenu par **définition unique** versionnée et invoquée de part et d'autre (FR-020, SC-005) — l'article exige l'équivalence, pas un mécanisme de comparaison. Commits conventionnels au `scope` = spec, vérifiés mécaniquement (FR-004). |
| 15 | Boucles bornées | ➖ | Aucune boucle agentique dans l'outillage. |
| 16 | La revue trie | ✅ | Une porte rouge arrête le fil ; la configuration versionnée rend visible toute désactivation, y compris celle d'une garde de topologie ou d'épinglage. |
| 17 | Le code modèle le domaine | ✅ | Le moteur factice se rattache à `Engine` de l'arbre d'exécution de `10a` (`Cluster → Host → Node → Engine → Instance`) **sans être une `Instance`** : il ne sert aucun `alias` et ne réside sur aucun `node`. Aucune autre entité n'est créée : **portes**, **seuils** et **étapes** ne sont pas modélisés — l'arbre de la méthode de `10a` s'arrête à `Tâche Tn` — et le faire exigerait un amendement préalable de `10a` (ARBITRAGE 5). |
| 18 | Modules SOLID | ✅ | Ajouter un niveau de test = ajouter une étape, sans toucher aux autres. |
| 19 | Une connaissance, un endroit | ✅ | **Article central.** Un seul moteur factice (FR-012) ; une seule déclaration de portes consommée en local et à distance (FR-002) ; seuils définis une fois ; la topologie de fusion est déclarée par l'Art. 23 et seulement **gardée** ici ; les scénarios de charge appartiennent à **S21** — S03 pose l'étape et le minimum qui prouve la porte, sans créer un second jeu (FR-027). |
| 20 | YAGNI | ✅ | Aucun test métier ici — seulement l'outillage. La matrice de permissions vient de S13, les scénarios de charge de S21, la **génération du client d'interface de S11** (`9p` T2, jalon M2). `9h` borne `ui/` à « eslint flat, prettier, vitest, playwright ». |
| 21 | Sécurité continue | ✅ | Analyse statique + audits de dépendances + scan de secrets dans les portes ; une vulnérabilité sans correctif se documente, ne se tait pas. |
| 22 | État de l'art | ✅ | Veille consignée et non dupliquée ; aucune décision D1–D6 ne couvre S03 en propre ; la conséquence indirecte de D1 est répercutée sur les bases éphémères ; le silence de la veille sur l'exécuteur est porté en ARBITRAGE 1. |
| 23 | La chaîne d'abord, le local en attendant | ✅ | **Article central.** S03 **est** la chaîne dont l'Art. 23 exige la mise en place au plus tôt : elle prime sur toute fonctionnalité métier, et sa livraison est la condition de sortie du régime dégradé consigné dans la constitution (FR-030). La topologie `NNN-slug` → `dev` → `test` → `master` recouvre l'ordre des portes sans retouche — rangs 1 à 3 à l'entrée dans `dev`, rangs 4 et 5, qui n'existent qu'à distance, à la promotion de `test` — et elle est **outillée**, pas seulement affirmée : un contrôle local versionné refuse tout commit dont la branche courante est `test` ou `master` et toute promotion qui saute un maillon (FR-029, SC-009) ; les protections de branche de la forge exprimeront la même règle dès qu'une forge sera choisie (ARBITRAGE 1). La définition unique des portes est ce qui rend le régime local prédictif du régime distant. |

**Verdict** : porte **franchie**. Aucun article violé. `Complexity Tracking` vide.

## Project Structure

### Documentation (this feature)

```text
specs/003-socle-qualite-ci/
├── plan.md              # Ce fichier
├── research.md          # Phase 0
├── data-model.md        # Phase 1 — objets d'outillage
├── quickstart.md        # Phase 1 — guide de validation
├── contracts/
│   ├── fake-engine.md   # Contrat du moteur factice (consommé par S04..S20)
│   └── quality-gates.md # Contrat de la definition of done mécanique
├── checklists/
│   └── requirements.md  # Déjà produite
└── tasks.md             # Produit par /speckit-tasks
```

### Source Code (repository root)

```text
pyproject.toml                  # ruff + mypy strict + pytest + couverture + `alembic check` (réf. `9h` T1, T2)
.pre-commit-config.yaml         # Portes locales · convention de commits (`scope` = spec) ·
                                #   garde de topologie (FR-029) · garde d'épinglage (FR-026)  (réf. `9h` T3)
eslint.config.js                # Lint interface (réf. `9h` T4)
playwright.config.ts            # Bout en bout (réf. `9h` T5)
Makefile                        # lint / test / e2e / build / up — DÉFINITION UNIQUE des portes,
                                #   invoquée à l'identique en local et par la chaîne (FR-002, SC-005)
uv.lock                         # Verrou reproductible (réf. `9h` T1)

ci.yaml                         # Chaîne : style → typage → tests + couverture → sécurité →
                                #   construction d'images → bout en bout ET charge (réf. `9h` T8, T9)
                                # Nom fixé par `9b` ; emplacement et plateforme NON fixés — ARBITRAGE 1

k6/<lane>-<scénario>.js         # Graphie fixée par `10b`. S03 pose le minimum qui prouve la porte ;
                                #   S21 versionne les scénarios sans en créer un second jeu (FR-027)

packages/
└── fake-engine/                # PAQUET DISTRIBUABLE, pas un fichier de test
    ├── pyproject.toml          # publiable et versionné
    └── src/fake_engine/
        ├── server.py           # Contrat d'inférence simulé, sans GPU : complétion, flux jeton par
                                #   jeton (FR-007, FR-008) (réf. `9h` T6)
        ├── control.py          # injection d'erreur · réglage de latence premier jeton et inter-jetons
                                #   (FR-009, FR-010) (réf. `9h` T7)
        └── embeddings.py       # Représentations vectorielles (FR-011) (réf. `9h` T7)

ui/
└── package.json                # eslint · prettier · vitest · playwright (réf. `9h` T4, T5)
                                # Borne de `9h` pour `ui/` — le client généré relève de S11

tests/
├── conftest.py                 # Bases éphémères partagées, aux majeures de production (D1)
├── smoke/                      # Fumée bout en bout (réf. `9h` T5)
└── tooling/
    ├── test_quality_gates.py   # Une porte refuse · la chaîne échoue sous seuil (réf. `9h` T10)
    └── test_fake_engine.py     # Flux, latence, erreurs (réf. `9h` T10)
```

**Structure Decision** : trois choix portent la structure.

1. Le moteur factice vit dans `packages/fake-engine/` avec **son propre manifeste** — c'est ce qui
   en fait un composant **installable par les autres specs** plutôt qu'un fichier copié (FR-012).
2. Les cibles du `Makefile` (`9b` : `make lint / test / e2e / build / up`) sont la **définition
   unique** des portes. `.pre-commit-config.yaml` et la définition de chaîne les **invoquent** au
   lieu de redéclarer des contrôles — il n'existe donc jamais deux listes à comparer (SC-005).
3. Les deux gardes postérieures au document — topologie de fusion et épinglage de la définition de
   chaîne — vivent dans `.pre-commit-config.yaml`, **déjà versionné par `9b`** : aucun fichier
   inventé, et leur désactivation reste un diff visible en revue.

Aucun chemin de ce plan ne désigne de plateforme d'intégration. Le fichier de définition de chaîne
est nommé `ci.yaml` d'après `9b` ; son emplacement suit la forge qui sera choisie (ARBITRAGE 1).

## Ordre de construction

Jalons de la fiche `9h`, tous dans la profondeur du jalon produit **M0** (`9e` : « S03 complet »).
**`tasks.md` est la source unique du détail des tâches** (Art. 19).

| Jalon | Intention | User story | Rattachement `9h` | Tâches |
| --- | --- | --- | --- | --- |
| **J1** Fondations | lint, types et tests configurés des deux côtés | US1 (P1) | critère **A1** « pre-commit bloque un fichier non conforme » | voir [`tasks.md`](./tasks.md) |
| **J2** Cœur | un moteur factice simule l'inférence pour tous les tests | US2 (P2) | critère **A3** « le moteur factice simule streaming, latence et erreurs » | idem |
| **J3** Chaîne | la chaîne rejoue tout — bout en bout **et charge** | US3 (P3) | critère **A2** « CI rouge si couverture < seuils » · consigne « la CI ne touche jamais un GPU » | idem |
| **J4** Preuves | porte qui bloque, chaîne rouge sous seuil, scénarios simulés | — | critères **A1**, **A2**, **A3** (tâche `[TEST]` de `9h`) | idem |

**Exigences sans critère `9h`** — quatre exigences de la spec sont **postérieures au document** ou
portées par `9b` sans critère d'acceptation propre. Elles se rattachent à leur source, jamais à un
critère inventé :

| Exigence | Source | Jalon d'accueil |
| --- | --- | --- |
| FR-026 épinglage de la définition de chaîne (SC-011) | Art. 11 (« ou action CI ») | J1 (garde locale) + J3 (étape) |
| FR-027 la charge est une porte (SC-010) | Art. 8 porte 4 · `9b` « e2e + k6 » | J3 |
| FR-028 cohérence des migrations | `9b` « `alembic check` » | J1 (déclaration) + J3 (étape) — ARBITRAGE 2 |
| FR-029 / FR-030 topologie et exclusivité (SC-009) | Art. 23, postérieur au document | **J1 seul** (garde locale) — le volet *promotion* est **suspendu à ARBITRAGE 1** |

**Pourquoi FR-029 / FR-030 n'ont pas de volet J3** : le versant *promotion* de la topologie —
protections de branche exprimant la même règle à distance — **ne peut pas être configuré avant
ARBITRAGE 1** (aucune forge n'est choisie). Il reste donc une **exigence suspendue**, sans tâche, et
n'est pas inscrit au jalon J3 : une ligne de plan sans tâche serait une couverture affirmée. Ce qui est
livré à M0 est la **garde locale versionnée** de J1, qui vaut dans le régime local de l'Art. 23 ; le
volet distant sera ouvert par l'arbitrage sur la forge, pas par S03.

**Contraintes d'ordre** : J1 précède tout. **J2 est indépendante de J1** — le moteur factice ne
dépend d'aucune porte et peut être développé en parallèle par un second agent. J3 exige J1 et J2.
J4 exige les trois.

## Consignes d'implémentation

- **Équivalence locale ↔ chaîne par définition unique, pas par comparaison.** FR-002 et SC-005
  exigent que les deux ensembles de contrôles soient **identiques** pour les rangs 1 à 3. La façon
  retenue : les cibles du `Makefile` sont la seule déclaration des portes ; la configuration locale
  et la définition de chaîne les **invoquent**. Il n'existe donc pas deux listes susceptibles de
  diverger — l'équivalence est structurelle. **Aucun test de parité n'est écrit** : la constitution
  (Art. 14) exige l'équivalence, et SC-005 précise qu'aucun mécanisme de comparaison n'est requis.
  Corollaire à faire respecter en revue : une étape de chaîne qui redéclare un contrôle au lieu
  d'invoquer sa cible est un constat de revue (Art. 16), car c'est précisément là que la divergence
  redeviendrait possible.
- **Le moteur factice est un paquet, pas un fichier.** Il porte son propre manifeste, il est
  versionné, et les autres specs l'installent comme dépendance de test. Un fichier copié divergerait
  entre specs et invaliderait toute la pyramide (FR-012).
- **La couverture est nécessaire, pas suffisante.** Le seuil bloque, mais ne prouve pas que les tests
  assertent. Le cycle rouge → vert reste dû pour tout comportement (Art. 10) — à faire respecter en
  revue, la mécanique ne peut pas le vérifier seule. **À dire explicitement dans la documentation des
  commandes uniformes** exigée par **FR-023**, dont le chemin n'est fixé par aucune source
  (ARBITRAGE 3) : ne pas en inventer un.
- **Bases éphémères aux majeures de production.** Conséquence de D1 : tester contre une majeure
  antérieure ferait passer des tests qui échoueraient en production.
- **Aucun accès GPU dans la chaîne.** Contrainte d'architecture. Le moteur factice existe précisément
  pour cela. **Quatre** exigences du projet échappent donc à la chaîne et sont prouvées au banc /
  canari — cibles de collecte `up` et cartes rafraîchies (S02, **dès M0**), découverte de topologie
  matérielle (S06), calibration du verdict de `fit` (S09), débit additionné sur deux `host` (S20) : à
  dire dans les plans concernés plutôt qu'à croire couvert ici. La liste unique vit dans
  [`contracts/quality-gates.md`](./contracts/quality-gates.md) (Art. 19) ; toute spec qui en découvre
  une l'y ajoute.
- **Trois épinglages distincts, à ne pas confondre.**
  1. Les **dépendances** sont épinglées par le verrou reproductible.
  2. Les **images construites** sont étiquetées version + empreinte (FR-019) — c'est ce qui rend le
     retour arrière possible par ré-étiquetage (Art. 11), en articulation avec S01 qui consomme ces
     images.
  3. Les **briques consommées par la chaîne** — actions, outils, images de base des étapes — sont
     référencées par tag exact ou empreinte (FR-026). Un contrôle refuse `:latest`, une branche ou un
     intervalle ouvert dans la définition de chaîne ; il tourne en porte locale **et** en étape, pour
     que le refus survienne avant l'envoi. SC-011 exige 100 % : la porte ne connaît pas d'exception.
- **La charge est une porte, pas une mesure indicative.** Le dernier maillon de la chaîne est
  **unique** : bout en bout **et** charge, sur le même environnement éphémère et contre le même
  moteur factice (FR-013, FR-017, FR-027). Un scénario de charge en échec fait échouer la chaîne et
  bloque la fusion (SC-010). S03 y place le **minimum qui prouve la porte** ; les scénarios vivent
  dans `k6/<lane>-<scénario>.js` (`10b`) et sont versionnés par **S21**, qui les rejoue sans en créer
  un second jeu (Art. 19). Une dépendance déclarée sans porte n'est pas une porte : c'est ce défaut
  que cette consigne corrige.
- **Cohérence des migrations : la porte est posée, même vide.** `alembic check` (`9b`) est déclaré
  dans le manifeste du plan de contrôle et exécuté au **rang 3** de la chaîne (tests et couverture),
  donc dans l'ensemble couvert par l'équivalence locale ↔ chaîne. À **M0 aucune migration n'existe**
  — le schéma arrive avec S04 (`9c`, jalon M1) — la porte s'exécute donc à vide et doit **réussir à
  vide sans être neutralisée** : la désactiver « en attendant » la rendrait invisible au moment où
  elle compterait. Son rattachement à S03 plutôt qu'à S04 est un ARBITRAGE 2 non tranché.
- **Topologie de fusion : gardée, pas seulement affirmée.** L'Art. 23 déclare la topologie ; S03 ne
  la redéclare pas (Art. 19) et se borne à l'**outiller**, en deux couches indépendantes de toute
  plateforme :
  1. **Garde locale versionnée** — un contrôle de `.pre-commit-config.yaml` refuse toute validation
     dont la branche courante est `test` ou `master`, et refuse une promotion qui saute un maillon de
     `NNN-slug` → `dev` → `test` → `master`. Elle fonctionne **aujourd'hui**, sans dépôt distant, et
     reste vraie dans le régime local de l'Art. 23.
  2. **Protections de branche de la forge** — la même règle exprimée par la plateforme dès qu'une
     forge existe : entrée dans `dev` par demande de fusion aux portes de rang 1 à 3 vertes,
     promotion de `test` aux portes 4 et 5 vertes, aucun commit direct sur `test` ni `master`. Elle
     **ne peut pas être configurée avant ARBITRAGE 1** ; ce plan en fixe l'exigence, pas la syntaxe.

  Les deux couches disent la même chose : la seconde ne remplace pas la première, elle la rend
  opposable à distance (FR-030 — dès qu'un dépôt distant existe, la fusion passe par la forge, jamais
  par une fusion locale).
- **Scope de commit = spec.** La convention de messages n'est pas seulement « conventionnelle » : son
  `scope` DOIT désigner la spec concernée, dans la graphie fixée par `10b` (« Commits :
  conventionnels, scope = spec », `feat(S09): vram fit estimator`). La même porte qui refuse un type
  non conventionnel refuse un message sans `scope` de spec (FR-004). C'est ce qui rend le journal des
  modifications généré exploitable par spec (Art. 13).
- **Les trois chemins à revue humaine** — authentification, facturation, proxy de flux — sont nommés
  par l'Art. 8 comme des **chemins**, pas comme des specs. S03 rend l'exigence **visible et tracée
  dans le processus** et ne fige **aucune liste de specs** : toute spec qui touche l'un de ces chemins
  porte la revue humaine **en plus** des portes mécaniques, chacune au titre du chemin qu'elle
  traverse. `9d` en donne un cas explicite (« revue humaine sur S04 ») et nomme par ailleurs la revue
  humaine des permissions (S13), qui s'ajoute sans être l'un des trois chemins.

## Arbitrages

Les **huit** arbitrages ouverts sont consignés dans [`spec.md`](./spec.md), registre unique, et ne sont
pas dupliqués ici (Art. 19). Ne figurent ci-dessous que ceux qui ont une incidence sur ce plan — les
arbitrages **7** (écart d'effort) et **8** (format des identifiants de tâches) n'en ont aucune : ils
portent sur `tasks.md`, qui en détaille l'incidence.

| Arbitrage | Incidence sur le plan |
| --- | --- |
| **1 — forge et exécuteur de la chaîne** | Le plan nomme `ci.yaml` (`9b`) sans emplacement ni plateforme, et outille la topologie par une garde **locale**. Les protections de branche restent une exigence non configurée. **Le plus urgent** : FR-029 et FR-030 supposent une forge. |
| **2 — `alembic check` : S03 ou S04 ?** | La porte est posée à M0 et s'exécute à vide, sans neutralisation. Si l'arbitrage la reporte à S04, la ligne de dépendance et l'étape correspondante sortent du plan. |
| **3 — chemin du guide du contributeur** | Le plan exige la consigne « couverture nécessaire, non suffisante » **sans fixer de chemin** : `10b` n'en prévoit aucun. À normaliser par amendement de `10b`. |
| **4 — FR-017 et la dépendance à S01** | L'étape de bout en bout et charge consomme la définition d'environnement de S01, alors que `9c` donne S03 « Dépend de : — ». Le plan ne crée pas de seconde définition d'environnement (Art. 19). |
| **5 — amendement de `10a` si les portes deviennent des entités** | Le Constitution Check (Art. 17) est franchi **parce que** portes, seuils et étapes ne sont pas modélisés. Les modéliser exigerait l'amendement d'abord. |
| **6 — `10a` annonce « Constitution (22 articles) »** | Le Constitution Check de ce plan porte **23 lignes**, Art. 23 inclus. Aucun artefact ne recopie le chiffre 22. |

## Complexity Tracking

*Aucune violation de la porte Constitution Check. Section volontairement vide.*
