# Feature Specification: S09 — Catalogue HF + fit VRAM + confirm-and-warn + fiche modèle

**Feature Branch**: `009-catalogue-hf-fit-vram`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9n du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S09 du plan de specs 9c : « Catalogue HF + fit VRAM + confirm/warn + fiche modèle », références 7a · 7b · 7c · W3, dépend de S06, effort ≈ 9 j-agent, phase 3 (produit modèles), jalon produit M2 (V1 équipe). Décrite par le document comme **la brique la plus originale** du produit. Risque identifié de la phase 3 : **la calibration du verdict de tenue mémoire**.

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J3 de la fiche 9n. Cette spec répond à la question
que ni un dépôt de modèles ni un moteur ne savent traiter : **« est-ce que ce modèle tient sur *mon*
matériel, et à quel prix ? »**

### User Story 1 - Données : le dépôt public est interrogeable, sans le marteler (Priority: P1)

L'administrateur recherche des modèles dans le dépôt public depuis la plateforme, sans quitter
l'outil. Les interrogations répétées ne saturent pas le service distant : les informations récentes
sont réutilisées.

**Why this priority**: c'est la profondeur J1. Sans accès aux métadonnées du dépôt public, il n'y a
ni verdict de tenue mémoire, ni fiche, ni téléchargement. Le cache n'est pas un raffinement : il est
ce qui rend le parcours du catalogue utilisable et respectueux du service distant.

**Independent Test**: rechercher un modèle, constater que ses métadonnées reviennent ; relancer la
même recherche immédiatement et constater qu'aucune nouvelle sollicitation du service distant n'a
lieu — sans qu'aucun verdict de tenue mémoire soit encore calculé.

**Acceptance Scenarios**:

1. **Given** la plateforme connectée, **When** l'administrateur recherche un modèle par mots-clés,
   **Then** il obtient les résultats du dépôt public avec leurs métadonnées (famille, variantes
   disponibles, taille, licence).
2. **Given** une recherche déjà effectuée, **When** la même recherche est relancée dans l'heure,
   **Then** les résultats proviennent du cache local — le service distant **n'est pas resollicité**.
3. **Given** le service distant indisponible ou en erreur, **When** l'administrateur recherche,
   **Then** il reçoit un message **actionnable** nommant la cause (indisponibilité, quota,
   authentification manquante) et l'action attendue — jamais une erreur technique brute.
4. **Given** la plateforme en production, **When** on observe ses flux réseau sortants, **Then** la
   consultation du dépôt public de modèles est la **seule** sortie autorisée (Art. 1).

---

### User Story 2 - Cœur : je sais si un modèle tient, sur quels GPUs, avec quel moteur (Priority: P2)

L'administrateur voit, pour chaque modèle et chaque variante quantifiée, un verdict clair : **il
tient**, **il tient juste**, ou **il ne tient pas** — calculé à partir de son matériel réel et de la
longueur de contexte visée, et assorti du moteur capable de le servir.

**Why this priority**: c'est la profondeur J2 et le cœur de la valeur. C'est ce qui distingue ce
catalogue d'une simple recherche : il répond en fonction **du matériel de cette installation**. C'est
aussi le point de risque de la phase 3 — un verdict faux est pire qu'une absence de verdict, car il
fait perdre un téléchargement de plusieurs dizaines de gigaoctets.

**Independent Test**: soumettre les 20 modèles de référence mesurés, comparer le verdict calculé au
verdict observé réellement sur le matériel, et constater la concordance.

**Acceptance Scenarios**:

1. **Given** un modèle, une variante quantifiée, une longueur de contexte et la topologie matérielle
   réelle, **When** le verdict de tenue est calculé, **Then** il vaut exactement l'une des trois
   valeurs normatives : **il tient**, **il tient juste**, **il ne tient pas**.
2. **Given** le calcul du verdict, **When** on l'examine, **Then** il tient compte du **poids des
   paramètres**, de la **mémoire du cache de contexte** pour la longueur visée, et d'une **marge de
   sécurité**.
