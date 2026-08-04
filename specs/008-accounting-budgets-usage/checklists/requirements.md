# Specification Quality Checklist: S08 — Accounting + budgets + usage

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-01
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

**Itération de validation 1 — constats et corrections appliquées**

- *No implementation details* : la fiche 9m nomme des produits et des fonctions (Postgres, Redis,
  CSV, `meter_request`, `compute_cost`, `budget_ratio`, partitionnement, `INSERT`). Tous réservés au
  plan. La spec parle de « registre », « ligne d'usage », « organisation par période mensuelle »,
  « format tabulaire », « hors du chemin critique ». Le code HTTP `402` devient « code canonique de
  dépassement de budget ».
- *Vocabulaire normatif conservé* : « budget » est défini dans Key Entities avec ses synonymes
  interdits — « limite » (ambigu) et « cap » (réservé à la concurrence). La distinction
  budget (€) / quota (débit) est respectée partout, et la frontière S08 (calcule) / S04 (refuse) est
  posée explicitement dans les Assumptions.
- *Requirements testable* : « ±0 » du critère A1 a été **interprété et écrit** comme « exact au
  centime, comparé à un résultat de référence indépendant » (FR-007 → SC-001), et complété par
  SC-004 sur l'absence de dérive d'arrondi en agrégation — sans quoi « ±0 » sur une requête isolée
  peut coexister avec une dérive de plusieurs euros sur un mois.
- *Ajouts dérivés de la constitution* — cinq exigences explicitées, chacune motivée :
  1. **FR-003 / SC-006** : détecter l'**échec d'enregistrement**. Le document place l'écriture hors
     du chemin critique sans dire ce qui se passe si elle échoue ; une requête servie non
     comptabilisée viole l'Art. 4 et fausse la facturation.
  2. **FR-008 / SC-004** : règle d'arrondi explicite et non dérivante.
  3. **FR-010 / SC-007** : absence de recalcul rétroactif lors d'un changement de tarif.
  4. **FR-011** : un modèle **sans tarif** doit être signalé, jamais compté à zéro — un coût nul
     silencieux masque une consommation réelle.
  5. **FR-012** : règle explicite pour les requêtes **échouées ou annulées**. Sans elle, l'annulation
     devient un moyen d'échapper au comptage.
  6. **FR-019** : un seuil ne notifie **qu'une fois**, y compris sur terminaisons simultanées.
- *Edge cases* : ajout des cas « tarif modifié en cours de mois », « dépassement largement au-delà de
  100 % » (ne doit pas être tronqué), « export pendant l'arrivée de nouvelles requêtes », et
  « partition ancienne détachée » (un export doit le dire plutôt que retourner un vide silencieux).
- *Scope is clearly bounded* : la frontière la plus importante est avec **S04** — elle est énoncée
  deux fois (Hors périmètre et Assumptions) car c'est la confusion la plus probable : *S08 calcule et
  alimente, S04 applique*. Il est aussi précisé que le produit fait de la **refacturation interne**,
  pas de la facturation externe — ce qui borne définitivement le périmètre.

**Traçabilité critère → preuve** : A1 → SC-001/004/007 (T11, revue humaine), A2 → SC-002/008 (T12),
A3 → SC-003/010 (T12). Table complète dans la spec.

**Revue humaine obligatoire** : cette spec porte le troisième des chemins non délégables de l'Art. 8
— la **facturation** (T4, calcul de coût). Avec S04 (authentification, proxy de flux), les trois
chemins à revue humaine du projet sont désormais tous couverts par une spec écrite.

**Points d'attention pour le plan**

1. SC-005 (latence inchangée) doit être **mesuré**, pas supposé : le plan doit prévoir une comparaison
   de latence avec et sans enregistrement, sinon « hors du chemin critique » reste une intention.
2. FR-009 (fonction de calcul pure) est ce qui rend possible la preuve par fichiers de référence
   (T11) et la couverture ≥ 90 %. Le plan ne doit pas laisser le calcul dépendre d'un accès aux
   données.
3. FR-025 (export au fil de l'eau) et SC-010 (plusieurs millions de lignes) imposent de ne pas
   matérialiser l'export en mémoire — contrainte à fixer dès la conception de l'interface d'export.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
