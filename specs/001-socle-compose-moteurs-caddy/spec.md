# Feature Specification: S01 — Socle compose + moteurs + Caddy

**Feature Branch**: `001-socle-compose-moteurs-caddy`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9f du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S01 du plan de specs 9c : « Socle compose + moteurs + Caddy », références 5b · W10 · scénario B, sans dépendance, effort ≈ 5.5 j-agent, phase 1 (socle), jalon produit M0 (Alpha).

## User Scenarios & Testing *(mandatory)*

Les trois parcours ci-dessous reprennent les jalons internes J1–J3 de la fiche 9f. Ils sont ordonnés
par profondeur croissante : chaque jalon est une tranche livrable et vérifiable seule, et la
profondeur du jalon produit M0 exige les trois.

### User Story 1 - Fondations : le dépôt cloné démarre ses bases (Priority: P1)

Un développeur qui rejoint le projet clone le dépôt, trouve une arborescence lisible et une
documentation d'amorçage, et démarre les deux bases de données (relationnelle et cache) sans
connaître le reste de la plateforme.

**Why this priority**: c'est la profondeur J1 de la fiche 9f. Sans arborescence stable ni bases
démarrables, aucune autre spec ne peut se poser : S03 (qualité & CI) et S04 (gateway) prennent leur
point d'appui ici. C'est aussi la seule tranche qui ne dépend d'aucun GPU, donc la seule vérifiable
sur n'importe quelle machine de développement.

**Independent Test**: cloner le dépôt sur une machine vierge sans GPU, lancer la cible de démarrage
des bases, et constater que la base relationnelle et le cache répondent à leur sonde de santé — sans
qu'aucun moteur d'inférence soit requis.

**Acceptance Scenarios**:

1. **Given** une machine vierge disposant seulement du moteur de conteneurs, **When** le développeur
   clone le dépôt et consulte le README racine, **Then** il identifie sans ambiguïté le rôle de
   chaque répertoire de premier niveau (`gateway/`, `ui/`, `deploy/`, `docs/`) et trouve à la racine
   `CONSTITUTION.md` — la constitution qui gouverne tout travail sur le dépôt — et `CHANGELOG.md`.
2. **Given** le dépôt cloné, **When** le développeur démarre les services de données, **Then** la
   base relationnelle et le cache atteignent l'état sain et leurs données persistent dans des
   volumes nommés.
3. **Given** les bases démarrées puis arrêtées et redémarrées, **When** le développeur relance la
   pile, **Then** les données écrites avant l'arrêt sont toujours présentes.

---

### User Story 2 - Cœur : une commande démarre moteurs, observabilité et TLS (Priority: P2)

L'administrateur exécute une commande unique sur la machine GPU et obtient la plateforme complète :
le reverse proxy termine le TLS et publie les routes, les moteurs d'inférence tournent sur leurs
GPUs, la chaîne d'observabilité collecte et affiche.

**Why this priority**: c'est la profondeur J2, le cœur de la valeur de S01 et la promesse du jalon
M0 (« stack verte sur machine vierge »). Elle est vérifiable seule dès que J1 existe.

**Independent Test**: sur la machine de référence à 4 GPUs, exécuter la commande de démarrage unique
et constater que tous les services atteignent l'état sain, que le point d'entrée TLS répond, et
qu'aucun port de moteur n'est joignable depuis l'extérieur du réseau interne `quadra-net`.

**Acceptance Scenarios**:

1. **Given** une machine vierge conforme au matériel de référence, **When** l'administrateur exécute
   la commande de démarrage unique, **Then** l'ensemble des services atteint l'état sain en moins de
   5 minutes.
