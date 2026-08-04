# Feature Specification: S05 — Scheduler lanes P0/P1/P2 + caps

**Feature Branch**: `005-scheduler-lanes-caps`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9j du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S05 du plan de specs 9c : « Scheduler lanes P0/P1/P2 + caps par clé », références 6c · W1 · W12, dépend de S04, effort ≈ 7 j-agent, phase 2 (cœur runtime), jalon produit M1 (MVP interne).

## User Scenarios & Testing *(mandatory)*

Les parcours ci-dessous reprennent les jalons internes J1–J3 de la fiche 9j, par profondeur
croissante. Cette spec est l'**exécution technique de l'Art. 2** : elle est le mécanisme qui garantit
qu'aucun agent ni aucun batch ne dégrade l'expérience d'un humain qui attend une réponse.

### User Story 1 - Fondations : les trois lanes existent et l'admission est cadrée (Priority: P1)

L'administrateur dispose de trois lanes d'ordonnancement — interactive, agents, batch — chacune
configurée. Chaque requête entrante est affectée à une lane de façon déterministe, et une requête
qui arrive sur une lane saturée est refusée proprement plutôt que d'attendre indéfiniment.

**Why this priority**: c'est la profondeur J1 de la fiche 9j. Sans lanes matérialisées ni règle
d'affectation, l'arbitrage de J2 n'a rien à arbitrer. C'est aussi la tranche qui rend le vocabulaire
du domaine exécutable : la lane est une entité, pas une étiquette.

**Independent Test**: soumettre des requêtes portées par des clés de lanes différentes et constater
que chacune rejoint la lane attendue ; saturer une lane et constater que les requêtes excédentaires
sont refusées avec un motif explicite, sans attente indéfinie.

**Acceptance Scenarios**:

1. **Given** le système configuré, **When** l'administrateur inspecte l'ordonnanceur, **Then** les
   **trois lanes** existent : interactive (P0), agents (P1) et batch (P2), chacune avec sa
   configuration propre.
2. **Given** une clé portant une lane par défaut, **When** une requête est soumise avec cette clé,
   **Then** elle est affectée à la lane de la clé.
3. **Given** une requête qui demande explicitement une lane, **When** elle est soumise, **Then** la
   lane demandée **surcharge** la lane par défaut de la clé, dans les limites autorisées à cette clé.
4. **Given** une lane dont la file est pleine, **When** une requête supplémentaire s'y présente,
   **Then** elle est **refusée immédiatement** avec un motif explicite — elle n'est jamais mise en
   attente sans borne.
5. **Given** une requête admise, **When** elle progresse, **Then** son état suit la machine à états
   normative : en file → ordonnancée → préremplissage → décodage → terminée, avec les issues
   refusée, annulée ou échouée.

---

### User Story 2 - Cœur : le chat passe devant le batch, l'agent reste cadré (Priority: P2)

Un membre de l'équipe pose une question dans le chat pendant qu'un agent sature la lane agents et
qu'un traitement par lot occupe la lane batch. Sa requête passe devant. L'agent, lui, ne peut pas
dépasser le cap de concurrence de sa clé, quel que soit le volume qu'il soumet.

**Why this priority**: c'est la profondeur J2 et la raison d'être de la spec — « personne n'affame
personne ». C'est la **preuve exécutable de l'Art. 2**, et le critère de sortie du jalon M1
(« k6 burst sans starvation P0 »).

**Independent Test**: lancer une rafale saturant la lane agents et un traitement continu sur la lane
batch, puis mesurer le temps d'attente des requêtes interactives — il doit rester sous le seuil quel
que soit le volume concurrent.

**Acceptance Scenarios**:

1. **Given** les lanes agents et batch saturées, **When** une requête interactive arrive, **Then**
   elle est servie **avant** toute requête agents ou batch en attente.
2. **Given** un agent qui soumet un volume supérieur au cap de concurrence de sa clé, **When** ses
   requêtes sont ordonnancées, **Then** le nombre de ses requêtes simultanément en exécution
   n'excède **jamais** son cap — les autres attendent dans sa lane.
