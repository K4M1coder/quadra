# Phase 1 — Contrat : definition of done mécanique (S03)

**Consommateurs** : **toutes** les specs du projet. C'est le contrat qui rend la délégation aux
agents possible — l'Art. 8 en fait la condition pour « ne relire à la main que auth, facturation et
proxy streaming ».

---

## Contrat 1 — Les portes, dans l'ordre

Deux numérotations coexistent et ne doivent pas être confondues.

### Rangs de l'Art. 8 — ce qui garde quoi

| Rang | Porte | Contenu | Où |
| --- | --- | --- | --- |
| 1 | **validation locale** | style, format, **scan de secrets**, message de validation (`scope` = spec) | locale + distante |
| 2 | **contrôles de la chaîne** | typage strict · pyramide et **seuils de couverture** · **cohérence des migrations** · analyse statique et audits de dépendances | locale + distante |
| 3 | **construction d'images épinglées** | images étiquetées **version + digest** (FR-019) | locale + distante |
| 4 | **bout en bout et charge** | environnement éphémère + moteur factice ; **la charge bloque** | distante |
| 5 | **canari GPU** | hors chaîne — relève de l'exploitation | hors chaîne |

**Garde de topologie (Art. 23)** : les rangs **1 à 3** gardent l'**entrée dans `dev`** ; les rangs
**4 et 5**, qui n'existent qu'à distance, gardent la **promotion de `test`**.

**Le rang 3 s'exécute aussi en local** : `9b` fournit la cible `make build`, FR-002 range les rangs
**1 à 3** dans l'ensemble couvert par l'équivalence locale ↔ chaîne, et FR-029 leur fait garder
l'entrée dans `dev`. Seuls les rangs **4 et 5** sont purement distants — c'est le périmètre exact de
SC-005.

### Ordre d'exécution de la chaîne (FR-013) — affinement des rangs 1 à 4

style et formatage → typage → tests et couverture → contrôles de sécurité → construction des images →
**bout en bout et charge**.

Six étapes, dont la dernière est **une porte unique** : Art. 8 porte 4 dit « e2e + charge sur compose
éphémère », `9b` dit « e2e + k6 · compose éphémère · moteur factice ». Il n'existe pas d'étape de
charge séparée, et il n'existe pas de charge sans porte.

**Règle absolue** : **rien ne fusionne tant qu'une porte est rouge** (FR-014). Il n'existe pas de
contournement, pas de « on corrigera après ». Désactiver une porte pour faire passer un changement
est qualifié de **faute** par l'Art. 14, pas de mitigation.

---

## Contrat 2 — Équivalence locale ↔ chaîne

| Engagement | Comment il est tenu |
| --- | --- |
| Les portes de rang 1 à 3 s'exécutent **à l'identique** en local et à distance | **définition unique** — les cibles du `Makefile` (`9b`) ; les deux côtés les **invoquent** |
| Un état **vert en local prédit** un état vert à distance | Art. 14 |
| Les portes 4 et 5 n'existent qu'à distance | par nature (environnement éphémère, canari) |

**Ce qui n'est pas exigé** : aucun **mécanisme de comparaison** entre les deux listes. SC-005 est
explicite — « l'équivalence est obtenue par une définition unique des portes, versionnée et invoquée
de part et d'autre ; aucun test de parité entre les deux n'est exigé : la constitution demande
l'équivalence, pas un mécanisme de comparaison ». Une table de comparaison serait une **seconde
source de vérité** sur ce que sont les portes (Art. 19).

**Ce qui reste à surveiller en revue** : une étape de chaîne qui **redéclare** un contrôle au lieu
d'invoquer sa cible. C'est là — et seulement là — que la divergence redevient possible ; c'est un
constat de revue (Art. 16).

---

## Contrat 3 — Seuils de couverture

| Périmètre | Seuil | Statut |
| --- | --- | --- |
| **Cœur** — authentification, quotas, comptabilité | **≥ 90 %** | bloquant |
| Hors cœur | **≥ 70 %** | bloquant |

- **Mesurés par l'outillage**, avec sortie capturée. Un chiffre annoncé n'est pas une couverture.
- **Fixés par la constitution** — non négociables spec par spec.
- **Nécessaires, non suffisants** : le seuil ne prouve pas que les tests assertent. Le cycle
  rouge → vert reste dû pour tout comportement (Art. 10). C'est une limite assumée de
  l'automatisation, énoncée dans la documentation de contribution (dont le chemin n'est fixé par
  aucune source — ARBITRAGE 3).

