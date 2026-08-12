# Feature Specification: S03 — Socle qualité & CI

**Feature Branch**: `003-socle-qualite-ci`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9h du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S03 du plan de specs 9c : « Socle qualité & CI : lint, types, tests, moteur factice, pipeline », référence 9b, sans dépendance, effort ≈ 1 sem en 9c (≈ 6.5 j-agent au détail de la fiche 9h), phase 1 (socle), jalon produit M0 (Alpha).

## User Scenarios & Testing *(mandatory)*

Les parcours ci-dessous reprennent les jalons internes J1–J3 de la fiche 9h, par profondeur
croissante. Les « utilisateurs » de cette spec sont les contributeurs du projet — développeur humain,
agent IA implémentant une tâche, et mainteneur — puisque la feature livrée est la **chaîne de
contrôle** qui rend la definition of done mécanique (Art. 8).

### User Story 1 - Fondations : les portes locales refusent le non conforme (Priority: P1)

Un contributeur — humain ou agent — tente de valider un changement mal formaté, mal typé, ou
contenant un secret en dur. Les portes locales le refusent immédiatement, avant tout envoi, en
identifiant le fichier non conforme.

**Why this priority**: c'est la profondeur J1 et la condition d'existence de toutes les autres
specs. L'Art. 14 exige que « les hooks locaux exécutent exactement les portes de la CI » — sans J1,
aucun contributeur ne peut prédire une CI verte, et la délégation des tâches aux agents IA (Art. 8)
devient impossible faute de critère mécanique.

**Independent Test**: sur un dépôt fraîchement cloné, tenter de valider successivement un fichier
mal formaté, un fichier mal typé et un fichier contenant un secret en dur, puis constater que chaque
tentative est refusée et que le fichier en cause est identifié — sans qu'aucune chaîne d'intégration
distante existe encore.

**Acceptance Scenarios**:

1. **Given** un dépôt configuré, **When** un contributeur tente de valider un fichier qui viole les
   règles de formatage ou de style, **Then** la validation est **refusée** et le fichier non conforme
   est identifié.
2. **Given** un dépôt configuré, **When** un contributeur tente de valider du code du plan de
   contrôle dont le typage est incomplet ou incorrect, **Then** la validation est refusée : le typage
   strict est exigé sur le plan de contrôle.
3. **Given** un dépôt configuré, **When** un contributeur tente de valider un fichier contenant un
   secret en clair, **Then** la validation est refusée avant tout envoi (Art. 21).
4. **Given** un dépôt configuré, **When** un contributeur rédige un message de validation qui ne
   respecte pas la convention de nommage des commits, ou dont le `scope` ne désigne pas la spec
   concernée, **Then** la validation est refusée.
5. **Given** les deux versants du projet (plan de contrôle et interface), **When** un contributeur
   lance les portes locales, **Then** les règles de style, de typage et de tests s'appliquent **des
   deux côtés**, pas seulement au plan de contrôle.

---

### User Story 2 - Cœur : un moteur factice permet de tout tester sans GPU (Priority: P2)

Un contributeur écrit et exécute les tests d'intégration du plan de contrôle contre un moteur
d'inférence simulé, qui reproduit fidèlement le comportement d'un vrai moteur — réponses en flux,
latence paramétrable, erreurs injectables — sur une machine sans aucun GPU.

**Why this priority**: c'est la profondeur J2 et la clé de voûte de l'Art. 8 : **la CI ne touche
jamais un GPU**, les vrais moteurs ne sont exercés qu'au canari. Sans moteur factice, ni S04
(streaming, annulation), ni S05 (anti-starvation), ni S06 (hot-swap) ne seraient testables
mécaniquement. C'est aussi ce qui rend les tests reproductibles : une latence choisie plutôt que
subie.

**Independent Test**: sur une machine sans GPU, démarrer le moteur factice, lui demander une réponse
en flux, lui imposer une latence donnée puis lui faire injecter une erreur — et constater que chaque
comportement est celui demandé.

**Acceptance Scenarios**:

1. **Given** le moteur factice démarré sur une machine sans GPU, **When** un client compatible avec
   le contrat d'inférence standard lui adresse une demande de complétion en flux, **Then** il reçoit
   une réponse **jeton par jeton**, dans le même format qu'un moteur réel.
2. **Given** le moteur factice, **When** un test lui impose une latence de premier jeton et une
   latence inter-jetons données, **Then** les réponses respectent ces latences — le test devient
   déterministe.
