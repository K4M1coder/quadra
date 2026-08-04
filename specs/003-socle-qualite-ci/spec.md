# Feature Specification: S03 — Socle qualité & CI

**Feature Branch**: `003-socle-qualite-ci`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9h du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S03 du plan de specs 9c : « Socle qualité & CI : lint, types, tests, moteur factice, pipeline », référence 9b, sans dépendance, effort ≈ 6.5 j-agent, phase 1 (socle), jalon produit M0 (Alpha).

## User Scenarios & Testing *(mandatory)*

Les parcours ci-dessous reprennent les jalons internes J1–J3 de la fiche 9h, par profondeur
croissante. Les « utilisateurs » de cette spec sont les contributeurs du projet — développeur humain,
agent IA implémentant une tâche, et mainteneur — puisque la feature livrée est la **chaîne de
contrôle** qui rend la definition of done mécanique (Art. 8).

### User Story 1 - Fondations : les portes locales refusent le non conforme (Priority: P1)

Un contributeur — humain ou agent — tente de valider un changement mal formaté, mal typé, ou
contenant un secret en dur. Les portes locales le refusent immédiatement, avant tout envoi, avec un
message qui nomme le problème et le fichier.

**Why this priority**: c'est la profondeur J1 et la condition d'existence de toutes les autres
specs. L'Art. 14 exige que « les hooks locaux exécutent exactement les portes de la CI » — sans J1,
aucun contributeur ne peut prédire une CI verte, et la délégation des tâches aux agents IA (Art. 8)
devient impossible faute de critère mécanique.

**Independent Test**: sur un dépôt fraîchement cloné, tenter de valider successivement un fichier
mal formaté, un fichier mal typé et un fichier contenant un secret en dur, puis constater que chaque
tentative est refusée avec un message actionnable — sans qu'aucune chaîne d'intégration distante
existe encore.

**Acceptance Scenarios**:

1. **Given** un dépôt configuré, **When** un contributeur tente de valider un fichier qui viole les
   règles de formatage ou de style, **Then** la validation est **refusée** et le message nomme le
   fichier et la règle enfreinte.
2. **Given** un dépôt configuré, **When** un contributeur tente de valider du code du plan de
   contrôle dont le typage est incomplet ou incorrect, **Then** la validation est refusée : le typage
   strict est exigé sur le plan de contrôle.
3. **Given** un dépôt configuré, **When** un contributeur tente de valider un fichier contenant un
   secret en clair, **Then** la validation est refusée avant tout envoi (Art. 21).
4. **Given** un dépôt configuré, **When** un contributeur rédige un message de validation qui ne
   respecte pas la convention de nommage des commits, **Then** la validation est refusée.
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
parcours de bout en bout sur un environnement éphémère — et refuse la fusion si une seule porte est
rouge.

**Why this priority**: c'est la profondeur J3, qui transforme les portes locales en garantie
collective. Elle est vérifiable seule dès que J1 et J2 existent, et elle rend applicable l'Art. 16
(« une porte rouge arrête le fil »).

**Independent Test**: soumettre successivement un changement conforme, un changement dont la
couverture passe sous le seuil, et un changement introduisant une dépendance vulnérable — et
constater que seule la première soumission est acceptée.

**Acceptance Scenarios**:

1. **Given** un changement conforme, **When** la chaîne d'intégration s'exécute, **Then** elle
   franchit les portes **dans l'ordre** : style et formatage → typage → tests et couverture →
   contrôles de sécurité → construction des images → parcours de bout en bout.
2. **Given** un changement qui fait passer la couverture du cœur (authentification, quotas,
   comptabilité) **sous 90 %**, **When** la chaîne s'exécute, **Then** elle échoue et la fusion est
   bloquée.
3. **Given** un changement qui fait passer la couverture hors cœur **sous 70 %**, **When** la chaîne
   s'exécute, **Then** elle échoue et la fusion est bloquée.
4. **Given** la chaîne d'intégration, **When** elle exécute l'intégralité de ses étapes, **Then**
   **aucune** d'entre elles n'accède à un GPU : l'environnement d'exécution n'en comporte pas.
5. **Given** l'étape de bout en bout, **When** elle démarre, **Then** elle s'appuie sur un
   environnement éphémère complet, associé au moteur factice, détruit à la fin de l'exécution.
6. **Given** un changement introduisant une dépendance affectée par une vulnérabilité connue,
   **When** la chaîne s'exécute, **Then** elle échoue et nomme la dépendance concernée.
7. **Given** une porte rouge, **When** un contributeur tente de la désactiver pour faire passer son
   changement, **Then** cela constitue une faute de gouvernance et non une mitigation : la
   configuration des portes est versionnée et sa modification est visible en revue (Art. 14).

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

#### Portes locales (J1)

- **FR-001**: Le projet DOIT fournir des portes de validation locales exécutées avant tout envoi,
  couvrant le formatage, le style, le typage et la détection de secrets en clair.
- **FR-002**: Les portes locales DOIVENT exécuter **exactement** les mêmes contrôles que la chaîne
  d'intégration distante, afin qu'un état vert en local prédise un état vert à distance (Art. 14).
- **FR-003**: Le typage DOIT être vérifié en mode strict sur le plan de contrôle et sur l'interface.
- **FR-004**: Les messages de validation DOIVENT respecter une convention de nommage vérifiée
  mécaniquement, permettant la génération automatique du journal des modifications.
- **FR-005**: Les portes DOIVENT s'appliquer aux **deux versants** du projet — plan de contrôle et
  interface utilisateur — avec l'outillage propre à chacun.
- **FR-006**: Tout refus DOIT nommer le fichier et la règle enfreinte, de façon actionnable sans
  consultation d'une documentation externe.

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
  en bout.
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
  sémantique et empreinte du contenu), pour rendre le retour arrière possible par simple
  ré-étiquetage (Art. 11).
