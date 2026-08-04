---
description: "Liste de tâches — S03 Socle qualité & CI"
---

# Tasks: S03 — Socle qualité & CI

**Input**: Documents de conception de `/specs/003-socle-qualite-ci/`
**Prerequisites**: `plan.md` ✅ · `spec.md` ✅ · `research.md` ✅ · `data-model.md` ✅ ·
`contracts/fake-engine.md` ✅ · `contracts/quality-gates.md` ✅ · `quickstart.md` ✅

**Tests** : **exigés** (Art. 8, Art. 10). S03 *est* l'outillage de test — sa propre preuve T10 est
écrite **rouge avant** que les portes existent.

**Jalon produit** : **M0 (Alpha)**. **Aucune dépendance** — parallélisable avec S01.
**Effort** : ≈ **6.5 j-agent**.

## Format : `[ID] [P?] [Story] Description`

- **[P]** : parallélisable — **fichiers réellement différents**, aucune dépendance
- **[Story]** : `[US1]` `[US2]` `[US3]`
- **`[TEST]`** : tâche de preuve
- Chaque description porte son **chemin de fichier exact**

**Identifiants** : ceux de la fiche 9h (T1–T10), non renumérotés (Art. 8 — les tables de traçabilité
les référencent). Les tâches complémentaires issues du plan portent un suffixe explicite.

---

## Phase 1 : Setup & Foundational

**S03 n'a aucune dépendance** : elle peut démarrer avant, pendant ou après S01. Aucune phase de
fondation externe n'est requise.

- [ ] **T0** Initialiser le verrou de dépendances reproductible dans `uv.lock` et déclarer les
      versions d'outillage dans `pyproject.toml` — *inclus dans T1* · **Art. 11**

---

## Phase 2 : User Story 1 — Fondations (Priority: P1) 🎯 MVP

**Goal** : les portes locales refusent le non conforme — formatage, style, typage, secrets, message
de validation — **des deux côtés** du projet.

**Independent Test** : sur un dépôt fraîchement cloné, tenter de valider un fichier mal formaté, un
fichier mal typé et un fichier contenant un secret ; chaque tentative est refusée avec un message
nommant le fichier et la règle — **sans qu'aucune chaîne distante existe**.

### Implémentation US1

- [ ] **T1** [US1] Configurer lint, format et **typage strict** du plan de contrôle dans
      `pyproject.toml` (+ verrou `uv.lock`) — *0.5 j* · **FR-001, FR-003, FR-006**
- [ ] **T2** [US1] Configurer tests et **seuils de couverture bloquants** dans `pyproject.toml` —
      **≥ 90 %** cœur, **≥ 70 %** ailleurs, sortie **capturée** — *0.5 j* · **FR-015, FR-024**
- [ ] **T2b** [US1] Déclarer les **bases éphémères** dans `tests/conftest.py`, aux **majeures de
      production** (base relationnelle 18.x, cache 8.x — conséquence de **D1**) — *inclus dans T2*
      · **FR-022**
      · ⚠️ tester contre une majeure antérieure ferait passer des tests qui échoueraient en production
- [ ] **T3** [US1] Déclarer les **portes locales** et la convention de messages de validation dans
      `.pre-commit-config.yaml`, à partir de la **source unique** de déclaration des portes —
      *0.5 j* · **FR-001, FR-002, FR-004, FR-020**
- [ ] **T4** [P] [US1] Configurer lint, format et tests de composants de l'interface dans
      `eslint.config.js` et `ui/package.json` — *0.5 j* · **FR-005**
- [ ] **T5** [P] [US1] Configurer le bout en bout et un test de fumée dans `playwright.config.ts` et
      `tests/smoke/` — *0.5 j* · **FR-021**
- [ ] **T5b** [US1] Écrire les cibles uniformes `lint / test / e2e / build / up` dans le `Makefile`
      — *inclus dans T3* · **FR-023**

**Checkpoint** : US1 est fonctionnelle et testable seule. C'est le MVP de S03 — dès ce point, **S01
peut être développée sous portes**.

---

## Phase 3 : User Story 2 — Moteur factice (Priority: P2)

**Goal** : un moteur d'inférence simulé permet de tester **tout le plan de contrôle sans GPU**, avec
latence et erreurs choisies.

**Independent Test** : sur une machine sans GPU, démarrer le moteur factice, obtenir une réponse en
flux, imposer une latence, injecter une erreur — chaque comportement est celui demandé.

> **US2 est indépendante de US1** : le moteur factice ne dépend d'aucune porte. Deux agents peuvent
> travailler en parallèle dès le départ.

### Implémentation US2

- [ ] **T6** [US2] Créer le **paquet distribuable** `packages/fake-engine/pyproject.toml` et
      implémenter la surface d'inférence dans `packages/fake-engine/src/fake_engine/server.py` —
      complétion conversationnelle et **flux jeton par jeton** au format d'un moteur réel — *1 j*
      · **FR-007, FR-008, FR-012**
      · ⚠️ **paquet avec son propre manifeste**, pas un module dans `tests/` — il est installé comme
      dépendance par S04 à S20 (Art. 19)
