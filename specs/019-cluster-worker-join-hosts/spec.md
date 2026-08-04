# Feature Specification: S19 — Mode cluster : adhésion d'un worker, détection, vue des hôtes

**Feature Branch**: `019-cluster-worker-join-hosts`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9x du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S19 du plan de specs 9c : « Mode cluster : worker join, détection GPU/NVLink, vue hosts », références 2b · 7g · W13 · W14, dépend de S06, effort ≈ 9 j-agent, phase 6 (cluster & durcissement), jalon produit M4 (V2 cluster). Risque identifié de la phase 6 : **canal mutuellement authentifié et réseau à haut débit**.

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J3 de la fiche 9x. Cette spec fait sortir la
plateforme de la machine unique : l'arbre d'exécution gagne son niveau supérieur — **l'hôte** — et le
plan de contrôle pilote désormais des nœuds à distance.

### User Story 1 - Agent : j'installe le worker, il détecte et annonce son matériel (Priority: P1)

L'administrateur installe le composant worker sur une seconde machine. Sans rien déclarer, celui-ci
découvre les cartes GPU, leurs appairages haut débit, la mémoire vive et les disques, et annonce
cette configuration au plan de contrôle.

**Why this priority**: c'est la profondeur J1. Sans découverte fiable côté hôte distant, ni
l'adhésion ni le placement n'ont de sens. C'est aussi la reprise, côté worker, de l'exigence déjà
posée par S06 : **la topologie est découverte, jamais déclarée**.

**Independent Test**: installer le worker sur une machine, l'exécuter sans configuration matérielle,
et vérifier qu'il rapporte exactement les cartes présentes, leurs appairages réels, la mémoire vive
et les disques.

**Acceptance Scenarios**:

1. **Given** une machine dotée de cartes GPU, **When** le worker y est installé et démarré, **Then**
   il découvre seul les cartes, leur mémoire, la mémoire vive et les disques — **aucune déclaration
   manuelle**.
2. **Given** des cartes appairées par lien haut débit, **When** le worker inspecte la topologie,
   **Then** il identifie les **paires réelles**, sans les supposer.
3. **Given** la configuration découverte, **When** le worker l'annonce, **Then** le plan de contrôle
   en dispose intégralement.
4. **Given** le worker installé, **When** on l'inspecte, **Then** il est distribué comme un
   composant installable et configurable, indépendant du plan de contrôle.

---

### User Story 2 - Cluster : adhésion par jeton, approbation, pilotage distant sécurisé (Priority: P2)

L'administrateur fait rejoindre le cluster à la nouvelle machine au moyen d'un **jeton à usage
unique**. L'hôte apparaît en attente d'approbation ; une fois approuvé — et l'approbation tracée —
il devient actif, émet un signal de vie périodique, et le plan de contrôle pilote ses nœuds à
distance sur un canal **mutuellement authentifié**.

**Why this priority**: c'est la profondeur J2, le cœur de la spec et de la promesse du jalon M4.
C'est aussi le point sensible en sécurité : ouvrir le pilotage à distance sans authentification
mutuelle exposerait l'ensemble du cluster.

**Independent Test**: faire adhérer une machine avec un jeton, constater qu'elle apparaît en attente,
l'approuver, vérifier la trace d'audit, puis piloter un moteur à distance et couper le signal de vie
pour observer le passage à l'état perdu.

**Acceptance Scenarios**:

1. **Given** un jeton d'adhésion émis, **When** le worker l'utilise pour rejoindre le cluster,
   **Then** l'hôte apparaît à l'état **en attente d'approbation**, visible de l'administrateur.
2. **Given** un jeton déjà utilisé, **When** on tente de s'en resservir, **Then** l'adhésion est
   **refusée** — le jeton est à **usage unique**.
3. **Given** un hôte en attente, **When** l'administrateur l'approuve, **Then** il passe à l'état
   **actif** et l'approbation est **inscrite au journal d'audit** (Art. 4).
4. **Given** un hôte actif, **When** le plan de contrôle pilote ses moteurs, **Then** les échanges
   empruntent un canal où **les deux extrémités s'authentifient mutuellement**.
5. **Given** un hôte actif, **When** il fonctionne, **Then** il émet un **signal de vie périodique**
   vers le plan de contrôle.
6. **Given** un hôte dont **trois signaux de vie consécutifs manquent**, **When** le seuil est
   atteint, **Then** l'hôte passe à l'état **perdu** et ses nœuds sont marqués comme indisponibles.
