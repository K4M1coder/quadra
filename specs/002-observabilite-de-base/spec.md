# Feature Specification: S02 — Observabilité de base

**Feature Branch**: `002-observabilite-de-base`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9g du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S02 du plan de specs 9c : « Observabilité de base (Prom + DCGM + Grafana) », références 6e · 5a, dépend de S01, effort **0.5 sem** (9c porte les efforts en semaines ; la fiche 9g les détaille en j-agent et totalise « ≈ 3 j-agent »), phase 1 (socle), jalon produit M0 (Alpha).

## User Scenarios & Testing *(mandatory)*

Les parcours ci-dessous reprennent les jalons internes J1–J2 de la fiche 9g, par profondeur
croissante. J3 (preuves) n'est pas un parcours utilisateur : il fournit la vérification mécanique des
critères d'acceptation.

### User Story 1 - Collecte : toutes les métriques sont captées et conservées 90 jours (Priority: P1)

L'administrateur dispose de Prometheus, qui scrape périodiquement tous les composants de la
plateforme — le `gateway`, les moteurs, `dcgm-exporter` et Prometheus lui-même — et conserve
l'historique assez longtemps pour analyser une dérive sur un trimestre.

**Why this priority**: c'est la profondeur J1 de la fiche 9g et la raison d'être de la spec :
établir **la source unique de métriques avant tout code métier**. Sans elle, S04, S05 et S15
n'auraient nulle part où publier leurs mesures, et l'Art. 19 (une connaissance, un seul endroit)
serait violé dès la première fonctionnalité.

**Independent Test**: démarrer la plateforme et constater que chaque cible déclarée apparaît `up`
dans `/targets`, que `dcgm-exporter` expose ses mesures par carte, et que la durée de conservation
configurée est bien celle attendue — sans qu'aucun `Dashboard` existe encore.

**Acceptance Scenarios**:

1. **Given** la plateforme démarrée, **When** l'administrateur consulte `/targets`, **Then**
   **toutes** les cibles déclarées (le `gateway`, les moteurs, `dcgm-exporter`, et Prometheus
   lui-même) sont `up`.
2. **Given** la machine de référence à 4 GPUs, **When** Prometheus scrape `dcgm-exporter`, **Then**
   les mesures de température, de puissance et de mémoire vidéo sont disponibles **par carte**, pour
   les 4 cartes.
3. **Given** `prometheus.yml` configuré, **When** l'administrateur inspecte les `scrape_interval`,
   **Then** `dcgm-exporter` porte un `scrape_interval` plus fin (1 seconde) que les autres cibles
   (5 secondes), afin de capter les pics thermiques et de puissance.
4. **Given** des mesures collectées depuis plus de 90 jours, **When** l'administrateur interroge
   l'historique, **Then** les données des 90 derniers jours sont disponibles et les plus anciennes
   ont été purgées.
5. **Given** la plateforme arrêtée puis redémarrée, **When** l'administrateur interroge l'historique,
   **Then** les mesures collectées avant l'arrêt sont toujours présentes (volume `promdata`
   persistant).

---

### User Story 2 - Surface : `Dashboards` provisionnés et alertes routées (Priority: P2)

L'administrateur ouvre Grafana et y trouve, sans avoir rien créé à la main, les `Dashboards` GPU
(DCGM) et moteurs ; les alertes déclenchées partent vers les destinataires configurés.

