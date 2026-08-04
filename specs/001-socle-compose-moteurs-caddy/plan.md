# Implementation Plan: S01 — Socle compose + moteurs + Caddy

**Branch**: `001-socle-compose-moteurs-caddy` | **Date**: 2026-08-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-socle-compose-moteurs-caddy/spec.md`

## Summary

Rendre l'infrastructure complète démarrable par **une commande unique** sur une machine vierge :
reverse proxy terminant le TLS et seul port publié, moteurs d'inférence épinglés par digest, bases de
données, chaîne d'observabilité. Le socle sur lequel les vingt autres specs se posent.

**Approche technique** : une composition de conteneurs unique décrit l'ensemble des services sur un
réseau interne isolé ; seul le reverse proxy publie un port sur l'hôte. Toutes les images sont
référencées par **digest** (Art. 11), ce qui rend le canari et le retour arrière par ré-étiquetage
possibles. La configuration passe par un fichier d'environnement unique, **validé au démarrage** de
sorte qu'une pile mal configurée échoue vite plutôt que de démarrer à moitié.

**Point de vigilance principal** : le risque identifié de la phase 1 est la **combinaison
pilote GPU / CUDA / toolkit conteneur** — une seule est validée. Le plan la traite comme une
constante figée, pas comme une variable.

## Technical Context

**Language/Version** : aucun code applicatif dans S01. Les artefacts sont déclaratifs — composition de
conteneurs, configuration du reverse proxy, cibles de commandes, documentation. Le seul exécutable
est le **validateur de configuration au démarrage**, écrit dans le langage du plan de contrôle
(Python 3.12) pour être réutilisé par S04 plutôt que dupliqué (Art. 19).

**Primary Dependencies** — **versions retenues après décision D1** (voir ci-dessous). Toutes sont
épinglées **par digest** ; la colonne indique la version lisible correspondante.

| Rôle | Composant | **Version retenue** | Version du document (5a) | Licence |
| --- | --- | --- | --- | --- |
| Hôte | ubuntu-lts · docker · compose | 24.04 · 27 · v2 | idem | — |
| GPU | nvidia-driver · cuda · nvidia-ctk | **560 · 12.6** *(conservées, D2)* | idem | — |
| Moteur principal | sglang | 0.5.x | 0.5 | Apache-2.0 |
| Moteur format fichier unique | llama.cpp | b4102 | idem | MIT |
| Reverse proxy | caddy | 2.11.x | 2 | Apache-2.0 |
| Base relationnelle | postgresql | **18.x** | ~~16~~ *périmé* | PostgreSQL |
| Cache | redis | **8.x** | ~~7~~ *périmé* | BSD |
| Métriques | prometheus + alertmanager | **3.x LTS** | ~~2~~ *périmé* | Apache-2.0 |
| Visualisation | grafana | **13.x** | ~~11~~ *périmé* | AGPL-3 |
| Métriques GPU | dcgm-exporter | amont courant | — | NVIDIA |
| Sauvegarde | pg_dump + rsync | fournis par l'hôte | — | — |

> **Quatre lignes de la table 5a du document sont périmées** (base relationnelle, cache, métriques,
> visualisation) — décision **D1**. Le fichier de digests du dépôt fait foi (Art. 19). Le couple
> pilote GPU / CUDA est en revanche **conservé** tel quel (décision **D2**).

**Storage** : quatre volumes nommés, distincts par usage — `models` (NVMe, ~1,8 To), `offload`
(~400 Go, **provisionné mais inactif** : opt-in par job, S18), `pgdata`, `promdata` (rétention 90 j,
configurée par S02).

**Testing** : la preuve de S01 est une procédure automatisée sur **machine vierge** vérifiant
simultanément le délai de démarrage, l'exposition réseau et l'épinglage des digests (tâche T10).
L'outillage de test lui-même vient de S03, développée en parallèle.

**Target Platform** : machine unique Linux avec 4 cartes GPU. **Pas d'orchestrateur de cluster**
(Art. 9). Le multi-machines relève de S19–S20 et n'est pas anticipé ici (Art. 20).

**Performance Goals** : pile saine en **moins de 5 minutes** sur machine vierge ; échec de validation
de configuration en **moins de 10 secondes**.

**Constraints** :

- **Un seul port publié** sur l'hôte : le port TLS. Aucun port de moteur, de base, de cache ou
  d'observabilité.
- **Aucune référence d'image mouvante** — digest exact obligatoire, jamais de marqueur flottant.
- **Aucune sortie réseau** hors téléchargement de modèles et copie de sauvegarde (Art. 1).
- Topologie matérielle de référence : 4 cartes de 24 Go, limite de puissance 280 W, appairage par
  paires 0↔1 et 2↔3.

**Scale/Scope** : ~9 services conteneurisés, 4 volumes, 4 routes publiées, 1 réseau interne.

### Décisions issues de la veille — **arbitrées**

Référence et justification complète : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md), §7.

- **D1 — épingler l'amont actuel** (Postgres 18.x, Redis 8.x, Grafana 13.x, Prometheus 3.x LTS)
  plutôt que les versions du document. Aucun code n'existe : c'est le seul moment où la montée est
  gratuite. L'Art. 11 exige des versions **figées**, pas anciennes. **La table de dépendances 5a du
  document est périmée sur ces quatre lignes** ; le fichier de digests du dépôt fait foi (Art. 19).
- **D2 — conserver le pilote GPU et CUDA du document** (560 / 12.6). Le couple pilote/CUDA est le
  seul élément de la pile qu'on **ne peut pas valider en intégration continue** (Art. 8 : la CI ne
  touche jamais un GPU) ; ce qu'on ne peut pas tester, on ne le change pas sans banc. Révision au
  canari uniquement.

D1 et D2 ne se contredisent pas : les composants de D1 sont interchangeables derrière des interfaces
stables et testables sans GPU ; le couple pilote/CUDA ne l'est pas.

## Constitution Check

*GATE : à franchir avant la génération des tâches. Ré-évalué après la conception détaillée.*

| Art. | Exigence | Statut | Comment S01 s'y conforme |
| --- | --- | --- | --- |
| 1 | Données sur site | ✅ | Seul flux entrant : le port TLS. Sorties admises : téléchargement de modèles, copie de sauvegarde. Aucune télémétrie. Vérifié par SC-002 et SC-010 (S09). |
| 2 | Humain interactif d'abord | ➖ | Sans objet à ce stade : aucun ordonnancement dans S01. Le socle ne doit rien préempter. |
| 3 | Consentement explicite | ✅ | Le volume d'offload est **provisionné mais inactif** : aucune activation implicite. |
| 4 | Tout est tracé | ➖ | Le journal d'audit arrive en S13. S01 n'exécute aucune action sensible. |
| 5 | Le serveur décide | ➖ | Aucune permission ni UI dans S01. |
| 6 | Réutiliser, ne jamais forker | ✅ | Moteurs et briques consommés **tels quels**, uniquement démarrés. Aucun correctif appliqué à un composant amont. |
| 7 | La spec avant le code | ✅ | Spec S01 figée et validée (checklist qualité complète) avant ce plan. |
| 8 | Qualité mécanique | ✅ | La preuve T10 est une tâche `[TEST]` tracée critère→preuve. Aucun chemin à revue humaine dans S01. |
| 9 | Simplicité, opérable par un seul | ✅ | **Pas d'orchestrateur de cluster.** Une commande démarre, une commande arrête. Retour arrière par ré-étiquetage. |
| 10 | Tests d'abord | ✅ | T10 écrit depuis les critères A1–A3, exécuté rouge avant que la composition existe. |
| 11 | Rien ne flotte | ✅ | **Cœur du critère A3.** Digest exact pour chaque image ; échec explicite si un digest est indisponible (FR-013). |
| 12 | Langage ubiquitaire | ✅ | Nommage des services et volumes dérivé de la taxonomie ; aucun synonyme interdit. |
| 13 | Doc et changelog | ✅ | `docs/install.md` est une **tâche du même jalon** (T9), pas un suivi ultérieur. |
| 14 | Histoire atomique | ✅ | Une tâche = un changement cohérent ; hooks locaux fournis par S03. |
| 15 | Boucles bornées | ➖ | Aucune boucle agentique dans S01. Les politiques de redémarrage sont bornées par nature. |
| 16 | La revue trie | ✅ | Les portes de S03 s'appliquent dès le premier changement. |
| 17 | Le code modèle le domaine | ✅ | Les objets de S01 (service, volume, route) se rattachent à l'arbre d'exécution de la taxonomie. |
| 18 | Modules SOLID | ✅ | Chaque service a une responsabilité unique ; le reverse proxy est le seul point d'entrée. |
| 19 | Une connaissance, un endroit | ✅ | Le validateur de configuration est **partagé** avec S04, pas dupliqué. Les versions vivent dans un seul fichier. |
| 20 | YAGNI | ✅ | Périmètre borné par la section « Hors périmètre » de la spec. Volume d'offload provisionné mais **aucun mécanisme** d'offload. |
| 21 | Sécurité continue | ✅ | Aucun secret en dur ; le fichier d'environnement d'exemple ne contient que des valeurs factices. Scan de secrets fourni par S03. |
| 22 | État de l'art | ✅ | Veille consignée dans `RESEARCH-STACK.md` §1 et §2 ; décisions D1 et D2 signalées. |

**Verdict** : porte **franchie**. Aucun article violé, aucune dérogation demandée.
`Complexity Tracking` reste vide.

## Project Structure

### Documentation (this feature)

```text
specs/001-socle-compose-moteurs-caddy/
├── plan.md              # Ce fichier
├── research.md          # Phase 0 — décisions techniques et alternatives
├── data-model.md        # Phase 1 — objets de déploiement (pas d'entité métier)
├── quickstart.md        # Phase 1 — guide de validation exécutable
├── contracts/           # Phase 1 — contrat des routes publiées (surface only)
├── checklists/
│   └── requirements.md  # Checklist qualité de la spec (déjà produite)
└── tasks.md             # Phase 2 — produit par /speckit-tasks, PAS par ce plan
```

### Source Code (repository root)

```text
gateway/                 # Plan de contrôle (Python) — S04 et suivantes
└── config/
    └── settings.py      # Validateur de configuration au boot (T7) — seul code de S01

