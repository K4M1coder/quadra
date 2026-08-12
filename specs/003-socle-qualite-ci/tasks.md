---
description: "Liste de tâches — S03 Socle qualité & CI"
---

# Tasks: S03 — Socle qualité & CI

**Input**: Documents de conception de `/specs/003-socle-qualite-ci/`
**Prerequisites**: `plan.md` ✅ · `spec.md` ✅ · `research.md` ✅ · `data-model.md` ✅ ·
`contracts/fake-engine.md` ✅ · `contracts/quality-gates.md` ✅ · `quickstart.md` ✅

**Tests** : **exigés** (Art. 8, Art. 10). S03 *est* l'outillage de test — ses tâches `[TEST]` sont
écrites **rouge avant** que les portes existent.

**Jalon produit** : **M0 (Alpha)** — `9e` : « S03 complet ». Aucune tâche ne dépasse cette profondeur
(Art. 7, Art. 20). **Aucune dépendance de code** — parallélisable avec S01 (ARBITRAGE 4).

**Effort total** : **10.0 j-agent** — somme explicite ci-dessous. La fiche `9h` porte
« Total ≈ 6.5 j-agent » et `9c` « ≈ 1 sem » : l'écart de **+3.5 j** est détaillé et porté en
**ARBITRAGE 7**.

| Phase | Tâches | Effort |
| --- | --- | --- |
| 1 · Setup | T001 | 0.25 j |
| 2 · US1 Fondations (P1) | T002 → T014 | 4.5 j |
| 3 · US2 Moteur factice (P2) | T015 → T019 | 2.0 j |
| 4 · US3 Chaîne (P3) | T020 → T027 | 2.75 j |
| 5 · Preuves (J4) | T028 | 0.25 j |
| 6 · Polish & Cross-Cutting | T029 | 0.25 j |
| **Total** | **29 tâches** | **10.0 j-agent** |

Détail du 0.25 + 4.5 + 2.0 + 2.75 + 0.25 + 0.25 = **10.0**.

## Format : `[ID] [P?] [Story] Description`

- **`T001`…** : identifiant **séquentiel à trois chiffres**, sans gras, sans suffixe
- **[P]** : parallélisable — **fichiers réellement différents**, aucune dépendance
- **[Story]** : `[US1]` `[US2]` `[US3]`
- **`[TEST]`** : tâche de preuve — chaque critère d'acceptation et chaque critère de succès est prouvé
  par **une** tâche `[TEST]`, jamais par une tâche d'implémentation (Art. 8)
- **`[INT]`** : tâche transverse d'intégration ou de conformité — ne prouve aucun critère à elle seule
- Chaque description porte son **chemin de fichier exact**

**Identifiants** : format Spec Kit. Les `Tn` de la fiche `9h` (T1–T10) ne sont **pas** des
identifiants ici : ils sont cités en **référence de traçabilité** (« réf. `9h` T3 »). `10b` fixe
« tâches : `S<nn>-T<n>` » — écart documentaire porté en **ARBITRAGE 8**, le format Spec Kit prévaut
(précédent : l'Art. 23 a déjà fait prévaloir le nommage `NNN-slug` sur le `feat/S09-catalog-fit` de
`10b`).

**Aucune plateforme d'intégration n'est nommée** : le fichier de définition de chaîne s'appelle
`ci.yaml` d'après `9b` ; son **emplacement** et sa **plateforme** ne sont fixés par aucune source
(ARBITRAGE 1). Aucune tâche ne désigne de forge, de répertoire de workflows, ni d'exécuteur.

---

## Phase 1 : Setup

**S03 n'a aucune dépendance externe** : elle peut démarrer avant, pendant ou après S01.

- [ ] T001 Épingler les versions d'outillage dans `pyproject.toml` et produire le verrou
      reproductible `uv.lock` — aucune dépendance sur un intervalle ouvert — *0.25 j* ·
      **Art. 11** · réf. `9h` T1

---

## Phase 2 : User Story 1 — Fondations (Priority: P1) 🎯 MVP

**Goal** : les portes locales refusent le non conforme — formatage, style, typage, secrets, message de
validation au `scope` = spec — **des deux côtés** du projet, et gardent la topologie de fusion.

