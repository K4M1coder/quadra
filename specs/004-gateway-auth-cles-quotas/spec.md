# Feature Specification: S04 — Gateway /v1 + auth clés + quotas

**Feature Branch**: `004-gateway-auth-cles-quotas`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9i du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S04 du plan de specs 9c : « Gateway /v1 + auth clés + quotas », références 5e · W1 · W5 · 4d · 5c, dépend de S01 et S03, effort ≈ 11 j-agent, phase 2 (cœur runtime), jalon produit M1 (MVP interne). **Revue humaine obligatoire** sur les chemins auth et proxy streaming (Art. 8).

## User Scenarios & Testing *(mandatory)*

Les parcours ci-dessous reprennent les jalons internes J1–J3 de la fiche 9i, par profondeur
croissante. Cette spec est le **point de passage unique** de toute requête d'inférence du système :
tout ce qui suit (S05 lanes, S06 hot-swap, S08 comptabilité, S16–S18 usages) s'y branche.

### User Story 1 - Fondations : la hiérarchie d'accès existe et les clés sont sûres (Priority: P1)

L'administrateur dispose d'une hiérarchie d'accès persistée — organisation, team, utilisateur, clé —
où chaque clé porte ses propres limites de débit, son cap de concurrence, son budget et sa lane. La
valeur secrète d'une clé n'est jamais stockée en clair.

**Why this priority**: c'est la profondeur J1 de la fiche 9i, et le socle de données dont dépendent
S08 (comptabilité), S12 (login) et S13 (permissions). Sans hiérarchie d'accès, il n'y a ni
authentification, ni quota, ni attribution de coût.

**Independent Test**: créer une organisation, une team, un utilisateur et une clé, puis vérifier en
base que la valeur secrète est absente et qu'une empreinte irréversible la remplace — sans qu'aucune
requête d'inférence ait été servie.

**Acceptance Scenarios**:

1. **Given** une base initialisée, **When** l'administrateur crée la hiérarchie organisation → team →
   utilisateur → clé, **Then** chaque niveau est persisté avec ses attributs propres (budget mensuel
   pour l'organisation ; budget et liste des modèles autorisés pour la team ; rôle pour
   l'utilisateur ; limites de débit, cap de concurrence, budget, lane et portées pour la clé).
2. **Given** une clé créée, **When** l'administrateur inspecte la base de données, **Then** la valeur
   secrète de la clé **n'y figure pas** : seule une empreinte irréversible est stockée.
3. **Given** une clé créée, **When** on inspecte les journaux et les métriques du système, **Then**
   la valeur secrète **n'y apparaît nulle part** ; seul un identifiant de clé non secret est utilisé.
4. **Given** une clé, **When** son état change, **Then** il suit la machine à états normative :
   active ⇄ suspendue (par dépassement de budget ou décision administrateur) → révoquée, les états
   terminaux étant immuables.
5. **Given** une clé en rotation, **When** une nouvelle valeur est émise, **Then** l'identité de la
   clé est conservée et l'ancienne valeur cesse d'être acceptée après un délai de grâce de
   **24 heures**.

---

### User Story 2 - Auth & quotas : ma clé m'authentifie, mes limites me répondent proprement (Priority: P2)

Un membre de l'équipe et un agent automatisé présentent chacun leur clé. Le système les identifie,
applique leurs limites de débit, leur cap de concurrence et leur budget, et refuse proprement — avec
le bon code et le bon délai d'attente — quand une limite est atteinte.

**Why this priority**: c'est la profondeur J2. Elle rend le serveur **multi-utilisateurs cadré** :
c'est la promesse du jalon M1 (« 3 humains + 1 agent capé »). Elle est vérifiable seule dès que J1
existe, en amont de tout proxy de flux.

**Independent Test**: avec deux clés aux limites différentes, émettre une rafale de requêtes et
constater que chacune est refusée exactement à sa propre limite, avec le code d'erreur et le délai
d'attente attendus.

**Acceptance Scenarios**:

1. **Given** une clé valide et active, **When** un client l'utilise pour s'authentifier, **Then** la
   requête est acceptée et rattachée à l'identité, aux portées et à la lane de cette clé.
2. **Given** une clé absente, malformée, révoquée ou suspendue, **When** un client l'utilise,
   **Then** la requête est refusée avec un code d'authentification, et le motif exact (clé révoquée
   ou clé suspendue) est distingué.
