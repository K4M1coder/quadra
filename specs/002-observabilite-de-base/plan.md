# Implementation Plan: S02 — Observabilité de base

**Branch**: `002-observabilite-de-base` | **Date**: 2026-08-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-observabilite-de-base/spec.md`

## Summary

Établir **la source unique de métriques** de la plateforme, **avant tout code métier** : collecte de
tous les composants, exposition des mesures matérielles par carte GPU, tableaux de bord provisionnés
depuis le dépôt, routage des alertes, conservation 90 jours.

**Approche technique** : S01 a démarré les conteneurs ; S02 en fournit **la configuration**. Toute
définition — cibles de collecte, tableaux de bord, routes de notification — vit **dans le dépôt** et
est **réappliquée au démarrage**, jamais seulement importée une fois. C'est la différence entre
respecter l'Art. 19 et le contourner.

**Point de vigilance principal** : la tentation d'ajuster un tableau de bord directement dans
l'interface de visualisation. Le plan la rend impossible par construction — le provisionnement
réapplique le dépôt à chaque démarrage, et une modification manuelle ne survit pas.

## Technical Context

**Language/Version** : aucun code applicatif. Les artefacts sont **déclaratifs** : configuration de
collecte, définitions de tableaux de bord, configuration de routage d'alertes, provisionnement. La
seule logique est un **contrôle de conformité des libellés** (interdiction de données personnelles et
de cardinalité libre), exécuté en intégration continue.

**Primary Dependencies** *(après décision D1 — voir ci-dessous)* :

| Rôle | Composant | Version retenue | Licence |
| --- | --- | --- | --- |
| Collecte de métriques | prometheus | **3.x LTS** (amont) | Apache-2.0 |
| Routage d'alertes | alertmanager | **amont courant** | Apache-2.0 |
| Visualisation | grafana | **13.x** (amont) | AGPL-3 |
| Métriques matérielles GPU | dcgm-exporter | épinglé par digest | NVIDIA |

**Storage** : volume `promdata`, créé par S01, **configuré ici** avec une rétention de **90 jours**.

**Testing** : contrôle de l'état des cibles, présence et conformité des tableaux de bord après
démarrage sur stockage de visualisation vide, vérification de la rétention à 89 j / 91 j. Aucun GPU
requis pour la majorité des contrôles ; l'exportateur matériel est le seul à en exiger un.

**Target Platform** : machine unique, réseau interne de la composition. Le libellé d'hôte est prévu
par la convention de nommage mais n'est exercé qu'à partir de S19.

**Performance Goals** : interrogation du matériel GPU à **1 seconde**, des autres cibles à
**5 secondes**. Ces cadences sont un compromis assumé : assez fin pour capter un pic thermique, assez
lâche pour ne pas peser sur les moteurs.

**Constraints** :

- **Aucune seconde chaîne de mesure** dans tout le projet (Art. 19). Toute vue de métrique lit celle-ci.
- **Aucune donnée personnelle ni valeur à cardinalité libre** dans un libellé (Art. 1).
- **Aucun tableau de bord créé à la main** : le dépôt fait autorité, réappliqué au démarrage.
- **Aucune télémétrie sortante.** Seules sorties : notifications d'alerte vers destinataires internes.

**Scale/Scope** : 4 familles de cibles, 2 tableaux de bord, 1 source de données, N routes de
notification par gravité.

### Décisions issues de la veille — **arbitrées**

Référence : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md), §1 et §7.

- **D1 — épingler l'amont actuel.** S02 est directement concernée : le document épingle Prometheus 2
  et Grafana 11, l'amont est à 3.x LTS et 13.x. La décision retenue est l'amont, épinglé par digest.
  **Conséquence concrète** : la ligne de commande et le format de configuration de la collecte ont
  évolué entre les majeures — la tâche T1 doit être écrite pour la version retenue, pas transposée
  depuis un exemple ancien.

## Constitution Check

*GATE : à franchir avant la génération des tâches. Ré-évalué après la conception détaillée.*

| Art. | Exigence | Statut | Comment S02 s'y conforme |
| --- | --- | --- | --- |
| 1 | Données sur site | ✅ | **Article central de cette spec.** Libellés = identifiants stables uniquement, jamais de contenu ni de donnée personnelle. Aucune télémétrie sortante ; seules sorties = notifications internes. Vérifié par SC-006. |
| 2 | Humain interactif d'abord | ➖ | Sans objet : S02 n'ordonnance rien. La cadence de collecte est choisie pour ne pas peser sur les moteurs. |
| 3 | Consentement explicite | ➖ | Aucune action coûteuse ni irréversible. |
| 4 | Tout est tracé | ✅ | S02 **est** l'infrastructure de traçabilité côté mesures. Le journal d'audit (S13) en est le pendant côté actions. |
| 5 | Le serveur décide | ➖ | Aucune permission dans S02. |
| 6 | Réutiliser, ne jamais forker | ✅ | Métriques des moteurs **réexposées telles quelles**, sans renommage (FR-009). Aucun correctif amont. |
| 7 | La spec avant le code | ✅ | Spec S02 figée et validée avant ce plan. |
| 8 | Qualité mécanique | ✅ | Preuve T8 tracée critère→preuve. Aucun chemin à revue humaine. |
| 9 | Simplicité | ✅ | Une chaîne de collecte, pas deux. Configuration déclarative, lisible d'un fichier. |
| 10 | Tests d'abord | ✅ | T8 écrit depuis A1–A3 ; le contrôle de rétention (89 j / 91 j) est écrit avant la configuration. |
| 11 | Rien ne flotte | ✅ | Images épinglées par digest, comme S01. |
| 12 | Langage ubiquitaire | ✅ | **Convention de nommage des métriques imposée** (FR-008) et des tableaux de bord (FR-015), dérivée de la taxonomie. |
| 13 | Doc et changelog | ✅ | Tout changement de cible ou de tableau de bord est un changement versionné, revuable. |
| 14 | Histoire atomique | ✅ | Un tableau de bord = un fichier = un changement. |
| 15 | Boucles bornées | ➖ | Aucune boucle agentique. Les actions automatiques d'alerte relèvent de S15. |
| 16 | La revue trie | ✅ | Un tableau de bord modifié se lit en revue comme un diff de fichier — c'est l'effet recherché. |
| 17 | Le code modèle le domaine | ✅ | Entités rattachées à l'arbre de l'observation (Metric → Dashboard / Alert rule / Audit entry). |
| 18 | Modules SOLID | ✅ | Ajouter une cible = ajouter une entrée de configuration, sans toucher au reste. |
| 19 | Une connaissance, un endroit | ✅ | **Article central.** Source unique de métriques (FR-007) ; le dépôt fait autorité sur les tableaux de bord (FR-012) ; réapplication au démarrage. |
| 20 | YAGNI | ✅ | Ni hub interne, ni éditeur de règles, ni heatmap — tout cela est S15. S02 pose la collecte et le routage, rien de plus. |
| 21 | Sécurité continue | ✅ | Le contrôle de libellés est aussi un contrôle de fuite : aucune donnée personnelle ne peut entrer dans une série temporelle. |
| 22 | État de l'art | ✅ | Veille consignée, D1 arbitrée. Écart de majeures documenté et pris en compte dans T1. |

**Verdict** : porte **franchie**. `Complexity Tracking` vide.

## Project Structure

### Documentation (this feature)

```text
specs/002-observabilite-de-base/
├── plan.md              # Ce fichier
├── research.md          # Phase 0
├── data-model.md        # Phase 1 — objets d'observabilité
├── quickstart.md        # Phase 1 — guide de validation
├── contracts/
│   └── metrics.md       # Contrat de la surface de métriques + provisionnement
├── checklists/
│   └── requirements.md  # Déjà produite
└── tasks.md             # Produit par /speckit-tasks
```

### Source Code (repository root)

```text
deploy/
├── prometheus/
│   └── prometheus.yml           # Cibles, cadences, rétention (T1, T6)
├── alertmanager/
│   ├── alertmanager.yml         # Routes par gravité (T5)
│   └── templates/               # Gabarits de notification (T5)
└── grafana/
    ├── provisioning/
    │   ├── datasources/         # Source de données (T2)
    │   └── dashboards/          # Déclaration de provisionnement (T2)
    └── dashboards/
        ├── ds-gpu.json          # Tableau de bord matériel (T3)
        └── ds-engines.json      # Tableau de bord moteurs (T4)