2. **Given** la pile démarrée, **When** un client externe tente de joindre directement un moteur
   d'inférence sur son port, **Then** la connexion échoue — parmi les services de la pile, le port
   TLS 443 de `caddy` est le seul qui sorte du réseau `quadra-net` (réf. `5b` § Sécurité, qui place
   à côté de lui le seul autre accès sortant de l'hôte, SSH, hors périmètre de la pile).
3. **Given** la pile démarrée, **When** un client interroge les routes publiées `/v1` (inférence),
   `/api` (administration), `/ws` (temps réel) et `/grafana` (tableaux de bord), **Then** le reverse
   proxy les achemine vers le bon service avec un certificat TLS valide.
4. **Given** un service qui échoue au démarrage, **When** sa sonde de santé reste rouge, **Then** les
   services qui en dépendent ne sont pas déclarés sains et le service est redémarré selon sa
   politique de redémarrage.
5. **Given** la machine qui redémarre, **When** le système revient, **Then** la pile se relance
   automatiquement et retrouve l'état sain sans intervention.

---

### User Story 3 - Surface : configuration par fichier d'environnement et installation documentée (Priority: P3)

L'administrateur configure l'installation par un unique fichier d'environnement dont chaque variable
est documentée, et suit une procédure d'installation écrite qui l'amène de la machine vierge à la
pile saine.

**Why this priority**: c'est la profondeur J3. Elle ne change pas ce que fait la plateforme mais
rend l'installation reproductible par quelqu'un d'autre que l'auteur — exigence de l'Art. 9
(opérable par un seul) et condition de la preuve J4 sur machine vierge.

**Independent Test**: donner à une personne n'ayant jamais vu le projet la documentation
d'installation et une copie du fichier d'environnement d'exemple, et constater qu'elle atteint la
pile saine sans poser de question.

**Acceptance Scenarios**:

1. **Given** le dépôt cloné, **When** l'administrateur copie `.env.example` en `.env`, **Then**
   chaque variable requise y figure — nommée en UPPER_SNAKE et préfixée `QUADRA_` (convention `10b`)
   — avec sa description et, quand elle existe, sa valeur par défaut.
2. **Given** un fichier d'environnement auquel il manque une variable requise ou dont une valeur est
   invalide, **When** l'administrateur démarre la pile, **Then** le démarrage s'interrompt
   immédiatement avec un message nommant la variable fautive et la correction attendue — la pile ne
   démarre jamais à moitié configurée.
3. **Given** la documentation d'installation, **When** un opérateur la suit pas à pas sur une machine
   vierge, **Then** il obtient une pile saine sans recourir à une connaissance non écrite.
4. **Given** la pile en fonctionnement, **When** l'administrateur veut l'arrêter, consulter les
   journaux ou lister l'état des services, **Then** une cible de commande dédiée existe pour chacune
   de ces opérations.

---

### Edge Cases

- **Un digest d'image épinglé n'est plus disponible au registre** : le démarrage échoue en nommant
  l'image et son digest attendu ; aucune substitution automatique par une version plus récente n'est
  tentée (Art. 11).
- **Une image épinglée se révèle défaillante après bascule** : le retour arrière consiste à re-pointer
  le digest précédent puis à redémarrer, en une commande — pas de reconstruction, pas d'autre fichier
  touché (réf. `w10` ; Art. 9, Art. 11).
- **Une sonde de santé ne devient jamais verte dans le délai imparti** : le service est marqué en
  échec et la commande de démarrage rend la main avec un état non nul, plutôt que d'attendre
  indéfiniment.
- **Un moteur d'inférence se termine anormalement pendant que la pile tourne** : sa politique de
  redémarrage le relance ; le reste de la pile n'est pas interrompu.
- **La machine redémarre pendant un arrêt propre** : au retour, la pile se relance et les volumes
  nommés sont intacts.

## Requirements *(mandatory)*

### Functional Requirements

*Les identifiants FR sont stables : les exigences ajoutées par amendement (FR-019 à FR-021) sont
placées dans leur section thématique **sans renumérotation** des exigences existantes, que les
artefacts dépendants référencent par identifiant (Art. 19).*

#### Arborescence et amorçage (J1)

- **FR-001**: Le dépôt DOIT présenter une arborescence de premier niveau stable séparant le plan de
  contrôle (`gateway/`), l'interface utilisateur (`ui/`), les artefacts de déploiement (`deploy/`) et
  la documentation (`docs/`).
- **FR-002**: Le dépôt DOIT fournir un README racine décrivant le rôle de chaque répertoire de
  premier niveau et la commande d'amorçage.
- **FR-019**: Le dépôt DOIT porter à sa racine `CONSTITUTION.md`, copie de référence de la
  constitution ratifiée — dont `.specify/memory/constitution.md` est la source (Art. 19) — destinée
  à être injectée dans le contexte de chaque agent avant tout travail. Les deux copies DOIVENT
  porter la même version.
- **FR-020**: Le dépôt DOIT porter à sa racine `CHANGELOG.md` au format Keep a Changelog et versionné
  en SemVer (Art. 13, convention `10b`), et le changement qui livre S01 DOIT y figurer.
- **FR-003**: Le système DOIT fournir une base de données relationnelle et un cache démarrables
  indépendamment des moteurs d'inférence, chacun avec sa sonde de santé.
- **FR-004**: Toute donnée persistante DOIT être stockée dans des volumes nommés, distincts par
  usage (`pgdata` pour les données relationnelles, `promdata` pour les données de métriques,
  `/data/models` pour les modèles, `/data/offload` pour l'offload), et survivre à l'arrêt et au
  redémarrage de la pile.

#### Démarrage unifié et exposition réseau (J2)

- **FR-005**: Le système DOIT démarrer l'intégralité de la pile — reverse proxy, moteurs d'inférence,
  bases, chaîne d'observabilité — au moyen d'une commande unique.
- **FR-006**: Le système NE DOIT publier vers l'extérieur que le port TLS 443. Aucun port de moteur
  d'inférence, de base de données, de cache ou de composant d'observabilité NE DOIT être publié sur
  l'hôte.
- **FR-007**: Les moteurs d'inférence DOIVENT être joignables uniquement depuis le réseau interne
  `quadra-net` ; ils n'exposent ni authentification ni TLS et ne doivent donc jamais être atteignables
  hors de ce réseau.
- **FR-008**: Le reverse proxy DOIT obtenir et renouveler automatiquement son certificat TLS, et
  acheminer les routes publiées `/v1` (inférence), `/api` (administration), `/ws` (temps réel) et
  `/grafana` (tableaux de bord) vers les services correspondants.
- **FR-009**: Chaque service DOIT déclarer une sonde de santé, et les services dépendants NE DOIVENT
  être considérés comme démarrés qu'une fois leurs dépendances saines.
- **FR-010**: Chaque service DOIT déclarer une politique de redémarrage assurant la reprise
  automatique après défaillance du service ou redémarrage de la machine.
- **FR-011**: La chaîne d'observabilité DOIT être démarrée par la même commande que le reste de la
  pile — collecte des métriques, routage des alertes, tableaux de bord et exportateur de métriques
  GPU.

#### Épinglage et reproductibilité (transverse, Art. 11)

- **FR-012**: Toute image de conteneur utilisée DOIT être référencée par un digest exact. Aucune
  référence mouvante (marqueur `latest`, nom de branche, intervalle de versions ouvert) N'EST
  autorisée.
- **FR-013**: Le démarrage DOIT échouer explicitement si une image référencée n'est pas disponible
  au digest attendu, sans jamais substituer une autre version.
- **FR-021**: Le retour arrière d'un service de la pile DOIT s'obtenir en re-pointant, dans le fichier
  de digests du dépôt, le digest précédemment épinglé, puis en redémarrant le service par **une seule
  commande** — sans reconstruction d'image, sans modification d'aucun autre fichier, et sans
  substitution d'une version autre que celle précédemment épinglée (réf. `w10` ; Art. 9, Art. 11 —
  l'épinglage est la condition du retour arrière). La version effectivement en service DOIT être
  lisible depuis la définition de déploiement ; son affichage dans une vue de santé (`6g`) relève de
  S21.

#### Configuration et exploitation (J3)

- **FR-014**: Le système DOIT être configurable par un unique fichier d'environnement `.env`,
  accompagné d'un `.env.example` exhaustif documentant chaque variable, son rôle et sa valeur par
  défaut quand elle existe. Toute variable de configuration DOIT être nommée en UPPER_SNAKE et
  préfixée `QUADRA_` (convention `10b`) ; aucun autre espace de noms N'EST autorisé pour les
  variables propres à la plateforme.
- **FR-015**: Le système DOIT valider la configuration au démarrage et interrompre celui-ci avec un
  message nommant la variable fautive et la correction attendue lorsqu'une variable requise est
  absente ou invalide.
- **FR-016**: Le système DOIT fournir des commandes dédiées pour démarrer, arrêter, consulter les
  journaux et lister l'état des services.
- **FR-017**: La documentation d'installation DOIT permettre à un opérateur n'ayant pas participé au
  développement d'aller de la machine vierge à la pile saine sans connaissance implicite.

#### Preuves (J4)

- **FR-018**: Le système DOIT être vérifiable par une procédure automatisée exécutée sur une machine
  vierge, prouvant simultanément le délai de démarrage, l'exposition réseau et l'épinglage des
  versions.

### Hors périmètre *(Art. 20 — YAGNI)*

Les éléments suivants sont explicitement exclus de S01 et appartiennent à d'autres specs. Aucun
d'eux NE DOIT être anticipé ici :

- Authentification, clés d'API, quotas et budgets → S04, S08.
- Ordonnancement par lane et caps de concurrence → S05.
- Pilotage du cycle de vie des moteurs, création de nœuds GPU, hot-swap → S06, S07.
- Contenu des tableaux de bord, règles d'alerte et rétention des métriques → S02.
- Chaîne de qualité et intégration continue → S03.
- Toute interface web d'administration → S11.
- Tout mécanisme multi-machines (worker, join, réplication) → S19, S20.

### Key Entities

Cette spec ne crée aucune entité du domaine métier ; elle fixe des objets de déploiement, rattachés
à l'arbre d'exécution de la taxonomie (Cluster → Host → Node → Engine → Instance).

- **Service de la pile** : unité déployable du socle (reverse proxy, moteur d'inférence, base
  relationnelle, cache, collecte de métriques, routage d'alertes, tableaux de bord, exportateur GPU).
  Attributs : image épinglée par digest, sonde de santé, politique de redémarrage, dépendances.
- **Volume nommé** : espace de stockage persistant distinct par usage — `/data/models`,
  `/data/offload` (opt-in, inutilisé par défaut), `pgdata`, `promdata`.
- **Route publiée** : correspondance entre un chemin exposé sur le point d'entrée TLS (`/v1`, `/api`,
  `/ws`, `/grafana`) et le service interne qui le sert.
- **Variable d'environnement** : paramètre de configuration nommé en UPPER_SNAKE préfixé `QUADRA_`,
  documenté dans `.env.example`, validé au démarrage.
- **Fichier de gouvernance à la racine** : `CONSTITUTION.md` (copie de référence de la constitution,
  même version que sa source) et `CHANGELOG.md` (Keep a Changelog + SemVer).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Sur une machine vierge conforme au matériel de référence,
  la commande de démarrage unique amène l'intégralité des services à l'état sain en **moins de
  5 minutes**, toutes sondes de santé vertes.
- **SC-002** *(critère A2)*: Depuis l'extérieur de la machine, **seul le port TLS 443 est
  joignable** ; un balayage des ports des moteurs d'inférence, bases, cache et composants
  d'observabilité ne trouve **aucun port publié**.
- **SC-003** *(critère A3)*: **100 % des images** de la pile sont référencées par un digest exact ;
  une inspection automatisée de la définition de déploiement ne trouve **aucune référence mouvante**.
- **SC-004**: Un opérateur n'ayant jamais vu le projet atteint la pile saine en suivant uniquement la
  documentation d'installation, **sans poser de question** au mainteneur.
- **SC-005**: Après un redémarrage de la machine, la pile retrouve l'état sain **sans intervention
  manuelle**.
- **SC-006**: Un démarrage avec une variable de configuration requise absente ou invalide **est
  refusé** : la validation interrompt le démarrage, **nomme la variable fautive** et la correction
  attendue, et **aucun service** n'est laissé démarré — la pile ne démarre jamais à moitié
  configurée.
- **SC-007**: Les données écrites dans les volumes nommés survivent à **100 %** des cycles
  arrêt/redémarrage de la pile.
- **SC-008**: Le dépôt cloné porte à sa racine `CONSTITUTION.md`, et la version qu'il déclare est
  **identique** à celle de sa source `.specify/memory/constitution.md` — une inspection automatisée
  compare les deux et échoue à la moindre divergence.
- **SC-009**: Le dépôt cloné porte à sa racine `CHANGELOG.md` au format Keep a Changelog, et
  l'entrée du changement qui livre S01 y figure (Art. 13).
- **SC-010**: Le retour arrière d'un service vers le digest précédemment épinglé s'obtient par **une
  seule commande** et la pile retrouve l'état sain, sans reconstruction d'image et sans modification
  d'aucun fichier autre que celui qui porte les digests.

### Traçabilité critère → preuve

Conformément à l'Art. 8 (chaque critère d'acceptation est prouvé par une tâche `[TEST]` tracée) et à
la fiche 9f :

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9f) |
| --- | --- | --- |
| A1 — pile saine en < 5 min, healthchecks verts | SC-001, SC-005, SC-007 | T10 `[TEST]` vierge → verte < 5 min |
| A2 — seul :443 exposé, moteurs invisibles | SC-002 | T10 `[TEST]` vérification des ports |
| A3 — toute version épinglée | SC-003 | T10 `[TEST]` vérification des digests |
| Exigences de surface (J3) | SC-004, SC-006 | T7 validation au boot · T9 documentation d'installation — **tâches d'implémentation, ce que l'Art. 8 interdit** : ce sont les **objets sous test**, pas la preuve. Les preuves sont les tâches `[TEST]` **T014** (démarrage refusé sur configuration invalide, SC-006) et **T015** (installation par un tiers, SC-004) de `tasks.md` — **écart documentaire, Art. 7**, amendement dû sur cette ligne et sur la fiche `9f` |
| Fichiers de gouvernance à la racine (`10b`, Art. 13, § Governance) | SC-008, SC-009 | tâche `[TEST]` de vérification des fichiers de racine — **aucune tâche de la fiche `9f` ne la porte** : à créer dans `tasks.md` (écart documentaire, Art. 7) |
| Retour arrière en une commande (réf. `w10`, contrat 4) | SC-010 | tâche `[TEST]` de retour arrière (J4) — la fiche `9f` ne détaille que T10 pour J4 : à créer dans `tasks.md` (écart documentaire, Art. 7) |