**Independent Test** : sur un dépôt fraîchement cloné, tenter de valider un fichier mal formaté, un
fichier mal typé, un fichier contenant un secret en clair, un message hors convention et un message
sans `scope` de spec ; chaque tentative est refusée et le fichier en cause est identifié — **sans
qu'aucune chaîne distante existe** (régime local de l'Art. 23).

### Preuves US1 — écrites rouge d'abord (Art. 10)

- [ ] T002 [TEST] [US1] Écrire dans `tests/tooling/test_quality_gates.py` le volet **portes
      locales** : une validation est refusée pour un fichier mal formaté, du code mal typé **des deux
      versants** — plan de contrôle **et** interface —, un fichier contenant un secret en clair, un
      message de validation hors convention et un message conventionnel **sans `scope` de spec** ; le
      refus **nomme le fichier** en cause —
      *0.25 j* · **SC-001** · critère **A1** · FR-001, FR-003, FR-004, FR-005, FR-006 · réf. `9h` T10
      · ⚠️ les portes s'appliquent aux **deux versants** (FR-005, critère d'acceptation US1-AS5) :
      n'exercer que le plan de contrôle laisserait le versant interface sans aucune preuve, T012 étant
      une tâche d'implémentation.
- [ ] T003 [TEST] [US1] Compléter `tests/tooling/test_quality_gates.py` par le volet **définition
      unique et topologie** : aucun contrôle de rang 1 à 3 n'est déclaré deux fois —
      `.pre-commit-config.yaml` et `ci.yaml` **invoquent** les cibles du `Makefile` — et la garde
      refuse un commit dont la branche courante est `test` ou `master` ainsi qu'une promotion qui
      saute un maillon de `NNN-slug` → `dev` → `test` → `master` — *0.25 j* · **SC-005**, **SC-009** ·
      FR-002, FR-020, FR-029, FR-030 · Art. 14, Art. 23
      · ⚠️ **ce n'est pas un test de parité** : SC-005 exige l'équivalence par définition unique, pas
      un mécanisme de comparaison. Ce qui est vérifié est l'**absence de seconde déclaration**.

### Implémentation US1

- [ ] T004 [US1] Configurer lint, format et **typage strict** du plan de contrôle dans
      `pyproject.toml` — ruff (lint + format), mypy `--strict` — *0.5 j* · **FR-001, FR-003,
      FR-006** · réf. `9h` T1
- [ ] T005 [US1] Configurer tests et **seuils de couverture bloquants** dans `pyproject.toml` —
      pytest, pytest-asyncio, pytest-cov ; **≥ 90 %** cœur (authentification, quotas, comptabilité),
      **≥ 70 %** ailleurs, sortie **capturée** — *0.5 j* · **FR-015, FR-024** · niveau *unitaires*
      de FR-021 · réf. `9h` T2
- [ ] T006 [US1] Déclarer le contrôle de **cohérence des migrations** (`alembic check`) dans
      `pyproject.toml`, exécuté au rang 3 — donc dans l'ensemble couvert par l'équivalence locale ↔
      chaîne — *0.25 j* · **FR-028** · `9b`
      · ⚠️ à **M0 aucune migration n'existe** (le schéma arrive avec S04, `9c` jalon M1) : la porte
      **réussit à vide** et n'est **pas** neutralisée. Rattachement à S03 plutôt qu'à S04 :
      ARBITRAGE 2.
- [ ] T007 [P] [US1] Déclarer les **bases éphémères** dans `tests/conftest.py`, aux **majeures de
      production** (base relationnelle 18.x, cache 8.x — conséquence de **D1**) — *0.25 j* ·
      **FR-022** · niveau *intégration* de FR-021
      · ⚠️ tester contre une majeure antérieure ferait passer des tests qui échoueraient en production
- [ ] T008 [US1] Écrire les cibles uniformes `lint / test / e2e / build / up` dans le `Makefile` —
      **DÉFINITION UNIQUE** des portes, invoquée à l'identique en local et par la chaîne — *0.25 j* ·
      **FR-002, FR-023** · **SC-005** · `9b`
- [ ] T009 [US1] Déclarer les **portes locales** dans `.pre-commit-config.yaml` en **invoquant** les
      cibles du `Makefile` — style, format, **scan de secrets**, et convention de messages de
      validation dont le **`scope` désigne la spec** (`feat(S03): …`, graphie de `10b`) ; un message
      sans `scope` de spec est refusé par la même porte — *0.5 j* · **FR-001, FR-002, FR-004,
      FR-020** · réf. `9h` T3