- [ ] **T7** [P] [US2] Implémenter les paramètres de simulation dans
      `packages/fake-engine/src/fake_engine/control.py` — **latence du premier jeton**, **latence
      inter-jetons**, **injection d'erreur** — *0.25 j* · **FR-009, FR-010**
- [ ] **T7b** [P] [US2] Implémenter les représentations vectorielles dans
      `packages/fake-engine/src/fake_engine/embeddings.py` — *0.25 j* · **FR-011**

**Checkpoint** : US2 fonctionne seule. **S04, S05, S06 et S07 peuvent désormais écrire leurs tests
d'intégration**, même si les portes de US1 ne sont pas finies.

---

## Phase 4 : User Story 3 — Chaîne d'intégration (Priority: P3)

**Goal** : la chaîne rejoue toutes les portes **dans l'ordre**, bout en bout compris, et bloque la
fusion dès qu'une seule est rouge.

**Independent Test** : soumettre un changement conforme, un changement sous les seuils de couverture,
puis un changement introduisant une dépendance vulnérable — seule la première soumission est
acceptée.

### Implémentation US3

- [ ] **T8** [US3] Écrire la chaîne dans `.github/workflows/ci.yaml` — ordre imposé : style et
      format → **typage** → tests et couverture → **contrôles de sécurité** → construction des
      images → bout en bout — *1 j* · **FR-013, FR-014, FR-018, FR-019**
      · images étiquetées **version + empreinte** (FR-019) — condition du retour arrière (Art. 11),
      consommées par S01
- [ ] **T8b** [US3] Vérifier dans `.github/workflows/ci.yaml` qu'**aucune étape** ne dispose d'un
      GPU — *inclus dans T8* · **FR-016**
      · ⚠️ trois exigences du projet **échappent donc à la chaîne** et sont prouvées au canari :
      découverte de topologie (**S06** SC-001), calibration du verdict de tenue mémoire (**S09**
      SC-001), débit additionné sur deux machines (**S20** SC-001)
- [ ] **T9** [US3] Ajouter l'étape de bout en bout sur **environnement éphémère complet** associé au
      moteur factice, dans `.github/workflows/ci.yaml` — **détruit en fin d'exécution** — *1 j*
      · **FR-017**

**Checkpoint** : les trois user stories fonctionnent. La definition of done devient **mécanique**.

---

## Phase 5 : Portes transverses issues du plan

Tâches non listées dans la fiche 9h mais **exigées par la spec et le plan**. Sans elles, deux
propriétés centrales se dégradent sans signal.

- [ ] **TP1** `[TEST]` Écrire `tests/tooling/test_gates_parity.py` — comparer les listes de portes
      **résolues** en local et à distance, échouer si elles divergent — *0.25 j*
      · **FR-002** · **SC-005** · **Art. 14**
      · ⚠️ **tâche indispensable** : sans elle, la parité se dégrade silencieusement au premier ajout
      de porte, et le symptôme (chaîne rouge après un local vert) est attribué à autre chose
- [ ] **TP2** [P] Mettre en place la **génération vérifiée** du client d'interface dans
      `ui/src/api/generated/` et l'étape de contrôle associée dans `.github/workflows/ci.yaml` —
      régénérer, comparer, **échouer si divergence** — *0.25 j* · **Art. 19**
      · prépare le critère **A1 de S11** (« client 100 % généré ») et le rend vrai **dans la durée**
- [ ] **TP3** [P] Documenter dans `docs/CONTRIBUTING.md` que le seuil de couverture est
      **nécessaire mais non suffisant** — le cycle rouge → vert reste dû pour tout comportement —
      *0.25 j* · **Art. 10**
      · limite **assumée** de l'automatisation : aucune mécanique ne détecte de façon fiable des
      tests sans assertion. La nommer plutôt que la masquer.

---

## Phase 6 : Preuves (J4)

**Purpose** : prouver les trois critères. Écrit **rouge avant** que les portes existent (Art. 10).

- [ ] **T10** `[TEST]` Écrire `tests/tooling/test_quality_gates.py` et
      `tests/tooling/test_fake_engine.py` — vérifier **simultanément** — *0.5 j* · **FR-025** :
  - **A1** — une porte locale **refuse** un fichier non conforme (formatage, typage, secret,
    message hors convention), avec un message nommant fichier et règle ;
  - **A2** — la chaîne **échoue et bloque la fusion** sous **90 %** (cœur) ou **70 %** (hors cœur) ;
  - **A3** — le moteur factice reproduit **flux**, **latence imposée** et **erreur injectée**, sur
    une machine **sans GPU**.

**Checkpoint** : part S03 du jalon **M0** atteinte.

---

## Phase 7 : Polish & Cross-Cutting

- [ ] **T10b** [P] Rejouer les 9 scénarios de [`quickstart.md`](./quickstart.md), dont le
      **scénario 2** (parité) et le **scénario 4** (unicité du moteur factice)
- [ ] **T10c** [P] Vérifier qu'**aucun second simulateur** du contrat d'inférence n'existe dans le
      dépôt — recherche automatisée · **FR-012**
