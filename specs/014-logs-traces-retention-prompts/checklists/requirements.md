# Specification Quality Checklist: S14 — Journaux & traces + rétention des prompts

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

- *No implementation details* : la fiche 9s nomme des fonctions (`record_spans`, `purge_expired`), une
  route (`/api/logs`), une technique de pagination (keyset) et un mécanisme d'ordonnancement (cron).
  Réservés au plan. La spec dit « durées par étape », « purge », « pagination stable sous écriture
  continue », « purge quotidienne ». La formulation « stable sous écriture continue » (FR-009 →
  SC-005) conserve l'exigence que la pagination par curseur satisfait, **sans imposer la technique**.
- *Vocabulaire* : le terme « span » du document est rendu par « étape », rattaché aux étapes du cycle
  de vie déjà nommées dans la machine à états normative (attente en file, préremplissage,
  génération) — cohérent avec l'Art. 12.
- *Requirements testable* : A1 (moins d'une seconde) → SC-001 ; A2 (contenu absent) → SC-002,
  renforcé par « vérifié y compris en accédant directement au stockage » — sans quoi le critère
  pourrait être satisfait par une simple omission d'affichage ; A3 (purge vérifiable) → SC-003.
- *Ajouts dérivés de la constitution* — cinq exigences explicitées :
  1. **FR-013 / SC-006** : le choix d'opt-in en vigueur est celui **du moment de la requête**. Le
     document ne traite pas le changement d'option ; sans cette règle, activer l'option ferait
     apparaître rétroactivement des contenus jamais conservés (impossible) ou la désactiver
     supprimerait des contenus avant terme (incohérent).
  2. **FR-015 / SC-007** : l'**échec de purge est signalé**. Une purge silencieusement inopérante
     laisserait des contenus au-delà de leur durée, contredisant l'engagement pris à l'opt-in
     (Art. 3).
  3. **FR-006** : la trace d'une requête **en cours** est consultable — utile pour diagnostiquer une
     requête bloquée, cas non traité par le document.
  4. **FR-011** : un identifiant inexistant produit une réponse **distincte** d'une trace vide.
  5. **FR-010 / SC-009** : le périmètre de visibilité est décidé **côté serveur** (Art. 5).
- *Réutilisation vérifiable* : la consigne « les spans viennent des métriques déjà émises » devient
  FR-005 + **SC-004**, contrôlé par inspection (Art. 19). C'est important : une seconde
  instrumentation produirait des durées divergentes de celles des tableaux de bord, et personne ne
  saurait laquelle croire.
- *Edge cases* : ajout des cas « requête annulée avant ordonnancement » (la trace existe quand même),
  « requête très longue » et « volume très élevé » (stabilité de la pagination).
- *Scope is clearly bounded* : la distinction la plus importante a été explicitée dans les Assumptions
  — **traces de requêtes (S14) et journal d'audit (S13) sont deux journaux distincts**, avec des
  rétentions (30 j / 2 ans) et des exigences (infalsifiabilité) différentes. Les fusionner serait une
  erreur de conception tentante.

**Profondeur de jalon vérifiée (Art. 20)** : le plan de specs impose « S14 ≤ J1 → M3 ». **J1 est dû à
M2**, **J2 (interface) et J3 à M3**. C'est la troisième spec du projet, avec S07 et S11, dont la
profondeur est coupée par un jalon — la coupure est marquée dans chaque sous-titre d'exigences.

**Traçabilité critère → preuve** : A1 → SC-001/008 (T8), A2 → SC-002/006 (T9), A3 → SC-003/007 (T9).
Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-002 doit être vérifié au niveau du stockage**, pas de l'affichage : le test doit confirmer
   qu'aucun contenu n'a **jamais été écrit** pour une clé sans opt-in.
2. **SC-001 (moins d'une seconde)** dépend du fait que l'enregistrement des durées ne soit pas sur le
   chemin critique tout en restant rapidement visible — le plan doit dire comment ces deux exigences
   coexistent, en cohérence avec S08 dont l'écriture est explicitement différée.
3. **FR-005 / SC-004** : le plan doit nommer précisément quelles mesures existantes alimentent
   quelles étapes, sinon la tentation de réinstrumenter sera forte au moment de l'implémentation.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
