# Specification Quality Checklist: S07 — Drivers moteurs gérés / attachés + sélecteur

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

- *No implementation details* : la fiche 9l nomme des produits (SGLang, llama.cpp, vLLM, Ollama,
  TabbyAPI), des formats (AWQ, GPTQ, GGUF, EXL) et des classes (`EngineDriver`, `SGLangDriver`,
  `RemoteDriver`, `engine_for`). Tous ont été réservés au plan. La spec parle de « moteur géré
  principal / secondaire » et de « format de quantification ».
  **Conséquence assumée** : le critère A3 (« AWQ/GPTQ→SGLang, GGUF→llama.cpp ») ne peut pas être
  énoncé littéralement dans la spec sans nommer des produits. Il y est donc exprimé comme
  « la correspondance versionnée attribue le moteur attendu à 100 % des formats référencés »
  (FR-014/FR-016 → SC-003), la table concrète vivant dans le plan — ce qui est **cohérent avec
  l'Art. 19** : la correspondance est une donnée versionnée, source unique de la décision.
- *Vocabulaire normatif conservé* : « géré » et « attaché » sont maintenus avec leurs synonymes
  interdits (embedded, managed/unmanaged, external) dans Key Entities.
- *Requirements testable* : le « zéro changement ailleurs » du critère A1 devient une exigence
  vérifiable par comparaison de dépôt (SC-001) **et** par recherche automatisée de références à un
  moteur nommé (SC-004). Le « < 10 s » du critère A2 est chronométré depuis la **première
  vérification de santé en échec** — le point de départ est précisé, sans quoi le critère est
  inmesurable.
- *Ajouts dérivés de la constitution* — quatre exigences explicitées :
  1. **FR-010 / SC-007** : la santé d'un moteur attaché couvre la **conformité** des réponses, pas
     seulement la joignabilité. Un service qui répond n'importe quoi est aussi nocif qu'un service
     mort, et le document ne le dit pas.
  2. **FR-009 / SC-006** : la **réintégration** automatique d'un moteur redevenu joignable. Le
     document décrit le retrait sans décrire le retour.
  3. **FR-005 / SC-008** : rejet **au démarrage** d'un driver au contrat incomplet, plutôt qu'un échec
     au premier appel.
  4. **FR-023** : l'attachement d'un service **hors de l'infrastructure** violerait l'Art. 1 (les
     données restent sur site). Le document présente l'attachement comme une simple URL ; la
     constitution impose d'en faire une action confirmée et tracée. **Point à valider par le
     mainteneur** — c'est l'interprétation la plus contraignante ajoutée par cette spec.
- *Edge cases* : ajout du cas « service attaché lent sans être injoignable » (sans délai borné, le
  retrait en 10 s est intenable), « correspondance modifiée pendant que des instances tournent »
  (tranché par FR-018 : pas de déplacement rétroactif), et « moteur attaché perdu en cours de
  génération » (pas de réémission d'une génération entamée — cohérent avec le glossaire, où
  « redrive » ne concerne que les requêtes **non entamées**).

**Profondeur de jalon vérifiée (Art. 20)** : la spec marque explicitement la coupure M1/M2 imposée par
le plan de specs — J1–J2 (contrat, drivers, sélecteur) à **M1 sans interface**, J3 (fiches, journaux
en direct, sélecteur visuel) et J4 à **M2**. Chaque groupe d'exigences porte son jalon dans son
sous-titre, pour que `/speckit-plan` et `/speckit-tasks` ne mélangent pas les profondeurs.

**Traçabilité critère → preuve** : A1 → SC-001/004/009 (T11), A2 → SC-002/006/007 (T11), A3 →
SC-003/005 (T5–T6). Table complète dans la spec.

**Points d'attention pour le plan**

1. SC-001 (« zéro modification ailleurs ») se prouve le plus honnêtement en **ajoutant réellement un
   driver factice** dans le test T11 et en comparant le dépôt — pas en le raisonnant.
2. FR-008 exige un chronomètre : le plan doit fixer la **période de vérification de santé** et le
   **nombre d'échecs** tolérés de façon que leur produit reste sous 10 secondes.
3. FR-013 / SC-009 (aucun moteur forké) est vérifiable : le plan doit prévoir un contrôle
   automatisé de l'absence de correctif appliqué au code upstream.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
