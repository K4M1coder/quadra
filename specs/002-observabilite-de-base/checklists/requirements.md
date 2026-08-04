# Specification Quality Checklist: S02 — Observabilité de base

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

- *No implementation details* : la fiche 9g nomme les produits (Prometheus, DCGM, Grafana,
  Alertmanager) et leurs fichiers (`prometheus.yml`, `alertmanager.yml`, `deploy/grafana/`). Ce sont
  des **identifiants normatifs du document**, employés **tels quels** dans la spec comme dans le plan
  (Art. 12) : `Dashboard`, `ds-<domaine>.json`, `/targets`, `up`, `key_id`, `promdata`, `quadra-net`,
  `firing`. Les paraphraser (« chaîne de collecte », « outil de visualisation ») créerait deux mots
  pour une même chose — c'est précisément ce que l'Art. 12 interdit. Ce que la spec ne fait pas, en
  revanche, c'est décider des versions, des digests et de l'arborescence : cela reste au plan.
- *Convention de nommage conservée dans la spec* : FR-008 (`quadra_<entité>_<mesure>_<unité>`) et
  FR-010 (libellés à cardinalité bornée) **ne sont pas** des détails d'implémentation mais des
  **contrats normatifs** imposés par les Art. 12 (langage ubiquitaire) et 19 (source unique). Les noms
  de métriques individuels (`quadra_requests_total`…) sont en revanche laissés aux specs qui les
  émettent (S04, S05, S08).
- *Requirements testable* : FR-003 (cadences 1 s / 5 s) et FR-005 (90 jours) ont été chiffrés depuis
  le document (`5b`, `5c`) plutôt que laissés qualitatifs ; SC-003 les rend vérifiables par un test à
  89 j / 91 j. FR-001 nomme les jobs d'après la topologie `5b` (`node-A` sglang GPU 0+1 · `node-B`
  sglang GPU 2 · `node-C` llama.cpp GPU 3), les noms `vllm-*` de `6e` étant un état antérieur.
- *Scope is clearly bounded* : section « Hors périmètre (Art. 20 — YAGNI) » ajoutée. Le partage de
  responsabilité avec S15 (hub, règles, heatmap) est explicite — c'est le risque de confusion
  principal sur cette spec, S02 et S15 touchant tous deux à l'observabilité.

**Traçabilité critère → preuve** : A1 → SC-001/SC-004, A2 → SC-002/SC-005, A3 → SC-003, tous prouvés
par la tâche `[TEST]` T8 de la fiche 9g, complétée par T7 `[INT]` pour le scrape du `gateway` issu de
S01. La table figure dans la spec.

**Itération de validation 2 — SC-006 retiré**

- Le critère SC-006 portait un **contrôle automatisé des libellés** que `9g` ne demande pas : sa table
  dit « Critères → preuves : A1–A3 → T8 », et « labels = ids, jamais de PII » y est une **consigne**.
  Le numéro est retiré et non réattribué.
- Conséquence : *All functional requirements have clear acceptance criteria* reste vrai — FR-010 est
  une règle de nommage normative, portée par la liste blanche `10b` et tenue à M0 par la convention et
  la revue (Art. 16). À M0 **aucun composant n'émet** `lane`, `alias`, `node`, `host` ou `key_id` :
  ces familles arrivent avec S04, S05 et S08 (M1–M2, `9c`).
- La porte mécanique correspondante est **rattachée à S03 ou S04** — arbitrage consigné dans le plan.
  L'écrire dans S02 serait du code avant le jalon qui l'exige (Art. 20).

**Point d'attention pour le plan** : la consigne « aucun `Dashboard` créé à la main » (FR-012) implique
que le provisionnement **réapplique** les définitions au démarrage et n'est pas un simple import
initial — c'est la différence entre respecter l'Art. 19 et le contourner. Vérifié : le plan le pose en
D-S02-1 et le fait prouver par le scénario 4 du `quickstart.md`.

**Résultat** : tous les items passent. `/speckit-clarify` non requis.
