# Feature Specification: S18 — Jobs par lot + offload sur demande

**Feature Branch**: `018-jobs-batch-offload`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9w du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S18 du plan de specs 9c : « Jobs batch + offload opt-in », références 7j · 6h · W8, dépend de S05 et S06, effort ≈ 6 j-agent, phase 5 (usages avancés), jalon produit M3 (V1.1 confort).

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J2 de la fiche 9w. Cette spec introduit le **traitement
asynchrone** : un lot n'est pas une conversation, c'est un **ticket** — on le dépose, on est notifié,
on récupère le résultat. Elle est aussi le seul consommateur de l'**offload**, strictement sur
demande.

### User Story 1 - Cœur : je dépose un lot, il tourne dans les creux, avec une estimation (Priority: P1)

Un agent ou un pipeline soumet un lot de travaux. Le système l'accepte, le planifie de préférence
aux heures creuses, l'exécute dans la lane batch en cédant systématiquement aux utilisateurs
interactifs, et fournit une estimation de fin qui s'affine.

**Why this priority**: c'est la profondeur J1 et la totalité de la valeur métier. C'est aussi le lieu
où l'Art. 2 est mis à l'épreuve : un lot de plusieurs heures ne doit jamais dégrader l'expérience
d'un humain qui attend.

**Independent Test**: soumettre un lot, vérifier qu'il progresse, mesurer le temps d'attente des
requêtes interactives pendant son exécution, et vérifier que l'estimation de fin est fournie et
s'affine.

**Acceptance Scenarios**:

1. **Given** un lot soumis, **When** il est accepté, **Then** son état suit la machine à états
   normative : accepté → planifié → en cours ⇄ en cession → terminé, avec les issues **refusé**,
   **échoué** et **expiré**.
2. **Given** un lot accepté, **When** il est planifié, **Then** le système privilégie les **périodes
   creuses** identifiées à partir de l'historique de charge.
3. **Given** un lot en cours, **When** une requête interactive se présente, **Then** le lot **cède**
   la ressource — la lane interactive garde sa préséance (Art. 2).
4. **Given** un lot en cours, **When** l'utilisateur consulte son avancement, **Then** il obtient une
   **estimation de fin**, calculée à partir du débit mesuré et du travail restant, qui **s'affine**
   au fil de l'exécution.
5. **Given** un lot en cours, **When** son avancement change, **Then** la progression est **diffusée
   en direct**.
6. **Given** un lot dont le contexte dépasse la mémoire disponible et **qui n'a pas demandé
   l'offload**, **When** il est soumis, **Then** il est **refusé explicitement**, avec le code
   canonique indiquant que l'offload serait requis — jamais accepté puis échoué en silence.
7. **Given** un lot qui **a explicitement demandé** l'offload, **When** son contexte dépasse la
   mémoire disponible, **Then** il est routé vers le mode avec débordement mémoire.
8. **Given** un lot quelconque, **When** il est exécuté, **Then** l'offload **n'est jamais activé
   implicitement** : il résulte uniquement d'une demande explicite du lot (Art. 3).
9. **Given** les lanes, **When** un lot s'exécute, **Then** il occupe **exclusivement la lane batch**.

---

### User Story 2 - Surface : je suis notifié et je récupère mon résultat (Priority: P2)

À la fin de son lot, l'auteur est notifié, récupère le résultat, et sait combien de temps il restera
disponible. Il suit ses lots depuis une vue dédiée.

**Why this priority**: c'est la profondeur J2. Un traitement asynchrone sans notification oblige à
surveiller, ce qui annule son intérêt. La durée de disponibilité du résultat doit être connue
d'avance pour éviter les pertes.

**Independent Test**: soumettre un lot, attendre sa fin, vérifier la réception de la notification,
télécharger le résultat, puis vérifier qu'il n'est plus disponible passé le délai annoncé.

**Acceptance Scenarios**:

1. **Given** un lot terminé, **When** il s'achève, **Then** l'auteur est **notifié** par les moyens
   configurés — appel sortant et courriel.
2. **Given** une notification par appel sortant, **When** elle est émise, **Then** elle est
   **signée**, afin que le destinataire puisse en vérifier l'origine.
3. **Given** un lot terminé, **When** l'auteur récupère son résultat, **Then** celui-ci est
   disponible pendant **7 jours**, cette durée étant **annoncée**.
4. **Given** un résultat au terme de sa durée de disponibilité, **When** le délai expire, **Then**
   le lot passe à l'état **expiré** et le résultat est **purgé**.
5. **Given** ses lots, **When** l'utilisateur ouvre la vue dédiée, **Then** il y voit leur état, leur
   avancement, leur estimation de fin et l'accès à leurs résultats.

---

### Edge Cases

- **Le lot échoue en cours d'exécution** : son état devient échoué, l'auteur est notifié, et la
  partie déjà produite est mise à disposition si elle a du sens — plutôt qu'un échec sans rien.
- **Le lot est soumis alors que la plateforme est saturée** : il est accepté et planifié, pas refusé
  — c'est précisément l'intérêt de l'asynchrone.
