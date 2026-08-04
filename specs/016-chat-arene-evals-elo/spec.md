# Feature Specification: S16 — Chat multi-utilisateur + arène + classement Elo

**Feature Branch**: `016-chat-arene-evals-elo`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9u du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S16 du plan de specs 9c : « Chat multi-user + arène + evals Elo », références 7h · 7k · W7, dépend de S04 et S11, effort ≈ 6 j-agent, phase 5 (usages avancés), jalon produit M3 (V1.1 confort). Phase parallélisable, aucun risque bloquant identifié.

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J2 de la fiche 9u. Cette spec apporte **la valeur
quotidienne pour l'équipe** : un chat interne, et surtout un moyen objectif de décider quel modèle
adopter, fondé sur des votes réels plutôt que sur des impressions.

### User Story 1 - Fondations : mes conversations sont persistées (Priority: P1)

Un membre de l'équipe converse avec un modèle depuis le produit et retrouve ses échanges d'un jour
sur l'autre.

**Why this priority**: c'est la profondeur J1. Sans persistance des conversations, ni l'arène ni le
retour d'expérience n'ont de support. C'est aussi la tranche la plus simple à livrer seule.

**Independent Test**: échanger quelques messages, recharger le produit, et retrouver la conversation
intacte.

**Acceptance Scenarios**:

1. **Given** un membre connecté, **When** il échange avec un modèle, **Then** la conversation et ses
   messages sont **persistés** et retrouvés après rechargement.
2. **Given** une conversation, **When** elle est enregistrée, **Then** elle reste **sur site** —
   aucun contenu ne quitte l'infrastructure (Art. 1).
3. **Given** un membre, **When** il consulte ses conversations, **Then** il ne voit **que les
   siennes**, la décision étant prise côté serveur.

---

### User Story 2 - Cœur : je compare deux modèles et mon vote compte (Priority: P2)

Un membre envoie le même prompt à deux modèles, voit les deux réponses **arriver en parallèle**,
choisit celle qu'il préfère — et son vote fait bouger un classement que toute l'équipe consulte pour
décider quel modèle adopter.

**Why this priority**: c'est la profondeur J2 et la valeur distinctive de la spec. Elle transforme
une opinion individuelle en une donnée collective exploitable, et alimente la décision d'adoption
d'un modèle.

**Independent Test**: lancer une comparaison, vérifier que les deux réponses se construisent
simultanément, voter, et constater que le classement évolue conformément au calcul de référence.

**Acceptance Scenarios**:

1. **Given** un prompt et deux modèles choisis, **When** la comparaison est lancée, **Then** les
   **deux réponses sont diffusées en parallèle** — non l'une après l'autre.
2. **Given** une comparaison, **When** les deux requêtes sont émises, **Then** elles emploient les
   **mêmes paramètres d'échantillonnage**, afin que la comparaison porte sur les modèles et non sur
   le hasard.
3. **Given** deux réponses affichées, **When** le membre vote, **Then** le **classement est mis à
   jour** selon la formule de référence du projet.
4. **Given** une série de votes, **When** le classement est recalculé, **Then** le résultat est
   **exact** — identique à un calcul de référence établi indépendamment.
5. **Given** le classement, **When** un membre le consulte, **Then** il voit le rang des modèles et
   une représentation permettant de situer chacun.
6. **Given** un retour négatif exprimé sur une réponse, **When** il est enregistré, **Then** il
   constitue une **entrée réutilisable** dans un jeu de données d'évaluation, exportable.
7. **Given** un membre, **When** il choisit les modèles à comparer, **Then** il ne peut sélectionner
   que ceux **auxquels sa team a droit** — la décision étant prise côté serveur (Art. 5).
8. **Given** un échange du chat ou de l'arène, **When** il est servi, **Then** il **emprunte le même
   chemin d'inférence que n'importe quel client**, et apparaît dans les journaux avec une marque
   distinctive indiquant son origine.

---

### Edge Cases

- **Un des deux modèles échoue pendant la comparaison** : la réponse disponible est conservée, la
  comparaison est marquée incomplète, et **aucun vote n'est comptabilisé** — sans quoi le classement
  refléterait une disponibilité, pas une qualité.
- **Le membre ne vote pas** : la comparaison reste sans vote et n'influence pas le classement.
- **Le membre vote plusieurs fois sur la même comparaison** : un seul vote est retenu.
- **Un modèle est retiré du catalogue après avoir été classé** : son historique de votes est
  conservé et son rang reste consultable, marqué comme non disponible.