**Why this priority**: c'est la profondeur J2. Elle rend la collecte exploitable par un humain et
prépare la surface sur laquelle S15 (hub d'observabilité, éditeur de règles, heatmap) viendra se
poser. Elle est vérifiable seule dès que J1 existe.

**Independent Test**: repartir d'un stockage Grafana vide, démarrer la plateforme, et constater que
les `Dashboards` attendus sont présents et alimentés — sans aucune action manuelle dans Grafana.

**Acceptance Scenarios**:

1. **Given** un stockage Grafana vide, **When** la plateforme démarre, **Then** la datasource
   Prometheus et les `Dashboards` sont créés automatiquement à partir des fichiers JSON versionnés
   dans le dépôt.
2. **Given** les `Dashboards` provisionnés, **When** l'administrateur ouvre le `Dashboard` GPU
   (DCGM), **Then** il voit par carte la température, la puissance consommée et l'occupation de la
   mémoire vidéo.
3. **Given** les `Dashboards` provisionnés, **When** l'administrateur ouvre le `Dashboard` des
   moteurs, **Then** il voit la latence du premier jeton (TTFT), la latence inter-jetons (ITL) et la
   profondeur des files.
4. **Given** un `Dashboard` modifié à la main dans Grafana, **When** la plateforme redémarre,
   **Then** le fichier JSON versionné du dépôt fait autorité et la modification manuelle ne survit
   pas — le dépôt est la source unique (Art. 19).
5. **Given** une alerte qui se déclenche, **When** Alertmanager la traite, **Then** elle est
   acheminée vers les destinataires configurés (point de terminaison sortant signé et courriel)
   selon sa gravité, avec un contenu lisible issu d'un gabarit versionné.

---

### Edge Cases

- **Une cible est injoignable** (composant arrêté ou non encore construit) : elle apparaît
  explicitement `down` dans `/targets`, avec la raison ; le scrape des autres cibles n'est pas
  interrompu.
- **`dcgm-exporter` ne trouve aucune carte** (pilote absent, machine sans GPU) : la cible est
  signalée `down` sans faire échouer le reste du scrape — utile pour les machines de
  développement.
- **Le volume `promdata` approche de la saturation** : la purge par ancienneté (90 j) s'applique et
  le scrape ne s'arrête pas silencieusement. S02 ne pose **aucune règle d'alerte** sur le stockage :
  `6e` n'en comporte pas, l'éditeur de règles d'alerte relève de S15 et la santé du stockage de S21.
- **Un libellé de métrique porterait une valeur à cardinalité libre** (identifiant de requête, texte
  saisi par un utilisateur, adresse) : le cas est exclu par la règle de nommage — seuls des
  identifiants stables sont admis comme libellés (`labels = ids`, jamais de PII : `9g`, `5c`,
  Art. 1, Art. 5). À M0, la règle est tenue par la convention et par la revue ; aucune porte
  mécanique de libellés n'est posée par S02.
- **Le destinataire d'alerte est injoignable** : l'échec d'acheminement est lui-même observable et ne
  fait pas disparaître l'alerte.

## Requirements *(mandatory)*

### Functional Requirements

#### Collecte et conservation (J1)

- **FR-001**: Prometheus DOIT scraper, comme jobs déclarés dans `prometheus.yml`, le `gateway`, les
  moteurs du déploiement de référence (`node-A` sglang GPU 0+1 · `node-B` sglang GPU 2 · `node-C`
  llama.cpp GPU 3, réf. `5b`), `dcgm-exporter`, et Prometheus lui-même (job `self`).
- **FR-002**: Prometheus DOIT exposer `/targets`, indiquant pour chaque cible son état — `up` ou
  `down` — et, lorsqu'elle est `down`, la raison de l'échec du dernier scrape.
- **FR-003**: Prometheus DOIT scraper `dcgm-exporter` avec un `scrape_interval` de 1 seconde et les
  autres cibles avec un `scrape_interval` de 5 secondes.
- **FR-004**: `dcgm-exporter` DOIT exposer, pour chacune des cartes GPU, sa température, sa puissance
  consommée et l'occupation de sa mémoire vidéo.
- **FR-005**: Prometheus DOIT conserver l'historique des mesures pendant **90 jours** et purger
  automatiquement au-delà.
- **FR-006**: L'historique des mesures DOIT être stocké de façon persistante (volume `promdata`) et
  survivre à l'arrêt et au redémarrage de la plateforme.

#### Source unique et nommage (transverse, Art. 12 · Art. 19)

- **FR-007**: Prometheus DOIT être **l'unique source de métriques** de la plateforme : aucun
  composant ne constitue une seconde chaîne parallèle de mesure.
- **FR-008**: Toute métrique propre à la plateforme DOIT suivre la convention de nommage
  `quadra_<entité>_<mesure>_<unité>`, où l'entité provient de la taxonomie du domaine (`10a`).
- **FR-009**: Les métriques exposées nativement par les moteurs upstream (sglang, llama.cpp)
  DOIVENT être réexposées **telles quelles**, sans renommage ni réécriture (Art. 6).
- **FR-010**: Les libellés de métriques NE DOIVENT contenir que des identifiants stables et de
  cardinalité bornée (`lane`, `alias`, `node`, `host`, `key_id`). Aucune donnée personnelle, aucun
  contenu de prompt et aucune valeur à cardinalité libre NE DOIT apparaître dans un libellé (Art. 1).

#### `Dashboards` provisionnés (J2)

- **FR-011**: Grafana DOIT provisionner automatiquement, au démarrage, la datasource Prometheus et
  les `Dashboards` à partir des fichiers JSON versionnés dans le dépôt.
- **FR-012**: Aucun `Dashboard` NE DOIT être créé ou modifié à la main dans Grafana : le fichier JSON
  versionné fait autorité et est réappliqué au démarrage.
- **FR-013**: Le système DOIT fournir un `Dashboard` GPU (DCGM) présentant, par carte, température,
  puissance et mémoire vidéo.
- **FR-014**: Le système DOIT fournir un `Dashboard` des moteurs présentant TTFT, ITL et la
  profondeur des files.
- **FR-015**: Les fichiers JSON de `Dashboard` DOIVENT être nommés `ds-<domaine>.json` (`10b`) et
  versionnés dans le dépôt.

#### Routage des alertes (J2)

- **FR-016**: Alertmanager DOIT acheminer les alertes déclenchées vers les destinataires configurés
  dans `alertmanager.yml` — point de terminaison sortant et courriel — selon la gravité de l'alerte.
- **FR-017**: Le contenu des notifications DOIT être produit à partir de gabarits versionnés dans le
  dépôt.
- **FR-018**: L'échec d'acheminement d'une notification DOIT lui-même être observable et ne DOIT pas
  faire disparaître l'alerte sous-jacente.

#### Preuves (J3)

- **FR-019**: Le système DOIT être vérifiable par une procédure automatisée prouvant simultanément
  que toutes les cibles de `/targets` sont `up`, que les `Dashboards` attendus sont chargés, et que
  la durée de conservation est celle exigée.

### Hors périmètre *(Art. 20 — YAGNI)*

- Le hub d'observabilité interne, l'éditeur de règles d'alerte, les actions automatiques réversibles
  et la heatmap de charge → **S15**. S02 pose la collecte et le routage ; S15 pose l'interface et les
  règles.
- L'émission des métriques métier (requêtes, jetons, lanes, budgets) → **S04**, **S05**, **S08** :
  S02 déclare comment on collecte et comment on nomme, chaque spec émettant ses propres mesures.
- Les traces par requête et la rétention des prompts → **S14**.
- La vue de santé agrégée et les diagnostics, dont la santé du stockage (`6g`) → **S21**.
- Le démarrage des conteneurs d'observabilité et l'exposition réseau → **S01**.

### Key Entities

Les entités ci-dessous sont celles de l'arbre de l'observation de la taxonomie (`10a`) :
`Metric → Dashboard / Alert rule → Action → Event /ws → Audit entry`. S02 n'en touche que les trois
premières et n'en crée aucune autre : un concept absent de `10a` s'y ajoute d'abord par amendement
(Art. 17, Art. 12).

- **Metric** : mesure nommée selon la convention du domaine, porteuse de libellés à cardinalité
  bornée. Elle est produite par une cible déclarée dans `prometheus.yml` — un job, son
  `scrape_interval`, et le résultat de son dernier scrape (`up` ou `down`) lisible dans `/targets`.
  Prometheus en est la source unique.
- **Dashboard** : fichier JSON `ds-<domaine>.json` versionné dans le dépôt, provisionné
  automatiquement dans Grafana, lisant la datasource Prometheus.
- **Alert rule** : règle dont le passage en `firing` est acheminé par `alertmanager.yml` vers ses
  destinataires selon sa gravité (point de terminaison sortant, courriel), avec son gabarit de
  message. S02 pose le routage ; l'édition des règles relève de S15.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: **100 % des cibles déclarées** apparaissent `up` dans
  `/targets`, sur une plateforme fraîchement démarrée.
- **SC-002** *(critère A2)*: Sur un stockage Grafana vide, les `Dashboards` GPU et moteurs sont
  présents et alimentés **sans aucune action manuelle**, à l'issue du démarrage.
- **SC-003** *(critère A3)*: La durée de conservation effective des mesures est de **90 jours** :
  une mesure de 89 jours est lisible, une mesure de 91 jours ne l'est plus.
- **SC-004**: Les 4 cartes GPU exposent chacune température, puissance et mémoire vidéo, rafraîchies
  au moins **une fois par seconde**.
- **SC-005**: Une modification manuelle d'un `Dashboard` ne survit pas au redémarrage : **100 %** des
  `Dashboards` correspondent à leur fichier JSON versionné après démarrage.
- **SC-007**: Une alerte déclenchée atteint ses destinataires configurés, et un échec
  d'acheminement est lui-même visible dans l'état de la plateforme.

*(Le numéro SC-006 est retiré et non réattribué : il portait un contrôle automatisé des libellés que
la fiche `9g` ne demande pas — voir la table ci-dessous et les Arbitrages ouverts.)*

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9g) |
| --- | --- | --- |
| A1 — tous les targets up | SC-001, SC-004 | T8 `[TEST]` targets · T7 `[INT]` scrape du `gateway` (S01) |
| Cible `down` signalée avec sa raison | FR-002 — **aucun critère de succès** | T8 `[TEST]` — assertion du chemin `down` : cible injoignable signalée `down` avec la raison, scrape des autres cibles non interrompu (cas limite ci-dessus) |
| A2 — dashboards importés automatiquement | SC-002, SC-005 | T8 `[TEST]` dashboards |
| A3 — rétention 90 j configurée | SC-003 | T8 `[TEST]` rétention |
| Consignes (aucun `Dashboard` à la main · tout JSON versionné · `labels = ids`, jamais de PII) | portées par FR-012 · FR-011 + FR-015 · FR-010 — **aucun critère de succès** | `9g` n'attache aucune preuve aux consignes (« Critères → preuves : A1–A3 → T8 ») ; T1 `prometheus.yml` en est l'objet, pas la preuve |
| Routage des alertes | SC-007 | T8 `[TEST]` — scénario 7 de `quickstart.md` (routage par gravité, échec d'acheminement observable) ; T5 `alertmanager.yml` : routes + gabarits **en est l'objet, pas la preuve** |

## Assumptions

- **Dépendance à S01** : les conteneurs d'observabilité (Prometheus, Alertmanager, Grafana,
  `dcgm-exporter`) sont démarrés par le socle S01 et joignables sur le réseau interne `quadra-net`.
  S02 les **configure**, il ne les déploie pas.
