# Feature Specification: S02 — Observabilité de base

**Feature Branch**: `002-observabilite-de-base`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9g du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S02 du plan de specs 9c : « Observabilité de base (Prom + DCGM + Grafana) », références 6e · 5a, dépend de S01, effort ≈ 3 j-agent, phase 1 (socle), jalon produit M0 (Alpha).

## User Scenarios & Testing *(mandatory)*

Les parcours ci-dessous reprennent les jalons internes J1–J2 de la fiche 9g, par profondeur
croissante. J3 (preuves) n'est pas un parcours utilisateur : il fournit la vérification mécanique des
critères d'acceptation.

### User Story 1 - Collecte : toutes les métriques sont captées et conservées 90 jours (Priority: P1)

L'administrateur dispose d'une chaîne de collecte qui interroge périodiquement tous les composants
de la plateforme — plan de contrôle, moteurs d'inférence, matériel GPU et la collecte elle-même — et
conserve l'historique assez longtemps pour analyser une dérive sur un trimestre.

**Why this priority**: c'est la profondeur J1 de la fiche 9g et la raison d'être de la spec :
établir **la source unique de métriques avant tout code métier**. Sans elle, S04, S05 et S15
n'auraient nulle part où publier leurs mesures, et l'Art. 19 (une connaissance, un seul endroit)
serait violé dès la première fonctionnalité.

**Independent Test**: démarrer la plateforme et constater que chaque composant attendu apparaît
comme cible interrogée avec succès, que le matériel GPU expose ses mesures par carte, et que la durée
de conservation configurée est bien celle attendue — sans qu'aucun tableau de bord existe encore.

**Acceptance Scenarios**:

1. **Given** la plateforme démarrée, **When** l'administrateur consulte l'état des cibles de
   collecte, **Then** **toutes** les cibles déclarées (plan de contrôle, moteurs d'inférence,
   exportateur matériel GPU, et la collecte elle-même) sont à l'état « joignable ».
2. **Given** la machine de référence à 4 GPUs, **When** la collecte interroge l'exportateur matériel,
   **Then** les mesures de température, de puissance et de mémoire vidéo sont disponibles
   **par carte**, pour les 4 cartes.
3. **Given** la chaîne de collecte configurée, **When** l'administrateur inspecte la fréquence
   d'interrogation, **Then** le matériel GPU est interrogé à une cadence plus fine (1 seconde) que
   les autres composants (5 secondes), afin de capter les pics thermiques et de puissance.
4. **Given** des mesures collectées depuis plus de 90 jours, **When** l'administrateur interroge
   l'historique, **Then** les données des 90 derniers jours sont disponibles et les plus anciennes
   ont été purgées.
5. **Given** la plateforme arrêtée puis redémarrée, **When** l'administrateur interroge l'historique,
   **Then** les mesures collectées avant l'arrêt sont toujours présentes (stockage persistant).

---

### User Story 2 - Surface : tableaux de bord provisionnés et alertes routées (Priority: P2)

L'administrateur ouvre l'outil de visualisation et y trouve, sans avoir rien créé à la main, les
tableaux de bord du matériel GPU et des moteurs d'inférence ; les alertes déclenchées partent vers
les destinataires configurés.