## Assumptions

- **Matériel de référence** : machine unique à 4 GPUs de 24 Go (RTX 3090), limite de puissance
  280 W, NVLink apparié 0↔1 et 2↔3, stockage NVMe dédié aux modèles. Le déploiement de référence de
  S01 est **single-node** ; le multi-machines relève de S19–S20.
- **Combinaison pilote/CUDA unique validée** : une seule combinaison pilote GPU / CUDA / toolkit
  conteneur est supportée et épinglée. C'est le risque identifié de la phase 1 ; toute autre
  combinaison est hors garantie.
- **Sortie réseau autorisée** : en entrée, le point d'entrée TLS ; **hors de l'infrastructure**, la
  seule sortie est **le téléchargement de modèles depuis Hugging Face** (plafonné) — et rien d'autre.
  Aucune télémétrie, jamais (Art. 1).
- **La copie de sauvegarde n'est pas une seconde sortie autorisée** : sa destination est **dans
  l'infrastructure** (le NAS du réseau local, à côté de `node-01`, réf. `5b`) — jamais hors site, ni
  vers un service en nuage ; elle ne quitte donc pas le périmètre que l'Art. 1 protège, et n'en
  élargit pas la portée. Conditions qui s'imposent à sa spécification : les `prompts` et les réponses
  sont **exclus du dump** ; `/data/models` est **exclu** (re-téléchargeable, `checksum` en base) ; le
  contenu est pseudonyme ; le **chiffrement au repos** est assuré sur la destination. La sauvegarde
  elle-même — planification, vérification, restauration — relève de S21 ; S01 ne fait que ne pas
  l'empêcher.