- **Aucune métrique métier n'existe encore à M0** : au jalon M0, les seules cibles réellement
  peuplées sont `dcgm-exporter`, les moteurs et la santé du `gateway`. Les familles de métriques
  métier (requêtes, jetons, lanes, budgets) sont déclarées par leurs specs respectives et scrapées
  par Prometheus dès qu'elles apparaissent.
- **Aucune télémétrie sortante** : les métriques ne quittent jamais l'infrastructure ; les seuls flux
  sortants admis sont les notifications d'alerte vers les destinataires internes configurés (Art. 1).
- **Matériel de référence** : 4 cartes GPU de 24 Go sur une machine unique. Le multi-machines
  (libellé `host`, métrique de disponibilité par hôte) est prévu par la convention de nommage mais
  n'est exercé qu'à partir de S19.
- **`scrape_interval` retenus** : 1 seconde pour `dcgm-exporter`, 5 secondes pour les autres cibles —
  valeurs fixées par le déploiement de référence du document (5b).
- **Conservation** : 90 jours pour les métriques. Les autres rétentions du projet (requêtes
  24 mois, prompts 30 j, audit 2 ans, résultats de jobs 7 j) relèvent des specs qui portent ces
  données.

### Arbitrages ouverts *(Art. 7 — consignés, non tranchés)*

