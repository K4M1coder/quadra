# Implementation Plan: S01 — Socle compose + moteurs + Caddy

**Branch**: `001-socle-compose-moteurs-caddy` | **Date**: 2026-08-04 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-socle-compose-moteurs-caddy/spec.md`

**Cadrage** — fiche source `9f` · **phase 1** (socle : S01 · S02 · S03, `9c` et `9d`) · **jalon produit
M0 — Alpha**. `9e` exige « **S01 complet** » à M0 : la profondeur autorisée est donc **J1 → J4**, et
rien au-delà (Art. 7, Art. 20). `9c` donne S01 « **Dépend de : —** » : aucune étape, aucun artefact et
aucune ligne du Constitution Check ci-dessous n'est gagée sur une autre spec.

## Summary

Rendre l'infrastructure complète démarrable par **une commande unique** sur une machine vierge :
reverse proxy terminant le TLS et seul port publié, moteurs d'inférence épinglés par digest, bases de
données, chaîne d'observabilité. Le socle sur lequel les vingt autres specs se posent.

**Approche technique** : une composition de conteneurs unique décrit l'ensemble des services sur le
réseau interne isolé `quadra-net` ; seul le reverse proxy `caddy` publie un port sur l'hôte (443).
Toutes les images sont référencées par **digest** (Art. 11) dans un **fichier de digests unique**
(Art. 19) : c'est ce fichier, et lui seul, que le **retour arrière par ré-étiquetage** modifie —
re-pointer le digest précédemment épinglé puis redémarrer, en une commande, sans reconstruction
(FR-021, SC-010, réf. `w10`, prouvé en J4). L'épinglage n'est donc pas de l'hygiène : c'est la
condition du canari et du retour arrière. La configuration passe par un fichier d'environnement
unique, **validé au démarrage** de sorte qu'une pile mal configurée échoue avant qu'aucun service ne
soit démarré, plutôt que de démarrer à moitié.

**Point de vigilance principal** : le risque identifié de la phase 1 est la **combinaison
pilote GPU / CUDA / toolkit conteneur** — une seule est validée. Le plan la traite comme une
constante figée, pas comme une variable.

## Technical Context

**Language/Version** : aucun code applicatif dans S01. Les artefacts sont déclaratifs — composition de
conteneurs, configuration du reverse proxy, cibles de commandes, documentation. Le seul exécutable
est le **validateur de configuration au démarrage**, écrit dans le langage du plan de contrôle
(Python 3.12) pour être réutilisé par S04 plutôt que dupliqué (Art. 19).

**Primary Dependencies** — **versions retenues après décision D1** (voir ci-dessous). Toutes sont
épinglées **par digest** ; la colonne indique la version lisible correspondante.

| Rôle | Composant | **Version retenue** | Version du document (5a) | Licence (5a) |
| --- | --- | --- | --- | --- |
| Hôte | ubuntu-lts · docker · compose | 24.04 · 27 · v2 | idem | non attribuée par 5a |
| GPU | nvidia-driver · cuda · nvidia-ctk | **560 · 12.6** *(conservées, D2)* | idem | non attribuée par 5a |
| Moteur principal | sglang | 0.5.x | 0.5 | Apache-2.0 |
| Moteur format fichier unique | llama.cpp | b4102 *(tag à vérifier)* | idem | MIT |
| Reverse proxy | caddy | 2.11.x | 2 | Apache-2.0 |
| Base relationnelle | postgresql | **18.x** | ~~16~~ *périmé* | non attribuée par 5a |
| Cache | redis | **8.x** | ~~7~~ *périmé* | BSD |
| Métriques | prometheus + alertmanager | **3.x LTS** | ~~2~~ *périmé* | non attribuée par 5a |
| Visualisation | grafana | **13.x** | ~~11~~ *périmé* | AGPL-3 |
| Métriques GPU | dcgm-exporter | **à trancher** — voir *Arbitrages ouverts* | — | NVIDIA |

> **Aucune ligne de cette table n'est déduite.** Les licences reproduisent celles que `5a` attribue
> effectivement ; là où `5a` n'en attribue aucune (hôte, GPU, postgresql, prometheus + alertmanager),
> la case le dit au lieu d'en inventer une.
>
> **Quatre lignes de la table 5a du document sont périmées** (base relationnelle, cache, métriques,
> visualisation) — décision **D1**. Le fichier de digests du dépôt fait foi (Art. 19). Le couple
> pilote GPU / CUDA est en revanche **conservé** tel quel (décision **D2**).
>
> **`dcgm-exporter` n'a pas de version retenue et ne peut pas en recevoir une ici** : `5a` n'épingle
> aucune version, et la **portée de D1** (`RESEARCH-STACK.md` §7) nomme limitativement Postgres,
> Redis, Grafana, Prometheus, Caddy et React. Écrire « amont courant » serait ouvrir exactement
> l'intervalle ouvert que l'Art. 11 et FR-012 interdisent — dans le fichier même qui porte le critère
> A3. Le point est donc laissé en arbitrage, et **la définition de déploiement ne peut pas être
> complétée sans lui** (FR-012 vaut pour *toute* image).
>
> **La sauvegarde ne figure pas dans cette table** : `5a` la rattache à `w11` (« pg_dump + rsync
> (sauvegardes **W11**) ») et `9c` la porte dans S21, jalon M4. Aucune étape de S01 ne l'utilise ;
> l'inscrire en dépendance de S01 dépasserait le jalon M0 (Art. 20). S01 se borne à **ne pas
> l'empêcher** (hypothèse de `spec.md`).

**Storage** : quatre volumes nommés, distincts par usage — `/data/models` (NVMe, ~1,8 To),
`/data/offload` (~400 Go, **provisionné mais inactif** : `offload` opt-in par job, S18), `pgdata`,
`promdata` (rétention 90 j, configurée par S02). Graphie de `5b` et de FR-004, employée telle quelle
(Art. 12).

**Testing** — **régime local (Art. 23)**. `9c` donne S01 « Dépend de : — » : la preuve de S01 ne peut
pas être gagée sur un outillage que S03 n'a pas livré. Les portes (style, typage, tests, sécurité)
**s'exécutent localement et leur sortie capturée EST la definition of done**. La preuve principale est
une procédure automatisée sur **machine vierge** vérifiant simultanément le délai de démarrage,
l'exposition réseau et l'épinglage des digests (réf. `9f` T10). **Trois critères** supplémentaires sont
dus mais **absents de la fiche `9f`** — les fichiers de gouvernance à la racine (SC-008, SC-009) et le
retour arrière en une commande (SC-010) — et se prouvent par **deux** preuves à créer dans `tasks.md` :
une seule vérification couvre les deux fichiers de racine, une seconde couvre le retour arrière. Écart
documentaire consigné (Art. 7). Quand la chaîne de S03 existera, ces mêmes portes s'y exécuteront sans
être réécrites — c'est l'ordre que fixe l'Art. 23, pas une dépendance de S01 envers S03.

**Target Platform** : machine unique Linux avec 4 cartes GPU. **Pas d'orchestrateur de cluster**
(Art. 9). Le multi-machines relève de S19–S20 et n'est pas anticipé ici (Art. 20).

**Performance Goals** : **un seul seuil chiffré est sourcé** — pile saine en **moins de 5 minutes** sur
machine vierge (critère A1 de `9f`, SC-001). L'échec de validation de configuration n'a **pas** de
seuil : l'exigence est qualitative et vérifiable telle quelle — le démarrage s'interrompt, la variable
fautive et la correction attendue sont nommées, **aucun service n'est laissé démarré** (FR-015,
SC-006). Aucun chiffre n'est inventé ici.

**Constraints** :

- **Un seul port publié** sur l'hôte : le port TLS 443, celui de `caddy`. Aucun port de moteur, de
  base, de cache ou d'observabilité.
- **Aucune référence d'image mouvante** — digest exact obligatoire, jamais de marqueur flottant, jamais
  d'intervalle ouvert (Art. 11, FR-012).
- **Aucune sortie hors de l'infrastructure** hormis **le téléchargement de modèles** (plafonné) — et
  rien d'autre ; aucune télémétrie, jamais (Art. 1). La copie de sauvegarde **n'est pas une seconde
  sortie autorisée** : sa destination est **dans l'infrastructure** (le NAS du réseau local, à côté de
  `node-01`, réf. `5b`), elle ne quitte donc pas le périmètre que l'Art. 1 protège et n'en élargit pas
  la portée. Sa spécification relève de S21 ; S01 se borne à ne pas l'empêcher.
- Topologie matérielle de référence : 4 cartes de 24 Go, limite de puissance 280 W, appairage `NVLink`
  par paires 0↔1 et 2↔3.

**Scale/Scope** : 9 services conteneurisés (`caddy`, sglang, llama.cpp, postgres, redis, prometheus,
alertmanager, grafana, dcgm-exporter — énumération de `9f`), 4 volumes, 4 routes publiées (`/v1`,
`/api`, `/ws`, `/grafana`), 1 réseau interne `quadra-net`.

### Décisions issues de la veille — **arbitrées**

Référence et justification complète : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md), §7.

- **D1 — épingler l'amont actuel** (Postgres 18.x, Redis 8.x, Grafana 13.x, Prometheus 3.x LTS)
  plutôt que les versions du document. Aucun code n'existe : c'est le seul moment où la montée est
  gratuite. L'Art. 11 exige des versions **figées**, pas anciennes. **La table de dépendances 5a du
  document est périmée sur ces quatre lignes** ; le fichier de digests du dépôt fait foi (Art. 19).
- **D2 — conserver le pilote GPU et CUDA du document** (560 / 12.6). Le couple pilote/CUDA est le
  seul élément de la pile qu'on **ne peut pas valider en intégration continue** (Art. 8 : la CI ne
  touche jamais un GPU) ; ce qu'on ne peut pas tester, on ne le change pas sans banc. Révision au
  canari uniquement.

D1 et D2 ne se contredisent pas : les composants de D1 sont interchangeables derrière des interfaces
stables et testables sans GPU ; le couple pilote/CUDA ne l'est pas.

**Décisions qui ne couvrent pas S01** : D3 et D4 (tenue mémoire) relèvent de S09, D5 de S16, D6 de S04
et S18. Aucune ne s'applique ici. La veille n'est pas recopiée : `specs/RESEARCH-STACK.md` en est la
source unique (Art. 19, Art. 22).

### Arbitrages ouverts *(Art. 7 — consignés, non tranchés)*

`spec.md` § « Arbitrages ouverts » en est la source ; seuls les effets **sur ce plan** sont notés ici,
sans les redupliquer (Art. 19).

| Point | Effet sur le plan |
| --- | --- |
| **Version de `dcgm-exporter`** — non épinglée par `5a`, hors portée de D1 | Le fichier de digests reste **incomplet** ; la ligne de service `dcgm-exporter` de `docker-compose.yml` ne peut pas être écrite sans violer FR-012. Bloque la clôture de J2. |
| **Tag `llama.cpp b4102`** — « à revérifier » (`RESEARCH-STACK.md` §1) | À vérifier **avant** l'épinglage, faute de quoi FR-013 devient vrai au premier démarrage et A1 échoue pour une cause documentaire. |
| **SSH sur la machine de référence** (`5b` § Sécurité) | Ne change pas le plan : SC-002 et le contrat 1 sont bornés aux **ports des services de la pile**. Le statut d'un service de l'hôte est hors périmètre de S01. |

**Écarts documentaires dus (Art. 7, Art. 12)** — signalés, jamais reproduits : `10a` annonce une
« Constitution (22 articles) » alors que la version ratifiée en compte **23** ; `10b` fixe
`specs/S<nn>-<slug>.md`, `plans/S<nn>.md` et `S<nn>-T<n>` alors que l'Art. 23 a déjà fait prévaloir le
nommage Spec Kit `NNN-slug` — cette spec vit donc sous `specs/001-socle-compose-moteurs-caddy/` ;
`9f` énumère `caddy` parmi les services de `docker-compose.yml` mais ne nomme que le `Caddyfile` dans
ses tâches ; `9f` ne porte aucune tâche pour les fichiers de gouvernance à la racine ni pour le retour
arrière, que `10b`, l'Art. 13, le § Governance et `w10` exigent pourtant.

## Constitution Check

*GATE : à franchir avant la génération des tâches. Ré-évalué après la conception détaillée.*

Les 23 articles de la constitution v1.1.0 sont évalués, Art. 23 inclus (`10a` annonce 22 articles :
écart documentaire, voir *Arbitrages ouverts*). Légende : ✅ conforme · ➖ sans objet au périmètre de
S01 · ⚠️ **réserve explicite** — la ligne n'est pas verte et dit pourquoi. Aucune ligne n'est gagée sur
une spec non livrée : `9c` donne S01 « Dépend de : — » et l'Art. 23 impose que ce qui n'existe pas
encore s'exécute **en local**, sa sortie capturée faisant foi.

| Art. | Exigence | Statut | Comment S01 s'y conforme |
| --- | --- | --- | --- |
| 1 | Données sur site | ✅ | Seul flux entrant : le port TLS 443 de `caddy`. **Hors de l'infrastructure, une seule sortie** : le téléchargement de modèles (plafonné, S10). Aucune télémétrie, jamais. La copie de sauvegarde n'est pas une seconde sortie autorisée — sa destination est **dans l'infrastructure** (NAS du réseau local, `5b`) et n'élargit donc pas la portée de l'article. Vérifié par SC-002 (aucun port publié hors 443) et par le contrat 3 de `contracts/routes.md`. |
| 2 | Humain interactif d'abord | ➖ | Aucun ordonnancement dans S01 : les `lane P0/P1/P2` relèvent de S05. Le socle ne préempte rien et n'introduit aucune tâche de fond. |
| 3 | Consentement explicite | ✅ | `/data/offload` est **provisionné mais monté par aucun moteur** : aucune activation implicite de l'`offload`, qui reste opt-in par job (S18). Aucune autre action coûteuse ou irréversible dans S01. |
| 4 | Tout est tracé | ➖ | Le journal d'audit arrive en S13 ; S01 n'exécute aucune action sensible et ne mesure aucune requête. Ce dont il doit rendre compte — l'état de chaque service — l'est par les sondes de santé (FR-009). |
| 5 | Le serveur décide | ➖ | Aucune permission, aucun rôle, aucune UI dans S01. La contrepartie qui s'applique déjà — aucun secret en clair — est portée par la ligne 21. |
| 6 | Réutiliser, ne jamais forker | ✅ | Moteurs et briques consommés **tels quels**, uniquement démarrés ; aucun correctif amont, aucune image construite localement (`research.md` D-S01-2). Les moteurs n'exposant ni authentification ni TLS est une propriété de l'amont, corrigée par l'isolation réseau, pas par un fork. |
| 7 | La spec avant le code | ✅ | `spec.md` figée et validée (`checklists/requirements.md`) avant ce plan. Profondeur bornée à M0 = « S01 complet » (`9e`) ; aucune étape au-delà de J4. Les écarts découverts sont remontés en *Arbitrages ouverts* au lieu d'être absorbés. |
| 8 | Qualité mécanique | ✅ | **Régime local (Art. 23)** : les portes 1 à 3 s'exécutent localement, leur sortie capturée EST la definition of done ; les portes 4 et 5, qui n'existent qu'à distance, ne gardent que la promotion de `test` et ne conditionnent aucune étape de S01. Chaque critère d'acceptation est prouvé par une tâche `[TEST]` : A1–A3 par la preuve machine vierge (réf. `9f` T10), SC-008/SC-009 et SC-010 par deux preuves **absentes de `9f`**, à créer dans `tasks.md` (écart consigné, Art. 7). **SC-004 et SC-006 sont dans le même cas, mais pour une autre raison** : `9f` et la table de `spec.md` les attribuent à T9 et T7, **tâches d'implémentation**, ce que cet article interdit — leur preuve est donc portée par deux tâches `[TEST]` créées dans `tasks.md` (installation par un tiers, refus d'une configuration invalide), T7 et T9 n'en étant que les objets sous test ; **écart documentaire dû sur `9f` et sur la table de `spec.md`** (Art. 7). Aucun des trois chemins à revue humaine obligatoire (auth, facturation, proxy streaming) n'est touché par S01. |
| 9 | Simplicité, opérable par un seul | ✅ | **Pas d'orchestrateur de cluster** (`research.md` D-S01-1). Une commande démarre, une commande arrête, une commande consulte (FR-016). Le **retour arrière** est spécifié, pas seulement affirmé : re-pointer le digest précédent dans le fichier de digests puis redémarrer, en une commande, aucun autre fichier touché (FR-021), consigne d'implémentation ci-dessous, preuve en J4 (SC-010). |
| 10 | Tests d'abord | ✅ | Les preuves sont écrites depuis les critères d'acceptation et vues **rouges** avant que la définition de déploiement existe : A1–A3 (réf. `9f` T10), fichiers de gouvernance à la racine (SC-008, SC-009), retour arrière (SC-010). Pas de pyramide applicable — S01 ne porte qu'un seul module de code, le validateur de configuration, couvert unitairement. |
| 11 | Rien ne flotte | ✅ | **Cœur du critère A3.** Digest exact pour chaque image, dans un fichier unique ; échec explicite si un digest est indisponible, sans substitution (FR-013) ; retour arrière par ré-épinglage du digest précédent (FR-021). Le plan **n'ouvre lui-même aucun intervalle** : la version de `dcgm-exporter`, non sourcée, est portée en arbitrage plutôt qu'écrite « amont courant ». |
| 12 | Langage ubiquitaire | ✅ | Les identifiants fixés par `10b`, `10c` et `5b` sont employés **tels quels** : `quadra-net`, `pgdata`, `promdata`, `/data/models`, `/data/offload`, `/v1`, `/api`, `/ws`, `/grafana`, variables `QUADRA_` en UPPER_SNAKE, `offload`, `NVLink`, `node`, `host`, `engine`, `canari`. Aucun synonyme interdit du glossaire `10c`. |
| 13 | Doc et changelog | ✅ | `docs/install.md` est une **étape du même jalon** (réf. `9f` T9, J3), pas un suivi. `CHANGELOG.md` est à la racine (`10b`), au format Keep a Changelog + SemVer, et **l'entrée du changement qui livre S01 y figure dans ce même changement** (FR-020, SC-009). |
| 14 | Histoire atomique | ✅ | Une étape = un changement logique, un état qui fonctionne, un message conventionnel de scope `S01`. **Régime local (Art. 23)** : les hooks du dépôt exécutent les portes localement et font foi seuls — S01 n'attend rien de S03 pour les exécuter (`9c` : « Dépend de : — »). |
| 15 | Boucles bornées | ➖ | Aucun workflow agentique dans S01. Les politiques de redémarrage (FR-010) sont bornées par construction, et une sonde qui ne verdit pas rend la main avec un état non nul plutôt que d'attendre indéfiniment (cas limite de `spec.md`). |
| 16 | La revue trie | ✅ | **Régime local (Art. 23)** : chaque changement non trivial est revu avant fusion par une passe agentique indépendante, hors du chemin du risque ; les portes locales sont rouges ou vertes, jamais contournées. Chaque constat est corrigé ou accepté avec sa raison — les réserves de ce tableau et les *Arbitrages ouverts* en sont la trace écrite. |
| 17 | Le code modèle le domaine | ✅ | Les objets de S01 (service de la pile, volume nommé, route publiée, variable d'environnement) se rattachent à l'arbre d'exécution `Cluster → Host → Node → Engine → Instance` de `10a`. **Aucun état nouveau n'est créé** : les états observables d'un conteneur ne sont pas des états du domaine et `10d` n'en définit pas — ils sont signalés comme tels dans `data-model.md`, jamais stockés ni affichés comme états métier. |
| 18 | Modules SOLID | ✅ | Chaque service a une responsabilité unique ; `caddy` est le seul point d'entrée et le seul port publié. Ajouter un service se fait en ajoutant une déclaration, sans toucher les autres. Le validateur de configuration est appelé, il n'est pas dupliqué. |
| 19 | Une connaissance, un endroit | ✅ | Trois sources uniques : le **fichier de digests** pour les versions, le **validateur** partagé avec S04 pour les variables, et `.specify/memory/constitution.md` pour la constitution — `CONSTITUTION.md` à la racine en est la **copie de référence**, jamais éditée directement, et SC-008 échoue à la moindre divergence de version. La veille n'est pas recopiée : `RESEARCH-STACK.md` en est la source. `tasks.md` est la seule liste de tâches. |
| 20 | YAGNI | ⚠️ | **Réserve.** Deux provisions dépassent la lettre de l'article et sont assumées, pas dissimulées : (a) `/data/offload` est **créé** à M0 alors que l'`offload` relève de S18 (M3) — c'est un partitionnement de stockage coûteux à reprendre après mise en service, et **aucun mécanisme** n'est implémenté (aucun moteur ne le monte, aucune option n'existe) ; (b) le validateur de configuration est écrit dans le langage du plan de contrôle pour être **appelé** par S04 (M1) plutôt que réécrit — même besoin, pas une abstraction spéculative (`research.md` D-S01-4). Le reste est borné par la section « Hors périmètre » de `spec.md`, qui renvoie chaque exclusion à sa spec. **À lever** par arbitrage du mainteneur : soit ces deux provisions sont confirmées, soit `/data/offload` sort de S01. |
| 21 | Sécurité continue | ✅ | Aucun secret en dur ; `.env.example` ne contient que des valeurs factices explicitement marquées (FR-014). **Régime local (Art. 23)** : le scan de secrets, l'audit de dépendances et l'analyse statique s'exécutent en local avant chaque validation et leur sortie est capturée. L'épinglage par digest, qui relève de l'Art. 11, est la face « dépendances auditées » de cet article. |
| 22 | État de l'art | ✅ | Veille consignée dans `specs/RESEARCH-STACK.md` §1 et §2, **référencée sans être dupliquée** (Art. 19). Décisions applicables : **D1** et **D2**. **Aucune autre décision D3–D6 ne couvre S01** — dit explicitement plus haut. |
| 23 | La chaîne d'abord, le local en attendant | ✅ | S01 ne construit pas la chaîne (c'est S03) et **ne la consomme pas non plus** : `9c` lui donne « Dépend de : — », et l'ordre de l'Art. 23 ne crée pas de dépendance à rebours. En l'absence de chaîne et de dépôt distant, **tout s'exécute en local et fait foi** : portes de style, typage, tests, couverture et sécurité exécutées avant chaque validation, sortie capturée = definition of done ; versionnement et fusions en local, en `--no-ff`, sur la topologie `NNN-slug` → `dev` → `test` → `master`, sans commit direct sur `test` ni `master`. Ce que S01 fournit en retour est la définition de déploiement dont l'étape de bout en bout de S03 aura besoin — une contribution, pas une dette. L'épinglage par digest (Art. 11, critère A3) est ce qui rendra la promotion de `test` vers `master` réversible par ré-étiquetage. Régime dégradé **transitoire**, consigné ici, levé à la livraison de S03 (jalon M0). |

**Verdict** : porte **franchie avec une réserve**. Aucun article violé, aucune dérogation demandée —
la constitution n'en admet aucune. La réserve de l'**Art. 20** est un constat de revue ouvert
(Art. 16), tracé et adressé aux *Arbitrages ouverts* ; elle ne bloque pas la génération des tâches
mais doit être tranchée avant la déclaration du volume `/data/offload`.
`Complexity Tracking` reste vide : aucune complexité technique n'est à justifier.

## Project Structure

### Documentation (this feature)

```text
specs/001-socle-compose-moteurs-caddy/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — décisions techniques et alternatives
├── data-model.md        # Phase 1 — objets de déploiement (pas d'entité métier)
├── quickstart.md        # Phase 1 — guide de validation exécutable
├── contracts/           # Phase 1 — contrat des routes publiées (surface only)
├── checklists/
│   └── requirements.md  # Checklist qualité de la spec (déjà produite)
└── tasks.md             # Phase 2 — produit par /speckit-tasks, PAS par ce plan
```

### Source Code (repository root)

Les références `T1`…`T10` sont les **étapes de la fiche `9f`** citées en traçabilité, jamais des
identifiants de tâches : `tasks.md` seul les porte, au format Spec Kit.

```text
gateway/                 # Plan de contrôle (Python) — S04 et suivantes
└── config/
    └── settings.py      # Validateur de configuration au démarrage (réf. 9f T7)
                         # — seul code exécutable de S01

