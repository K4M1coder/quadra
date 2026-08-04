# Feature Specification: S06 — Superviseur moteurs + nœuds GPU + hot-swap

**Feature Branch**: `006-superviseur-noeuds-hotswap`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9k du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S06 du plan de specs 9c : « Superviseur moteurs + nœuds GPU + hot-swap TTL », références 7e · 7g · W2 · topologie NVLink, dépend de S05, effort ≈ 10.5 j-agent, phase 2 (cœur runtime), jalon produit M1 (MVP interne).

## User Scenarios & Testing *(mandatory)*

Les parcours ci-dessous reprennent les jalons internes J1–J3 de la fiche 9k, par profondeur
croissante. Le superviseur est le **chef d'orchestre local** : il est le seul composant autorisé à
piloter le cycle de vie des moteurs, ce qui en fait le point de passage obligé de toute mutation de
l'arbre d'exécution (Host → Node → Engine → Instance).

### User Story 1 - Détection : le matériel est découvert, jamais déclaré (Priority: P1)

L'administrateur installe la plateforme sans décrire son matériel. Le système découvre seul les
cartes GPU présentes, leur modèle, leur mémoire vidéo et — point critique — **quelles cartes sont
appairées par lien haut débit**.

**Why this priority**: c'est la profondeur J1 de la fiche 9k et le critère A1. Une topologie
déclarée à la main est une topologie fausse tôt ou tard : elle survit à un changement de matériel
sans être mise à jour, et le placement des modèles devient silencieusement erroné. La découverte est
donc une exigence de correction, pas de confort.

**Independent Test**: sur la machine de référence, démarrer le superviseur sans aucun fichier
décrivant le matériel, et constater qu'il rapporte exactement les cartes présentes, leur mémoire
vidéo et les paires appairées réelles.

**Acceptance Scenarios**:

1. **Given** une machine dotée de cartes GPU, **When** le superviseur démarre, **Then** il découvre
   seul chaque carte avec son modèle et sa mémoire vidéo — **aucune** déclaration manuelle n'est
   requise ni acceptée comme source de vérité.
2. **Given** la machine de référence dont les cartes sont appairées deux à deux par lien haut débit,
   **When** le superviseur inspecte la topologie, **Then** il identifie **les paires réelles**, sans
   les supposer à partir des numéros de carte.
3. **Given** une machine dont les cartes ne sont pas appairées, **When** le superviseur inspecte la
   topologie, **Then** il le rapporte correctement plutôt que d'inventer des paires.
4. **Given** une topologie découverte, **When** le matériel change (carte retirée, lien débranché),
   **Then** la découverte suivante reflète le nouvel état.

---

### User Story 2 - Nœuds : je regroupe les GPUs en unités d'inférence validées (Priority: P2)

L'administrateur assemble les cartes disponibles en nœuds — une carte seule, ou une paire appairée —
et crée des nœuds tant qu'il reste des cartes libres. Le système valide chaque création et
l'avertit quand son choix est techniquement défavorable.

**Why this priority**: c'est la profondeur J2. Le nœud est l'unité d'inférence du domaine : sans lui,
il n'y a nulle part où placer un modèle. La validation à la création est ce qui empêche les
configurations silencieusement dégradées.

**Independent Test**: créer successivement un nœud sur une carte libre, un nœud sur une paire
appairée, puis tenter un nœud sur une carte déjà prise et un nœud scindant une paire — et constater
que chaque cas produit la réponse attendue (acceptation, avertissement, ou refus).

**Acceptance Scenarios**:

1. **Given** des cartes libres, **When** l'administrateur crée un nœud, **Then** celui-ci regroupe de
   **1 à 4 cartes** et devient une unité d'inférence utilisable.
2. **Given** une carte déjà affectée à un nœud, **When** l'administrateur tente de l'affecter à un
   second nœud, **Then** la création est **refusée** : une carte n'appartient qu'à un nœud.
