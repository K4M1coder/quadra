# Feature Specification: S11 — Coquille d'interface d'administration + Overview, Queue, Models + temps réel

**Feature Branch**: `011-admin-ui-shell-overview`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9p du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S11 du plan de specs 9c : « Admin UI shell + overview + queue + models + /ws live », références 6a · 6c · 7e · 4d, dépend de S05, effort ≈ 7.5 j-agent, phase 3 (produit modèles). **Profondeur de jalon : J1 à M1 (coquille + temps réel), J2–J3 complétés à M2** (Art. 20).

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J2 de la fiche 9p. Cette spec pose **la coquille
unique** dans laquelle toutes les vues des autres specs viendront s'inscrire : une seule application,
une seule navigation, un seul canal temps réel.

### User Story 1 - Fondations : une coquille prête, un client dérivé du contrat, un canal temps réel (Priority: P1)

Un développeur dispose d'une application d'administration qui démarre, présente la navigation
canonique du produit, parle au serveur au moyen d'un client **entièrement dérivé du contrat
d'interface**, et reste connectée au canal temps réel malgré les coupures.

**Why this priority**: c'est la profondeur J1, **due dès le jalon M1**. Sans coquille ni canal temps
réel, aucune des vues de S07, S08, S09, S10, S13–S18 n'a d'endroit où exister. Le client dérivé du
contrat est l'application directe de l'Art. 19 : une seule source de vérité, le reste est généré.

**Independent Test**: démarrer l'application, constater que la navigation présente toutes les
entrées du produit, que le client d'accès au serveur n'a **aucune** portion écrite à la main, et que
le canal temps réel se rétablit seul après une coupure — sans qu'aucune vue métier existe encore.

**Acceptance Scenarios**:

1. **Given** le contrat d'interface du serveur, **When** le client d'accès est produit, **Then** il
   est **entièrement généré** à partir de ce contrat — **aucune** portion n'est écrite à la main
   (Art. 19).
2. **Given** une modification du contrat d'interface, **When** le client est régénéré, **Then**
   l'écart se manifeste à la compilation plutôt qu'à l'exécution.
3. **Given** l'application démarrée, **When** l'utilisateur observe la navigation, **Then** elle
   présente les entrées canoniques du produit, nommées avec **les termes du glossaire** — aucun
   synonyme d'affichage (Art. 12).
4. **Given** un utilisateur dont le rôle ne donne pas accès à une entrée, **When** la navigation
   s'affiche, **Then** cette entrée lui est **masquée** — étant entendu que ce masquage est
   **cosmétique** : la permission reste appliquée par le serveur (Art. 5).
5. **Given** le canal temps réel établi, **When** la connexion est interrompue, **Then** elle est
   **rétablie automatiquement**, avec un espacement croissant entre les tentatives, sans action de
   l'utilisateur.
6. **Given** une vue sans données, en erreur, ou en cours de chargement, **When** elle s'affiche,
   **Then** elle présente un état **explicite** pour chacune de ces trois situations — jamais un
   écran vide sans explication.
7. **Given** l'application, **When** on inspecte sa gestion d'état, **Then** elle ne comporte
   **aucun** état global hors du cache des requêtes et du magasin alimenté par le canal temps réel.

---

### User Story 2 - Vues : je pilote le serveur depuis trois écrans (Priority: P2)

L'opérateur ouvre l'application et pilote la plateforme : il voit la santé générale et les alertes
actives, l'état des files d'ordonnancement avec les requêtes vivantes, et les modèles résidents avec
leur placement sur les cartes.

**Why this priority**: c'est la profondeur J2, due à **M2**. Elle transforme la coquille en outil :
c'est le moment où l'administration cesse de passer par la base de données.

**Independent Test**: avec un serveur en charge, ouvrir chacune des trois vues et vérifier qu'elle
reflète l'état réel, se met à jour spontanément, et correspond à la maquette de référence.

**Acceptance Scenarios**:

1. **Given** la plateforme en fonctionnement, **When** l'opérateur ouvre la vue d'ensemble, **Then**
   il voit la **santé générale**, l'état des **cartes GPU**, les **alertes actives** et les
   indicateurs de niveau de service.
2. **Given** des requêtes en attente et en cours, **When** l'opérateur ouvre la vue des files,
   **Then** il voit les **trois lanes**, la profondeur de chacune, et les **requêtes vivantes** avec
   leur position.
3. **Given** des modèles résidents, **When** l'opérateur ouvre la vue des modèles, **Then** il voit
   leur **placement sur les cartes**, leur état et leur délai d'inactivité.
4. **Given** une de ces vues ouverte, **When** l'état du serveur change, **Then** l'affichage se met
   à jour **spontanément**, sans que l'utilisateur rafraîchisse et **sans interrogation répétée** du
   serveur.
5. **Given** une entité dans un état donné, **When** elle est affichée, **Then** son état apparaît
   comme un **badge unique**, dont la couleur suit la famille normative (nominal, transitoire,
   dégradé, terminal).
6. **Given** les maquettes de référence du document, **When** on compare les trois vues livrées,
   **Then** elles **correspondent** à ces maquettes.