3. **Given** le moteur factice, **When** un test lui demande d'injecter une erreur donnée, **Then**
   il la produit fidèlement, permettant de vérifier le comportement du plan de contrôle en cas de
   défaillance moteur.
4. **Given** le moteur factice, **When** un test demande une représentation vectorielle, **Then** le
   moteur répond au format attendu — les tests ne se limitent pas à la complétion conversationnelle.
5. **Given** plusieurs specs qui ont besoin d'un moteur simulé, **When** leurs tests d'intégration
   s'exécutent, **Then** ils réutilisent **le même** moteur factice : il n'en existe qu'une seule
   implémentation dans le projet (Art. 19).

---

### User Story 3 - Chaîne : l'intégration rejoue tout, bout à bout (Priority: P3)

Le mainteneur pousse un changement et la chaîne d'intégration rejoue, dans l'ordre, l'ensemble des
portes — style, typage, tests avec seuils de couverture, sécurité, construction des images, puis
parcours de bout en bout **et charge** sur un environnement éphémère — et refuse la fusion si une
seule porte est rouge. Ces portes gardent une topologie de fusion fixe : rien n'entre dans `dev`
sans elles, et rien n'atteint `master` sans être passé par `test` (Art. 23).

**Why this priority**: c'est la profondeur J3, qui transforme les portes locales en garantie
collective. Elle est vérifiable seule dès que J1 et J2 existent, et elle rend applicable l'Art. 16
(« une porte rouge arrête le fil »).

**Independent Test**: soumettre successivement un changement conforme, un changement dont la
couverture passe sous le seuil, et un changement introduisant une dépendance vulnérable — et
constater que seule la première soumission est acceptée.

**Acceptance Scenarios**:

1. **Given** un changement conforme, **When** la chaîne d'intégration s'exécute, **Then** elle
   franchit les portes **dans l'ordre** : style et formatage → typage → tests et couverture →
   contrôles de sécurité → construction des images → parcours de bout en bout **et charge**.
2. **Given** un changement qui fait passer la couverture du cœur (authentification, quotas,
   comptabilité) **sous 90 %**, **When** la chaîne s'exécute, **Then** elle échoue et la fusion est
   bloquée.
3. **Given** un changement qui fait passer la couverture hors cœur **sous 70 %**, **When** la chaîne
   s'exécute, **Then** elle échoue et la fusion est bloquée.
4. **Given** la chaîne d'intégration, **When** elle exécute l'intégralité de ses étapes, **Then**
   **aucune** d'entre elles n'accède à un GPU : l'environnement d'exécution n'en comporte pas.
5. **Given** l'étape de bout en bout, **When** elle démarre, **Then** elle s'appuie sur un
   environnement éphémère complet, associé au moteur factice, détruit à la fin de l'exécution — et
   c'est sur ce même environnement que s'exécute son volet de **charge**.
6. **Given** un changement introduisant une dépendance affectée par une vulnérabilité connue,
   **When** la chaîne s'exécute, **Then** elle échoue et nomme la dépendance concernée.
7. **Given** une porte rouge, **When** un contributeur tente de la désactiver pour faire passer son
   changement, **Then** cela constitue une faute de gouvernance et non une mitigation : la
   configuration des portes est versionnée et sa modification est visible en revue (Art. 14).
8. **Given** l'étape de bout en bout et de charge, **When** son scénario de charge échoue, **Then**
   la chaîne échoue et la fusion est bloquée : la charge est une porte, pas une mesure indicative
   (Art. 8, porte 4).
9. **Given** la topologie de fusion de l'Art. 23, **When** un contributeur tente de porter un commit
   directement sur `test` ou sur `master`, ou de faire entrer une branche `NNN-slug` dans `dev` alors
   qu'une porte de rang 1 à 3 est rouge, **Then** l'opération est refusée : `dev` ne s'atteint que par
   demande de fusion aux portes vertes, et `master` que par promotion depuis `test`.
10. **Given** un changement qui laisse les migrations de base de données incohérentes avec le schéma
    déclaré, **When** la chaîne s'exécute, **Then** elle échoue et nomme l'incohérence.
11. **Given** une étape de la chaîne qui référence une action, un outil ou une image sur un tag
    flottant (`:latest`, une branche, un intervalle ouvert), **When** la chaîne s'exécute, **Then**
    elle échoue : la définition de la chaîne est épinglée comme le reste (Art. 11).

---