3. **Given** une paire de cartes appairées par lien haut débit, **When** l'administrateur crée un
   nœud n'en prenant qu'une seule (**paire scindée**), **Then** le système l'**avertit** de la perte
   de performance, tout en le laissant décider en connaissance de cause (Art. 3).
4. **Given** un nœud dont le nombre de cartes est impair alors que le modèle visé exige un
   parallélisme pair, **When** l'administrateur le crée, **Then** le système l'**avertit** de
   l'incompatibilité prévisible.
5. **Given** des nœuds créés, **When** la plateforme redémarre, **Then** leur définition et leur état
   sont **retrouvés** — la configuration est persistée, pas reconstruite de mémoire.
6. **Given** toutes les cartes affectées, **When** l'administrateur tente de créer un nœud
   supplémentaire, **Then** la création est refusée faute de carte libre.

---

### User Story 3 - Cycle de vie : un modèle non résident arrive seul, un nœud se draine sans casse (Priority: P3)

Un membre de l'équipe demande un modèle qui n'est pas chargé : le système libère la place nécessaire,
démarre le moteur, vérifie qu'il répond, et la requête repart — le tout sans redémarrer le service.
L'administrateur, de son côté, peut retirer un nœud du service sans perdre une seule requête en
cours.

**Why this priority**: c'est la profondeur J3, et elle porte les critères A2 et A3. C'est la promesse
opérationnelle du jalon M1 : « swap < 120 s ». Elle est vérifiable seule dès que J2 existe.

**Independent Test**: demander un modèle non chargé alors que les nœuds sont occupés, et mesurer le
délai jusqu'à la première réponse ; en parallèle, drainer un nœud pendant qu'il sert des requêtes et
vérifier qu'aucune n'échoue.

**Acceptance Scenarios**:

1. **Given** un modèle présent sur disque mais non résident, **When** une requête le demande,
   **Then** le système choisit un nœud compatible, libère la place si nécessaire, démarre le moteur,
   vérifie sa santé, et la requête est servie — **sans redémarrage du service**.
2. **Given** un chargement de modèle en cours, **When** il dépasse **120 secondes**, **Then** la
   requête reçoit une erreur de service indisponible **explicite**, portant le code canonique
   correspondant et une estimation de délai — jamais une attente indéfinie ni une erreur générique.
3. **Given** plusieurs instances résidentes dont certaines inactives, **When** la place manque pour
   en charger une nouvelle, **Then** le système **évince** l'instance inactive depuis le plus
   longtemps au-delà de son délai d'inactivité, en priorité sur les autres.
4. **Given** une instance marquée **épinglée**, **When** la place manque, **Then** elle n'est
   **jamais** évincée, ni par inactivité ni par pression mémoire.
5. **Given** un nœud qui sert des requêtes, **When** l'administrateur le **draine**, **Then** il
   cesse d'accepter de nouvelles requêtes et laisse **se terminer** celles en cours — aucune requête
   n'est perdue.
6. **Given** un moteur qui ne répond pas à sa vérification de santé, **When** le système réessaie,
   **Then** il effectue **au plus trois tentatives** avant de le déclarer arrêté.
7. **Given** une instance quelconque, **When** son état change, **Then** il suit la machine à états
   normative : chargement → prête → en drainage → arrêtée, avec les issues **évincée** (par
   inactivité ou pression) et **défaillante**.
8. **Given** un changement d'état d'instance, **When** il survient, **Then** il est **diffusé en
   temps réel** aux clients abonnés.
9. **Given** une éviction ou un démarrage de moteur, **When** l'opération a lieu, **Then** elle est
   **inscrite au journal d'audit** (Art. 4).

---

### Edge Cases

- **Aucun nœud ne peut accueillir le modèle demandé** (mémoire insuffisante sur toutes les
  configurations) : refus explicite indiquant que le modèle ne tient pas, plutôt qu'une tentative de
  chargement vouée à l'échec.
- **Deux requêtes demandent simultanément deux modèles non résidents** : les chargements sont
  sérialisés ou arbitrés de façon déterministe, sans double éviction ni interblocage.
