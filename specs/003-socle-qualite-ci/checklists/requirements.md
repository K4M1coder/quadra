# Specification Quality Checklist: S03 — Socle qualité & CI

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

**Nature particulière de cette spec** — S03 livre de l'outillage : ses « utilisateurs » sont les
contributeurs (développeur humain, agent IA, mainteneur), pas des utilisateurs finaux. Les items
« focused on user value » et « written for non-technical stakeholders » ont donc été évalués par
rapport à ce public. La spec décrit **ce que les portes garantissent** (un refus, un seuil, un
comportement simulé), jamais **quel outil** les implémente.

**Itération de validation 1 — constats et corrections appliquées**

- *No implementation details* : la fiche 9h et la section 9b nomment une trentaine d'outils (ruff,
  mypy, pytest, testcontainers, eslint, prettier, vitest, playwright, openapi-typescript, bandit,
  pip-audit, uv, k6…). **Tous** ont été retirés de la spec et réservés au plan. Ils sont remplacés
  par le contrôle rendu : « portes de formatage et de style », « typage strict », « bases éphémères »,
  « analyse statique », « audit des dépendances », « scénarios de charge ».
- *Requirements testable* : les seuils chiffrés (90 % cœur / 70 % ailleurs) et l'ordre des portes
  sont conservés — ce sont des **contrats normatifs** de la constitution (Art. 8, Art. 10), pas des
  détails d'outil. FR-013 fixe l'ordre, FR-015 les seuils, FR-014 le caractère bloquant.
- *Success criteria technology-agnostic* : SC-001 à SC-008 s'expriment en taux de refus, en seuils,
  en présence/absence d'accès GPU et en destruction de ressources — aucun ne cite un outil.
- *Edge cases* : deux cas non présents dans le document ont été ajoutés parce qu'ils menacent
  directement la validité du socle — le **moteur factice qui diverge du comportement réel** (invalide
  silencieusement toute la pyramide) et le **seuil de couverture atteint par des tests sans
  assertion** (la couverture est nécessaire mais non suffisante, le cycle rouge-vert de l'Art. 10
  reste dû). Ils sont dérivés de la constitution, pas inventés.
- *Scope is clearly bounded* : section « Hors périmètre (Art. 20 — YAGNI) » ajoutée. La frontière la
  plus délicate est avec **S13** (S03 rend possible la génération de tests depuis une source unique,
  S13 fournit `permissions.yaml`) et avec **S21** (S03 rend l'étape de charge exécutable, S21
  versionne les scénarios) — les deux sont explicitées.

**Traçabilité critère → preuve** : A1 → SC-001/SC-005, A2 → SC-002, A3 → SC-003/SC-004, tous prouvés
par la tâche `[TEST]` T10 de la fiche 9h, complétée par T8 (contrôles de sécurité) et T9
(environnement éphémère). La table figure dans la spec.

**Points d'attention pour le plan**

1. FR-002 / SC-005 exigent que les portes locales et distantes exécutent le **même** ensemble de
   contrôles, et que cette équivalence soit **vérifiée automatiquement** — pas seulement affirmée.
   C'est la lecture stricte de l'Art. 14 ; le plan doit dire comment cette comparaison est faite.
2. FR-012 impose une **implémentation unique** du moteur factice, empaquetée pour être consommée par
   toutes les specs. Le plan doit en faire un composant distribuable, pas un fichier de test copié.
3. FR-019 (étiquetage reproductible des images) prépare le retour arrière par ré-étiquetage exigé par
   l'Art. 11 ; à articuler avec S01 qui produit la définition de déploiement.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