- [ ] T010 [US1] Ajouter dans `.pre-commit-config.yaml` la **garde de topologie de fusion** : refus
      de toute validation dont la branche courante est `test` ou `master`, refus d'une promotion qui
      saute un maillon de `NNN-slug` → `dev` → `test` → `master` — *0.25 j* · **FR-029, FR-030** ·
      Art. 23
      · ⚠️ garde **versionnée et indépendante de toute plateforme** : elle fonctionne **aujourd'hui**,
      sans dépôt distant. Les protections de branche expriment la même règle à distance et **ne
      peuvent pas être configurées avant ARBITRAGE 1**.
- [ ] T011 [US1] Ajouter dans `.pre-commit-config.yaml` la **garde d'épinglage** : refuser tout
      référencement flottant (`:latest`, une branche, un intervalle ouvert) parmi les briques
      consommées par les étapes de `ci.yaml`, pour que le refus survienne **avant l'envoi** —
      *0.25 j* · **FR-026** · Art. 11 (« toute image, dépendance **ou action CI** EST épinglée »)
      · ⚠️ à distinguer de FR-019, qui étiquette les images **construites** : ici ce sont les briques
      **consommées**.
- [ ] T012 [P] [US1] Configurer lint, format et tests de composants de l'interface dans
      `eslint.config.js` et `ui/package.json` — eslint (flat config), prettier, vitest, playwright —
      *0.5 j* · **FR-005** · réf. `9h` T4
      · ⚠️ borne de `9h` pour `ui/` : **ces quatre outils et rien de plus**. La génération du client
      d'interface relève de **S11** (`9p` T2, jalon M2).
- [ ] T013 [P] [US1] Configurer le bout en bout et un test de fumée dans `playwright.config.ts` et
      `tests/smoke/` — *0.5 j* · niveau *bout en bout* de **FR-021** · réf. `9h` T5
- [ ] T014 [P] [US1] Documenter les commandes uniformes du `Makefile` et énoncer que le seuil de
      couverture est **nécessaire mais non suffisant** — le cycle rouge → vert reste dû pour tout
      comportement — dans la **documentation de contribution**, dont **aucune source ne fixe le
      chemin** : à ne pas inventer — *0.25 j* · **FR-023** · Art. 10 · **ARBITRAGE 3**
      · ⚠️ limite **assumée** de l'automatisation : aucune mécanique ne détecte de façon fiable des
      tests sans assertion. La nommer plutôt que la masquer.

**Checkpoint** : US1 est fonctionnelle et testable seule. C'est le MVP de S03 — dès ce point, **S01
peut être développée sous portes**, et la topologie de fusion est **gardée**, pas seulement affirmée.

---

## Phase 3 : User Story 2 — Moteur factice (Priority: P2)

**Goal** : un moteur d'inférence simulé permet de tester **tout le plan de contrôle sans GPU**, avec
latence et erreurs choisies.

**Independent Test** : sur une machine sans GPU, démarrer le moteur factice, obtenir une réponse en
flux, imposer une latence, injecter une erreur, demander une représentation vectorielle — chaque
comportement est celui demandé.

> **US2 est indépendante de US1** : le moteur factice ne dépend d'aucune porte. Deux agents peuvent
> travailler en parallèle dès le départ.

### Preuve US2 — écrite rouge d'abord (Art. 10)

- [ ] T015 [TEST] [US2] Écrire `tests/tooling/test_fake_engine.py` — sur une machine **sans GPU** :
      réponse **jeton par jeton** au format d'un moteur réel, **latence de premier jeton** et
      **latence inter-jetons** imposées et respectées, **erreur injectée** fidèlement reproduite,
      **représentation vectorielle** au format attendu ; et **aucun second simulateur** du contrat
      d'inférence dans le dépôt (recherche automatisée) — *0.5 j* · **SC-003** · critère **A3** ·
      FR-007 à FR-012 · Art. 19 · réf. `9h` T10

### Implémentation US2

- [ ] T016 [US2] Créer le **paquet distribuable** `packages/fake-engine/pyproject.toml` — publiable
      et versionné indépendamment — *0.25 j* · **FR-012**
      · ⚠️ **paquet avec son propre manifeste**, pas un module dans `tests/` : il est installé comme
      dépendance de test par S04 à S20 (Art. 19). Un fichier copié divergerait entre specs et
      invaliderait toute la pyramide.