- **Toutes les instances candidates à l'éviction sont épinglées** : le chargement est refusé avec un
  motif explicite — l'épinglage n'est jamais contourné.
- **Une carte GPU tombe en panne ou surchauffe pendant le service** : le nœud concerné est drainé,
  ses modèles replacés ailleurs s'ils y tiennent, sinon marqués indisponibles ; l'incident est
  observable.
- **Le moteur démarre mais ne devient jamais sain** : après trois tentatives, il est déclaré arrêté
  et la place est rendue — il ne reste pas à occuper une ressource indéfiniment.
- **Le drainage d'un nœud n'aboutit jamais** (une requête ne se termine pas) : un délai maximal de
  drainage est appliqué, au terme duquel la situation est signalée plutôt que laissée en suspens.
- **La plateforme redémarre pendant qu'une instance est en chargement** : au retour, l'état persisté
  est cohérent — aucune instance fantôme n'est comptabilisée comme résidente.
- **Un composant autre que le superviseur tente de piloter un moteur** : c'est un défaut de
  conception — le superviseur est le **seul** point de pilotage (Art. 18).

## Requirements *(mandatory)*

### Functional Requirements

#### Découverte du matériel (J1)

- **FR-001**: Le système DOIT **découvrir** seul les cartes GPU présentes, avec leur modèle et leur
  mémoire vidéo, sans déclaration manuelle.
- **FR-002**: Le système DOIT **découvrir** la topologie d'appairage haut débit entre cartes. Cette
  topologie NE DOIT **jamais** être déclarée ni déduite des numéros de carte.
- **FR-003**: La découverte DOIT refléter l'état réel du matériel à chaque exécution, y compris après
  un changement de configuration matérielle.

#### Nœuds d'inférence (J2)

- **FR-004**: Le système DOIT permettre de regrouper de **1 à 4 cartes** en un **nœud**, unité
  d'inférence du domaine.
- **FR-005**: Le système DOIT **refuser** l'affectation d'une carte déjà rattachée à un autre nœud :
  une carte n'appartient qu'à un seul nœud.
- **FR-006**: Le système DOIT **avertir** l'administrateur lorsqu'une création de nœud **scinde une
  paire** appairée, en explicitant la perte de performance, sans pour autant l'interdire (Art. 3 —
  confirm-and-warn).
- **FR-007**: Le système DOIT **avertir** l'administrateur lorsqu'un nœud comporte un nombre de
  cartes incompatible avec le parallélisme attendu du modèle visé.
- **FR-008**: Le système DOIT **persister** la définition et l'état des nœuds et des instances, et
  les retrouver après redémarrage.
- **FR-009**: Le système DOIT permettre de créer des nœuds **tant qu'il reste des cartes libres**, et
  refuser au-delà.

#### Cycle de vie des moteurs et hot-swap (J3)

- **FR-010**: Le système DOIT charger à la demande un modèle présent sur disque mais non résident,
  **sans redémarrer le service** (hot-swap).
- **FR-011**: Le système DOIT **choisir le nœud** d'accueil d'un modèle en fonction de la mémoire
  vidéo requise et des regroupements configurés.
- **FR-012**: Le système DOIT **évincer** en priorité l'instance inactive depuis le plus longtemps
  au-delà de son délai d'inactivité, lorsque la place manque.
- **FR-013**: Le système NE DOIT **jamais** évincer une instance **épinglée**, ni par inactivité ni
  par pression mémoire.
- **FR-014**: Si aucune place ne peut être libérée, le système DOIT **refuser** le chargement avec un
  motif explicite plutôt que d'évincer une instance protégée.
- **FR-015**: Le système DOIT interrompre un chargement dépassant **120 secondes** et retourner une
  erreur de service indisponible **explicite**, portant le code canonique correspondant et une
  estimation de délai.
- **FR-016**: Le système DOIT permettre de **drainer** un nœud : cesser d'admettre de nouvelles
  requêtes tout en laissant **se terminer** celles en cours, sans perte.