### Edge Cases

- **Un contributeur contourne les portes locales** (validation forcée) : la chaîne d'intégration
  distante rejoue exactement les mêmes portes et refuse le changement — le local prédit, le distant
  fait autorité.
- **Le moteur factice diverge du comportement réel** : l'écart est traité comme un défaut du moteur
  factice et corrigé, puisqu'il invalide silencieusement toute la pyramide de tests.
- **Une dépendance vulnérable n'a pas de correctif publié** : la chaîne échoue par défaut ; la seule
  issue admise est de documenter et d'isoler la vulnérabilité explicitement — jamais de l'accepter
  silencieusement (Art. 21).
- **Un test est instable** (résultat non déterministe) : il est traité comme un test en échec ; la
  latence et les erreurs étant paramétrables sur le moteur factice, aucune instabilité liée au timing
  n'a de raison d'être tolérée.
- **La couverture est annoncée sans sortie capturée** : la valeur est refusée — seule une mesure
  produite par l'outillage fait foi (Art. 10).
- **Le seuil de couverture est atteint par des tests qui n'assertent rien** : la porte de couverture
  est nécessaire mais non suffisante ; le cycle rouge-vert (voir le test échouer d'abord) reste
  obligatoire pour tout comportement (Art. 10).
- **L'environnement éphémère de bout en bout ne démarre pas** : l'étape échoue explicitement plutôt
  que d'être ignorée.

## Requirements *(mandatory)*

### Functional Requirements

*La numérotation suit l'ordre de création : les exigences **FR-026 et suivantes** ont été ajoutées
après la première rédaction et figurent dans la rubrique qui les concerne, sans renumérotation — les
renvois des autres artefacts restent valides.*

#### Portes locales (J1)

- **FR-001**: Le projet DOIT fournir des portes de validation locales exécutées avant tout envoi,
  couvrant le formatage, le style, le typage et la détection de secrets en clair.
- **FR-002**: Les portes locales DOIVENT exécuter **exactement** les mêmes contrôles que la chaîne
  d'intégration distante, afin qu'un état vert en local prédise un état vert à distance (Art. 14).
  L'équivalence porte sur les portes exécutables localement (rangs 1 à 3) ; les portes 4 et 5
  n'existent qu'à distance (Art. 23).
- **FR-003**: Le typage DOIT être vérifié en mode strict sur le plan de contrôle et sur l'interface.
- **FR-004**: Les messages de validation DOIVENT respecter une convention de nommage vérifiée
  mécaniquement, permettant la génération automatique du journal des modifications. Le `scope` du
  message DOIT désigner la spec concernée, dans la graphie fixée par `10b` (« Commits :
  conventionnels, scope = spec », `feat(S09): vram fit estimator`) ; un message sans `scope` de spec
  est refusé par la même porte.
- **FR-005**: Les portes DOIVENT s'appliquer aux **deux versants** du projet — plan de contrôle et
  interface utilisateur — avec l'outillage propre à chacun.
- **FR-006**: Le refus d'une porte locale DOIT identifier le **fichier** non conforme — c'est la
  granularité que porte le critère A1 de `9h` (« pre-commit bloque un fichier non conforme »). La
  qualité rédactionnelle des messages n'est **pas** une exigence de S03 : l'outillage restitue la
  sortie de ses propres contrôles telle quelle, et l'exigence de « messages actionnables » du document
  ne concerne que les erreurs Hugging Face (`9c`, `9n` — S09).

#### Moteur factice (J2)

- **FR-007**: Le projet DOIT fournir un **moteur d'inférence simulé** exposant le même contrat que
  les moteurs réels, exécutable sur une machine dépourvue de GPU.
- **FR-008**: Le moteur factice DOIT produire des réponses **en flux**, jeton par jeton, dans le
  format des moteurs réels.
- **FR-009**: Le moteur factice DOIT permettre de **fixer la latence** du premier jeton et la latence
  inter-jetons, afin de rendre les tests déterministes.
- **FR-010**: Le moteur factice DOIT permettre d'**injecter des erreurs** choisies, afin de vérifier
  le comportement du plan de contrôle en cas de défaillance moteur.
- **FR-011**: Le moteur factice DOIT couvrir la complétion conversationnelle et les représentations
  vectorielles.
- **FR-012**: Le moteur factice DOIT être un composant **unique et réutilisable** par tous les tests
  d'intégration du projet — aucune seconde implémentation de simulateur n'est admise (Art. 19).

#### Chaîne d'intégration (J3)

- **FR-013**: La chaîne d'intégration DOIT exécuter les portes dans l'ordre : style et formatage →
  typage → tests et couverture → contrôles de sécurité → construction des images → parcours de bout
  en bout **et charge**. Le dernier maillon est une porte unique, conformément à la porte 4 de
  l'Art. 8 (« e2e + charge sur compose éphémère ») et à `9b` (« e2e + k6 · compose éphémère · moteur
  factice »).
