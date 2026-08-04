# Specification Quality Checklist: S09 — Catalogue HF + fit VRAM + confirm-and-warn + fiche modèle

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

- *No implementation details* : la fiche 9n nomme le service (Hugging Face), les formats (AWQ, GPTQ,
  GGUF, EXL), les fonctions (`hf_client`, `vram_fit`, `compat`, `build_warnings`), les routes
  (`/api/catalog?fits=true`, `/api/downloads`), l'algorithme de hachage et la marge chiffrée (8 %).
  Tous réservés au plan. La spec dit « dépôt public de modèles », « format de quantification »,
  « verdict de tenue », « empreinte d'intégrité », « marge de sécurité ».
  **Décision explicite sur la marge** : la valeur de 8 % a été retirée de la spec et déplacée vers le
  plan, parce qu'elle est un **paramètre issu de la calibration**, pas un contrat. L'exigence
  vérifiable est la **concordance 20/20** (SC-001) ; figer 8 % dans la spec empêcherait de corriger la
  marge si la calibration l'exige, ce qui inverserait le rapport entre l'exigence et le moyen.
- *Vocabulaire normatif conservé* : le verdict à trois valeurs (« il tient » / « il tient juste » /
  « il ne tient pas ») et le « confirm-and-warn » sont documentés dans Key Entities avec leurs
  synonymes interdits (compatible, ok, feasible ; popup, are-you-sure).
- *Requirements testable* : A1 devient SC-001 « 20/20 » ; A2 devient SC-002 « zéro téléchargement non
  confirmé + 100 % des confirmations auditées » ; A3 devient SC-003 « les quatre informations, pour
  100 % des modèles ».
- *Ajouts dérivés de la constitution* — six exigences explicitées :
  1. **FR-011 / SC-006** : verdict **indéterminable** quand les métadonnées manquent. Le document ne
     traite pas ce cas ; deviner un verdict coûte un téléchargement de dizaines de gigaoctets.
  2. **FR-012 / SC-008** : recalcul après **changement de topologie**, sinon un cache sert un verdict
     faux.
  3. **FR-004** : servir des métadonnées **périmées en le signalant** plutôt que rendre le catalogue
     inutilisable quand le service distant est indisponible.
  4. **FR-014** : la compatibilité moteur est **indépendante** du verdict mémoire — un modèle peut
     tenir et n'être servi par aucun moteur.
  5. **FR-023** : deux confirmations simultanées n'engagent **qu'une** opération.
  6. **FR-005 / SC-010** : rappel explicite que la consultation du dépôt public est la **seule**
     sortie réseau autorisée (Art. 1) — cette spec est la seule du projet à ouvrir un flux sortant,
     il fallait l'y borner.
- *Edge cases* : ajout des cas « licence exigeant une acceptation préalable » (à traiter dans le
  dialogue, pas en échec tardif), « contexte demandé très supérieur à l'usage » (montrer le point de
  bascule), « il tient juste n'est pas un refus », et « espace disque insuffisant » (à signaler à la
  confirmation, pas après le début du transfert).
- *Scope is clearly bounded* : la frontière décisive est avec **S10** — *S09 décide et fait confirmer,
  S10 télécharge* — et avec **S06** — *S09 prévoit l'éviction dans ses avertissements, S06 l'exécute*.
  Le transfert de la source du verdict de S06 (M1, calcul interne) vers S09 (M2, calibré) est
  documenté dans les Assumptions pour éviter une double implémentation (Art. 19).

**Art. 22 (état de l'art) traité** : la spec consigne ce qui est **imité** (parcours et confirmation
inspirés des gestionnaires de modèles existants ; fiche de transparence inspirée des pratiques de
publication de modèles ouverts) et surtout ce qui est **écarté avec sa raison** — le téléchargement
implicite au premier usage, courant ailleurs, est rejeté comme contraire à l'Art. 3. Les références
nominatives sont renvoyées au plan.

**Traçabilité critère → preuve** : A1 → SC-001/005/006 (T13, T3), A2 → SC-002/009 (T12), A3 → SC-003
(T13). Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-001 ne peut pas être prouvé en intégration continue** : la calibration exige de mesurer
   20 modèles sur du matériel réel. Le plan doit décrire cette campagne comme une activité distincte,
   dont le **résultat** (jeu de cas de référence) alimente ensuite des tests unitaires exécutables
   sans GPU. C'est le risque identifié de la phase 3 et il ne doit pas être masqué.
2. **FR-009 (fonction pure)** est ce qui rend la calibration exploitable : le calcul doit être
   isolable des accès au dépôt et au matériel.
3. **FR-020 / FR-021** : le refus sans confirmation doit être appliqué **côté serveur** (Art. 5), pas
   seulement par l'absence de bouton dans l'interface. Le test T12 doit contourner l'interface.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
