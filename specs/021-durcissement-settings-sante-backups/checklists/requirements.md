# Specification Quality Checklist: S21 — Durcissement : réglages, santé, sauvegardes, charge

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

- *No implementation details* : la fiche 9z nomme les outils (`pg_dump`, `rsync`, NAS, k6, cron,
  DCGM), les routes (`/api/settings`, `/api/health`) et l'horaire (03:00). Réservés au plan. La spec
  dit « sauvegarde périodique », « copie hors machine », « scénarios de charge », « état de santé
  agrégé ». L'horaire et la cadence exacte relèvent de la configuration ; l'exigence testable est
  l'existence d'une sauvegarde **récente** (FR-009).
- *Requirements testable* : A1 → SC-001, formulé pour exiger « en suivant **uniquement** la procédure
  documentée » et « rejoué au moins une fois par trimestre » — les deux moitiés du critère (testée
  **et** documentée) ; A2 → SC-002 ; A3 → SC-003, avec le détail de ce que l'entrée d'audit doit
  porter.
- **Renforcement du critère A1** : le document affirme « une sauvegarde non testée en restauration
  n'est pas une sauvegarde ». La spec en fait une **exigence stricte** (FR-014) : la vérification
  porte sur le **contenu restauré**, pas sur la réussite de la copie. La distinction est décisive —
  une copie réussie d'une base corrompue passe tous les contrôles de copie et ne restaure rien.
- *Ajouts dérivés de la constitution* — six exigences explicitées :
  1. **FR-023** : les scénarios de charge s'exécutent sur un **environnement dédié**. Les rejouer en
     production dégraderait précisément ce qu'ils mesurent, et violerait l'Art. 2.
  2. **FR-016 / SC-007** : une destination pleine ou injoignable **n'écrase pas** une sauvegarde
     valide — mode de défaillance classique où l'on perd la dernière bonne copie.
  3. **FR-005 / SC-011** : le raccourcissement d'une durée de conservation présente son **effet sur
     les données existantes avant validation** (Art. 3) — c'est une purge déguisée.
  4. **FR-007 / SC-005** : l'état agrégé ne peut **jamais** être au vert avec un composant en échec.
  5. **FR-008** : l'**indisponibilité** de la vue de santé doit être distinguable d'un état sain —
     sinon une panne d'observabilité se lit comme « tout va bien ».
  6. **FR-009 / FR-019** : l'absence de sauvegarde récente est un **défaut de santé**, et la date du
     dernier exercice de restauration est **visible** — pour que l'oubli se voie.
- *Edge cases* : ajout des cas « restauration réussie mais données incomplètes », « réglage modifié
  pendant un incident », « modifications simultanées », et « charge exécutée en production ».
- *Scope is clearly bounded* : la règle posée est *S21 fournit le point de réglage, pas le
  comportement réglé* — chaque famille de réglages est renvoyée à la spec qui porte la
  fonctionnalité. De même, la vue de santé est explicitement un **agrégat d'exploitation**, pas une
  seconde chaîne d'observabilité (même contrainte que celle imposée à S15, Art. 19).

**Traçabilité critère → preuve** : A1 → SC-001/006/007 (T6, T5), A2 → SC-002/009 (T9, T7), A3 →
SC-003/010/011 (T9, T2). Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-001 doit partir d'un environnement réellement vierge** et n'utiliser que la procédure écrite.
   Un test de restauration lancé par quelqu'un qui connaît le système ne prouve pas que la procédure
   est suffisante — c'est le piège de ce critère.
2. **FR-014** : le plan doit dire **comment** le contenu restauré est vérifié (quelles données, quels
   contrôles), sinon « vérifiée » retombe sur « la copie s'est terminée ».
3. **FR-022** : les scénarios de charge de S21 rejouent l'exigence d'anti-famine déjà prouvée par
   S05. Le plan devrait **réutiliser** le dispositif de S05 plutôt qu'en créer un second (Art. 19) —
   la différence étant qu'ici la preuve est rejouée **avant chaque mise en service**, sur la
   plateforme complète.

**Clôture du plan de specs** : S21 est la dernière des 21 specs. Avec elle, l'intégralité du plan
9c du document de référence est couverte, chaque spec portant ses critères d'acceptation d'origine,
sa traçabilité critère → preuve, et son périmètre borné par l'Art. 20.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
