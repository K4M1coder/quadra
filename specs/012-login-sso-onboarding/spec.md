# Feature Specification: S12 — Connexion (SSO ou locale) + onboarding de première installation

**Feature Branch**: `012-login-sso-onboarding`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9q du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S12 du plan de specs 9c : « Login / SSO + onboarding première installation », références 8a · 8b · W9, dépend de S04, effort ≈ 6 j-agent, phase 3 (produit modèles), jalon produit M2 (V1 équipe). **Revue humaine obligatoire** sur le flux de session.

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J2 de la fiche 9q. Cette spec est **la porte d'entrée
humaine** du produit : jusqu'ici, seuls les clients programmatiques (par clé, S04) accédaient au
service. Elle porte aussi l'assistant qui mène une machine vierge jusqu'au premier modèle servi.

### User Story 1 - Connexion : je m'authentifie par le fournisseur d'identité ou en local (Priority: P1)

Un membre de l'équipe se connecte au produit, soit par le fournisseur d'identité de l'entreprise,
soit — si aucun n'est configuré — par un identifiant local protégé par un second facteur optionnel.
Sa session dure une journée de travail.

**Why this priority**: c'est la profondeur J1. Sans authentification humaine, aucune vue
d'administration n'est accessible et S13 (permissions) n'a pas de sujet à qui les appliquer.

**Independent Test**: configurer un fournisseur d'identité d'essai, effectuer une connexion complète
de bout en bout, et vérifier qu'une session valide en résulte ; puis répéter en mode local avec
second facteur.

**Acceptance Scenarios**:

1. **Given** un fournisseur d'identité configuré, **When** l'utilisateur se connecte, **Then** le
   parcours aboutit **de bout en bout** et une session valide est établie.
2. **Given** une connexion réussie, **When** l'identité est enregistrée, **Then** l'utilisateur est
   rattaché à son **rôle** parmi ceux du modèle de gouvernance du projet.
3. **Given** aucun fournisseur d'identité configuré, **When** l'utilisateur se connecte, **Then** un
   mode **local** lui est proposé, avec un second facteur **optionnel**.
4. **Given** un identifiant local, **When** il est stocké, **Then** seule une **empreinte
   irréversible** est conservée — jamais la valeur en clair (Art. 5).
5. **Given** une session établie, **When** elle atteint **12 heures**, **Then** elle expire et
   l'utilisateur doit se reconnecter.
6. **Given** une session, **When** elle est transportée, **Then** elle l'est de façon **inaccessible
   au code exécuté dans le navigateur** et **non transmissible depuis un site tiers**.
7. **Given** une tentative de connexion échouée, **When** elle est refusée, **Then** le message
   n'indique **pas** si l'identifiant existe.

---

### User Story 2 - Onboarding : de la machine vierge au premier modèle servi (Priority: P2)

L'administrateur qui vient d'installer la plateforme est guidé par un assistant : le matériel est
détecté pour lui, il choisit l'emplacement de stockage, crée le compte administrateur ou raccorde le
fournisseur d'identité, puis choisit un premier modèle — qui est servi à l'issue du parcours.

**Why this priority**: c'est la profondeur J2 et le critère de sortie du jalon M2 (« wizard vierge →
modèle servi »). C'est la tranche qui rend le produit installable par quelqu'un d'autre que son
auteur (Art. 9).

**Independent Test**: partir d'une installation vierge, suivre l'assistant sans connaissance
préalable, et obtenir un modèle qui répond — puis vérifier qu'à aucun moment l'assistant n'a activé
le débordement mémoire.

**Acceptance Scenarios**:

1. **Given** une installation vierge, **When** l'administrateur ouvre le produit, **Then**
   l'assistant de première installation se présente.
2. **Given** l'assistant, **When** il présente le matériel, **Then** les cartes et leur topologie
   sont **détectées automatiquement**, non saisies à la main.
3. **Given** l'assistant, **When** l'administrateur choisit l'emplacement de stockage des modèles,
   **Then** l'espace disponible lui est indiqué avant validation.
4. **Given** l'étape de débordement mémoire vers la mémoire vive ou le stockage, **When** elle est
   présentée, **Then** l'option est **désactivée par défaut** et ne s'active que par choix explicite
   (Art. 3 — le silence vaut refus).
5. **Given** l'assistant, **When** l'administrateur configure l'accès, **Then** il crée un compte
   administrateur local **ou** raccorde le fournisseur d'identité.
6. **Given** l'assistant, **When** l'administrateur choisit un premier modèle, **Then** le choix
   s'appuie sur le **catalogue filtré par le matériel détecté**.
7. **Given** l'assistant achevé, **When** l'administrateur émet une première requête, **Then** le
   modèle choisi **répond** — le parcours va de la machine vierge au modèle servi.
8. **Given** un administrateur déjà créé, **When** quelqu'un tente d'atteindre l'assistant de
   première installation, **Then** l'accès lui est **refusé** — l'assistant n'est accessible que tant
   qu'aucun administrateur n'existe.

---

### Edge Cases