- [ ] T017 [US2] Implémenter la surface d'inférence dans
      `packages/fake-engine/src/fake_engine/server.py` — complétion conversationnelle et **flux
      jeton par jeton** au format d'un moteur réel — *0.75 j* · **FR-007, FR-008** · réf. `9h` T6
- [ ] T018 [P] [US2] Implémenter les paramètres de simulation dans
      `packages/fake-engine/src/fake_engine/control.py` — **latence du premier jeton**, **latence
      inter-jetons**, **injection d'erreur**, réglables **par test** et non globalement — *0.25 j* ·
      **FR-009, FR-010** · réf. `9h` T7
- [ ] T019 [P] [US2] Implémenter les **représentations vectorielles** dans
      `packages/fake-engine/src/fake_engine/embeddings.py` — *0.25 j* · **FR-011** · réf. `9h` T7

**Checkpoint** : US2 fonctionne seule. **S04 à S07 peuvent désormais écrire leurs tests
d'intégration**, même si les portes de US1 ne sont pas finies.

---

## Phase 4 : User Story 3 — Chaîne d'intégration (Priority: P3)

**Goal** : la chaîne rejoue toutes les portes **dans l'ordre**, **bout en bout et charge** compris,
bloque la fusion dès qu'une seule est rouge, et n'est elle-même construite que de briques épinglées.

**Independent Test** : soumettre un changement conforme, un changement sous les seuils de couverture,
un changement introduisant une dépendance vulnérable, puis un changement dont un scénario de charge
échoue — seule la première soumission est acceptée.

### Preuves US3 — écrites rouge d'abord (Art. 10)

