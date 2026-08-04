# Specification Quality Checklist: S05 — Scheduler lanes P0/P1/P2 + caps

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

- *No implementation details* : la fiche 9j nomme une structure de données concrète
  (`asyncio.PriorityQueue`) et des fonctions (`lane_for`, `dispatch`, `cancel`). Toutes ont été
  réservées au plan. La spec exprime le **comportement** : préséance stricte (FR-006), préemption
  (FR-007), cession (FR-009), annulation en file et en vol (FR-011).
- *Vocabulaire normatif conservé* : « lane » et « cap » sont maintenus tels quels et documentés dans
  Key Entities avec leurs **synonymes interdits** (priorité / queue class / tier pour lane ; cap
  réservé à la concurrence). C'est une exigence de l'Art. 12, pas un détail d'implémentation.
- *Requirements testable* : le seuil du critère A1 (200 ms au 95ᵉ centile) est repris tel quel dans
  SC-001 ; le « ±0 » du critère A2 devient FR-008 + SC-002 avec la mention explicite du cas simultané.
- *Ajout dérivé de la constitution — FR-010 / SC-004* : le document exige la préséance de P0 mais ne
  dit pas explicitement que P2 doit **progresser malgré tout**. Sans cette exigence, une lecture
  littérale de « P0 préempte tout » autorise la famine permanente du batch — ce qui contredirait la
  raison d'être annoncée de la spec (« personne n'affame personne ») et casserait S18. L'exigence a
  donc été rendue explicite et mesurable (débit batch strictement positif sur fenêtre longue).
  **À valider par le mainteneur** : c'est la seule interprétation ajoutée par cette spec.
- *Ajout dérivé — FR-013 / SC-008* : la consigne du document « le scheduler ne connaît pas les
  moteurs » a été transformée en exigence **vérifiable mécaniquement** (contrôle automatisé des
  dépendances du module), plutôt que laissée à l'appréciation de la revue. C'est l'application de
  l'Art. 18.
- *Edge cases* : ajout du cas « traitement batch très long » (la granularité de cession détermine le
  respect de SC-001 — c'est le piège d'implémentation principal), du cas « annulation exactement au
  moment de l'ordonnancement » (compteur de concurrence faussé), et du cas « clé demandant une lane
  non autorisée » (Art. 5).

**Traçabilité critère → preuve** : A1 → SC-001/SC-004 (T11), A2 → SC-002 (T12), A3 → SC-003 (T12).
Table complète dans la spec, enrichie des preuves pour l'annulation, l'admission, la journalisation
et le découplage.

**Points d'attention pour le plan**

1. FR-009 (granularité de cession) est le point technique décisif : c'est lui qui fait tenir ou
   échouer SC-001. Le plan doit dire à quelle fréquence la lane batch cède, et le test T11 doit
   mesurer l'attente interactive **pendant** un traitement batch long, pas seulement pendant une
   rafale courte.
2. FR-008 (cap à ±0) exige un comptage exempt de condition de course. Le test T12 doit inclure des
   arrivées **simultanées** de la même clé, pas séquentielles.
3. FR-014 impose la diffusion poussée et interdit l'interrogation répétée : à vérifier côté client
   dans les tests de S11, pas seulement côté serveur.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis
— la seule zone d'interprétation (progression garantie du batch) a été tranchée explicitement et
signalée ci-dessus plutôt que laissée en suspens.