3. **Given** une requête batch en cours d'exécution, **When** une requête interactive se présente et
   qu'aucune ressource n'est libre, **Then** la lane batch **cède** la ressource au profit de la lane
   interactive.
4. **Given** une charge soutenue sur la lane agents, **When** on observe la lane batch sur la durée,
   **Then** celle-ci **progresse tout de même** : la préséance des lanes supérieures ne conduit pas à
   un blocage définitif du batch.
5. **Given** une requête en attente dans une file, **When** elle est annulée, **Then** elle est
   retirée de la file et ne sera jamais exécutée.
6. **Given** une requête déjà en cours d'exécution, **When** elle est annulée, **Then** l'annulation
   est propagée jusqu'à son exécution effective — elle ne se poursuit pas dans le vide.
7. **Given** une décision d'ordonnancement quelconque, **When** elle est prise, **Then** elle est
   journalisée à un niveau de détail permettant de reconstituer *a posteriori* pourquoi telle requête
   est passée avant telle autre.

---

### User Story 3 - Surface : l'opérateur voit les files et les positions en direct (Priority: P3)

L'opérateur observe l'état des trois lanes en temps réel : profondeur de chaque file, position de
chaque requête vivante, temps d'attente — sans jamais rafraîchir manuellement ni interroger en
boucle.

**Why this priority**: c'est la profondeur J3. Elle rend l'ordonnancement observable, condition de
la vue « file d'attente » de l'interface d'administration (S11) et du diagnostic d'incident. Elle est
vérifiable seule dès que J2 existe.

**Independent Test**: ouvrir un canal temps réel, soumettre des requêtes, et constater que la
profondeur des files et les positions sont poussées spontanément à chaque changement, sans aucune
interrogation répétée du client.

**Acceptance Scenarios**:

1. **Given** un client abonné au flux temps réel des files, **When** la profondeur d'une lane change,
   **Then** la mise à jour lui est **poussée** — le client n'interroge jamais en boucle.
2. **Given** une requête en attente, **When** sa position dans la file évolue, **Then** la nouvelle
   position est diffusée en temps réel.
3. **Given** le système en fonctionnement, **When** on consulte les mesures, **Then** la
   **profondeur de file par lane** et le **temps d'attente** sont exposés comme métriques du projet.

---

### Edge Cases

- **Une clé demande une lane à laquelle elle n'a pas droit** : la demande est refusée ou ramenée à la
  lane autorisée — le serveur décide, jamais le client (Art. 5).
- **Toutes les lanes sont vides sauf la batch** : le batch consomme toute la ressource disponible —
  la préséance ne signifie pas la réservation.
- **La lane interactive est elle-même saturée** : les requêtes interactives excédentaires sont
  refusées avec un motif explicite plutôt que d'attendre au-delà du seuil de service.
- **Une requête est annulée exactement au moment où elle est ordonnancée** : l'annulation est traitée
  sans laisser d'exécution orpheline ni de compteur de concurrence faussé.
- **La cible d'exécution devient indisponible** (incident matériel, moteur arrêté) : les requêtes
  concernées sont traitées selon leur état — celles non entamées peuvent être réordonnancées, celles
  entamées échouent proprement.
- **Un traitement batch très long occupe la ressource** : le mécanisme de cession doit agir à une
  granularité suffisamment fine pour que l'attente interactive reste sous le seuil, sans attendre la
  fin du traitement long.
- **Deux requêtes de même lane et de même clé arrivent au même instant** : le cap de concurrence est
  respecté exactement, sans condition de course.

## Requirements *(mandatory)*

### Functional Requirements

#### Lanes et admission (J1)

- **FR-001**: Le système DOIT matérialiser **trois lanes** d'ordonnancement : interactive (P0),
  agents (P1) et batch (P2), conformément à l'arbre du trafic de la taxonomie.
- **FR-002**: Le système DOIT affecter chaque requête à une lane de façon **déterministe**, à partir
  de la lane portée par la clé, surchargeable par la requête dans les limites autorisées à cette clé.