3. **Given** les **20 modèles de référence** mesurés sur le matériel réel, **When** on compare le
   verdict calculé au comportement observé, **Then** ils **concordent** pour les 20.
4. **Given** la topologie matérielle, **When** le verdict est calculé, **Then** il tient compte des
   regroupements de cartes possibles — un modèle peut ne pas tenir sur une carte et tenir sur une
   paire.
5. **Given** un modèle et les moteurs disponibles, **When** la compatibilité est évaluée, **Then**
   le système indique **quel moteur** peut le servir, en croisant architecture, format de
   quantification et moteurs installés.
6. **Given** un modèle qu'aucun moteur disponible ne peut servir, **When** il est présenté, **Then**
   cette incompatibilité est **affichée explicitement**, indépendamment du verdict de tenue mémoire.
7. **Given** un téléchargement envisagé, **When** le système prépare les avertissements, **Then** il
   signale les conséquences prévisibles : **éviction d'un modèle résident**, **contrainte de
   licence**, **volume à télécharger et durée estimée**.
8. **Given** le calcul du verdict, **When** on l'exécute deux fois avec les mêmes entrées, **Then**
   il rend **le même résultat** — c'est une fonction déterministe, sans effet de bord.

---

### User Story 3 - Surface : je parcours, je lis la fiche, je confirme en connaissance de cause (Priority: P3)

L'administrateur filtre le catalogue pour ne voir que ce qui tient sur son matériel, ouvre la fiche
d'un modèle pour vérifier sa provenance et sa licence, puis lance le téléchargement — au travers
d'un dialogue bloquant qui lui montre l'impact exact et exige une confirmation explicite.

**Why this priority**: c'est la profondeur J3, portant les critères A2 et A3. Le dialogue de
confirmation est **l'application directe de l'Art. 3** : le silence vaut refus. La fiche est
l'application de l'exigence de transparence sur la provenance.

**Independent Test**: filtrer le catalogue sur les modèles qui tiennent ; ouvrir une fiche et
vérifier qu'elle porte provenance, licence, empreinte d'intégrité et performances locales ; puis
tenter un téléchargement **sans** confirmation et constater le refus.

**Acceptance Scenarios**:

1. **Given** le catalogue, **When** l'administrateur active le filtre de tenue matérielle, **Then**
   seuls les modèles qui tiennent sur son matériel sont listés.
2. **Given** la liste du catalogue, **When** elle s'affiche, **Then** chaque entrée porte son
   **verdict de tenue** sous forme visuelle distinctive pour chacune des trois valeurs.