- **FR-014**: La chaîne DOIT échouer, et bloquer la fusion, dès qu'une seule porte est rouge.
- **FR-015**: La chaîne DOIT imposer une couverture **≥ 90 %** sur le cœur (authentification,
  quotas, comptabilité) et **≥ 70 %** ailleurs, ces seuils étant **bloquants** et mesurés par
  l'outillage.
- **FR-016**: La chaîne NE DOIT **jamais** accéder à un GPU ; les moteurs réels ne sont exercés qu'au
  déploiement canari.
- **FR-017**: L'étape de bout en bout DOIT s'exécuter sur un environnement éphémère complet associé
  au moteur factice, détruit en fin d'exécution.
- **FR-018**: La chaîne DOIT exécuter des contrôles de sécurité — analyse statique du code et audit
  des dépendances — et échouer en nommant la dépendance ou le motif en cause (Art. 21).
- **FR-019**: Les images construites DOIVENT être étiquetées de façon reproductible (version
  sémantique et digest du contenu), pour rendre le retour arrière possible par simple
  ré-étiquetage (Art. 11).
- **FR-020**: Toute la configuration des portes DOIT être **versionnée dans le dépôt**, de sorte que
  la désactivation d'une porte soit visible en revue.
- **FR-026**: La définition de la chaîne DOIT être **épinglée** au même titre que ce qu'elle produit :
  chaque action, outil ou image qu'une étape consomme est référencée par un tag exact ou une
  digest — jamais `:latest`, jamais une branche, jamais un intervalle ouvert (Art. 11 : « toute
  image, dépendance **ou action CI** EST épinglée »). Un référencement flottant DOIT faire échouer la
  chaîne. FR-019 couvre les images **construites** ; celle-ci couvre les briques **consommées** par la
  chaîne elle-même.
- **FR-027**: L'étape de bout en bout DOIT comporter un volet de **charge**, exécuté sur le même
  environnement éphémère et contre le même moteur factice, et son échec DOIT bloquer la fusion : la
  charge est une porte, pas une dépendance d'outillage sans porte (Art. 8 porte 4 ; `9b`). S03 rend
  l'étape exécutable et y place le minimum qui prouve la porte ; les scénarios eux-mêmes vivent dans
  `k6/<lane>-<scénario>.js` (`10b`) et sont versionnés par **S21**, qui les rejoue sans en créer un
  second jeu (Art. 19).
- **FR-028**: La chaîne DOIT exécuter le contrôle de cohérence des migrations de base de données —
  `alembic check` en `9b`, porte du socle partagé — et échouer si les migrations et le schéma déclaré
  divergent. À M0 aucune migration n'existe encore, le schéma arrivant avec **S04** (`9c`, jalon M1) :
  la porte est posée et s'exécute à vide, et son rattachement à S03 plutôt qu'à S04 est porté en
  ARBITRAGE.

#### Topologie de fusion et régime courant (Art. 23)

- **FR-029**: Les portes DOIVENT garder une topologie de fusion **fixe** : une branche de
  développement `NNN-slug` n'entre dans `dev` que par demande de fusion ; `dev` promeut vers `test`,
  où la chaîne s'exécute intégralement ; `test` promeut vers `master`, qui reste stable par
  construction. Les portes de rang 1 à 3 — validation locale, contrôles de typage / tests /
  couverture / sécurité, construction des images épinglées — gardent l'**entrée dans `dev`** ; les
  portes 4 et 5 — bout en bout et charge, canari —, qui n'existent qu'à distance, gardent la
  **promotion de `test`**. Aucune promotion NE DOIT sauter un maillon, et aucun commit direct NE DOIT
  atterrir sur `test` ni sur `master`.
