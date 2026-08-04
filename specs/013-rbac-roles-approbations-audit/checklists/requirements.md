# Specification Quality Checklist: S13 — Permissions par rôle + éditeur + approbations + audit

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

- *No implementation details* : la fiche 9r nomme le format (`permissions.yaml`), l'outil de test
  (pytest), le mécanisme (`décorateur require()`, `audit()`, hash chaîné) et le code HTTP (403).
  Réservés au plan. La spec dit « description unique et versionnée », « tests générés », « chaque
  route déclare la permission qu'elle exige », « chaque entrée liée à la précédente », « code
  canonique de permission refusée ».
  **Le chaînage cryptographique est conservé comme exigence de comportement** (FR-017 : une
  altération rend la vérification invalide **et désigne le point de rupture**) sans nommer
  l'algorithme — c'est ce qui rend le critère A3 testable indépendamment de la technique.
- *Requirements testable* : A1 (« 100 % de cas couverts ») devient SC-001, complété par « zéro test
  écrit à la main » — sans quoi une couverture de 100 % pourrait être atteinte par des tests
  manuels, ce qui violerait l'Art. 19 tout en satisfaisant la lettre du critère.
- *Ajouts dérivés de la constitution* — sept exigences explicitées :
  1. **FR-005 / SC-004** : une route **sans déclaration** de permission est détectée mécaniquement et
     **bloque la fusion**. Le document exige de décorer chaque route sans dire ce qui arrive si on
     oublie ; or une route non déclarée est ouverte par défaut.
  2. **FR-013 / SC-011** : une demande ne peut pas être approuvée par **son propre auteur**. Le
     document ne le précise pas ; sans cette règle, le flux d'approbation ne protège de rien.
  3. **FR-019 / SC-009** : si l'entrée d'audit ne peut pas être écrite, l'action est **refusée**.
     C'est la lecture stricte de l'Art. 4 (« un composant qui ne peut pas rendre compte n'entre pas
     en production »).
  4. **FR-021** : l'archivage d'entrées anciennes **ne rompt pas** la vérification de la chaîne
     restante — indispensable pour que l'Art. 4 tienne au-delà de 2 ans.
  5. **FR-017** : la vérification doit **désigner le point de rupture**, pas seulement échouer.
  6. **FR-010 / SC-010** : l'**expiration** d'une demande sans décision, auditée (reprise de la
     machine à états 10d).
  7. **FR-006** : la surcharge par organisation ne peut **jamais élargir** au-delà de la matrice.
- *Edge cases* : ajout des cas « deux actions sensibles simultanées » (cohérence et ordre de la
  chaîne) et « journal très volumineux » (l'archivage ne doit pas casser la vérification).
- *Scope is clearly bounded* : la frontière décisive est sur l'audit — **S13 fournit le mécanisme et
  garantit l'infalsifiabilité ; les autres specs émettent leurs entrées** (S06 évictions, S10
  quarantaines, S15 actions d'alerte, S19 adhésions). Sans cette règle, chaque spec créerait son
  propre journal (Art. 19). La frontière avec **S12** est aussi posée : *S12 établit l'identité, S13
  dit ce qu'elle peut faire*.

**Revue humaine obligatoire** : le document identifie « revue humaine des permissions » comme le
**risque de la phase 4**. Le plan doit en faire une porte explicite sur T1–T3.

**Traçabilité critère → preuve** : A1 → SC-001/005 (T11, T3), A2 → SC-002/004 (T10, T9), A3 →
SC-003/007 (T11, T4). Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-002 doit être testé hors interface** : le test T10 doit appeler le serveur directement, avec
   un jeton de rôle insuffisant. Un test passant par l'interface ne prouverait que le masquage.
2. **SC-003 exige de tester l'altération d'une entrée *ancienne***, pas seulement de la dernière —
   c'est tout l'intérêt du chaînage, et l'erreur classique est de ne vérifier que la fin.
3. **FR-002 / SC-001** : la génération doit être rejouée en intégration continue, sinon la matrice et
   les tests peuvent diverger silencieusement entre deux régénérations manuelles.
4. **FR-019** crée un couplage fort entre l'écriture d'audit et l'exécution de l'action : le plan doit
   dire comment il est réalisé sans rendre le chemin critique dépendant d'une écriture lente.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
