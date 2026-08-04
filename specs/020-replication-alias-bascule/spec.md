# Feature Specification: S20 — Réplication d'alias entre hôtes + bascule sur panne

**Feature Branch**: `020-replication-alias-bascule`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9y du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S20 du plan de specs 9c : « Réplication d'alias inter-hosts + bascule sur panne », références 2b · 7g · W12, dépend de S19, effort ≈ 5 j-agent, phase 6 (cluster & durcissement), jalon produit M4 (V2 cluster).

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent le jalon interne J1 de la fiche 9y. Cette spec est la **façon saine de
monter en charge** retenue par le projet : on ne répartit pas un modèle **entre** machines, on le
**réplique** sur plusieurs — ce qui additionne le débit et rend le service résistant à la perte d'une
machine.

### User Story 1 - Le débit s'additionne, et une panne ne me casse pas (Priority: P1)

Un utilisateur adresse ses requêtes à un nom de modèle unique. En coulisse, plusieurs machines le
servent : la charge est répartie vers la moins occupée, le débit total s'additionne, et si une
machine tombe, le service continue sans que le client voie une erreur serveur.

**Why this priority**: c'est l'intégralité de la valeur de la spec et la promesse du jalon M4. C'est
aussi ce qui justifie l'existence de S19 : disposer de plusieurs machines ne sert à rien si elles ne
se répartissent pas le travail et ne se relaient pas en cas de panne.

**Independent Test**: servir un même nom de modèle depuis deux machines, mesurer le débit agrégé,
puis arrêter brutalement l'une d'elles et observer, côté client, l'absence d'erreur serveur et la
reprise du service.

**Acceptance Scenarios**:

1. **Given** un même nom de modèle servi par plusieurs machines, **When** un client l'appelle,
   **Then** il l'appelle **par ce nom unique**, sans connaître ni choisir la machine.
2. **Given** deux machines servant le même nom de modèle, **When** la charge est soutenue, **Then**
   le **débit total s'additionne** — de l'ordre du double par rapport à une machine seule.
3. **Given** plusieurs exemplaires disponibles, **When** une requête doit être placée, **Then** elle
   est dirigée vers **le moins occupé**, la charge étant appréciée à partir de l'attente en file et
   du débit observé.
4. **Given** une machine qui devient indisponible, **When** sa perte est constatée, **Then** elle est
   **retirée du routage en moins de 10 secondes** et les requêtes **non entamées** qui lui étaient
   destinées sont **réinjectées en file** vers les exemplaires restants.
5. **Given** une machine perdue, **When** la bascule s'opère, **Then** le client ne reçoit **aucune
   erreur serveur** : le service se poursuit sur les exemplaires restants.
6. **Given** une génération **déjà commencée** sur une machine perdue, **When** celle-ci disparaît,
   **Then** la requête **échoue proprement** avec une erreur que le client peut réessayer — elle
   n'est **jamais** relancée automatiquement.
7. **Given** plusieurs exemplaires d'un même nom de modèle, **When** on consulte les mesures,
   **Then** le débit est exposé **par exemplaire et par machine**.
8. **Given** le cluster en charge, **When** l'opérateur ouvre les vues d'exploitation, **Then** la
   **répartition** entre machines lui est visible.

---

### Edge Cases

- **Un seul exemplaire subsiste pour un nom de modèle** : le service continue, à débit réduit ; la
  perte du dernier exemplaire rend le nom de modèle indisponible, avec une erreur explicite.
- **Deux exemplaires ont des performances très différentes** : la répartition tient compte de la
  charge **observée**, pas d'un partage égalitaire — sinon le plus lent deviendrait le goulot.
- **Une machine oscille entre disponible et indisponible** : sa réintégration au routage n'est pas
  immédiate, pour éviter d'y renvoyer du trafic qu'elle perdra à nouveau.
- **La réinjection en file crée un pic** : les requêtes réinjectées respectent les lanes et les caps
  existants — elles ne court-circuitent pas l'ordonnancement, et la lane interactive garde sa
  préséance.
- **Une requête est réinjectée alors qu'elle a déjà été servie ailleurs** : le mécanisme garantit
  qu'une requête n'est **pas** exécutée deux fois.
- **Toutes les machines sont également chargées** : le choix reste déterministe et réparti, sans
  concentrer sur la première.
