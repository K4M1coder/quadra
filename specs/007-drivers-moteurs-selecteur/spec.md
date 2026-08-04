# Feature Specification: S07 — Drivers moteurs gérés / attachés + sélecteur

**Feature Branch**: `007-drivers-moteurs-selecteur`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9l du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S07 du plan de specs 9c : « Drivers moteurs gérés / attachés + sélecteur par modèle », référence 7f, dépend de S06, effort ≈ 7.5 j-agent, phase 2 (cœur runtime). **Profondeur de jalon : J1–J2 à M1 (drivers sans interface), J3–J4 complétés à M2** (Art. 20).

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J3 de la fiche 9l. Cette spec est **l'exécution des
Art. 6 et 18** : elle est le mécanisme qui rend les moteurs upstream remplaçables sans jamais les
forker ni toucher au superviseur.

### User Story 1 - Contrat : ajouter un moteur, c'est écrire un driver (Priority: P1)

Un développeur veut prendre en charge un nouveau moteur d'inférence. Il écrit une unique
implémentation du contrat de driver et l'enregistre. **Aucun autre fichier du projet n'est modifié** :
ni le superviseur, ni l'ordonnanceur, ni la passerelle.

**Why this priority**: c'est la profondeur J1 et le critère A1. C'est la tranche qui donne sa valeur
à toutes les autres : sans contrat, chaque moteur ajouté contamine le reste du code et l'Art. 6
(réutiliser sans forker) devient inapplicable.

**Independent Test**: écrire un driver factice supplémentaire, l'enregistrer, et constater par
comparaison du dépôt qu'aucun fichier existant hors du nouveau driver et de son enregistrement n'a
été modifié — puis vérifier que le superviseur sait le piloter.

**Acceptance Scenarios**:

1. **Given** le contrat de driver défini, **When** un développeur ajoute la prise en charge d'un
   nouveau moteur, **Then** il lui suffit d'écrire **une implémentation du contrat** et de
   l'enregistrer : **zéro modification** ailleurs dans le projet.
2. **Given** le contrat de driver, **When** on l'inspecte, **Then** il couvre l'ensemble du cycle de
   vie exigé : démarrage, arrêt, vérification de santé, exposition des mesures et accès aux journaux.
3. **Given** un driver enregistré, **When** le superviseur pilote un moteur, **Then** il le fait
   **exclusivement au travers du contrat** — il ne référence aucun moteur par son nom.
4. **Given** l'ensemble du code hors des drivers, **When** on recherche une référence à un moteur
   nommé, **Then** on n'en trouve **aucune** (Art. 18).

---

### User Story 2 - Drivers : moteurs gérés installés, backends distants attachés (Priority: P2)

L'administrateur dispose de deux moteurs **gérés** — installés et supervisés par la plateforme — et
peut **attacher** n'importe quel service d'inférence externe compatible en fournissant simplement son
adresse. Quand un service attaché devient injoignable, il est retiré du routage en quelques secondes.

**Why this priority**: c'est la profondeur J2, complète au jalon M1. Elle porte le critère A2 et rend
la plateforme réellement ouverte : un moteur qui n'est pas géré reste utilisable.

**Independent Test**: attacher un service externe simulé, vérifier qu'il sert des requêtes, puis le
rendre injoignable et mesurer le délai au bout duquel il ne reçoit plus de trafic.

**Acceptance Scenarios**:

1. **Given** la plateforme, **When** l'administrateur installe un moteur **géré**, **Then** celui-ci
   est démarré, configuré et supervisé par la plateforme, qui expose ses journaux et ses mesures.
2. **Given** un service d'inférence externe compatible, **When** l'administrateur l'**attache** en
   fournissant son adresse, **Then** il devient utilisable pour servir des modèles, **sans** être
   installé ni supervisé par la plateforme.
3. **Given** un service **attaché** qui devient injoignable, **When** sa vérification de santé
   échoue, **Then** il est **retiré du routage en moins de 10 secondes** — aucune requête ne lui est
   plus adressée.
4. **Given** un service attaché retiré du routage, **When** il redevient joignable, **Then** il est
   réintégré automatiquement.
5. **Given** aucun moteur disponible pour un modèle demandé, **When** une requête arrive, **Then**
   elle reçoit une erreur de moteur indisponible portant le code canonique correspondant.
6. **Given** l'état d'un moteur, **When** il change, **Then** il suit la machine à états normative :
   chargement → prêt → en drainage → arrêté, avec l'issue **défaillant** (au plus trois tentatives
   avant arrêt).