3. **Given** une clé dont la limite de débit en requêtes ou en jetons par minute est atteinte,
   **When** une requête supplémentaire arrive, **Then** elle est refusée avec le code de limitation
   de débit et un **délai d'attente exact** indiquant quand réessayer.
4. **Given** une clé dont le cap de concurrence est atteint, **When** une requête supplémentaire
   arrive, **Then** elle est refusée avec le code de dépassement de concurrence — distinct du
   dépassement de débit.
5. **Given** une clé dont le budget est épuisé, **When** une requête arrive, **Then** elle est
   refusée avec le code de dépassement de budget, distinct de la limitation de débit.
6. **Given** des budgets définis à plusieurs niveaux (organisation, team, clé), **When** le système
   évalue une requête, **Then** **le plafond le plus bas l'emporte** — l'héritage descend
   d'organisation vers team puis vers clé.
7. **Given** un budget consommé progressivement, **When** il franchit **80 %**, **90 %** puis
   **100 %**, **Then** le système déclenche respectivement une notification par courriel, une alerte
   avec bannière, puis le refus des requêtes.
8. **Given** une clé modifiée ou révoquée par un administrateur, **When** elle est présentée à
   nouveau, **Then** la modification prend effet en **au plus 60 secondes**, sans redémarrage du
   service.
9. **Given** une requête en cours d'exécution, **When** le budget est atteint pendant son
   déroulement, **Then** elle **n'est pas interrompue rétroactivement** — seules les requêtes
   suivantes sont refusées.

---

### User Story 3 - Proxy : je streame sans différence avec un fournisseur cloud (Priority: P3)

Un développeur branche un client standard compatible avec le contrat d'inférence de l'industrie,
sans modifier une ligne de son code, et obtient des réponses en flux. S'il interrompt sa connexion,
la génération est réellement arrêtée côté moteur.

**Why this priority**: c'est la profondeur J3 et la promesse produit centrale — « comme un
fournisseur cloud, mais les données ne quittent jamais l'entreprise ». C'est aussi le chemin le plus
risqué de la spec (flux et annulation), soumis à revue humaine.

**Independent Test**: exécuter un programme écrit pour un fournisseur cloud standard, en ne changeant
que l'adresse du service et la clé, et constater que complétion conversationnelle, flux et
représentations vectorielles fonctionnent sans modification ; puis interrompre le client en cours de
flux et vérifier côté moteur que la génération s'est arrêtée.

**Acceptance Scenarios**:

1. **Given** un client standard non modifié, **When** il demande une complétion conversationnelle,
   une complétion en flux, ou des représentations vectorielles, **Then** il obtient une réponse
   conforme au contrat de l'industrie, **sans aucune adaptation de son code**.
2. **Given** un client qui demande la liste des modèles disponibles, **When** le système répond,
   **Then** la liste est **filtrée selon les droits de la clé** : un client ne voit que les modèles
   auxquels sa team a accès.
3. **Given** une réponse en flux, **When** le moteur produit des jetons, **Then** le système les
   relaie **sans les mettre en tampon** : le premier jeton parvient au client dès que le moteur le
   produit.
4. **Given** un client qui ferme sa connexion pendant un flux, **When** la déconnexion est détectée,
   **Then** l'annulation est **propagée jusqu'au moteur** et la génération cesse réellement — le
   calcul n'est pas poursuivi dans le vide.
5. **Given** une requête quelconque, **When** elle est traitée, **Then** un identifiant de requête
   unique lui est attribué, retourné au client et utilisable pour la retrouver dans les traces.