- [ ] **T10d** Vérifier que l'environnement éphémère de bout en bout est **entièrement détruit** :
      aucune ressource résiduelle entre deux exécutions · **SC-007**

---

## Dependencies & Execution Order

### Phase Dependencies

- **US1 (Phase 2)** : aucune dépendance externe.
- **US2 (Phase 3)** : **indépendante de US1** — le moteur factice ne dépend d'aucune porte.
- **US3 (Phase 4)** : dépend de **US1 et US2** — la chaîne rejoue les portes de US1 et son étape de
  bout en bout consomme le moteur factice de US2.
- **Phase 5** : TP1 dépend de T3 et T8 (les deux listes de portes doivent exister) ; TP2 et TP3 sont
  indépendantes.
- **Preuves (Phase 6)** : dépendent de US1 + US2 + US3.

### Within Each User Story

- **T10 et TP1 sont écrits avant** l'implémentation correspondante et **vus rouges** (Art. 10).
- **US1** : T1 → T2 → T3 (T3 consomme la déclaration de portes) ; T4 et T5 en parallèle.
- **US2** : T6 d'abord (la surface), puis T7 et T7b en parallèle.
- **US3** : T8 puis T9.

### Parallel Opportunities

- **Entre stories** : **US1 et US2 en parallèle dès le départ** — deux agents, aucun fichier commun.
  C'est la principale opportunité de la spec.
- **US1** : T4 et T5 sont `[P]` (`eslint.config.js` + `ui/package.json` vs `playwright.config.ts` +
  `tests/smoke/`). T1, T2, T2b, T3 touchent tous `pyproject.toml` ou en dépendent — **non `[P]`**.
- **US2** : T7 et T7b sont `[P]` — deux fichiers distincts du paquet.
- **US3** : T8 et T9 éditent **le même fichier** — **non `[P]`**.
- **Phase 5** : TP2 et TP3 sont `[P]` ; TP1 ne l'est pas (dépend de T3 et T8).
- **Phase 7** : T10b et T10c sont `[P]`.

---

## Parallel Example: démarrage à deux agents

```bash
# Dès le premier jour, deux pistes totalement disjointes :
Agent A — Task: "T1 → T2 → T3, portes locales dans pyproject.toml et .pre-commit-config.yaml"
Agent B — Task: "T6 → T7 + T7b, moteur factice dans packages/fake-engine/"

# Puis, au sein de US1 :
Task: "T4 — lint interface dans eslint.config.js et ui/package.json"
Task: "T5 — bout en bout dans playwright.config.ts et tests/smoke/"
```

---

## Traçabilité critère → preuve

| Critère du document | Critères de succès | Tâche de preuve |
| --- | --- | --- |
| **A1** — une porte locale bloque un fichier non conforme | SC-001, SC-005 | **T10** · **TP1** (parité) |
| **A2** — chaîne rouge sous les seuils de couverture | SC-002 | **T10** |
| **A3** — moteur factice : flux, latence, erreurs | SC-003, SC-004 | **T10** · **T10c** (unicité) |
| Aucun accès GPU dans la chaîne | SC-004 | **T8b** |
| Sécurité continue | SC-006 | **T8** |
| Environnement éphémère détruit | SC-007 | **T9** · **T10d** |
| Definition of done mécanique | SC-008 | **T2** · **T8** · [`contracts/quality-gates.md`](./contracts/quality-gates.md) |
| Chaque vue a son test de composant | SC-009 | **T4** |

---

## Implementation Strategy

### MVP d'abord — mais deux MVP en parallèle

S03 est la seule spec du projet dont **deux user stories sont indépendantes dès le départ**. La
stratégie optimale n'est donc pas séquentielle :

1. **Agent A → US1** : dès T3, **S01 peut être développée sous portes**.
2. **Agent B → US2** : dès T7b, **S04 à S07 peuvent écrire leurs tests d'intégration**.
3. Les deux convergent sur **US3**, qui a besoin des deux.

### Livraison incrémentale

1. US1 → les portes locales protègent tout changement ultérieur.
2. US2 → la pyramide de tests devient possible **sans GPU**.
3. US3 → la chaîne rend la definition of done mécanique → **délégation aux agents possible**.
4. Phase 5 → TP1 et TP2 empêchent les deux dégradations silencieuses (parité, client généré).
5. Phase 6 → **T10** prouve A1, A2, A3 → part S03 du jalon **M0** atteinte.

---

## Notes

- **S03 ne contient aucun test métier** — seulement l'outillage qui les rend possibles (Art. 20). La
  matrice de permissions vient de **S13**, les scénarios de charge de **S21**.
- **Les trois chemins à revue humaine** (authentification, facturation, proxy de flux) sont rendus
  **visibles** par S03 mais **déclenchés** par S04, S08 et S12.
- Le seuil de couverture bloque, mais ne prouve pas que les tests assertent — **TP3** le dit
  explicitement dans le guide de contribution.
- Commits atomiques et conventionnels (Art. 14) ; la configuration des portes étant versionnée,
  toute désactivation se lit en revue (Art. 16).