---

### User Story 3 - Sélecteur : le bon moteur est choisi automatiquement, ou imposé (Priority: P3)

L'administrateur n'a pas à savoir quel moteur convient à quel format de modèle : la plateforme choisit
automatiquement selon le format de quantification. S'il veut imposer un moteur pour un modèle
particulier, il le peut.

**Why this priority**: c'est la profondeur J3, portant le critère A3. Le choix automatique est ce qui
rend le catalogue (S09) utilisable sans expertise ; la possibilité de forcer est ce qui évite que
l'automatisme devienne une impasse (Art. 3 — l'humain garde la décision).

**Independent Test**: enregistrer des modèles de formats de quantification différents et constater
que chacun se voit attribuer le moteur attendu ; puis forcer manuellement un autre moteur et vérifier
que le choix manuel l'emporte.

**Acceptance Scenarios**:

1. **Given** un modèle dont le format de quantification est pris en charge par un moteur géré
   principal, **When** le sélecteur choisit automatiquement, **Then** ce moteur est retenu.
2. **Given** un modèle au format de quantification destiné au moteur géré secondaire, **When** le
   sélecteur choisit automatiquement, **Then** ce second moteur est retenu.
3. **Given** un choix automatique effectué, **When** l'administrateur **impose** un autre moteur pour
   ce modèle, **Then** son choix **l'emporte** sur l'automatisme.
4. **Given** un modèle dont le format n'est compatible avec aucun moteur disponible, **When** le
   sélecteur est sollicité, **Then** il le signale explicitement plutôt que de retenir un moteur
   incompatible.
5. **Given** la correspondance entre formats de quantification et moteurs, **When** on la consulte,
   **Then** elle est **versionnée dans le dépôt** et constitue la source unique de la décision
   (Art. 19).
6. **Given** l'interface d'administration des moteurs, **When** l'administrateur l'ouvre, **Then**
   il voit chaque moteur sous forme de fiche, peut en installer ou en attacher un, consulter ses
   **journaux en direct**, et choisir le moteur d'un modèle.

---

### Edge Cases

- **Un service attaché répond mais renvoie des réponses non conformes au contrat d'inférence** : il
  est traité comme défaillant — la conformité fait partie de la santé, pas seulement la joignabilité.
- **Un service attaché est lent sans être injoignable** : la vérification de santé doit trancher sur
  un délai borné, sinon le retrait en moins de 10 secondes n'est pas tenable.
- **Un moteur géré et un service attaché servent le même modèle** : la situation est admise ; le
  routage entre eux relève du placement, pas du driver.
- **La correspondance format ↔ moteur est modifiée alors que des instances tournent** : les instances
  en cours ne sont pas déplacées ; la nouvelle correspondance s'applique aux placements suivants.
- **Un driver tiers échoue à s'enregistrer** (contrat incomplet) : l'échec est détecté au démarrage
  et nommé, plutôt que découvert au premier appel.
- **Un service attaché est injoignable pendant qu'il sert une requête** : la requête échoue proprement
  avec le code canonique de moteur indisponible ; elle n'est pas réémise automatiquement si la
  génération avait commencé.
- **L'adresse d'un service attaché pointe hors de l'infrastructure** : c'est une violation de l'Art. 1
  (les données restent sur site) — l'attachement d'un service hors du périmètre doit être refusé ou
  explicitement confirmé par un administrateur averti.

## Requirements *(mandatory)*

### Functional Requirements

#### Contrat de driver (J1 — M1)

- **FR-001**: Le système DOIT définir un **contrat de driver unique** couvrant le cycle de vie d'un
  moteur : démarrage, arrêt, vérification de santé, exposition des mesures, accès aux journaux.
- **FR-002**: Le système DOIT fournir un **registre** de drivers permettant d'enregistrer une
  implémentation supplémentaire sans modifier le code existant.
- **FR-003**: Prendre en charge un nouveau moteur NE DOIT exiger que **l'écriture d'une
  implémentation du contrat et son enregistrement** — aucune autre modification du projet.
- **FR-004**: Aucun composant hors des drivers NE DOIT référencer un moteur **par son nom** : tout
  passe par le contrat (Art. 18).
- **FR-005**: Un driver dont l'implémentation du contrat est incomplète DOIT être rejeté **au
  démarrage**, avec un message le nommant.

