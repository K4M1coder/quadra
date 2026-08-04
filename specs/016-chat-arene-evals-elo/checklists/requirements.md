# Specification Quality Checklist: S16 — Chat multi-utilisateur + arène + classement Elo

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

- *No implementation details* : la fiche 9u nomme la fonction (`update_elo`), la constante (K=32), la
  route (`/v1`), et le mécanisme (fan-out, seed). Réservés au plan. La spec dit « formule de
  référence du projet », « mêmes paramètres d'échantillonnage », « chemin d'inférence commun »,
  « marque distinctive ». Le **facteur de mise à jour** est traité comme un paramètre du plan :
  l'exigence vérifiable est l'**exactitude** du calcul (SC-002), pas une valeur particulière — ce qui
  permet de l'ajuster sans réécrire la spec.
- *Requirements testable* : A1 (deux réponses en parallèle) → SC-001, formulé de façon mesurable
  (« le premier jeton de chacune arrive sans attendre la fin de l'autre ») ; A2 → SC-002, prouvé par
  fichiers de référence conformément à l'Art. 10 ; A3 → SC-003.
- *Ajouts dérivés de la constitution et du bon sens statistique* — six exigences explicitées :
  1. **FR-011 / SC-004** : une comparaison dont **un modèle échoue** ne produit aucun vote. Le
     document ne traite pas ce cas ; sans cette règle, le classement mesurerait la **disponibilité**
     et non la qualité — il deviendrait trompeur pour la décision d'adoption qu'il sert. C'est
     l'ajout le plus important de cette spec.
  2. **FR-016 / SC-010** : afficher le **nombre de votes** fondant chaque rang. Un rang établi sur
     deux votes lu comme un verdict conduit à une mauvaise décision.
  3. **FR-012 / SC-008** : un **seul vote** par comparaison.
  4. **FR-017** : le classement reste valide sans que **toutes les paires** aient été comparées.
  5. **FR-018** : un modèle retiré du catalogue **conserve** son historique.
  6. **FR-004** : signaler l'approche de la limite de contexte **avant** l'échec.
- *Application vérifiable de l'Art. 19* : la consigne « le chat passe par /v1 comme tout client »
  devient FR-007 + **SC-007**, contrôlé par inspection. C'est ce qui garantit que les échanges du
  chat sont comptabilisés par S08 et tracés par S14 comme n'importe quel appel — un chemin
  privilégié les rendrait invisibles à la comptabilité.
- *Edge cases* : ajout des cas « vote absent », « modèle retiré après classement », « paires jamais
  comparées », « conversation très longue ».
- *Scope is clearly bounded* : deux exclusions notables — le **playground** (S17, usage distinct) et
  surtout l'**évaluation automatisée par jeux de tests**, explicitement hors périmètre : le classement
  de cette spec repose **exclusivement sur des votes humains réels**. C'est le choix du document et il
  borne nettement la feature (Art. 20).

**Traçabilité critère → preuve** : A1 → SC-001/004 (T8), A2 → SC-002/008/010 (T9), A3 → SC-003 (T9),
plus le parcours complet vote → classement (T10). Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-001 doit mesurer le parallélisme**, pas seulement constater que les deux réponses arrivent :
   un test séquentiel qui aboutit passerait à tort. Le critère porte sur l'arrivée du **premier
   jeton** de chaque réponse.
2. **FR-015 (fonction pure de classement)** est ce qui rend possible la preuve par fichiers de
   référence exigée par l'Art. 10. Le calcul ne doit pas dépendre d'un accès aux données.
3. **FR-010 (mêmes paramètres d'échantillonnage)** doit être vérifié sur les requêtes réellement
   émises, pas seulement sur ce que l'interface envoie — sinon la comparaison perd sa validité sans
   que personne le voie.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