ui/                      # Interface d'administration — S11 et suivantes

deploy/                  # Tout l'artefact de déploiement de S01
├── docker-compose.yml   # 9 services, 4 volumes, réseau quadra-net
│                        #   postgres + redis .............. réf. 9f T2
│                        #   sglang + llama.cpp ............ réf. 9f T3
│                        #   prometheus, alertmanager,
│                        #   grafana, dcgm-exporter ........ réf. 9f T4
│                        #   caddy — seul port publié :443 . réf. 9f T5
│                        #   healthchecks, depends_on,
│                        #   restart policies .............. réf. 9f T6
├── digests.yml          # Source unique composant → digest (Art. 19)
│                        # peuplé au fil de T2, T3, T4, T5 ; seul fichier que
│                        # le retour arrière modifie (FR-021, SC-010)
├── Caddyfile            # TLS auto + routes /v1 /api /ws /grafana (réf. 9f T5)
├── .env.example         # Toutes les variables QUADRA_, documentées (réf. 9f T7)
├── prometheus/
│   └── prometheus.yml   # Cibles et intervalles — peuplé par S02
├── alertmanager/
│   └── alertmanager.yml # Routes de notification — peuplé par S02
└── grafana/
    └── provisioning/    # Source de données + tableaux de bord — peuplés par S02