6. **Given** une requête en attente dans une file, **When** le client interroge son état, **Then** sa
   position dans la file lui est communiquée.
7. **Given** une erreur quelconque, **When** le système la retourne, **Then** elle emprunte la forme
   attendue par les clients standards et porte un **code canonique stable** issu de la liste
   normative du projet, accompagné d'un message humain.
8. **Given** une requête servie de bout en bout, **When** elle se termine, **Then** le système émet
   les mesures correspondantes — nombre de requêtes par clé, modèle, lane et code ; latence du
   premier jeton ; jetons consommés en entrée et en sortie ; concurrence par clé.
9. **Given** une requête, **When** elle progresse, **Then** son état suit la machine à états
   normative : en file → ordonnancée → préremplissage → décodage → terminée, avec les issues
   alternatives refusée (limitée, hors budget, ne tient pas), annulée ou échouée.

---

### Edge Cases

- **Le client envoie un corps de requête non conforme au contrat** : refus immédiat avec une erreur
  de validation explicite, avant toute consommation de ressource moteur.
- **Deux requêtes atteignent la limite au même instant** : le comptage est exact — le cap de
  concurrence est respecté **à zéro dépassement près**, sans condition de course.
- **Le service de comptage rapide est indisponible** : le système refuse de servir plutôt que de
  servir sans limite — une limite non vérifiable est traitée comme atteinte (Art. 5, le serveur
  décide).
- **Le moteur cible n'est pas disponible ou le modèle n'est pas résident** : le client reçoit une
  erreur de service indisponible portant le code canonique correspondant, assortie si possible d'une
  estimation de délai — jamais une erreur générique.
- **Le contexte demandé dépasse la capacité** : refus explicite avec le code canonique dédié, plutôt
  qu'un échec tardif du moteur.
- **Le client se déconnecte avant même le premier jeton** : la requête est annulée et comptabilisée
  comme telle, pas comme terminée.
- **La même clé est utilisée depuis plusieurs endroits simultanément** : les limites s'appliquent à
  la clé, globalement — pas par connexion.
- **Une clé est révoquée pendant qu'une de ses requêtes s'exécute** : la requête en vol se termine ;
  les suivantes sont refusées.
- **Le délai d'attente retourné serait approximatif** : il doit être **exact** — un délai indicatif
  provoquerait des rafales de reprise synchronisées chez les agents.

## Requirements *(mandatory)*

### Functional Requirements

#### Hiérarchie d'accès et clés (J1)

- **FR-001**: Le système DOIT persister la hiérarchie d'accès du domaine : organisation → team →
  utilisateur → clé, conformément à l'arbre d'accès de la taxonomie.
- **FR-002**: Une organisation DOIT porter un budget mensuel ; une team DOIT porter un budget et la
  liste des modèles auxquels elle a accès ; un utilisateur DOIT porter son rôle ; une clé DOIT porter
  ses portées, sa lane, ses limites de débit (requêtes et jetons par minute), son cap de concurrence
  et son budget.
- **FR-003**: Le système NE DOIT **jamais** stocker la valeur secrète d'une clé : seule une empreinte
  irréversible est conservée.
- **FR-004**: La valeur secrète d'une clé NE DOIT apparaître dans **aucun** journal, **aucune**
  métrique et **aucun** message d'erreur ; seul un identifiant de clé non secret est utilisable
  ailleurs.
- **FR-005**: L'état d'une clé DOIT suivre la machine à états normative : active ⇄ suspendue →
  révoquée, les états terminaux étant immuables.
- **FR-006**: La rotation d'une clé DOIT conserver son identité, émettre une nouvelle valeur et
  laisser l'ancienne valide pendant un délai de grâce de **24 heures**, au terme duquel elle cesse
  d'être acceptée.
- **FR-007**: Les évolutions du schéma de données DOIVENT être portées par des migrations
  versionnées, jamais renumérotées.