---

### Edge Cases

- **Le canal temps réel ne peut pas être établi du tout** : l'application reste utilisable en lecture
  et signale explicitement que les données ne sont pas en direct — elle ne bascule pas
  silencieusement sur de l'interrogation répétée, ce qui violerait le critère A2.
- **Le canal se rétablit après une longue coupure** : l'état affiché est **resynchronisé**
  intégralement plutôt que reconstitué à partir des seuls événements manqués.
- **Le serveur envoie un événement d'un type inconnu du client** (client plus ancien que le serveur) :
  il est ignoré sans faire échouer l'affichage.
- **Un utilisateur atteint directement l'adresse d'une vue qui lui est masquée** : le serveur refuse
  la donnée ; l'interface affiche un refus explicite — le masquage de navigation n'est pas la
  protection (Art. 5).
- **Une vue reçoit un état qui n'existe pas dans la machine à états normative** : c'est un défaut à
  corriger côté serveur ; l'interface l'affiche comme état inconnu plutôt que de l'interpréter.
- **Le débit d'événements temps réel est élevé** (statistiques matérielles à haute fréquence) :
  l'affichage reste fluide, les mises à jour étant regroupées si nécessaire — sans jamais retomber
  sur de l'interrogation.

## Requirements *(mandatory)*

### Functional Requirements

#### Coquille, client et temps réel (J1 — M1)

- **FR-001**: Le client d'accès au serveur DOIT être **entièrement généré** à partir du contrat
  d'interface. Aucune portion NE DOIT être écrite à la main (Art. 19).
- **FR-002**: Un écart entre le client et le contrat DOIT se manifester **à la compilation**.
- **FR-003**: L'application DOIT présenter la **navigation canonique** du produit, couvrant
  l'ensemble de ses modules.
- **FR-004**: Les libellés de l'interface DOIVENT employer **les termes du glossaire normatif**, sans
  synonyme d'affichage (Art. 12).
- **FR-005**: La navigation DOIT **masquer** les entrées inaccessibles au rôle de l'utilisateur, ce
  masquage étant **cosmétique** — la permission reste appliquée par le serveur (Art. 5).
- **FR-006**: L'application DOIT maintenir une connexion au **canal temps réel**, la rétablir
  automatiquement après coupure, avec un espacement croissant entre les tentatives.
- **FR-007**: L'application DOIT s'abonner aux flux temps réel **par entité**, conformément à la
  convention de nommage du projet.
- **FR-008**: Après rétablissement du canal, l'application DOIT **resynchroniser** intégralement
  l'état affiché.
- **FR-009**: Un événement d'un type inconnu DOIT être **ignoré** sans faire échouer l'affichage.
- **FR-010**: Chaque vue DOIT présenter un état explicite pour les situations **sans données**, **en
  erreur** et **en cours de chargement**.
- **FR-011**: L'application NE DOIT comporter **aucun** état global hors du cache des requêtes et du
  magasin alimenté par le canal temps réel.
- **FR-012**: Les styles DOIVENT provenir des jetons du système de conception du projet, sans valeur
  écrite en dur.

#### Absence d'interrogation répétée (transverse)

- **FR-013**: **Toutes** les données vivantes DOIVENT parvenir par le canal temps réel. L'application
  NE DOIT réaliser **aucune** interrogation répétée du serveur.
- **FR-014**: Si le canal temps réel est indisponible, l'application DOIT le **signaler
  explicitement** et NE DOIT **pas** basculer sur de l'interrogation répétée.

#### Vues d'exploitation (J2 — M2)

- **FR-015**: La vue d'ensemble DOIT présenter la santé générale, l'état des cartes GPU, les alertes
  actives et les indicateurs de niveau de service.
- **FR-016**: La vue des files DOIT présenter les **trois lanes**, la profondeur de chacune et les
  requêtes vivantes avec leur position.
- **FR-017**: La vue des modèles DOIT présenter les modèles résidents, leur **placement sur les
  cartes**, leur état et leur délai d'inactivité.
- **FR-018**: Chaque état d'entité DOIT être présenté comme un **badge unique**, coloré selon sa
  famille normative (nominal, transitoire, dégradé, terminal).
- **FR-019**: Les trois vues DOIVENT **correspondre aux maquettes de référence** du document.
- **FR-020**: Les adresses des vues DOIVENT être **calquées sur celles du serveur**, selon la
  convention de nommage du projet.

#### Preuves (J3 — M2)

- **FR-021**: Chaque vue DOIT disposer de son propre test de composant.
- **FR-022**: La génération intégrale du client, l'absence d'interrogation répétée et la conformité
  des vues aux maquettes DOIVENT être prouvées par des tests dédiés, dont un parcours de bout en
  bout.

### Hors périmètre *(Art. 20 — YAGNI)*

- Les **autres vues** du produit — catalogue, téléchargements, moteurs, journaux, consommation,
  organisations, clés, observabilité, chat, playground, jobs, réglages — appartiennent aux specs qui
  les portent (**S07** à **S21**). S11 fournit **la coquille** qui les accueille, plus **trois** vues.