3. **Given** un modèle, **When** l'administrateur ouvre sa fiche, **Then** elle présente sa
   **provenance** (auteur, dépôt d'origine, date), sa **licence**, l'**empreinte d'intégrité** de ses
   fichiers, et ses **performances mesurées localement** lorsqu'elles existent.
4. **Given** un modèle jamais servi localement, **When** on ouvre sa fiche, **Then** l'absence de
   performances locales est indiquée explicitement plutôt que laissée vide.
5. **Given** un téléchargement demandé **sans confirmation explicite**, **When** la demande est
   traitée, **Then** elle est **refusée** avec le code canonique de confirmation requise — le
   silence vaut refus.
6. **Given** un téléchargement demandé, **When** le dialogue de confirmation s'affiche, **Then** il
   est **bloquant** et présente l'impact — verdict de tenue, éviction prévue, licence, volume et
   durée estimée — **avant** que la confirmation soit possible.
7. **Given** une confirmation donnée, **When** le téléchargement est accepté, **Then** la
   confirmation est **inscrite au journal d'audit** avec son auteur et l'horodatage (Art. 4).

---

### Edge Cases

- **Le modèle n'expose pas les métadonnées nécessaires** (architecture inconnue, taille absente) : le
  verdict est déclaré **indéterminable** plutôt que deviné — un verdict faux coûte un téléchargement
  inutile.
- **Le modèle est sous une licence restrictive ou exige une acceptation préalable** : c'est un
  avertissement explicite du dialogue de confirmation, pas un échec tardif au téléchargement.
- **La longueur de contexte demandée est très supérieure à l'usage réel** : le verdict est calculé
  pour la longueur visée et l'utilisateur voit à quelle longueur le modèle bascule d'une valeur à
  l'autre.
- **Le matériel change après un calcul** (nœud reconfiguré, carte retirée) : les verdicts affichés
  sont recalculés à partir de la topologie courante, jamais servis depuis un cache obsolète.
- **Deux administrateurs confirment le même téléchargement simultanément** : une seule opération est
  engagée ; la seconde est informée qu'elle est déjà en cours.
- **Le cache de métadonnées est périmé alors que le service distant est indisponible** : les données
  périmées sont servies **en le signalant**, plutôt que de rendre le catalogue inutilisable.
- **Le verdict dit « il tient juste »** : ce n'est pas un refus — le téléchargement reste possible,
  avec un avertissement sur le risque de saturation en contexte long.
- **Aucun espace disque disponible pour le téléchargement** : signalé au moment de la confirmation,
  pas après le début du transfert.

## Requirements *(mandatory)*

### Functional Requirements

#### Accès au dépôt public de modèles (J1)

- **FR-001**: Le système DOIT permettre de rechercher des modèles dans le dépôt public et d'obtenir
  leurs métadonnées : famille, variantes quantifiées disponibles, taille, licence, provenance.
- **FR-002**: Le système DOIT **mettre en cache** les métadonnées obtenues pendant **1 heure**, afin
  de ne pas resolliciter le service distant pour une recherche identique.
- **FR-003**: Toute erreur du service distant DOIT être traduite en un message **actionnable**
  nommant la cause et l'action attendue — jamais une erreur technique brute.
- **FR-004**: Lorsque le cache est périmé et le service distant indisponible, le système DOIT servir
  les données périmées **en le signalant**, plutôt que de rendre le catalogue inutilisable.
- **FR-005**: La consultation du dépôt public de modèles DOIT être la **seule** sortie réseau du
  système en production (Art. 1).

#### Verdict de tenue mémoire (J2)

- **FR-006**: Le système DOIT calculer, pour un modèle, une variante quantifiée, une longueur de
  contexte et la topologie matérielle réelle, un **verdict de tenue** valant exactement l'une des
  trois valeurs normatives : **il tient**, **il tient juste**, **il ne tient pas**.
- **FR-007**: Le calcul DOIT prendre en compte le **poids des paramètres**, la **mémoire du cache de
  contexte** pour la longueur visée, et une **marge de sécurité**.
- **FR-008**: Le calcul DOIT tenir compte des **regroupements de cartes** possibles : un verdict est
  rendu par configuration matérielle envisageable, pas seulement pour une carte isolée.
- **FR-009**: Le calcul DOIT être une **fonction déterministe et pure**, testable isolément, sans
  effet de bord ni dépendance à l'état du système.
- **FR-010**: Le verdict DOIT être **calibré** contre des mesures réelles effectuées sur un jeu de
  **20 modèles de référence**.
- **FR-011**: Lorsque les métadonnées nécessaires sont absentes, le verdict DOIT être déclaré
  **indéterminable** — il NE DOIT jamais être deviné.
- **FR-012**: Les verdicts affichés DOIVENT être recalculés à partir de la **topologie courante**,
  jamais servis depuis un cache devenu obsolète après un changement matériel.

#### Compatibilité moteur (J2)

- **FR-013**: Le système DOIT indiquer **quel moteur** peut servir un modèle, en croisant son
  architecture, son format de quantification et les moteurs disponibles.
- **FR-014**: Une incompatibilité moteur DOIT être affichée **explicitement** et **indépendamment**
  du verdict de tenue mémoire — un modèle peut tenir en mémoire et n'être servi par aucun moteur.

#### Avertissements (J2)

- **FR-015**: Le système DOIT produire, avant tout téléchargement, les avertissements pertinents :
  **éviction prévisible** d'un modèle résident, **contrainte de licence**, **volume à télécharger et
  durée estimée**, et **espace disque insuffisant** le cas échéant.

#### Catalogue, fiche et confirmation (J3)

- **FR-016**: Le système DOIT permettre de **filtrer** le catalogue sur les modèles qui tiennent sur
  le matériel de l'installation.
- **FR-017**: Chaque entrée du catalogue DOIT porter son **verdict de tenue** sous une forme visuelle
  distinctive pour chacune des trois valeurs.
- **FR-018**: La fiche d'un modèle DOIT présenter sa **provenance**, sa **licence**, l'**empreinte
  d'intégrité** de ses fichiers et ses **performances mesurées localement**.
- **FR-019**: L'absence de performances locales DOIT être indiquée explicitement, jamais laissée
  vide.
- **FR-020**: Aucun téléchargement NE DOIT être engagé sans **confirmation explicite** : une demande
  dépourvue de confirmation est **refusée** avec le code canonique de confirmation requise (Art. 3 —
  le silence vaut refus).
- **FR-021**: Le dialogue de confirmation DOIT être **bloquant** et présenter l'impact complet —
  verdict, éviction prévue, licence, volume, durée — **avant** que la confirmation soit possible
  (confirm-and-warn).
- **FR-022**: Toute confirmation DOIT être **inscrite au journal d'audit** avec son auteur et son
  horodatage (Art. 4).
- **FR-023**: Deux confirmations simultanées du même téléchargement NE DOIVENT engager **qu'une
  seule** opération.

#### Preuves (J4)

- **FR-024**: L'exactitude des verdicts sur les 20 modèles de référence, et le refus de tout
  téléchargement non confirmé, DOIVENT être prouvés par des tests dédiés, le refus étant vérifié de
  bout en bout.

### Hors périmètre *(Art. 20 — YAGNI)*

- L'**exécution** du téléchargement — file d'attente, reprise après coupure, vérification
  d'intégrité, quarantaine, plafond de débit → **S10**. S09 **décide et fait confirmer** ; S10
  **télécharge**.
- Le **placement effectif** du modèle sur un nœud, l'éviction et le hot-swap → **S06**. S09 **prévoit**
  l'éviction dans ses avertissements ; S06 l'exécute.
- La **correspondance format ↔ moteur** elle-même → **S07**, dont S09 est consommateur.
- La **coquille d'interface** et le client généré → **S11**.
- Le **contrôle d'accès** déterminant qui peut télécharger, et le flux d'approbation pour les membres
  → **S13**.
- Les **performances mesurées localement** sont **lues** par la fiche ; leur production relève de
  l'observabilité (**S02**, **S15**) et de l'usage réel.

### Key Entities

- **Modèle** : famille publiée dans le dépôt public. Attributs : nom, auteur, provenance, licence,
  architecture. Racine de l'arbre des modèles (Model → Variant → Alias → Instance).
- **Variante** : déclinaison quantifiée d'un modèle. Attributs : format de quantification, taille des
  fichiers, empreinte d'intégrité.
- **Verdict de tenue** : résultat normatif à trois valeurs — **il tient**, **il tient juste**, **il ne
  tient pas** — pour un couple (variante, configuration matérielle) et une longueur de contexte.
  *Terme normatif — « compatible », « ok » et « feasible » sont des synonymes interdits (Art. 12).*
- **Avertissement** : conséquence prévisible d'un téléchargement, présentée avant confirmation
  (éviction, licence, volume, espace disque).
- **Confirmation** : acte explicite et tracé autorisant une opération coûteuse. *Le dialogue est un
  « confirm-and-warn » — « popup » et « are-you-sure » sont des synonymes interdits.*

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Le verdict de tenue calculé **concorde avec le comportement
  réel** pour les **20 modèles de référence** mesurés — soit **20/20**.
- **SC-002** *(critère A2)*: **Zéro** téléchargement engagé sans confirmation explicite : toute
  demande non confirmée est refusée avec le code canonique attendu, et **100 %** des confirmations
  sont retrouvables dans le journal d'audit.
- **SC-003** *(critère A3)*: La fiche d'un modèle présente **les quatre** informations exigées —
  provenance, licence, empreinte d'intégrité, performances locales (ou leur absence explicite) —
  pour **100 %** des modèles du catalogue.
- **SC-004**: Une recherche répétée dans l'heure ne provoque **aucune** sollicitation supplémentaire
  du service distant.
- **SC-005**: Le calcul du verdict est **déterministe** : deux exécutions avec les mêmes entrées
  rendent un résultat identique dans **100 %** des cas.
- **SC-006**: Un modèle dont les métadonnées sont incomplètes reçoit le verdict **indéterminable** —
  **zéro** verdict deviné.
- **SC-007**: Toute erreur du service distant produit un message nommant la cause et l'action
  attendue — **zéro** erreur technique brute présentée à l'utilisateur.
- **SC-008**: Un changement de topologie matérielle est reflété dans les verdicts affichés **sans
  intervention manuelle**.
- **SC-009**: Le dialogue de confirmation présente **l'intégralité** des avertissements applicables
  avant que la confirmation soit possible — vérifié pour chaque famille d'avertissement.
- **SC-010**: En production, une observation des flux réseau sortants ne révèle **aucune** connexion
  autre que celle du dépôt public de modèles (Art. 1).

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9n) |
| --- | --- | --- |
| A1 — verdict exact pour 20 modèles de référence | SC-001, SC-005, SC-006 | T13 `[TEST]` verdicts exacts · T3 calibration sur 20 modèles mesurés |
| A2 — aucun téléchargement sans confirmation tracée | SC-002, SC-009 | T12 `[TEST]` refus sans confirmation, de bout en bout |
| A3 — fiche : provenance, licence, intégrité, perfs locales | SC-003 | T13 `[TEST]` fiche complète |
| Cache des métadonnées | SC-004, SC-007 | T1 accès au dépôt public + cache |
| Verdict lié à la topologie réelle | SC-008 | T11 `[INT]` le verdict lit la topologie (S06) |
| Confinement réseau | SC-010 | Contrôle de flux sortants (S01 · S21) |