Ces points ne sont pas décidables depuis les sources ; ils sont notés ici et n'engagent aucun critère
ci-dessus.

- **Amendement de taxonomie dû sur `10a`** : la configuration de scrape et le routage des
  notifications sont ici rattachés à `Metric` et à `Alert rule`, faute d'entités correspondantes dans
  l'arbre de l'observation (`Metric → Dashboard / Alert rule → Action → Event /ws → Audit entry`). Si
  la cible de scrape et la route de notification doivent devenir des entités du domaine, `10a` doit
  d'abord être amendé (Art. 17, Art. 12) — S02 ne les crée pas de son propre chef.
- **Nommage du fichier de spec** : `10b` fixe « Specs : `specs/S<nn>-<slug>.md` », alors que ce
  fichier vit dans `specs/002-observabilite-de-base/spec.md`. Le nommage Spec Kit `NNN-slug` est
  imposé par l'Art. 23 et prévaut ; l'écart de `10b` est un amendement documentaire dû (Art. 7).
- **`10a` annonce « Constitution (22 articles) »** alors que 23 sont ratifiés (v1.1.0). Amendement
  documentaire dû (Art. 7, Art. 13) ; aucun effet sur le périmètre de S02.
- **Noms de cibles de `6e`** : `6e` liste `vllm-qwen:8000`, `vllm-mistral:8001`,
  `llamacpp-gpu3:8002`, alors que la topologie de déploiement de `5b` est `node-A` sglang GPU 0+1 ·
  `node-B` sglang GPU 2 · `node-C` llama.cpp GPU 3, cohérente avec `5a` qui fait de sglang le moteur
  principal. FR-001 suit `5b` ; l'état antérieur de `6e` est un amendement documentaire dû (Art. 7).