- **L'estimation de fin est très imprécise au début** : elle est présentée comme une estimation, et
  s'affine ; elle n'est pas donnée comme un engagement.
- **La notification ne peut pas être délivrée** : l'échec est enregistré et visible sur le lot ;
  le résultat reste récupérable — la perte d'une notification ne fait pas perdre le travail.
- **L'auteur annule son lot en cours** : l'exécution s'arrête et les ressources sont libérées ;
  l'état reflète l'annulation.
- **Le volume dédié au débordement mémoire est absent ou plein** : un lot demandant l'offload est
  refusé explicitement, plutôt que de dégrader silencieusement.
- **Un lot cède si souvent qu'il n'avance plus** : sa progression reste strictement positive sur une
  fenêtre longue — la cession ne doit pas se transformer en famine (cohérent avec S05).
- **Le résultat contient des données sensibles** : il reste **sur site** ; la notification sortante
  ne transporte que l'information de fin et une référence, jamais le contenu (Art. 1).

## Requirements *(mandatory)*

### Functional Requirements

#### Soumission et cycle de vie (J1)

- **FR-001**: Le système DOIT accepter la soumission de **lots de travaux asynchrones**.
- **FR-002**: L'état d'un lot DOIT suivre la machine à états normative : accepté → planifié → en
  cours ⇄ en cession → terminé, avec les issues **refusé**, **échoué** et **expiré**.
- **FR-003**: Le système DOIT permettre d'**annuler** un lot en cours, en libérant ses ressources.
- **FR-004**: Un lot échoué DOIT mettre à disposition la partie déjà produite lorsque celle-ci a du
  sens.

#### Planification et préséance (J1 — Art. 2)

- **FR-005**: Le système DOIT privilégier les **périodes creuses**, identifiées à partir de
  l'historique de charge, pour planifier l'exécution des lots.
- **FR-006**: Un lot DOIT s'exécuter **exclusivement dans la lane batch**.
- **FR-007**: Un lot en cours DOIT **céder** la ressource lorsqu'une lane supérieure a du travail —
  la lane interactive garde sa préséance absolue.
- **FR-008**: La progression d'un lot DOIT rester **strictement positive** sur une fenêtre longue :
  la cession NE DOIT pas se transformer en famine.

#### Offload strictement sur demande (J1 — Art. 3)

- **FR-009**: L'offload NE DOIT **jamais** être activé implicitement : il résulte **uniquement d'une
  demande explicite portée par le lot**.
- **FR-010**: Un lot dont le contexte dépasse la mémoire disponible et **qui n'a pas demandé
  l'offload** DOIT être **refusé explicitement**, avec le code canonique indiquant que l'offload
  serait requis — jamais accepté puis échoué en silence.
- **FR-011**: Un lot ayant demandé l'offload DOIT être routé vers le mode avec débordement mémoire
  lorsque son contexte l'exige.
- **FR-012**: Si le volume dédié au débordement est absent ou plein, un lot demandant l'offload DOIT
  être **refusé explicitement**, sans dégradation silencieuse.

#### Estimation et suivi (J1)

- **FR-013**: Le système DOIT fournir une **estimation de fin**, calculée à partir du débit mesuré et
  du travail restant, qui **s'affine** au fil de l'exécution.
- **FR-014**: L'estimation DOIT être présentée **comme une estimation**, non comme un engagement.
- **FR-015**: La progression d'un lot DOIT être **diffusée en direct**.

#### Notification et résultats (J2)

- **FR-016**: À l'achèvement d'un lot, le système DOIT **notifier** son auteur par les moyens
  configurés — appel sortant et courriel.
- **FR-017**: Une notification par appel sortant DOIT être **signée**, afin que le destinataire
  puisse en vérifier l'origine.
- **FR-018**: Une notification NE DOIT transporter **que** l'information de fin et une référence —
  **jamais le contenu** du résultat (Art. 1).
- **FR-019**: Un échec de notification DOIT être **enregistré et visible** sur le lot, sans rendre le
  résultat inaccessible.
- **FR-020**: Le résultat d'un lot DOIT rester disponible **7 jours**, cette durée étant
  **annoncée**.
- **FR-021**: Au terme de ce délai, le lot DOIT passer à l'état **expiré** et son résultat être
  **purgé**.
- **FR-022**: Le système DOIT fournir une vue des lots présentant leur état, leur avancement, leur
  estimation de fin et l'accès à leurs résultats.

#### Preuves (J3)

- **FR-023**: Le refus d'un lot sans offload, la cession effective à la lane interactive, la
  notification et l'expiration du résultat DOIVENT être prouvés par des tests dédiés, la cession
  étant **mesurée**.

### Hors périmètre *(Art. 20 — YAGNI)*

- L'**ordonnancement** entre lanes et le mécanisme de cession → **S05**. S18 **utilise** la lane
  batch et son mécanisme de cession ; il ne les implémente pas.
- Le **placement** des modèles et le pilotage des moteurs → **S06**, **S07**. Le mode avec
  débordement mémoire est fourni par un driver dédié.
- La **carte de charge** identifiant les périodes creuses → **S15**, dont S18 est **consommateur**.
- La **comptabilité** des requêtes produites par un lot → **S08** : elles sont comptées comme toutes
  les autres.
