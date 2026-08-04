# Feature Specification: S13 — Permissions par rôle + éditeur de rôles + approbations + audit

**Feature Branch**: `013-rbac-roles-approbations-audit`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9r du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S13 du plan de specs 9c : « Orgs / teams / RBAC + éditeur de rôles + approbations + audit », références 8c · 8h · 8i · 6i · W4, dépend de S04, effort ≈ 7 j-agent, phase 4 (gouvernance & observabilité), jalon produit M2 (V1 équipe). **Revue humaine obligatoire** sur les permissions — risque identifié de la phase 4.

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J3 de la fiche 9r. Cette spec est **la confiance du
produit** : elle applique les Art. 4 (rien n'est falsifiable) et 5 (le serveur décide, jamais l'UI).

### User Story 1 - Fondations : la matrice de permissions est une source de vérité exécutable (Priority: P1)

Le mainteneur dispose d'une matrice de permissions — quel rôle peut faire quelle action sur quelle
ressource — décrite **une seule fois**, appliquée automatiquement sur chaque route du serveur, et
d'où sont **générés** les tests qui la vérifient.

**Why this priority**: c'est la profondeur J1 et l'application directe de l'Art. 19. Une matrice
décrite dans un document et réimplémentée à la main dans le code produit deux vérités qui divergent :
c'est la définition même du bug de sécurité futur.

**Independent Test**: modifier une entrée de la matrice, régénérer, et constater que les tests
correspondants changent **sans qu'aucun test soit écrit à la main** — puis vérifier que chaque route
du serveur est effectivement couverte.

**Acceptance Scenarios**:

1. **Given** la matrice de permissions du document, **When** elle est transcrite, **Then** elle
   existe comme **fichier de description unique et versionné**, source de vérité du projet.
2. **Given** cette description, **When** les tests de permissions sont produits, **Then** ils sont
   **générés** à partir d'elle — **aucun** n'est écrit à la main (Art. 19).
3. **Given** les tests générés, **When** ils s'exécutent, **Then** ils couvrent **100 %** des couples
   (rôle, ressource, action) de la matrice.
4. **Given** chaque route du serveur, **When** on l'inspecte, **Then** elle **déclare** la permission
   qu'elle exige — aucune route n'est laissée sans déclaration.
5. **Given** une modification de la matrice, **When** elle est appliquée, **Then** les tests générés
   et les contrôles des routes changent **ensemble**, sans intervention manuelle.

---

### User Story 2 - Cœur : approbations tracées, audit infalsifiable, garde-fous (Priority: P2)

L'administrateur constate qu'un membre ne peut pas déclencher seul une action coûteuse : il en fait
la demande, quelqu'un d'habilité approuve ou refuse, et tout est tracé. Le journal d'audit ne peut
pas être altéré sans que cela se voie. Enfin, le système empêche de supprimer le dernier
administrateur.

**Why this priority**: c'est la profondeur J2. C'est ce qui rend le produit exploitable en équipe
sans que le mainteneur soit un point de passage — tout en garantissant qu'aucune action sensible
n'échappe à la trace (Art. 4).

**Independent Test**: soumettre une demande d'action coûteuse en tant que membre, l'approuver, puis
tenter de modifier une entrée ancienne du journal d'audit et constater que la vérification de la
chaîne échoue.

**Acceptance Scenarios**:

1. **Given** un membre sans droit d'exécuter directement une action coûteuse, **When** il la
   demande, **Then** une **demande d'approbation** est créée et il en est informé, avec le code
   canonique indiquant qu'une approbation est requise.
2. **Given** une demande d'approbation, **When** elle évolue, **Then** elle suit la machine à états
   normative : demandée → approuvée **ou** refusée, avec l'issue **expirée** faute de décision.
3. **Given** une demande d'approbation, **When** elle change d'état, **Then** **chaque transition
   est auditée**.
4. **Given** une demande approuvée, **When** l'approbation est donnée, **Then** l'action demandée
   devient exécutable — et pas avant.
5. **Given** une action sensible quelconque, **When** elle est réalisée, **Then** une entrée d'audit
   est créée, nommée selon la convention **entité.verbe** du projet, portant l'auteur, l'horodatage
   et le contexte.
6. **Given** le journal d'audit, **When** on tente de **modifier ou supprimer** une entrée existante,
   **Then** l'opération est impossible : le journal n'accepte que l'**ajout**.
