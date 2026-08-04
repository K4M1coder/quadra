# Implementation Plan: S03 — Socle qualité & CI

**Branch**: `003-socle-qualite-ci` | **Date**: 2026-08-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-socle-qualite-ci/spec.md`

## Summary

Rendre la **definition of done mécanique** avant la première ligne de code métier : portes locales,
chaîne d'intégration ordonnée, seuils de couverture bloquants, et un **moteur d'inférence factice**
qui permet de tout tester sans GPU.

**Approche technique** : deux versants outillés séparément (plan de contrôle et interface) mais
**un seul ordre de portes** et **un seul jeu de seuils**, définis une fois. Les portes locales et la
chaîne distante exécutent **le même ensemble de contrôles**, et cette équivalence est **vérifiée
automatiquement** plutôt qu'affirmée. Le moteur factice est un **paquet distribuable**, pas un
fichier de test — il sera consommé par S04 à S20.

**Point de vigilance principal** : la couverture. Atteindre 90 % avec des tests qui n'assertent rien
satisferait la lettre de l'Art. 10 en violant son esprit. Le plan traite le seuil comme **nécessaire
mais non suffisant** — le cycle rouge → vert reste dû pour tout comportement.

## Technical Context

**Language/Version** : **Python 3.12** (plan de contrôle) · **TypeScript strict** (interface).
S03 ne livre aucun code métier : elle livre de la **configuration outillée** et **un composant
réutilisable** (le moteur factice).

**Primary Dependencies** — versions retenues épinglées par verrou de dépendances ; aucune n'est
concernée par la décision D1 (qui ne porte que sur l'infrastructure de S01/S02).

| Versant | Rôle | Composant |
| --- | --- | --- |
| Plan de contrôle | lint + format | ruff |
| | typage strict | mypy `--strict` |
| | tests + couverture | pytest · pytest-cov · pytest-asyncio |
| | bases éphémères | testcontainers |
| | cohérence des migrations | contrôle de migrations |
| Interface | lint + format | eslint (flat config) · prettier |
| | tests de composants | vitest · testing-library |
| | bout en bout | playwright |
| | client généré | openapi-typescript |
| Transverse | portes locales | pre-commit |
| | convention de commits | conventional commits |
| | charge | k6 |
| | sécurité | bandit · pip-audit · npm audit |
| Build | verrou reproductible | uv |
| | images | construction multi-étapes, **image du plan de contrôle < 300 Mo** |

**Storage** : aucun stockage propre. Les tests d'intégration démarrent des **bases éphémères**,
créées et détruites par le test lui-même.

**Testing** : S03 **est** l'outillage de test. Sa propre preuve (T10) vérifie qu'une porte refuse un
fichier non conforme, que la chaîne échoue sous les seuils, et que le moteur factice reproduit flux,
latence et erreurs.

**Target Platform** : machines de développement et agents d'intégration continue, **sans GPU**.
C'est une **contrainte d'architecture**, pas une limitation temporaire.

**Performance Goals** : un état vert local doit prédire un état vert distant. Objectif de
non-régression : les portes locales restent assez rapides pour être exécutées à chaque validation.

**Constraints** :

- **La chaîne d'intégration ne touche jamais un GPU** (Art. 8). Les vrais moteurs ne sont exercés
  qu'au canari.
- **Seuils bloquants** : **≥ 90 %** sur le cœur (authentification, quotas, comptabilité),
  **≥ 70 %** ailleurs — mesurés par l'outillage, jamais annoncés.
- **Ordre des portes imposé** : style/format → typage → tests + couverture → sécurité → construction
  d'images → bout en bout.
- **Client d'interface généré**, jamais écrit à la main (Art. 19).
- **Toute la configuration de portes est versionnée** — désactiver une porte doit se voir en revue.

**Scale/Scope** : 2 versants outillés · 6 étapes de chaîne · 9 niveaux de la pyramide de tests
rendus exécutables · 1 moteur factice distribuable · 6 fichiers de configuration versionnés.

### Décisions issues de la veille — **arbitrées**

Référence : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md), §7.

- **D1 et D2 ne concernent pas S03.** Elles portent sur l'infrastructure déployée (S01, S02). S03
  n'épingle que des outils de développement, dont les versions vivent dans les verrous de
  dépendances.
- **Conséquence indirecte de D1** : les **bases éphémères** des tests d'intégration doivent utiliser
  **les mêmes majeures** que celles retenues en production (base relationnelle 18.x, cache 8.x).
  Tester contre une majeure antérieure ferait passer des tests qui échoueraient en production —
  c'est le seul point où D1 touche S03.

## Constitution Check

*GATE : à franchir avant la génération des tâches. Ré-évalué après la conception détaillée.*

| Art. | Exigence | Statut | Comment S03 s'y conforme |
| --- | --- | --- | --- |
| 1 | Données sur site | ➖ | S03 ne manipule aucune donnée d'usage. Les audits de dépendances interrogent des registres publics — flux d'outillage, hors production. |
| 2 | Humain interactif d'abord | ➖ | Aucun ordonnancement. |
| 3 | Consentement explicite | ➖ | Aucune action coûteuse ni irréversible. |
| 4 | Tout est tracé | ✅ | Les sorties d'outillage (couverture, audits) sont **capturées**, pas annoncées — « un chiffre sans sortie capturée est une opinion ». |
| 5 | Le serveur décide | ➖ | Aucune permission. |
| 6 | Réutiliser, ne jamais forker | ✅ | Outils consommés tels quels. Le moteur factice **simule** le contrat d'inférence, il ne forke aucun moteur. |
| 7 | La spec avant le code | ✅ | Spec S03 figée et validée avant ce plan. |
| 8 | Qualité mécanique | ✅ | **Article central.** S03 **est** l'implémentation des 5 portes, dans l'ordre, avec blocage de fusion. Elle rend aussi visibles les 3 chemins à revue humaine. |
| 9 | Simplicité | ✅ | Un seul ordre de portes, un seul jeu de seuils, un seul moteur factice — pas de variante par versant. |
| 10 | Tests d'abord | ✅ | **Article central.** Pyramide complète rendue exécutable ; seuils mesurés par l'outillage. T10 est écrit rouge avant les portes. |
| 11 | Rien ne flotte | ✅ | Verrou de dépendances reproductible ; images étiquetées version + empreinte (FR-019), condition du retour arrière. |
| 12 | Langage ubiquitaire | ✅ | Nommage des tests et des étapes aligné sur le vocabulaire du domaine. |
| 13 | Doc et changelog | ✅ | Convention de commits → journal des modifications généré. |
| 14 | Histoire atomique, hooks = CI | ✅ | **Article central.** FR-002 : portes locales ≡ portes distantes, **vérifié automatiquement** (SC-005). |
| 15 | Boucles bornées | ➖ | Aucune boucle agentique dans l'outillage. |
| 16 | La revue trie | ✅ | Une porte rouge arrête le fil ; la configuration versionnée rend visible toute désactivation. |
| 17 | Le code modèle le domaine | ✅ | Le moteur factice expose le **contrat d'inférence** du domaine, pas une interface inventée. |
| 18 | Modules SOLID | ✅ | Ajouter un niveau de test = ajouter une étape, sans toucher aux autres. |
| 19 | Une connaissance, un endroit | ✅ | **Article central.** Un seul moteur factice (FR-012) ; client d'interface **généré** depuis le contrat ; seuils définis une fois. |
| 20 | YAGNI | ✅ | Aucun test métier ici — seulement l'outillage. La matrice de permissions vient de S13, les scénarios de charge de S21. |
| 21 | Sécurité continue | ✅ | Analyse statique + audits de dépendances + scan de secrets dans les portes ; une vulnérabilité sans correctif se documente, ne se tait pas. |
| 22 | État de l'art | ✅ | Veille consignée ; l'écart de majeures de D1 est répercuté sur les bases éphémères. |

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
pyproject.toml                  # ruff + mypy strict + pytest + couverture (T1, T2)
.pre-commit-config.yaml         # Portes locales + convention de commits (T3)
eslint.config.js                # Lint interface (T4)
playwright.config.ts            # Bout en bout (T5)
Makefile                        # lint / test / e2e / build / up (transverse)
uv.lock                         # Verrou reproductible (T1)

.github/workflows/ci.yaml       # Chaîne : lint → types → tests → sécurité → build → e2e (T8, T9)

packages/
└── fake-engine/                # ⚠️ PAQUET DISTRIBUABLE, pas un fichier de test
    ├── pyproject.toml          # publiable et versionné
    └── src/fake_engine/
        ├── server.py           # Contrat d'inférence simulé : complétion, flux (T6)
        ├── control.py          # inject_error() · set_latency() (T7)
        └── embeddings.py       # Représentations vectorielles (T7)

ui/
├── package.json                # eslint · prettier · vitest · playwright (T4, T5)
└── src/api/generated/          # Client GÉNÉRÉ depuis le contrat — jamais édité (Art. 19)

tests/
├── conftest.py                 # Bases éphémères partagées
├── smoke/                      # Fumée bout en bout (T5)
└── tooling/
    ├── test_gates_parity.py    # ⚠️ Portes locales ≡ portes distantes (FR-002, SC-005)
    └── test_fake_engine.py     # Flux, latence, erreurs (T10)
```