- La **coquille d'interface** → **S11**.
- Le **service d'inférence synchrone** et son contrat → **S04**.
- L'**ordonnancement fin par priorité entre lots** (au-delà de l'ordre de soumission et des périodes
  creuses) : hors périmètre, aucun jalon ne l'exige (Art. 20).

### Key Entities

- **Lot** : ensemble de travaux soumis pour exécution asynchrone. Attributs : état, avancement,
  estimation de fin, demande d'offload, référence de résultat, durée de disponibilité. Rattaché à
  l'arbre du trafic de la taxonomie (Request → Job).
- **Offload** : débordement de la mémoire de travail vers la mémoire vive ou le stockage.
  **Sur demande explicite par lot, lane batch uniquement.** *Terme normatif — « swap » est un
  synonyme interdit, réservé au hot-swap (Art. 12).*
- **Estimation de fin** : projection du moment d'achèvement, dérivée du débit mesuré et du travail
  restant, affinée en continu.
- **Notification** : signal de fin adressé à l'auteur, signé lorsqu'il sort du système, ne
  transportant jamais le contenu du résultat.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Un lot dont le contexte dépasse la mémoire disponible et qui
  n'a pas demandé l'offload est **refusé explicitement** dans **100 %** des cas, avec le code
  canonique attendu — **zéro** acceptation suivie d'un échec silencieux.
- **SC-002** *(critère A2)*: Pendant l'exécution d'un lot, le temps d'attente des requêtes
  interactives **reste dans son seuil de service** — la cession est **mesurée**, non supposée.
- **SC-003** *(critère A3)*: L'auteur d'un lot est **notifié** à son achèvement, et le résultat
  reste disponible **7 jours** puis est **purgé**.
- **SC-004**: **Zéro** activation implicite de l'offload : toute exécution avec débordement mémoire
  correspond à une demande explicite du lot.
- **SC-005**: La progression d'un lot reste **strictement positive** sur une fenêtre longue, même
  sous charge interactive soutenue.
- **SC-006**: L'estimation de fin **s'affine** : son écart avec le temps réel décroît à mesure que le
  lot progresse.
- **SC-007**: **Aucun** contenu de résultat ne figure dans une notification sortante.
- **SC-008**: Un échec de notification laisse le résultat **récupérable** et l'échec **visible**.
- **SC-009**: Un lot annulé libère ses ressources et son état reflète l'annulation.
- **SC-010**: Un lot demandant l'offload alors que le volume dédié est indisponible est **refusé
  explicitement** — **zéro** dégradation silencieuse.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9w) |
| --- | --- | --- |
| A1 — refus si contexte trop grand sans offload | SC-001, SC-004, SC-010 | T10 `[TEST]` refus · T3 refus sans demande d'offload |
| A2 — la lane batch cède aux lanes interactives | SC-002, SC-005 | T9 `[INT]` cession **mesurée** (S05) |
| A3 — notification à la fin + résultat 7 jours | SC-003, SC-007, SC-008 | T10 `[TEST]` notification + durée de disponibilité |
| Estimation de fin | SC-006 | T5 estimation + progression |
| Annulation | SC-009 | T1 cycle de vie du lot |

## Assumptions

- **Dépendances** : S05 fournit la **lane batch** et son mécanisme de cession ; S06 et S07
  fournissent le pilotage des moteurs et le driver de débordement mémoire ; S15 fournit la **carte de
  charge** d'où sont déduites les périodes creuses. S18 est consommateur des trois.
- **Un lot est un ticket, pas une conversation** : c'est la formulation du document. L'interaction
  est déposer → être notifié → récupérer ; il n'y a pas de diffusion continue au client, mais une
  **estimation de fin**.
- **L'offload est le seul mécanisme du projet activé par un flag de requête** : partout ailleurs, les
  décisions coûteuses passent par une confirmation d'interface. Ici, le demandeur est un programme,
  et l'Art. 3 s'applique sous la forme d'un **opt-in explicite par lot** — le silence vaut refus
  (FR-009, FR-010).
- **Le volume dédié au débordement existe mais reste inutilisé par défaut** : provisionné par S01,
  laissé inactif par l'assistant d'installation (S12). S18 est le premier — et le seul — à s'en
  servir.
- **Durée de disponibilité de 7 jours** : valeur fixée par le document (5c). Elle est **annoncée** à
  l'auteur (FR-020), sans quoi une purge est vécue comme une perte de données.
- **Les notifications sortantes sont signées et ne transportent pas de contenu** : le document exige
  la signature ; la spec ajoute l'interdiction de transporter le résultat (FR-018), déduite de
  l'Art. 1 — une notification part vers un système tiers, et y placer le contenu ferait sortir les
  données de l'infrastructure.
- **Les requêtes d'un lot sont comptabilisées comme les autres** : elles passent par le chemin commun
  et sont comptées par S08. Un lot n'échappe ni au budget ni au métrage.
- **Jalon M3** : la spec est **complète à M3**, en même temps que S15 dont elle consomme la carte de
  charge.