- **FR-030**: Dès que la chaîne existe, son usage DOIT être **obligatoire et exclusif** : aucun
  changement n'entre sans l'avoir traversée, aucune porte n'est contournée, aucune fusion ne se fait
  hors d'elle ; dès qu'un dépôt distant existe, la fusion passe par la forge et ses protections de
  branche, jamais par une fusion locale. En son absence, les portes locales DOIVENT faire foi seules
  et leur sortie capturée EST la definition of done. La livraison de S03 EST la **condition de sortie**
  du régime dégradé consigné dans la constitution : cette spec ne livre pas seulement de l'outillage,
  elle clôt un régime transitoire.

#### Pyramide de tests et definition of done (transverse, Art. 10)

- **FR-021**: Le socle DOIT poser à **M0** l'outillage des niveaux de la pyramide (Art. 10) qui ne
  dépendent d'aucune fonctionnalité métier : **unitaires**, **intégration sur bases éphémères**,
  **bout en bout**, **charge** et **sécurité**. Les niveaux restants sont rendus exécutables par les
  specs qui les produisent, sans anticipation à M0 (Art. 20) : **contrat** (clients standards réels
  contre la surface publique) → **S04**, jalon M1 ; **fichiers de référence** de facturation →
  **S08**, M2 ; **tests générés depuis une source unique** (matrice de permissions) → **S13**, M2 ;
  **résilience** (coupure / reprise, kill `worker`, restauration de sauvegarde) → **S19**, **S20**,
  **S21**, M4. S03 ne préempte ni leur outillage ni leurs jeux d'essai.
- **FR-022**: Le socle DOIT permettre de démarrer des bases de données **éphémères** pour les tests
  d'intégration, sans dépendre d'une instance partagée.
- **FR-023**: Le socle DOIT fournir des commandes uniformes et documentées pour exécuter localement
  chaque famille de contrôles (style, tests, bout en bout, construction, démarrage).
- **FR-024**: La **definition of done** d'une tâche DOIT être mécaniquement vérifiable : style et
  typage propres, tests écrits et verts, couverture au seuil, contrat d'interface inchangé ou
  versionné.

#### Preuves (J4)

- **FR-025**: Le socle DOIT être vérifiable par une procédure automatisée prouvant simultanément
  qu'une porte locale refuse un fichier non conforme, que la chaîne échoue sous les seuils de
  couverture, et que le moteur factice reproduit flux, latence et erreurs.

### Hors périmètre *(Art. 20 — YAGNI)*

- Le contenu métier testé (authentification, quotas, ordonnancement…) → specs **S04** et suivantes.
  S03 fournit **l'outillage**, pas les tests métier eux-mêmes.
- La matrice de permissions générée et ses tests → **S13** (S03 rend le mécanisme possible, S13
  fournit la source de vérité), jalon **M2**.
- Les scénarios de charge métier et le runbook d'incidents → **S21** (S03 rend l'étape de charge
  exécutable et porteuse d'une porte, S21 versionne les scénarios), jalon **M4**.
- La **génération du client d'interface** depuis le contrat et sa vérification → **S11** (`9p`,
  tâche T2, critère A1 « Client API 100 % généré (openapi-typescript) »), jalon **M2**. `9h` ne met
  dans `ui/` que « eslint flat, prettier, vitest, playwright » : S03 outille le style, le typage et
  les tests de l'interface, pas la génération de son client.
- Les **fichiers de référence** de facturation → **S08** (M2) ; les tests de **résilience** —
  coupure / reprise, kill `worker`, restauration de sauvegarde → **S19**, **S20**, **S21** (M4).
- Le déploiement canari sur GPU et la bascule → workflow d'exploitation, hors chaîne d'intégration.
- Le démarrage de la pile de production et son exposition réseau → **S01**.
- La collecte de métriques et les tableaux de bord → **S02**.

### Key Entities

- **Moteur factice** : simulateur qui expose le contrat d'un `engine` de l'arbre d'exécution de `10a`
  (`Cluster → Host → Node → Engine → Instance`) **sans en être une instance** — il ne sert aucun
  `alias` en production et ne réside sur aucun `node`. Attributs paramétrables : latence du premier
  jeton, latence inter-jetons, erreur injectée, capacités exposées (complétion en flux,
  représentations vectorielles).

Aucune autre entité n'est introduite. Les **portes**, leurs **seuils** et leurs **étapes** ne sont pas
des entités du domaine : l'arbre de la méthode de `10a` s'arrête à `Tâche Tn`
(`Constitution → Spec S01–S21 → Plan → Jalon interne J1–J4 → Tâche Tn`), et l'Art. 17 interdit de
faire naître dans le code un concept absent de la taxonomie. Ils restent ici des propriétés de la
chaîne décrites par les exigences ci-dessus. Les modéliser exigerait un **amendement préalable** de
`10a` — consigné en ARBITRAGE, jamais créé au passage.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Une tentative de validation d'un fichier non conforme
  (formatage, style, typage ou secret en clair) est **refusée dans 100 % des cas**, et le refus
  identifie le fichier en cause.