7. **Given** un nœud, **When** il est défini, **Then** il appartient à **un seul hôte** — un nœud ne
   s'étend **jamais** sur deux machines.
8. **Given** l'état d'un hôte, **When** il change, **Then** il suit la machine à états normative et
   le changement est **diffusé en direct**.

---

### User Story 3 - Surface : je vois les hôtes, je draine, je retire (Priority: P3)

L'administrateur consulte l'ensemble des machines du cluster avec leur matériel et leur latence
réseau, draine celle qu'il veut arrêter, et la retire proprement. Symétriquement, un worker peut
demander lui-même à quitter le cluster.

**Why this priority**: c'est la profondeur J3. Un cluster dans lequel on ne peut pas retirer une
machine proprement n'est pas exploitable — c'est ce que couvre le workflow de sortie du document,
dans ses **deux initiatives**.

**Independent Test**: drainer un hôte servant des requêtes et vérifier qu'aucune n'est perdue ; puis
le retirer côté administrateur et, séparément, faire quitter un autre hôte à l'initiative du worker.

**Acceptance Scenarios**:

1. **Given** le cluster, **When** l'administrateur ouvre la vue dédiée, **Then** il voit chaque hôte
   avec son **matériel**, son **état** et sa **latence réseau**.
2. **Given** un hôte servant des requêtes, **When** l'administrateur le **draine**, **Then** il
   cesse d'admettre de nouvelles requêtes et laisse **se terminer** celles en cours.
3. **Given** un hôte drainé, **When** l'administrateur le **retire**, **Then** il passe à l'état
   **retiré**, après une **confirmation avertie** si des modèles n'étaient servis que par lui.
4. **Given** un worker, **When** il demande lui-même à **quitter** le cluster, **Then** il est drainé
   puis passe par l'état **en cours de départ** jusqu'à **parti**, et son certificat d'accès est
   **révoqué**.
5. **Given** un hôte parti, retiré ou perdu, **When** il souhaite revenir, **Then** cela exige une
   **nouvelle adhésion** — il n'y a pas de réintégration automatique.
6. **Given** un hôte en cours de drainage, **When** une requête lui est adressée, **Then** elle est
   refusée avec le code canonique indiquant un drainage en cours et une indication de délai.

---

### Edge Cases

- **Un jeton d'adhésion est intercepté** : son usage unique et l'approbation administrateur limitent
  la fenêtre ; un jeton non utilisé expire.
- **Un hôte non approuvé tente de servir des requêtes** : il ne reçoit aucun trafic tant qu'il n'est
  pas approuvé.
- **Le signal de vie reprend après deux manques** : l'hôte reste actif — seuls **trois** manques
  consécutifs déclenchent le passage à perdu.
- **Un hôte perdu réapparaît spontanément** : il ne réintègre pas le routage de lui-même ; une
  nouvelle adhésion est requise, sans quoi un hôte instable oscillerait dans le cluster.
- **La latence réseau entre plan de contrôle et hôte est trop élevée** : la situation est visible
  dans la vue des hôtes, le débit du réseau étant le risque identifié de cette phase.
- **Le drainage d'un hôte n'aboutit pas** (requête qui ne se termine pas) : un délai maximal
  s'applique, au terme duquel la situation est signalée.
- **Un administrateur retire le dernier hôte servant un modèle** : la confirmation avertie l'indique
  explicitement avant validation (Art. 3).
- **Le certificat d'un worker expire pendant son service** : le renouvellement est prévu ; à défaut,
  l'hôte est traité comme perdu plutôt que de continuer sans authentification.
- **Le cluster dépasse trois machines** : le document prévoit de **réévaluer** l'approche plutôt que
  d'étendre indéfiniment ce mécanisme (Art. 9).

## Requirements *(mandatory)*

### Functional Requirements

#### Composant worker et découverte (J1)

- **FR-001**: Le système DOIT fournir un **composant worker** installable sur chaque machine,
  configurable et indépendant du plan de contrôle.
- **FR-002**: Le worker DOIT **découvrir** seul les cartes GPU, leur mémoire, les appairages haut
  débit, la mémoire vive et les disques — **aucune déclaration manuelle**.
- **FR-003**: Le worker DOIT **annoncer** la configuration découverte au plan de contrôle.

#### Adhésion et approbation (J2)

- **FR-004**: Un worker DOIT pouvoir rejoindre le cluster au moyen d'un **jeton à usage unique**.
- **FR-005**: Un jeton déjà utilisé, ou expiré, DOIT être **refusé**.
- **FR-006**: Un hôte ayant rejoint le cluster DOIT apparaître à l'état **en attente d'approbation**
  et NE DOIT recevoir **aucun trafic** avant approbation.
