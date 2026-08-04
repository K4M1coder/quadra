# specify / Spec Kit — fichier de contrôle

> Ce fichier documente comment utiliser **specify** (GitHub Spec Kit) et la méthode SDD (« speckit ») qu'il installe dans un projet : quelles commandes, quels skills, quels scripts, quels agents, et dans quel ordre les enchaîner.
> Il est **agnostique du projet** : à poser tel quel à la racine de n'importe quel dépôt initialisé avec `specify init`, pour servir de repère à un agent (Claude Code ou autre) ou à un humain qui reprend le projet.
>
> Les chemins exacts, la variante de script (`sh` / `ps1` / `py`) et l'intégration installée (`claude`, `copilot`, `gemini`, `opencode`…) dépendent du choix fait à l'init de **ce** projet — vérifier `.specify/init-options.json` et `.specify/integrations/` en cas de doute. Les exemples ci-dessous utilisent la syntaxe PowerShell (`.ps1`) par défaut ; substituer par les jumeaux `.sh` / `.py` si le projet a été initialisé avec `--script sh` ou `--script py` (mêmes options, mêmes noms de flags).

## 1. Architecture — deux couches distinctes

« specify » désigne deux choses différentes selon le contexte :

- **Couche 1 — Outillage : `specify` (CLI)**
  Installé sur la machine (typiquement `~/.local/bin/specify`), indépendant du projet. Scaffold un projet, gère extensions / presets / bundles / catalogues, exécute des workflows d'automatisation déclaratifs (YAML). Utilisé une fois à l'init, puis ponctuellement pour maintenir le projet.

- **Couche 2 — Méthode SDD : skills `speckit-*`**
  Installés *dans* le projet par `specify init --integration <agent>` (ex. `.claude/skills/speckit-*` pour l'intégration Claude — le dossier varie selon l'agent choisi). Invoqués tout au long du cycle de développement : constitution → spec → plan → tasks → implement.

Ce fichier documente principalement la couche 2, celle qui vit dans le dépôt et que tout agent/humain reprenant le projet doit connaître.

## 2. Arbre des commandes CLI (résumé)

9 groupes de premier niveau. Les sous-groupes `catalog` / `step` / `overlay` gèrent des sources de configuration et se répètent avec la même forme (list / add / remove) à travers plusieurs primitives (extension, integration, preset, bundle, workflow) — ces primitives partagent le même modèle de résolution en couches.

| Groupe | Rôle |
|---|---|
| `init [project_name]` | Scaffold un nouveau projet Specify (`--script sh\|ps\|py`, `--here`, `--force`, `--integration`, `--preset`…) |
| `check` | Diagnostic environnement (agents détectés, git…) |
| `version` | Version du CLI, Python, plateforme |
| `self check` / `self upgrade` | Gestion du CLI lui-même |
| `extension` | Extensions spec-kit (list/add/remove/search/info/update/enable/disable/set-priority + `catalog`) |
| `integration` | Intégrations agent (Claude, Copilot, Codex…) : install/uninstall/switch/upgrade/list/status/use/search/info/scaffold + `catalog` |
| `preset` | Jeux de templates prédéfinis : list/add/remove/search/resolve/info/set-priority/enable/disable + `catalog` |
| `bundle` | Packages composites (extensions+presets+intégrations) : search/info/list/install/update/remove/validate/build/init + `catalog` |
| `workflow` | Automatisations déclaratives YAML : run/resume/status/list/add/remove/update/enable/disable/search/info/resolve + `catalog`/`step`/`overlay` |

Pour l'aide exhaustive et à jour d'un groupe donné : `specify <groupe> --help`.

## 3. Couche agent — cycle SDD (« speckit »)

Installée par `specify init --integration <agent>` sous `.<agent>/skills/speckit-*` (ou l'équivalent selon l'intégration). Le workflow déclaratif `speckit`, quand il est installé, orchestre 4 skills core avec deux portes de revue :

```
specify → [gate: review-spec] → plan → [gate: review-plan] → tasks → implement
```

| Skill | Rôle fonctionnel |
|---|---|
| `constitution` | Crée/met à jour la constitution du projet (principes directeurs). |
| `specify` | Crée/met à jour la spécification de fonctionnalité à partir d'une description en langage naturel. |
| `clarify` | Repère les zones sous-spécifiées via jusqu'à 5 questions ciblées, encode les réponses dans la spec. |
| `plan` | Génère les artefacts de conception à partir du template de plan. |
| `tasks` | Génère un `tasks.md` actionnable, ordonné par dépendances. |
| `checklist` | Génère une checklist personnalisée selon les exigences utilisateur. |
| `analyze` | Analyse de cohérence croisée non destructive entre `spec.md`, `plan.md`, `tasks.md`. |
| `implement` | Exécute le plan en traitant toutes les tâches de `tasks.md`. |
| `converge` | Évalue le code existant vs spec/plan/tasks, ajoute le travail manquant comme nouvelles tâches. |
| `taskstoissues` | Convertit les tâches en issues GitHub actionnables, ordonnées par dépendances. |