- **FR-017**: Le système DOIT vérifier la santé d'un moteur après démarrage et réessayer **au plus
  trois fois** avant de le déclarer arrêté.
- **FR-018**: L'état d'une instance DOIT suivre la machine à états normative : chargement → prête →
  en drainage → arrêtée, avec les issues **évincée** (inactivité ou pression) et **défaillante**.
- **FR-019**: Le système DOIT libérer la ressource d'un moteur déclaré défaillant — il ne DOIT pas
  rester à occuper un nœud indéfiniment.

#### Autorité exclusive et traçabilité (transverse, Art. 4 · Art. 18)

- **FR-020**: Le superviseur DOIT être le **seul** composant autorisé à piloter le cycle de vie des
  moteurs. Aucun autre composant NE DOIT démarrer, arrêter ou évincer un moteur.
- **FR-021**: Toute **éviction** et tout **démarrage** de moteur DOIVENT être inscrits au journal
  d'audit, avec leur motif.

#### Surface temps réel (J4)

- **FR-022**: Tout changement d'état d'instance DOIT être **diffusé en temps réel** aux clients
  abonnés.

#### Preuves (J4)

- **FR-023**: La découverte de topologie, le délai de hot-swap et l'absence de perte au drainage
  DOIVENT être prouvés par des tests dédiés.

### Hors périmètre *(Art. 20 — YAGNI)*

- Le **contrat de driver** rendant les moteurs interchangeables, les moteurs attachés et le sélecteur
  par modèle → **S07**. S06 pilote un cycle de vie ; S07 en abstrait les implémentations.
- Le **calcul du verdict de tenue mémoire** (fits / tight / won't fit) exposé au catalogue, sa
  calibration et les avertissements de téléchargement → **S09**. S06 **consomme** un verdict de
  tenue ; S09 le produit et le calibre.
- Le **téléchargement** des modèles, la reprise et la vérification d'intégrité → **S10**.
- L'**interface** de placement, la vue des nœuds et la vue des modèles résidents → **S11**.
- L'**ordonnancement** entre lanes et les caps de concurrence → **S05**.
- Le **multi-machines** — agent worker, adhésion au cluster, pilotage distant, réplication —
  → **S19**, **S20**. S06 est **mono-machine** ; son arbre d'exécution s'arrête au nœud local.
- Les **règles d'alerte** et les actions automatiques déclenchées sur incident matériel → **S15**.
  S06 expose le drainage ; S15 décide de le déclencher.

### Key Entities

- **Nœud** : groupe de 1 à 4 cartes GPU d'une machine formant une unité d'inférence, l'appairage se
  faisant par paire. Attributs : cartes affectées, état. *Terme normatif — « device group » et
  « slot » sont des synonymes interdits (Art. 12).*
- **Moteur** : processus servant un ou plusieurs modèles sur un nœud. Attributs : type, état, santé.
- **Instance** : un alias résident sur un nœud, servi par un moteur — l'unité qu'exploite
  l'ordonnanceur. Attributs : modèle, moteur, cartes, état, délai d'inactivité, caractère **épinglé**.
- **Alias** : nom de modèle servi, visible des clients. *Ne se confond pas avec l'instance : un alias
  peut être servi par plusieurs instances (à partir de S20).*
- **Topologie** : ensemble des cartes découvertes et de leurs appairages haut débit. **Découverte,
  jamais déclarée.**

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: La topologie d'appairage rapportée par le système correspond
  à **100 %** à la topologie réelle du matériel, **sans aucun fichier de déclaration** — vérifié en
  comparant à la topologie physique de la machine de référence.
- **SC-002** *(critère A2)*: Un hot-swap complet — libération de place, démarrage du moteur,
  vérification de santé, reprise de la requête — s'achève en **moins de 120 secondes** ; au-delà, le
  client reçoit une erreur explicite avec code canonique et estimation de délai dans **100 %** des
  cas.
- **SC-003** *(critère A3)*: Le drainage d'un nœud servant des requêtes se solde par **zéro requête
  perdue** : toutes les requêtes en cours aboutissent.
- **SC-004**: Une instance épinglée survit à **100 %** des cycles d'éviction, quelle qu'en soit la
  cause.
- **SC-005**: Une carte GPU n'est jamais affectée à plus d'un nœud : **zéro** double affectation sur
  l'ensemble des tentatives de création.
- **SC-006**: Toute création de nœud scindant une paire appairée produit un **avertissement explicite**
  avant validation — **100 %** des cas.
- **SC-007**: Après redémarrage de la plateforme, la configuration des nœuds et l'état des instances
  sont restaurés **à l'identique** ; aucune instance fantôme n'est comptabilisée comme résidente.
- **SC-008**: Un moteur qui ne devient jamais sain est déclaré arrêté après **au plus 3 tentatives**,
  et sa ressource est **rendue**.
- **SC-009**: **100 %** des évictions et démarrages de moteur sont retrouvables dans le journal
  d'audit avec leur motif.
- **SC-010**: Une inspection automatisée confirme qu'**aucun** composant autre que le superviseur ne
  pilote le cycle de vie des moteurs.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9k) |