- **Le fournisseur d'identité devient injoignable** : le mode local reste disponible pour les
  comptes qui en disposent, afin de ne pas verrouiller l'administration hors de la plateforme.
- **Le fournisseur d'identité renvoie une identité sans correspondance locale** : la règle
  d'attribution du rôle initial est explicite — jamais un rôle privilégié par défaut.
- **L'assistant est interrompu en cours de route** (fermeture, redémarrage) : il reprend à l'étape
  atteinte ; les étapes déjà validées ne sont pas rejouées.
- **Deux personnes ouvrent l'assistant simultanément sur une installation vierge** : un seul compte
  administrateur est créé ; la seconde tentative est refusée.
- **Aucun modèle ne tient sur le matériel détecté** : l'assistant le dit explicitement et permet de
  terminer sans modèle, plutôt que de bloquer l'installation.
- **La session expire pendant une action longue** : l'utilisateur est informé et l'action n'est pas
  silencieusement perdue.
- **Le second facteur est perdu** : une procédure de récupération existe côté administrateur — sans
  quoi la perte du second facteur verrouille définitivement un compte.

## Requirements *(mandatory)*

### Functional Requirements

#### Authentification (J1 — chemin à revue humaine)

- **FR-001**: Le système DOIT permettre la connexion au travers d'un **fournisseur d'identité**
  externe, de bout en bout.
- **FR-002**: Le système DOIT offrir un mode d'authentification **local** lorsqu'aucun fournisseur
  d'identité n'est configuré, avec un **second facteur optionnel**.
- **FR-003**: Les identifiants locaux NE DOIVENT être stockés que sous forme d'**empreinte
  irréversible** (Art. 5).
- **FR-004**: Une session DOIT expirer au bout de **12 heures**.
- **FR-005**: Une session DOIT être transportée de façon **inaccessible au code exécuté dans le
  navigateur** et **non transmissible depuis un site tiers**.
- **FR-006**: Un échec de connexion NE DOIT **pas** révéler l'existence d'un identifiant.
- **FR-007**: Une identité connectée DOIT être rattachée à un **rôle** du modèle de gouvernance du
  projet, selon une règle d'attribution explicite — **jamais** un rôle privilégié par défaut.
- **FR-008**: Le mode local DOIT rester utilisable lorsque le fournisseur d'identité est injoignable,
  afin de ne pas verrouiller l'administration.
- **FR-009**: Une procédure de **récupération** du second facteur DOIT exister, à la main d'un
  administrateur.

#### Assistant de première installation (J2)

- **FR-010**: Le système DOIT présenter un **assistant de première installation** sur une
  installation vierge.
- **FR-011**: L'assistant DOIT **détecter automatiquement** le matériel — cartes et topologie — sans
  saisie manuelle.
- **FR-012**: L'assistant DOIT permettre de choisir l'**emplacement de stockage** des modèles, en
  indiquant l'espace disponible avant validation.
- **FR-013**: L'option de **débordement mémoire** vers la mémoire vive ou le stockage DOIT être
  **désactivée par défaut** et ne s'activer que par choix explicite (Art. 3).
- **FR-014**: L'assistant DOIT permettre de créer un **compte administrateur** local ou de raccorder
  le fournisseur d'identité.
- **FR-015**: L'assistant DOIT permettre de choisir un **premier modèle** à partir du catalogue
  **filtré par le matériel détecté**.
- **FR-016**: À l'issue de l'assistant, le modèle choisi DOIT être **servi** et répondre.
- **FR-017**: L'assistant NE DOIT être accessible **que tant qu'aucun administrateur n'existe** ;
  au-delà, l'accès est refusé.
- **FR-018**: Un assistant interrompu DOIT **reprendre à l'étape atteinte**, sans rejouer les étapes
  validées.
- **FR-019**: Deux ouvertures simultanées de l'assistant NE DOIVENT créer **qu'un seul** compte
  administrateur.
- **FR-020**: Si aucun modèle ne tient sur le matériel détecté, l'assistant DOIT le **dire
  explicitement** et permettre de terminer sans modèle.

#### Réutilisation (transverse, Art. 19)

- **FR-021**: L'assistant DOIT **réutiliser** la détection matérielle et le catalogue existants — il
  NE DOIT pas en produire une seconde implémentation.

#### Confidentialité (transverse, Art. 1)

- **FR-022**: Le recours à un fournisseur d'identité NE DOIT faire sortir **aucun** prompt, aucune
  réponse et aucune donnée d'usage de l'infrastructure : seule l'authentification transite.

#### Preuves (J3)

- **FR-023**: La connexion par fournisseur d'identité de bout en bout, le parcours complet de
  l'assistant, et la désactivation par défaut du débordement mémoire DOIVENT être prouvés par des
  tests dédiés.

### Hors périmètre *(Art. 20 — YAGNI)*

- L'**authentification par clé** des clients programmatiques → **S04**. S12 traite l'authentification
  **humaine**.
- La **définition des permissions** par rôle, l'éditeur de rôles et le flux d'approbation → **S13**.
  S12 attribue un rôle ; S13 dit ce qu'il permet.
