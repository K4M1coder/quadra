# Specification Quality Checklist: S12 — Connexion (SSO ou locale) + onboarding

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

- *No implementation details* : la fiche 9q nomme des protocoles et bibliothèques (OIDC, authlib,
  argon2, TOTP, cookies HttpOnly/SameSite) et des fonctions (`oidc_login`, `callback`). Réservés au
  plan. La spec dit « fournisseur d'identité », « empreinte irréversible », « second facteur »,
  « inaccessible au code exécuté dans le navigateur », « non transmissible depuis un site tiers ».
  Cette dernière formulation conserve l'**exigence de sécurité** (les propriétés attendues du
  transport de session) sans nommer le mécanisme — elle reste testable.
- *Requirements testable* : les valeurs normatives sont reprises — session de 12 h (FR-004 →
  SC-004), débordement désactivé par défaut (FR-013 → SC-003), assistant inaccessible après création
  d'un administrateur (FR-017 → SC-007).
- *Ajouts dérivés de la constitution* — six exigences explicitées :
  1. **FR-007** : règle d'attribution du rôle **explicite**, et **jamais** de rôle privilégié par
     défaut pour une identité externe inconnue. Le document ne traite pas ce cas ; l'attribution
     implicite d'un rôle administrateur serait une faille (Art. 5).
  2. **FR-008** : le mode local reste utilisable si le fournisseur d'identité est injoignable. Sans
     cela, une panne d'annuaire verrouille l'administration hors de la plateforme.
  3. **FR-009** : **procédure de récupération** du second facteur. Le document le présente comme
     optionnel sans traiter sa perte, qui verrouillerait définitivement un compte.
  4. **FR-006 / SC-006** : un échec de connexion ne révèle pas l'existence d'un identifiant.
  5. **FR-018 / FR-019** : reprise d'un assistant interrompu, et **un seul** administrateur en cas
     d'ouvertures simultanées — deux cas de course non traités par le document.
  6. **FR-020** : terminer l'assistant **sans modèle** si aucun ne tient, plutôt que bloquer
     l'installation.
- *Réutilisation vérifiable* : la consigne du document « le wizard réutilise detect_gpus() et le
  catalogue » devient FR-021 + **SC-010**, contrôlé par inspection des dépendances plutôt que laissé
  à la revue (Art. 19).
- *Edge cases* : ajout des cas « session expirée pendant une action longue » et « identité externe
  sans correspondance locale ».
- *Scope is clearly bounded* : deux frontières nettes — avec **S04** (*S04 authentifie les clients
  par clé, S12 authentifie les humains*) et avec **S13** (*S12 attribue un rôle, S13 dit ce qu'il
  permet*). Le **débordement mémoire** est explicitement renvoyé à S18 : S12 garantit seulement
  qu'il est désactivé à l'installation.

**Revue humaine obligatoire** : le **flux de session** relève du chemin « authentification » de
l'Art. 8. Le plan doit en faire une porte explicite, comme pour S04.

**Traçabilité critère → preuve** : A1 → SC-001/004/006 (T9), A2 → SC-002/008/009 (T8), A3 → SC-003
(T9). Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-002 est le critère de sortie du jalon M2** (« wizard vierge → modèle servi »). Le test T8
   doit partir d'un état réellement vierge — base vide, aucun administrateur, aucun modèle — et non
   d'un environnement pré-amorcé, sinon il ne prouve rien.
2. **SC-003** doit être vérifié sur le **résultat** de l'installation (l'état effectif du réglage),
   pas seulement sur l'apparence de la case dans l'assistant.
3. **FR-017 / SC-007** : la garde doit être appliquée **côté serveur**, pas par l'absence de lien
   dans l'interface (Art. 5) — c'est un chemin d'élévation de privilège s'il est mal placé.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