7. **Given** le journal d'audit, **When** on en vérifie l'intégrité, **Then** chaque entrée est liée
   à la précédente de sorte qu'une altération, même ancienne, **rende la vérification invalide** et
   désigne le point de rupture.
8. **Given** un unique administrateur restant, **When** on tente de le supprimer ou de le
   rétrograder, **Then** l'opération est **refusée** — le système ne peut pas se retrouver sans
   administrateur.
9. **Given** le journal d'audit, **When** la politique de conservation s'applique, **Then** les
   entrées sont conservées **2 ans**.

---

### User Story 3 - Surface : j'édite les rôles et je lis l'audit (Priority: P3)

L'administrateur ajuste les permissions d'un rôle depuis une interface dédiée, et consulte le journal
d'audit pour comprendre qui a fait quoi, quand.

**Why this priority**: c'est la profondeur J3. Elle rend la gouvernance opérable sans accès direct
aux fichiers de configuration ni à la base.

**Independent Test**: modifier un rôle depuis l'interface, vérifier l'effet immédiat sur les droits
d'un utilisateur de ce rôle, puis retrouver la modification dans le journal d'audit.

**Acceptance Scenarios**:

1. **Given** l'interface d'édition des rôles, **When** l'administrateur modifie les permissions d'un
   rôle, **Then** la modification prend effet et est **auditée**.
2. **Given** un utilisateur d'un rôle modifié, **When** il agit, **Then** ses droits reflètent la
   nouvelle définition.
3. **Given** le journal d'audit, **When** l'administrateur le consulte, **Then** il peut y filtrer
   les actions par auteur, par type et par période.
4. **Given** une même vue du produit, **When** elle est ouverte par des utilisateurs de rôles
   différents, **Then** chacun voit ce que son rôle autorise — l'écart étant **cosmétique**, la
   décision restant serveur.

---

### Edge Cases

- **Un utilisateur contourne l'interface et appelle le serveur directement** : la permission est
  vérifiée **côté serveur** et l'accès est refusé avec le code canonique correspondant (Art. 5).
- **Une route est ajoutée sans déclarer sa permission** : c'est détecté mécaniquement et bloque la
  fusion — une route non déclarée est une route ouverte par défaut, ce qui est inacceptable.
- **Une organisation veut des permissions différentes du standard** : une surcharge par organisation
  est possible, sans jamais permettre d'élargir au-delà de ce que la matrice autorise.
- **Une demande d'approbation reste sans décision** : elle **expire**, plutôt que de rester en
  suspens indéfiniment ; l'expiration est auditée.
- **Celui qui demande est aussi celui qui pourrait approuver** : la règle est explicite — une demande
  ne peut pas être approuvée par son propre auteur.
- **Le journal d'audit devient très volumineux** : la conservation de 2 ans s'applique, et
  l'archivage d'anciennes entrées ne doit pas rompre la vérification de la chaîne restante.
- **Une entrée d'audit ne peut pas être écrite** (défaillance de stockage) : l'action sensible
  correspondante est **refusée** — un composant qui ne peut pas rendre compte n'agit pas (Art. 4).
- **Deux actions sensibles simultanées** : la chaîne d'audit reste cohérente et ordonnée, sans
  entrée orpheline ni rupture.

## Requirements *(mandatory)*

### Functional Requirements

#### Matrice de permissions (J1 — chemin à revue humaine)

- **FR-001**: La matrice de permissions DOIT exister comme **description unique et versionnée**
  (couples rôle × ressource × action), source de vérité du projet (Art. 19).
- **FR-002**: Les tests de permissions DOIVENT être **générés** à partir de cette description —
  **aucun** écrit à la main.
- **FR-003**: Les tests générés DOIVENT couvrir **100 %** des couples de la matrice.
- **FR-004**: Chaque route du serveur DOIT **déclarer** la permission qu'elle exige.
- **FR-005**: Une route dépourvue de déclaration de permission DOIT être **détectée mécaniquement**
  et bloquer la fusion.
- **FR-006**: Le système DOIT prendre en charge les rôles du modèle de gouvernance du projet, avec
  possibilité de **surcharge par organisation**, sans jamais élargir au-delà de la matrice.