- La **gestion des utilisateurs et des invitations** au quotidien (au-delà du premier
  administrateur) → **S13**.
- La **coquille d'interface** et le client généré → **S11**.
- La **détection du matériel** elle-même → **S06** ; le **catalogue et le verdict de tenue** →
  **S09**. S12 les **réutilise**.
- Le **débordement mémoire** lui-même (mécanisme, routage, opt-in par job) → **S18**. S12 se borne à
  garantir qu'il est **désactivé par défaut** à l'installation.
- Les **réglages** complets du produit → **S21**.

### Key Entities

- **Session** : preuve d'authentification d'un utilisateur, d'une durée de 12 heures, transportée de
  façon inaccessible au navigateur et non transmissible depuis un site tiers.
- **Identité** : utilisateur reconnu, issu du fournisseur d'identité ou local. Attributs : rôle,
  référence externe d'authentification.
- **Rôle** : niveau d'habilitation du modèle de gouvernance du projet (administrateur, opérateur,
  développeur, observateur). Rattaché à l'arbre de gouvernance de la taxonomie.
- **Étape d'assistant** : phase du parcours de première installation, validable et reprenable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Une connexion par fournisseur d'identité aboutit **de bout
  en bout** contre un fournisseur d'essai, et établit une session valide.
- **SC-002** *(critère A2)*: Un opérateur partant d'une **installation vierge** obtient un **modèle
  qui répond** en suivant uniquement l'assistant, **sans connaissance préalable** du produit.
- **SC-003** *(critère A3)*: Le débordement mémoire est **désactivé** à l'issue de l'assistant dans
  **100 %** des parcours où il n'a pas été explicitement activé.
- **SC-004**: Une session expire **exactement à 12 heures** ; au-delà, l'accès est refusé.
- **SC-005**: Aucun identifiant local n'est stocké en clair : **zéro occurrence** lors d'une
  recherche automatisée en base et dans les journaux.
- **SC-006**: Un échec de connexion ne permet **pas** de distinguer un identifiant inexistant d'un
  identifiant valide mal authentifié.
- **SC-007**: Une fois un administrateur créé, **100 %** des tentatives d'accès à l'assistant de
  première installation sont refusées.
- **SC-008**: Un assistant interrompu reprend à l'étape atteinte dans **100 %** des cas.
- **SC-009**: Deux ouvertures simultanées de l'assistant produisent **exactement un** compte
  administrateur.
- **SC-010**: L'assistant ne comporte **aucune** seconde implémentation de la détection matérielle ni
  du catalogue — vérifié par inspection des dépendances.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9q) |
| --- | --- | --- |
| A1 — connexion par fournisseur d'identité de bout en bout | SC-001, SC-004, SC-006 | T9 `[TEST]` connexion — **revue humaine** du flux de session |
| A2 — machine vierge → premier modèle servi | SC-002, SC-008, SC-009 | T8 `[TEST]` parcours complet de bout en bout |
| A3 — débordement mémoire désactivé par défaut | SC-003 | T9 `[TEST]` débordement désactivé |
| Garde de l'assistant | SC-007 | T4 garde tant qu'aucun administrateur n'existe |
| Aucun identifiant en clair | SC-005 | T3 mode local + second facteur |
| Réutilisation, pas de duplication | SC-010 | T7 `[INT]` réutilise la détection (S06) et le catalogue (S09) |

**Revue humaine obligatoire** (Art. 8) : le **flux de session** (T1–T2) est relu ligne à ligne par un
humain — il relève du chemin « authentification », non délégable.

## Assumptions

- **Dépendance à S04** : le modèle de données des utilisateurs, teams et organisations existe déjà.
  S12 ajoute l'**authentification humaine** au-dessus, sans redéfinir la hiérarchie d'accès.
- **Réutilisation stricte (Art. 19)** : l'assistant **consomme** la détection matérielle de S06 et le
  catalogue de S09. Il n'en produit aucune variante — c'est explicitement vérifié (SC-010).
- **Le fournisseur d'identité peut être interne ou externe** : l'Art. 1 interdit la sortie des
  prompts et des données d'usage, pas l'usage d'un annuaire d'entreprise. Seule l'authentification
  transite (FR-022).
- **Durée de session de 12 heures** : valeur fixée par le document ; elle correspond à une journée de
  travail et évite les reconnexions en cours de journée.
- **Second facteur optionnel** : le document le présente comme optionnel en mode local. Il n'est donc
  pas imposé, mais une **procédure de récupération** est exigée (FR-009) — sans elle, sa perte
  verrouille définitivement un compte, ce que le document ne traite pas.
- **Rôle initial jamais privilégié par défaut** : le document ne précise pas la règle d'attribution
  pour une identité externe inconnue. La spec impose une règle **explicite** et interdit le rôle
  privilégié par défaut (FR-007), conformément à l'Art. 5.
- **Profondeur du jalon M2** : la spec est **complète à M2**. Ses vues se posent dans la coquille
  d'interface de S11, disponible au même jalon.
