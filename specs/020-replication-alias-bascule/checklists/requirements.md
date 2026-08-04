# Specification Quality Checklist: S20 — Réplication d'alias entre hôtes + bascule

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

- *No implementation details* : la fiche 9y nomme les fonctions (`pick_instance`, `failover`), la
  structure (`alias → instances[]`) et le code HTTP (500). Réservés au plan. La spec dit « nom de
  modèle servi », « exemplaire », « le moins occupé », « aucune erreur serveur ».
- *Vocabulaire normatif conservé et central* : « alias », « instance » et surtout « réinjection en
  file » sont définis dans Key Entities avec leurs synonymes interdits. La définition de la
  réinjection est ici **normative et discriminante** : elle ne concerne que les requêtes **non
  entamées**, jamais une génération commencée — « retry » est réservé au client, « replay » est
  interdit. C'est la distinction la plus importante de la spec.
- *Requirements testable* : A1 → SC-001 ; A2 → SC-002, vérifié par **arrêt brutal** (le document dit
  « kill worker ») ; A3 → SC-003.
- *Ajouts dérivés de la constitution* — cinq exigences explicitées :
  1. **FR-012 / SC-006** : les requêtes réinjectées **respectent lanes et caps** et ne
     court-circuitent pas l'ordonnancement. Une bascule crée un pic ; le faire passer devant
     violerait l'Art. 2 exactement au moment où le service est déjà dégradé. Le document ne traite
     pas ce point.
  2. **FR-011 / SC-005** : garantie qu'une requête **n'est pas exécutée deux fois** — corollaire
     indispensable de la réinjection, non énoncé par le document.
  3. **FR-015** : **réintégration différée** d'une machine redevenue disponible, par symétrie avec le
     refus de réintégration automatique posé dans S19.
  4. **FR-014 / SC-008** : la perte du **dernier** exemplaire produit une erreur **explicite**,
     distincte d'une erreur générique.
  5. **FR-004 / FR-005 / SC-009** : la répartition suit la charge **observée** (pas un partage
     égalitaire) et reste **déterministe** à charge égale — sans quoi un exemplaire lent devient le
     goulot, ou tout le trafic se concentre sur le premier.
  6. **FR-006 / SC-007** : un exemplaire **en cours de chargement** n'est pas éligible au routage.
- *Edge cases* : ajout des cas « machine oscillante », « exemplaires de performances inégales »,
  « pic de réinjection », « dernier exemplaire perdu », « charges égales ».
- *Scope is clearly bounded* : deux exclusions structurantes — le **parallélisme inter-machines**,
  explicitement écarté par le document au profit de la réplication (c'est **le** choix d'architecture
  de la spec), et la **synchronisation d'état entre exemplaires**, hors périmètre. Cette seconde
  exclusion explique pourquoi une génération entamée ne peut pas être reprise ailleurs : chaque
  exemplaire est indépendant.

**Cohérence inter-specs vérifiée** : le seuil de 10 secondes de retrait du routage est **le même**
que celui du retrait d'un moteur attaché injoignable (S07). Le projet a donc un comportement homogène
face à l'indisponibilité, ce qui est noté dans les Assumptions. De même, FR-001 découle directement
de la règle de S19 « un nœud ne traverse jamais deux hôtes ».

**Traçabilité critère → preuve** : A1 → SC-001/009 (T7), A2 → SC-002/004/005/006 (T6), A3 → SC-003
(T7, T4). Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-002 doit être prouvé par un arrêt brutal**, pas par un retrait ordonné : c'est le mode de
   défaillance réel. Un test qui draine proprement ne prouverait pas la bascule.
2. **FR-010 / SC-004** : le plan doit distinguer sans ambiguïté « requête en file » et « génération
   entamée » — c'est cette frontière qui décide si une requête est réinjectée ou échoue. Une erreur
   ici produit soit des générations perdues, soit des doubles facturations.
3. **SC-001 (débit ×2)** exige deux machines réelles avec GPU : comme SC-002 de S19, il échappe à
   l'intégration continue. Le plan doit le situer au canari ou sur banc dédié, et prévoir des
   exemplaires simulés pour tester la logique de routage et de bascule sans matériel.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