#### Moteurs gérés et attachés (J2 — M1)

- **FR-006**: Le système DOIT prendre en charge des moteurs **gérés** : installés, démarrés,
  configurés et supervisés par la plateforme, avec exposition de leurs journaux et de leurs mesures.
- **FR-007**: Le système DOIT prendre en charge des moteurs **attachés** : services d'inférence
  externes compatibles, joints par leur adresse, **ni installés ni supervisés** par la plateforme.
- **FR-008**: Le système DOIT retirer du routage un moteur attaché devenu injoignable en **moins de
  10 secondes**.
- **FR-009**: Le système DOIT réintégrer automatiquement au routage un moteur attaché redevenu
  joignable et conforme.
- **FR-010**: La vérification de santé d'un moteur attaché DOIT couvrir non seulement sa
  **joignabilité** mais aussi la **conformité** de ses réponses au contrat d'inférence.
- **FR-011**: Le système DOIT retourner une erreur portant le **code canonique de moteur
  indisponible** lorsqu'aucun moteur ne peut servir un modèle demandé.
- **FR-012**: L'état d'un moteur DOIT suivre la machine à états normative : chargement → prêt → en
  drainage → arrêté, avec l'issue défaillant après **au plus trois tentatives**.
- **FR-013**: Les moteurs upstream DOIVENT être consommés **tels quels**, sans modification de leur
  code (Art. 6). Toute adaptation vit dans le driver.

#### Sélecteur (J3 — M2)

- **FR-014**: Le système DOIT **choisir automatiquement** le moteur d'un modèle en fonction de son
  **format de quantification**.
- **FR-015**: Le système DOIT permettre à un administrateur d'**imposer** un moteur pour un modèle
  donné ; ce choix manuel **l'emporte** sur le choix automatique.
- **FR-016**: La **correspondance entre formats de quantification et moteurs** DOIT être versionnée
  dans le dépôt et constituer la **source unique** de la décision de sélection (Art. 19).
- **FR-017**: Le système DOIT signaler explicitement qu'aucun moteur compatible n'existe pour un
  format donné, plutôt que de retenir un moteur incompatible.
- **FR-018**: Une modification de la correspondance NE DOIT **pas** déplacer les instances en cours ;
  elle s'applique aux placements suivants.

#### Interface d'administration des moteurs (J3 — M2)

- **FR-019**: L'interface DOIT présenter chaque moteur sous forme de fiche indiquant son type (géré
  ou attaché), son état et sa santé.
- **FR-020**: L'interface DOIT permettre d'**installer** un moteur géré et d'**attacher** un service
  externe.
- **FR-021**: L'interface DOIT permettre de consulter les **journaux en direct** d'un moteur.
- **FR-022**: L'interface DOIT permettre de choisir le moteur associé à un modèle.

#### Confinement réseau (transverse, Art. 1)

- **FR-023**: L'attachement d'un service situé hors de l'infrastructure DOIT être refusé, ou exiger
  une confirmation explicite et tracée d'un administrateur averti de la sortie de périmètre.

#### Preuves (J4 — M2)

- **FR-024**: L'ajout d'un moteur sans modification du reste du projet, et le retrait en moins de
  10 secondes d'un moteur attaché injoignable, DOIVENT être prouvés par des tests dédiés.

### Hors périmètre *(Art. 20 — YAGNI)*

- La **découverte du matériel**, les nœuds, le placement, l'éviction et le hot-swap → **S06**. S07
  fournit le moyen de piloter un moteur ; S06 décide **quand** et **où**.
- Le **verdict de tenue mémoire** et la compatibilité annoncée au catalogue → **S09**. S07 fournit la
  correspondance format ↔ moteur, que S09 consomme pour annoncer la compatibilité.
- Le **téléchargement** des modèles et de leurs variantes → **S10**.
- Le **coquille d'interface**, la navigation et le client généré → **S11**. S07 fournit les vues
  propres aux moteurs, posées dans cette coquille.
- L'**ordonnancement** et les caps → **S05**.
- La **réplication d'un même modèle sur plusieurs machines** et la bascule → **S20**.
- L'**offload** vers la mémoire vive ou le stockage → **S18**, qui s'appuiera sur un driver dédié.

### Key Entities

- **Driver** : implémentation du contrat de pilotage d'un moteur. Attributs : identifiant, type de
  moteur pris en charge, formats de quantification compatibles.