ui/                      # Interface d'administration — S11 et suivantes

deploy/                  # Tout l'artefact de déploiement de S01
├── docker-compose.yml   # 9 services, 4 volumes, réseau interne (T2, T3, T4, T6)
├── Caddyfile            # TLS auto + routes /v1 /api /ws /grafana (T5)
├── .env.example         # Toutes les variables, documentées (T7)
├── prometheus/
│   └── prometheus.yml   # Cibles et intervalles — peuplé par S02
├── alertmanager/
│   └── alertmanager.yml # Routes de notification — peuplé par S02
└── grafana/
    └── provisioning/    # Source de données + tableaux de bord — peuplés par S02

docs/
└── install.md           # Procédure machine vierge → pile saine (T9)

tests/
└── e2e/
    └── test_bare_metal_boot.py  # Preuve A1+A2+A3 sur machine vierge (T10)
                                 # harnais fourni par S03

Makefile                 # up / down / logs / ps (T8)
README.md                # Rôle de chaque répertoire (T1)
```

**Structure Decision** : arborescence **imposée par la fiche 9f** (`gateway/`, `ui/`, `deploy/`,
`docs/`). Le découpage sépare le **plan de contrôle** (code custom, Art. 6) de l'**artefact de
déploiement** (déclaratif). Les répertoires `prometheus/`, `alertmanager/` et `grafana/` sont **créés
vides par S01** et **peuplés par S02** : S01 fournit le point de montage, S02 le contenu — ce qui
évite que les deux specs se disputent les mêmes fichiers.

## Ordre de construction

Les jalons internes de la fiche 9f donnent l'ordre ; **`tasks.md` est la source unique du détail des
tâches** (Art. 19 — ne pas réénumérer T1..T10 ici, les deux listes divergeraient).

| Jalon | Intention | User story | Tâches |
| --- | --- | --- | --- |
| **J1** Fondations | le dépôt cloné démarre ses bases | US1 (P1) | voir [`tasks.md`](./tasks.md) |
| **J2** Cœur | une commande démarre moteurs, observabilité et TLS | US2 (P2) | idem |
| **J3** Surface | configuration par fichier, installation documentée | US3 (P3) | idem |
| **J4** Preuves | les trois critères prouvés sur machine vierge | — | idem |

**Contraintes d'ordre** : J1 précède J2 et J3 ; J3 est indépendante de J2 hormis la validation de
configuration ; J4 exige les trois précédents. Le détail des dépendances et des opportunités de
parallélisation est dans `tasks.md`.

## Consignes d'implémentation

- **Aucun port de moteur publié.** C'est le critère A2 et une exigence de sécurité : les moteurs
  n'exposent ni authentification ni TLS. Le contrôle est automatisable — un balayage doit ne trouver
  que le port TLS.
- **Digest, pas tag.** Un tag reste mouvant même s'il paraît figé. Le contrôle de T10 doit rejeter
  toute référence sans digest.
- **Volumes nommés, jamais de montage lié anonyme** — la persistance doit survivre à la recréation
  des conteneurs (SC-007).
- **Le fichier d'environnement d'exemple ne contient aucun secret réel**, seulement des valeurs
  factices explicitement marquées comme telles (Art. 21).
- **La validation de configuration est partagée avec S04** : elle vit dans le plan de contrôle et est
  invoquée au démarrage. Ne pas en écrire une seconde version dans les scripts de déploiement
  (Art. 19).
- **Le volume d'offload est créé mais n'est monté par aucun moteur** à ce stade. Il attend S18.

## Complexity Tracking

*Aucune violation de la porte Constitution Check. Section volontairement vide.*