- **FR-003**: Le système DOIT refuser une demande de lane à laquelle la clé n'a pas droit, ou la
  ramener à la lane autorisée — la décision appartient au serveur (Art. 5).
- **FR-004**: Le système DOIT appliquer une politique d'admission : une requête arrivant sur une lane
  saturée est **refusée immédiatement** avec un motif explicite, jamais mise en attente sans borne.
- **FR-005**: L'état d'une requête DOIT suivre la machine à états normative du projet, l'issue d'un
  refus d'admission étant l'état « refusée » avec le motif de limitation.

#### Arbitrage, caps et cession (J2)

- **FR-006**: Le système DOIT servir les lanes selon l'ordre de préséance strict **interactive >
  agents > batch**.
- **FR-007**: La lane interactive DOIT **préempter** les autres : une requête interactive ne peut pas
  être retardée par une requête agents ou batch en attente (Art. 2).
- **FR-008**: Le système DOIT respecter le **cap de concurrence par clé** à **zéro dépassement
  près**, y compris lorsque plusieurs requêtes de la même clé arrivent simultanément.
- **FR-009**: La lane batch DOIT **céder** la ressource lorsqu'une lane supérieure a du travail en
  attente, à une granularité suffisamment fine pour que le seuil d'attente interactive soit tenu.
- **FR-010**: Le système DOIT garantir que la lane batch **progresse malgré tout** sous charge
  soutenue des lanes supérieures : la préséance ne DOIT pas produire de blocage définitif.
- **FR-011**: Le système DOIT permettre d'**annuler** une requête, qu'elle soit **en file** (retrait
  immédiat) ou **en cours d'exécution** (propagation de l'annulation jusqu'à l'exécution effective).
- **FR-012**: Toute décision d'ordonnancement DOIT être **journalisée** à un niveau de détail
  permettant de reconstituer *a posteriori* l'ordre de service et son motif.

#### Découplage (transverse, Art. 18)

- **FR-013**: L'ordonnanceur NE DOIT **pas** connaître les moteurs d'inférence : il s'adresse à un
  **routeur** au travers d'un contrat, sans référence à une implémentation de moteur.

#### Observabilité temps réel (J3)

- **FR-014**: Le système DOIT **pousser** en temps réel, sur un canal d'abonnement, la profondeur des
  files et la position des requêtes en attente. Le client NE DOIT **jamais** interroger en boucle.
- **FR-015**: Le système DOIT exposer, comme métriques du projet, la **profondeur de file par lane**
  et le **temps d'attente**, nommées selon la convention du projet.

#### Preuves (J4)

- **FR-016**: L'absence de famine de la lane interactive DOIT être prouvée par un test de charge
  saturant la lane agents, exécuté contre le moteur factice.
- **FR-017**: Le respect exact du cap de concurrence et la diffusion des positions DOIVENT être
  prouvés par des tests dédiés.

### Hors périmètre *(Art. 20 — YAGNI)*

- L'**authentification**, les limites de débit et les budgets → **S04**. S05 reçoit une requête déjà
  authentifiée et autorisée, porteuse de sa lane et de son cap.
- Le **choix de l'instance d'exécution**, le hot-swap et le placement → **S06**, **S07**. S05
  s'adresse au routeur (Art. 18).
- La **vue d'interface** de la file d'attente → **S11**. S05 émet les événements ; S11 les affiche.
- Les **jobs par lot**, leur planification en heures creuses et l'offload → **S18**. S05 fournit la
  lane batch et son mécanisme de cession, dont S18 dépend.
- Les **actions automatiques** d'alerte (mise en pause de la lane batch, throttle de la lane agents)
  → **S15**. S05 expose les leviers ; S15 décide de les actionner.
- L'**enregistrement comptable** des requêtes → **S08**.

### Key Entities

- **Lane** : file d'ordonnancement. Trois valeurs normatives : interactive (P0), agents (P1), batch
  (P2). Attributs : rang de préséance, capacité d'admission, politique de cession. *Terme normatif —
  « priorité », « queue class » et « tier » sont des synonymes interdits (Art. 12).*
- **Entrée de file** : requête en attente dans une lane. Attributs : position, temps d'attente
  écoulé, clé propriétaire, état.
