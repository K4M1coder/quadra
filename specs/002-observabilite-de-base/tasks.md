---
description: "Liste de tâches — S02 Observabilité de base"
---

# Tasks: S02 — Observabilité de base

**Input**: Documents de conception de `/specs/002-observabilite-de-base/`
**Prerequisites**: `plan.md` ✅ · `spec.md` ✅ · `research.md` ✅ · `data-model.md` ✅ ·
`contracts/metrics.md` ✅ · `quickstart.md` ✅

**Tests** : **exigés** (Art. 10, Art. 8) — cycle rouge → vert, chaque critère prouvé par une tâche
`[TEST]` tracée critère → preuve.

**Jalon produit** : **M0 (Alpha)**. **Dépend de S01** (conteneurs démarrés).
**Effort** : ≈ **3 j-agent**.

## Format : `[ID] [P?] [Story] Description`

- **[P]** : parallélisable — fichiers différents, aucune dépendance sur une tâche incomplète
- **[Story]** : `[US1]` `[US2]` — rattachement à la user story de `spec.md`
- **`[TEST]` / `[INT]`** : marqueurs du document de référence

**Identifiants** : ceux de la fiche 9g (T1–T8), **non renumérotés** — les tables de traçabilité de
`spec.md` et `plan.md` les référencent (Art. 8).

---

## Phase 1 : Setup & Foundational

**Assurées par S01.** Les conteneurs de collecte, de routage d'alertes, de visualisation et
l'exportateur matériel sont **déjà démarrés** ; les répertoires de configuration existent **vides**.
S02 les **peuple** — elle ne déploie rien.

**Préalable bloquant issu de la décision D1** — voir [`RESEARCH-STACK.md`](../RESEARCH-STACK.md) §7 :

- [ ] **T0** Consulter la documentation **des majeures retenues** (collecte 3.x LTS, visualisation
      13.x) pour le format de configuration et les options de rétention, **avant** d'écrire T1 et T2
      · ⚠️ **piège réel** : les exemples les plus répandus en ligne portent encore sur la majeure
      précédente et ne s'appliquent pas. *(0.25 j, absorbé dans T1)*

---

## Phase 2 : User Story 1 — Collecte (Priority: P1) 🎯 MVP

**Goal** : toutes les métriques de la plateforme sont captées et conservées 90 jours. C'est **la
source unique de métriques**, posée avant tout code métier.

**Independent Test** : démarrer la pile et constater que chaque composant attendu apparaît comme
cible interrogée avec succès, que le matériel expose ses mesures par carte, et que la conservation
est bien de 90 jours — **sans qu'aucun tableau de bord existe encore**.

### Implémentation US1

- [ ] **T1** [US1] Écrire `deploy/prometheus/prometheus.yml` : les **quatre familles de cibles**
      (plan de contrôle, moteurs, exportateur matériel, la collecte elle-même) avec leurs cadences
      — **1 s** pour le matériel GPU, **5 s** pour les autres — *0.5 j* · **FR-001, FR-003**
      · écrire pour la majeure retenue (D1), pas transposer un exemple ancien
- [ ] **T2** [P] [US1] Provisionner la source de données depuis le dépôt, dans
      `deploy/grafana/provisioning/datasources/` — *0.25 j* · **FR-011**
- [ ] **T6** [P] [US1] Configurer la **rétention 90 jours** et le rattachement du volume persistant
      `promdata`, dans `deploy/prometheus/prometheus.yml` et la définition de déploiement — *0.25 j*
      · **FR-005, FR-006**

**Checkpoint** : la source unique de métriques existe. Les specs ultérieures (S04, S05, S08) pourront
y publier **sans changement de configuration**, à condition de respecter le nommage.

---

## Phase 3 : User Story 2 — Surface (Priority: P2)

**Goal** : les tableaux de bord sont provisionnés depuis le dépôt sans aucune action manuelle, et les
alertes sont acheminées.

**Independent Test** : repartir d'un **stockage de visualisation vide**, démarrer, et constater que
les tableaux de bord attendus sont présents et alimentés — sans aucune action dans l'interface.

### Implémentation US2

- [ ] **T3** [P] [US2] Écrire le tableau de bord matériel versionné
      `deploy/grafana/dashboards/ds-gpu.json` : température, puissance, mémoire vidéo **par carte**
      — *0.5 j* · **FR-013** · nommage `ds-<domaine>.json` (convention 10b)