#### Application côté serveur (J1 — Art. 5)

- **FR-007**: Toute permission DOIT être vérifiée **côté serveur**, indépendamment de l'interface.
- **FR-008**: Un accès non autorisé DOIT être refusé avec le **code canonique de permission
  refusée**, y compris lorsque l'interface est contournée.

#### Approbations (J2)

- **FR-009**: Une action coûteuse demandée par un utilisateur qui n'a pas le droit de l'exécuter
  directement DOIT créer une **demande d'approbation**, signalée par le code canonique dédié.
- **FR-010**: Une demande d'approbation DOIT suivre la machine à états normative : demandée →
  approuvée ou refusée, avec l'issue **expirée** faute de décision.
- **FR-011**: **Chaque transition** d'une demande d'approbation DOIT être auditée.
- **FR-012**: L'action demandée NE DOIT devenir exécutable **qu'après** approbation.
- **FR-013**: Une demande NE DOIT **pas** pouvoir être approuvée par son propre auteur.

#### Audit infalsifiable (J2 — Art. 4)

- **FR-014**: Toute action sensible DOIT produire une **entrée d'audit** portant l'auteur,
  l'horodatage, l'action et son contexte.
- **FR-015**: Les entrées d'audit DOIVENT être nommées selon la convention **entité.verbe** du
  projet.
- **FR-016**: Le journal d'audit DOIT n'accepter que l'**ajout** : aucune entrée existante NE DOIT
  pouvoir être modifiée ni supprimée.
- **FR-017**: Chaque entrée DOIT être **liée à la précédente** de sorte qu'une altération, même
  ancienne, rende la vérification de l'ensemble **invalide** et **désigne le point de rupture**.
- **FR-018**: Le système DOIT fournir un moyen de **vérifier** l'intégrité du journal.
- **FR-019**: Si une entrée d'audit ne peut pas être écrite, l'action sensible correspondante DOIT
  être **refusée** (Art. 4).
- **FR-020**: Les entrées d'audit DOIVENT être conservées **2 ans**.
- **FR-021**: L'archivage d'entrées anciennes NE DOIT **pas** rompre la vérification de la chaîne
  restante.

#### Garde-fous (J2)

- **FR-022**: Le système DOIT **refuser** la suppression ou la rétrogradation du **dernier
  administrateur**.

#### Surface (J3)

- **FR-023**: Le système DOIT fournir une interface d'**édition des rôles**, dont chaque modification
  est auditée et prend effet sans redémarrage.
- **FR-024**: Le système DOIT fournir une **consultation du journal d'audit**, filtrable par auteur,
  type d'action et période.
- **FR-025**: Une même vue ouverte par des rôles différents DOIT présenter ce que chaque rôle
  autorise, cet écart étant **cosmétique** — la décision restant serveur.

#### Preuves (J4)

- **FR-026**: La couverture intégrale de la matrice, le refus serveur en cas de contournement de
  l'interface, et la vérifiabilité de la chaîne d'audit DOIVENT être prouvés par des tests dédiés.

### Hors périmètre *(Art. 20 — YAGNI)*

- L'**authentification** elle-même — connexion, sessions, fournisseur d'identité → **S12**. S13
  applique des droits à une identité **déjà établie**.
- L'**authentification par clé** des clients programmatiques et les quotas → **S04**.
- L'**émission** des entrées d'audit par les autres composants (évictions, téléchargements,
  quarantaines, actions d'alerte) → specs concernées (**S06**, **S10**, **S15**, **S19**). S13
  fournit le **mécanisme** et en garantit l'infalsifiabilité.
- La **coquille d'interface** et le client généré → **S11**.
- Les **budgets** et leur application → **S04**, **S08**.
- La **génération de tests** comme outillage → **S03**. S13 fournit la **source** dont ils sont
  générés.

### Key Entities

- **Rôle** : niveau d'habilitation du modèle de gouvernance (administrateur, opérateur, développeur,
  observateur), surchargeable par organisation.
- **Permission** : couple ressource × action, associé aux rôles qui le détiennent. Décrit **une seule
  fois** dans la matrice versionnée.
- **Approbation** : demande d'exécution d'une action coûteuse par un utilisateur non habilité à
  l'exécuter directement. États : demandée → approuvée · refusée · expirée. *Terme normatif —
  « validation » et « review » sont des synonymes interdits (Art. 12).*
