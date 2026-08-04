# Specification Quality Checklist: S11 — Coquille d'interface + Overview, Queue, Models + temps réel

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

- *No implementation details* : la fiche 9p est la plus chargée en noms de technologies du plan de
  specs (React, vite, tanstack-query, recharts, openapi-typescript, WebSocket, thème Nocturne,
  tauri). **Tous** réservés au plan. La spec dit « application d'administration », « client d'accès
  généré à partir du contrat », « canal temps réel », « jetons du système de conception ». Le nombre
  « 13 entrées » de la navigation a été remplacé par « la navigation canonique couvrant l'ensemble
  des modules » — le décompte exact est une propriété du catalogue de vues (4a/4b), pas un contrat de
  cette spec, et le figer ici créerait une seconde source de vérité (Art. 19).
- *Requirements testable* : A1 (« 100 % généré ») devient SC-001, vérifiable par inspection
  automatisée ; A2 (« zéro polling ») devient SC-002, vérifiable par observation des appels émis ;
  A3 (« correspond aux prototypes ») devient SC-003, avec une définition explicite de
  « correspondre » — mêmes informations et même structure, **pas** une identité au pixel près, sans
  quoi le critère serait invérifiable.
- *Ajouts dérivés de la constitution* — cinq exigences explicitées :
  1. **FR-014 / edge case** : si le canal temps réel est indisponible, l'application **ne bascule
     pas** sur de l'interrogation répétée. Sans cette précision, un repli « raisonnable » viderait le
     critère A2 de son sens exactement quand il compte.
  2. **FR-008 / SC-004** : **resynchronisation intégrale** après reconnexion. Rejouer les seuls
     événements manqués laisse un état divergent.
  3. **FR-009** : ignorer les événements de type inconnu (client plus ancien que le serveur).
  4. **FR-005 / SC-007** : le masquage de navigation est **cosmétique** ; la protection est serveur
     (Art. 5). Formulé comme exigence testable, avec un cas de contournement direct de l'adresse.
  5. **FR-004 / SC-006** : les libellés emploient les termes du glossaire, vérifiés par contrôle
     automatisé (Art. 12). C'est ce qui empêche « priorité » d'apparaître à l'écran là où le domaine
     dit « lane ».
- *Edge cases* : ajout du cas « débit d'événements élevé » (les statistiques matérielles arrivent à
  haute fréquence : l'affichage doit rester fluide sans retomber sur l'interrogation) et du cas
  « état absent de la machine à états normative » (à signaler comme inconnu, pas à interpréter).
- *Scope is clearly bounded* : S11 attire naturellement tout le périmètre d'interface du produit. La
  section « Hors périmètre » énumère donc explicitement les **autres vues** et les renvoie à leur
  spec, en posant la règle : *S11 fournit la coquille, plus trois vues*. L'enveloppe applicative de
  bureau, mentionnée comme optionnelle par le document, est explicitement **écartée** faute de jalon
  l'exigeant (Art. 20).

**Profondeur de jalon vérifiée (Art. 20)** : le plan de specs impose « S11 ≤ J1 → M2 ». La spec marque
la coupure dans chaque sous-titre d'exigences — **J1 dû à M1** (coquille, client, navigation, canal),
**J2–J3 dus à M2** (les trois vues, les preuves). C'est la seconde spec du projet, avec S07, dont la
profondeur est coupée par un jalon.

**Traçabilité critère → preuve** : A1 → SC-001/005 (T11, T2), A2 → SC-002/004/010 (T11, T3), A3 →
SC-003/008/009 (T10, T11). Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-002 doit être prouvé côté client**, en observant les appels réellement émis par
   l'application — pas côté serveur. Un test serveur ne peut pas distinguer une interrogation d'une
   requête légitime.
2. **SC-001** exige un contrôle automatisé de l'absence de code client écrit à la main : le plan doit
   dire comment (par exemple en régénérant et en comparant), sinon l'exigence retombe sur la revue.
3. **FR-011** (aucun état global hors cache de requêtes et magasin temps réel) est une contrainte
   d'architecture qui devient très coûteuse à rattraper plus tard : à faire respecter dès la coquille,
   pas à la première vue complexe.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
