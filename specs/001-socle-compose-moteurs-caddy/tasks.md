---
description: "Liste de tâches — S01 Socle compose + moteurs + Caddy"
---

# Tasks: S01 — Socle compose + moteurs + Caddy

**Input**: Documents de conception de `/specs/001-socle-compose-moteurs-caddy/`
**Prerequisites**: `plan.md` ✅ · `spec.md` ✅ · `research.md` ✅ · `data-model.md` ✅ ·
`contracts/routes.md` ✅ · `quickstart.md` ✅

**Tests** : **exigés**, non optionnels. L'Art. 10 impose le cycle rouge → vert pour tout
comportement, et l'Art. 8 exige que chaque critère d'acceptation soit prouvé par une tâche `[TEST]`
tracée critère → preuve.

**Jalon produit** : **M0 (Alpha)** — spec complète à M0. Aucune dépendance externe.
**Effort** : ≈ **5.5 j-agent**.

## Format : `[ID] [P?] [Story] Description`

- **[P]** : parallélisable — fichiers différents, aucune dépendance sur une tâche incomplète
- **[Story]** : `[US1]` `[US2]` `[US3]` — rattachement à la user story de `spec.md`
- **`[TEST]` / `[INT]`** : marqueurs du document de référence — tâche de preuve / d'intégration
- Chaque description porte son **chemin de fichier exact**

**Identifiants** : ceux du document de référence (fiche 9f, T1–T10), **volontairement non
renumérotés**. Les tables « Traçabilité critère → preuve » de `spec.md` et `plan.md` les référencent
déjà ; renuméroter romprait la chaîne exigée par l'Art. 8.

---

## Phase 1 : Setup & Foundational

**S01 *est* la phase de fondation du projet entier.** Les phases « Setup » et « Foundational » du
gabarit sont donc **assurées par la user story US1** ci-dessous, et non dupliquées ici.

