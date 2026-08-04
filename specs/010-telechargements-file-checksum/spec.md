# Feature Specification: S10 — Téléchargements : file, reprise, intégrité, quarantaine

**Feature Branch**: `010-telechargements-file-checksum`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9o du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S10 du plan de specs 9c : « Téléchargements : file, reprise, checksum, quarantaine », références 7d · W3, dépend de S09, effort ≈ 6.5 j-agent, phase 3 (produit modèles), jalon produit M2 (V1 équipe).

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J2 de la fiche 9o. Cette spec exécute ce que S09 a
fait confirmer : elle transfère des dizaines de gigaoctets de façon **interruptible, reprenable et
vérifiable**, et garantit qu'un fichier corrompu n'atteint jamais un moteur.

### User Story 1 - Cœur : un téléchargement survit aux coupures et n'entre jamais corrompu (Priority: P1)

L'administrateur lance le téléchargement d'un modèle de plusieurs dizaines de gigaoctets. Le réseau
tombe en cours de route ; à la reprise, seuls les fragments manquants sont retransférés. À l'arrivée,
l'intégrité est vérifiée : un fichier altéré est isolé et n'est jamais servi.

**Why this priority**: c'est la profondeur J1 et la totalité de la valeur métier. Un téléchargement
non reprenable oblige à recommencer plusieurs heures de transfert ; un téléchargement non vérifié
introduit un modèle corrompu que le moteur chargera sans le savoir. Les deux sont des défauts
inacceptables (Art. 4).

**Independent Test**: lancer un téléchargement, couper le réseau à mi-parcours, le relancer, et
mesurer le volume réellement retransféré ; puis altérer volontairement un fichier et constater qu'il
est isolé au lieu d'être enregistré.

**Acceptance Scenarios**:

1. **Given** un téléchargement confirmé, **When** il démarre, **Then** il progresse selon la machine
   à états normative : en attente → en téléchargement ⇄ en pause → en vérification → prêt, avec les
   issues **en quarantaine**, **échoué** et **annulé**.
2. **Given** un téléchargement en cours, **When** le réseau est coupé puis rétabli, **Then** le
   transfert **reprend** et **ne retransfère pas** les fragments déjà obtenus et vérifiés.
3. **Given** un téléchargement terminé, **When** son intégrité est vérifiée par rapport aux
   empreintes publiées, **Then** un contenu conforme passe à l'état prêt et est **enregistré au
   registre des modèles**.
4. **Given** un contenu dont l'empreinte ne correspond pas, **When** la vérification échoue,
   **Then** il est placé en **quarantaine**, l'événement est **inscrit au journal d'audit**, et il
   n'est **jamais** servi ni proposé au déploiement.
5. **Given** un téléchargement en cours, **When** on observe le débit sortant, **Then** il respecte
   le **plafond configuré** — la consultation du dépôt public ne sature pas le lien.
6. **Given** un téléchargement demandé, **When** l'espace disque disponible est insuffisant,
   **Then** il est **refusé avant tout transfert**, avec le code canonique correspondant.
7. **Given** plusieurs téléchargements demandés, **When** ils sont traités, **Then** ils sont
   **ordonnés en file** et **un seul est actif à la fois** — le nombre d'actifs simultanés étant
   configurable.
8. **Given** un téléchargement à n'importe quel état, **When** le service redémarre, **Then** son
   état est **retrouvé** et le transfert peut reprendre là où il s'était arrêté.

---

### User Story 2 - Surface : je vois la file, je mets en pause, je reprends (Priority: P2)

L'administrateur suit l'avancement de ses téléchargements en direct — pourcentage et débit — met en
pause celui qui sature le lien, le reprend plus tard, et consulte l'historique de ce qui a été
téléchargé, échoué ou mis en quarantaine.

**Why this priority**: c'est la profondeur J2. Elle rend le transfert pilotable plutôt que subi : sur
un lien partagé, pouvoir suspendre un transfert de 40 Go est une exigence d'exploitation, pas un
confort.

