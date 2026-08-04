# Feature Specification: S14 — Journaux & traces + rétention des prompts

**Feature Branch**: `014-logs-traces-retention-prompts`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9s du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S14 du plan de specs 9c : « Logs & traces + rétention des prompts », références 6d · 5c (prompts), dépend de S08, effort ≈ 6 j-agent, phase 4 (gouvernance & observabilité). **Profondeur de jalon : J1 à M2 (traces et interface d'accès), J2–J3 complétés à M3** (Art. 20).

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J2 de la fiche 9s. Cette spec rend chaque requête
**explicable après coup** — où le temps est passé, ce qu'elle a coûté — tout en garantissant que le
contenu des échanges n'est conservé **que si la clé l'a explicitement demandé** (Art. 3).

### User Story 1 - Cœur : chaque requête est traçable, les prompts ne sont conservés que sur demande (Priority: P1)

Un opérateur retrouve n'importe quelle requête par son identifiant ou par des filtres, et voit
comment son temps s'est réparti entre l'attente en file, la phase de préremplissage et la phase de
génération, avec son coût. Le contenu de la requête, lui, n'est présent que si la clé a opté pour sa
conservation.

**Why this priority**: c'est la profondeur J1, **due à M2**. Sans trace, un ralentissement n'est pas
diagnosticable : on ne sait pas distinguer une file saturée d'un modèle lent. L'opt-in des prompts
est l'application directe de l'Art. 3 — le contenu des échanges est la donnée la plus sensible du
système.

**Independent Test**: émettre une requête, la retrouver par son identifiant moins d'une seconde après
sa fin, et vérifier la présence des durées par étape ; puis répéter avec une clé qui n'a pas opté et
constater l'absence du contenu.

**Acceptance Scenarios**:

1. **Given** une requête terminée, **When** un opérateur la recherche, **Then** sa **trace complète**
   est disponible **moins d'une seconde** après la fin de la requête.
2. **Given** une trace, **When** elle est consultée, **Then** elle présente la **durée de chaque
   étape** du cycle de vie — attente en file, préremplissage, génération — ainsi que le **coût** de la
   requête et l'indication d'une réutilisation de contexte le cas échéant.
3. **Given** une clé qui **n'a pas** opté pour la conservation du contenu, **When** une de ses
   requêtes est consultée, **Then** le **contenu est absent** — seules les métadonnées existent.
4. **Given** une clé qui **a** explicitement opté, **When** une de ses requêtes est consultée,
   **Then** le contenu est présent, dans la limite de la durée de conservation.
5. **Given** un ensemble de requêtes, **When** l'opérateur les filtre par clé, par état ou par
   période, **Then** il obtient les résultats correspondants, paginés de façon stable même sous
   écriture continue.
6. **Given** la durée de conservation des contenus, **When** la purge s'exécute, **Then** les
   contenus expirés sont **effectivement supprimés** et la purge est **journalisée**.
7. **Given** les durées d'étape, **When** elles sont produites, **Then** elles proviennent des
   mesures **déjà émises** par le système — **aucune seconde chaîne d'instrumentation** n'est
   introduite (Art. 19).
8. **Given** une requête à n'importe quelle issue — terminée, refusée, annulée, échouée — **When**
   elle est consultée, **Then** son **état final** figure dans la trace, conformément à la machine à
   états normative.

---

### User Story 2 - Surface : je filtre et je lis la trace (Priority: P2)

L'opérateur parcourt la liste des requêtes depuis l'interface, applique des filtres, et ouvre une
requête pour lire sa trace détaillée sous forme lisible.

**Why this priority**: c'est la profondeur J2, **due à M3** — le document diffère explicitement
l'interface (« S14 ≤ J1 → M3 »). L'accès programmatique de J1 suffit à M2 ; l'interface ajoute le
confort de diagnostic.

**Independent Test**: ouvrir la vue des journaux, filtrer sur une clé et une période, ouvrir une
requête et vérifier que le panneau de trace présente la répartition des durées.

**Acceptance Scenarios**:

1. **Given** la vue des journaux, **When** l'opérateur applique des filtres, **Then** la liste se
   restreint en conséquence et reste utilisable sur de grands volumes.
2. **Given** une requête sélectionnée, **When** l'opérateur ouvre son panneau de trace, **Then** il
   voit la répartition des durées par étape sous forme lisible, avec le coût.
3. **Given** une requête dont le contenu n'a pas été conservé, **When** l'opérateur ouvre sa trace,
   **Then** l'absence de contenu est **indiquée explicitement** comme un choix d'opt-in, pas comme
   une erreur.

---

### Edge Cases

- **Une requête est annulée avant d'être ordonnancée** : sa trace existe tout de même, avec les
  étapes atteintes et son état final.
- **Une requête dure très longtemps** : sa trace est consultable **pendant** son exécution, avec les
  étapes déjà franchies.
- **La clé change d'option de conservation en cours de route** : le choix en vigueur **au moment de
  la requête** s'applique ; changer l'option ne fait pas apparaître rétroactivement des contenus non
  conservés, ni disparaître ceux déjà conservés avant leur expiration.
- **La purge échoue** : l'échec est signalé — une purge silencieusement inopérante laisserait des
  contenus au-delà de leur durée de conservation, ce qui contredirait l'engagement pris à l'opt-in.
- **Le volume de requêtes est très élevé** : la pagination reste stable sous écriture continue —
  aucune requête n'est vue deux fois ni sautée pendant la navigation.
- **Une trace est demandée pour un identifiant inexistant** : réponse explicite, distincte d'une
  trace vide.
- **Un utilisateur consulte des requêtes hors de son périmètre** : elles ne lui sont pas visibles ;
  la décision est serveur.

## Requirements *(mandatory)*

### Functional Requirements

#### Traces (J1 — M2)

- **FR-001**: Le système DOIT enregistrer, pour chaque requête, la **durée de chaque étape** de son
  cycle de vie : attente en file, préremplissage, génération.
- **FR-002**: La trace complète d'une requête DOIT être disponible **moins d'une seconde** après la
  fin de celle-ci.
- **FR-003**: La trace DOIT présenter le **coût** de la requête et l'indication d'une **réutilisation
  de contexte** le cas échéant.
- **FR-004**: La trace DOIT porter l'**état final** de la requête, conformément à la machine à états
  normative — y compris pour les requêtes refusées, annulées ou échouées.
- **FR-005**: Les durées d'étape DOIVENT provenir des **mesures déjà émises** par le système. Aucune
  **seconde chaîne d'instrumentation** NE DOIT être introduite (Art. 19).
- **FR-006**: La trace d'une requête **en cours** DOIT être consultable, avec les étapes déjà
  franchies.
- **FR-007**: Une requête DOIT être retrouvable par son **identifiant unique**.

#### Recherche et filtres (J1 — M2)

- **FR-008**: Le système DOIT permettre de filtrer les requêtes par **clé**, par **état** et par
  **période**.
- **FR-009**: La pagination DOIT rester **stable sous écriture continue** : aucune requête n'est vue
  deux fois ni omise pendant la navigation.
- **FR-010**: Un utilisateur NE DOIT voir que les requêtes de son **périmètre**, la décision étant
  prise côté serveur (Art. 5).
- **FR-011**: Une demande portant sur un identifiant inexistant DOIT produire une réponse explicite,
  **distincte** d'une trace vide.

#### Conservation du contenu (J1 — M2, Art. 3)

- **FR-012**: Le contenu des requêtes NE DOIT être conservé **que si la clé a explicitement opté**
  pour cette conservation. Le silence vaut refus.
- **FR-013**: Le choix en vigueur **au moment de la requête** DOIT s'appliquer : un changement
  d'option NE DOIT ni faire apparaître rétroactivement un contenu non conservé, ni supprimer avant
  terme un contenu déjà conservé.
- **FR-014**: Les contenus conservés DOIVENT être **purgés** au terme de leur durée de conservation,
  **30 jours** par défaut, cette durée étant réglable.
- **FR-015**: La purge DOIT être **journalisée** et son **échec signalé**.
- **FR-016**: L'absence de contenu DOIT être présentée comme un **choix d'opt-in**, jamais comme une
  erreur.

#### Surface (J2 — M3)

- **FR-017**: Le système DOIT fournir une vue **liste des requêtes** avec ses filtres, utilisable sur
  de grands volumes.
- **FR-018**: Le système DOIT fournir un **panneau de trace** présentant la répartition des durées
  par étape et le coût, sous forme lisible.

#### Preuves (J3 — M3)

- **FR-019**: Le délai de disponibilité de la trace, l'absence de contenu sans opt-in et
  l'effectivité de la purge DOIVENT être prouvés par des tests dédiés.

### Hors périmètre *(Art. 20 — YAGNI)*

- Le **calcul du coût** et l'enregistrement de la ligne d'usage → **S08**. S14 **affiche** le coût
  déjà calculé et **enrichit** la même ligne de ses durées d'étape.
- L'**émission des mesures** de latence et de file → **S04**, **S05**, dont S14 réutilise les
  valeurs sans réinstrumenter.
- La **collecte et la conservation des métriques** → **S02**. S14 traite la trace **par requête**,
  pas les séries temporelles agrégées.
- Le **hub d'observabilité**, les règles d'alerte et la carte de charge → **S15**.
- La **coquille d'interface** → **S11**.
- Le **contrôle d'accès** définissant les périmètres de visibilité → **S13**.
- Le **journal d'audit** des actions d'administration → **S13**. S14 trace les **requêtes
  d'inférence**, pas les actions d'administration : ce sont deux journaux distincts par nature.

### Key Entities

- **Trace** : décomposition temporelle d'une requête en étapes (attente en file, préremplissage,
  génération), avec son coût et son état final. Rattachée à l'arbre du trafic de la taxonomie
  (Request → Trace).
