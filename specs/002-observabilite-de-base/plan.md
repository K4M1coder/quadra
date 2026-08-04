# Implementation Plan: S02 — Observabilité de base

**Branch**: `002-observabilite-de-base` | **Date**: 2026-08-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-observabilite-de-base/spec.md`

## Summary

Établir **la source unique de métriques** de la plateforme — **Prometheus** — **avant tout code
métier** : scrape de tous les composants, exposition des mesures matérielles par carte GPU via
`dcgm-exporter`, `Dashboards` Grafana provisionnés depuis le dépôt, routage des alertes par
Alertmanager, conservation 90 jours.

**Approche technique** : S01 a démarré les conteneurs ; S02 en fournit **la configuration**. Toute
définition — jobs de `prometheus.yml`, fichiers `ds-<domaine>.json`, routes d'`alertmanager.yml` —
vit **dans le dépôt** et est **réappliquée au démarrage**, jamais seulement importée une fois. C'est
la différence entre respecter l'Art. 19 et le contourner.

**Point de vigilance principal** : la tentation d'ajuster un `Dashboard` directement dans Grafana. Le
plan la rend impossible par construction — le provisionnement réapplique le dépôt à chaque démarrage,
et une modification manuelle ne survit pas.

**Jalon** : **M0** — `9e` exige « S02 complet ». Aucune étape de ce plan ne va au-delà.

## Technical Context

**Language/Version** : **aucun code applicatif.** Les artefacts sont **déclaratifs** :
`prometheus.yml`, fichiers JSON de `Dashboard`, `alertmanager.yml` et ses gabarits, provisionnement
Grafana. La consigne « labels = ids, jamais de PII » (`9g`, `5c`) est une **règle de nommage**, pas un
module : à M0 elle est tenue par la liste blanche de `10b` et par la revue (Art. 16) — voir
*Arbitrages ouverts*.

**Primary Dependencies** *(après décision D1 — voir ci-dessous)* :

| Rôle | Composant | Version retenue | Licence |
| --- | --- | --- | --- |
| Collecte de métriques | prometheus | **3.x LTS**, épinglée par digest — D1 | Apache-2.0 |
| Routage d'alertes | alertmanager | **à trancher** — hors de la *Portée* de D1, aucune version dans `5a` ni dans `RESEARCH-STACK` §1 | Apache-2.0 |
| Visualisation | grafana | **13.x**, épinglée par digest — D1 | AGPL-3 |
| Métriques matérielles GPU | dcgm-exporter | épinglé par digest | NVIDIA |

Les quatre images DOIVENT être épinglées **par digest** (Art. 11 : jamais `:latest`, jamais une
branche, jamais un intervalle ouvert). La ligne alertmanager reste **ouverte** : `5a` écrit « prometheus 2 ·
alertmanager » sans version, la table §1 de la veille n'en porte pas de ligne, et la *Portée* de D1
se limite à « Postgres, Redis, Grafana, Prometheus, Caddy, React ». Aucune valeur n'est inventée ici —
le point est porté en *Arbitrages ouverts*.

**Storage** : volume `promdata`, créé par S01, **configuré ici** avec une rétention de **90 jours**
(`5b` : « volume pgdata · promdata (rétention 90 j) »).

**Testing** : `/targets` — toutes les cibles `up` ; présence et conformité des `Dashboards` après
démarrage sur stockage Grafana vide ; rétention vérifiée à 89 j / 91 j. Aucun GPU requis pour la
majorité des contrôles ; `dcgm-exporter` est le seul à en exiger un. Tant que S03 n'est pas livrée,
ces portes **s'exécutent en local** et leur sortie capturée fait foi (Art. 23).

**Target Platform** : machine unique `node-01`, réseau interne `quadra-net` (`5b`). Le libellé `host`
est prévu par la convention de nommage (`10b`) mais n'est exercé qu'à partir de S19.

**Performance Goals** : `scrape_interval` de **1 seconde** pour `dcgm-exporter`, de **5 secondes**
pour les autres jobs (`5b`). Ces valeurs sont un compromis assumé : assez fin pour capter un pic
thermique, assez lâche pour ne pas peser sur les moteurs (Art. 2).

**Constraints** :

- **Aucune seconde chaîne de mesure** dans tout le projet (Art. 19). Tout consommateur de métriques
  lit ce Prometheus.
- **Aucune donnée personnelle ni valeur à cardinalité libre** dans un libellé (Art. 1) — liste
  blanche `lane`, `alias`, `node`, `host`, `key_id` (`10b`).
- **Aucun `Dashboard` créé à la main** : le dépôt fait autorité, réappliqué au démarrage.
- **Aucune télémétrie sortante.** Seules sorties : notifications d'alerte vers destinataires internes.
- **Aucun échec d'acheminement silencieux** : lorsqu'un destinataire est injoignable, l'échec de la
  notification est lui-même observable et l'alerte passée en `firing` **ne disparaît pas** (FR-018).

**Scale/Scope** : 6 jobs de scrape (`gateway`, `node-A`, `node-B`, `node-C`, `dcgm-exporter`,
`self`), 2 `Dashboards`, 1 datasource Prometheus, N routes de notification par gravité.

### Décisions issues de la veille — **arbitrées**

Référence : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md), §1 et §7 — jamais dupliquée ici
(Art. 19, Art. 22).

- **D1 — épingler l'amont actuel.** S02 est directement concernée : `5a` épingle prometheus 2 et
  grafana 11, l'amont est à 3.x LTS et 13.x. La décision retenue est l'amont, épinglé par digest.
  **Conséquence concrète** : le format de `prometheus.yml` et les options de rétention ont évolué
  entre les majeures — T1 et T2 doivent être écrites **pour la version retenue**, pas transposées
  depuis un exemple ancien.
- **Aucune autre décision de la veille ne couvre S02.** D2 (pilote/CUDA) relève de S01 ; D3, D4 (fit
  VRAM) de S09 ; D5 (Elo) de S16 ; D6 (surface des lots) de S04 et S18. Et **D1 ne couvre pas
  alertmanager** : sa *Portée* ne le nomme pas.
- **Cibles de scrape — topologie `5b`.** Les jobs moteurs sont `node-A` sglang GPU 0+1 · `node-B`
  sglang GPU 2 · `node-C` llama.cpp GPU 3, cohérents avec `5a` qui fait de sglang le moteur
  principal. Les noms `vllm-qwen:8000` · `vllm-mistral:8001` · `llamacpp-gpu3:8002` de `6e` sont un
  **état antérieur** de l'étude préliminaire : ils ne sont pas recopiés. FR-001 fixe la même liste.

## Constitution Check

*GATE : à franchir avant la génération des tâches. Ré-évalué après la conception détaillée.*

| Art. | Exigence | Statut | Comment S02 s'y conforme |
| --- | --- | --- | --- |
| 1 | Données sur site | ✅ | **Article central de cette spec.** Libellés = identifiants stables uniquement (`lane`, `alias`, `node`, `host`, `key_id`), jamais de contenu ni de donnée personnelle (FR-010). Aucune télémétrie sortante ; seules sorties = notifications internes. À M0 la règle est tenue par la convention `10b` et par la revue : `9g` n'attache aucune preuve à ses consignes. |
| 2 | Humain interactif d'abord | ➖ | Sans objet : S02 n'ordonnance rien. La cadence de collecte est choisie pour ne pas peser sur les moteurs. |
| 3 | Consentement explicite | ➖ | Aucune action coûteuse ni irréversible. |
| 4 | Tout est tracé | ✅ | S02 **est** l'infrastructure de traçabilité côté mesures. Le journal d'audit (S13) en est le pendant côté actions. |
| 5 | Le serveur décide | ➖ | Aucune permission dans S02. |
| 6 | Réutiliser, ne jamais forker | ✅ | Métriques des moteurs **réexposées telles quelles**, sans renommage (FR-009). Aucun correctif amont. |
| 7 | La spec avant le code | ✅ | Spec S02 figée et validée avant ce plan. Profondeur limitée à M0 (`9e` : « S02 complet »). |
| 8 | Qualité mécanique | ✅ | Preuve T8 tracée critère→preuve (`9g` : « A1–A3 → T8 »), complétée par T7 `[INT]`. Aucun chemin à revue humaine (ni auth, ni facturation, ni proxy streaming). |
| 9 | Simplicité | ✅ | Un Prometheus, pas deux. Configuration déclarative, lisible d'un fichier. |
| 10 | Tests d'abord | ✅ | T8 écrit depuis A1–A3 ; le contrôle de rétention (89 j / 91 j) est écrit avant `prometheus.yml`. |
| 11 | Rien ne flotte | ✅ | prometheus, alertmanager, grafana, dcgm-exporter épinglés **par digest**, comme S01. La version d'alertmanager est **à trancher** — elle sera épinglée, jamais laissée flottante. |
| 12 | Langage ubiquitaire | ✅ | **Convention de nommage des métriques imposée** (FR-008) et des `Dashboards` `ds-<domaine>.json` (FR-015), dérivée de la taxonomie `10a` et de `10b`. Identifiants normatifs employés tels quels. |
| 13 | Doc et changelog | ✅ | Tout changement de job ou de `Dashboard` est un changement versionné, revuable. |
| 14 | Histoire atomique | ✅ | Un `Dashboard` = un fichier = un changement. Portes locales avant chaque validation (Art. 23). |
| 15 | Boucles bornées | ➖ | Aucune boucle agentique. Les actions automatiques d'alerte relèvent de S15. |
| 16 | La revue trie | ✅ | Un `Dashboard` modifié se lit en revue comme un diff de fichier — c'est l'effet recherché. C'est aussi la revue qui tient la règle de libellés à M0. |
| 17 | Le code modèle le domaine | ✅ | Entités rattachées à l'arbre de l'observation de `10a` (`Metric → Dashboard / Alert rule`). Aucune entité créée hors `10a` : les manques sont signalés, pas comblés. |
| 18 | Modules SOLID | ✅ | Ajouter un job = ajouter une entrée dans `prometheus.yml`, sans toucher au reste. |
| 19 | Une connaissance, un endroit | ✅ | **Article central.** Source unique de métriques (FR-007) ; le dépôt fait autorité sur les `Dashboards` (FR-012) ; réapplication au démarrage. Veille non dupliquée (renvoi à `RESEARCH-STACK.md`). |
| 20 | YAGNI | ✅ | Ni hub interne, ni éditeur de règles, ni heatmap — tout cela est S15. **Ni module de contrôle de libellés** : à M0 aucun composant n'émet `lane`/`alias`/`key_id`, ces familles arrivent avec S04, S05, S08 (M1–M2, `9c`). S02 pose les jobs, les `Dashboards` et le routage, rien de plus. |
| 21 | Sécurité continue | ✅ | Aucun secret ni donnée personnelle dans une série temporelle : la liste blanche de libellés (`10b`) l'exclut par construction du nommage. Aucune entrée applicative à valider — S02 n'expose aucune route. |
| 22 | État de l'art | ✅ | Veille consignée dans `specs/RESEARCH-STACK.md`, D1 arbitrée et reprise ici. Aucune autre décision D2–D6 ne couvre S02. Écart de majeures pris en compte dans T1 et T2. |
| 23 | La chaîne d'abord, le local en attendant | ✅ | S02 ne construit pas la chaîne et **n'en dépend pas** : `9c` ne lui donne que S01 comme dépendance, la chaîne est S03. Le provisionnement depuis le dépôt, réappliqué à chaque démarrage, est exactement ce que l'Art. 23 exige de la promotion : rien n'entre par un ajustement manuel dans Grafana, tout passe par un changement versionné qui traverse `dev` puis `test`. Tant que S03 n'est pas livrée, **les portes de S02 s'exécutent en local et font foi**, leur sortie capturée étant la definition of done — régime dégradé consigné au Sync Impact Report de la constitution, dont la sortie est fixée à l'implémentation de S03. |

**Verdict** : porte **franchie**. `Complexity Tracking` vide.

## Project Structure

### Documentation (this feature)

```text
specs/002-observabilite-de-base/
├── plan.md              # Ce fichier
├── research.md          # Phase 0
├── data-model.md        # Phase 1 — objets d'observabilité
├── quickstart.md        # Phase 1 — guide de validation
├── contracts/
│   └── metrics.md       # Contrat de la surface de métriques + provisionnement
├── checklists/
│   └── requirements.md  # Déjà produite
└── tasks.md             # Produit par /speckit-tasks
```

### Source Code (repository root)

```text
deploy/
├── prometheus/
│   └── prometheus.yml           # Jobs, `scrape_interval`, rétention (T1, T6)
├── alertmanager/
│   ├── alertmanager.yml         # Routes par gravité (T5)
│   └── templates/               # Gabarits de notification (T5)
└── grafana/
    ├── provisioning/
    │   ├── datasources/         # Datasource Prometheus (T2)
    │   └── dashboards/          # Déclaration de provisionnement (T2)
    └── dashboards/
        ├── ds-gpu.json          # `Dashboard` GPU (DCGM) (T3)
        └── ds-engines.json      # `Dashboard` moteurs (T4)

