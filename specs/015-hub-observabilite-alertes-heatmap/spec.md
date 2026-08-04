# Feature Specification: S15 — Hub d'observabilité + règles d'alerte + actions automatiques + carte de charge

**Feature Branch**: `015-hub-observabilite-alertes-heatmap`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9t du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S15 du plan de specs 9c : « Hub observabilité + éditeur d'alertes + actions auto + heatmap », références 6e · 6f · 6h · W6, dépend de S02 et S11, effort ≈ 7 j-agent, phase 4 (gouvernance & observabilité), jalon produit M3 (V1.1 confort).

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J2 de la fiche 9t. Cette spec transforme
l'observation en **action bornée et réversible** — application directe de l'Art. 15 (boucles
agentiques bornées) : le système peut réagir seul, mais jamais de façon destructive, et toujours en
rendant compte.

### User Story 1 - Cœur : une règle créée agit, et son action s'annule d'elle-même (Priority: P1)

L'opérateur définit une condition d'alerte depuis le produit, sans écrire de langage de requête. Il
peut l'assortir d'une action automatique — ralentir la lane des agents, suspendre la lane batch,
réduire la puissance des cartes. Quand la condition se résorbe, l'action est **annulée
automatiquement**. Il peut aussi l'essayer à blanc avant de l'armer.

**Why this priority**: c'est la profondeur J1 et la totalité de la valeur métier. Une alerte qui ne
fait que notifier laisse le problème entier à 3 h du matin ; une action automatique **non
réversible** serait pire que le problème. La réversibilité et l'essai à blanc sont ce qui rend
l'automatisme acceptable (Art. 15).

**Independent Test**: créer une règle depuis le produit, provoquer la condition, constater que
l'action s'applique, puis résorber la condition et constater que l'action est annulée — le tout sans
toucher à un fichier de configuration.

**Acceptance Scenarios**:

1. **Given** l'éditeur de règles, **When** l'opérateur définit une condition à partir des types
   proposés, **Then** la règle est créée **sans qu'il écrive de langage de requête**.
2. **Given** une règle créée dans le produit, **When** elle est enregistrée, **Then** elle est
   **prise en compte par le moteur d'évaluation en moins d'une minute**.
3. **Given** une règle assortie d'une action automatique, **When** la condition se déclenche,
   **Then** l'action est **exécutée** et **inscrite au journal d'audit**.
4. **Given** une action automatique exécutée, **When** la condition se **résorbe**, **Then** l'action
   est **annulée automatiquement**, et cette annulation est également tracée.
5. **Given** l'ensemble des actions automatiques disponibles, **When** on les examine, **Then**
   **aucune n'est destructive ni difficilement réversible** — elles se limitent à ralentir, suspendre
   ou réduire, toutes annulables.
6. **Given** une règle, **When** l'opérateur l'exécute **à blanc**, **Then** le système lui indique
   **combien de fois elle se serait déclenchée sur les 7 derniers jours**, **sans agir**.
7. **Given** une règle et son action, **When** leur état évolue, **Then** ils suivent les machines à
   états normatives : règle inactive → en attente → déclenchée → résolue ; action armée → exécutée →
   annulée.
8. **Given** les lanes, **When** une action automatique s'applique, **Then** elle agit sur les lanes
   **agents et batch** — **jamais** sur la lane interactive, qui garde sa préséance (Art. 2).

---

### User Story 2 - Surface : hub en direct, bannières, carte de charge (Priority: P2)

L'opérateur dispose d'un hub interne présentant les quantiles de latence, l'occupation des différents
niveaux de mémoire et l'état des cibles de collecte. Les alertes en cours s'affichent en bannière.
Une carte de charge lui montre quand la plateforme est creuse, pour y planifier les traitements
lourds.

**Why this priority**: c'est la profondeur J2. Elle rend l'observabilité utilisable sans quitter le
produit et prépare la planification en heures creuses dont S18 dépend.