- [ ] **T4** [P] [US2] Écrire le tableau de bord moteurs versionné
      `deploy/grafana/dashboards/ds-engines.json` : latence du premier jeton, latence inter-jetons,
      profondeur des files — *0.5 j* · **FR-014**
      · ⚠️ métriques amont **réexposées telles quelles**, sans renommage (Art. 6)
- [ ] **T4b** [US2] Déclarer le provisionnement des tableaux de bord dans
      `deploy/grafana/provisioning/dashboards/` de sorte qu'il **réapplique** les définitions **à
      chaque démarrage** — *inclus dans T3/T4* · **FR-012**
      · ⚠️ **ce n'est pas un import initial** — voir T8b
- [ ] **T5** [P] [US2] Écrire `deploy/alertmanager/alertmanager.yml` (routes par gravité) et les
      gabarits de notification dans `deploy/alertmanager/templates/` — *0.5 j*
      · **FR-016, FR-017, FR-018**

**Checkpoint** : US1 **et** US2 fonctionnent. Les critères **A1**, **A2** et **A3** sont atteignables.

---

## Phase 4 : Conformité des libellés (transverse, Art. 1)

**Purpose** : empêcher mécaniquement qu'une donnée personnelle ou une valeur à cardinalité libre
entre dans une série temporelle conservée 90 jours. Porte **transverse** : elle s'appliquera à toutes
les specs qui émettront des métriques.

- [ ] **TL1** Implémenter le contrôle de conformité des libellés dans
      `gateway/observability/labels.py` — **liste blanche** `lane`, `alias`, `node`, `host`,
      `key_id` ; rejet de toute donnée personnelle, de tout contenu de prompt et de toute valeur à
      cardinalité libre — *0.25 j* · **FR-010**
- [ ] **TL2** `[TEST]` Écrire `tests/observability/test_labels.py` : l'existant passe, **et** une
      métrique introduite volontairement avec un libellé à cardinalité libre est **rejetée** —
      *0.25 j* · **SC-006** · exécuté en intégration continue (Art. 8)

> Écrire **TL2 avant TL1** et le voir rouge (Art. 10).

---

## Phase 5 : Preuves (J3)

- [ ] **T7** `[INT]` Vérifier que la collecte atteint le **plan de contrôle démarré par S01** —
      *0.25 j* · **SC-001**
- [ ] **T8** `[TEST]` Vérifier **simultanément** — *0.5 j* · **FR-019** :
  - **A1** — **100 %** des cibles déclarées joignables ; les 4 cartes exposent température,
    puissance et mémoire vidéo rafraîchies au moins **une fois par seconde** ;
  - **A2** — sur **stockage de visualisation vide**, les deux tableaux de bord sont présents et
    alimentés **sans action manuelle** ;
  - **A3** — rétention effective : une mesure de **89 j est lisible**, une mesure de **91 j ne l'est
    plus**.
- [ ] **T8b** `[TEST]` **Le dépôt fait autorité** — modifier un tableau de bord **à la main** dans
      l'interface, **redémarrer**, constater le **retour à la définition versionnée** — *inclus dans
      T8* · **SC-005**
      · ⚠️ **tâche indispensable** : un test qui vérifierait seulement la *présence* des tableaux de
      bord passerait à tort sur un simple import initial. C'est cette tâche qui distingue un
      provisionnement conforme à l'Art. 19 d'un provisionnement qui le contourne.

**Checkpoint** : part S02 du jalon **M0** atteinte.

---

## Phase 6 : Polish & Cross-Cutting

- [ ] **T8c** [P] Rejouer les 9 scénarios de [`quickstart.md`](./quickstart.md), dont le
      **scénario 9** (source unique : aucun second collecteur, aucun second magasin de séries)
- [ ] **T8d** [P] Vérifier la persistance : arrêt/redémarrage de la pile, mesures antérieures
      toujours présentes · **FR-006**
- [ ] **T8e** Consigner dans le `CHANGELOG` l'écart avec la table 5a du document (décision **D1** :
      majeures amont retenues) — **Art. 13**

---

## Dependencies & Execution Order

### Phase Dependencies

- **S01 doit être livrée** : sans conteneurs démarrés ni répertoires de configuration, S02 n'a rien à
  peupler.