#### Authentification (J2 — chemin à revue humaine)

- **FR-008**: Le système DOIT authentifier chaque requête d'inférence à partir de la clé présentée,
  et rattacher la requête à l'identité, aux portées et à la lane correspondantes.
- **FR-009**: Le système DOIT refuser toute requête dont la clé est absente, malformée, révoquée ou
  suspendue, en distinguant ces motifs par des codes canoniques stables.
- **FR-010**: Le système DOIT mettre en cache le résultat de la résolution d'une clé pour une durée
  d'au plus **60 secondes**, et DOIT invalider ce cache lorsqu'une clé est modifiée ou révoquée, de
  sorte qu'un changement prenne effet en au plus 60 secondes sans redémarrage.

#### Quotas, caps et budgets (J2)

- **FR-011**: Le système DOIT appliquer, par clé, une limite de débit en **requêtes par minute** et
  en **jetons par minute**, évaluée sur une fenêtre glissante.
- **FR-012**: Le système DOIT appliquer, par clé, un **cap de concurrence** respecté à **zéro
  dépassement près**, y compris en cas de requêtes simultanées.
- **FR-013**: Le système DOIT refuser toute requête dépassant une limite de débit avec le code
  canonique de limitation et un **délai d'attente exact**.
- **FR-014**: Le système DOIT refuser toute requête dépassant le cap de concurrence avec un code
  canonique **distinct** de celui de la limitation de débit.
- **FR-015**: Le système DOIT refuser toute requête d'une clé dont le budget est épuisé, avec le code
  canonique de dépassement de budget.
- **FR-016**: Lorsque des budgets existent à plusieurs niveaux, **le plafond le plus bas DOIT
  l'emporter**, l'héritage descendant d'organisation vers team puis vers clé.
- **FR-017**: Le système DOIT déclencher une notification à **80 %** du budget, une alerte avec
  bannière à **90 %**, et le refus des requêtes à **100 %**.
- **FR-018**: Le système NE DOIT **jamais** interrompre rétroactivement une requête en vol lorsqu'un
  budget est atteint pendant son exécution.
- **FR-019**: Si le mécanisme de comptage rapide est indisponible, le système DOIT refuser de servir
  plutôt que de servir sans limite.

#### Contrat d'inférence et proxy de flux (J3 — chemin à revue humaine)

- **FR-020**: Le contrat d'interface DOIT être **écrit et figé avant** toute implémentation, et
  constituer la source unique dont le client d'interface est généré (Art. 19).
- **FR-021**: Le système DOIT exposer la complétion conversationnelle (avec et sans flux), la
  complétion historique, les représentations vectorielles et la liste des modèles, conformément au
  contrat d'inférence standard de l'industrie.
- **FR-022**: Un client standard non modifié DOIT fonctionner sans **aucune** adaptation de son code,
  au-delà du changement d'adresse de service et de clé.
- **FR-023**: La liste des modèles DOIT être **filtrée selon les droits de la clé** présentée.
- **FR-024**: Le système DOIT relayer les réponses en flux **sans mise en tampon**, de sorte que le
  premier jeton parvienne au client dès que le moteur le produit.
- **FR-025**: À la déconnexion d'un client pendant un flux, le système DOIT **propager l'annulation
  jusqu'au moteur** afin que la génération cesse réellement.
- **FR-026**: Le système DOIT attribuer à chaque requête un **identifiant unique**, le retourner au
  client, et permettre de retrouver la requête par cet identifiant.
- **FR-027**: Le système DOIT communiquer au client la **position en file** d'une requête en attente.
- **FR-028**: Toute erreur DOIT emprunter la forme attendue par les clients standards et porter un
  **code canonique stable** issu de la liste normative du projet, accompagné d'un message humain.
- **FR-029**: L'état d'une requête DOIT suivre la machine à états normative : en file → ordonnancée →
  préremplissage → décodage → terminée, avec les issues refusée (limitée, hors budget, ne tient pas),
  annulée ou échouée.

