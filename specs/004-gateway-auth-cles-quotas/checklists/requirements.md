# Specification Quality Checklist: S04 — Gateway /v1 + auth clés + quotas

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

- *No implementation details* : la fiche 9i nomme des composants (argon2, Redis, httpx, FastAPI,
  Postgres, alembic) et des codes HTTP littéraux (401/402/429/503). Les **produits** ont été
  entièrement réservés au plan (« empreinte irréversible », « magasin rapide », « fenêtre
  glissante »). Les **codes HTTP littéraux** ont été remplacés par leur **code canonique** du
  glossaire normatif (10d) — `RATE_LIMITED`, `OVER_BUDGET`, `QUOTA_CONCURRENCY`, `KEY_REVOKED`,
  `KEY_SUSPENDED`, `MODEL_NOT_RESIDENT`, `CONTEXT_WONT_FIT` — désignés dans la spec par leur sens
  (« code canonique de limitation de débit »). Les valeurs numériques exactes appartiennent au
  contrat figé en T9 et au plan.
- *Compatibilité comme exigence, pas comme technologie* : FR-021/FR-022 et SC-001 parlent de
  « contrat d'inférence standard de l'industrie » et de « client standard non modifié » plutôt que de
  nommer un fournisseur. C'est **la** valeur produit de la spec et elle reste vérifiable
  mécaniquement (T14 exécute de vrais clients).
- *Requirements testable* : les valeurs chiffrées normatives ont toutes été conservées et rendues
  vérifiables — cache 60 s (FR-010 → SC-006), délai de grâce 24 h (FR-006), seuils 80/90/100 %
  (FR-017), cap à ±0 (FR-012 → SC-005), héritage « plafond le plus bas » (FR-016 → SC-007).
- *Edge cases* : quatre cas absents du document ont été ajoutés car ils déterminent la correction du
  cœur — **indisponibilité du magasin de comptage** (FR-019 : refuser plutôt que servir sans limite,
  déduit des Art. 2 et 5), **course entre deux requêtes simultanées** sur le cap (SC-005 exige ±0),
  **révocation pendant une requête en vol**, et **déconnexion avant le premier jeton**. Ils sont
  dérivés de la constitution et des machines à états, pas inventés.
- *Scope is clearly bounded* : la section « Hors périmètre » est particulièrement développée sur
  cette spec, parce que S04 est le point de passage de tout le système et attire naturellement le
  périmètre de S05 (lanes), S06/S07 (moteurs), S08 (comptabilité) et S13 (permissions). La frontière
  retenue est celle de l'Art. 18 : **S04 s'adresse à un routeur, il ne connaît pas les moteurs**.

**Distinction de vocabulaire vérifiée (Art. 12)** : la spec respecte le glossaire normatif — « cap »
est réservé à la concurrence, « budget » désigne un plafond de dépense en monnaie, « quota » un
plafond de débit, « lane » n'est jamais remplacé par « priorité ». FR-014 impose d'ailleurs des codes
**distincts** pour le dépassement de débit et le dépassement de concurrence, ce que la confusion de
vocabulaire aurait masqué.

**Traçabilité critère → preuve** : A1 → SC-001/009/010 (T14), A2 → SC-002/005/007 (T15), A3 →
SC-003/008 (T16). Table complète dans la spec.

**Revue humaine obligatoire** : cette spec porte **deux** des trois chemins non délégables de
l'Art. 8 — l'**authentification** (T3–T5) et le **proxy de flux** (T10–T11). Le plan doit matérialiser
ces revues comme des portes explicites, pas comme une recommandation.

**Points d'attention pour le plan**

1. FR-024 (relais sans mise en tampon) et FR-025 (propagation de l'annulation) sont le risque
   technique identifié de la phase 2. Le plan doit prouver l'absence de tampon **mesurée**, pas
   supposée (SC-008 compare la latence côté client à celle côté moteur).
2. FR-013 exige un délai d'attente **exact**, pas indicatif : c'est ce qui évite les rafales de
   reprise synchronisées entre agents. La fenêtre glissante doit pouvoir répondre « dans combien de
   temps », pas seulement « non ».
3. FR-020 impose que le contrat soit figé **avant** le code, par un humain (T9). Le plan ne doit pas
   ordonner cette tâche après les tâches d'implémentation.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
