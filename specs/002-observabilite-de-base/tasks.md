---
description: "Liste de tâches — S02 Observabilité de base"
---

# Tasks: S02 — Observabilité de base

**Input**: Documents de conception de `/specs/002-observabilite-de-base/`
**Prerequisites**: `plan.md` ✅ · `spec.md` ✅ · `research.md` ✅ · `data-model.md` ✅ ·
`contracts/metrics.md` ✅ · `quickstart.md` ✅

**Tests** : **exigés** (Art. 10, Art. 8) — cycle rouge → vert, chaque critère prouvé par une tâche
`[TEST]` tracée critère → preuve. Tant que S03 n'est pas livrée, ces portes **s'exécutent en local**
et leur sortie capturée fait foi (Art. 23).

**Jalon produit** : **M0 (Alpha)** — `9e` exige « S02 complet ». Aucune tâche ne va au-delà.
**Dépend de S01** (conteneurs démarrés sur `quadra-net`).

**Effort** — somme **explicite** des huit tâches de la fiche `9g` :

| Tâche | Réf. `9g` | Charge |
| --- | --- | --- |
| T001 | T1 | 0.5 j |
| T002 | T2 | 0.25 j |
| T003 | T6 | 0.25 j |
| T004 | T3 | 0.5 j |
| T005 | T4 | 0.5 j |
| T007 | T5 | 0.5 j |
| T008 | T7 | 0.25 j |
| T009 | T8 | 0.5 j |
| **Total** | | **3.25 j-agent** |

`T006`, `T010`, `T011`, `T012` et `T013` ne portent **aucune charge additionnelle** : elles sont
absorbées par la tâche de `9g` dont elles sont le détail (colonne « Charge » de chaque ligne). Le
total reste donc **3.25 j-agent**, ce que `9g` arrondit en « Total ≈ 3 j-agent » — même somme que
celle affichée par `plan.md`.

## Format : `- [ ] T001 [P] [US1] Description avec chemin de fichier`

- **T001** : identifiant **séquentiel à trois chiffres**, sans suffixe alphabétique (format Spec Kit)
- **[P]** : parallélisable — fichiers différents, aucune dépendance sur une tâche incomplète
- **[US1]** `[US2]` : rattachement à la user story de `spec.md`, dans son ordre de priorité — **les
  tâches des phases transverses (Preuves, Polish) n'en portent aucun** : `T008`→`T013` couvrent
  plusieurs user stories à la fois (T009 prouve A1 et A3 pour US1 **et** A2 pour US2), et un
  rattachement unique y serait faux. C'est l'usage Spec Kit.
- **`[TEST]` / `[INT]`** : marqueurs de la fiche `9g`

**Identifiants** : ceux de Spec Kit, **renumérotés `T001`…`T013`**. Les `Tn` de la fiche `9g`
(T1–T8) ne sont **pas** des identifiants ici : ce sont des **références de traçabilité**, citées dans
la description et dans la table critère → preuve sous la forme « réf. `9g` T3 ». Le `S<nn>-T<n>` de
`10b` n'est pas repris — voir *Arbitrages ouverts*.

---

## Phase 1 : Setup & Foundational

**Aucune tâche — tout est assuré par S01.** Prometheus, Alertmanager, Grafana et `dcgm-exporter` sont
**déjà démarrés** sur `quadra-net` ; les répertoires de configuration existent **vides**. S02 les
**peuple** — elle ne déploie rien.

**Préalable issu de la décision D1** — voir [`RESEARCH-STACK.md`](../RESEARCH-STACK.md) §7 : le format
de `prometheus.yml` et les options de rétention ont évolué entre les majeures. Ce préalable est
**porté par T001, T002 et T003 elles-mêmes**, pas par une tâche séparée : la fiche `9g` chiffre T1 à
0.5 j et ne prévoit aucun redécoupage. ⚠️ **piège réel** : les exemples les plus répandus en ligne
portent encore sur la majeure précédente et ne s'appliquent pas.

---

## Phase 2 : User Story 1 — Collecte (Priority: P1) 🎯 MVP

**Goal** : toutes les métriques de la plateforme sont scrapées par Prometheus et conservées 90 jours.
C'est **la source unique de métriques**, posée avant tout code métier.