**Independent Test**: lancer un téléchargement, observer la progression poussée en direct, le mettre
en pause, vérifier l'arrêt du transfert, le reprendre et vérifier qu'il repart sans perte.

**Acceptance Scenarios**:

1. **Given** un téléchargement en cours, **When** l'administrateur l'observe, **Then** sa
   **progression** et son **débit** lui sont **poussés en direct**, sans interrogation répétée.
2. **Given** un téléchargement en cours, **When** l'administrateur le **met en pause**, **Then** le
   transfert s'arrête et l'état devient « en pause » ; les fragments déjà obtenus sont conservés.
3. **Given** un téléchargement en pause, **When** l'administrateur le **reprend**, **Then** il repart
   sans retransférer les fragments déjà obtenus.
4. **Given** un téléchargement quelconque, **When** l'administrateur l'**annule**, **Then** il passe
   à l'état annulé et l'espace occupé par les fragments partiels est libéré.
5. **Given** des téléchargements passés, **When** l'administrateur consulte l'historique, **Then** il
   y voit les téléchargements terminés, échoués et en quarantaine, avec leur motif.

---

### Edge Cases

- **Le disque se remplit pendant le transfert** (et non avant) : le transfert est mis en pause et
  signalé, plutôt que d'échouer en laissant un fichier tronqué.
- **Le dépôt public ne publie pas d'empreinte pour un fichier** : le contenu ne peut pas être
  vérifié ; il est traité comme non vérifiable et **n'est pas** enregistré comme prêt — la spec
  n'admet pas d'enregistrement sur confiance.
- **Le même modèle est demandé deux fois** : une seule opération est engagée ; la seconde demande
  rejoint la première plutôt que de dupliquer le transfert.
- **Le service redémarre pendant la phase de vérification** : la vérification est reprise depuis le
  début, la vérification partielle n'ayant pas de valeur.
- **Un fragment déjà obtenu est corrompu sur disque** : il est détecté à la vérification et
  retransféré, plutôt que de faire échouer l'ensemble.
- **Le fichier distant a changé depuis la confirmation** (empreinte différente de celle annoncée) :
  le téléchargement est mis en quarantaine — l'écart avec ce qui a été confirmé est un motif
  d'isolement, pas d'acceptation silencieuse (Art. 3).
- **Un téléchargement reste en pause indéfiniment** : les fragments partiels occupent de l'espace ;
  l'occupation est visible dans l'historique pour que l'administrateur puisse décider.
- **Un modèle en quarantaine est demandé au service** : il est refusé avec le code canonique dédié —
  la quarantaine n'est jamais contournable.

## Requirements *(mandatory)*

### Functional Requirements

#### File et cycle de vie (J1)

- **FR-001**: Le système DOIT ordonner les téléchargements en **file** et n'en exécuter qu'un nombre
  limité simultanément, **un seul par défaut**, ce nombre étant configurable.
- **FR-002**: L'état d'un téléchargement DOIT suivre la machine à états normative : en attente → en
  téléchargement ⇄ en pause → en vérification → prêt, avec les issues **en quarantaine**, **échoué**
  et **annulé**.
- **FR-003**: L'état d'un téléchargement DOIT être **persisté** et **survivre à un redémarrage** du
  service, à n'importe quelle étape.
- **FR-004**: Le système DOIT permettre de **mettre en pause**, **reprendre** et **annuler** un
  téléchargement.
- **FR-005**: L'annulation DOIT **libérer l'espace** occupé par les fragments partiels.
- **FR-006**: Une demande portant sur un téléchargement déjà en cours NE DOIT **pas** engager une
  seconde opération.

#### Transfert et reprise (J1)

- **FR-007**: Le transfert DOIT s'effectuer **par fragments**, à partir de la liste de fichiers et
  d'empreintes publiée par le dépôt.
- **FR-008**: Après une interruption, le transfert DOIT **reprendre** sans retransférer les fragments
  déjà obtenus et vérifiés.
- **FR-009**: Un fragment déjà obtenu mais corrompu sur disque DOIT être **détecté et retransféré**,
  sans faire échouer l'ensemble.