- **Moteur géré** : moteur installé et supervisé par la plateforme. *Terme normatif — « embedded » et
  « managed/unmanaged » sont des synonymes interdits (Art. 12).*
- **Moteur attaché** : service d'inférence externe joint par son adresse, non supervisé. *Terme
  normatif — « external » est un synonyme interdit.*
- **Correspondance format ↔ moteur** : table versionnée associant chaque format de quantification aux
  moteurs capables de le servir. Source unique de la sélection automatique.
- **Variante** : déclinaison quantifiée d'un modèle, rattachée à l'arbre des modèles de la taxonomie
  (Model → Variant → Alias → Instance).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: L'ajout d'un moteur se solde par **un seul fichier de driver
  nouveau et son enregistrement** : une comparaison du dépôt montre **zéro** modification de fichier
  existant hors de l'enregistrement.
- **SC-002** *(critère A2)*: Un moteur attaché devenu injoignable ne reçoit plus aucune requête
  **moins de 10 secondes** après sa première vérification de santé en échec.
- **SC-003** *(critère A3)*: Le choix automatique attribue le **moteur attendu** à **100 %** des
  formats de quantification référencés dans la correspondance versionnée.
- **SC-004**: Une recherche automatisée dans le code hors drivers ne trouve **aucune** référence à un
  moteur nommé.
- **SC-005**: Un choix de moteur imposé par un administrateur l'emporte sur l'automatisme dans
  **100 %** des cas.
- **SC-006**: Un moteur attaché redevenu joignable est réintégré au routage **sans intervention
  manuelle**.
- **SC-007**: Un moteur attaché qui répond de façon non conforme au contrat d'inférence est traité
  comme défaillant et retiré du routage, au même titre qu'un moteur injoignable.
- **SC-008**: Un driver au contrat incomplet est rejeté **au démarrage**, jamais au premier appel.
- **SC-009**: Aucun moteur upstream n'est modifié : le dépôt ne contient **aucun** correctif appliqué
  au code d'un moteur (Art. 6).

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9l) |
| --- | --- | --- |
| A1 — un moteur = un driver, zéro changement ailleurs | SC-001, SC-004, SC-009 | T11 `[TEST]` ajout sans changement |
| A2 — moteur attaché injoignable retiré < 10 s | SC-002, SC-006, SC-007 | T11 `[TEST]` retrait < 10 s |
| A3 — sélection automatique par format de quantification | SC-003, SC-005 | T5 correspondance versionnée · T6 sélecteur |
| Pilotage exclusivement par contrat | SC-004 | T10 `[INT]` superviseur via drivers (S06) |
| Rejet d'un driver incomplet | SC-008 | T1 contrat + registre |

## Assumptions

- **Profondeur de jalon — coupure explicite** : au jalon **M1**, seuls J1 et J2 sont dus (contrat,
  drivers gérés et attachés, correspondance, sélecteur) — **sans interface**. J3 (interface des
  moteurs, journaux en direct, sélecteur visuel) et J4 sont complétés au jalon **M2**. Rien de J3 ne
  DOIT être anticipé à M1 (Art. 20).
- **Dépendance à S06** : le superviseur pilote le cycle de vie ; S07 lui fournit le contrat au travers
  duquel il le fait. L'interface de S07 se pose dans la coquille d'interface de S11, disponible à M2.
- **Deux moteurs gérés au départ** : un moteur principal pour les formats de quantification
  compressés et un moteur secondaire pour le format de fichier unique. D'autres moteurs sont prévus
  comme **drivers optionnels** et n'entrent pas dans le périmètre initial (Art. 20).
- **La correspondance est une donnée, pas du code** : elle est versionnée et lisible, ce qui permet de
  l'amender sans redéployer la logique de sélection (Art. 19).
- **Les tests s'exécutent contre le moteur factice** : le retrait en moins de 10 secondes et l'ajout
  sans modification sont prouvés avec des drivers et services simulés, sans GPU (Art. 8). Le moteur
  factice de S03 sert lui-même de service attaché simulé.
- **Confinement réseau** : un service attaché reste, par défaut, à l'intérieur de l'infrastructure.
  L'Art. 1 interdit toute sortie de données ; attacher un service externe au périmètre est donc une
  action à confirmation explicite, pas une simple configuration.
- **Pas de réémission d'une génération entamée** : si un moteur disparaît en cours de génération, la
  requête échoue proprement. La réinjection des requêtes **non entamées** est un mécanisme de S20, pas
  de S07.