**Independent Test** : démarrer la pile et constater que chaque cible déclarée apparaît `up` dans
`/targets`, que `dcgm-exporter` expose ses mesures par carte, et que la conservation configurée est
bien de 90 jours — **sans qu'aucun `Dashboard` existe encore**.

### Implémentation US1

- [ ] T001 [US1] Écrire `deploy/prometheus/prometheus.yml` : les **six `job`** — `gateway`, `node-A`
      (sglang GPU 0+1), `node-B` (sglang GPU 2), `node-C` (llama.cpp GPU 3), `dcgm-exporter`, `self`
      (topologie `5b`) — avec leur `scrape_interval` : **1 s** pour `dcgm-exporter`, **5 s** pour les
      autres. Cibles internes à `quadra-net`, jamais un port publié sur l'hôte — *0.5 j* ·
      **FR-001, FR-003** · réf. `9g` T1 · écrire pour la majeure retenue en D1, pas transposer un
      exemple ancien
- [ ] T002 [P] [US1] Provisionner la **datasource** Prometheus depuis le dépôt, dans
      `deploy/grafana/provisioning/datasources/` — *0.25 j* · **FR-011** · réf. `9g` T2
- [ ] T003 [P] [US1] Configurer la **rétention 90 jours** et le rattachement du volume persistant
      `promdata`, dans `deploy/prometheus/prometheus.yml` et la définition de déploiement — *0.25 j*
      · **FR-005, FR-006** · réf. `9g` T6

**Checkpoint** : la source unique de métriques existe. Les specs ultérieures (S04, S05, S08) pourront
y publier **sans changement de `prometheus.yml`**, à condition de respecter le nommage
`quadra_<entité>_<mesure>_<unité>` (FR-008).

---

## Phase 3 : User Story 2 — Surface (Priority: P2)

**Goal** : les `Dashboards` sont provisionnés depuis le dépôt sans aucune action manuelle, et les
alertes sont acheminées par Alertmanager.

**Independent Test** : repartir d'un **stockage Grafana vide**, démarrer, et constater que les
`Dashboards` attendus sont présents et alimentés — sans aucune action dans Grafana.

### Implémentation US2

- [ ] T004 [P] [US2] Écrire le `Dashboard` GPU (DCGM) versionné
      `deploy/grafana/dashboards/ds-gpu.json` : température, puissance, mémoire vidéo **par carte** —
      *0.5 j* · **FR-013, FR-015** · réf. `9g` T3 · nommage `ds-<domaine>.json` (`10b`)
- [ ] T005 [P] [US2] Écrire le `Dashboard` moteurs versionné
      `deploy/grafana/dashboards/ds-engines.json` : TTFT, ITL, profondeur des files — *0.5 j* ·
      **FR-014, FR-015** · réf. `9g` T4
      · ⚠️ métriques amont **réexposées telles quelles**, sans renommage (Art. 6, FR-009)
- [ ] T006 [US2] Déclarer le provisionnement des `Dashboards` dans
      `deploy/grafana/provisioning/dashboards/` de sorte qu'il **réapplique** les définitions **à
      chaque démarrage** — *charge incluse dans T002 (réf. `9g` T2, plan d'intégration :
      « Provisioning Grafana (datasource + dashboards) »)* · **FR-012**
      · ⚠️ **ce n'est pas un import initial** — voir T010