- **Un exemplaire est en cours de chargement** : il n'est pas éligible au routage tant qu'il n'est
  pas prêt.

## Requirements *(mandatory)*

### Functional Requirements

#### Réplication et routage (J1)

- **FR-001**: Un **nom de modèle servi** DOIT pouvoir correspondre à **plusieurs exemplaires**
  répartis sur des machines différentes.
- **FR-002**: Un client DOIT appeler ce nom **unique**, sans connaître ni choisir la machine qui le
  sert.
- **FR-003**: Le système DOIT diriger chaque requête vers l'exemplaire **le moins occupé**, la
  charge étant appréciée à partir de **l'attente en file et du débit observé**.
- **FR-004**: La répartition DOIT tenir compte de la charge **observée** et non d'un partage
  égalitaire, afin qu'un exemplaire plus lent ne devienne pas le goulot.
- **FR-005**: Lorsque plusieurs exemplaires sont également chargés, le choix DOIT rester
  **déterministe et réparti**, sans concentration sur l'un d'eux.
- **FR-006**: Un exemplaire **en cours de chargement** NE DOIT **pas** être éligible au routage.
- **FR-007**: Le débit total servi pour un nom de modèle DOIT **s'additionner** avec le nombre
  d'exemplaires.

#### Bascule sur panne (J1)

- **FR-008**: Une machine devenue indisponible DOIT être **retirée du routage en moins de
  10 secondes**.
- **FR-009**: Les requêtes **non entamées** destinées à une machine perdue DOIVENT être
  **réinjectées en file** vers les exemplaires restants.
- **FR-010**: Une génération **déjà commencée** sur une machine perdue NE DOIT **jamais** être
  relancée automatiquement : la requête **échoue proprement**, avec une erreur que le client peut
  réessayer.
- **FR-011**: Le mécanisme de réinjection DOIT garantir qu'une requête **n'est pas exécutée deux
  fois**.
- **FR-012**: Les requêtes réinjectées DOIVENT respecter les **lanes et les caps** existants et NE
  DOIVENT **pas** court-circuiter l'ordonnancement — la lane interactive garde sa préséance
  (Art. 2).
- **FR-013**: Lors d'une bascule, le client NE DOIT recevoir **aucune erreur serveur** tant qu'un
  exemplaire reste disponible.
- **FR-014**: La perte du **dernier** exemplaire d'un nom de modèle DOIT rendre celui-ci
  indisponible avec une **erreur explicite**.
- **FR-015**: La **réintégration** d'une machine redevenue disponible NE DOIT **pas** être
  immédiate, afin d'éviter de lui réadresser du trafic qu'elle perdrait à nouveau.

#### Observabilité (J2)

- **FR-016**: Le système DOIT exposer le **débit par exemplaire et par machine** comme métriques du
  projet.
- **FR-017**: La **répartition** entre machines DOIT être visible dans les vues d'exploitation.

#### Preuves (J2)

- **FR-018**: L'additivité du débit, la bascule en moins de 10 secondes sans erreur serveur et la
  visibilité de la répartition DOIVENT être prouvées par des tests dédiés, la bascule étant vérifiée
  par **arrêt brutal** d'une machine.

### Hors périmètre *(Art. 20 — YAGNI)*

- L'**adhésion** d'une machine au cluster, sa découverte, son signal de vie et son retrait →
  **S19**. S20 **exploite** des machines déjà membres.
- La **répartition d'un même modèle entre plusieurs machines** (parallélisme inter-machines) :
  explicitement **écartée** par le document au profit de la réplication — c'est le choix
  d'architecture central de cette spec.
- L'**ordonnancement** par lane et les caps → **S05**, que la réinjection **respecte** sans le
  modifier.
- Le **placement** initial d'un modèle sur un nœud et le hot-swap → **S06**.
- Les **vues** elles-mêmes → **S11**, qui les porte ; S20 fournit les données de répartition.
- La **synchronisation d'état** entre exemplaires (mémoire de contexte partagée) : hors périmètre —
  chaque exemplaire est indépendant.

### Key Entities

- **Alias** : nom de modèle servi, **unité que voient les clients**. Peut correspondre à plusieurs
  exemplaires. *Terme normatif — « model name » et « deployment » sont des synonymes interdits
  (Art. 12).*
- **Instance** : exemplaire d'un alias résident sur un nœud d'une machine, **unité qu'exploite
  l'ordonnanceur**. *Terme normatif — « replica » et « copy » sont des synonymes interdits.*