- **Deux modèles n'ont jamais été comparés entre eux** : le classement reste valide — il ne suppose
  pas un affrontement direct de toutes les paires.
- **Le nombre de votes est très faible** : le classement l'indique, pour éviter qu'un rang fondé sur
  deux votes soit lu comme un verdict.
- **Une conversation devient très longue** : le chat reste utilisable ; la limite de contexte du
  modèle est signalée avant échec plutôt qu'après.

## Requirements *(mandatory)*

### Functional Requirements

#### Conversations (J1)

- **FR-001**: Le système DOIT **persister** les conversations et leurs messages, et les restituer
  après rechargement.
- **FR-002**: Les conversations DOIVENT rester **sur site** — aucun contenu ne quitte
  l'infrastructure (Art. 1).
- **FR-003**: Un membre NE DOIT voir que **ses propres** conversations, la décision étant prise côté
  serveur.
- **FR-004**: Le système DOIT signaler l'approche de la limite de contexte d'une conversation
  **avant** l'échec.

#### Chat (J2)

- **FR-005**: Le système DOIT diffuser les réponses du chat **au fil de leur production**.
- **FR-006**: Un membre NE DOIT pouvoir sélectionner que les modèles **auxquels sa team a droit**,
  la décision étant prise côté serveur (Art. 5).
- **FR-007**: Les échanges du chat DOIVENT emprunter **le même chemin d'inférence que n'importe quel
  client** — aucun chemin privilégié (Art. 19).
- **FR-008**: Les échanges du chat et de l'arène DOIVENT apparaître dans les journaux avec une
  **marque distinctive** indiquant leur origine.

#### Arène (J2)

- **FR-009**: Le système DOIT permettre d'envoyer **le même prompt à deux modèles** et de diffuser
  **les deux réponses en parallèle**.
- **FR-010**: Les deux requêtes d'une comparaison DOIVENT employer les **mêmes paramètres
  d'échantillonnage**.
- **FR-011**: Si l'un des deux modèles échoue, la comparaison DOIT être marquée **incomplète** et
  **aucun vote NE DOIT être comptabilisé**.
- **FR-012**: Un membre NE DOIT pouvoir enregistrer **qu'un seul vote** par comparaison.

#### Classement (J2)

- **FR-013**: Un vote DOIT mettre à jour le **classement** selon la formule de référence du projet.
- **FR-014**: Le calcul du classement DOIT être **exact** et vérifiable contre un calcul de référence
  établi indépendamment.
- **FR-015**: Le calcul du classement DOIT être une **fonction pure**, testable isolément.
- **FR-016**: Le classement DOIT indiquer le **nombre de votes** sur lequel repose chaque rang.
- **FR-017**: Le classement DOIT rester valide même si toutes les paires de modèles n'ont pas été
  comparées entre elles.
- **FR-018**: Un modèle retiré du catalogue DOIT conserver son historique de votes et rester
  consultable, marqué comme non disponible.

#### Retour d'expérience (J2)

- **FR-019**: Un retour négatif exprimé sur une réponse DOIT constituer une **entrée réutilisable**
  dans un jeu de données d'évaluation.
- **FR-020**: Le système DOIT permettre d'**exporter** l'historique des retours d'expérience.

#### Preuves (J3)

- **FR-021**: La diffusion parallèle des deux réponses, l'exactitude du classement et
  l'exploitabilité des retours négatifs DOIVENT être prouvés par des tests dédiés, dont un parcours
  complet de bout en bout du vote au classement.

### Hors périmètre *(Art. 20 — YAGNI)*

- Le **service d'inférence** lui-même, l'authentification et les quotas → **S04**. Le chat est un
  **client comme un autre**.
- L'**ordonnancement** et les lanes → **S05**. Les échanges du chat empruntent la lane interactive
  par leur clé, sans traitement de faveur particulier.
- La **coquille d'interface** → **S11**.
- La **trace par requête** et les journaux → **S14**. S16 y **apparaît** avec sa marque distinctive.
- Le **contrôle d'accès** définissant les modèles autorisés par team → **S13**, dont S16 consomme la
  décision.
- Le **playground** et la génération d'extraits de code → **S17** : usage distinct, spec distincte.
- L'**évaluation automatisée** par jeux de tests de référence : hors périmètre — le classement de
  cette spec repose **exclusivement sur des votes humains réels**.

### Key Entities

- **Conversation** : suite d'échanges persistée d'un membre avec un modèle. Racine de l'arbre de
  l'usage de la taxonomie.