- [ ] T007 [P] [US2] Écrire `deploy/alertmanager/alertmanager.yml` (routes par gravité, pour les
      alertes passées en `firing`, vers point de terminaison sortant et courriel — l'échec
      d'acheminement restant observable, sans faire disparaître l'alerte `firing`) et les gabarits de
      notification dans `deploy/alertmanager/templates/` — *0.5 j* · **FR-016, FR-017, FR-018** ·
      réf. `9g` T5
      (4ᵉ item du plan d'intégration : « route webhook + email ») · SC-007
      · ⚠️ le digest d'alertmanager à épingler (Art. 11) est **à trancher avant T007** — voir
      *Arbitrages ouverts*

**Checkpoint** : US1 **et** US2 fonctionnent. Les critères **A1**, **A2** et **A3** sont atteignables.

---

## Phase 4 : Preuves (J3)

Écrites **avant** l'implémentation de US1/US2 et **vues rouges** (Art. 10). Elles vivent sous
`tests/observability/`.

- [ ] T008 `[INT]` Vérifier dans `tests/observability/` que Prometheus scrape le `gateway` **démarré
      par S01** — *0.25 j* · **SC-001** · réf. `9g` T7
- [ ] T009 `[TEST]` Vérifier **simultanément**, dans `tests/observability/` — *0.5 j* · **FR-019** ·
      réf. `9g` T8 (« Critères → preuves : A1–A3 → T8 ») :
  - **A1** — **100 %** des cibles déclarées `up` dans `/targets` ; les 4 cartes exposent température,
    puissance et mémoire vidéo rafraîchies au moins **une fois par seconde** — **FR-004** ·
    **SC-001, SC-004** ;
  - **A1 bis, chemin `down`** — une cible rendue injoignable apparaît `down` dans `/targets` **avec
    la raison de l'échec**, et le scrape des autres cibles **n'est pas interrompu** (cas limite de
    `spec.md`) — **FR-002** ;
  - **A2** — sur **stockage Grafana vide**, les deux `Dashboards` sont présents et alimentés **sans
    action manuelle** — **SC-002** ;
  - **A3** — rétention effective : une mesure de **89 j est lisible**, une mesure de **91 j ne l'est
    plus** — **SC-003**.
- [ ] T010 `[TEST]` **Le dépôt fait autorité** — dans `tests/observability/`, modifier un `Dashboard`
      **à la main** dans Grafana, **redémarrer**, constater le **retour à la définition versionnée**
      — *charge incluse dans T009 (réf. `9g` T8)* · **SC-005**
      · ⚠️ **tâche indispensable** : un test qui vérifierait seulement la *présence* des `Dashboards`
      passerait à tort sur un simple import initial. C'est cette tâche qui distingue un
      provisionnement conforme à l'Art. 19 d'un provisionnement qui le contourne.

**Checkpoint** : part S02 du jalon **M0** atteinte.

---

## Phase 5 : Polish & Cross-Cutting

- [ ] T011 [P] `[TEST]` Rejouer les **8 scénarios** de [`quickstart.md`](./quickstart.md), dont le
      **scénario 7** (alerte portée en `firing`, routage par gravité, échec d'acheminement
      observable) et le **scénario 8** (source unique : aucun second collecteur, aucun second magasin
      de séries temporelles) — *charge incluse dans T009 (réf. `9g` T8, dont `quickstart.md` est la
      forme humaine)* · **SC-007, FR-007, FR-018**
- [ ] T012 [P] `[TEST]` Vérifier dans `tests/observability/` la persistance de `promdata` :
      arrêt/redémarrage de la pile, mesures antérieures toujours présentes — *charge incluse dans
      T003 (réf. `9g` T6)* · **FR-006**
- [ ] T013 Consigner dans `CHANGELOG.md` l'écart avec la table `5a` du document (décision **D1** :
      majeures amont retenues, `prometheus` 3.x LTS et `grafana` 13.x au lieu de « prometheus 2 » et
      « grafana 11 ») — *charge incluse dans T001 et T002, doc et changelog dans le même changement*
      · **Art. 13**

---

## Dependencies & Execution Order

### Phase Dependencies

- **S01 doit être livrée** : sans conteneurs démarrés ni répertoires de configuration, S02 n'a rien à
  peupler.
- **US1 (Phase 2)** : dépend de S01. **Bloque US2** — sans collecte, un `Dashboard` n'affiche rien.
- **US2 (Phase 3)** : dépend de US1.
- **Preuves (Phase 4)** : dépendent de US1 + US2 pour passer au vert, mais sont **écrites d'abord**.
- **Polish (Phase 5)** : dépend des phases 2 à 4.

### Within Each User Story

- **US1** : T001 d'abord (les `job`), puis T002 et T003. T003 revient sur le **même fichier** que
  T001 (`deploy/prometheus/prometheus.yml`) : elle ne s'exécute donc **jamais en même temps** que
  T001, mais bien en parallèle de T002.
- **US2** : T004, T005 et T007 en parallèle ; T006 est indissociable de la déclaration de
  provisionnement de T002.
- **T009 et T010 écrits avant** l'implémentation de US1/US2 et vus rouges.

