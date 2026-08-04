# Specification Quality Checklist: S06 — Superviseur moteurs + nœuds GPU + hot-swap

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

- *No implementation details* : la fiche 9k nomme des technologies (NVML, API Docker, NVLink) et des
  fonctions (`detect_gpus`, `spawn_engine`, `evict_idle`, `place_model`, `drain_node`). Toutes ont
  été réservées au plan. La spec parle de « découverte du matériel », « appairage haut débit »,
  « pilotage du cycle de vie ». **NVLink** en particulier est un nom de produit : il devient
  « appairage haut débit entre cartes », ce qui garde l'exigence (A1) sans figer la technologie.
- *Vocabulaire normatif conservé* : node, hot-swap, éviction, drain, pinned (épinglé), instance,
  alias sont maintenus et documentés dans Key Entities avec leurs synonymes interdits (Art. 12). La
  distinction **drain** (arrêt gracieux) / **stop** (kill) est respectée partout — FR-016 emploie
  bien « drainer », jamais « arrêter ».
- *Requirements testable* : les valeurs normatives sont reprises et rendues mesurables — 1 à 4 cartes
  par nœud (FR-004), 120 s de hot-swap (FR-015 → SC-002), 3 tentatives de santé (FR-017 → SC-008),
  épinglage inviolable (FR-013 → SC-004).
- *Ajouts dérivés de la constitution* — trois exigences ont été explicitées parce que le document les
  implique sans les écrire :
  1. **FR-014** : que faire si toutes les instances candidates sont épinglées. Le document dit
     « jamais les pinned » sans dire l'issue ; la seule conforme à l'Art. 3 est le **refus explicite**,
     pas le contournement.
  2. **FR-019 / SC-008** : un moteur défaillant doit **rendre** sa ressource. Sans cela, trois échecs
     de santé laisseraient un nœud occupé indéfiniment.
  3. **FR-020 / SC-010** : la consigne « le superviseur est le seul à parler à Docker » devient une
     exigence **vérifiable mécaniquement** (inspection automatisée), plutôt qu'une règle de revue
     (Art. 18).
- *Edge cases* : ajout des cas « deux chargements concurrents » (risque de double éviction ou
  d'interblocage), « drainage qui n'aboutit jamais » (délai maximal nécessaire, sinon le nœud reste
  bloqué), et « redémarrage pendant un chargement » (instance fantôme comptabilisée comme résidente —
  c'est le piège de persistance principal, couvert par SC-007).
- *Scope is clearly bounded* : la frontière la plus délicate est avec **S09** (verdict de tenue
  mémoire). Le partage retenu et documenté : **S06 consomme un verdict, S09 le produit et le
  calibre** ; à M1 un calcul interne suffit, remplacé à M2 sans changement de contrat. La frontière
  avec **S07** (drivers) et **S19** (multi-machines) est également explicitée.

**Traçabilité critère → preuve** : A1 → SC-001, A2 → SC-002/SC-008, A3 → SC-003, tous prouvés par la
tâche `[TEST]` T13, complétée par T12 `[INT]`. Table complète dans la spec, enrichie des preuves pour
l'épinglage, la validation de nœud, la persistance, l'audit et l'autorité exclusive.

**Points d'attention pour le plan**

1. **SC-001 ne peut pas être prouvé contre le moteur factice** : la découverte de topologie exige du
   matériel réel. C'est la seule exigence de cette spec qui échappe à l'intégration continue et qui
   doit être vérifiée au canari. Le plan doit le dire explicitement plutôt que de laisser croire que
   T13 tourne intégralement en CI.
2. **FR-015 (120 s)** doit mesurer le **hot-swap complet** — libération, démarrage, santé, reprise —
   pas seulement le démarrage du moteur. Le plan doit fixer où démarre et où s'arrête le chronomètre.
3. **FR-008 / SC-007** : la persistance doit distinguer l'état *souhaité* de l'état *observé*, sinon
   un redémarrage pendant un chargement produit une instance fantôme.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