- **Étape** : segment du cycle de vie d'une requête, borné par deux instants et issu des mesures déjà
  émises.
- **Contenu conservé** : corps d'une requête, stocké **uniquement sur opt-in de la clé**, associé à
  une unique requête, purgé au terme de sa durée de conservation.
- **Option de conservation** : choix explicite porté par une clé, déterminant si le contenu de ses
  requêtes est conservé.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: La trace complète d'une requête est disponible en **moins
  d'une seconde** après sa fin, pour **100 %** des requêtes.
- **SC-002** *(critère A2)*: Pour une clé n'ayant pas opté, le contenu est **absent dans 100 %** des
  cas — vérifié y compris en accédant directement au stockage.
- **SC-003** *(critère A3)*: La purge s'exécute quotidiennement, **supprime effectivement** les
  contenus expirés, et son exécution est **vérifiable** dans les journaux.
- **SC-004**: **Zéro** seconde chaîne d'instrumentation : les durées d'étape proviennent des mesures
  existantes — vérifié par inspection.
- **SC-005**: La pagination reste stable sous écriture continue : sur un parcours complet pendant que
  de nouvelles requêtes arrivent, **aucune** requête n'est vue deux fois ni omise.
- **SC-006**: Un changement d'option de conservation n'a **aucun effet rétroactif**.
- **SC-007**: Un échec de purge est **signalé** — jamais silencieux.
- **SC-008**: Les requêtes refusées, annulées et échouées ont **toutes** une trace portant leur état
  final.