| --- | --- | --- |
| A1 — topologie détectée, jamais déclarée | SC-001 | T13 `[TEST]` topologie |
| A2 — hot-swap < 120 s sinon erreur explicite | SC-002, SC-008 | T13 `[TEST]` swap < 120 s · T12 `[INT]` ordonnanceur → swap |
| A3 — drain sans perte de requête | SC-003 | T13 `[TEST]` drainage |
| Épinglage jamais contourné | SC-004 | T8 éviction par inactivité, épinglés exclus |
| Validation de création de nœud | SC-005, SC-006 | T4 validation de création |
| Persistance de l'état | SC-007 | T3 modèle de nœuds + migrations |
| Audit des évictions et démarrages | SC-009 | T11 diffusion d'état + audit |
| Autorité exclusive du superviseur | SC-010 | T5–T6 pilotage du cycle de vie |

## Assumptions

- **Dépendance à S05** : le superviseur est sollicité par l'ordonnanceur au travers d'un contrat de
  routage. Il ne connaît ni les lanes, ni les clés, ni les budgets.
- **Mono-machine à ce stade** : l'arbre d'exécution s'arrête au nœud **local**. La notion d'hôte
  distant, l'adhésion au cluster et le pilotage à distance relèvent de S19 — mais le modèle de
  données est conçu pour les accueillir sans refonte (un nœud appartiendra à un hôte).
- **Matériel de référence** : 4 cartes de 24 Go, appairées 0↔1 et 2↔3, limite de puissance 280 W.
  L'appairage **par paire** est une propriété du matériel de référence, pas une hypothèse du logiciel :
  la découverte doit rapporter ce qui existe réellement.
- **Le verdict de tenue mémoire est consommé, pas produit** : S06 place selon un verdict de tenue
  fourni ; sa **calibration** sur des modèles mesurés appartient à S09. À M1, un calcul de tenue
  interne suffit au placement ; il est remplacé par celui de S09 à M2 sans changer le contrat.
- **Délai de hot-swap de 120 secondes** : valeur fixée par le document (W2, critère A2). Elle est le
  seuil au-delà duquel l'attente devient une panne du point de vue du client.
- **Trois tentatives de vérification de santé** : valeur fixée par la machine à états normative
  (10d).
- **Les tests s'exécutent contre le moteur factice** : le cycle de vie, l'éviction et le drainage sont
  prouvés sans GPU en intégration continue (Art. 8) ; la découverte de topologie est la seule partie
  qui exige du matériel réel, et n'est donc vérifiée qu'au canari.
- **Épinglage = décision administrateur explicite** : aucune instance n'est épinglée par défaut ;
  l'épinglage est un choix conscient, conforme à l'Art. 3.