- **FR-020**: Toute la configuration des portes DOIT être **versionnée dans le dépôt**, de sorte que
  la désactivation d'une porte soit visible en revue.

#### Pyramide de tests et definition of done (transverse, Art. 10)

- **FR-021**: Le socle DOIT rendre exécutables tous les niveaux de la pyramide de tests exigée par le
  projet : unitaires, intégration sur bases éphémères, contrat, bout en bout, charge, sécurité,
  fichiers de référence, tests générés depuis une source unique, et résilience.
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
  fournit la source de vérité).
- Les scénarios de charge métier et le runbook d'incidents → **S21** (S03 rend l'étape de charge
  exécutable, S21 versionne les scénarios).
- Le déploiement canari sur GPU et la bascule → workflow d'exploitation, hors chaîne d'intégration.
- Le démarrage de la pile de production et son exposition réseau → **S01**.
- La collecte de métriques et les tableaux de bord → **S02**.

### Key Entities

- **Porte de qualité** : contrôle mécanique franchi ou non. Attributs : nom, versant concerné (plan
  de contrôle / interface / transverse), rang dans l'ordre d'exécution, caractère bloquant.
- **Moteur factice** : simulateur du contrat d'inférence. Attributs paramétrables : latence du
  premier jeton, latence inter-jetons, erreur injectée, capacités exposées (complétion en flux,
  représentations vectorielles).
- **Seuil de couverture** : valeur plancher associée à un périmètre de code (cœur / hors cœur),
  bloquante en cas de dépassement par le bas.
- **Étape de chaîne** : maillon ordonné de la chaîne d'intégration, avec sa condition de réussite et
  son effet sur la fusion. Rattachée à l'arbre de la méthode de la taxonomie (Constitution → Spec →
  Plan → Jalon → Tâche).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Une tentative de validation d'un fichier non conforme
  (formatage, style, typage ou secret en clair) est **refusée dans 100 % des cas**, avec un message
  nommant le fichier et la règle.
- **SC-002** *(critère A2)*: Un changement faisant passer la couverture du cœur sous **90 %**, ou la
  couverture hors cœur sous **70 %**, fait échouer la chaîne d'intégration et **bloque la fusion**.
- **SC-003** *(critère A3)*: Le moteur factice reproduit, **sur une machine sans GPU**, une réponse
  en flux jeton par jeton, une latence imposée respectée, et une erreur injectée conforme à celle
  demandée.
- **SC-004**: **100 %** des étapes de la chaîne d'intégration s'exécutent sans accéder à un GPU.
- **SC-005**: Un état vert des portes locales prédit un état vert de la chaîne distante : les deux
  exécutent le **même ensemble** de contrôles, vérifié par comparaison automatisée.
- **SC-006**: Un changement introduisant une dépendance affectée par une vulnérabilité connue fait
  échouer la chaîne et **nomme** la dépendance concernée.
- **SC-007**: L'environnement éphémère de bout en bout est **entièrement détruit** après exécution :
  aucune ressource résiduelle ne subsiste entre deux exécutions.
- **SC-008**: Un contributeur — humain ou agent — peut déterminer si sa tâche est terminée **sans
  jugement humain**, à partir des seules sorties de l'outillage.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9h) |
| --- | --- | --- |
| A1 — pre-commit bloque un fichier non conforme | SC-001, SC-005 | T10 `[TEST]` le hook bloque |
| A2 — CI rouge si couverture sous les seuils | SC-002 | T10 `[TEST]` CI rouge sous seuil |
| A3 — moteur factice : flux, latence, erreurs | SC-003, SC-004 | T10 `[TEST]` scénarios du moteur factice |
| Consigne « la CI ne touche jamais un GPU » | SC-004, SC-007 | T9 étape de bout en bout sur environnement éphémère |
| Sécurité continue (Art. 21) | SC-006 | T8 chaîne : contrôles de sécurité |
| Definition of done mécanique (Art. 8) | SC-008 | T2 seuils bloquants · T8 chaîne complète |

## Assumptions

- **Aucune dépendance de code** : S03 est parallélisable avec S01. Elle n'attend ni le socle de
  déploiement ni aucune fonctionnalité métier ; son étape de bout en bout consomme en revanche la
  définition d'environnement produite par S01 dès que celle-ci existe.
- **Deux versants outillés séparément** : le plan de contrôle et l'interface utilisateur ont chacun
  leur outillage de style, de typage et de tests ; les seuils et l'ordre des portes sont en revanche
  communs et définis une seule fois.
- **Le client d'interface est généré, jamais écrit à la main** : le contrat d'interface est la source
  unique dont le client est dérivé (Art. 19). S03 pose le mécanisme de génération et sa vérification ;
  le contrat lui-même est figé par S04.
- **Environnement d'exécution sans GPU** : la chaîne d'intégration s'exécute sur des machines
  dépourvues de GPU ; c'est une contrainte assumée, pas une limitation temporaire.
- **Revue humaine sur trois chemins** : l'authentification, la facturation et le relais de flux
  exigent une revue humaine **en plus** des portes mécaniques. S03 rend cette exigence visible dans
  le processus ; ce sont les specs concernées (S04, S08) qui la déclenchent.
- **Journal des modifications généré** : la convention de nommage des validations permet de produire
  le journal automatiquement ; l'obligation de documenter tout changement de comportement visible
  relève de l'Art. 13 et s'applique à toutes les specs.
- **Seuils fixés par la constitution** : 90 % sur le cœur, 70 % ailleurs. Ces valeurs ne sont pas
  négociables spec par spec ; les modifier exige un amendement de la constitution.