- **Cap de concurrence** : nombre maximal de requêtes d'une même clé simultanément en exécution.
  *Terme réservé à la concurrence — ne désigne jamais un budget ni un quota de débit.*
- **Décision d'ordonnancement** : choix de servir une requête plutôt qu'une autre, journalisé avec
  son motif.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Pendant qu'un agent sature la lane agents, le temps
  d'attente des requêtes interactives reste **sous 200 ms au 95ᵉ centile**.
- **SC-002** *(critère A2)*: Le cap de concurrence par clé est respecté à **±0** : sous rafale
  simultanée, le nombre de requêtes en exécution pour une clé n'excède **jamais** son cap.
- **SC-003** *(critère A3)*: La position d'une requête en file et la profondeur de chaque lane sont
  **poussées en temps réel** ; un client observateur ne réalise **aucune** interrogation répétée.
- **SC-004**: Sous charge soutenue des lanes supérieures, la lane batch **progresse** : son débit
  mesuré sur une fenêtre longue est strictement supérieur à zéro.
- **SC-005**: Une requête annulée en file n'est **jamais** exécutée ; une requête annulée en cours
  d'exécution voit son exécution réellement interrompue — **100 %** des cas.
- **SC-006**: Une requête arrivant sur une lane saturée est refusée en **moins d'une seconde** avec
  un motif explicite, sans attente non bornée.
- **SC-007**: À partir des seules traces d'ordonnancement, un opérateur peut **reconstituer l'ordre
  de service** d'une séquence de requêtes et le motif de chaque décision.
- **SC-008**: L'ordonnanceur ne comporte **aucune** référence à une implémentation de moteur :
  vérification automatisée des dépendances du module.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9j) |
| --- | --- | --- |
| A1 — attente P0 sous 200 ms p95 pendant saturation P1 | SC-001, SC-004 | T11 `[TEST]` anti-famine sous rafale |
| A2 — cap de concurrence à ±0 | SC-002 | T12 `[TEST]` caps ±0 |
| A3 — position de file visible en temps réel | SC-003 | T12 `[TEST]` positions temps réel |
| Annulation en file et en vol | SC-005 | T7 annulation file + en-vol |
| Admission bornée | SC-006 | T3 admission + rejet file pleine |
| Journalisation des décisions | SC-007 | T4 arbitrage · consigne « chaque décision loggée » |
| Découplage moteur (Art. 18) | SC-008 | T10 `[INT]` gateway → ordonnanceur (S04) |

## Assumptions

- **Dépendance à S04** : l'ordonnanceur reçoit des requêtes **déjà authentifiées et autorisées**,
  porteuses de leur lane, de leur cap de concurrence et de leur identifiant unique. S05 n'accède ni
  aux clés ni aux budgets.
- **Le moteur factice est la cible des tests** : l'anti-famine, la cession et les caps sont prouvés
  contre le moteur simulé de S03 ; aucun GPU n'est sollicité en intégration continue (Art. 8).
- **Trois lanes, pas davantage** : le nombre de lanes est fixé à trois par le document et le
  glossaire normatif. Ajouter une lane serait un amendement de la taxonomie, pas une option de
  configuration (Art. 17).
- **Le seuil de service interactif est de 200 ms au 95ᵉ centile** : valeur fixée par le critère A1
  du document ; c'est la définition opérationnelle de l'Art. 2.
- **La cession du batch est coopérative** : elle s'appuie sur des points de cession suffisamment
  fréquents pour tenir le seuil interactif. Le mécanisme précis relève du plan ; l'exigence est le
  seuil tenu (SC-001), pas la technique.
- **Le routeur est un contrat, pas un composant connu** : à M1, il est fourni par S06/S07. S05 ne
  dépend que de son contrat, ce qui permet de le remplacer sans toucher l'ordonnanceur (Art. 18).
- **La lane batch existe dès M1** mais n'a de consommateur réel qu'à partir de S18 (M3). Elle est
  néanmoins spécifiée et testée dès maintenant, car le mécanisme de cession est indissociable de la
  preuve d'anti-famine.
