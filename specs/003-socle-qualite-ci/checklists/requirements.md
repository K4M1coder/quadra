# Specification Quality Checklist: S03 — Socle qualité & CI

**Purpose**: Validate specification completeness and quality before proceeding to planning
**Created**: 2026-08-01
**Last reviewed**: 2026-08-12 (itération 3 — revue de cohérence croisée des artefacts de conception)
**Feature**: [spec.md](../spec.md)

## Content Quality

- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

## Requirement Completeness

- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous
- [x] Success criteria are measurable
- [x] Success criteria are technology-agnostic (no implementation details)
- [x] All acceptance scenarios are defined
- [x] Edge cases are identified
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

## Feature Readiness

- [x] All functional requirements have clear acceptance criteria
- [x] User scenarios cover primary flows
- [x] Feature meets measurable outcomes defined in Success Criteria
- [x] No implementation details leak into specification

## Notes

**Nature particulière de cette spec** — S03 livre de l'outillage : ses « utilisateurs » sont les
contributeurs (développeur humain, agent IA, mainteneur), pas des utilisateurs finaux. Les items
« focused on user value » et « written for non-technical stakeholders » ont donc été évalués par
rapport à ce public. La spec décrit **ce que les portes garantissent** (un refus, un seuil, un
comportement simulé), jamais **quel outil** les implémente.

**Itération de validation 1 — constats et corrections appliquées**

- *No implementation details* : la fiche `9h` et la section `9b` nomment une trentaine d'outils (ruff,
  mypy, pytest, testcontainers, eslint, prettier, vitest, playwright, bandit, pip-audit, uv, k6…).
  **Tous** ont été retirés de la spec et réservés au plan. Ils sont remplacés par le contrôle rendu :
  « portes de formatage et de style », « typage strict », « bases éphémères », « analyse statique »,
  « audit des dépendances », « scénarios de charge ».
- *Requirements testable* : les seuils chiffrés (90 % cœur / 70 % ailleurs) et l'ordre des portes
  sont conservés — ce sont des **contrats normatifs** de la constitution (Art. 8, Art. 10), pas des
  détails d'outil. FR-013 fixe l'ordre, FR-015 les seuils, FR-014 le caractère bloquant.
- *Success criteria technology-agnostic* : les critères s'expriment en taux de refus, en seuils, en
  présence/absence d'accès GPU et en destruction de ressources — aucun ne cite un outil.
- *Edge cases* : deux cas non présents dans le document ont été ajoutés parce qu'ils menacent
  directement la validité du socle — le **moteur factice qui diverge du comportement réel** (invalide
  silencieusement toute la pyramide) et le **seuil de couverture atteint par des tests sans
  assertion** (la couverture est nécessaire mais non suffisante, le cycle rouge-vert de l'Art. 10
  reste dû). Ils sont dérivés de la constitution, pas inventés.
- *Scope is clearly bounded* : section « Hors périmètre (Art. 20 — YAGNI) » ajoutée.

**Itération de validation 2 — révision après amendement constitutionnel v1.1.0 (Art. 23)**

Cinq exigences et trois critères ont été ajoutés **sans renumérotation** (les renvois des autres
artefacts restent valides), et quatre points ont été retirés.

Ajouts :

- **FR-026 / SC-011** — épinglage des **briques consommées** par la chaîne (Art. 11 nomme
  explicitement « ou action CI »). À distinguer de FR-019, qui couvre les images **construites**.
- **FR-027 / SC-010** — la **charge** est une porte bloquante et non une dépendance d'outillage sans
  porte (Art. 8 porte 4 « e2e + charge sur compose éphémère » ; `9b` « e2e + k6 »). Le dernier maillon
  est **unique** : bout en bout **et** charge.
- **FR-028** — cohérence des migrations (`9b` « `alembic check` »), porte posée à M0 et s'exécutant à
  vide, le schéma arrivant avec S04.
- **FR-029 / SC-009** — topologie `NNN-slug` → `dev` → `test` → `master`, rangs 1 à 3 à l'entrée dans
  `dev`, rangs 4 et 5 à la promotion de `test`, aucun commit direct sur `test` ni `master` (Art. 23).
- **FR-030** — usage **obligatoire et exclusif** de la chaîne dès qu'elle existe ; régime local en son
  absence, sortie capturée valant definition of done.

Retraits :

- **La génération du client d'interface** et sa vérification sortent du périmètre → **S11** (`9p`
  tâche T2, critère A1 « Client API 100 % généré », jalon **M2**). `9h` borne `ui/` à « eslint flat,
  prettier, vitest, playwright », et à **M0 il n'existe aucun contrat à générer** : le contrat `/v1`
  est figé par S04 à M1.