- **FR-007**: L'approbation d'un hôte DOIT être **inscrite au journal d'audit** (Art. 4).

#### Canal de pilotage (J2)

- **FR-008**: Les échanges entre le plan de contrôle et un worker DOIVENT emprunter un canal où **les
  deux extrémités s'authentifient mutuellement**.
- **FR-009**: Le plan de contrôle DOIT pouvoir **piloter à distance** le cycle de vie des moteurs
  d'un hôte approuvé.
- **FR-010**: Un certificat d'accès expiré ou non renouvelé DOIT conduire à traiter l'hôte comme
  **perdu**, jamais à poursuivre sans authentification.

#### Signal de vie et états (J2)

- **FR-011**: Un hôte actif DOIT émettre un **signal de vie périodique** vers le plan de contrôle.
- **FR-012**: **Trois** signaux de vie consécutifs manquants DOIVENT faire passer l'hôte à l'état
  **perdu** et marquer ses nœuds comme indisponibles.
- **FR-013**: Une reprise du signal avant le troisième manque NE DOIT **pas** changer l'état de
  l'hôte.
- **FR-014**: L'état d'un hôte DOIT suivre la machine à états normative — en attente d'approbation →
  actif ⇄ en drainage → inactif, avec les sorties **en cours de départ → parti** (initiative du
  worker), **retiré** (initiative de l'administrateur) et **perdu** (défaillance).
- **FR-015**: Tout changement d'état d'hôte DOIT être **diffusé en direct**.

#### Rattachement des nœuds (J2)

- **FR-016**: Un nœud DOIT appartenir à **un seul hôte** — un nœud NE DOIT **jamais** s'étendre sur
  deux machines.

#### Sortie du cluster (J3)

- **FR-017**: Le système DOIT permettre de **drainer** un hôte : cesser d'admettre de nouvelles
  requêtes tout en laissant se terminer celles en cours.
- **FR-018**: Une requête adressée à un hôte en drainage DOIT être refusée avec le **code canonique
  de drainage en cours** et une indication de délai.
- **FR-019**: Un **worker** DOIT pouvoir demander lui-même à quitter le cluster : drainage, puis
  états **en cours de départ** et **parti**, avec **révocation de son certificat d'accès**.
- **FR-020**: Un **administrateur** DOIT pouvoir retirer un hôte : drainage puis état **retiré**,
  précédé d'une **confirmation avertie** si des modèles n'étaient servis que par cet hôte (Art. 3).
- **FR-021**: Un hôte parti, retiré ou perdu NE DOIT **pas** réintégrer le cluster automatiquement :
  le retour exige une **nouvelle adhésion**.
- **FR-022**: Un drainage qui n'aboutit pas dans un délai maximal DOIT être **signalé**.

#### Vue du cluster (J3)

- **FR-023**: Le système DOIT présenter chaque hôte avec son **matériel**, son **état** et sa
  **latence réseau**.

#### Preuves (J4)

- **FR-024**: L'adhésion complète jusqu'au service de requêtes, la découverte de topologie et le
  passage à l'état perdu sur signal de vie manquant DOIVENT être prouvés par des tests dédiés.

### Hors périmètre *(Art. 20 — YAGNI)*

- La **réplication d'un même modèle sur plusieurs hôtes**, le routage entre eux et la bascule sur
  panne → **S20**. S19 rend les hôtes **disponibles** ; S20 les fait **collaborer**.
- Le **cycle de vie local** des moteurs, la découverte mono-machine, l'éviction et le hot-swap →
  **S06**, que S19 **étend** au distant sans le réécrire.
- Le **téléchargement** des modèles → **S10** ; S19 en assure seulement l'acheminement vers l'hôte
  cible.
- La **coquille d'interface** → **S11**.
- Le **journal d'audit** → **S13**, où S19 émet ses entrées.
- Le **durcissement**, les sauvegardes et les scénarios de charge → **S21**.
- Tout **orchestrateur de cluster générique** : explicitement écarté sous trois machines (Art. 9) ;
  au-delà, le document prévoit de **réévaluer** l'approche plutôt que d'étendre ce mécanisme.

### Key Entities

- **Hôte** : machine physique du cluster, portant un worker. Attributs : matériel découvert, état,
  dernier signal de vie, latence réseau. Niveau supérieur de l'arbre d'exécution (Cluster → Host →
  Node → Engine → Instance).
- **Worker** : composant Quadra installé sur un hôte, assurant découverte, adhésion, signal de vie et
  pilotage local. *Terme normatif — « agent » (réservé aux clients IA) et « daemon » sont des
  synonymes interdits (Art. 12).*
- **Jeton d'adhésion** : secret à **usage unique** permettant à un worker de se présenter au cluster.
- **Signal de vie** : émission périodique du worker vers le plan de contrôle ; **trois manques
  consécutifs** valent perte de l'hôte. *Terme normatif — « ping » et « keepalive » sont des
  synonymes interdits.*

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Une commande d'adhésion depuis une machine dotée d'un jeton
  fait apparaître l'hôte **en attente d'approbation**, et il devient **approuvable** par
  l'administrateur.
- **SC-002** *(critère A2)*: La topologie d'appairage de l'hôte est **découverte automatiquement** et
  correspond à **100 %** à la topologie physique réelle.
- **SC-003** *(critère A3)*: Après **trois** signaux de vie manquants, l'hôte passe à l'état **perdu**
  et ses nœuds sont marqués indisponibles — **100 %** des cas.
- **SC-004**: Un jeton d'adhésion ne peut être utilisé **qu'une seule fois** : toute réutilisation
  est refusée.
- **SC-005**: Un hôte non approuvé reçoit **zéro** requête.
- **SC-006**: **100 %** des approbations d'hôte figurent au journal d'audit.
- **SC-007**: **Zéro** échange de pilotage sans authentification mutuelle des deux extrémités.
- **SC-008**: Le drainage d'un hôte se solde par **zéro requête perdue**.
- **SC-009**: Un hôte parti, retiré ou perdu ne réintègre **jamais** le cluster sans nouvelle
  adhésion.
- **SC-010**: **Zéro** nœud s'étendant sur deux hôtes.
- **SC-011**: Le retrait d'un hôte servant seul un modèle produit une **confirmation avertie** avant
  validation.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9x) |