Seuls `specify`, `plan`, `tasks`, `implement` sont garantis « core » (présents dans toute intégration). Les autres skills peuvent être absents selon le preset/bundle installé — vérifier `.claude/skills/` (ou équivalent) du projet avant de s'appuyer dessus.

## 4. Skills & agents mobilisables

Deux registres distincts : les **skills speckit-*** (spécifiques à un projet spec-kit, décrits ci-dessus) et les **agents génériques** de l'outil agentique utilisé (Task tool, sous-agents…), indépendants de spec-kit et mobilisables à l'intérieur de n'importe quelle étape.

### 4.1 Anatomie d'un skill speckit-*

Chaque skill est un fichier `SKILL.md` sous `.claude/skills/speckit-{nom}/` (ou équivalent selon l'intégration), exposé comme commande slash `/speckit-{nom}`.

| Champ frontmatter | Rôle |
|---|---|
| `name` | Identifiant du skill, dérive le nom de la commande slash. |
| `description` | Résumé affiché dans la liste des skills disponibles. |
| `argument-hint` | Placeholder affiché après la commande. |
| `compatibility` | Précondition documentaire (ex. « requires .specify/ directory »). |
| `user-invocable` | Si `true`, l'utilisateur peut taper `/speckit-{nom}` directement. |
| `disable-model-invocation` | Si `true`, l'agent ne peut pas déclencher le skill de sa propre initiative. |

Chaque `SKILL.md` encode aussi un mécanisme de **hooks d'extension** commun : avant/après l'exécution, il lit `.specify/extensions.yml` et cherche des entrées sous `hooks.before_{nom}` / `hooks.after_{nom}`. Les hooks `optional: false` sont exécutés automatiquement (`EXECUTE_COMMAND`) et bloquent la suite tant qu'ils n'ont pas rendu la main — c'est ce qui délègue par exemple la création de branche git à une extension plutôt qu'au skill `specify` lui-même. Ce mécanisme n'existe que si le projet a installé des extensions ; en son absence, les skills s'exécutent sans hook.

### 4.2 Agents génériques disponibles en soutien

Table indicative — les agents réellement disponibles dépendent de l'outil agentique utilisé (Claude Code, autre) ; vérifier la liste courante en session plutôt que de supposer que ces noms existent partout.

| Agent (type usuel) | Quand le mobiliser dans le cycle SDD |
|---|---|
| Recherche ciblée (ex. `Explore`) | Recherche rapide dans le code. Utile avant `speckit-plan` / `speckit-tasks` pour repérer les fichiers critiques, ou avant `speckit-converge` pour situer le code déjà en place. |
| Recherche/exécution générale (ex. `general-purpose`) | Utile pendant `speckit-implement` pour paralléliser des tâches indépendantes, ou pendant `speckit-analyze` pour croiser plusieurs artefacts volumineux sans saturer le contexte principal. |
| Architecte de plan (ex. `Plan`) | Complémentaire de `speckit-plan` pour arbitrer un choix d'architecture avant de figer `plan.md`. |
| Guide outillage agent | Questions sur l'outil agentique lui-même (CLI, SDK, API) — hors périmètre SDD. |

Ces agents génériques s'insèrent **à l'intérieur** d'une étape — ils ne remplacent jamais une gate ni le rapport de complétion attendu par le skill suivant.

## 5. Scripts `.specify/scripts/`

Les skills ne contiennent aucune logique de résolution de chemins : ils délèguent systématiquement à des scripts sous `.specify/scripts/{powershell|bash|python}/` (variante choisie à l'init via `--script sh|ps|py` — un seul dossier existe normalement dans un projet donné). C'est la couche qui fait le pont entre l'état sur disque (branche git, répertoire de fonctionnalité, artefacts présents) et le raisonnement du skill.

| Script | Rôle | Invoqué par |
|---|---|---|
| `common.*` | Bibliothèque partagée (jamais appelée directement) : résolution de la racine `.specify/`, chemins de fonctionnalité, branche git courante, persistance de `.specify/feature.json`, résolution de template. | dot-sourced / importé par les 4 autres scripts |
| `create-new-feature.*` | Calcule le nom court, le préfixe (séquentiel `NNN` ou timestamp), crée `specs/<prefixe>-<nom>/` et optionnellement la branche git. Fallback quand aucune extension git n'est installée. | hook `before_specify` (extension git) ou appel manuel |
| `check-prerequisites.*` | Script de garde consolidé : valide l'existence de `plan.md` (et `tasks.md` si `--require-tasks`), liste les documents disponibles (`research.md`, `data-model.md`, `contracts/`, `quickstart.md`). En mode paths-only, résout juste les chemins sans valider. | clarify (paths-only), checklist, analyze / converge / implement / taskstoissues (`--require-tasks --include-tasks`) |
| `setup-plan.*` | Résout `FEATURE_SPEC`, `IMPL_PLAN`, `SPECS_DIR`, `BRANCH`. | speckit-plan |
| `setup-tasks.*` | Résout `FEATURE_DIR`, `TASKS_TEMPLATE`, `AVAILABLE_DOCS`. | speckit-tasks |

Options communes : `--json` (`-Json` en PowerShell) `--help`. Spécifiques à `check-prerequisites` : `--require-tasks` `--include-tasks` `--paths-only`. Spécifiques à `create-new-feature` : `--dry-run` `--allow-existing-branch` `--short-name` `--number` `--timestamp`. Tous sortent en JSON compact avec `--json`, le format attendu par les skills pour parser les variables sans ambiguïté.

## 6. Enchaînement — commandes, scripts, skills, agents

Deux modes d'exécution pour le même cycle SDD, tous deux passant par la même chaîne interne skill → hook → script → génération.

### 6.1 Mode automatisé (CLI)

```
specify workflow run speckit -i spec="<description>" [-i integration=auto] [-i scope=full]
```

```
speckit.specify → [review-spec, on_reject: abort] → speckit.plan → [review-plan, on_reject: abort] → speckit.tasks → speckit.implement
```

À vérifier au cas par cas dans `.specify/workflows/speckit/workflow.yml` : la version minimale de speckit requise (`requires.speckit_version`) et les intégrations compatibles déclarées (`requires.integrations.any`, liste indicative non fermée — le workflow tourne avec toute intégration exposant les 4 commandes core). Un rejet à une gate déclenche `on_reject: abort` ; une exécution interrompue se reprend avec `specify workflow resume {run_id}`.

### 6.2 Mode manuel — séquence de commandes slash

Usage courant au jour le jour : taper les commandes une à une, dans cet ordre, en insérant les étapes optionnelles selon le besoin. Pas de gate bloquante automatique ici — la revue humaine se fait en lisant les fichiers générés avant de passer à l'étape suivante.

1. **`/speckit-constitution`** *(optionnel, une fois par projet)* — écrit `.specify/memory/constitution.md`, lu ensuite par `speckit-specify`.
2. **`/speckit-specify "<description>"`** *(core)* — hook `before_specify` (branche git, optionnel) → génère `spec.md` depuis le `spec-template` résolu → checklist qualité (jusqu'à 3 itérations, jusqu'à 3 questions [NEEDS CLARIFICATION]) → hook `after_specify` → persiste le chemin dans `.specify/feature.json`.
3. **`/speckit-clarify`** *(optionnel)* — résout les chemins (paths-only) → jusqu'à 5 questions ciblées → réponses encodées dans `spec.md`.
4. **`/speckit-plan`** *(core)* — setup-plan → génère `plan.md` et les artefacts de conception (`research.md`, `data-model.md`, `contracts/`, `quickstart.md`).
5. **`/speckit-checklist`** *(optionnel)* — checklist personnalisée.
6. **`/speckit-tasks`** *(core)* — setup-tasks → `tasks.md` actionnable, ordonné par dépendances.
7. **`/speckit-analyze`** *(optionnel)* — check-prerequisites (`--require-tasks --include-tasks`) → analyse de cohérence croisée non destructive spec/plan/tasks.
8. **`/speckit-implement`** *(core)* — check-prerequisites (`--require-tasks --include-tasks`) → exécute toutes les tâches ; peut déléguer des lots indépendants à un agent de recherche/exécution générale (§4.2) pour paralléliser.
9. **`/speckit-converge`** *(optionnel — boucle)* — compare le code existant à spec/plan/tasks, ajoute les tâches manquantes, renvoie vers l'étape 8.
10. **`/speckit-taskstoissues`** *(optionnel — branche alternative)* — convertit `tasks.md` en issues GitHub, en substitut ou complément de l'étape 8.

### 6.3 Ce qui fait tenir la chaîne : l'état partagé, pas les arguments

Aucune commande ne passe le chemin de la fonctionnalité à la suivante en argument. Chaque skill résout l'état courant lui-même via son script (fonction de résolution de chemins dans `common.*`), qui lit `.specify/feature.json` (`feature_directory`) et la branche git courante. Ce découplage permet d'enchaîner les skills dans des sessions séparées, ou de reprendre le cycle après une interruption, sans ressaisir de chemins. Les agents génériques (§4.2) s'insèrent à l'intérieur d'une étape — ils ne remplacent jamais une gate ni le rapport de complétion attendu par le skill suivant.

---

*Ce fichier décrit la structure générique de GitHub Spec Kit. Les noms de dossiers, l'intégration installée et la variante de script effectivement présente dans ce dépôt doivent être vérifiés dans `.specify/` avant de s'appuyer sur les détails ci-dessus.*