## Assumptions

- **Dépendance à S06** : la topologie matérielle réelle — cartes, mémoire disponible, appairages,
  regroupements possibles — est **fournie par le superviseur**. S09 ne découvre pas le matériel : il
  consomme ce que S06 découvre (`T11`).
- **Partage de responsabilité avec S06 sur la tenue mémoire** : à M1, S06 utilise un calcul interne
  suffisant pour placer. À M2, **S09 devient la source unique** du verdict, calibrée sur mesures
  réelles ; S06 la consomme sans changer de contrat (Art. 19).
- **Calibration = risque assumé de la phase 3** : le document identifie explicitement la calibration
  du verdict comme le risque de cette phase. Les 20 modèles de référence sont **mesurés sur le
  matériel réel**, ce qui implique une campagne de mesure hors intégration continue — la CI ne touche
  jamais un GPU (Art. 8).
- **Marge de sécurité** : le calcul intègre une marge au-dessus du besoin théorique. Sa valeur exacte
  est un paramètre du plan, ajusté par la calibration ; l'exigence de la spec est la **concordance
  20/20**, pas une valeur de marge particulière.
- **« Il tient juste » n'est pas un refus** : cette valeur intermédiaire autorise le téléchargement en
  avertissant du risque en contexte long. C'est un choix de l'Art. 3 — informer plutôt qu'interdire.
- **État de l'art consigné (Art. 22)** : l'expérience de parcours et de confirmation s'inspire des
  gestionnaires de modèles existants ; la fiche de transparence s'inspire des pratiques de publication
  de modèles ouverts documentant provenance et licence. Ce qui est **écarté** : le téléchargement
  implicite au premier usage, pratique courante ailleurs mais contraire à l'Art. 3. Les références
  précises sont consignées dans le plan.
- **Le dépôt public exige parfois une authentification** : un jeton de lecture peut être nécessaire
  pour certains modèles ; son absence produit un message actionnable (FR-003), pas un échec opaque.
- **Profondeur du jalon M2** : la spec est **complète à M2**. Ses vues se posent dans la coquille
  d'interface de S11, disponible au même jalon.