### Parallel Opportunities

- **US1** : T002 et T003 sont `[P]` entre elles, une fois T001 écrite.
- **US2** : T004, T005 et T007 sont `[P]` — trois fichiers distincts.
- **Phase 5** : T011 et T012 sont `[P]`.

---

## Parallel Example: User Story 2

```bash
# Une fois US1 terminée, lancer les trois ensemble :
Task: "T004 — Dashboard GPU (DCGM) dans deploy/grafana/dashboards/ds-gpu.json"
Task: "T005 — Dashboard moteurs dans deploy/grafana/dashboards/ds-engines.json"
Task: "T007 — routes par gravité et gabarits dans deploy/alertmanager/"
```

---

## Traçabilité critère → preuve

| Critère du document | Critères de succès | Tâche de preuve |
| --- | --- | --- |
| A1 — toutes les cibles `up` dans `/targets` | SC-001, SC-004 | T009 `[TEST]` (réf. `9g` T8) · T008 `[INT]` (réf. `9g` T7) |
| Cible `down` signalée avec sa raison | **aucun critère de succès** — FR-002 | T009 `[TEST]` — puce « A1 bis, chemin `down` » (réf. `9g` T8) |
| Mesures GPU par carte exposées par `dcgm-exporter` | SC-004 — FR-004 | T009 `[TEST]` — puce **A1** (réf. `9g` T8) |
| A2 — `Dashboards` provisionnés automatiquement | SC-002, SC-005 | T009 `[TEST]` (réf. `9g` T8) · T010 `[TEST]` (le dépôt fait autorité) |
| A3 — rétention 90 j configurée | SC-003 | T009 `[TEST]` — 89 j / 91 j (réf. `9g` T8) |
| Routage des alertes | SC-007 | T011 `[TEST]` — scénario 7 de `quickstart.md` ; T007 en est l'objet (réf. `9g` T5), pas la preuve |
| Persistance de `promdata` | — | T012 `[TEST]` |
| Source unique de métriques | — | T011 `[TEST]` — scénario 8 |
| Consignes de `9g` (aucun `Dashboard` à la main · tout JSON versionné · `labels = ids`, jamais de PII) | **aucun critère de succès** | `9g` n'attache **aucune preuve** aux consignes (« Critères → preuves : A1–A3 → T8 ») ; T001 en est l'objet, pas la preuve |

**Aucune tâche ne prouve « labels = ids, jamais de PII ».** Le numéro SC-006 est retiré de `spec.md`
et non réattribué. À M0, **aucun composant n'émet** `lane`, `alias`, `node`, `host` ni `key_id` : ces
familles arrivent avec S04, S05 et S08 (M1–M2, `9c`). Écrire ici une porte mécanique serait du code
avant le jalon qui l'exige (Art. 20). La règle est portée par FR-010 et tenue par la convention `10b`
et par la revue (Art. 16) — voir *Arbitrages ouverts*.

---

## Implementation Strategy

### MVP d'abord (US1 seule)

1. **T001**, **T002**, **T003** → la source unique de métriques existe et conserve 90 jours.
2. **STOP et VALIDER** : scénarios 1, 2, 5 **et 6** de `quickstart.md`. Le **scénario 6**
   (persistance de `promdata`) est la 5ᵉ condition d'acceptation d'US1 et prouve **FR-006**, posé par
   T003 : US1 n'est pas validable sans lui. C'est l'issue retenue — ajouter le scénario au point
   d'arrêt — plutôt que de remonter T012 dans US1, qui aurait déplacé une tâche de la phase de
   preuves sans rien prouver de plus.
3. À ce stade, **S04, S05 et S08 peuvent déjà publier leurs métriques** — c'est la valeur réelle de
   l'US1, bien avant qu'un humain regarde un `Dashboard`.

### Livraison incrémentale

1. US1 → Prometheus scrape → les specs métier ont où publier.
2. US2 → l'observabilité devient lisible par un humain → prépare la surface de **S15**.
3. Preuves → **T009 + T010** prouvent A1, A2, A3 → part S02 du jalon **M0** atteinte.

### Stratégie parallèle

- Agent A : T001 puis T002/T003 (chemin critique US1), puis US2.
- Agent B : T009 et T010 écrits d'abord et vus rouges, pendant que l'agent A écrit US1.