- **SC-002** *(critère A2)*: Un changement faisant passer la couverture du cœur sous **90 %**, ou la
  couverture hors cœur sous **70 %**, fait échouer la chaîne d'intégration et **bloque la fusion**.
- **SC-003** *(critère A3)*: Le moteur factice reproduit, **sur une machine sans GPU**, une réponse
  en flux jeton par jeton, une latence imposée respectée, et une erreur injectée conforme à celle
  demandée.
- **SC-004**: **100 %** des étapes de la chaîne d'intégration s'exécutent sans accéder à un GPU.
- **SC-005**: Un état vert des portes locales prédit un état vert de la chaîne distante : les deux
  exécutent le **même ensemble** de contrôles pour les portes de rang 1 à 3 (Art. 14, Art. 23).
  L'équivalence est obtenue par une **définition unique** des portes, versionnée et invoquée de part et
  d'autre (FR-002, FR-020) — aucun test de parité entre les deux n'est exigé : la constitution demande
  l'équivalence, pas un mécanisme de comparaison.
- **SC-006**: Un changement introduisant une dépendance affectée par une vulnérabilité connue fait
  échouer la chaîne et **nomme** la dépendance concernée.
- **SC-007**: L'environnement éphémère de bout en bout est **entièrement détruit** après exécution :
  aucune ressource résiduelle ne subsiste entre deux exécutions.
- **SC-008**: Un contributeur — humain ou agent — peut déterminer si sa tâche est terminée **sans
  jugement humain**, à partir des seules sorties de l'outillage.
- **SC-009**: Aucun commit n'atterrit directement sur `test` ni sur `master`, et **100 %** des entrées
  dans `dev` sont des demandes de fusion dont les portes de rang 1 à 3 sont vertes (Art. 23).
- **SC-010**: Un scénario de charge en échec fait échouer la chaîne et **bloque la fusion**, au même
  titre qu'un test unitaire rouge.
- **SC-011**: **100 %** des actions, outils et images consommés par les étapes de la chaîne sont
  épinglés par tag exact ou digest ; aucun référencement flottant ne subsiste (Art. 11).

### Traçabilité critère → preuve

Une ligne par critère de succès, **une seule** tâche `[TEST]` de [`tasks.md`](./tasks.md) par ligne
(Art. 8). Les `Tn` de la fiche `9h` sont des **références de traçabilité**, jamais des preuves : une
tâche d'implémentation ne prouve aucun critère.

| Critère du document | Critère de succès | Preuve (tâche `[TEST]` de `tasks.md`) | Réf. de traçabilité (`9h`) |
| --- | --- | --- | --- |
| A1 — pre-commit bloque un fichier non conforme | SC-001 | T002 | T10 |
| A2 — CI rouge si couverture sous les seuils | SC-002 | T020 | T10 |
| A3 — moteur factice : flux, latence, erreurs | SC-003 | T015 | T10 |
| Consigne « la CI ne touche jamais un GPU » | SC-004 | T020 | T8, T9 |
| Hooks ≡ CI (Art. 14) | SC-005 | T003 | T3, T8 |
| Sécurité continue (Art. 21) | SC-006 | T020 | T8 |
| Environnement éphémère **entièrement détruit** | SC-007 | T021 | T9 |
| Definition of done mécanique (Art. 8) | SC-008 | T028 | T2, T8 |
| Topologie de fusion et garde des portes (Art. 23) | SC-009 | T003 | *aucune tâche de `9h`* — exigence **postérieure** au document |
| Porte 4 « e2e + charge » (Art. 8) · `9b` « e2e + k6 » | SC-010 | T021 | T9 |
| « Rien ne flotte », actions comprises (Art. 11) | SC-011 | T021 | T8 |

**SC-005 n'est pas prouvé par un test de parité** : T003 vérifie l'**absence de seconde déclaration**
des contrôles de rang 1 à 3. L'équivalence est obtenue par la définition unique des portes (FR-002,
FR-020) ; la constitution demande l'équivalence, pas un mécanisme de comparaison.

## Assumptions