- **US1 (Phase 2)** : dépend de S01. **Bloque US2** — sans collecte, un tableau de bord n'affiche
  rien.
- **US2 (Phase 3)** : dépend de US1.
- **Conformité des libellés (Phase 4)** : **indépendante** — peut avancer en parallèle de US1 dès que
  S01 est livrée.
- **Preuves (Phase 5)** : dépendent de US1 + US2.

### Within Each User Story

- **US1** : T1 d'abord (les cibles), puis T2 et T6 en parallèle.
- **US2** : T3, T4 et T5 en parallèle ; T4b est indissociable de la déclaration de provisionnement.
- **TL2 avant TL1** — cycle rouge → vert.
- **T8 et T8b écrits avant** l'implémentation de US1/US2 et vus rouges.

### Parallel Opportunities

- **US1** : T2 et T6 sont `[P]` — fichiers distincts.
- **US2** : T3, T4, T5 sont `[P]` — trois fichiers distincts.
- **Phase 4** entière est parallélisable avec les phases 2 et 3 : elle ne touche que
  `gateway/observability/` et `tests/observability/`.
- **Phase 6** : T8c et T8d sont `[P]`.

---

## Parallel Example: User Story 2

```bash
# Une fois US1 terminée, lancer les trois ensemble :
Task: "T3 — tableau de bord matériel dans deploy/grafana/dashboards/ds-gpu.json"
Task: "T4 — tableau de bord moteurs dans deploy/grafana/dashboards/ds-engines.json"
Task: "T5 — routes et gabarits dans deploy/alertmanager/"

# En parallèle des phases 2 et 3, sur des fichiers totalement disjoints :
Task: "TL2 puis TL1 — conformité des libellés dans gateway/observability/ et tests/observability/"
```

---

## Traçabilité critère → preuve

| Critère du document | Critères de succès | Tâche de preuve |
| --- | --- | --- |
| **A1** — toutes les cibles joignables | SC-001, SC-004 | **T8** · **T7** `[INT]` |
| **A2** — tableaux de bord importés automatiquement | SC-002, SC-005 | **T8** · **T8b** (le dépôt fait autorité) |
| **A3** — rétention 90 j configurée | SC-003 | **T8** (89 j / 91 j) |
| Libellés = identifiants, jamais de PII | SC-006 | **TL2** |
| Routage des alertes | SC-007 | **T5** |
| Persistance des mesures | — | **T8d** |
| Source unique de métriques | — | **T8c** (scénario 9) |

---

## Implementation Strategy

### MVP d'abord (US1 seule)

1. **T1**, **T2**, **T6** → la source unique de métriques existe et conserve 90 jours.
2. **STOP et VALIDER** : scénarios 1, 2 et 5 de `quickstart.md`.
3. À ce stade, **S04, S05 et S08 peuvent déjà publier leurs métriques** — c'est la valeur réelle de
   l'US1, bien avant qu'un humain regarde un tableau de bord.

### Livraison incrémentale

1. US1 → la collecte tourne → les specs métier ont où publier.
2. US2 → l'observabilité devient lisible par un humain → prépare la surface de **S15**.
3. Phase 4 → la porte de conformité protège **toutes** les specs suivantes.
4. Phase 5 → **T8 + T8b** prouvent A1, A2, A3 → part S02 du jalon **M0** atteinte.

### Stratégie parallèle

- Agent A : US1 puis US2 (chemin critique).
- Agent B : Phase 4 (conformité des libellés) — totalement disjointe, dès que S01 est livrée.

---

## Notes

- **S02 configure, S01 déploie.** Aucune tâche de S02 ne modifie `deploy/docker-compose.yml`.
- **Aucun tableau de bord pour des métriques inexistantes** (Art. 20) : seulement matériel et moteurs,
  les seules familles réellement peuplées à M0. Les vues de requêtes, jetons et budgets viendront
  avec les specs qui les émettent.
- **Ne pas renommer les métriques amont** (Art. 6) : la convention `quadra_*` ne s'applique qu'aux
  métriques propres au projet.
- Aucune tâche de S02 ne relève des trois chemins à revue humaine.
- Commits atomiques et conventionnels (Art. 14) ; un tableau de bord = un fichier = un changement,
  revuable comme du code.