**Independent Test**: ouvrir le hub avec de la charge en cours, vérifier que les quantiles et l'état
des cibles s'affichent ; déclencher une alerte et constater la bannière ; ouvrir la carte de charge
et retrouver les périodes creuses.

**Acceptance Scenarios**:

1. **Given** de la charge en cours, **When** l'opérateur ouvre le hub, **Then** il voit les
   **quantiles de latence** — premier jeton et inter-jetons — l'occupation des **niveaux de
   mémoire**, et l'**état des cibles de collecte**.
2. **Given** une alerte qui se déclenche, **When** elle passe à l'état déclenché, **Then** une
   **bannière** apparaît en direct ; elle disparaît à la résolution.
3. **Given** un historique de charge, **When** l'opérateur ouvre la carte de charge, **Then** il voit
   la charge **par modèle et par heure**, permettant d'identifier les périodes creuses.
4. **Given** une case de la carte de charge, **When** l'opérateur l'ouvre, **Then** il accède aux
   requêtes correspondantes.
5. **Given** le hub, **When** il affiche ses données, **Then** elles proviennent **de la source
   unique de métriques** — aucune seconde chaîne de mesure n'est constituée (Art. 19).

---

### Edge Cases

- **Une règle mal formée est enregistrée** : elle est refusée à la création avec un motif explicite,
  plutôt qu'acceptée et silencieusement jamais évaluée.
- **Deux règles déclenchent des actions contradictoires** : l'ordre d'application est déterministe et
  l'état résultant est cohérent ; l'annulation de l'une ne défait pas l'effet de l'autre.
- **La condition oscille rapidement autour du seuil** : l'action n'est pas appliquée et annulée en
  boucle — un délai de confirmation évite le battement (Art. 15 : cadence de contrôle).
- **La condition se résorbe pendant que le système est arrêté** : au redémarrage, les actions
  armées sont réévaluées et annulées si leur condition n'est plus vraie — aucune action ne reste
  appliquée indéfiniment.
- **L'action ne peut pas être annulée** (composant cible indisponible) : l'échec est signalé comme
  incident, l'action restant visible comme non annulée — jamais silencieusement oubliée.
- **Une règle à blanc est armée par erreur** : le passage de l'essai à blanc à l'armement est un acte
  explicite, distinct de l'enregistrement de la règle.
- **La période d'essai à blanc dépasse l'historique disponible** : le système indique sur quelle
  durée réelle le décompte porte, plutôt que d'extrapoler.

## Requirements *(mandatory)*

### Functional Requirements

#### Règles d'alerte (J1)

- **FR-001**: Le système DOIT permettre de définir une condition d'alerte **sans écrire de langage de
  requête**, à partir de types de conditions proposés.
- **FR-002**: Une règle créée depuis le produit DOIT être prise en compte par le moteur d'évaluation
  en **moins d'une minute**.
- **FR-003**: Une règle mal formée DOIT être **refusée à la création** avec un motif explicite.
- **FR-004**: Une règle DOIT porter une **gravité**, déterminant son routage de notification.
- **FR-005**: L'état d'une règle DOIT suivre la machine à états normative : inactive → en attente →
  déclenchée → résolue.

#### Actions automatiques (J1 — Art. 15)

- **FR-006**: Une règle DOIT pouvoir être assortie d'une **action automatique**.
- **FR-007**: Les actions automatiques DOIVENT se limiter à des opérations **réversibles** :
  ralentir la lane des agents, suspendre la lane batch, réduire la puissance des cartes. **Aucune
  action destructive ou difficilement réversible NE DOIT être disponible en automatique.**
- **FR-008**: Une action automatique NE DOIT **jamais** s'appliquer à la lane interactive, qui garde
  sa préséance (Art. 2).
- **FR-009**: Toute action automatique exécutée DOIT être **inscrite au journal d'audit** (Art. 4).
- **FR-010**: À la **résolution** de la condition, l'action DOIT être **annulée automatiquement**,
  et cette annulation tracée.
- **FR-011**: L'état d'une action DOIT suivre la machine à états normative : armée → exécutée →
  annulée.