- **Aucune dépendance de code** : S03 est parallélisable avec S01. Elle n'attend ni le socle de
  déploiement ni aucune fonctionnalité métier ; son étape de bout en bout consomme en revanche la
  définition d'environnement produite par S01 dès que celle-ci existe — tension avec `9c`, qui donne
  S03 « Dépend de : — », consignée en ARBITRAGE.
- **Deux versants outillés séparément** : le plan de contrôle et l'interface utilisateur ont chacun
  leur outillage de style, de typage et de tests ; les seuils et l'ordre des portes sont en revanche
  communs et définis une seule fois.
- **Le client d'interface est généré, jamais écrit à la main** : le contrat d'interface est la source
  unique dont le client est dérivé (Art. 19). Le **mécanisme** de génération et sa vérification
  relèvent de **S11** (`9p`, tâche T2 ; critère A1 « Client API 100 % généré (openapi-typescript) » ;
  jalon **M2** en `9e`), pas de S03 : `9b` est le catalogue partagé du socle et n'attribue ce point à
  aucune spec, tandis que `9h` ne met dans `ui/` que « eslint flat, prettier, vitest, playwright ». Le
  contrat lui-même est figé par S04.
- **Environnement d'exécution sans GPU** : la chaîne d'intégration s'exécute sur des machines
  dépourvues de GPU ; c'est une contrainte assumée, pas une limitation temporaire.
- **Revue humaine sur trois chemins** : l'Art. 8 nomme trois **chemins** — auth, facturation, proxy
  streaming — et non des specs. Toute spec qui touche l'un de ces chemins porte la revue humaine **en
  plus** des portes mécaniques ; `9d` en donne un cas explicite avec la revue humaine des permissions
  (S13). S03 fournit le **mécanisme** — la revue est une étape visible et tracée du processus, jamais
  une politesse — et ne fige **aucune liste de specs** : ce sont les specs concernées qui la
  déclenchent, chacune au titre du chemin qu'elle touche.
- **Journal des modifications généré** : la convention de nommage des validations permet de produire
  le journal automatiquement ; l'obligation de documenter tout changement de comportement visible
  relève de l'Art. 13 et s'applique à toutes les specs.
- **Seuils fixés par la constitution** : 90 % sur le cœur, 70 % ailleurs. Ces valeurs ne sont pas
  négociables spec par spec ; les modifier exige un amendement de la constitution.
- **Chaîne spécifiée indépendamment de son exécuteur** : le document ne nomme aucune plateforme
  d'hébergement du dépôt ni aucun exécuteur — `9b` ne versionne qu'« un `ci.yaml` » — et
  `specs/RESEARCH-STACK.md` est muet sur ce point (aucune de ses décisions D1–D6 ne couvre S03). Cette
  spec décrit donc les portes, leur ordre et leur effet sans désigner de plateforme, et le fichier de
  définition peut être nommé sans que sa plateforme le soit. Le choix est porté en ARBITRAGE.

## Arbitrages en attente *(ARBITRAGE — consignés ici, non tranchés)*

Ces points demandent une décision du mainteneur ; aucune source du projet ne permet de la prendre à
sa place (Art. 7). Ils sont consignés, jamais devinés. **Neuf** arbitrages sont ouverts et ce registre
les porte **tous** : `plan.md`, `tasks.md`, `research.md` et les contrats n'en rappellent que les
incidences, sans les dupliquer (Art. 19).

- **ARBITRAGE 1 — la forge et l'exécuteur de la chaîne.** Aucune source ne les désigne (voir
  l'hypothèse ci-dessus). **C'est l'arbitrage le plus urgent du lot** : l'Art. 23 fait de la livraison
  de S03 la condition de sortie du régime dégradé courant — « ni chaîne d'intégration, ni dépôt
  distant à ce jour » — et FR-029 comme FR-030 supposent une forge choisie (protections de branche,
  demandes de fusion, portes 4 et 5 qui n'existent qu'à distance). Tant qu'il n'est pas tranché, les
  portes s'exécutent en local et font foi.