---

## Notes

- **S02 configure, S01 déploie.** Aucune tâche de S02 ne modifie `deploy/docker-compose.yml`.
- **Aucun code applicatif.** Aucune tâche de S02 n'écrit sous `gateway/` : les artefacts sont
  déclaratifs (`prometheus.yml`, JSON de `Dashboard`, `alertmanager.yml` et ses gabarits,
  provisionnement Grafana). Le `gateway` applicatif est S04 (phase 2, M1).
- **Aucun `Dashboard` pour des métriques inexistantes** (Art. 20) : seulement GPU (DCGM) et moteurs,
  les seules familles réellement peuplées à M0. Les vues de requêtes, jetons et budgets viendront
  avec les specs qui les émettent.
- **Ne pas renommer les métriques amont** (Art. 6) : la convention `quadra_*` ne s'applique qu'aux
  métriques propres au projet.
- Aucune tâche de S02 ne relève des trois chemins à revue humaine (ni auth, ni facturation, ni proxy
  streaming).
- Commits atomiques et conventionnels (Art. 14) ; un `Dashboard` = un fichier = un changement,
  revuable comme du code. Portes locales avant chaque validation (Art. 23) — S02 **ne dépend pas** de
  la chaîne d'intégration, qui est S03 (`9c`).

---

## Arbitrages ouverts *(Art. 7 — consignés, non tranchés)*

- **Où vit la porte mécanique de conformité des libellés.** La consigne `9g` (« labels = ids, jamais
  de PII ») et `5c` (« Jamais de PII dans les métriques Prometheus ») imposent une **règle**, pas un
  module. Sa vérification mécanique n'a **aucun sujet à M0**. Elle doit être rattachée à **S03**
  (porte de qualité, où elle rejoint les autres portes) ou à **S04** (première métrique métier
  émise) — jamais à S02, où elle serait du code avant le jalon qui l'exige (Art. 20) et ≈ 0.5 j hors
  des ≈ 3 j-agent de `9g`. À trancher par le mainteneur.
- **Routage : deux routes simples ou routage par gravité à M0 ?** `9g` demande « route webhook +
  email ». Le routage **par gravité** (`info` · `warning` · `critical`) vient de `6f`, qui est la
  référence de **S15** (M3, `9c`). T007 suit `plan.md`, qui rattache la tâche au 4ᵉ item du plan
  d'intégration de `9g` et à SC-007. À trancher : s'en tenir aux deux routes de `9g` à M0, ou
  admettre dès maintenant la graduation de gravité de `6f`.
- **Version d'alertmanager.** `5a` écrit « prometheus 2 · alertmanager » sans version ; la *Portée* de
  D1 ne le nomme pas. Le digest à épingler (Art. 11) est **à trancher avant T007**.
- **Charge des tâches absorbées.** `9g` ne chiffre ni la déclaration de provisionnement (T006), ni le
  contrôle « le dépôt fait autorité » (T010), ni les vérifications de sortie (T011, T012), ni la
  consignation CHANGELOG (T013). Elles sont ici **absorbées** par la tâche de `9g` dont elles sont le
  détail, afin que le total reste 3.25 j-agent. À trancher si elles doivent être budgétées à part —
  ce serait un amendement de la fiche `9g`.
- **Écart documentaire sur le nommage des tâches** (Art. 7) : `10b` fixe « tâches : `S<nn>-T<n>` »,
  alors que le format Spec Kit `T001` prévaut ici — précédent de l'Art. 23, qui a déjà fait prévaloir
  le nommage `NNN-slug` sur le `feat/S09-catalog-fit` de `10b`. Amendement documentaire dû.
- **Écart documentaire sur les cibles de collecte** (Art. 7) : `6e` liste `vllm-qwen:8000`,
  `vllm-mistral:8001` et `llamacpp-gpu3:8002`, alors que T001 suit la topologie de `5b` (`node-A`
  sglang GPU 0+1 · `node-B` sglang GPU 2 · `node-C` llama.cpp GPU 3), cohérente avec `5a` qui fait
  de sglang le moteur principal. Les noms `vllm-*` sont un **état antérieur** de l'étude
  préliminaire : ils ne sont pas recopiés. Amendement documentaire dû.
