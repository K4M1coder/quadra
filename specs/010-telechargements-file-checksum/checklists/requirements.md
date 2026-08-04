# Specification Quality Checklist: S10 — Téléchargements : file, reprise, intégrité, quarantaine

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

- *No implementation details* : la fiche 9o nomme l'algorithme (SHA-256), le service (Hugging Face),
  la fonction (`verify_checksum`), la structure (`manifest`) et la valeur de plafond (40 MB/s). Tous
  réservés au plan. La spec dit « empreinte d'intégrité », « dépôt public », « liste de fichiers et
  d'empreintes publiée », « plafond de débit configurable ».
  **Décision sur le plafond** : les 40 MB/s sont retirés de la spec au profit de « plafond
  configurable respecté » (FR-010 → SC-003). Le document présente cette valeur comme une
  caractéristique du déploiement de référence (5b), pas comme un contrat produit ; la figer dans la
  spec empêcherait de l'adapter à un lien différent. La valeur de référence est rappelée dans les
  Assumptions et fixée dans le plan.
- *Vocabulaire normatif conservé* : « quarantaine » est défini dans Key Entities avec ses synonymes
  interdits (blacklist, blocked). La machine à états est reprise **telle quelle** depuis 10d
  (FR-002), y compris la transition bidirectionnelle téléchargement ⇄ pause.
- *Requirements testable* : A1 devient SC-001, formulé de façon mesurable (« volume retransféré ≤
  volume restant, zéro fragment vérifié retéléchargé ») plutôt que par la formule qualitative du
  document.
- *Ajouts dérivés de la constitution* — six exigences explicitées :
  1. **FR-012** : que faire si le disque se remplit **pendant** le transfert. Le document ne vérifie
     l'espace qu'**avant** ; sans FR-012, le cas produit un fichier tronqué.
  2. **FR-015** : un contenu **non vérifiable** (aucune empreinte publiée) n'est pas enregistré.
     L'Art. 4 interdit d'accepter ce qu'on ne peut pas prouver.
  3. **FR-016** : une empreinte **différente de celle annoncée à la confirmation** met en quarantaine.
     C'est l'Art. 3 : ce qui a été confirmé engage — accepter un contenu différent viderait la
     confirmation de son sens.
  4. **FR-009** : un fragment corrompu **sur disque** est retransféré isolément, sans faire échouer
     l'ensemble.
  5. **FR-017 / SC-010** : la quarantaine n'est **contournable par aucun chemin**, y compris hors
     interface (Art. 5).
  6. **FR-006 / SC-009** : une demande en double n'engage pas un second transfert.
- *Edge cases* : ajout des cas « redémarrage pendant la vérification » (la vérification partielle n'a
  pas de valeur, on recommence), « téléchargement en pause indéfiniment » (l'espace occupé doit être
  visible pour être arbitrable), et « fichier distant modifié depuis la confirmation ».
- *Scope is clearly bounded* : la frontière avec **S09** est posée en une phrase — *S10 démarre à
  partir d'un téléchargement déjà confirmé* — et répétée dans les Assumptions, car c'est la
  duplication la plus probable (rejouer le verdict ou la confirmation violerait l'Art. 19). La
  frontière avec **S13** est également précisée : S10 **émet** des entrées d'audit, S13 en garantit
  l'infalsifiabilité.

**Traçabilité critère → preuve** : A1 → SC-001/004 (T9), A2 → SC-002/006/010 (T9), A3 → SC-003 (T9).
Table complète dans la spec, enrichie des preuves pour l'espace disque, la diffusion de progression
et l'enregistrement au registre.

**Points d'attention pour le plan**

1. **SC-001 exige de mesurer le volume retransféré**, pas seulement de constater que le
   téléchargement aboutit. Un test qui vérifie uniquement le succès final passerait alors même que
   tout aurait été retéléchargé — c'est le piège principal de cette spec.
2. **FR-003 / SC-004** : la persistance doit couvrir **chaque** état, y compris « en vérification ».
   Le plan doit décrire ce qui est écrit sur disque et quand.
3. **FR-010 / SC-003** : le plafond doit être mesuré **sur la durée**, pas instantanément — un
   plafond respecté en moyenne mais violé par rafales saturerait quand même le lien.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
