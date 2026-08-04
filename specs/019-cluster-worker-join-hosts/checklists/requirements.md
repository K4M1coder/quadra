# Specification Quality Checklist: S19 — Mode cluster : adhésion, détection, vue des hôtes

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

- *No implementation details* : la fiche 9x nomme la technologie de détection (NVML), le protocole
  (mTLS), les fonctions (`join_cluster`, `announce_hw`, `drain_host`, `leave_cluster`,
  `remove_host`), les tables et la commande exacte (`quadra worker join <url> --token`). Réservés au
  plan. La spec dit « découverte », « canal où les deux extrémités s'authentifient mutuellement »,
  « jeton à usage unique », « signal de vie ». Le critère A1, qui cite une commande précise, est
  reformulé en SC-001 comme « une commande d'adhésion depuis une machine dotée d'un jeton fait
  apparaître l'hôte en attente d'approbation » — l'exigence est conservée, la syntaxe relève du plan.
- *Vocabulaire normatif conservé* : « worker » et « signal de vie » sont définis dans Key Entities
  avec leurs synonymes interdits — « agent » (réservé aux clients IA) et « daemon » pour le premier,
  « ping » et « keepalive » pour le second. La distinction worker/agent est particulièrement
  importante dans ce projet, où « agent » désigne un client IA consommant l'API.
- *Requirements testable* : A1 → SC-001/004/005/006 ; A2 → SC-002 ; A3 → SC-003, avec la précision
  que **trois** manques consécutifs sont requis (FR-012) et qu'une reprise avant le troisième ne
  change rien (FR-013) — sans quoi un hic réseau bref sortirait un hôte du cluster.
- *Ajouts dérivés de la constitution* — cinq exigences explicitées :
  1. **FR-010** : un **certificat expiré** fait traiter l'hôte comme perdu, jamais poursuivre sans
     authentification. Le document ne traite pas l'expiration en cours de service.
  2. **FR-021 / SC-009** : **pas de réintégration automatique**. C'est déductible de la machine à
     états (« ré-admission = nouveau join »), mais l'écrire explicitement empêche qu'un hôte instable
     oscille dans le cluster.
  3. **FR-022** : un **drainage qui n'aboutit pas** est signalé après un délai maximal — même
     exigence que celle posée dans S06 pour le drainage de nœud.
  4. **FR-005** : un jeton **expire** s'il n'est pas utilisé, en plus d'être à usage unique.
  5. **FR-006 / SC-005** : un hôte non approuvé reçoit **zéro** trafic — l'approbation est une porte,
     pas une formalité.
- *Edge cases* : ajout des cas « jeton intercepté », « reprise du signal après deux manques »,
  « hôte perdu qui réapparaît », « latence réseau trop élevée » (le risque identifié de la phase), et
  « cluster au-delà de trois machines ».
- *Scope is clearly bounded* : la frontière la plus importante est avec **S20** — *S19 rend les hôtes
  disponibles, S20 les fait collaborer*. Elle est renforcée par FR-016 (**un nœud ne traverse jamais
  deux hôtes**), qui explique **pourquoi** S20 est nécessaire : on ne répartit pas un modèle entre
  machines, on le réplique.

**Art. 9 respecté et rendu visible** : la spec note explicitement qu'aucun orchestrateur générique
n'est introduit sous trois machines, et que le document prévoit de **réévaluer** l'approche au-delà
plutôt que d'étendre ce mécanisme. C'est consigné dans les Assumptions pour que l'extension ne se
fasse pas par inertie.

**Traçabilité critère → preuve** : A1 → SC-001/004/005/006 (T12, T4), A2 → SC-002 (T12, T2), A3 →
SC-003/009 (T12, T6). Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-002 exige du matériel réel** sur un second hôte — comme SC-001 de S06, il échappe à
   l'intégration continue. Le plan doit le dire, et prévoir un worker simulé pour tout le reste
   (adhésion, signal de vie, états, drainage), qui **est** testable sans GPU.
2. **FR-002 / Art. 19** : le code de découverte doit être **le même** que celui de S06, exécuté
   localement. Le plan ne doit pas produire une seconde implémentation côté worker.
3. **SC-007** (authentification mutuelle) est le risque de sécurité de la spec : le plan doit décrire
   la distribution et le **renouvellement** des certificats, pas seulement leur émission initiale —
   FR-010 en dépend.

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