#### Observabilité (J3)

- **FR-030**: Le système DOIT émettre, pour chaque requête, les mesures du projet : compteur de
  requêtes ventilé par clé, modèle, lane et code de retour ; latence du premier jeton ; jetons
  consommés en entrée et en sortie ; concurrence courante par clé.
- **FR-031**: Les mesures émises DOIVENT respecter la convention de nommage du projet et n'utiliser
  que des libellés à cardinalité bornée, sans donnée personnelle ni contenu de prompt.

#### Preuves (J4)

- **FR-032**: La conformité au contrat d'inférence DOIT être prouvée par des tests exécutant de
  **vrais clients standards** de l'industrie contre le service.
- **FR-033**: L'exactitude des refus sous charge DOIT être prouvée par un test de charge produisant
  une rafale d'agents.

### Hors périmètre *(Art. 20 — YAGNI)*

- Les **lanes de priorité**, l'arbitrage entre elles et la préemption → **S05**. S04 rattache une
  requête à sa lane et expose sa position en file ; c'est S05 qui ordonnance.
- Le **choix de l'instance**, le hot-swap et le placement des modèles → **S06**, **S07**. S04
  s'adresse à un routeur, sans connaître les moteurs.
- L'**enregistrement comptable** des requêtes, le calcul de coût, la vue de consommation et l'export
  → **S08**. S04 applique les budgets ; S08 les alimente et les restitue.
- Les **traces détaillées** par étape et la conservation des prompts → **S14**.
- L'**interface d'administration** des clés, des teams et des budgets → **S11**, **S13**. À M1, les
  clés sont gérées directement en base, sans interface (profondeur du jalon).
- Le **contrôle d'accès par rôle** sur les routes d'administration → **S13**.
- Les **jobs asynchrones par lot** → **S18**. Décision **D6** (voir
  [`RESEARCH-STACK.md`](../RESEARCH-STACK.md)) : les lots sont exposés sur la **surface
  d'administration**, pas sur la surface d'inférence publique. Le contrat public figé ici **ne
  déclare donc aucune route de lots**.
