---
description: "Liste de tâches — S01 Socle compose + moteurs + Caddy"
---

# Tasks: S01 — Socle compose + moteurs + Caddy

**Input**: Documents de conception de `/specs/001-socle-compose-moteurs-caddy/`
**Prerequisites**: `plan.md` ✅ · `spec.md` ✅ · `research.md` ✅ · `data-model.md` ✅ ·
`contracts/routes.md` ✅ · `quickstart.md` ✅

**Tests** : **exigés**, non optionnels. L'Art. 10 impose le cycle rouge → vert pour tout
comportement, et l'Art. 8 exige que chaque critère d'acceptation soit prouvé par une tâche `[TEST]`
tracée critère → preuve — jamais par une tâche d'implémentation.

**Jalon produit** : **M0 (Alpha)** — `9e` exige « **S01 complet** », donc la profondeur **J1 → J4** et
rien au-delà (Art. 7, Art. 20). **Dépendances** : aucune — `9c` donne S01 « **Dépend de : —** ».
Les portes s'exécutent **en local** et leur sortie capturée EST la definition of done (Art. 23) :
aucune tâche de cette liste n'attend un outillage livré par une autre spec.

**Effort** : **7.75 j-agent** — 5.5 j pour les dix étapes de la fiche `9f` (9 × 0.5 j + 1 j) et
**2.25 j pour les sept tâches que la fiche ne porte pas**. Voir § *Arbitrages ouverts*, écart nº 1.

## Format : `- [ ] T001 [P] [US1] Description avec chemin de fichier`

- **`T001`…`T017`** : identifiants **Spec Kit**, séquentiels à trois chiffres, sans gras, sans
  suffixe alphabétique
- **[P]** : parallélisable — fichiers différents, aucune dépendance sur une tâche incomplète
- **[Story]** : `[US1]` `[US2]` `[US3]` — rattachement à la user story de `spec.md`
- **`[TEST]` / `[INT]`** : tâche de preuve / tâche d'intégration
- Chaque description porte son **chemin de fichier exact**

