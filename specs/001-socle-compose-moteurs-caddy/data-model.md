# Phase 1 — Modèle de données : S01 Socle compose + moteurs + Caddy

**S01 ne crée aucune entité du domaine métier** et **aucune table**. Le premier schéma relationnel
est introduit par S04 (organisations, teams, utilisateurs, clés).

Ce document décrit les **objets de déploiement** manipulés par S01. Ils se rattachent à l'arbre
d'exécution de la taxonomie (Cluster → Host → Node → Engine → Instance), dont S01 matérialise
le socle physique : un hôte unique et les processus qui y tournent.

---

## Service de la pile

Unité déployable du socle.

| Attribut | Type | Règle |
| --- | --- | --- |
| `nom` | identifiant | **repris tel quel de l'énumération de `9f`**, unique dans la composition (Art. 12) |
| `image` | référence | **digest exact obligatoire** ; toute référence mouvante — marqueur flottant, branche, **intervalle ouvert** — est rejetée (Art. 11, FR-012) |
| `réseau` | référence | `quadra-net`, réseau interne unique ; **aucun port publié** sauf `caddy` (443) |
| `sonde de santé` | définition | obligatoire pour **tout** service (FR-009) |
| `dépendances` | liste | services dont l'état sain conditionne le démarrage (FR-009) |
| `politique de redémarrage` | énuméré | assure la reprise après défaillance et après redémarrage machine (FR-010) |
| `volumes montés` | liste | volumes nommés uniquement |

**Instances attendues** (9), graphie de `9f` : `caddy` · `sglang` · `llama.cpp` · `postgres` · `redis` ·
`prometheus` · `alertmanager` · `grafana` · `dcgm-exporter`. Leur rôle fonctionnel — reverse proxy,
moteur principal, moteur format fichier unique, base relationnelle, cache, collecte de métriques,
routage d'alertes, visualisation, exportateur de métriques GPU — est celui que `spec.md` emploie ; les
identifiants ci-dessus sont ceux de la définition de déploiement.

**États observables** : `démarrage` → `sain` · `en échec` (sonde rouge) · `redémarrage`.
**Ce ne sont pas des états du domaine.** Ce sont ceux du moteur de conteneurs : `10d` ne définit aucune
machine à états pour un service de la pile, et l'Art. 17 interdit d'en créer une sans amendement
préalable. Ils ne sont ni stockés, ni exposés en API, ni affichés comme un état métier ; les états de
`Instance` / `Engine` (`loading` → `ready` → `draining` → `stopped`, `10d`) appartiennent à S06 et S07.

---

## Volume nommé

Espace de stockage persistant, distinct par usage.

| Volume | Usage | Note |
| --- | --- | --- |
| `/data/models` | poids des modèles téléchargés | ~1,8 To ; **exclu du dump de sauvegarde** (S21) car re-téléchargeable, son `checksum` étant en base |
| `/data/offload` | `offload` — opt-in par job | ~400 Go ; **créé mais monté par aucun service** — attend S18 (Art. 3, Art. 20). Provision consignée en réserve au Constitution Check de `plan.md`, ligne Art. 20 |
| `pgdata` | données relationnelles | sauvegardé (S21) |
| `promdata` | séries temporelles de métriques | rétention 90 j, configurée par S02 |

Graphie de `5b` et de FR-004, employée telle quelle (Art. 12) — jamais « débordement mémoire » pour
`offload` (`10c`).

**Règle** : volumes **nommés** exclusivement — la persistance doit survivre à la recréation des
conteneurs (SC-007). Aucun montage anonyme.

---

## Route publiée

Correspondance entre un chemin exposé sur le point d'entrée TLS et le service interne qui le sert.

| Route (`10b`) | Rôle | Destination | Contrat introduit par |
| --- | --- | --- | --- |
| `/v1` | inférence | plan de contrôle | contrat figé par **S04** |
| `/api` | administration | plan de contrôle | **S04** et suivantes |
| `/ws` | temps réel | plan de contrôle | **S05**, **S11** |
| `/grafana` | tableaux de bord | visualisation | **S02** |

**S01 déclare les routes ; il n'en définit pas le contrat.** Le contrat d'interface est figé par S04
(réf. `9i` T9 — « contrat OpenAPI `/v1` figé (humain) »). C'est la frontière qui évite que S01 anticipe
une surface qu'il ne spécifie pas.

---

## Variable d'environnement

Paramètre de configuration nommé, documenté, validé au démarrage.

| Attribut | Règle |
| --- | --- |
| `nom` | UPPER_SNAKE **préfixé `QUADRA_`** (convention `10b`) ; aucun autre espace de noms n'est autorisé pour les variables propres à la plateforme (FR-014) |
| `requise` | booléen — si requise et absente, le démarrage échoue |
| `valeur par défaut` | présente dans `.env.example` quand elle existe |
| `description` | obligatoire dans `.env.example` |
| `secret` | si vrai, `.env.example` ne contient qu'une **valeur factice explicitement marquée** (Art. 21) |

**Validation** : le démarrage **s'interrompt**, le message nomme la variable fautive **et** la
correction attendue, **aucun service n'est laissé démarré** (FR-015, SC-006). **Aucun délai chiffré
n'est exigé** — aucune source n'en fixe un.

---

## Fichier de gouvernance à la racine

Objet imposé par `10b` (« Racine : `CONSTITUTION.md` · `CHANGELOG.md` ») et, pour le premier, confié à
S01 par le § Governance de la constitution.

| Fichier | Règle |
| --- | --- |
| `CONSTITUTION.md` | **copie de référence** de la constitution ratifiée ; source unique = `.specify/memory/constitution.md` (Art. 19). Jamais éditée directement — un amendement passe par l'outil de gouvernance. Les deux copies **portent la même version** ; un contrôle automatisé compare et échoue à la moindre divergence (FR-019, SC-008). Destination : injection dans le contexte de chaque agent avant tout travail. |
| `CHANGELOG.md` | format **Keep a Changelog**, versionnement **SemVer** (Art. 13, `10b`). L'entrée du changement qui livre S01 y figure, écrite **dans ce même changement** (FR-020, SC-009). |

Ce ne sont pas des entités du domaine : ce sont des artefacts de gouvernance du dépôt, sans
représentation en base ni en API.

---

## Référence d'image épinglée

Objet transverse, source unique des versions (Art. 19) — un fichier unique du dépôt le porte
(`deploy/digests.yml`, voir `plan.md`).

| Attribut | Règle |
| --- | --- |
| `composant` | nom du service, graphie de `9f` |
| `digest` | empreinte exacte — **seul champ faisant foi** |
| `version lisible` | commentaire humain, **jamais** utilisé pour résoudre l'image |
| `digest précédent` | valeur épinglée avant la dernière montée — le référent du retour arrière (FR-021) |
| `licence` | consignée **quand `5a` en attribue une** ; sinon la case le dit, aucune licence n'est déduite |

**Contrainte** : un contrôle automatisé rejette toute référence dépourvue de digest (réf. `9f` T10,
SC-003), y compris un intervalle de versions ouvert.

**Retour arrière** : re-pointer le `digest précédent` **dans ce seul fichier**, puis redémarrer le
service par **une seule commande** — aucune reconstruction d'image, aucun autre fichier modifié, aucune
substitution par une version autre que celle précédemment épinglée (FR-021, prouvé par SC-010). C'est
le « rollback en une commande » de l'Art. 9, rendu possible par l'Art. 11, et la lecture de `w10`. La
version effectivement en service reste **lisible depuis la définition de déploiement** ; son affichage
dans une vue de santé (`6g`) relève de S21.