- La **connexion des utilisateurs** (authentification humaine, sessions, fournisseur d'identité) →
  **S12**. S04 traite l'authentification **par clé** des clients programmatiques.

### Key Entities

- **Organisation** : sommet de l'arbre d'accès. Attribut : budget mensuel.
- **Team** : regroupement d'utilisateurs. Attributs : budget, liste des modèles autorisés.
- **Utilisateur** : personne rattachée à une ou plusieurs teams. Attributs : rôle, identifiant
  externe d'authentification.
- **Clé** : moyen d'accès programmatique. Attributs : empreinte irréversible de la valeur secrète,
  portées, lane, limites de débit (requêtes et jetons par minute), cap de concurrence, budget, état
  (active / suspendue / révoquée).
- **Requête** : une entrée dans le service d'inférence, unité d'usage et de facturation. Attributs :
  identifiant unique, clé, modèle, lane, jetons entrée/sortie, durée, code de retour, état.
- **Budget** : plafond de dépense exprimé en monnaie, attaché à une clé, une team ou une
  organisation — **distinct du quota**, qui est un plafond de débit.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Un programme écrit pour un fournisseur d'inférence standard
  fonctionne **sans aucune modification de code** — complétion conversationnelle, flux et
  représentations vectorielles — en ne changeant que l'adresse du service et la clé.
- **SC-002** *(critère A2)*: Sous une rafale d'agents, **100 %** des refus pour dépassement de débit
  portent le bon code et un délai d'attente **exact** : un client qui respecte ce délai n'est plus
  refusé.
- **SC-003** *(critère A3)*: À la déconnexion d'un client pendant un flux, la génération est arrêtée
  côté moteur dans **100 %** des cas — aucune génération orpheline ne se poursuit.
- **SC-004**: La valeur secrète d'une clé est introuvable dans la base, les journaux et les
  métriques : **zéro occurrence** lors d'une recherche automatisée.
- **SC-005**: Le cap de concurrence par clé est respecté à **±0** : sous rafale simultanée, le nombre
  de requêtes en vol pour une clé n'excède **jamais** son cap.
- **SC-006**: Une révocation ou une modification de clé prend effet en **au plus 60 secondes**, sans
  redémarrage du service.
- **SC-007**: Lorsque plusieurs budgets s'appliquent, le plafond effectif est **le plus bas** dans
  **100 %** des combinaisons testées.
- **SC-008**: Le premier jeton parvient au client **sans attendre la fin** de la génération : la
  latence du premier jeton mesurée côté client est du même ordre que celle mesurée côté moteur.
- **SC-009**: **100 %** des erreurs retournées portent un code canonique de la liste normative — une
  vérification automatisée ne trouve aucun code hors liste.
- **SC-010**: Une requête servie est retrouvable par son identifiant unique.
- **SC-011**: Aucune requête en vol n'est interrompue rétroactivement par l'atteinte d'un budget.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9i) |
| --- | --- | --- |
| A1 — SDK standard sans modification | SC-001, SC-009, SC-010 | T14 `[INT]` tests de contrat avec de vrais clients |
| A2 — refus de débit exacts sous rafale | SC-002, SC-005, SC-007 | T15 `[TEST]` charge : rafale d'agents |
| A3 — déconnexion → annulation propagée | SC-003, SC-008 | T16 `[TEST]` client standard + annulation |
| Consigne « jamais de clé en clair » | SC-004 | T3 empreinte irréversible — **revue humaine** |
| Invalidation du cache de clés | SC-006 | T4 cache + invalidation |
| Pas de blocage rétroactif | SC-011 | T8 vérification de budget |

**Revue humaine obligatoire** (Art. 8) : les chemins **authentification** (T3–T5) et **proxy de
flux** (T10–T11) sont relus ligne à ligne par un humain, en plus des portes mécaniques.

## Assumptions

- **Dépendances** : S01 fournit la pile démarrée (bases, cache, reverse proxy) ; S03 fournit le
  moteur factice et la chaîne de contrôle. Les tests d'intégration et de charge de S04 s'exécutent
  contre le **moteur factice**, jamais contre un GPU (Art. 8).
- **Le contrat est figé par un humain avant le code** : la tâche T9 (« contrat figé ») est explicitement
  attribuée à un humain dans le document. Le client d'interface en est ensuite **généré** (Art. 19).
- **Compatibilité stricte, jamais d'extension** : la surface d'inférence publique suit le contrat de
  l'industrie et **n'est jamais étendue** ; tout besoin propre au produit vit sur la surface
  d'administration, distincte (convention de nommage 10b).
- **Le routage s'adresse à un routeur, pas à un moteur** : S04 traduit un alias de modèle en cible de
  routage et délègue ; il ne connaît ni les moteurs ni leur placement (Art. 18). À M1, ce routeur est
  fourni par S05 et S06.
- **Profondeur du jalon M1** : à M1, les clés sont administrées **directement en base**, sans
  interface (« clés gérées en SQL, pas encore d'UI »). Aucune interface n'est anticipée ici
  (Art. 20).
- **Comptage rapide en mémoire partagée** : les compteurs de débit et de concurrence vivent dans le
  magasin rapide de la pile, en fenêtre glissante ; l'enregistrement durable des requêtes appartient
  à S08 et se fait **hors du chemin critique**.
- **Seuils de budget** : 80 % / 90 % / 100 % sont fixés par le document (W5) et communs à tout le
  projet.
- **Délai de grâce de rotation** : 24 heures, fixé par le document (W4).
- **Le refus prime sur le service dégradé** : en cas d'indisponibilité d'un mécanisme de limite, le
  système refuse — conséquence directe de l'Art. 5 (le serveur décide) et de l'Art. 2 (protéger la
  lane interactive).