- **SC-009**: Un utilisateur ne voit **aucune** requête hors de son périmètre, y compris en
  contournant l'interface.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9s) |
| --- | --- | --- |
| A1 — trace complète en moins d'une seconde | SC-001, SC-008 | T8 `[TEST]` trace < 1 s |
| A2 — contenu absent sans opt-in | SC-002, SC-006 | T9 `[TEST]` opt-in |
| A3 — purge quotidienne vérifiable | SC-003, SC-007 | T9 `[TEST]` purge |
| Pas de double instrumentation | SC-004 | T1 enregistrement des durées d'étape |
| Pagination stable | SC-005 | T2 recherche + pagination |
| Coût affiché | SC-001 | T7 `[INT]` coût par requête (S08) |

## Assumptions

- **Profondeur de jalon — coupure explicite** : le plan de specs impose « S14 ≤ J1 → M3 ». **J1 est
  dû à M2** (enregistrement des durées, recherche, opt-in, purge) ; **J2 (interface) et J3 (preuves)
  sont dus à M3**. Aucune interface de journaux ne DOIT être développée à M2 (Art. 20).
- **Dépendance à S08** : la ligne d'usage existe déjà, avec son coût. S14 l'**enrichit** de ses
  durées d'étape plutôt que de créer une seconde table — ce qui évite deux vérités sur la même
  requête (Art. 19).
- **Réutilisation des mesures existantes** : la consigne du document est explicite (« les spans
  viennent des métriques déjà émises »). C'est une contrainte d'architecture, pas une optimisation :
  une seconde instrumentation produirait des durées divergentes de celles des tableaux de bord.
- **Conservation** : contenus 30 jours par défaut (réglable), lignes d'usage 24 mois — valeurs fixées
  par le document (5c). La durée des contenus est réglable parce qu'elle engage la confidentialité ;
  celle des lignes d'usage ne l'est pas, elle engage la facturation.
- **Deux journaux distincts** : les **traces de requêtes** (S14) et le **journal d'audit des actions
  d'administration** (S13) sont des objets différents, avec des rétentions différentes (30 j / 2 ans)
  et des exigences différentes (le second est infalsifiable). Ils ne sont pas fusionnés.
- **L'opt-in porte sur la clé, pas sur la requête** : c'est le choix du document. Une clé de débogage
  peut conserver ses contenus ; une clé de production ne le fait pas. Le choix est visible et
  révocable.