- La **définition des permissions** et l'éditeur de rôles → **S13**. S11 **consomme** le rôle pour
  masquer ; il ne le définit pas.
- La **connexion de l'utilisateur** et les sessions → **S12**.
- L'**émission** des événements temps réel → specs productrices (**S05**, **S06**, **S10**, **S15**,
  **S18**, **S19**). S11 les **consomme**.
- Le **contrat d'interface** lui-même → **S04**, dont S11 dérive son client.
- L'**enveloppe applicative de bureau**, mentionnée comme optionnelle par le document : **hors
  périmètre** tant qu'aucun jalon ne l'exige (Art. 20).

### Key Entities

- **Vue** : écran de l'application correspondant à un module du produit. Nommée selon la convention
  du projet et adressée par une adresse calquée sur celle du serveur.
- **Flux temps réel** : canal d'abonnement par entité, portant les changements d'état poussés par le
  serveur.
- **Badge d'état** : représentation visuelle unique d'un état issu d'une machine à états normative,
  coloré par famille (nominal, transitoire, dégradé, terminal).
- **Client d'accès** : couche d'appel au serveur, **entièrement dérivée** du contrat d'interface.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: **100 %** du client d'accès au serveur est généré à partir
  du contrat : une inspection automatisée ne trouve **aucune** portion écrite à la main.
- **SC-002** *(critère A2)*: **Zéro** interrogation répétée : sur une session d'observation, toutes
  les mises à jour de données vivantes proviennent du canal temps réel, et aucun appel périodique
  n'est émis.
- **SC-003** *(critère A3)*: Les trois vues **correspondent aux maquettes de référence** — vérifié
  élément par élément sur les informations exigées par chacune.
- **SC-004**: Après une coupure du canal temps réel, la connexion est rétablie **sans action de
  l'utilisateur**, et l'état affiché est resynchronisé intégralement.
- **SC-005**: Une modification du contrat d'interface incompatible avec l'application est détectée
  **à la compilation**, jamais découverte en production.
- **SC-006**: **100 %** des libellés d'interface correspondent aux termes du glossaire normatif —
  vérifié par contrôle automatisé contre le glossaire.
- **SC-007**: Un utilisateur atteignant directement une vue masquée obtient un **refus du serveur** —
  le masquage de navigation n'est jamais la seule protection.
- **SC-008**: Chaque vue présente un état explicite dans les trois situations sans données, en erreur
  et en chargement — **zéro** écran vide sans explication.
- **SC-009**: Chaque vue dispose d'un test de composant : **couverture des trois vues à 100 %** en
  présence de test.
- **SC-010**: Sous un débit soutenu d'événements temps réel, l'affichage reste utilisable et ne
  bascule **jamais** sur de l'interrogation.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9p) |
| --- | --- | --- |
| A1 — client 100 % généré | SC-001, SC-005 | T11 `[TEST]` conformité · T2 génération du client |
| A2 — tout le direct par le canal temps réel, zéro interrogation | SC-002, SC-004, SC-010 | T11 `[TEST]` zéro interrogation · T3 canal + reconnexion |
| A3 — les trois vues correspondent aux maquettes | SC-003, SC-008, SC-009 | T10 `[TEST]` test par vue · T11 `[TEST]` conformité |
| Masquage cosmétique, permission serveur | SC-007 | T4 navigation + masquage · vérifié avec S13 |
| Langage ubiquitaire dans l'interface | SC-006 | T4 navigation · contrôle contre le glossaire |
| Abonnements réels | SC-002 | T9 `[INT]` flux réels (S05 / S06) |

## Assumptions

- **Profondeur de jalon — coupure explicite** : **J1 est dû à M1** (coquille, client généré,
  navigation, canal temps réel), conformément au plan de specs (« S11 ≤ J1 → M2 »). Les **trois
  vues** (J2) et les preuves (J3) sont dues à **M2**. Rien de J2 ne DOIT être anticipé à M1
  (Art. 20).
- **Dépendance à S05 et S06** : les flux temps réel des files et des modèles sont **produits** par
  l'ordonnanceur et le superviseur. S11 les consomme ; il ne les invente pas.
- **Le contrat d'interface est figé par S04** : il est la source unique dont le client est généré. Un
  besoin d'interface non couvert par le contrat se règle en amendant le contrat, jamais en écrivant
  du client à la main (Art. 19).
- **Le masquage n'est pas une sécurité** : l'interface reflète les droits pour éviter de proposer
  l'impossible ; la décision reste serveur (Art. 5). Cette distinction est vérifiée par SC-007, en
  coordination avec S13.
- **Les maquettes de référence font foi pour l'apparence** : le document fournit les prototypes des
  trois vues. « Correspondre » signifie porter les mêmes informations et la même structure, non une
  identité au pixel près — c'est ce que rend vérifiable SC-003.
- **Enveloppe de bureau écartée** : le document la mentionne comme optionnelle. Aucun jalon ne
  l'exige ; elle est donc hors périmètre jusqu'à décision contraire (Art. 20).
- **Système de conception** : les styles proviennent des jetons du système de conception fourni par
  le document. Aucune valeur d'apparence n'est écrite en dur dans les vues.