**Why this priority**: c'est la profondeur J2. Elle rend la collecte exploitable par un humain et
prépare la surface sur laquelle S15 (hub d'observabilité, éditeur de règles, heatmap) viendra se
poser. Elle est vérifiable seule dès que J1 existe.

**Independent Test**: repartir d'un stockage de visualisation vide, démarrer la plateforme, et
constater que les tableaux de bord attendus sont présents et alimentés — sans aucune action manuelle
dans l'interface de visualisation.

**Acceptance Scenarios**:

1. **Given** un stockage de visualisation vide, **When** la plateforme démarre, **Then** la source de
   données et les tableaux de bord sont créés automatiquement à partir des définitions versionnées
   dans le dépôt.
2. **Given** les tableaux de bord provisionnés, **When** l'administrateur ouvre le tableau de bord
   matériel, **Then** il voit par carte la température, la puissance consommée et l'occupation de la
   mémoire vidéo.
3. **Given** les tableaux de bord provisionnés, **When** l'administrateur ouvre le tableau de bord
   des moteurs, **Then** il voit la latence du premier jeton, la latence inter-jetons et la
   profondeur des files.
4. **Given** un tableau de bord modifié à la main dans l'interface de visualisation, **When** la
   plateforme redémarre, **Then** la définition versionnée du dépôt fait autorité et la modification
   manuelle ne survit pas — le dépôt est la source unique (Art. 19).
5. **Given** une alerte qui se déclenche, **When** la chaîne de routage la traite, **Then** elle est
   acheminée vers les destinataires configurés (point de terminaison sortant signé et courriel)
   selon sa gravité, avec un contenu lisible issu d'un gabarit versionné.

---

### Edge Cases

- **Une cible de collecte est injoignable** (composant arrêté ou non encore construit) : elle
  apparaît explicitement en échec dans l'état des cibles, avec la raison ; la collecte des autres
  cibles n'est pas interrompue.
- **L'exportateur matériel GPU ne trouve aucune carte** (pilote absent, machine sans GPU) : la cible
  est signalée en échec sans faire échouer le reste de la chaîne — utile pour les machines de
  développement.
- **Le volume de stockage des métriques est plein** : la situation est signalée comme une alerte, et
  la purge par ancienneté s'applique — la collecte ne s'arrête pas silencieusement.
- **Une définition de tableau de bord versionnée est invalide** : le provisionnement signale l'erreur
  en nommant le fichier fautif, et les autres tableaux de bord sont tout de même chargés.
- **Un libellé de métrique porterait une valeur à cardinalité libre** (identifiant de requête, texte
  saisi par un utilisateur, adresse) : la métrique est refusée — seuls des identifiants stables sont
  admis comme libellés (Art. 1, Art. 5).
- **Le destinataire d'alerte est injoignable** : l'échec d'acheminement est lui-même observable et ne
  fait pas disparaître l'alerte.

## Requirements *(mandatory)*

### Functional Requirements

#### Collecte et conservation (J1)

- **FR-001**: Le système DOIT interroger périodiquement, comme cibles déclarées, le plan de contrôle,
  chaque moteur d'inférence, l'exportateur de métriques matérielles GPU, et la chaîne de collecte
  elle-même.
- **FR-002**: Le système DOIT exposer un état consultable de toutes les cibles, indiquant pour
  chacune si la dernière interrogation a réussi et, sinon, la raison de l'échec.
- **FR-003**: Le système DOIT interroger l'exportateur matériel GPU à une cadence de 1 seconde et les
  autres cibles à une cadence de 5 secondes.
- **FR-004**: Le système DOIT exposer, pour chacune des cartes GPU, sa température, sa puissance
  consommée et l'occupation de sa mémoire vidéo.
- **FR-005**: Le système DOIT conserver l'historique des mesures pendant **90 jours** et purger
  automatiquement au-delà.
- **FR-006**: L'historique des mesures DOIT être stocké de façon persistante et survivre à l'arrêt et
  au redémarrage de la plateforme.

#### Source unique et nommage (transverse, Art. 12 · Art. 19)

- **FR-007**: La chaîne de collecte DOIT être **l'unique source de métriques** de la plateforme :
  aucun composant ne constitue une seconde chaîne parallèle de mesure.
- **FR-008**: Toute métrique propre à la plateforme DOIT suivre la convention de nommage
  `quadra_<entité>_<mesure>_<unité>`, où l'entité provient de la taxonomie du domaine.
- **FR-009**: Les métriques exposées nativement par les moteurs d'inférence upstream DOIVENT être
  réexposées **telles quelles**, sans renommage ni réécriture (Art. 6).
- **FR-010**: Les libellés de métriques NE DOIVENT contenir que des identifiants stables et de
  cardinalité bornée (lane, alias, node, host, identifiant de clé). Aucune donnée personnelle, aucun
  contenu de prompt et aucune valeur à cardinalité libre NE DOIT apparaître dans un libellé (Art. 1).

#### Tableaux de bord provisionnés (J2)

- **FR-011**: Le système DOIT créer automatiquement, au démarrage, la source de données et les
  tableaux de bord à partir de définitions versionnées dans le dépôt.
- **FR-012**: Aucun tableau de bord NE DOIT être créé ou modifié à la main dans l'interface de
  visualisation : la définition versionnée fait autorité et est réappliquée au démarrage.
- **FR-013**: Le système DOIT fournir un tableau de bord matériel présentant, par carte GPU,
  température, puissance et mémoire vidéo.
- **FR-014**: Le système DOIT fournir un tableau de bord des moteurs présentant la latence du premier
  jeton, la latence inter-jetons et la profondeur des files.
- **FR-015**: Les définitions de tableaux de bord DOIVENT être nommées par domaine, selon la
  convention de nommage du projet, et versionnées dans le dépôt.

#### Routage des alertes (J2)

- **FR-016**: Le système DOIT acheminer les alertes déclenchées vers les destinataires configurés —
  point de terminaison sortant et courriel — selon la gravité de l'alerte.
- **FR-017**: Le contenu des notifications DOIT être produit à partir de gabarits versionnés dans le
  dépôt.
- **FR-018**: L'échec d'acheminement d'une notification DOIT lui-même être observable et ne DOIT pas
  faire disparaître l'alerte sous-jacente.

#### Preuves (J3)

- **FR-019**: Le système DOIT être vérifiable par une procédure automatisée prouvant simultanément
  que toutes les cibles sont joignables, que les tableaux de bord attendus sont chargés, et que la
  durée de conservation est celle exigée.

### Hors périmètre *(Art. 20 — YAGNI)*

- Le hub d'observabilité interne, l'éditeur de règles d'alerte, les actions automatiques réversibles
  et la heatmap de charge → **S15**. S02 pose la collecte et le routage ; S15 pose l'interface et les
  règles.
- L'émission des métriques métier (requêtes, jetons, lanes, budgets) → **S04**, **S05**, **S08** :
  S02 déclare comment on collecte et comment on nomme, chaque spec émettant ses propres mesures.
- Les traces par requête et la rétention des prompts → **S14**.
- La vue de santé agrégée et les diagnostics → **S21**.
- Le démarrage des conteneurs d'observabilité et l'exposition réseau → **S01**.

### Key Entities

- **Cible de collecte** : composant interrogé périodiquement. Attributs : nom du travail de collecte,
  cadence d'interrogation, dernier état (joignable / en échec), raison de l'échec.
- **Métrique** : mesure nommée selon la convention du domaine, porteuse de libellés à cardinalité
  bornée. Rattachée à l'arbre de l'observation de la taxonomie (Metric → Dashboard / Alert rule /
  Audit entry).
- **Tableau de bord** : définition versionnée dans le dépôt, provisionnée automatiquement, nommée par
  domaine.
- **Route de notification** : correspondance entre la gravité d'une alerte et ses destinataires
  (point de terminaison sortant, courriel), avec son gabarit de message.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: **100 % des cibles déclarées** apparaissent à l'état
  « joignable » dans l'état des cibles, sur une plateforme fraîchement démarrée.
- **SC-002** *(critère A2)*: Sur un stockage de visualisation vide, les tableaux de bord matériel et
  moteurs sont présents et alimentés **sans aucune action manuelle**, à l'issue du démarrage.
- **SC-003** *(critère A3)*: La durée de conservation effective des mesures est de **90 jours** :
  une mesure de 89 jours est lisible, une mesure de 91 jours ne l'est plus.
- **SC-004**: Les 4 cartes GPU exposent chacune température, puissance et mémoire vidéo, rafraîchies
  au moins **une fois par seconde**.
- **SC-005**: Une modification manuelle d'un tableau de bord ne survit pas au redémarrage :
  **100 %** des tableaux de bord correspondent à leur définition versionnée après démarrage.
- **SC-006**: Un contrôle automatisé des libellés de métriques ne trouve **aucune** donnée
  personnelle ni valeur à cardinalité libre.
- **SC-007**: Une alerte déclenchée atteint ses destinataires configurés, et un échec
  d'acheminement est lui-même visible dans l'état de la plateforme.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9g) |