docs/
└── install.md           # Procédure machine vierge → pile saine (réf. 9f T9)

tests/
├── e2e/
│   ├── test_bare_metal_boot.py  # Preuve A1+A2+A3 sur machine vierge (réf. 9f T10)
│   ├── test_repo_governance.py  # Preuve SC-008 + SC-009 — CONSTITUTION.md même
│   │                            # version que sa source, CHANGELOG.md conforme
│   │                            # aucune étape de 9f ne la porte : à créer
│   └── test_digest_rollback.py  # Preuve SC-010 — ré-épinglage du digest précédent
│                                # + redémarrage en une commande ; à créer
└── unit/
    └── test_config_validation.py # Preuve SC-006 — un démarrage dont une variable
                                  # QUADRA_ requise manque ou est invalide est
                                  # refusé, aucun service laissé démarré ; 9f et
                                  # spec.md l'attribuent à T7, tâche
                                  # d'implémentation : à créer (Art. 8, Art. 10)

Makefile                 # up / down / logs / ps (réf. 9f T8)
README.md                # Rôle de chaque répertoire de premier niveau (réf. 9f T1)
CONSTITUTION.md          # Copie de référence de la constitution ratifiée, injectée
                         # dans le contexte de chaque agent — source :
                         # .specify/memory/constitution.md (FR-019, SC-008)
                         # racine imposée par 10b, livraison confiée à S01 par le
                         # § Governance de la constitution ; réf. 9f T1