- **Réinjection en file** : remise en file des requêtes **non entamées** après la perte d'une
  machine. *Terme normatif — ne désigne **jamais** la relance d'une génération commencée ; « retry »
  est réservé au client et « replay » est interdit.*
- **Charge observée** : appréciation de l'occupation d'un exemplaire, fondée sur l'attente en file et
  le débit constaté, servant au choix de routage.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Avec **deux machines** servant le même nom de modèle, le
  débit agrégé est de l'ordre du **double** de celui d'une machine seule.
- **SC-002** *(critère A2)*: À l'arrêt brutal d'une machine, le routage l'exclut en **moins de
  10 secondes** et le client ne reçoit **aucune erreur serveur** tant qu'un exemplaire subsiste.
- **SC-003** *(critère A3)*: La **répartition** entre machines est visible dans les vues
  d'exploitation, et le débit est exposé **par exemplaire et par machine**.
- **SC-004**: **Zéro** génération déjà commencée relancée automatiquement après une panne.
- **SC-005**: **Zéro** requête exécutée deux fois à la suite d'une réinjection.
- **SC-006**: Les requêtes réinjectées respectent lanes et caps : le temps d'attente de la lane
  interactive **reste dans son seuil** pendant une bascule.
- **SC-007**: Un exemplaire en cours de chargement reçoit **zéro** requête.
- **SC-008**: La perte du dernier exemplaire produit une **erreur explicite**, distincte d'une erreur
  générique.
- **SC-009**: Avec des exemplaires de performances inégales, la répartition suit la **charge
  observée** — le plus lent ne devient pas le goulot du service.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9y) |
| --- | --- | --- |
| A1 — deux machines, débit doublé | SC-001, SC-009 | T7 `[TEST]` débit ×2 |
| A2 — machine perdue, bascule < 10 s sans erreur serveur | SC-002, SC-004, SC-005, SC-006 | T6 `[TEST]` arrêt brutal → bascule |
| A3 — répartition visible | SC-003 | T7 `[TEST]` répartition visible · T4 métriques par exemplaire |
| Routage par exemplaire | SC-007 | T5 `[INT]` l'ordonnanceur route par exemplaire (S05) |
| Dernier exemplaire perdu | SC-008 | T3 bascule + réinjection |

## Assumptions

- **Dépendance à S19** : les machines sont déjà membres du cluster, découvertes, approuvées et
  surveillées par signal de vie. La **perte** d'une machine est détectée par S19 (trois signaux
  manqués) ; S20 en tire les conséquences sur le routage.
- **Réplication, pas répartition** : c'est le choix d'architecture central, énoncé par le document
  comme « la façon saine de scaler sans parallélisme inter-machines ». Un modèle n'est jamais
  découpé entre deux machines — conséquence directe de la règle de S19 selon laquelle **un nœud ne
  traverse jamais deux hôtes**.
- **Chaque exemplaire est indépendant** : aucune mémoire de contexte n'est partagée entre
  exemplaires. C'est ce qui rend la réplication simple et la bascule possible ; c'est aussi pourquoi
  une génération entamée ne peut pas être reprise ailleurs.
- **Distinction cruciale entre réinjection et relance** : le glossaire du projet est explicite — la
  réinjection ne concerne que les requêtes **non entamées**. Relancer une génération commencée
  produirait une double facturation et, potentiellement, une double exécution d'effets. C'est
  l'exigence FR-010, couplée à FR-011.
- **Seuil de bascule de 10 secondes** : valeur fixée par le critère A2 du document. Elle est
  cohérente avec le seuil de retrait d'un moteur attaché injoignable (S07), ce qui donne au projet un
  comportement homogène face à l'indisponibilité.
- **Réintégration différée** : le document ne la traite pas. La spec l'impose (FR-015) pour la même
  raison que S19 refuse la réintégration automatique d'un hôte perdu — une machine instable ne doit
  pas recevoir du trafic qu'elle perdra à nouveau.
- **La réinjection ne court-circuite pas l'ordonnancement** : ajout de la spec (FR-012, SC-006). Une
  bascule crée un pic de requêtes réinjectées ; les faire passer devant violerait l'Art. 2 au pire
  moment, celui où le service est déjà dégradé.
- **Jalon M4** : la spec est **complète à M4**, avec S19 et S21.
