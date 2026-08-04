# Feature Specification: S17 — Playground / console d'essai

**Feature Branch**: `017-playground-console-api`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9v du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S17 du plan de specs 9c : « Playground / console API », référence 7i, dépend de S11, effort ≈ 4 j-agent, phase 5 (usages avancés), jalon produit M3 (V1.1 confort).

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent le jalon interne J1 de la fiche 9v. Cette spec supprime la marche d'entrée
du produit : **essayer avant d'écrire du code**, puis repartir avec le code exact qui reproduit
l'essai.

### User Story 1 - Je teste un prompt et je repars avec le code exact (Priority: P1)

Un membre compose une requête depuis le produit — message système, message utilisateur, paramètres
d'échantillonnage — choisit une de ses clés, exécute, voit la réponse se construire, puis copie un
extrait de code qui **reproduit exactement** cet appel dans son propre environnement.

**Why this priority**: c'est la totalité de la valeur de la spec, et c'est aussi une brique du
parcours d'accueil d'un nouvel utilisateur (première clé, premier appel). Le point critique est
l'**exactitude** de l'extrait : un extrait qui ne fonctionne pas tel quel est pire que pas d'extrait
du tout, car il fait perdre du temps en débogage sur un faux problème.

**Independent Test**: composer une requête, l'exécuter dans le produit, copier l'extrait généré,
l'exécuter tel quel hors du produit, et constater qu'il fonctionne et produit le même type de
résultat.

**Acceptance Scenarios**:

1. **Given** la console d'essai, **When** le membre compose sa requête, **Then** il peut définir le
   message système, le ou les messages utilisateur, et **l'ensemble des paramètres
   d'échantillonnage** offerts par le contrat d'inférence.
2. **Given** une requête composée, **When** le membre l'exécute avec une de ses clés, **Then** la
   réponse est **diffusée au fil de sa production**.
3. **Given** une requête composée, **When** le membre demande l'extrait de code, **Then** il l'obtient
   dans plusieurs formes — appel en ligne de commande et clients des langages courants.
4. **Given** un extrait copié, **When** il est exécuté **tel quel** hors du produit, **Then** il
   **fonctionne** et reproduit l'appel réalisé dans la console.
5. **Given** l'extrait et l'appel réel, **When** on les compare, **Then** ils dérivent de **la même
   structure de requête** — il n'existe **pas** deux représentations à maintenir (Art. 19).
6. **Given** un appel exécuté depuis la console, **When** il se termine, **Then** son **coût**, sa
   **latence de premier jeton** et son **débit** sont affichés.
7. **Given** un appel exécuté depuis la console, **When** on le retrouve dans les journaux, **Then**
   il est **métré comme tout appel** et porte une **marque distinctive** indiquant son origine.
8. **Given** une clé choisie, **When** l'appel est exécuté, **Then** les droits appliqués sont ceux
   **de cette clé** — la décision étant prise côté serveur (Art. 5).

---

### Edge Cases

- **La clé choisie n'a pas accès au modèle sélectionné** : le refus est celui du serveur, présenté
  clairement — la console ne masque pas l'erreur et n'utilise aucun accès privilégié.
- **L'appel dépasse un quota ou un budget** : la console affiche le refus tel qu'un client réel le
  recevrait, ce qui fait précisément partie de ce qu'on vient tester.
- **Le membre copie l'extrait sans avoir exécuté** : l'extrait est tout de même correct — il dérive
  de la requête composée, pas d'une exécution.
- **La valeur secrète de la clé apparaîtrait dans l'extrait** : l'extrait référence la clé de manière
  à ne pas divulguer sa valeur en clair, et indique où l'utilisateur doit la fournir (Art. 5).
- **Un paramètre d'échantillonnage est laissé vide** : l'extrait ne l'inclut pas, plutôt que
  d'inventer une valeur par défaut divergente de celle du serveur.
- **Le contrat d'inférence évolue** : les extraits suivent, puisqu'ils dérivent de la même structure
  que l'appel réel.

## Requirements *(mandatory)*

### Functional Requirements

#### Composition et exécution (J1)

- **FR-001**: Le système DOIT permettre de composer une requête d'inférence : message système,
  messages utilisateur, et **l'ensemble des paramètres d'échantillonnage** offerts par le contrat
  d'inférence.
- **FR-002**: Le système DOIT permettre de choisir **la clé** avec laquelle l'appel est exécuté.
- **FR-003**: Le système DOIT **diffuser la réponse au fil de sa production**.
- **FR-004**: Les droits appliqués DOIVENT être ceux **de la clé choisie**, décidés côté serveur —
  la console NE DOIT disposer d'**aucun accès privilégié** (Art. 5).
- **FR-005**: Un refus du serveur — droit, quota, budget — DOIT être présenté **tel qu'un client réel
  le recevrait**.

#### Extraits de code (J1)

- **FR-006**: Le système DOIT générer un **extrait de code reproduisant l'appel**, sous plusieurs
  formes : appel en ligne de commande et clients des langages courants.
- **FR-007**: L'extrait copié DOIT **fonctionner tel quel**, sans adaptation, hors du produit.
- **FR-008**: L'extrait et l'appel réel DOIVENT dériver de **la même structure de requête** — il NE
  DOIT **pas** exister deux représentations à maintenir (Art. 19).
- **FR-009**: L'extrait NE DOIT **pas** divulguer la valeur secrète de la clé ; il DOIT indiquer où
  l'utilisateur doit la fournir.
- **FR-010**: Un paramètre laissé vide NE DOIT **pas** apparaître dans l'extrait avec une valeur
  inventée.