- **FR-010**: Le système DOIT respecter un **plafond de débit** configurable pour ne pas saturer le
  lien réseau.
- **FR-011**: Le système DOIT **vérifier l'espace disque disponible avant** de démarrer un transfert
  et refuser avec le code canonique dédié s'il est insuffisant.
- **FR-012**: Si l'espace vient à manquer **pendant** le transfert, le système DOIT **mettre en
  pause** et signaler, plutôt que d'échouer en laissant un contenu tronqué.

#### Intégrité et quarantaine (J1)

- **FR-013**: Le système DOIT **vérifier l'intégrité** du contenu téléchargé par rapport aux
  empreintes publiées, **avant** tout enregistrement.
- **FR-014**: Un contenu dont l'empreinte ne correspond pas DOIT être placé en **quarantaine** :
  isolé, **inscrit au journal d'audit**, et **jamais servi** ni proposé au déploiement.
- **FR-015**: Un contenu **non vérifiable** (aucune empreinte publiée) NE DOIT **pas** être
  enregistré comme prêt.
- **FR-016**: Un contenu dont l'empreinte diffère de celle **annoncée à la confirmation** DOIT être
  placé en quarantaine (Art. 3 — ce qui a été confirmé engage).
- **FR-017**: Un modèle en quarantaine demandé au service DOIT être refusé avec le code canonique
  dédié — la quarantaine NE DOIT **jamais** être contournable.
- **FR-018**: Un contenu vérifié conforme DOIT être **enregistré au registre des modèles** et devenir
  déployable.

#### Surface et suivi (J2)

- **FR-019**: Le système DOIT **pousser en direct** la progression et le débit de chaque
  téléchargement, sans interrogation répétée du client.
- **FR-020**: Le système DOIT présenter la **file** des téléchargements et permettre les actions de
  pause, reprise et annulation.
- **FR-021**: Le système DOIT conserver un **historique** des téléchargements terminés, échoués et
  mis en quarantaine, avec leur motif et l'espace occupé par d'éventuels fragments partiels.

#### Confinement réseau (transverse, Art. 1)

- **FR-022**: Le téléchargement depuis le dépôt public de modèles DOIT rester la **seule** sortie
  réseau engagée par cette spec.

#### Preuves (J3)

- **FR-023**: La reprise sans retransfert, la mise en quarantaine sur intégrité invalide et le
  respect du plafond de débit DOIVENT être prouvés par des tests dédiés.

### Hors périmètre *(Art. 20 — YAGNI)*

- La **recherche** au catalogue, le verdict de tenue mémoire, les avertissements et le **dialogue de
  confirmation** → **S09**. S10 démarre à partir d'un téléchargement **déjà confirmé**.
- Le **placement** du modèle sur un nœud et son chargement → **S06**. S10 s'arrête à l'enregistrement
  au registre et à la **proposition** de déploiement.
- La **coquille d'interface** et le client généré → **S11**.
- Le **contrôle d'accès** déterminant qui peut télécharger, et le flux d'approbation → **S13**.
- Le **routage d'un téléchargement vers une machine cible** en environnement multi-machines →
  **S19**.
- La **journalisation d'audit** elle-même (chaînage, inviolabilité) → **S13**. S10 **émet** des
  entrées d'audit ; S13 en garantit l'infalsifiabilité.

### Key Entities

- **Téléchargement** : opération de transfert d'une variante de modèle. Attributs : modèle et
  variante visés, état, progression, débit, espace occupé, motif d'échec ou d'isolement.
- **Fragment** : portion transférable et vérifiable indépendamment d'un fichier de modèle. Unité de
  la reprise.
- **Empreinte d'intégrité** : valeur publiée par le dépôt permettant de vérifier qu'un contenu est
  exactement celui attendu.
- **Quarantaine** : état terminal d'isolement d'un contenu dont l'intégrité est invalide. Audité,
  jamais servi. *Terme normatif — « blacklist » et « blocked » sont des synonymes interdits
  (Art. 12).*

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Après une coupure réseau à mi-parcours, la reprise
  retransfère **uniquement** les fragments manquants : le volume retransféré est **inférieur ou égal**
  au volume restant, et **aucun** fragment déjà vérifié n'est retéléchargé.