- [ ] T020 [TEST] [US3] Compléter `tests/tooling/test_quality_gates.py` par le volet **chaîne** : les
      **six étapes s'exécutent dans l'ordre** imposé — style et formatage → typage → tests et
      couverture → contrôles de sécurité → construction des images → bout en bout **et charge** —,
      l'ordre effectif étant **asserté et non supposé** ; la chaîne échoue et **bloque la fusion** sous
      **90 %** (cœur) ou **70 %** (hors cœur) avec la valeur mesurée en sortie capturée ; **100 %** de
      ses étapes s'exécutent sans accéder à un GPU ; une dépendance affectée par une vulnérabilité
      connue la fait échouer **en nommant** la dépendance ; des **migrations incohérentes** avec le
      schéma déclaré la font échouer **en nommant l'incohérence** — *0.25 j* · **SC-002, SC-004,
      SC-006** · critère **A2** · FR-013, FR-014, FR-015, FR-016, FR-018, FR-028 · réf. `9h` T10
      · ⚠️ l'**ordre** des portes (FR-013, critère d'acceptation US3-AS1) et la **cohérence des
      migrations** (FR-028, critère d'acceptation US3-AS10) sont assertés **ici** : T022 et T026 sont
      des tâches d'implémentation, et le scénario 6 de `quickstart.md` — rejoué par T029 `[INT]` — ne
      se substitue à aucune tâche `[TEST]`.
- [ ] T021 [TEST] [US3] Compléter `tests/tooling/test_quality_gates.py` par le volet **dernier
      maillon et épinglage** : l'environnement éphémère est **entièrement détruit** — aucune
      ressource résiduelle entre deux exécutions ; un scénario de **charge** en échec fait échouer la
      chaîne et bloque la fusion ; **100 %** des actions, outils et images consommés par les étapes
      sont épinglés par tag exact ou empreinte, et un référencement flottant introduit délibérément
      fait échouer la chaîne — *0.25 j* · **SC-007, SC-010, SC-011** · FR-017, FR-026, FR-027

### Implémentation US3

- [ ] T022 [US3] Écrire les **cinq premières étapes** de la chaîne dans `ci.yaml`, dans l'ordre
      imposé — style et formatage → **typage** → tests et couverture (dont la **cohérence des
      migrations**) → **contrôles de sécurité** (analyse statique, audits de dépendances) →
      construction des images —, chaque étape **invoquant** une cible du `Makefile` au lieu de
      redéclarer un contrôle — *0.5 j* · **FR-013, FR-014, FR-018, FR-028** · réf. `9h` T8
      · ⚠️ **emplacement et plateforme non fixés** (ARBITRAGE 1) : le nom `ci.yaml` vient de `9b`,
      rien d'autre. Une étape qui redéclare un contrôle est un **constat de revue** (Art. 16) — c'est
      là que la divergence redeviendrait possible.
- [ ] T023 [US3] Étiqueter dans `ci.yaml` les images **construites** de façon reproductible —
      **version sémantique + empreinte du contenu** — pour rendre le retour arrière possible par
      simple ré-étiquetage — *0.25 j* · **FR-019** · Art. 11
      · consommées par **S01**
- [ ] T024 [US3] Épingler dans `ci.yaml` **toutes les briques consommées** par ses étapes — actions,
      outils, images de base — par tag exact ou empreinte ; jamais `:latest`, jamais une branche,
      jamais un intervalle ouvert, et faire échouer la chaîne sur un référencement flottant —
      *0.25 j* · **FR-026** · **SC-011** · Art. 11
      · même règle que la garde locale T011, exprimée en **étape** : le refus doit survenir aux deux
      endroits
- [ ] T025 [US3] Garantir dans `ci.yaml` qu'**aucune étape** ne dispose d'un GPU — l'environnement
      d'exécution n'en comporte pas — *0.25 j* · **FR-016** · Art. 8
      · ⚠️ trois exigences du projet **échappent donc à la chaîne** et sont prouvées au canari :
      découverte de topologie matérielle (**S06** SC-001), calibration du verdict de `fit` (**S09**
      SC-001), débit additionné sur deux `host` (**S20** SC-001) — à dire dans les plans concernés
      plutôt qu'à croire couvert ici
- [ ] T026 [US3] Ajouter dans `ci.yaml` la **sixième étape**, porte **unique** : parcours de **bout
      en bout ET charge** sur un **environnement éphémère complet** associé au moteur factice,
      **détruit en fin d'exécution** ; l'échec du volet de charge fait échouer la chaîne au même
      titre qu'un test unitaire rouge — *0.75 j* · **FR-013, FR-017, FR-027** · Art. 8 porte 4 ·
      `9b` « e2e + k6 » · réf. `9h` T9
      · ⚠️ **une seule** étape, **un seul** environnement éphémère : il n'existe pas d'étape de charge
      séparée, et il n'existe pas de charge sans porte
- [ ] T027 [P] [US3] Poser dans `k6/<lane>-<scénario>.js` le **minimum de scénario de charge qui
      prouve la porte** — graphie fixée par `10b` — *0.25 j* · **FR-027** · **SC-010** · niveau
      *charge* de FR-021
      · ⚠️ **S21** versionne les scénarios de charge métier et les rejoue **sans en créer un second
      jeu** (Art. 19, jalon M4). S03 n'écrit ici que ce qui rend la porte opposable.

**Checkpoint** : les trois user stories fonctionnent. La definition of done devient **mécanique**, et
la livraison de S03 clôt le **régime dégradé** consigné dans la constitution (FR-030, Art. 23).

---

## Phase 5 : Preuves (J4)

**Purpose** : prouver le dernier critère de succès que les phases 2 à 4 ne portent pas.

- [ ] T028 [TEST] Compléter `tests/tooling/test_quality_gates.py` par le volet **definition of
      done** : les quatre points du contrat — style et typage propres, tests écrits et verts,
      couverture au seuil, contrat d'interface inchangé ou versionné — sont décidables à partir des
      **seules sorties capturées** des cibles du `Makefile`, **sans jugement humain** — *0.25 j* ·
      **SC-008** · FR-024, FR-025 · [`contracts/quality-gates.md`](./contracts/quality-gates.md)

**Checkpoint** : part S03 du jalon **M0** atteinte — `9e` : « S03 complet ».

---

## Phase 6 : Polish & Cross-Cutting

- [ ] T029 [INT] Rejouer les **12 scénarios** de [`quickstart.md`](./quickstart.md) et **capturer les
      sorties** — un chiffre annoncé sans sortie capturée est une opinion (Art. 4, Art. 10) —
      *0.25 j*
      · tâche de conformité : elle ne se substitue à aucune tâche `[TEST]` ci-dessus

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** : T001 précède T004 à T006.
- **US1 (Phase 2)** : aucune dépendance externe.
- **US2 (Phase 3)** : **indépendante de US1** — le moteur factice ne dépend d'aucune porte.
- **US3 (Phase 4)** : dépend de **US1 et US2** — la chaîne **invoque** les cibles du `Makefile`
  posées en US1 et sa sixième étape consomme le moteur factice de US2.
- **Preuves (Phase 5)** : dépend de US1 + US2 + US3.
- **Polish (Phase 6)** : dépend de tout ce qui précède.

### Within Each User Story

- Les tâches `[TEST]` de chaque story sont écrites **avant** l'implémentation correspondante et
  **vues rouges** (Art. 10) : T002 et T003 avant T004→T014 ; T015 avant T016→T019 ; T020 et T021
  avant T022→T027.
- **US1** : T004 → T005 → T006 (même fichier `pyproject.toml`) ; T008 avant T009 (la
  `.pre-commit-config.yaml` invoque les cibles) ; T009 → T010 → T011 (même fichier
  `.pre-commit-config.yaml`) ; T007, T012, T013, T014 en parallèle.
- **US2** : T016 → T017 (le paquet avant sa surface), puis T018 et T019 en parallèle.
- **US3** : T022 → T023 → T024 → T025 → T026 (**même fichier** `ci.yaml`) ; T027 en parallèle.

### Parallel Opportunities

- **Entre stories** : **US1 et US2 en parallèle dès le départ** — deux agents, aucun fichier commun.
  C'est la principale opportunité de la spec.
- **US1** : T007 (`tests/conftest.py`), T012 (`eslint.config.js`, `ui/package.json`), T013
  (`playwright.config.ts`, `tests/smoke/`) et T014 (documentation de contribution) sont `[P]`. T004,
  T005 et T006 touchent tous `pyproject.toml`, T009 à T011 tous `.pre-commit-config.yaml` — **non
  `[P]`**.
- **US2** : T018 et T019 sont `[P]` — deux fichiers distincts du paquet.
- **US3** : T027 est `[P]` (`k6/<lane>-<scénario>.js`) ; T022 à T026 éditent `ci.yaml` — **non
  `[P]`**.
- Les tâches `[TEST]` T002, T003, T020, T021 et T028 écrivent toutes dans
  `tests/tooling/test_quality_gates.py` — **non `[P]`** entre elles.

---

## Parallel Example: démarrage à deux agents

```bash
# Dès le premier jour, deux pistes totalement disjointes :
Agent A — Task: "T002 → T003 (rouge), puis T004 → T014 : portes locales et gardes"
Agent B — Task: "T015 (rouge), puis T016 → T019 : moteur factice dans packages/fake-engine/"

# Puis, au sein de US1 :
Task: "T012 — lint et tests de composants de l'interface (eslint.config.js, ui/package.json)"
Task: "T013 — bout en bout et fumée (playwright.config.ts, tests/smoke/)"
```

---

## Traçabilité critère → preuve

Une ligne par critère, **une seule** tâche `[TEST]` par ligne (Art. 8). Les `Tn` cités entre
parenthèses sont des **références de traçabilité** vers la fiche `9h`, pas des identifiants.

| Critère ou exigence | Source | Critère de succès | Tâche de preuve |
| --- | --- | --- | --- |
| **A1** — une porte locale refuse un fichier non conforme | `9h` | SC-001 | T002 *(réf. `9h` T10)* |
| **A2** — chaîne rouge sous les seuils de couverture | `9h` | SC-002 | T020 *(réf. `9h` T10)* |
| **A3** — moteur factice : flux, latence, erreurs | `9h` | SC-003 | T015 *(réf. `9h` T10)* |
| Consigne « la CI ne touche jamais un GPU » | `9h` · Art. 8 | SC-004 | T020 |
| Équivalence locale ↔ chaîne par **définition unique** | Art. 14 | SC-005 | T003 |
| Sécurité continue — la dépendance est **nommée** | Art. 21 | SC-006 | T020 |
| Environnement éphémère **entièrement détruit** | FR-017 | SC-007 | T021 |
| Definition of done **mécanique**, sans jugement humain | Art. 8 | SC-008 | T028 |
| **Topologie de fusion** gardée — aucun commit direct sur `test` ni `master` | Art. 23 | SC-009 | T003 |
| La **charge** est une porte, pas une mesure indicative | Art. 8 porte 4 · `9b` | SC-010 | T021 |
| Épinglage des briques **consommées** par la chaîne | Art. 11 | SC-011 | T021 |
| Unicité du moteur factice | Art. 19 · FR-012 | — *(aucun SC dédié)* | T015 |
| Portes appliquées aux **deux versants** (US1-AS5) | FR-005 | — *(aucun SC dédié)* | T002 |
| **Ordre** des six étapes de la chaîne (US3-AS1) | FR-013 · Art. 8 | — *(aucun SC dédié)* | T020 |
| Cohérence des migrations (US3-AS10) | `9b` · FR-028 | — *(aucun SC dédié)* | T020 |

**Exigences postérieures au document** — FR-026, FR-027, FR-028, FR-029, FR-030 n'ont **aucun critère
dans `9h`** : elles viennent de l'Art. 11, de l'Art. 8 porte 4 (avec `9b`), de `9b` et de l'Art. 23.
Elles se rattachent à leur source, jamais à un critère inventé.

| Exigence | Source | Implémentation | Preuve |
| --- | --- | --- | --- |
| FR-026 épinglage de la définition de chaîne | Art. 11 | T011 (garde locale) · T024 (étape) | T021 · SC-011 |
| FR-027 la charge est une porte | Art. 8 porte 4 · `9b` | T026 · T027 | T021 · SC-010 |
| FR-028 cohérence des migrations | `9b` « `alembic check` » | T006 (déclaration) · T022 (étape) | T020 · ARBITRAGE 2 |
| FR-029 / FR-030 topologie et exclusivité | Art. 23 | T010 (garde locale) | T003 · SC-009 |

---

## Implementation Strategy

### MVP d'abord — mais deux MVP en parallèle

S03 est la seule spec du projet dont **deux user stories sont indépendantes dès le départ**. La
stratégie optimale n'est donc pas séquentielle :

1. **Agent A → US1** : dès T009, **S01 peut être développée sous portes** ; dès T010, la topologie de
   fusion est gardée sans dépôt distant.
2. **Agent B → US2** : dès T019, **S04 à S07 peuvent écrire leurs tests d'intégration**.
3. Les deux convergent sur **US3**, qui a besoin des deux.

### Livraison incrémentale

1. **US1** → les portes locales protègent tout changement ultérieur et **font foi seules** tant que la
   chaîne n'existe pas (Art. 23).
2. **US2** → la pyramide de tests devient possible **sans GPU**.
3. **US3** → la chaîne rend la definition of done mécanique → **délégation aux agents possible**, et
   la charge comme l'épinglage deviennent opposables.
4. **Phase 5** → SC-008 prouvé → part S03 du jalon **M0** atteinte.

---

## Notes

- **S03 ne contient aucun test métier** — seulement l'outillage qui les rend possibles (Art. 20). La
  matrice de permissions vient de **S13** (M2), les scénarios de charge métier de **S21** (M4), la
  **génération du client d'interface de S11** (`9p` T2, M2) : aucune de ces tâches n'est ici.
- **Cinq des neuf niveaux de la pyramide sont posés à M0** (FR-021) : unitaires (T005), intégration
  sur bases éphémères (T007), bout en bout (T013, T026), charge (T027), sécurité (T022). Les quatre
  autres sont rendus exécutables par les specs qui les produisent — contrat → **S04** (M1) · fichiers
  de référence → **S08** (M2) · tests générés depuis une source unique → **S13** (M2) · résilience →
  **S19**, **S20**, **S21** (M4). S03 ne préempte ni leur outillage ni leurs jeux d'essai.
- **Les trois chemins à revue humaine** — **authentification**, **facturation**, **proxy de flux** —
  sont nommés par l'Art. 8 comme des **chemins**, pas comme des specs. S03 fournit le **mécanisme** :
  la revue est une étape visible et tracée du processus, jamais une politesse. **Aucune liste de specs
  n'est figée ici** — chaque spec qui touche l'un de ces chemins porte la revue **en plus** des portes
  mécaniques. `9d` en donne un cas explicite (« revue humaine sur S04 ») et nomme par ailleurs la
  revue humaine des permissions (**S13**), qui s'ajoute sans être l'un des trois chemins.
- **Le seuil de couverture bloque, mais ne prouve pas que les tests assertent.** T014 le dit
  explicitement dans la documentation de contribution ; le cycle rouge → vert reste dû pour tout
  comportement (Art. 10).
- **Trois épinglages distincts, à ne pas confondre** : les **dépendances** par le verrou reproductible
  (T001) · les images **construites** par version + empreinte (T023, FR-019) · les briques
  **consommées** par la chaîne par tag exact ou empreinte (T011, T024, FR-026).
- Commits atomiques et conventionnels au **`scope` = spec** (Art. 14, `10b`) ; la configuration des
  portes étant versionnée, toute désactivation — y compris celle d'une garde de topologie ou
  d'épinglage — se lit en revue (Art. 16).

---

## Arbitrages

Les **huit** arbitrages ouverts sont consignés dans [`spec.md`](./spec.md), registre unique, et ne
sont pas dupliqués ici (Art. 19). Ne figurent ci-dessous que ceux qui ont une **incidence sur ce
fichier** — dont les arbitrages **7** et **8**, propres au découpage en tâches, et dont ce fichier
porte le détail chiffré.

| Arbitrage | Incidence sur ce fichier |
| --- | --- |
| **1 — forge et exécuteur** | Aucune tâche ne nomme de plateforme, de répertoire de workflows ni d'exécuteur. `ci.yaml` est nommé d'après `9b` ; son emplacement suit la forge qui sera choisie. La topologie est outillée par la **garde locale** T010 ; les protections de branche restent une exigence non configurée. |
| **2 — `alembic check` : S03 ou S04 ?** | T006 et le volet correspondant de T022 sortent du fichier si l'arbitrage reporte la porte à S04. |
| **3 — chemin du guide du contributeur** | T014 porte le travail **sans chemin fixé** : `10b` ne prévoit à la racine que `CONSTITUTION.md`, `CHANGELOG.md` et `runbooks/<incident>.md`. Le `docs/CONTRIBUTING.md` de la version précédente de ce fichier était une **invention d'implémentation**, retirée. À normaliser par amendement de `10b`. |
| **4 — FR-017 et la dépendance à S01** | T026 consomme la définition d'environnement de S01, alors que `9c` donne S03 « Dépend de : — ». Aucune seconde définition d'environnement n'est créée ici (Art. 19). |
| **7 — écart d'effort : 10.0 j contre ≈ 6.5 j** | La fiche `9h` porte « Total ≈ 6.5 j-agent » et `9c` « ≈ 1 sem ». L'écart de **+3.5 j** se réconcilie **exactement**, dans les deux sens : **+0.25** verrou reproductible T001, que la fiche ne détaille pas · **+2.75** **onze** tâches neuves à 0.25 j, postérieures ou latérales à la fiche — T006 `alembic check`, T007 bases éphémères, T008 `Makefile` comme définition unique, T010 garde de topologie, T011 et T024 gardes d'épinglage, T014 documentation de contribution, T016 paquet du moteur factice, T023 étiquetage des images construites, T025 absence de GPU, T027 minimum de charge · **+1.25** preuves portées de 0.5 j (`9h` T10 seul) à 1.75 j pour couvrir **onze** critères de succès au lieu de trois (T002, T003, T015, T020, T021, T028) · **−0.75** deux tâches **moins** chères que la fiche (`9h` T8 1.0 j → T022 0.5 j ; `9h` T9 1.0 j → T026 0.75 j). Soit 0.25 + 2.75 + 1.25 − 0.75 = **+3.5 j**. T029 (`[INT]`, 0.25 j) n'impute aucune exigence nouvelle — c'est le rejeu de `quickstart.md` — et tient dans l'arrondi du « ≈ » de la fiche : elle n'est donc pas imputée. Le mainteneur doit trancher : amender la fiche `9h` et `9c`, ou réduire le périmètre — la profondeur M0 ne bouge pas (Art. 7, Art. 20). |
| **8 — `10b` fixe « tâches : `S<nn>-T<n>` »** | Les identifiants de ce fichier sont au format Spec Kit (`T001`…), qui prévaut (précédent de l'Art. 23 sur `feat/S09-catalog-fit`). Écart documentaire à corriger par amendement de `10b` (Art. 7, Art. 12) ; les `Tn` de `9h` restent cités en **référence de traçabilité**. |