---

## Contrat 4 — Definition of done d'une tâche

Une tâche est terminée quand, **et seulement quand** :

1. style et typage **propres** ;
2. tests **écrits et verts** ;
3. couverture **au seuil** de son périmètre ;
4. contrat d'interface **inchangé ou versionné**.

**Propriété recherchée** : ces quatre points sont **mécaniquement vérifiables**. C'est ce qui permet
de confier une tâche à un agent et de ne pas relire chaque ligne — le critère remplace le jugement.

**En l'absence de chaîne** (régime de l'Art. 23) : la **sortie capturée** des portes locales EST la
definition of done. Dès que la chaîne existe, son usage devient **obligatoire et exclusif** (FR-030).

---

## Contrat 5 — Aucun accès GPU dans la chaîne

| Règle | Conséquence |
| --- | --- |
| La chaîne **ne touche jamais un GPU** | contrainte d'architecture, pas limitation temporaire |
| Les vrais moteurs ne sont exercés **qu'au canari** | la chaîne reste rapide et reproductible |

**Sept preuves du projet échappent donc à la chaîne** — à dire explicitement dans les plans concernés
plutôt que de les croire couvertes. **Deux causes distinctes, que l'Art. 8 ne traite pas de la même
façon** : ce qui échappe **par le matériel** reste une porte, la **porte 5**, et se rejoue au banc /
canari ; ce qui échappe **par un jugement humain** n'est pas une porte du tout — aucune mécanique ne
la rejouera, et l'article n'en fait pas une. Confondre les deux ferait croire qu'une recette manuelle
finira par entrer dans la chaîne.

### Échappent par le matériel — porte 5 (banc / canari)

| Exigence ou preuve | Spec | Jalon | Ce que le matériel impose |
| --- | --- | --- | --- |
| Cibles de collecte `up` et cartes rafraîchies à 1 Hz | **S02** (SC-001, SC-004) | **M0** | les moteurs et les cartes réelles |
| Pile saine < 5 min, seul 443 exposé, digests inspectés | **S01** (T011 — SC-001, SC-002, SC-003, SC-005, SC-007) | **M0** | machine de référence à **4 GPUs**, **redémarrage machine**, **balayage depuis une autre machine**. Seule l'assertion sur les digests est, en elle-même, rejouable sans GPU |
| Découverte de topologie matérielle | **S06** (SC-001) | M1 | de vraies cartes appairées (`NVLink`) |
| Calibration du verdict de `fit` (20 modèles mesurés) | **S09** (SC-001) | M2 | 20 modèles mesurés |
| Débit additionné sur deux `host` | **S20** (SC-001) | M4 | deux `host` réels |

### Échappent par un jugement humain — hors porte

| Preuve | Spec | Jalon | Pourquoi aucune mécanique ne la rejoue |
| --- | --- | --- | --- |
| Installation par une personne n'ayant jamais vu le projet | **S01** (T015 — SC-004) | **M0** | exige une **personne tierce** ; le critère est « aucune question posée », pas un état qu'un programme observe |
| Rejeu englobant des scénarios de validation, sorties capturées | **S01** (T018 — **aucun critère à elle seule**) | **M0** | passe de recette qui **englobe** les preuves matérielles ci-dessus ; la chaîne ne peut pas en rejouer la moitié |

**La liste s'ouvre dès M0.** La ligne S02 vient de la revue croisée de cette spec et non de la
rédaction initiale de ce contrat : `9e` exige au **même jalon** « dashboards GPU vivants » et « CI
verte », ce qui mobilise la porte 5 dès M0. Les **trois lignes S01** viennent de la revue croisée
suivante : ni `9f`, ni `9b`, ni les artefacts de S01 ne les avaient inscrites ici, alors que S01 les
qualifiait déjà de **recette manuelle** dans son plan et dans ses tâches. Toute spec qui découvre une
preuve de ce type l'**ajoute ici** — ce contrat est la liste unique (Art. 19), et une preuve hors
chaîne qu'aucun artefact ne nomme est une preuve qu'on croira couverte. **S01 et S02 y renvoient au
lieu de la redéclarer.**

---

## Contrat 6 — Les trois chemins à revue humaine