- **SC-002** *(critère A2)*: Un contenu à l'intégrité invalide est placé en quarantaine dans
  **100 %** des cas, y figure au journal d'audit, et n'est **jamais** servi — vérifié en tentant de
  le déployer.
- **SC-003** *(critère A3)*: Le débit du transfert reste **sous le plafond configuré**, mesuré sur la
  durée du transfert.
- **SC-004**: Un téléchargement survit à un redémarrage du service à **chacun** de ses états, et
  reprend là où il s'était arrêté.
- **SC-005**: Un téléchargement demandé sans espace disque suffisant est refusé **avant tout
  transfert** — **zéro octet** transféré.
- **SC-006**: **Zéro** contenu enregistré au registre sans vérification d'intégrité réussie.
- **SC-007**: La progression et le débit sont **poussés** en direct ; un client observateur ne réalise
  **aucune** interrogation répétée.
- **SC-008**: Une pause interrompt le transfert en **moins de 5 secondes** et conserve **100 %** des
  fragments déjà obtenus.
- **SC-009**: Une seconde demande portant sur un téléchargement en cours n'engage **aucun** transfert
  supplémentaire.
- **SC-010**: Un modèle en quarantaine ne peut être déployé par **aucun** chemin, y compris en
  contournant l'interface.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9o) |
| --- | --- | --- |
| A1 — reprise sans retransfert des fragments vérifiés | SC-001, SC-004 | T9 `[TEST]` coupure → reprise |
| A2 — intégrité invalide → quarantaine + audit, jamais servi | SC-002, SC-006, SC-010 | T9 `[TEST]` quarantaine |
| A3 — plafond de débit respecté | SC-003 | T9 `[TEST]` plafond |
| Vérification d'espace avant transfert | SC-005 | T4 plafond + vérification d'espace |
| Progression poussée en direct | SC-007, SC-008 | T6 diffusion de progression |
| Enregistrement au registre après vérification | SC-006 | T8 `[INT]` fin → registre des modèles (S09) |

## Assumptions

- **Dépendance à S09** : S10 démarre à partir d'un téléchargement **déjà confirmé** par le dialogue
  de confirmation. Il ne rejoue ni le verdict de tenue mémoire, ni les avertissements, ni la
  confirmation — cette responsabilité appartient entièrement à S09 (Art. 19).
- **Le dépôt publie une liste de fichiers et leurs empreintes** : c'est ce qui rend possibles à la
  fois le découpage en fragments et la vérification. Un dépôt qui n'en publierait pas rend le contenu
  **non vérifiable**, cas traité par FR-015.
- **Plafond de débit** : la valeur de référence du déploiement documenté est de l'ordre de plusieurs
  dizaines de mégaoctets par seconde ; elle est **configurable** et fixée dans le plan. L'exigence de
  la spec est le **respect du plafond**, pas une valeur particulière.
- **Un seul transfert actif par défaut** : choix du document, motivé par le partage du lien réseau et
  la lisibilité de l'exploitation (Art. 9). Le nombre est configurable pour ne pas fermer la porte à
  un lien plus rapide.
- **La quarantaine est terminale et réversible seulement par décision explicite** : un contenu isolé
  n'est jamais réhabilité automatiquement ; le relancer signifie lancer un **nouveau** téléchargement.
- **L'audit est émis, pas garanti ici** : S10 inscrit les mises en quarantaine au journal d'audit ;
  l'inviolabilité de ce journal (chaînage, ajout seul) est apportée par S13. À M2, les deux specs
  sont livrées au même jalon.
- **Les tests n'exigent pas le dépôt public réel** : coupure, reprise, intégrité invalide et plafond
  sont prouvés contre un dépôt simulé, conformément à l'Art. 8 (aucune dépendance externe en
  intégration continue).
- **Profondeur du jalon M2** : la spec est **complète à M2**. Sa vue de gestion se pose dans la
  coquille d'interface de S11, disponible au même jalon.