**Identifiants et références.** Les `T1`…`T10` de la fiche `9f` ne sont **pas** des identifiants de
tâches : ce sont des **références de traçabilité**, citées « réf. `9f` T3 » dans la description ou
dans la table critère → preuve. Les seuls identifiants sont ceux de cette liste, au format Spec Kit
(D-A4 ; précédent de l'Art. 23, qui a déjà fait prévaloir le nommage Spec Kit sur celui de `10b`).
`10b` fixe `S<nn>-T<n>` pour les tâches : **écart documentaire**, signalé au § *Arbitrages ouverts*,
jamais reproduit.

---

## Phase 1 : Setup & Foundational

**S01 *est* la phase de fondation du projet entier.** Les phases « Setup » et « Foundational » du
gabarit sont donc **assurées par la user story US1** ci-dessous, et non dupliquées ici.

**Préalable non livrable** (vérification d'environnement, pas une tâche de code) : la machine hôte
porte **la combinaison validée** pilote GPU 560 / CUDA 12.6 / toolkit conteneur — décision **D2**,
voir [`RESEARCH-STACK.md`](../RESEARCH-STACK.md) §7. Une combinaison différente invalide les
scénarios GPU de `quickstart.md`.

---

## Phase 2 : User Story 1 — Fondations (Priority: P1) 🎯 MVP · jalon interne J1

**Goal** : un développeur clone le dépôt, comprend l'arborescence, trouve les fichiers de gouvernance
à la racine, et démarre les bases de données sans connaître le reste de la plateforme.

**Independent Test** : sur une machine vierge **sans GPU**, cloner puis démarrer les services de
données ; base relationnelle et cache atteignent l'état sain, les données persistent dans des volumes
nommés.

### Implémentation US1

- [ ] T001 [US1] Créer l'arborescence de premier niveau (`gateway/`, `ui/`, `deploy/`, `docs/`),
      `README.md` décrivant le rôle de chaque répertoire et la commande d'amorçage, **`CONSTITUTION.md`**
      — copie de référence régénérée depuis `.specify/memory/constitution.md`, même version que sa
      source, jamais éditée directement (Art. 19) — et **`CHANGELOG.md`** au format Keep a Changelog +
      SemVer — *0.5 j* · **FR-001, FR-002, FR-019, FR-020** · réf. `9f` T1, étendue aux deux fichiers de
      racine par `plan.md` (précision 3) : racine imposée par `10b`, livraison confiée à S01 par le
      § Governance de la constitution. L'**entrée de changelog** qui livre S01 n'est pas écrite ici mais
      dans le changement de livraison (T017, Art. 13).
- [ ] T002 [US1] Déclarer dans `deploy/docker-compose.yml` le réseau interne **`quadra-net`** et les
      **quatre volumes nommés, distincts par usage** : **`pgdata`** (données relationnelles),
      **`promdata`** (métriques, rétention 90 j configurée par S02), **`/data/models`** (NVMe 1,8 To,
      alimenté par S10 — téléchargements et `checksum`) et **`/data/offload`** (400 Go, `offload`
      **opt-in**, S18) — *0.25 j* · **FR-004** · graphie de `5b` employée telle quelle (Art. 12)
      · ⚠️ **aucune étape de la fiche `9f` ne porte cette tâche** — `9f` T2 ne nomme aucun volume ;
      `5b` et FR-004 en exigent quatre (écart nº 2 des *Arbitrages ouverts*)
      · ⚠️ **réserve de l'Art. 20** sur `/data/offload` (voir `plan.md`, Constitution Check) : à lever
      par arbitrage du mainteneur **avant** de déclarer ce volume
- [ ] T003 [US1] Déclarer la base relationnelle et le cache dans `deploy/docker-compose.yml` —
      attachés à `quadra-net`, **aucun port publié**, montage de `pgdata`, **sondes de santé** — et
      amorcer `deploy/digests.yml`, source unique composant → digest (Art. 19) — *0.5 j*
      · **FR-003, FR-004, FR-012** · réf. `9f` T2 · versions **amont** (Postgres 18.x, Redis 8.x)
      épinglées **par digest**, décision **D1**

**Checkpoint** : US1 est fonctionnelle et testable seule, sans GPU. C'est le MVP de S01. Scénario 1 de
[`quickstart.md`](./quickstart.md).

---

## Phase 3 : User Story 2 — Cœur (Priority: P2) · jalon interne J2

**Goal** : l'administrateur exécute **une commande unique** et obtient la plateforme complète —
moteurs, observabilité, TLS.

**Independent Test** : sur la machine de référence à 4 GPUs, lancer la commande de démarrage et
constater que tous les services deviennent sains **en moins de 5 minutes**, que le point d'entrée TLS
répond, et que **parmi les ports des services de la pile, seul 443 sort de `quadra-net`**.

### Implémentation US2

- [ ] T004 [US2] Déclarer les deux moteurs d'inférence (`sglang`, `llama.cpp`) dans
      `deploy/docker-compose.yml` — attachés à `quadra-net`, **sans aucun port publié**, montant
      `/data/models`, **épinglés par digest exact** dans `deploy/digests.yml` — *0.5 j*
      · **FR-006, FR-007, FR-012** · réf. `9f` T3
      · ⚠️ **la version des moteurs n'est fixée par aucune décision de la veille** : la **portée de D1**
      (`RESEARCH-STACK.md` §7) nomme limitativement Postgres, Redis, Grafana, Prometheus, Caddy et
      React et dit « **ne s'applique pas** […] aux moteurs d'inférence, dont la version reste celle
      validée par le banc » ; **D2** porte sur le couple pilote/CUDA **de l'hôte**, pas sur les moteurs.
      Les versions retenues (sglang 0.5.x, llama.cpp b4102) sont celles du banc, et le **tag
      `llama.cpp b4102` est « à revérifier »** (`RESEARCH-STACK.md` §1) — à vérifier **avant**
      l'épinglage, sous peine de rendre FR-013 vrai au premier démarrage
- [ ] T005 [US2] Déclarer la chaîne d'observabilité dans `deploy/docker-compose.yml` — `prometheus`,
      `alertmanager`, `grafana`, `dcgm-exporter`, sans port publié, `promdata` monté par `prometheus` —
      et créer les répertoires de configuration **vides** `deploy/prometheus/`,
      `deploy/alertmanager/`, `deploy/grafana/` — *0.5 j* · **FR-004, FR-011** · réf. `9f` T4
      · ⚠️ **contenu peuplé par S02**, pas ici
      · ⚠️ **bloquée à la clôture** : la version de `dcgm-exporter` n'est pas sourcée et FR-012 vaut
      pour *toute* image (écart nº 5 des *Arbitrages ouverts*)
- [ ] T006 [US2] Déclarer le service **`caddy`** dans `deploy/docker-compose.yml` — **seul service qui
      publie un port sur l'hôte, et un seul : 443** — **et** écrire `deploy/Caddyfile` : TLS
      automatique et acheminement des quatre routes publiées `/v1` (inférence), `/api`
      (administration), `/ws` (temps réel) et `/grafana` (tableaux de bord) — *0.5 j*
      · **FR-006, FR-008** · réf. `9f` T5, **étendue au service `caddy` par `plan.md`** (précision 1) :
      `9f` énumère `caddy` parmi les services de `docker-compose.yml` mais aucune de ses tâches ne le
      déclare, et le port publié 443 — critère A2 — est une propriété du **service**, pas du fichier de
      configuration · voir [`contracts/routes.md`](./contracts/routes.md) contrats 1 et 2
- [ ] T007 [US2] Ajouter sondes de santé, dépendances de démarrage et politiques de redémarrage sur
      **tous** les services de `deploy/docker-compose.yml` — *0.5 j* · **FR-009, FR-010** · réf. `9f` T6
      · dépend de T003, T004, T005, T006

**Checkpoint** : US1 **et** US2 fonctionnent. Les critères **A1** et **A2** sont atteignables ; leur
preuve est T011. Scénarios 2, 3 et 6 de [`quickstart.md`](./quickstart.md).

---

## Phase 4 : User Story 3 — Surface (Priority: P3) · jalon interne J3

**Goal** : l'administrateur configure par un fichier unique dont chaque variable est documentée, et
suit une procédure écrite qui le mène de la machine vierge à la pile saine.

**Independent Test** : donner à une personne n'ayant jamais vu le projet la seule documentation
d'installation, et constater qu'elle atteint la pile saine **sans poser de question**.

### Implémentation US3

- [ ] T008 [US3] Écrire `deploy/.env.example` exhaustif — **chaque variable nommée en UPPER_SNAKE et
      préfixée `QUADRA_`** (convention `10b`, aucun autre espace de noms), documentée, avec sa valeur
      par défaut quand elle existe et des valeurs **factices explicitement marquées** pour les secrets
      (Art. 21) — **et** le validateur de configuration au démarrage dans `gateway/config/settings.py`,
      qui interrompt le démarrage en nommant **la variable fautive et la correction attendue** et ne
      laisse **aucun service démarré** — *0.5 j* · **FR-014, FR-015** · réf. `9f` T7
      · ⚠️ **aucun délai chiffré** n'est exigé et aucun n'est inventé : aucune source n'en fixe un
      (`spec.md` SC-006, `plan.md` § Performance Goals)
      · ⚠️ **Art. 19** : ce validateur est **partagé avec S04**. Ne pas écrire un second validateur
      en script de déploiement.
- [ ] T009 [P] [US3] Écrire le `Makefile` racine : cibles `up`, `down`, `logs`, `ps` — la cible `up`
      **est** la commande unique de démarrage de la pile, et la cible de redémarrage sur laquelle
      repose le retour arrière en **une seule commande**, sans reconstruction d'image — *0.5 j*
      · **FR-005, FR-016, FR-021** · réf. `9f` T8
- [ ] T010 [P] [US3] Écrire `docs/install.md` : machine vierge → pile saine, sans connaissance
      implicite, **y compris la procédure de retour arrière** — re-pointer dans `deploy/digests.yml`,
      **et lui seul**, le digest précédemment épinglé, puis redémarrer par une seule commande —
      *0.5 j* · **FR-017, FR-021** · réf. `9f` T9 · réf. `w10` (« rollback = re-pointer le tag
      précédent, 1 commande »), exprimé en digests conformément à `research.md` D-S01-2
      · **Art. 13** — livré dans le même changement, pas après

**Checkpoint** : les trois user stories sont fonctionnelles indépendamment. Scénarios 5 et 8 de
[`quickstart.md`](./quickstart.md).

---

## Phase 5 : Preuves et clôture (J4)

**Purpose** : prouver mécaniquement chaque critère de succès par une tâche `[TEST]` (Art. 8), et
clore la livraison par son entrée de changelog (Art. 13). Conformément à l'Art. 10, **chaque test de
cette phase est écrit et vu rouge avant** que l'artefact qu'il juge existe.

- [ ] T011 [TEST] Écrire `tests/e2e/test_bare_metal_boot.py` — procédure automatisée sur **machine
      vierge** vérifiant **simultanément** les trois critères d'acceptation — *1 j*
      · **FR-013, FR-018** · **SC-001, SC-002, SC-003, SC-005, SC-007** · réf. `9f` T10 :
  - **A1** — pile entièrement saine en **< 5 min**, toutes sondes vertes, données des volumes nommés
    intactes après un cycle arrêt/redémarrage ;
  - **A1, suite** — **redémarrage de la machine** : au retour du système, la pile est **relancée sans
    intervention** et retrouve l'état sain. Assertion **distincte** du cycle arrêt/redémarrage de la
    pile ci-dessus, qui relève de SC-007 : celle-ci porte **SC-005** · scénario 6 de
    [`quickstart.md`](./quickstart.md), ligne « Redémarrage machine » du contrat 4 de
    [`contracts/routes.md`](./contracts/routes.md) ;
  - **A2** — balayage des ports de l'hôte : **parmi les ports des services de la pile**, seul le port
    TLS 443 de `caddy` répond ; moteurs, base, cache et observabilité **injoignables** hors de
    `quadra-net`. L'assertion est **bornée aux services de la pile** : `5b` § Sécurité place SSH, service
    de l'hôte, à côté de `:443` parmi les accès qui sortent du réseau compose — un balayage y trouverait
    443 **et** 22, et une assertion « seul le port TLS répond » échouerait sur la machine de référence
    pour une cause hors périmètre (arbitrage ouvert de `spec.md`) ;
  - **A3** — inspection de `deploy/docker-compose.yml` et de `deploy/digests.yml` : **100 %** des images
    référencées par **digest exact**, **aucune** référence mouvante ni intervalle ouvert ; un digest rendu
    indisponible produit un échec explicite **sans substitution**.
- [ ] T012 [P] [TEST] Écrire `tests/e2e/test_repo_governance.py` — le dépôt cloné porte
      **`CONSTITUTION.md`** à sa racine et la version qu'il déclare est **identique** à celle de sa
      source `.specify/memory/constitution.md` (échec à la moindre divergence), et **`CHANGELOG.md`**
      est au format Keep a Changelog et porte l'entrée du changement qui livre S01 — *0.25 j*
      · **FR-019, FR-020** · **SC-008, SC-009** · scénario 1 de [`quickstart.md`](./quickstart.md)
      · ⚠️ **aucune étape de la fiche `9f` ne porte cette preuve** (écart nº 3) · vert seulement après T017
- [ ] T013 [P] [TEST] Écrire `tests/e2e/test_digest_rollback.py` — sur une pile saine, re-pointer dans
      `deploy/digests.yml`, **et lui seul**, le digest précédemment épinglé, redémarrer par **une seule
      commande**, et vérifier que la pile retrouve l'état sain, qu'**aucune image n'a été reconstruite**,
      qu'**aucun autre fichier n'a été modifié** et que la version en service reste **lisible depuis la
      définition de déploiement** — *0.5 j* · **FR-021** · **SC-010** · réf. `w10` ; scénario 8 de
      [`quickstart.md`](./quickstart.md), contrat 4 de [`contracts/routes.md`](./contracts/routes.md)
      · ⚠️ **aucune étape de la fiche `9f` ne porte cette preuve** (écart nº 3)
- [ ] T014 [P] [TEST] Écrire `tests/unit/test_config_validation.py` — un démarrage dont une variable
      `QUADRA_` requise est absente ou invalide **est refusé** : la validation interrompt le démarrage,
      **nomme la variable fautive et la correction attendue**, et **aucun service** n'est laissé démarré
      — *0.25 j* · **FR-015** · **SC-006** · scénario 5 de [`quickstart.md`](./quickstart.md)
      · ⚠️ **aucune mesure de délai** : l'exigence est qualitative
      · ⚠️ la fiche `9f` et `spec.md` attribuent SC-006 à T7, une tâche d'implémentation, ce que
      l'Art. 8 interdit (écart nº 4) ; le chemin de ce fichier est une précision de `tasks.md`, cohérente
      avec la ligne Art. 10 de `plan.md` (« le validateur […] couvert unitairement »)
- [ ] T015 [TEST] Rejouer les **8 scénarios** de [`quickstart.md`](./quickstart.md) et **capturer leur
      sortie** (Art. 23), dont le **scénario 7** — installation par une personne n'ayant jamais vu le
      projet, seule ressource `docs/install.md` — qui prouve **SC-004** et valide l'Art. 9 — *0.5 j*
      · **FR-017** · **SC-004**
      · ⚠️ **aucune étape de la fiche `9f` ne porte cette preuve** ; `spec.md` attribue SC-004 à T9,
      une tâche d'implémentation, ce que l'Art. 8 interdit (écart nº 4)
- [ ] T016 [P] [TEST] Vérifier la **frontière S01/S02** : le volume `/data/offload` est **créé et monté
      par aucun service** — aucune option d'`offload` n'existe dans S01, elle est opt-in par job et
      relève de S18 (Art. 3, Art. 20) — et `deploy/prometheus/`, `deploy/alertmanager/`,
      `deploy/grafana/` sont **vides** — *0.25 j* · **FR-004** · aucun critère de succès n'y est gagé :
      cette tâche garde la réserve de l'Art. 20 et la frontière avec S02, pas un critère d'acceptation
      · ⚠️ **absente de la fiche `9f`**
- [ ] T017 Écrire dans `CHANGELOG.md` l'entrée du changement qui livre S01 (Keep a Changelog + SemVer)
      et y consigner, ainsi que dans `docs/install.md`, l'**écart assumé avec la table 5a du document** —
      décision **D1** : versions amont retenues pour Postgres, Redis, Grafana, Prometheus ; le fichier de
      digests du dépôt fait foi (Art. 19) — *0.25 j* · **FR-020** · **Art. 13** — écrite
      **dans le changement de livraison**, pas après · ⚠️ **absente de la fiche `9f`**
      · ⚠️ **aucun critère de succès n'y est gagé** : **SC-009 est prouvé par T012** `[TEST]`, dont cette
      tâche est l'**objet sous test**. T017 n'est pas une tâche `[TEST]` et ne peut donc porter aucune
      preuve (Art. 8), et le critère n'est revendiqué qu'à un seul endroit (Art. 19).

**Checkpoint** : jalon **M0** atteignable pour la part S01. Aucune tâche ne dépasse J4 (`9e` : « S01
complet »).

---

## Dependencies & Execution Order

### Phase Dependencies

- **US1 (Phase 2)** : aucune dépendance — démarre immédiatement. **Bloque US2 et US3.**
- **US2 (Phase 3)** : dépend de US1 (le réseau, les volumes et la composition existent).
- **US3 (Phase 4)** : dépend de US1 ; **indépendante de US2** pour T009 et T010 — la documentation et
  les cibles de commande s'écrivent en parallèle des moteurs.
- **Preuves (Phase 5)** : chaque test est **écrit et vu rouge d'abord** ; son passage au vert dépend
  de US1 + US2 + US3. T012 ne passe au vert qu'après T017.

### Within Each User Story

- Cycle rouge → vert (Art. 10) : T011, T012, T013, T014 sont écrits **avant** l'artefact qu'ils jugent.
- T002 précède T003, T004 et T005 : les volumes et le réseau doivent exister avant d'être montés.
- T007 (sondes, dépendances, redémarrage) vient **après** que tous les services soient déclarés.
- T008 précède fonctionnellement T009 et T010, mais les trois fichiers sont distincts.
- T017 précède le passage au vert de T012 (l'entrée de changelog est ce que le test cherche).

### Parallel Opportunities

- **US1** : aucune tâche `[P]` — T002 et T003 éditent tous deux `deploy/docker-compose.yml`, et T003
  dépend de T002.
- **US2** : **aucune tâche `[P]`** — T004, T005, T006 et T007 éditent tous `deploy/docker-compose.yml`.
  Le `Caddyfile` seul serait parallélisable, mais `plan.md` (précision 1) rattache le **service
  `caddy`** à la même tâche que sa configuration : déclarer l'un sans l'autre laisse soit un proxy sans
  routes, soit des routes sans proxy.
- **US3** : T009 et T010 sont `[P]` — `Makefile` et `docs/install.md` sont indépendants.
- **Preuves** : T012, T013, T014 et T016 sont `[P]` — fichiers de test distincts et objets disjoints.
  T011 et T015 mobilisent la machine de référence entière et ne se parallélisent pas.
- **Entre stories** : une fois US1 terminée, US2 et US3 peuvent avancer en parallèle par deux agents
  distincts.

---

## Parallel Example: User Story 3

```bash
# Une fois US1 terminée, US3 offre les deux seules tâches d'implémentation réellement parallélisables :
Task: "T009 — Makefile racine : cibles up / down / logs / ps"
Task: "T010 — docs/install.md, machine vierge → pile saine + procédure de retour arrière"
```

> **US2 n'offre aucun parallélisme.** Ses quatre tâches éditent `deploy/docker-compose.yml`. Le
> gabarit définit `[P]` comme « fichiers différents, aucune dépendance » — deux agents éditant le même
> fichier en parallèle entrent en conflit. Si le parallélisme sur ce fichier devient nécessaire,
> scinder la composition par domaine plutôt que relâcher le marqueur.

---

## Traçabilité critère → preuve

Table de `spec.md` § « Traçabilité critère → preuve », **reprise ligne pour ligne**, la colonne de
droite portant les identifiants Spec Kit de cette liste et les références `9f` en traçabilité.
Chaque critère est prouvé par **une tâche `[TEST]`** (Art. 8) : là où `spec.md` et la fiche `9f`
attribuent un critère à une tâche d'implémentation, la preuve est la tâche `[TEST]` créée ici et
l'écart est consigné (écart nº 4).

| Critère du document | Critères de succès | Tâche de preuve `[TEST]` |
| --- | --- | --- |
| **A1** — pile saine < 5 min, sondes vertes | SC-001, SC-005, SC-007 | T011 — vierge → verte < 5 min (réf. `9f` T10) |
| **A2** — seul :443 exposé, moteurs invisibles | SC-002 | T011 — balayage des ports **des services de la pile** (réf. `9f` T10) |
| **A3** — toute version épinglée | SC-003 | T011 — inspection des digests (réf. `9f` T10) |
| Exigences de surface (J3) | SC-004, SC-006 | T014 — refus de configuration invalide · T015 — installation par un tiers *(objets sous test : T008 validation au boot, T010 documentation d'installation — réf. `9f` T7, T9, tâches d'implémentation : écart nº 4)* |
| Fichiers de gouvernance à la racine (`10b`, Art. 13, § Governance) | SC-008, SC-009 | T012 — **aucune tâche de la fiche `9f` ne la porte** (écart nº 3) |
| Retour arrière en une commande (réf. `w10`, contrat 4) | SC-010 | T013 — **aucune tâche de la fiche `9f` ne la porte** (écart nº 3) |

---

## Implementation Strategy

### MVP d'abord (US1 seule)

1. T001, T002, T003 → dépôt clonable, gouvernance à la racine, bases démarrables **sans
   GPU**.
2. **STOP et VALIDER** : scénario 1 de [`quickstart.md`](./quickstart.md).

### Livraison incrémentale

1. US1 → validée seule → le socle existe.
2. US2 → validée seule → la pile complète démarre ; **S02 peut peupler** les répertoires de
   configuration.
3. US3 → validée seule → l'installation devient reproductible par un tiers.
4. Phase 5 → T011 prouve A1, A2, A3 ; T012, T013, T014, T015 prouvent SC-004,
   SC-006, SC-008, SC-009, SC-010 ; T016 garde la frontière S01/S02 ; T017 clôt par le
   changelog → **part S01 du jalon M0 atteinte**.

### Stratégie parallèle

- Agent A : US1 puis US2 (chemin critique).
- Agent B : dès US1 terminée, US3 (T009, T010) — sans attendre les moteurs.
- **Régime local (Art. 23)** : le harnais de test de la Phase 5 s'exécute **en local** et sa sortie
  capturée fait foi. `9c` donne S01 « Dépend de : — » : **aucune tâche de cette liste n'est gagée sur
  S03** ni sur aucune autre spec. Quand la chaîne de S03 existera, ces mêmes portes s'y exécuteront
  sans être réécrites — c'est l'ordre que fixe l'Art. 23, pas une dépendance de S01 envers S03.

---

## Arbitrages ouverts *(Art. 7 — consignés, non tranchés)*

Écarts découverts en produisant cette liste. L'Art. 7 exige qu'ils remontent dans le document ; ils
sont donc signalés ici, jamais absorbés en silence.

| nº | Écart | Ce qu'un humain doit trancher |
| --- | --- | --- |
| **1** | **Effort.** La fiche `9f` annonce « Total ≈ 5.5 j-agent » pour T1–T10 exactement (9 × 0.5 j + T10 1 j). Les **sept tâches que la fiche ne porte pas** (T002, T012, T013, T014, T015, T016, T017) pèsent **2.25 j** : le total réel est **7.75 j-agent**, soit **+41 %**. Le chiffre de `9c` (1–2 sem) reste compatible. | Confirmer le budget de 7.75 j, ou retirer des tâches — sachant qu'aucune des sept n'est optionnelle au regard de FR-004, FR-019 à FR-021 et de l'Art. 8. |
| **2** | **Volumes absents de `9f`.** `9f` T2 ne nomme aucun volume ; `5b` en exige quatre (`/data/models`, `/data/offload`, `pgdata`, `promdata`) et FR-004 les veut distincts par usage. Rattachés ici à T002. | Amendement documentaire de `9f` (ajout des volumes à J1). |
| **3** | **Preuves absentes de `9f`.** La fiche ne porte aucune tâche `[TEST]` pour les fichiers de gouvernance à la racine (SC-008, SC-009) ni pour le retour arrière (SC-010), que `10b`, l'Art. 13, le § Governance et `w10` exigent pourtant. Créées ici : T012, T013. | Amendement documentaire de `9f` (ajout de deux étapes à J4). |
| **4** | **Ligne J3 prouvée par des tâches d'implémentation.** `spec.md` et `9f` attribuent SC-004 et SC-006 à T9 et T7, tâches d'implémentation — l'Art. 8 exige une tâche `[TEST]`. Créées ici : T014, T015. Le chemin `tests/unit/test_config_validation.py` est une précision de `tasks.md`, reportée depuis dans la Project Structure de `plan.md`. | Amendement documentaire de `9f` ; la table de `spec.md` marque désormais l'écart et renvoie à T014 et T015. Reste à confirmer le chemin du test unitaire. |
| **5** | **Version de `dcgm-exporter`** — non épinglée par `5a`, hors de la portée de D1. FR-012 vaut pour *toute* image : T005 **ne peut pas être clôturée** sans cet arbitrage, et A3 se vérifie sur la définition de déploiement entière. | Choisir la version à épingler. Ne pas écrire « amont courant » : ce serait l'intervalle ouvert que l'Art. 11 interdit. |
| **6** | **Tag `llama.cpp b4102`** — « à revérifier » (`RESEARCH-STACK.md` §1). À vérifier **avant** l'épinglage de T004, faute de quoi FR-013 devient vrai au premier démarrage et A1 échoue pour une cause documentaire. | Vérifier la disponibilité du tag, ou en désigner un autre validé par le banc. |
| **7** | **Réserve de l'Art. 20 sur `/data/offload`** (voir `plan.md`, Constitution Check). Le volume est créé à M0 alors que l'`offload` relève de S18 (M3). | Confirmer la provision, ou sortir `/data/offload` de S01 — donc de T002 et T016. |
| **8** | **Format des identifiants de tâches.** `10b` fixe `S<nn>-T<n>` ; cette liste emploie le format Spec Kit `T001`, comme l'Art. 23 a déjà fait prévaloir `NNN-slug` sur le nommage de `10b` (D-A4). | Amendement documentaire de `10b`. |
| **9** | **Statut de SSH sur la machine de référence** (`5b` § Sécurité). L'assertion A2 de T011 est bornée aux ports **des services de la pile** ; le statut d'un service de l'hôte est hors périmètre de S01. | Décider si SSH est publié sur la machine de référence, et à quelles conditions. |

---

## Notes

- `[P]` = fichiers différents, aucune dépendance.
- **Aucune tâche de S01 ne relève des trois chemins à revue humaine** (authentification, facturation,
  proxy de flux) : la revue de S01 est celle des portes mécaniques.
- Le contrôle « pas de tag mouvant » de T011 est ce qui rend possibles le `canari` et le retour arrière
  par ré-épinglage (Art. 11 → Art. 9) ; T013 le prouve, il n'est plus seulement affirmé.
- `deploy/digests.yml` est la **source unique** des versions (Art. 19) et le **seul** fichier que le
  retour arrière modifie (FR-021).
- `CONSTITUTION.md` est une **copie**, pas un original : sa source est
  `.specify/memory/constitution.md`. On la régénère, on ne l'édite jamais directement ; amender la
  constitution passe par l'outil de gouvernance.
- Valider après chaque tâche ; commits atomiques et conventionnels, scope `S01` (Art. 14). Portes
  locales rouges ou vertes, jamais contournées (Art. 16, Art. 23).