**Structure Decision** : le moteur factice vit dans `packages/fake-engine/` avec **son propre
manifeste** — c'est ce qui en fait un composant **installable par les autres specs** plutôt qu'un
fichier copié (FR-012). Le client d'interface généré vit dans un répertoire dédié `generated/`, dont
la convention de nommage signale qu'il ne s'édite pas.

## Ordre de construction

Jalons de la fiche 9h. **`tasks.md` est la source unique du détail des tâches** (Art. 19).

| Jalon | Intention | User story | Tâches |
| --- | --- | --- | --- |
| **J1** Fondations | lint, types et tests configurés des deux côtés | US1 (P1) | voir [`tasks.md`](./tasks.md) |
| **J2** Cœur | un moteur factice simule l'inférence pour tous les tests | US2 (P2) | idem |
| **J3** Chaîne | la chaîne d'intégration rejoue tout, bout en bout compris | US3 (P3) | idem |
| **J4** Preuves | porte qui bloque, chaîne rouge sous seuil, scénarios simulés | — | idem |

**Contraintes d'ordre** : J1 précède tout. **J2 est indépendante de J1** — le moteur factice ne
dépend d'aucune porte et peut être développé en parallèle par un second agent. J3 exige J1 et J2.
J4 exige les trois.

## Consignes d'implémentation