- **Message** : élément d'une conversation, diffusé au fil de sa production, servi par le chemin
  d'inférence commun et marqué de son origine.
- **Comparaison d'arène** : envoi d'un même prompt à deux modèles avec les mêmes paramètres
  d'échantillonnage. Peut être **incomplète** si un modèle échoue.
- **Vote** : préférence exprimée par un membre sur une comparaison complète. Un seul par
  comparaison.
- **Classement** : rang des modèles dérivé des votes, assorti du nombre de votes le fondant.
- **Retour d'expérience** : appréciation exprimée sur une réponse, réutilisable comme entrée de jeu
  de données d'évaluation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: En comparaison, les **deux réponses se construisent
  simultanément** : le premier jeton de chacune arrive sans attendre la fin de l'autre.
- **SC-002** *(critère A2)*: Le classement calculé après une série de votes est **identique** à un
  calcul de référence établi indépendamment — **écart nul** sur l'intégralité du jeu de cas de
  référence.
- **SC-003** *(critère A3)*: Un retour négatif produit une entrée **exportable et réutilisable** dans
  un jeu de données d'évaluation, dans **100 %** des cas.
- **SC-004**: Une comparaison dont un modèle échoue ne produit **aucun** vote comptabilisé.
- **SC-005**: Un membre ne peut sélectionner **aucun** modèle hors des droits de sa team, y compris
  en contournant l'interface.
- **SC-006**: **100 %** des échanges du chat et de l'arène apparaissent dans les journaux avec leur
  marque d'origine.
- **SC-007**: Le chat n'emprunte **aucun** chemin d'inférence privilégié — vérifié par inspection.
- **SC-008**: Un second vote sur la même comparaison ne modifie **pas** le classement.
- **SC-009**: Une conversation est retrouvée **intacte** après rechargement dans **100 %** des cas.
- **SC-010**: Le classement affiche le **nombre de votes** fondant chaque rang.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9u) |
| --- | --- | --- |
| A1 — deux réponses diffusées en parallèle | SC-001, SC-004 | T8 `[TEST]` diffusions parallèles |
| A2 — classement exact | SC-002, SC-008, SC-010 | T9 `[TEST]` classement juste, par fichiers de référence |
| A3 — retour négatif exploitable en jeu de données | SC-003 | T9 `[TEST]` jeu de données |
| Chat = client comme un autre, marqué | SC-006, SC-007 | T7 `[INT]` via le chemin commun, avec marque |
| Droits de team respectés | SC-005 | T2 sélecteur de modèles + droits |
| Vote → classement de bout en bout | SC-002 | T10 parcours complet vote → classement |

## Assumptions

- **Dépendances** : S04 fournit le service d'inférence et les droits par clé ; S11 fournit la
  coquille d'interface et le canal temps réel. S16 n'ajoute aucune infrastructure.
- **Le chat est un client comme un autre (Art. 19)** : c'est la consigne explicite du document. Le
  chat ne dispose d'aucun chemin d'inférence privilégié ; il est authentifié, compté et ordonnancé
  comme n'importe quel appel, et se distingue seulement par une marque dans les journaux. C'est ce
  qui garantit que ses coûts sont comptabilisés (S08) et ses traces disponibles (S14).
- **Formule de classement fixée par le document** : le facteur de mise à jour est celui indiqué par
  le document. Il est traité comme un **paramètre du plan**, la spec exigeant l'**exactitude** du
  calcul (SC-002) plutôt qu'une valeur particulière — ce qui permet de l'ajuster sans réécrire la
  spec.
- **Seuls des votes humains réels alimentent le classement** : aucune évaluation automatisée n'est
  introduite. C'est un choix de périmètre du document, et il borne clairement la spec (Art. 20).
- **Une comparaison incomplète ne vote pas** : le document ne traite pas l'échec d'un des deux
  modèles. La spec l'impose (FR-011), sans quoi le classement mesurerait la disponibilité plutôt que
  la qualité — ce qui le rendrait trompeur pour la décision d'adoption qu'il sert.
- **Le nombre de votes est affiché** : ajout de la spec (FR-016). Un rang fondé sur deux votes lu
  comme un verdict conduirait à une mauvaise décision d'adoption ; l'afficher est le minimum
  d'honnêteté statistique.
- **Mêmes paramètres d'échantillonnage en arène** : exigence du document, indispensable pour que la
  comparaison porte sur les modèles et non sur la variabilité aléatoire.
- **Jalon M3** : la spec est **complète à M3**, dans une phase que le document décrit comme
  parallélisable entre agents et sans risque bloquant.
