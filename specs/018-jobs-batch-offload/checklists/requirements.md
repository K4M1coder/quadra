# Specification Quality Checklist: S18 — Jobs par lot + offload sur demande

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

- *No implementation details* : la fiche 9w nomme la route (`/v1/batches`), les fonctions
  (`schedule`, `notify`), le mécanisme de signature (HMAC), les drivers d'offload et le champ
  (`offload:true`). Réservés au plan. La spec dit « lots de travaux asynchrones », « périodes
  creuses », « notification signée », « mode avec débordement mémoire », « demande explicite portée
  par le lot ».
- *Vocabulaire normatif conservé* : « offload » est défini dans Key Entities avec son synonyme
  interdit — « swap », réservé au hot-swap (Art. 12). La confusion entre les deux serait
  particulièrement nuisible ici, les deux mécanismes touchant à la mémoire.
- *Requirements testable* : A1 → SC-001, renforcé par « zéro acceptation suivie d'un échec
  silencieux » ; A2 → SC-002, avec la mention explicite « **mesurée**, non supposée » (le document
  écrit lui-même « mesuré ») ; A3 → SC-003.
- *Ajouts dérivés de la constitution* — six exigences explicitées :
  1. **FR-018 / SC-007** : une notification sortante **ne transporte jamais le contenu** du résultat.
     Le document exige la signature sans dire ce que la notification contient ; y placer le résultat
     ferait **sortir les données de l'infrastructure** et violerait l'Art. 1. C'est l'ajout le plus
     important de cette spec.
  2. **FR-008 / SC-005** : la progression d'un lot reste **strictement positive** — la cession ne
     doit pas devenir une famine. Cohérent avec l'exigence symétrique posée dans S05.
  3. **FR-012 / SC-010** : refus explicite si le **volume de débordement est indisponible**, plutôt
     qu'une dégradation silencieuse.
  4. **FR-019 / SC-008** : un **échec de notification** ne rend pas le résultat inaccessible — perdre
     une notification ne doit pas faire perdre le travail.
  5. **FR-014** : l'estimation est présentée **comme une estimation**, pas comme un engagement.
  6. **FR-004** : un lot échoué met à disposition la **partie déjà produite** quand elle a du sens.
- *Edge cases* : ajout des cas « lot soumis pendant une saturation » (à accepter, c'est l'intérêt de
  l'asynchrone), « annulation en cours », « estimation imprécise au début », et « lot qui cède si
  souvent qu'il n'avance plus ».
- *Scope is clearly bounded* : trois frontières explicitées — **S05** (*S18 utilise la lane batch, ne
  l'implémente pas*), **S15** (*S18 consomme la carte de charge*), **S08** (*les requêtes d'un lot
  sont comptées comme les autres*). L'ordonnancement fin par priorité entre lots est explicitement
  écarté faute de jalon l'exigeant.

**Point de conception relevé** : l'offload est **le seul mécanisme du projet dont le consentement
passe par un champ de requête** plutôt que par un dialogue de confirmation. La raison est notée dans
les Assumptions : le demandeur est un programme, pas un humain devant un écran. L'Art. 3 s'applique
donc sous la forme d'un opt-in explicite par lot, le silence valant refus — ce qui rend FR-009 et
FR-010 indissociables : sans le refus explicite, l'opt-in n'aurait aucune force.

**Traçabilité critère → preuve** : A1 → SC-001/004/010 (T10, T3), A2 → SC-002/005 (T9, mesuré), A3 →
SC-003/007/008 (T10). Table complète dans la spec.

**Points d'attention pour le plan**

1. **SC-002 doit être mesuré pendant un lot long**, pas pendant une exécution courte : c'est la durée
   qui met la cession à l'épreuve. Le test doit s'appuyer sur le même dispositif que celui de S05.
2. **FR-013 / SC-006** : l'estimation doit **s'affiner** — le plan doit dire à quelle fréquence elle
   est recalculée, sinon une estimation figée à la soumission satisferait la lettre de l'exigence.
3. **FR-021** : la purge des résultats à 7 jours doit être vérifiable au même titre que celle des
   contenus de S14 — le plan devrait réutiliser le même mécanisme plutôt qu'en créer un second
   (Art. 19).

**Résultat** : tous les items passent. Spec prête pour `/speckit-plan`. `/speckit-clarify` non requis.
