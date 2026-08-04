# Specification Quality Checklist: S15 — Hub d'observabilité + alertes + actions automatiques + carte de charge

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

- *No implementation details* : la fiche 9t nomme le langage de requête (PromQL), le produit
  (Prometheus), le mécanisme (`fichier rules + reload`, `range query`) et une valeur d'action
  (« power-limit −10 % »). Réservés au plan. La spec dit « sans écrire de langage de requête »,
  « moteur d'évaluation », « source unique de métriques », « réduire la puissance des cartes ». Le
  pourcentage exact de réduction est un paramètre de configuration, pas un contrat produit.
- *Requirements testable* : A1 (< 1 min) → SC-001 ; A2 (déclenchée puis annulée) → SC-002 ; A3
  (essai à blanc sur 7 j) → SC-003, précisé « nombre exact, sans qu'aucune action ne soit
  appliquée ».
- **Cette spec est le principal lieu d'application de l'Art. 15** (boucles agentiques bornées). Les
  trois garde-fous exigés par l'article ont été instanciés explicitement et rendus vérifiables :
  condition d'arrêt (FR-010, annulation à la résolution), journalisation (FR-009 → SC-006), et
  interdiction du destructif (FR-007 → SC-004). L'**inventaire fermé des actions autorisées** vaut
  « autorisation préalable capturée dans la spec » au sens de l'article — c'est ce point qui rend
  l'automatisme conforme.
- *Ajouts dérivés de la constitution* — six exigences explicitées :
  1. **FR-008 / SC-005** : **jamais** d'action automatique sur la lane interactive. Le document
     n'énumère que des actions sur les lanes agents et batch ; la spec en fait une interdiction
     explicite, car l'Art. 2 serait violé par une action ralentissant les humains.
  2. **FR-012 / SC-007** : protection contre le **battement** quand la condition oscille autour du
     seuil. Mode de défaillance classique, non traité par le document, et contraire à la « cadence de
     contrôle » de l'Art. 15.
  3. **FR-013 / SC-008** : au **redémarrage**, réévaluation des actions armées. Sans cela, une action
     peut rester appliquée indéfiniment si la condition s'est résorbée pendant l'arrêt.
  4. **FR-014 / SC-009** : un **échec d'annulation** est signalé comme incident. Une action non
     annulable silencieusement oubliée est exactement ce que l'Art. 15 veut empêcher.
  5. **FR-015** : ordre **déterministe** quand plusieurs actions s'appliquent.
  6. **FR-018** : le passage de l'essai à blanc à l'armement est un **acte explicite** (Art. 3).
  7. **FR-017** : si l'historique est plus court que la période demandée, le dire plutôt
     qu'extrapoler.
- *Edge cases* : les cas ajoutés ci-dessus sont tous documentés, plus « deux règles aux actions
  contradictoires ».
- *Scope is clearly bounded* : deux frontières décisives, toutes deux explicitées — avec **S02**
  (*S02 collecte et achemine, S15 lit et décide*) et avec **S05/S06** (*S15 actionne des leviers au
  travers de leur contrat, il ne les implémente pas*). Cette seconde frontière est ce qui permet
  d'ajouter un levier sans modifier l'exécuteur d'actions (Art. 18).

**Art. 22 (état de l'art) traité** : la spec consigne ce qui est **retenu** de l'outillage
d'exploitation GPU existant (lecture par quantiles, carte modèle × heure) et ce qui est **écarté avec
sa raison** — constituer une seconde chaîne de métriques propre au hub, qui violerait l'Art. 19. Les
références nominatives sont renvoyées au plan.

**Traçabilité critère → preuve** : A1 → SC-001 (T10, T2), A2 → SC-002/005/006/008/009 (T10, T9), A3 →
SC-003 (T11). Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-002 doit tester le cycle complet**, y compris l'annulation — un test qui vérifie seulement le
   déclenchement laisserait passer le mode de défaillance le plus dangereux (action appliquée pour
   toujours).
2. **FR-007 / SC-004** appellent un **inventaire fermé et explicite** des actions autorisées dans le
   plan. C'est cet inventaire qui constitue l'autorisation au sens de l'Art. 15 ; il ne doit pas être
   extensible par configuration sans amendement de la spec.
3. **FR-013** implique de persister l'état « armée / exécutée » des actions, pas seulement l'état des
   règles — sinon la réévaluation au redémarrage est impossible.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