**Préalable non livrable** (vérification d'environnement, pas une tâche de code) : la machine hôte
porte **la combinaison validée** pilote GPU 560 / CUDA 12.6 / toolkit conteneur — décision **D2**,
voir [`RESEARCH-STACK.md`](../RESEARCH-STACK.md) §7. Une combinaison différente invalide les
scénarios GPU de `quickstart.md`.

---

## Phase 2 : User Story 1 — Fondations (Priority: P1) 🎯 MVP

**Goal** : un développeur clone le dépôt, comprend l'arborescence, et démarre les bases de données
sans connaître le reste de la plateforme.

**Independent Test** : sur une machine vierge **sans GPU**, cloner puis démarrer les services de
données ; base relationnelle et cache atteignent l'état sain, les données persistent dans des volumes
nommés.

### Implémentation US1

- [ ] **T1** [US1] Créer l'arborescence de premier niveau (`gateway/`, `ui/`, `deploy/`, `docs/`) et
      `README.md` décrivant le rôle de chaque répertoire et la commande d'amorçage — *0.5 j*
      · **FR-001, FR-002**
- [ ] **T2** [US1] Déclarer la base relationnelle et le cache dans `deploy/docker-compose.yml`, avec
      **volumes nommés** (`pgdata`) et **sondes de santé** — *0.5 j* · **FR-003, FR-004**
      · versions **amont** (Postgres 18.x, Redis 8.x) épinglées **par digest**, décision **D1**

**Checkpoint** : US1 est fonctionnelle et testable seule, sans GPU. C'est le MVP de S01.

---

## Phase 3 : User Story 2 — Cœur (Priority: P2)

**Goal** : l'administrateur exécute **une commande unique** et obtient la plateforme complète —
moteurs, observabilité, TLS.

**Independent Test** : sur la machine de référence à 4 GPUs, lancer la commande de démarrage et
constater que tous les services deviennent sains **en moins de 5 minutes**, que le point d'entrée TLS
répond, et qu'**aucun port de moteur** n'est joignable de l'extérieur.

### Implémentation US2

- [ ] **T3** [P] [US2] Déclarer les deux moteurs d'inférence dans `deploy/docker-compose.yml`,
      attachés au réseau interne, **sans aucun port publié**, **épinglés par digest exact** — *0.5 j*
      · **FR-006, FR-007, FR-012** · versions **conservées** (D2) pour le couple pilote/CUDA
- [ ] **T4** [US2] Déclarer la chaîne d'observabilité dans `deploy/docker-compose.yml` — collecte,
      routage d'alertes, visualisation, exportateur matériel GPU — et créer les répertoires de
      configuration **vides** `deploy/prometheus/`, `deploy/alertmanager/`, `deploy/grafana/` — *0.5 j*
      · **FR-011** · ⚠️ **contenu peuplé par S02**, pas ici
- [ ] **T5** [P] [US2] Écrire `deploy/Caddyfile` : TLS automatique et acheminement des quatre familles
      de routes (inférence, administration, temps réel, tableaux de bord) — *0.5 j* · **FR-008**
      · voir [`contracts/routes.md`](./contracts/routes.md) contrat 2
- [ ] **T6** [US2] Ajouter sondes de santé, dépendances de démarrage et politiques de redémarrage sur
      **tous** les services de `deploy/docker-compose.yml` — *0.5 j* · **FR-009, FR-010**
      · dépend de T2, T3, T4, T5

**Checkpoint** : US1 **et** US2 fonctionnent. Les critères **A1** et **A2** sont atteignables ;
leur preuve est T10.

---

## Phase 4 : User Story 3 — Surface (Priority: P3)

**Goal** : l'administrateur configure par un fichier unique dont chaque variable est documentée, et
suit une procédure écrite qui le mène de la machine vierge à la pile saine.

**Independent Test** : donner à une personne n'ayant jamais vu le projet la seule documentation
d'installation, et constater qu'elle atteint la pile saine **sans poser de question**.

### Implémentation US3

- [ ] **T7** [US3] Écrire `deploy/.env.example` exhaustif (chaque variable documentée, valeurs
      **factices** pour les secrets) **et** le validateur de configuration au démarrage dans
      `gateway/config/settings.py` — échec en < 10 s nommant la variable fautive et la correction
      attendue, **aucun service laissé démarré** — *0.5 j* · **FR-014, FR-015**
      · ⚠️ **Art. 19** : ce validateur est **partagé avec S04**. Ne pas écrire un second validateur
      en script de déploiement.
- [ ] **T8** [P] [US3] Écrire le `Makefile` racine : cibles `up`, `down`, `logs`, `ps` — la cible
      `up` **est** la commande unique de démarrage de la pile — *0.5 j* · **FR-005, FR-016**
- [ ] **T9** [P] [US3] Écrire `docs/install.md` : machine vierge → pile saine, sans connaissance
      implicite — *0.5 j* · **FR-017** · **Art. 13** — livré dans le même changement, pas après

**Checkpoint** : les trois user stories sont fonctionnelles indépendamment.

---

## Phase 5 : Preuves (J4)

**Purpose** : prouver mécaniquement les trois critères d'acceptation. Conformément à l'Art. 10, ce
test est **écrit et vu rouge avant** que la composition existe.

- [ ] **T10** `[TEST]` Écrire `tests/e2e/test_bare_metal_boot.py` — procédure automatisée sur
      **machine vierge** vérifiant **simultanément** les trois critères — *1 j*
      · **FR-013, FR-018** :
  - **A1** — pile entièrement saine en **< 5 min**, toutes sondes vertes ;
  - **A2** — balayage des ports **depuis une autre machine** : seul le port TLS répond ; moteurs,
    base, cache et observabilité **injoignables** ;
  - **A3** — inspection de `deploy/docker-compose.yml` : **100 %** des images référencées par
    **digest exact**, **aucune** référence mouvante ; un digest rendu indisponible produit un échec
    explicite **sans substitution**.

**Checkpoint** : jalon **M0** atteignable pour la part S01.

---

## Phase 6 : Polish & Cross-Cutting

- [ ] **T10b** [P] Rejouer les 7 scénarios de [`quickstart.md`](./quickstart.md), dont le
      **scénario 7** — installation par un tiers, seule ressource `docs/install.md` — qui prouve
      **SC-004** et valide l'Art. 9
- [ ] **T10c** [P] Vérifier que le volume `offload` est **créé et monté par aucun service**
      (Art. 3, Art. 20) et que `deploy/prometheus/`, `deploy/alertmanager/`, `deploy/grafana/` sont
      **vides** — frontière avec S02
- [ ] **T10d** Consigner dans `docs/install.md` et le `CHANGELOG` l'écart assumé avec la table 5a du
      document (décision **D1** : versions amont retenues) — **Art. 13**

---

## Dependencies & Execution Order

### Phase Dependencies

- **US1 (Phase 2)** : aucune dépendance — démarre immédiatement. **Bloque US2 et US3.**
- **US2 (Phase 3)** : dépend de US1 (la composition et les volumes existent).
- **US3 (Phase 4)** : dépend de US1 ; **indépendante de US2** pour T8 et T9 — la documentation et les
  cibles de commande s'écrivent en parallèle des moteurs.
- **Preuves (Phase 5)** : dépendent de US1 + US2 + US3 — T10 vérifie les trois critères ensemble.
- **Polish (Phase 6)** : dépend de la Phase 5.

### Within Each User Story

- Le test T10 est **écrit avant** l'implémentation et **vu rouge** (Art. 10).
- T6 (sondes, dépendances, redémarrage) vient **après** que tous les services soient déclarés.
- T7 précède fonctionnellement T8 et T9, mais les trois fichiers sont distincts.

### Parallel Opportunities

- **US2** : T3 et T5 sont `[P]` — fichiers distincts (`deploy/docker-compose.yml` et
  `deploy/Caddyfile`). **T4 n'est pas `[P]`** : elle édite le même fichier que T3. T6 les rassemble
  et n'est pas parallélisable non plus.
- **US3** : T8 et T9 sont `[P]` — `Makefile` et `docs/install.md` sont indépendants.
- **Phase 6** : T10b et T10c sont `[P]`.
- **Entre stories** : une fois US1 terminée, US2 et US3 peuvent avancer en parallèle par deux agents
  distincts.

---

## Parallel Example: User Story 2

```bash
# Une fois US1 terminée, deux tâches seulement sont réellement parallélisables :
Task: "T3 — moteurs épinglés par digest, sans port publié, dans deploy/docker-compose.yml"
Task: "T5 — TLS et acheminement des routes, dans deploy/Caddyfile"

# Puis, séquentiellement — T4 édite le même fichier que T3 :
Task: "T4 — chaîne d'observabilité + répertoires de config vides, dans deploy/docker-compose.yml"
Task: "T6 — sondes, dépendances et politiques de redémarrage sur tous les services"
```

> **T4 n'est pas marquée `[P]`** : elle édite `deploy/docker-compose.yml`, comme T3. Le gabarit
> définit `[P]` comme « fichiers différents, aucune dépendance » — deux agents éditant le même
> fichier en parallèle entrent en conflit. Si le parallélisme sur ce fichier devient nécessaire,
> scinder la composition par domaine plutôt que relâcher le marqueur.

---

## Traçabilité critère → preuve

Reprise de `spec.md`, section « Traçabilité critère → preuve ».

| Critère du document | Critères de succès | Tâche de preuve |
| --- | --- | --- |
| **A1** — pile saine < 5 min, sondes vertes | SC-001, SC-005, SC-007 | **T10** |
| **A2** — seul :443 exposé, moteurs invisibles | SC-002 | **T10** (balayage depuis une autre machine) |
| **A3** — toute version épinglée | SC-003 | **T10** (inspection des digests) |
| Surface J3 — configuration et documentation | SC-004, SC-006 | **T7** (validation au boot) · **T9** + **T10b** (installation par un tiers) |
| Résilience au redémarrage | SC-005 | **T6** |
| Frontière S01/S02, offload inactif | — | **T10c** |

---

## Implementation Strategy

### MVP d'abord (US1 seule)

1. **T1**, **T2** → dépôt clonable, bases démarrables **sans GPU**.
2. **STOP et VALIDER** : scénario 1 de `quickstart.md`.
3. C'est le socle minimal sur lequel **S03** (qualité & CI) peut déjà travailler en parallèle.

### Livraison incrémentale

1. US1 → validée seule → **S03 peut démarrer**.
2. US2 → validée seule → la pile complète démarre ; **S02 peut peupler** les répertoires de
   configuration.
3. US3 → validée seule → l'installation devient reproductible par un tiers.
4. Phase 5 → **T10** prouve A1, A2, A3 → **part S01 du jalon M0 atteinte**.

### Stratégie parallèle

- Agent A : US1 puis US2 (chemin critique).
- Agent B : dès US1 terminée, US3 (T8, T9) — sans attendre les moteurs.
- Agent C : en parallèle de tout, **S03** — qui fournit le harnais de test de T10.

---

## Notes

- `[P]` = fichiers différents, aucune dépendance — sauf l'exception documentée sur T3/T4.
- **Aucune tâche de S01 ne relève des trois chemins à revue humaine** (authentification, facturation,
  proxy de flux) : la revue de S01 est celle des portes mécaniques.
- Le contrôle « pas de tag mouvant » de T10 est ce qui rend possibles le canari et le retour arrière
  par ré-étiquetage (Art. 11 → Art. 9).
- Valider après chaque tâche ; commits atomiques et conventionnels (Art. 14).