- **ARBITRAGE 2 — `alembic check` : S03 ou S04 ?** `9b` place ce contrôle dans le socle partagé et
  FR-028 le porte à ce titre. Mais aucune migration n'existe à M0 — le schéma arrive avec S04 (`9c`,
  jalon M1) — de sorte que la porte s'exécuterait à vide. Deux lectures cohérentes : la poser dès M0
  avec le reste du socle (fidélité à `9b`, coût quasi nul), ou la reporter à S04 avec la première
  migration (fidélité à l'Art. 20).
- **ARBITRAGE 3 — le chemin du guide du contributeur.** FR-023 exige des commandes **documentées**, et
  cette documentation n'a **nulle part où vivre** : `10b` ne prévoit à la racine que
  `CONSTITUTION.md`, `CHANGELOG.md` (Keep a Changelog) et `runbooks/<incident>.md`, et ne fixe **aucun
  chemin** pour un guide de contribution. Aucun artefact n'en invente : la tâche correspondante de
  `tasks.md` porte le travail **sans chemin fixé**, et le `docs/CONTRIBUTING.md` d'une version
  antérieure y est consigné comme invention d'implémentation retirée. Une exigence dont le livrable n'a
  pas d'emplacement normatif reste donc en attente : à normaliser par amendement de `10b`, ou à
  rattacher à un chemin déjà prévu.
- **ARBITRAGE 4 — FR-017 et la dépendance à S01.** L'étape de bout en bout consomme un environnement
  éphémère complet, c'est-à-dire la définition de déploiement produite par S01, alors que `9c` donne
  S03 « Dépend de : — » et que les deux specs sont annoncées parallélisables. Soit la dépendance est
  reconnue et l'ordonnancement de la phase 1 le dit, soit S03 porte sa propre définition
  d'environnement de test — ce qui créerait deux sources pour une même connaissance (Art. 19).
- **ARBITRAGE 5 — amendement de `10a` si les portes doivent devenir des entités.** Porte, seuil et
  étape ont été retirés des Key Entities : l'arbre de la méthode de `10a` s'arrête à `Tâche Tn` et
  l'Art. 17 interdit de faire naître un concept dans le code avant la taxonomie. Si le projet veut les
  modéliser, `10a` doit être amendé d'abord.
- **ARBITRAGE 6 — `10a` annonce « Constitution (22 articles) ».** La constitution ratifiée en compte
  **23**, et c'est précisément l'Art. 23 — postérieur au document — dont FR-029 et FR-030 portent
  désormais les exigences. Écart documentaire à corriger par amendement (Art. 7, Art. 13) ; aucun
  artefact ne doit recopier le chiffre 22.
- **ARBITRAGE 7 — écart d'effort : 10.0 j-agent contre « ≈ 6.5 j-agent ».** La fiche `9h` porte
  « Total ≈ 6.5 j-agent » et `9c` « ≈ 1 sem », quand le découpage en tâches somme à 10.0 j.
  L'écart de **+3.5 j** est intégralement imputable à des exigences **postérieures ou latérales** à la
  fiche ; sa réconciliation chiffrée, tâche par tâche, vit dans [`tasks.md`](./tasks.md) (Art. 19). Le
  mainteneur doit trancher : amender `9h` et `9c`, ou réduire le périmètre — la profondeur M0 ne bouge
  pas (Art. 7, Art. 20).
- **ARBITRAGE 8 — `10b` fixe « tâches : `S<nn>-T<n>` ».** Les identifiants de tâches employés par le
  projet sont au format Spec Kit (`T001`…), qui prévaut — précédent de l'Art. 23, qui a déjà fait
  prévaloir le nommage `NNN-slug` sur le `feat/S09-catalog-fit` de `10b`. Les `Tn` de `9h` ne sont
  cités qu'en **référence de traçabilité**. Écart documentaire à corriger par amendement de `10b`
  (Art. 7, Art. 12).
- **ARBITRAGE 9 — `10c` ne tranche pas le terme désignant la référence exacte d'une image.** Le
  glossaire normatif n'en porte **aucune** entrée, alors que trois specs du même socle devaient le
  nommer : S01 et S02 écrivaient `digest`, S03 écrivait « empreinte » — deux mots pour une même chose,
  ce que l'Art. 12 interdit. Le terme retenu est **`digest`**, parce qu'il est celui de la
  **constitution** (Art. 11 : « épinglée sur un tag exact ou un **digest** ») et celui du document
  (`9f` T10 : « ports · digests ») ; « empreinte » est retiré des artefacts de S03. **Le nom de
  fichier `deploy/digests.yml` de S01 reste inchangé** : un nom de fichier n'est pas un terme de
  glossaire. Écart documentaire à corriger par amendement de `10c` (ajout de l'entrée) ; d'ici là,
  aucun artefact n'introduit de synonyme.
