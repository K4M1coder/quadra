# Specification Quality Checklist: S01 — Socle compose + moteurs + Caddy

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-01 · **Revalidée**: 2026-08-04 (amendement FR-019 → FR-021, SC-008 → SC-010)
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

### Itération de validation 1 — constats et corrections appliquées

- *No implementation details* : la fiche 9f du document nomme des produits concrets (compose, Caddy,
  SGLang, llama.cpp, Postgres, Redis, Prometheus, Grafana, DCGM). Ces noms ont été **déplacés vers le
  plan** (section « Plan d'intégration » de la fiche = `plan.md`) et remplacés dans la spec par leur
  rôle fonctionnel (« reverse proxy », « moteur d'inférence », « base relationnelle », « cache »,
  « chaîne d'observabilité »). La spec reste ainsi vérifiable sans présupposer l'outil, conformément
  à l'Art. 6 (les briques sont remplaçables derrière un contrat).
- *Success criteria technology-agnostic* : SC-001 à SC-007 sont exprimés en délais, en ports
  joignables, en pourcentages et en absence d'intervention — aucun ne cite un produit. Le seul
  élément technique conservé est le **port 443**, qui est une exigence d'exposition réseau contractée
  par le document (critère A2), pas un détail d'implémentation.
- *Scope is clearly bounded* : une section « Hors périmètre (Art. 20 — YAGNI) » a été ajoutée,
  renvoyant explicitement chaque exclusion vers la spec qui la porte (S02–S21).

**Traçabilité critère → preuve** : les trois critères d'acceptation du document (A1, A2, A3) sont
couverts par SC-001/005/007, SC-002 et SC-003, tous prouvés par la tâche `[TEST]` T10 de la fiche 9f
(machine vierge → pile verte, vérification des ports, vérification des digests). La table de
correspondance figure dans la spec, section « Traçabilité critère → preuve ».

**Écart assumé sur les entités** : S01 ne crée aucune entité du domaine métier. La section
« Key Entities » a été conservée pour décrire les objets de déploiement (service, volume nommé, route
publiée, variable d'environnement), rattachés à l'arbre d'exécution de la taxonomie (10a) — utile au
plan, sans introduire de concept absent de la taxonomie (Art. 17).

**Résultat de l'itération 1** : tous les items passent. Spec prête pour `/speckit-plan`.
`/speckit-clarify` n'est pas requis — le document de référence fige les trois critères d'acceptation et
le périmètre, et aucun marqueur [NEEDS CLARIFICATION] n'a été nécessaire.

### Itération de validation 2 — après amendement (FR-019 → FR-021, SC-008 → SC-010)

Trois exigences et trois critères de succès ont été ajoutés à `spec.md` : les **fichiers de gouvernance
à la racine** (FR-019, FR-020 → SC-008, SC-009) et le **retour arrière en une commande** (FR-021 →
SC-010). Les identifiants existants n'ont **pas** été renumérotés : les artefacts dépendants les
référencent par identifiant (Art. 19). Constats de revalidation :

- *Requirements are testable and unambiguous* : les trois nouvelles exigences le sont chacune par une
  vérification mécanique — comparaison de versions entre `CONSTITUTION.md` et sa source, présence d'une
  entrée de changelog, dénombrement des commandes et des fichiers modifiés lors d'un retour arrière.
- *Success criteria are measurable* : SC-008 est binaire (identique / divergent), SC-009 binaire
  (entrée présente), SC-010 quantifié (**une** commande, **zéro** reconstruction, **zéro** autre
  fichier modifié).
- *All functional requirements have clear acceptance criteria* : FR-019 et FR-020 sont couverts par
  l'acceptation US1 nº 1 ; FR-021 par le cas limite « une image épinglée se révèle défaillante après
  bascule ». Les deux tâches `[TEST]` correspondantes **manquent à la fiche `9f`** et sont signalées
  comme écart documentaire dans la table de traçabilité de la spec, plutôt que passées sous silence
  (Art. 7).
- *Aucun seuil non sourcé ne subsiste* : l'ancien SC-006 portait un **seuil quantitatif** sur l'échec
  de validation qu'**aucune source ne borne** — ni la fiche `9f`, ni `10b`, ni la constitution. Ce seuil
  a été **retiré** ; le critère est désormais qualitatif et reste vérifiable. Le retrait a été propagé
  aux artefacts de conception qui reprenaient ce seuil (`research.md`, `contracts/routes.md`,
  `data-model.md`, `quickstart.md`).

### Écart assumé — identifiants normatifs dans la spec

L'item *No implementation details* reste coché, avec une réserve explicite : `spec.md` nomme désormais
`CONSTITUTION.md`, `CHANGELOG.md`, `.env.example`, `quadra-net`, `pgdata`, `promdata`, `/data/models`,
`/data/offload`, le préfixe `QUADRA_`, les routes `/v1` `/api` `/ws` `/grafana` et le port 443. Ce ne
sont **pas des choix d'implémentation** : ce sont des **identifiants normatifs** fixés par `10b`, `5b`
et le § Governance de la constitution, que l'Art. 12 impose d'employer **tels quels** — les paraphraser
créerait deux mots pour une même chose. Aucun produit, aucune bibliothèque, aucun langage n'est nommé
dans la spec ; les noms de produits restent confinés au plan.

SC-008 cite `.specify/memory/constitution.md`. C'est un chemin de fichier, donc à la limite de l'item
*Success criteria are technology-agnostic* — assumé : ce fichier **est** la source de vérité que
l'Art. 19 désigne, et un critère qui parlerait de « la source de la constitution » sans la nommer
serait invérifiable.

**Résultat** : tous les items passent, avec les deux réserves ci-dessus consignées. Aucun marqueur
[NEEDS CLARIFICATION] n'a été introduit ; les points non décidables sont en section « Arbitrages
ouverts » de `spec.md` et n'engagent aucun critère.
