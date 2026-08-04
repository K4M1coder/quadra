# Specification Quality Checklist: S17 — Playground / console d'essai

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

- *No implementation details* : la fiche 9v nomme les cibles (`to_curl`, `to_python`, `to_node`), la
  route `/v1` et les métriques. Réservés au plan. La spec dit « appel en ligne de commande et clients
  des langages courants », « contrat d'inférence », « latence de premier jeton ». La liste exacte des
  formes d'extrait relève du plan ; l'exigence testable est que **chaque forme proposée fonctionne
  réellement** (SC-001).
- *Requirements testable* : A1 → SC-001 ; A2 → SC-002 ; A3 → SC-003, vérifié « par comparaison au
  contrat » plutôt que par une liste figée de paramètres, qui divergerait du contrat avec le temps.
- **Renforcement notable du critère A1** : le document prévoit des « snapshots ». La spec exige **en
  plus une exécution réelle** de l'extrait (FR-015 → SC-001). Une comparaison à une référence figée
  prouve seulement que l'extrait **n'a pas changé** — pas qu'il **fonctionne**. Or A1 dit
  explicitement « le snippet copié fonctionne tel quel ». Sans exécution réelle, le critère
  d'acceptation le plus important de cette spec ne serait pas prouvé.
- *Ajouts dérivés de la constitution* — quatre exigences explicitées :
  1. **FR-009 / SC-005** : la **valeur secrète de la clé n'apparaît jamais** dans un extrait
     (Art. 5). Un extrait copié atterrit dans un canal de discussion ou un dépôt ; y inscrire une clé
     en clair serait une fuite par conception. Le document ne traite pas ce point.
  2. **FR-004 / FR-005 / SC-006** : la console n'a **aucun accès privilégié** ; les refus (droit,
     quota, budget) sont présentés tels qu'un client réel les recevrait. C'est ce qui rend l'essai
     représentatif — une console qui contournerait les quotas mentirait sur le comportement réel.
  3. **FR-010 / SC-008** : un paramètre laissé vide n'apparaît **pas** avec une valeur inventée, qui
     pourrait diverger du défaut serveur.
  4. **FR-011** : l'extrait est correct **sans exécution préalable** — il dérive de la requête
     composée, pas d'une trace d'appel.
- *Edge cases* : ajout des cas « clé sans accès au modèle », « dépassement de quota » (fait partie de
  ce qu'on vient tester), « copie sans exécution » et « évolution du contrat ».
- *Scope is clearly bounded* : distinction explicite avec **S16** (*chat = usage conversationnel
  persistant ; console = essai ponctuel*) et exclusion de l'enregistrement/partage de requêtes
  composées, qu'aucun jalon n'exige (Art. 20).

**Traçabilité critère → preuve** : A1 → SC-001/004/005/008 (T6), A2 → SC-002/006 (T7, T5), A3 →
SC-003 (T7). Table complète dans la spec.

**Points d'attention pour le plan**

1. **FR-008 / SC-004** est le cœur de la spec : appel réel et extraits doivent **dériver de la même
   description**. Le plan doit montrer cette dérivation explicitement ; c'est ce qui garantit A1 dans
   la durée, et l'erreur naturelle serait de maintenir des gabarits séparés.
2. **SC-001 exige une exécution réelle** dans les tests — donc un environnement où l'extrait peut
   être lancé, contre le moteur factice, pour chaque forme proposée.
3. **FR-012** : les appels de la console passent par le chemin commun, donc consomment quota et
   budget. À signaler à l'utilisateur dans l'interface, faute de quoi un essai répété épuiserait un
   budget sans que ce soit compris.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