- **FR-011**: L'extrait DOIT être correct **même sans exécution préalable** — il dérive de la requête
  composée.

#### Métrage et traçabilité (J2)

- **FR-012**: Un appel exécuté depuis la console DOIT être **métré comme tout appel** — il n'échappe
  ni à la comptabilité ni aux quotas.
- **FR-013**: Un appel exécuté depuis la console DOIT porter une **marque distinctive** indiquant son
  origine dans les journaux.
- **FR-014**: Le système DOIT afficher, pour chaque appel, son **coût**, sa **latence de premier
  jeton** et son **débit**.

#### Preuves (J2)

- **FR-015**: L'exactitude des extraits DOIT être prouvée par une **exécution réelle** de l'extrait
  généré, en plus d'une comparaison à des références figées.
- **FR-016**: Le métrage des appels et la complétude des paramètres d'échantillonnage DOIVENT être
  prouvés par des tests dédiés.

### Hors périmètre *(Art. 20 — YAGNI)*

- Le **service d'inférence**, l'authentification, les quotas et les budgets → **S04**, **S08**. La
  console est un **client comme un autre**.
- La **gestion des clés** — création, rotation, révocation → **S04**, **S13**. La console **utilise**
  une clé existante.
- Le **chat** et l'**arène** → **S16** : usage conversationnel persistant, distinct de l'essai
  ponctuel.
- La **coquille d'interface** → **S11**.
- La **trace détaillée** par requête → **S14**, où les appels de la console apparaissent avec leur
  marque.
- L'**enregistrement et le partage** de requêtes composées entre membres : hors périmètre, aucun
  jalon ne l'exige (Art. 20).

### Key Entities

- **Requête composée** : structure décrivant un appel d'inférence — messages, modèle, paramètres
  d'échantillonnage. **Source unique** dont dérivent à la fois l'appel réel et les extraits de code.
- **Extrait de code** : représentation textuelle exécutable de la requête composée, dans un langage
  ou un outil donné. Dérivé, jamais écrit à la main.
- **Appel de console** : exécution d'une requête composée, métrée et marquée de son origine.
  Rattachée à l'arbre de l'usage de la taxonomie.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Un extrait copié depuis la console **fonctionne tel quel**
  hors du produit et reproduit l'appel — vérifié par **exécution réelle**, pour chaque forme
  d'extrait proposée.
- **SC-002** *(critère A2)*: **100 %** des appels de la console sont métrés comme les autres appels
  et portent leur marque d'origine dans les journaux — **aucun** n'échappe à la comptabilité.
- **SC-003** *(critère A3)*: **Tous** les paramètres d'échantillonnage du contrat d'inférence sont
  disponibles dans la console — vérifié par comparaison au contrat.
- **SC-004**: L'extrait et l'appel réel dérivent de la **même structure** : une inspection ne trouve
  **aucune** seconde représentation de la requête.
- **SC-005**: **Zéro** valeur secrète de clé présente dans un extrait généré.
- **SC-006**: Un refus du serveur (droit, quota, budget) est présenté à l'identique de ce qu'un
  client réel recevrait.
- **SC-007**: Le coût, la latence de premier jeton et le débit sont affichés pour **100 %** des
  appels exécutés.
- **SC-008**: Un paramètre laissé vide n'apparaît dans **aucun** extrait avec une valeur inventée.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9v) |
| --- | --- | --- |
| A1 — l'extrait copié fonctionne tel quel | SC-001, SC-004, SC-005, SC-008 | T6 `[TEST]` références figées **et exécution réelle** |
| A2 — appels métrés et marqués | SC-002, SC-006 | T7 `[TEST]` métrage · T5 `[INT]` marque d'origine (S14) |
| A3 — paramètres d'échantillonnage complets | SC-003 | T7 `[TEST]` paramètres |
| Coût et latence affichés | SC-007 | T4 affichage coût / latence / débit |

## Assumptions

- **Dépendance à S11** : la console se pose dans la coquille d'interface existante. Elle n'introduit
  aucune infrastructure propre.
- **La console est un client comme un autre** : elle emprunte le service d'inférence public avec la
  clé choisie, sans accès privilégié. C'est ce qui rend l'essai **représentatif** : ce qui marche
  dans la console marche en production, et ce qui est refusé l'est aussi.
- **Une seule structure de requête (Art. 19)** : c'est la consigne explicite du document — « jamais
  deux templates à maintenir ». L'appel réel et chaque extrait sont **dérivés** de la même
  description. Sans cela, les extraits divergeraient silencieusement à la première évolution du
  contrat, et le critère A1 cesserait d'être vrai sans que personne le remarque.
- **La preuve d'exactitude passe par une exécution réelle** : le document mentionne des
  « snapshots » ; la spec exige **en plus** une exécution effective de l'extrait (FR-015, SC-001).
  Une comparaison à une référence figée prouve seulement que l'extrait n'a pas changé, pas qu'il
  fonctionne — ce que le critère A1 demande pourtant explicitement.
- **La valeur secrète de la clé n'est jamais écrite dans l'extrait** : ajout de la spec (FR-009),
  déduit de l'Art. 5 (« aucun secret en clair »). Un extrait copié se retrouve dans un canal de
  discussion ou un dépôt ; y inscrire une clé en clair serait une fuite par conception.
- **Formes d'extrait** : le document en cite trois. La spec exige « appel en ligne de commande et
  clients des langages courants », la liste exacte relevant du plan — l'exigence testable est que
  **chaque forme proposée** fonctionne réellement (SC-001).
- **Jalon M3** : la spec est **complète à M3**, dans une phase parallélisable sans risque bloquant.