gateway/
└── observability/
    └── labels.py                # Contrôle de conformité des libellés (transverse)

tests/
└── observability/
    └── test_labels.py           # Interdiction PII / cardinalité libre
```

**Structure Decision** : S01 a créé les répertoires **vides** ; S02 les **peuple**. Cette frontière,
posée dans les deux specs, évite que les deux se disputent les mêmes fichiers. Les tableaux de bord
sont nommés `ds-<domaine>.json` conformément à la convention 10b.

## Étapes d'implémentation

### J1 — Collecte *(admin : toutes les métriques sont captées et gardées 90 j)*

1. **T1** Configuration de collecte : quatre familles de cibles (plan de contrôle, moteurs,
   exportateur matériel, la collecte elle-même), avec leurs cadences — **1 s pour le matériel,
   5 s ailleurs**. *Écrire pour la majeure retenue en D1, pas transposer un exemple ancien.*
2. **T2** Provisionnement de la source de données, depuis le dépôt.
3. **T6** Rétention **90 jours** et rattachement du volume persistant.

### J2 — Surface *(admin : tableaux de bord auto-provisionnés, alertes routées)*

1. **T3** Tableau de bord matériel : température, puissance, mémoire vidéo **par carte**, versionné.
2. **T4** Tableau de bord moteurs : latence du premier jeton, latence inter-jetons, profondeur des
   files, versionné.
3. **T5** Routage d'alertes par gravité + gabarits de notification, versionnés.

### J3 — Preuves

1. **T7** `[INT]` la collecte atteint le plan de contrôle démarré par S01.
2. **T8** `[TEST]` toutes les cibles joignables · tableaux de bord chargés sur stockage vide ·
   rétention vérifiée à 89 j et 91 j.

## Consignes d'implémentation

- **Réapplication, pas import.** Le provisionnement doit **réappliquer** les définitions à chaque
  démarrage. Un import unique laisserait une modification manuelle survivre, ce qui contredirait
  FR-012 et l'Art. 19. C'est le point relevé en revue de la spec : à vérifier explicitement par un
  test qui modifie un tableau de bord, redémarre, et constate le retour à la définition versionnée.
- **Libellés : identifiants seulement.** Le contrôle automatisé rejette toute valeur à cardinalité
  libre — identifiant de requête, texte utilisateur, adresse. C'est une protection contre la fuite
  autant que contre l'explosion de cardinalité.
- **Réexposer les métriques amont telles quelles** (FR-009). Ne pas renommer pour « harmoniser » :
  ce serait un fork déguisé (Art. 6) et cela romprait la correspondance avec la documentation amont.
- **Les métriques métier n'existent pas encore.** À M0, seuls l'exportateur matériel, les moteurs et
  la santé du plan de contrôle sont réellement peuplés. Les familles de S04, S05 et S08 sont
  collectées dès qu'elles apparaissent, sans changement de configuration si le nommage est respecté.
- **Aucun tableau de bord n'est créé pour des métriques inexistantes** (Art. 20) : les deux tableaux
  de bord de S02 portent sur le matériel et les moteurs, qui existent à M0.

## Complexity Tracking

*Aucune violation. Section vide.*