- **FR-012**: L'application et l'annulation DOIVENT être protégées contre le **battement** lorsque la
  condition oscille autour du seuil.
- **FR-013**: Au redémarrage du système, les actions armées DOIVENT être **réévaluées** et annulées
  si leur condition n'est plus vraie.
- **FR-014**: Un échec d'annulation DOIT être **signalé comme incident**, l'action restant visible
  comme non annulée.
- **FR-015**: Lorsque plusieurs actions s'appliquent, leur ordre DOIT être **déterministe** et l'état
  résultant cohérent.

#### Essai à blanc (J1)

- **FR-016**: Le système DOIT permettre d'exécuter une règle **à blanc**, indiquant **combien de fois
  elle se serait déclenchée sur les 7 derniers jours**, **sans agir**.
- **FR-017**: Si l'historique disponible est plus court que la période demandée, le système DOIT
  indiquer la **durée réelle** couverte, sans extrapoler.
- **FR-018**: Le passage de l'essai à blanc à l'armement DOIT être un **acte explicite**, distinct de
  l'enregistrement de la règle (Art. 3).

#### Hub et carte de charge (J2)

- **FR-019**: Le hub DOIT présenter les **quantiles de latence** (premier jeton et inter-jetons),
  l'occupation des **niveaux de mémoire** et l'**état des cibles de collecte**.
- **FR-020**: Le système DOIT afficher une **bannière en direct** à l'apparition d'une alerte, et la
  retirer à sa résolution.
- **FR-021**: Le système DOIT présenter une **carte de charge par modèle et par heure**, permettant
  d'identifier les périodes creuses.
- **FR-022**: Une case de la carte de charge DOIT permettre d'**accéder aux requêtes**
  correspondantes.
- **FR-023**: Le hub DOIT lire **la source unique de métriques** du projet — **aucune** seconde
  chaîne de mesure (Art. 19).

#### Preuves (J3)

- **FR-024**: Le délai de prise en compte d'une règle, l'exécution puis l'annulation d'une action, et
  l'exactitude de l'essai à blanc DOIVENT être prouvés par des tests dédiés.

### Hors périmètre *(Art. 20 — YAGNI)*

- La **collecte** des métriques, leur conservation et les tableaux de bord provisionnés → **S02**.
  S15 **lit** cette source et y ajoute des règles ; il ne collecte rien.
- Le **routage** des notifications vers les destinataires → **S02**. S15 fixe la gravité ; S02
  achemine.
- Les **leviers** eux-mêmes — ordonnancement des lanes, cession, drainage, limite de puissance →
  **S05**, **S06**. S15 les **actionne** au travers de leur contrat, il ne les implémente pas.
- La **trace par requête** et l'accès aux journaux détaillés → **S14**. S15 y **renvoie** depuis la
  carte de charge.
- La **planification** des traitements en heures creuses → **S18**, qui **consomme** la carte de
  charge.
- La **coquille d'interface** → **S11**.
- Le **journal d'audit** lui-même → **S13**. S15 y **émet** ses entrées.

### Key Entities

- **Règle d'alerte** : condition évaluée périodiquement, portant une gravité et éventuellement une
  action. États : inactive → en attente → déclenchée → résolue, avec l'issue **essai à blanc**.
- **Action automatique** : opération **réversible** déclenchée par une règle. États : armée →
  exécutée → annulée. Limitée aux leviers non destructifs.
- **Carte de charge** : représentation de la charge par modèle et par heure, servant à identifier les
  périodes creuses.
- **Quantile de latence** : indicateur de distribution des temps de réponse, lu depuis la source
  unique de métriques. Rattaché à l'arbre de l'observation de la taxonomie.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Une règle créée depuis le produit est évaluée par le moteur
  **moins d'une minute** après son enregistrement.
- **SC-002** *(critère A2)*: Une action automatique est **exécutée** au déclenchement puis
  **annulée** à la résolution, dans **100 %** des cas — les deux transitions étant tracées.
- **SC-003** *(critère A3)*: Un essai à blanc rapporte le **nombre exact** de déclenchements qui
  auraient eu lieu sur la période, **sans qu'aucune action ne soit appliquée**.