- **Parité locale ↔ distante, vérifiée et non affirmée.** FR-002 et SC-005 exigent que les deux
  ensembles de contrôles soient **identiques**. La façon retenue : **une source unique déclare les
  portes**, la configuration locale et la chaîne distante la consomment toutes deux, et
  `tests/tooling/test_gates_parity.py` **compare les deux listes résolues** et échoue si elles
  divergent. Sans ce test, la parité se dégrade silencieusement au premier ajout de porte.
- **Le moteur factice est un paquet, pas un fichier.** Il porte son propre manifeste, il est
  versionné, et les autres specs l'installent comme dépendance de test. Un fichier copié divergerait
  entre specs et invaliderait toute la pyramide (FR-012).
- **La couverture est nécessaire, pas suffisante.** Le seuil bloque, mais ne prouve pas que les tests
  assertent. Le cycle rouge → vert reste dû pour tout comportement (Art. 10) — à faire respecter en
  revue, la mécanique ne peut pas le vérifier seule. **À dire explicitement dans la documentation de
  contribution.**
- **Bases éphémères aux majeures de production.** Conséquence de D1 : tester contre une majeure
  antérieure ferait passer des tests qui échoueraient en production.
- **Aucun accès GPU dans la chaîne.** Contrainte d'architecture. Le moteur factice existe précisément
  pour cela.
- **Étiquetage reproductible des images** (version + empreinte) — c'est ce qui rend le retour arrière
  possible par ré-étiquetage (Art. 11), en articulation avec S01 qui consomme ces images.
- **Les trois chemins à revue humaine** — authentification, facturation, proxy de flux — sont rendus
  **visibles dans le processus** par S03, mais **déclenchés par les specs concernées** (S04, S08,
  S12). S03 ne décide pas quel changement les traverse.

## Complexity Tracking

*Aucune violation de la porte Constitution Check. Section volontairement vide.*