| --- | --- | --- |
| A1 — adhésion → hôte visible et approuvable | SC-001, SC-004, SC-005, SC-006 | T12 `[TEST]` adhésion → service · T4 jeton + approbation auditée |
| A2 — topologie de l'hôte découverte automatiquement | SC-002 | T12 `[TEST]` topologie · T2 découverte côté worker |
| A3 — signal de vie perdu → hôte hors service | SC-003, SC-009 | T12 `[TEST]` signal de vie perdu · T6 états d'hôte |
| Canal authentifié mutuellement | SC-007 | T5 canal de pilotage |
| Drainage et sortie (deux initiatives) | SC-008, SC-011 | T10 drainage, départ, retrait |
| Acheminement vers l'hôte cible | — | T11 `[INT]` téléchargement vers l'hôte cible (S10) |

## Assumptions

- **Dépendance à S06** : le superviseur, la notion de nœud et le cycle de vie des moteurs existent
  déjà en mono-machine. S19 les **étend au distant** : le modèle de données de S06 était conçu pour
  accueillir un rattachement à un hôte, ce qui évite une refonte (Art. 18).
- **Découverte, jamais déclaration** : l'exigence de S06 est reprise à l'identique côté worker. Le
  code de découverte est **le même**, exécuté localement sur chaque hôte (Art. 19) — il n'en existe
  pas deux versions.
- **Risque assumé de la phase 6** : le document identifie le canal mutuellement authentifié et le
  débit réseau comme les risques de cette phase. La latence réseau est donc rendue **visible** dans
  la vue des hôtes (FR-023), pour que le problème soit diagnosticable plutôt que subi.
- **Pas d'orchestrateur générique sous trois machines** : choix explicite de l'Art. 9. Au-delà de
  trois machines, le document prévoit de **réévaluer** l'approche plutôt que d'étendre ce mécanisme —
  c'est noté ici pour que l'extension ne se fasse pas par inertie.
- **Trois signaux manqués** : seuil fixé par la machine à états normative. La reprise avant le
  troisième manque ne change rien (FR-013), ce qui évite qu'un hic réseau bref sorte un hôte du
  cluster.
- **Pas de réintégration automatique** : conséquence directe de la machine à états (« ré-admission =
  nouveau join »). C'est ce qui empêche un hôte instable d'osciller dans le cluster, et cela impose
  une décision humaine après chaque perte.
- **Un nœud ne traverse jamais deux hôtes** : consigne explicite du document. C'est aussi ce qui rend
  la réplication de S20 nécessaire : on ne répartit pas un modèle **entre** machines, on le
  **réplique** sur plusieurs.
- **Jalon M4** : la spec est **complète à M4**, avec S20 et S21.