tests/
└── observability/               # T7 `[INT]` scrape du `gateway` · T8 `[TEST]` /targets · `Dashboards` · rétention
```

**Aucun fichier sous `gateway/`.** S02 ne produit **aucun code applicatif** : la consigne « labels =
ids, jamais de PII » est une règle de nommage, et le `gateway` applicatif est la spec S04 (phase 2,
M1). Voir *Arbitrages ouverts*.

**Structure Decision** : S01 a créé les répertoires **vides** ; S02 les **peuple**. Cette frontière,
posée dans les deux specs, évite que les deux se disputent les mêmes fichiers. Les `Dashboards` sont
nommés `ds-<domaine>.json` conformément à `10b`. Les JSON vivent bien sous `deploy/grafana/`, comme
l'exige le Plan d'intégration de `9g`.

## Étapes d'implémentation

Chaque étape porte l'effort de la fiche `9g` et le critère d'acceptation qu'elle sert. Somme des huit
tâches : **3.25 j-agent**, ce que `9g` arrondit en « Total ≈ 3 j-agent ». **Aucune étape ne s'ajoute à
cette liste** — le module de contrôle de libellés, qui aurait coûté ≈ 0.5 j hors budget, est écarté
(Art. 20). Toutes les étapes sont **à M0** ; aucune ne va au-delà (`9e` : « S02 complet »).

### J1 — Collecte *(admin : toutes les métriques sont scrapées et gardées 90 j · réf. `5b`)*

1. **T1** — *0.5 j* — `prometheus.yml` : **jobs + `scrape_interval`**. Six jobs — `gateway`, `node-A`
   (sglang GPU 0+1), `node-B` (sglang GPU 2), `node-C` (llama.cpp GPU 3), `dcgm-exporter`, `self` —
   avec un `scrape_interval` de **1 s pour `dcgm-exporter`, 5 s ailleurs**. Cibles internes à
   `quadra-net`, jamais un port publié sur l'hôte. → **A1** (FR-001, FR-003). *Écrire pour la majeure
   retenue en D1, pas transposer un exemple ancien.*
2. **T2** — *0.25 j* — provisionnement de la **datasource** Prometheus, depuis le dépôt. → **A2**
   (FR-011).
3. **T6** — *0.25 j* — rétention **90 jours** + rattachement du volume `promdata`. → **A3** (FR-005,
   FR-006).

### J2 — Surface *(admin : `Dashboards` GPU/moteurs auto-provisionnés, alertes routées · réf. `6e`)*

1. **T3** — *0.5 j* — `Dashboard` GPU (DCGM) versionné : température, puissance, mémoire vidéo **par
   carte**, telles que `dcgm-exporter` les expose pour chacune des cartes (**FR-004**). → **A2**
   (FR-013, FR-015).
2. **T4** — *0.5 j* — `Dashboard` moteurs versionné : TTFT, ITL, profondeur des files. → **A2**
   (FR-014, FR-015).
3. **T5** — *0.5 j* — `alertmanager.yml` : **routes par gravité + gabarits** versionnés, pour les
   alertes passées en `firing` (**FR-016**, **FR-017**). L'échec d'acheminement vers un destinataire
   injoignable reste **observable** et ne fait pas disparaître l'alerte (**FR-018**). → 4ᵉ item du
   Plan d'intégration de `9g` (« route webhook + email ») · SC-007 ; `9g` n'attache **aucun** critère
   A1–A3 au routage.

### J3 — Preuves *(mainteneur : targets up, `Dashboards` chargés · réf. `6e`)*

1. **T7** — *0.25 j* — `[INT]` Prometheus scrape le `gateway` démarré par S01. → **A1**.
2. **T8** — *0.5 j* — `[TEST]` toutes les cibles `up` dans `/targets` · une cible injoignable
   signalée `down` **avec la raison de l'échec**, sans interrompre le scrape des autres (**FR-002**) ·
   `Dashboards` chargés sur stockage Grafana vide · rétention vérifiée à 89 j et 91 j. → **A1 · A2 ·
   A3** (`9g` : « A1–A3 → T8 »).

Portes exécutées **en local** tant que S03 n'est pas livrée ; leur sortie capturée est la definition
of done (Art. 23).

## Consignes d'implémentation

- **Réapplication, pas import.** Le provisionnement doit **réappliquer** les définitions à chaque
  démarrage. Un import unique laisserait une modification manuelle survivre, ce qui contredirait
  FR-012 et l'Art. 19. C'est le point relevé en revue de la spec : à vérifier explicitement par un
  test qui modifie un `Dashboard`, redémarre, et constate le retour à la définition versionnée.
- **Libellés : identifiants seulement — une règle, pas un module.** Seuls `lane`, `alias`, `node`,
  `host`, `key_id` sont admis (`10b`) ; jamais d'identifiant de requête, de texte utilisateur ni
  d'adresse. C'est une protection contre la fuite autant que contre l'explosion de cardinalité. À M0
  la règle est **tenue par la convention et par la revue** : aucun composant n'émet encore ces
  libellés, et `9g` n'attache aucune preuve à ses consignes. Écrire ici la porte mécanique serait du
  code avant le jalon qui l'exige (Art. 20) — voir *Arbitrages ouverts*.
- **Réexposer les métriques amont telles quelles** (FR-009). Ne pas renommer pour « harmoniser » :
  ce serait un fork déguisé (Art. 6) et cela romprait la correspondance avec la documentation amont.
- **Les métriques métier n'existent pas encore.** À M0, seuls `dcgm-exporter`, les moteurs et la
  santé du `gateway` sont réellement peuplés. Les familles de S04, S05 et S08 sont scrapées dès
  qu'elles apparaissent, sans changement de `prometheus.yml` si le nommage est respecté.
- **Aucun `Dashboard` n'est créé pour des métriques inexistantes** (Art. 20) : les deux `Dashboards`
  de S02 portent sur le GPU et les moteurs, qui existent à M0.

## Arbitrages ouverts *(Art. 7, Art. 20 — consignés, non tranchés)*

Ces points ne sont pas décidables depuis les sources. Ils sont notés, **pas codés**.

- **Version d'alertmanager.** `5a` écrit « prometheus 2 · alertmanager » sans version ; la table §1 de
  `RESEARCH-STACK.md` n'en porte pas de ligne ; la *Portée* de D1 (§7) se limite à « Postgres, Redis,
  Grafana, Prometheus, Caddy, React ». Le digest à épingler (Art. 11) est **à trancher par le
  mainteneur** avant T5. Aucune valeur n'est écrite dans la table de dépendances en attendant.
- **Où vit la porte mécanique de conformité des libellés.** La consigne `9g` (« labels = ids, jamais
  de PII ») et `5c` (« Jamais de PII dans les métriques Prometheus ») imposent une **règle**. Sa
  vérification mécanique n'a pas de sujet à M0 : les libellés visés (`lane`, `alias`, `node`, `host`,
  `key_id`) sont émis par S04, S05 et S08, en M1–M2 (`9c`). Elle doit donc être rattachée à **S03**
  (porte de qualité, où elle rejoint les autres portes) ou à **S04** (première métrique métier
  émise) — jamais à S02, où elle serait du code avant le jalon qui l'exige (Art. 20) et ≈ 0.5 j hors
  des ≈ 3 j-agent de `9g`.
- **Amendement de taxonomie dû sur `10a`.** Le job de scrape et la route de notification sont
  rattachés à `Metric` et à `Alert rule`, faute d'entités correspondantes dans l'arbre de
  l'observation. S'ils doivent devenir des entités du domaine, `10a` s'amende d'abord (Art. 17,
  Art. 12) — S02 ne les crée pas de son propre chef.
- **Écarts documentaires dus** (Art. 7) : les noms de cibles `vllm-*` de `6e` sont périmés face à la
  topologie `5b` ; `10a` annonce « Constitution (22 articles) » alors que 23 sont ratifiés ; `10b`
  fixe `specs/S<nn>-<slug>.md` alors que l'Art. 23 impose le nommage Spec Kit `NNN-slug`. Aucun effet
  sur le périmètre de S02.

## Complexity Tracking

*Aucune violation. Section vide.*