L'Art. 8 nomme trois **chemins**, pas trois specs. En **plus** des portes mécaniques, tout changement
qui traverse l'un d'eux exige une relecture humaine ligne à ligne.

| Chemin (Art. 8) | Qui déclenche la revue |
| --- | --- |
| **Authentification** | toute spec qui touche ce chemin. `9d` en donne un cas explicite : « revue humaine sur S04 » |
| **Facturation** | toute spec qui touche ce chemin. Le document ne nomme aucune spec à ce titre |
| **Proxy de flux** | toute spec qui touche ce chemin. Le document ne nomme aucune spec à ce titre |

**S03 fournit le mécanisme** — la revue est une étape visible et tracée du processus, jamais une
politesse — et ne fige **aucune liste de specs**. S03 ne décide pas quel changement traverse quel
chemin ; c'est la spec concernée qui le porte, au titre du chemin qu'elle traverse.

`9d` nomme par ailleurs la **revue humaine des permissions (S13)** : elle s'ajoute aux trois chemins
sans en être un.

---

## Contrat 7 — Configuration versionnée

| Règle | Raison |
| --- | --- |
| **Toute** la configuration de portes est dans le dépôt | désactiver une porte devient un **diff visible en revue** |
| Aucune porte configurée hors du dépôt | sinon la désactivation est invisible |
| Les **gardes** — topologie de fusion, épinglage de la définition de chaîne — sont versionnées au même titre | une garde désactivable en silence ne garde rien |

Fichiers versionnés par `9b` : `pyproject.toml` · `.pre-commit-config.yaml` · `eslint.config.js` ·
`playwright.config.ts` · `Makefile` · `ci.yaml`. C'est ce qui rend applicable l'Art. 16 : une porte
rouge arrête le fil, et maquiller un échec se voit.

**Le nom `ci.yaml` vient de `9b` ; son emplacement et sa plateforme ne viennent de nulle part** —
aucune source du projet ne désigne de forge ni d'exécuteur. Ce contrat décrit donc les portes, leur
ordre et leur effet **sans plateforme** (ARBITRAGE 1).

---

## Contrat 8 — Épinglage : trois portées distinctes

| Portée | Règle | Exigence |
| --- | --- | --- |
| **Dépendances** | verrou reproductible | Art. 11 |
| Images **construites** | étiquetées version + digest, retour arrière par ré-étiquetage | **FR-019** |
| Briques **consommées** par la chaîne — actions, outils, images de base des étapes | tag exact ou digest ; jamais `:latest`, jamais une branche, jamais un intervalle ouvert | **FR-026**, SC-011 |

Un référencement flottant **fait échouer la chaîne**. Le contrôle tourne en **porte locale** et en
**étape**, pour que le refus survienne avant l'envoi. SC-011 exige **100 %** : la porte ne connaît pas
d'exception.

*Sans FR-026, on obtient une chaîne non reproductible qui garde des artefacts reproductibles.*

---

## Contrat 9 — Topologie de fusion

Déclarée par l'**Art. 23** ; ce contrat ne la redéclare pas (Art. 19) et dit seulement comment elle est
**gardée**.

| Engagement | Comment il est tenu |
| --- | --- |
| `NNN-slug` n'entre dans `dev` que par demande de fusion, aux portes de rang 1 à 3 vertes | garde locale versionnée + protections de branche de la forge |
| `dev` promeut vers `test`, `test` vers `master` ; aucune promotion ne saute un maillon | garde locale versionnée |
| **Aucun commit direct** sur `test` ni sur `master` | garde locale versionnée — refus si la branche courante est `test` ou `master` |
| Les portes 4 et 5 gardent la **promotion de `test`** | par nature (elles n'existent qu'à distance) |
| Dès qu'un dépôt distant existe, la fusion passe par la forge, **jamais** par une fusion locale | FR-030 |

**Deux couches, une seule règle.** La garde locale fonctionne **aujourd'hui**, sans dépôt distant, et
reste vraie dans le régime local que l'Art. 23 prévoit. Les protections de branche expriment la même
règle à distance et **ne peuvent pas être configurées avant ARBITRAGE 1** : ce contrat en fixe
l'exigence, pas la syntaxe.

**Condition de sortie du régime dégradé** : la livraison de S03. Ce contrat ne livre pas seulement de
l'outillage — il clôt un régime transitoire (FR-030, Art. 23).