- **Pas d'orchestrateur** : le socle repose sur un déploiement par composition de conteneurs sur une
  machine ; aucun orchestrateur de cluster n'est introduit sous 3 machines (Art. 9).
- **L'offload est provisionné mais inactif** : le volume dédié existe, mais aucune fonctionnalité
  d'offload n'est activée par défaut — elle est opt-in par job et relève de S18 (Art. 3).
- **Les moteurs sont consommés tels quels** : les moteurs d'inférence upstream ne sont jamais
  modifiés ni forkés ; S01 se limite à les démarrer avec des versions épinglées (Art. 6).
- **Rétention des métriques** : la durée de rétention des données de métriques est fixée à 90 jours ;
  sa configuration effective relève de S02.
- **Dépendances** : aucune. S01 est la première spec du plan et le point d'appui de toutes les
  autres. Elle est complète au jalon produit M0.

### Arbitrages ouverts *(Art. 7 — consignés, non tranchés)*

Ces points ne sont pas décidables depuis les sources ; ils sont notés ici et n'engagent aucun critère
ci-dessus.

- **SSH sur la machine de référence** : `5b` § Sécurité place SSH à côté de `:443` parmi les accès qui
  sortent du réseau compose, sans dire s'il est publié sur la machine de référence. Un balayage
  externe y trouverait alors 443 **et** 22. SC-002 reste borné aux ports des services de la pile ; le
  statut de SSH, service de l'hôte, est à trancher par le mainteneur.
- **Version de `dcgm-exporter`** : FR-012 exige un digest exact pour **toute** image, y compris
  `dcgm-exporter`, mais la décision **D1** de `specs/RESEARCH-STACK.md` ne couvre pas ce composant
  (sa portée nomme Postgres, Redis, Grafana, Prometheus, Caddy, React). La version à épingler est à
  trancher.
- **Tag `llama.cpp b4102`** : `specs/RESEARCH-STACK.md` §1 le marque « à revérifier — vérifier la
  disponibilité du tag ». À vérifier avant l'épinglage, sous peine de rendre FR-013 vrai au premier
  démarrage.