- **SC-004**: **Zéro** action destructive ou difficilement réversible disponible en automatique —
  vérifié par revue de l'inventaire des actions.
- **SC-005**: **Zéro** action automatique appliquée à la lane interactive.
- **SC-006**: **100 %** des exécutions et annulations d'action sont retrouvables dans le journal
  d'audit.
- **SC-007**: Une condition oscillant autour du seuil ne provoque **pas** d'application/annulation en
  boucle.
- **SC-008**: Après un redémarrage, **aucune** action ne reste appliquée alors que sa condition n'est
  plus vraie.
- **SC-009**: Un échec d'annulation est **signalé** — **zéro** action silencieusement laissée
  appliquée.
- **SC-010**: Le hub ne constitue **aucune** seconde chaîne de mesure : toutes ses valeurs proviennent
  de la source unique — vérifié par inspection.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9t) |
| --- | --- | --- |
| A1 — règle évaluée en moins d'une minute | SC-001 | T10 `[TEST]` délai · T2 création + prise en compte |
| A2 — action déclenchée puis annulée | SC-002, SC-005, SC-006, SC-008, SC-009 | T10 `[TEST]` action + annulation · T9 `[INT]` actions → ordonnanceur et superviseur |
| A3 — essai à blanc sur 7 jours | SC-003 | T11 `[TEST]` essai à blanc |
| Aucune action destructive | SC-004 | T3 exécuteur d'actions + annulation |
| Protection contre le battement | SC-007 | T3 exécuteur d'actions |
| Source unique de métriques | SC-010 | T6 hub |

## Assumptions

- **Dépendances** : S02 fournit la **source unique de métriques** et le routage des notifications ;
  S11 fournit la **coquille d'interface** et le canal temps réel. S15 n'ajoute ni collecte, ni
  transport de notification, ni infrastructure d'interface.
- **Application de l'Art. 15** : cette spec est le principal lieu d'application des « boucles
  agentiques bornées ». Les trois garde-fous exigés par l'article y sont explicitement instanciés :
  **condition d'arrêt** (l'annulation automatique à la résolution, FR-010), **journalisation pour
  l'audit** (FR-009), et **aucune opération destructive sans autorisation préalable capturée dans la
  spec** (FR-007 — l'inventaire des actions autorisées **est** cette autorisation).
- **Les leviers appartiennent à d'autres specs** : ralentir une lane, la suspendre, réduire la
  puissance des cartes sont des capacités de S05 et S06. S15 les actionne au travers de leur contrat
  (Art. 18) — c'est ce qui permet d'ajouter un levier sans modifier l'exécuteur d'actions.
- **La lane interactive est intouchable** : l'Art. 2 donne la préséance absolue aux humains qui
  attendent. Le document décrit les actions sur les lanes agents et batch uniquement ; la spec en
  fait une interdiction explicite (FR-008, SC-005).
- **Protection contre le battement ajoutée** : le document ne la mentionne pas, mais une action
  appliquée et annulée en boucle autour d'un seuil est le mode de défaillance classique de ce
  mécanisme, et contredirait la « cadence de contrôle » de l'Art. 15.
- **Période d'essai à blanc de 7 jours** : valeur fixée par le document et cohérente avec la
  conservation des métriques (90 jours), donc toujours disponible en régime établi. Le cas d'un
  historique plus court est traité (FR-017).
- **État de l'art consigné (Art. 22)** : le hub interne et la carte de charge s'inspirent d'outils
  d'exploitation existants pour GPU, dont le document cite la référence. Ce qui est **retenu** : la
  lecture par quantiles et la carte modèle × heure. Ce qui est **écarté** : la constitution d'une
  seconde chaîne de métriques propre au hub, qui violerait l'Art. 19. Les références nominatives sont
  consignées dans le plan.
- **Jalon M3** : la spec est **complète à M3**, en même temps que la complétion de S14 dont elle
  utilise l'accès aux requêtes depuis la carte de charge.