- **FR-021** est borné aux niveaux de la pyramide **posables à M0** (unitaires, intégration, bout en
  bout, charge, sécurité) ; les quatre autres reviennent aux specs qui les produisent, sans
  anticipation (Art. 20).
- Les Key Entities **« Porte de qualité »**, **« Seuil de couverture »** et **« Étape de chaîne »**
  ont été retirées : l'arbre de la méthode de `10a` s'arrête à `Tâche Tn` et l'Art. 17 interdit de
  faire naître un concept absent de la taxonomie. Les modéliser exigerait un amendement (ARBITRAGE 5).
- **SC-005** n'exige plus de test de parité : l'Art. 14 demande l'**équivalence** hooks ≡ chaîne, pas
  un mécanisme de comparaison. L'équivalence est obtenue par **définition unique** des portes,
  versionnée et invoquée de part et d'autre (FR-002, FR-020).
- **FR-006** est réduit à « le refus identifie le **fichier** » — la granularité du critère A1 de
  `9h`. L'exigence de « messages actionnables » du document ne concerne que les erreurs Hugging Face
  (`9c`, `9n` — S09).

**Itération de validation 3 — revue de cohérence croisée des artefacts de conception**

Les itérations 1 et 2 portaient sur `spec.md`. Celle-ci croise les **huit** artefacts entre eux —
`spec.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`, `quickstart.md` et les deux contrats.
La spec elle-même n'est pas modifiée : **quatre constats** portant sur les artefacts dérivés, tous
corrigés (Art. 16 — un constat se corrige ou s'accepte explicitement, jamais en silence). Les trois
premiers viennent de la revue de S03 ; le quatrième est **remonté par la revue croisée de S02**, dont
les contrats de S03 sont consommateurs.

- **Constat 1 — `quickstart.md` scénario 3 revendiquait SC-004.** Le scénario du moteur factice
  déclarait prouver « SC-003, SC-004 » alors que **SC-004 porte sur les étapes de la chaîne** (« 100 %
  s'exécutent sans accéder à un GPU ») et appartient au scénario 7 — ce que le récapitulatif du même
  fichier disait déjà, et ce que `tasks.md` confirme en attribuant SC-004 à T020. Deux scénarios
  revendiquaient donc le même critère, en contradiction avec la règle « un critère, une preuve »
  (Art. 8). **Corrigé** : SC-004 retiré du scénario 3, avec la raison énoncée — le fonctionnement sans
  GPU du moteur factice (FR-007) est la *condition* de SC-004, pas sa preuve.
- **Constat 2 — FR-005 n'était couvert par aucun scénario de validation.** Le scénario 1 n'exerçait
  que le versant *plan de contrôle*, alors que FR-005 et le critère d'acceptation US1-AS5 exigent les
  **deux versants** et que la tâche `[TEST]` correspondante (T002) les asserte tous les deux. Le guide
  humain sous-couvrait donc sa propre preuve automatisée, et son récapitulatif omettait FR-005.
  **Corrigé** : une étape « code de l'interface mal typé » ajoutée au scénario 1 (désormais six
  tentatives), FR-005 ajouté à sa ligne « Prouve » et une ligne dédiée au récapitulatif. Le nombre de
  scénarios reste **12** — les renvois de `plan.md` et de T029 restent valides.
- **Constat 3 — la réconciliation d'effort de l'ARBITRAGE 7 n'était pas exacte.** `tasks.md`
  annonçait un écart « réconcilié **exactement**, dans les deux sens » de +3.5 j, mais son
  itemisation comportait **deux erreurs qui se compensaient** : la ligne « tâches moins chères »
  omettait `9h` T6 (1.0 j) → T017 (0.75 j), soit −0.25, et T029 (0.25 j) était déclarée *non imputée*
  alors qu'elle **est** comptée dans le tableau de phases qui somme à 10.0 j. Le total était donc
  juste par compensation, mais le détail ne l'était pas — précisément le défaut que le mot
  « exactement » interdit. **Corrigé** : `9h` T6 → T017 ajouté à la ligne des tâches moins chères
  (désormais **trois**, −1.00), T029 imputée (+0.25), et la chaîne de calcul rendue explicite jusqu'au
  total du tableau de phases : 0.25 + 2.75 + 1.25 + 0.25 − 1.00 = +3.5, puis 6.5 + 3.5 = 10.0.

- **Constat 4 — la liste des exigences hors chaîne était incomplète.** `research.md`, `plan.md`,
  `tasks.md` (T025) et `contracts/quality-gates.md` annonçaient **trois** exigences échappant à la
  chaîne et prouvées au canari (S06, S09, S20). La revue croisée de **S02** en a fait apparaître une
  **quatrième**, et la plus gênante : les cibles de collecte `up` et les cartes rafraîchies à 1 Hz
  (S02 `SC-001`, `SC-004`) exigent les moteurs et les cartes réelles, donc la porte 5 **dès M0** —
  alors que `9e` demande au même jalon « dashboards GPU vivants » **et** « CI verte ». Une exigence
  hors chaîne qu'aucun artefact ne nomme est une exigence qu'on croira couverte.
  **Corrigé** : les quatre emplacements passent à quatre, avec la colonne de jalon, et
  `contracts/quality-gates.md` est désigné **liste unique** (Art. 19) que toute spec découvrant un cas
  de ce type doit compléter. Propagation faite dans le même changement (Art. 13).

**Vérifications passées sans constat** : somme des efforts par phase (10.0 j, exacte au quart de jour)
· nombre de tâches (29, conforme à l'annonce) · couverture des **30** exigences par au moins une tâche
(100 %) · couverture des **11** critères de succès par **exactement une** tâche `[TEST]` chacun ·
concordance des trois tables de traçabilité (`spec.md`, `tasks.md`, `quickstart.md`) · 23 lignes au
Constitution Check · **huit** arbitrages, identiques dans les quatre artefacts qui les citent · aucune
plateforme d'intégration nommée · aucun `NEEDS CLARIFICATION` résiduel.

**Traçabilité critère → preuve** : chaque critère de succès est prouvé par **une seule** tâche `[TEST]`
de `tasks.md`, jamais par une tâche d'implémentation (Art. 8) — A1 → SC-001 → **T002** · A2 → SC-002 →
**T020** · A3 → SC-003 → **T015** · consigne « la CI ne touche jamais un GPU » → SC-004 → **T020**.
Les `Tn` de la fiche `9h` — T10 pour sa tâche de preuve, T8 et T9 pour les étapes de chaîne — sont des
**références de traçabilité**, pas des preuves. SC-009 n'a **aucune tâche de `9h`** — exigence
postérieure au document — et sa preuve **existe** : **T003**, qui vérifie la garde de topologie en même
temps que l'absence de seconde déclaration des portes. La table complète figure dans la spec.

**Réserves assumées, non des défauts de la spec**

- **Huit arbitrages restent ouverts** et sont consignés dans la spec — registre unique —, jamais
  devinés (Art. 7) : forge et exécuteur de la chaîne (le plus urgent — FR-029 et FR-030 le supposent
  tranché) · rattachement de `alembic check` à S03 ou S04 · chemin du guide du contributeur · FR-017 et
  la dépendance à S01 · amendement de `10a` si les portes doivent devenir des entités · `10a` annonce
  22 articles quand la constitution ratifiée en compte 23 · écart d'effort entre le découpage en tâches
  et le « ≈ 6.5 j-agent » de `9h` · `10b` fixe « tâches : `S<nn>-T<n>` » quand le format Spec Kit
  prévaut. `plan.md`, `tasks.md` et `research.md` n'en rappellent que les incidences (Art. 19).
- **Aucune plateforme d'intégration n'est nommée** dans la spec ni dans aucun artefact de conception :
  le fichier de définition peut être nommé `ci.yaml` (`9b`), son emplacement et sa plateforme non.

**Points d'attention pour le plan** *(état après itération 2)*

1. FR-002 / SC-005 exigent l'**équivalence** des portes de rang 1 à 3 entre local et chaîne, obtenue
   par **définition unique** — le plan doit dire où vit cette déclaration unique, et **ne pas** écrire
   de test de parité.
2. FR-012 impose une **implémentation unique** du moteur factice, empaquetée pour être consommée par
   toutes les specs. Le plan doit en faire un composant distribuable, pas un fichier de test copié.
3. Les **trois épinglages** ne se confondent pas : dépendances (verrou) · images **construites**
   (FR-019, condition du retour arrière par ré-étiquetage, articulé avec S01) · briques **consommées**
   par la chaîne (FR-026).
4. FR-029 / FR-030 doivent être **outillés**, pas seulement affirmés, et **indépendamment de toute
   plateforme** : une conformité à l'Art. 23 revendiquée sans garde est une affirmation, pas une porte.
5. FR-027 : le plan doit porter une **étape** de charge. Une dépendance déclarée sans porte n'est pas
   une porte.

**Résultat** : tous les items passent. Spec à jour et cohérente avec la constitution v1.1.0
(23 articles). Après l'itération 3, les **huit** artefacts sont cohérents entre eux : S03 est **prête
pour `/speckit-implement`**, sous la seule réserve des huit arbitrages ci-dessus — dont **aucun ne
bloque le démarrage** des tâches, l'ARBITRAGE 1 (forge et exécuteur) conditionnant uniquement le volet
*promotion* de FR-029 / FR-030, explicitement laissé sans tâche.