CHANGELOG.md             # Keep a Changelog + SemVer (FR-020, SC-009, Art. 13)
                         # créé en réf. 9f T1 ; l'entrée qui livre S01 est écrite
                         # dans le même changement que la livraison
```

**Structure Decision** : arborescence **imposée par la fiche 9f** (`gateway/`, `ui/`, `deploy/`,
`docs/`), complétée par les **deux fichiers de racine que `10b` impose** — `CONSTITUTION.md` et
`CHANGELOG.md`. Le découpage sépare le **plan de contrôle** (code custom, Art. 6) de l'**artefact de
déploiement** (déclaratif). Les répertoires `prometheus/`, `alertmanager/` et `grafana/` sont **créés
vides par S01** et **peuplés par S02** : S01 fournit le point de montage, S02 le contenu — ce qui
évite que les deux specs se disputent les mêmes fichiers.

**Trois précisions que la fiche `9f` ne donne pas** et que ce plan tranche, écarts consignés (Art. 7) :

1. **Le service `caddy` est rattaché à T5**, avec son `Caddyfile`. `9f` énumère bien `caddy` parmi les
   services de `docker-compose.yml`, mais aucune de ses tâches ne le déclare : T5 ne nomme que le
   `Caddyfile`. Or les deux sont indissociables — le port publié 443, l'unique publication de toute la
   pile (FR-006, critère A2), est une propriété du **service**, pas du fichier de configuration.
2. **`deploy/digests.yml` est le fichier de digests** annoncé par `research.md` D-S01-2 et exigé par
   FR-021. Son nom est une décision de ce plan ; sa fonction ne l'est pas. Il est peuplé dès la première
   image épinglée (T2) et complété à chaque service ajouté.
3. **`CONSTITUTION.md` et `CHANGELOG.md` sont livrés en T1**, avec l'arborescence et le README, parce
   que l'acceptation US1 nº 1 les exige dès le dépôt cloné. L'**entrée de changelog** qui livre S01,
   elle, s'écrit dans le changement de livraison lui-même (Art. 13), pas en T1.

## Ordre de construction

Les jalons internes de la fiche `9f` donnent l'ordre ; **`tasks.md` est la source unique du détail des
tâches** (Art. 19 — ne pas réénumérer les tâches ici, les deux listes divergeraient). La colonne de
droite rattache chaque étape à ce qui la juge : un **critère d'acceptation de `9f`** (A1, A2, A3) ou,
quand `9f` n'en donne pas, la **consigne de `9f`** ou l'exigence de la constitution qui la fonde.
Aucune étape ne dépasse M0, qui exige « S01 complet » (`9e`) : les quatre jalons internes y entrent.

| Jalon | Intention | User story | Étapes (réf. `9f`) | Rattachement — critère ou consigne |
| --- | --- | --- | --- | --- |
| **J1** Fondations | le dépôt cloné démarre ses bases | US1 (P1) | T1 arborescence + README + `CONSTITUTION.md` + `CHANGELOG.md` · T2 compose postgres + redis, `digests.yml` | **A3** dès la première image épinglée · consigne `9f` « volumes nommés » (SC-007) · racine `10b` + § Governance de la constitution (SC-008) · Art. 13 (SC-009) |
| **J2** Cœur | une commande démarre moteurs, observabilité et TLS | US2 (P2) | T3 sglang + llama.cpp épinglés · T4 prometheus, alertmanager, grafana, dcgm-exporter · T5 service `caddy` + `Caddyfile` (TLS, `/v1` `/api` `/ws` `/grafana`) · T6 healthchecks + depends_on + restart | **A1** (pile saine < 5 min, sondes vertes) · **A2** (seul 443 sort de `quadra-net`) · **A3** (toute version épinglée) · consigne `9f` « aucun port moteur publié » |
| **J3** Surface | configuration par fichier, installation documentée | US3 (P3) | T7 `.env.example` + validation au démarrage · T8 Makefile up/down/logs/ps · T9 `docs/install.md` | consignes `9f` « `.env.example` exhaustif » et « documenté dans `docs/install.md` » (SC-004, SC-006) · **A1** — la validation conditionne le démarrage, donc la pile saine |
| **J4** Preuves | les critères sont prouvés sur machine vierge | — | T10 `[TEST]` vierge → verte, ports, digests · **deux preuves à créer** : fichiers de gouvernance à la racine, retour arrière par ré-épinglage | **A1 · A2 · A3** (T10) · SC-008 et SC-009 · SC-010 (réf. `w10`) — `9f` ne porte aucune tâche pour ces deux dernières, écart consigné (Art. 7) |

**Contraintes d'ordre** : J1 précède J2 et J3 ; J3 est indépendante de J2 hormis la validation de
configuration ; J4 exige les trois précédents. Le détail des dépendances et des opportunités de
parallélisation est dans `tasks.md`.

**Point de blocage à surveiller** : la version de `dcgm-exporter` n'étant pas sourcée, T4 ne peut pas
être clôturée sans l'arbitrage correspondant — FR-012 vaut pour *toute* image, et A3 se vérifie sur la
définition de déploiement entière.

## Consignes d'implémentation

- **`caddy` est le seul service qui publie un port**, et il n'en publie qu'un : 443. Le service et son
  `Caddyfile` sont écrits ensemble (T5) ; déclarer l'un sans l'autre laisse soit un proxy sans routes,
  soit des routes sans proxy. Aucun port de moteur, de base, de cache ou d'observabilité n'est publié :
  c'est le critère A2 et une exigence de sécurité, les moteurs n'exposant ni authentification ni TLS.
  Le contrôle est automatisable — un balayage ne doit trouver que 443 parmi les ports de la pile.
- **Digest, pas tag.** Un tag reste mouvant même s'il paraît figé. Le contrôle de T10 doit rejeter toute
  référence sans digest, y compris un intervalle de versions ouvert.
- **Le retour arrière est une procédure, pas une propriété.** Il s'écrit et se prouve :
  1. un seul fichier porte les digests (`deploy/digests.yml`) et il est le **seul** que le retour
     arrière modifie ;
  2. re-pointer la valeur précédemment épinglée — jamais une autre version, jamais « la dernière qui
     marchait » choisie au jugé ;
  3. redémarrer le service par **une seule commande** de la cible d'exploitation, sans reconstruction
     d'image ;
  4. la version effectivement en service doit rester **lisible depuis la définition de déploiement**
     (son affichage dans une vue de santé `6g` relève de S21, pas de S01).

  C'est FR-021, prouvé par SC-010, et c'est la lecture de `w10` (« re-pointer le tag précédent,
  1 commande ») exprimée en digests conformément à D-S01-2.
- **Volumes nommés, jamais de montage lié anonyme** — la persistance doit survivre à la recréation des
  conteneurs (SC-007). Graphie de `5b` employée telle quelle : `/data/models`, `/data/offload`,
  `pgdata`, `promdata`.
- **Le fichier d'environnement d'exemple ne contient aucun secret réel**, seulement des valeurs
  factices explicitement marquées comme telles (Art. 21). Toute variable est en UPPER_SNAKE préfixée
  `QUADRA_` (`10b`) ; aucun autre espace de noms.
- **La validation de configuration est partagée avec S04** : elle vit dans le plan de contrôle et est
  invoquée au démarrage. Ne pas en écrire une seconde version dans les scripts de déploiement
  (Art. 19). Elle interrompt le démarrage en nommant la variable fautive **et** la correction attendue,
  et ne laisse **aucun service démarré** — aucun délai chiffré n'est exigé, ne pas en inventer un.
- **`CONSTITUTION.md` est une copie, pas un original.** Sa source est
  `.specify/memory/constitution.md` (Art. 19) : on ne l'édite jamais directement, on la régénère depuis
  la source. Les deux copies portent la même version, et le contrôle de SC-008 échoue à la moindre
  divergence. Amender la constitution passe par l'outil de gouvernance, jamais par ce fichier.
- **`CHANGELOG.md` se remplit dans le changement qu'il décrit** (Art. 13) : format Keep a Changelog,
  versionnement SemVer, et l'entrée du changement qui livre S01 est écrite avec la livraison, pas
  après.
- **`/data/offload` est créé mais n'est monté par aucun moteur** à ce stade. Aucune option d'`offload`
  n'existe dans S01 ; il attend S18. Voir la réserve de l'Art. 20.

## Complexity Tracking

*Aucune violation de la porte Constitution Check. Section volontairement vide.*