- **Entrée d'audit** : trace immuable d'une action sensible, nommée entité.verbe, liée à la
  précédente, conservée 2 ans. Rattachée à l'arbre de l'observation de la taxonomie.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Les tests de permissions générés couvrent **100 %** des
  couples (rôle, ressource, action) de la matrice, et **zéro** test de permission n'est écrit à la
  main.
- **SC-002** *(critère A2)*: Un appel direct au serveur contournant l'interface est refusé avec le
  code canonique de permission refusée dans **100 %** des cas non autorisés.
- **SC-003** *(critère A3)*: L'altération d'une entrée du journal d'audit — même la plus ancienne —
  rend la vérification **invalide** et **désigne le point de rupture**, dans **100 %** des cas
  testés.
- **SC-004**: **Zéro** route du serveur sans déclaration de permission — vérifié mécaniquement, et
  bloquant en cas de manquement.
- **SC-005**: Une modification de la matrice se propage aux tests générés et aux contrôles des routes
  **sans intervention manuelle**.
- **SC-006**: **100 %** des transitions d'approbation et des actions sensibles sont retrouvables dans
  le journal d'audit.
- **SC-007**: Une tentative de modification ou de suppression d'une entrée d'audit échoue dans
  **100 %** des cas.
- **SC-008**: Le système conserve **toujours au moins un** administrateur : toute tentative de
  supprimer ou rétrograder le dernier est refusée.
- **SC-009**: Une action sensible dont l'entrée d'audit ne peut être écrite est **refusée** — jamais
  exécutée sans trace.
- **SC-010**: Une demande d'approbation sans décision **expire**, et son expiration est auditée.
- **SC-011**: Une demande ne peut **jamais** être approuvée par son auteur.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9r) |
| --- | --- | --- |
| A1 — matrice générée, 100 % des cas couverts | SC-001, SC-005 | T11 `[TEST]` matrice 100 % · T3 génération — **revue humaine** |
| A2 — refus serveur même si l'interface est contournée | SC-002, SC-004 | T10 `[TEST]` contournement · T9 `[INT]` routes déclarées |
| A3 — chaîne d'audit vérifiable | SC-003, SC-007 | T11 `[TEST]` chaîne · T4 audit chaîné + vérification |
| Approbations tracées | SC-006, SC-010, SC-011 | T5 flux d'approbation |
| Garde-fou du dernier administrateur | SC-008 | T8 garde-fous |
| Refus sans trace possible | SC-009 | T4 audit |

**Revue humaine obligatoire** (Art. 8, risque de la phase 4) : la **matrice de permissions** et son
application (T1–T3) sont relues ligne à ligne par un humain.

## Assumptions

- **Dépendance à S04** : la hiérarchie organisation → team → utilisateur → clé existe. S13 y ajoute
  les **droits** ; il ne redéfinit pas la hiérarchie.
- **La matrice du document fait foi** : la table de permissions par rôle publiée dans le document est
  la référence transcrite. Toute divergence entre le code et cette table est un défaut du code, pas
  une évolution — la modifier relève de l'amendement du document (Art. 7).
- **Répartition sur l'audit** : S13 fournit le **mécanisme** d'audit et garantit son
  infalsifiabilité ; les autres specs **émettent** leurs entrées. C'est ce qui évite deux journaux
  (Art. 19).
- **Approbation exigée pour les téléchargements des membres** : le document identifie ce cas
  précis ; le mécanisme est général et réutilisable pour d'autres actions coûteuses, sans qu'aucune
  autre ne soit ajoutée par anticipation (Art. 20).
- **Séparation demandeur / approbateur** : le document ne le précise pas. La spec l'impose (FR-013),
  sans quoi le flux d'approbation ne protège de rien.
- **Conservation de 2 ans** : valeur fixée par le document (5c). L'archivage au-delà ne doit pas
  rompre la vérification de la chaîne restante (FR-021) — contrainte non traitée par le document mais
  indispensable pour que l'Art. 4 tienne dans la durée.
- **Le masquage d'interface n'est pas une protection** : cohérent avec S11 (FR-005 de cette spec), la
  décision est toujours serveur.
- **Profondeur du jalon M2** : la spec est **complète à M2**, en même temps que S11 qui accueille ses
  vues.