| --- | --- | --- |
| A1 — tous les targets up | SC-001, SC-004 | T8 `[TEST]` targets · T7 `[INT]` scrape du plan de contrôle (S01) |
| A2 — dashboards importés automatiquement | SC-002, SC-005 | T8 `[TEST]` dashboards |
| A3 — rétention 90 j configurée | SC-003 | T8 `[TEST]` rétention |
| Consignes (labels = ids, jamais de PII) | SC-006 | T1 configuration des travaux de collecte + contrôle de libellés |
| Routage des alertes | SC-007 | T5 routes + gabarits |

## Assumptions

- **Dépendance à S01** : les conteneurs d'observabilité (collecte, routage d'alertes, visualisation,
  exportateur matériel) sont démarrés par le socle S01 et joignables sur le réseau interne. S02 les
  **configure**, il ne les déploie pas.
- **Aucune métrique métier n'existe encore à M0** : au jalon M0, les seules cibles réellement
  peuplées sont l'exportateur matériel, les moteurs d'inférence et la santé du plan de contrôle. Les
  familles de métriques métier (requêtes, jetons, lanes, budgets) sont déclarées par leurs specs
  respectives et collectées par la présente chaîne dès qu'elles apparaissent.
- **Aucune télémétrie sortante** : les métriques ne quittent jamais l'infrastructure ; les seuls flux
  sortants admis sont les notifications d'alerte vers les destinataires internes configurés (Art. 1).
- **Matériel de référence** : 4 cartes GPU de 24 Go sur une machine unique. Le multi-machines
  (libellé `host`, métrique de disponibilité par hôte) est prévu par la convention de nommage mais
  n'est exercé qu'à partir de S19.
- **Cadences retenues** : 1 seconde pour le matériel GPU, 5 secondes pour les autres cibles — valeurs
  fixées par le déploiement de référence du document (5b).
- **Conservation** : 90 jours pour les métriques. Les autres rétentions du projet (requêtes
  24 mois, prompts 30 j, audit 2 ans, résultats de jobs 7 j) relèvent des specs qui portent ces
  données.
