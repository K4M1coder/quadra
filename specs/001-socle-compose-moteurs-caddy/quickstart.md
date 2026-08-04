# Phase 1 — Guide de validation : S01 Socle compose + moteurs + Caddy

Ce guide prouve que S01 est livrée. Il est la forme humaine de ses tâches `[TEST]` : la preuve machine
vierge de la fiche `9f` (réf. `9f` T10) et les **deux preuves que `9f` ne porte pas** — fichiers de
gouvernance à la racine, retour arrière — à créer dans `tasks.md` (écart documentaire, Art. 7). Les
versions automatisées en dérivent.

**Ne contient aucun code d'implémentation** — seulement les scénarios de validation, leurs
préconditions et les résultats attendus.

---

## Préconditions

| Élément | Attendu |
| --- | --- |
| Machine | **vierge** — aucune installation antérieure du produit |
| Système | distribution Linux de référence |
| Moteur de conteneurs | installé, version épinglée |
| Pilote GPU / CUDA / toolkit conteneur | **la combinaison validée** (voir décision D2) |
| Matériel | 4 cartes GPU de 24 Go, appairées par paires |
| Réseau | accès sortant au dépôt public de modèles |

> Sans GPU, les scénarios 1, 3, 4 et 5 restent valides, ainsi que le scénario 8 à condition de le jouer
> sur un composant qui n'utilise pas de GPU ; le scénario 2 signalera les services moteurs en échec, ce
> qui est le comportement attendu (cas limite documenté dans la spec).

---

## Scénario 1 — Fondations : les bases démarrent *(valide J1)*

1. Cloner le dépôt sur la machine vierge.
2. Lire le README racine.
3. Constater la présence de `CONSTITUTION.md` et `CHANGELOG.md` **à la racine**, et comparer la version
   déclarée par `CONSTITUTION.md` à celle de sa source `.specify/memory/constitution.md`.
4. Démarrer les services de données.

**Attendu**

- Le rôle de chaque répertoire de premier niveau (`gateway/`, `ui/`, `deploy/`, `docs/`) est
  identifiable **sans poser de question**.
- `CONSTITUTION.md` est présent et déclare **exactement la même version** que sa source ; la moindre
  divergence est un échec.
- `CHANGELOG.md` est présent, au format **Keep a Changelog**, et porte l'entrée du changement qui livre
  S01.
- Base relationnelle et cache atteignent l'état **sain**.
- Les données écrites persistent dans des **volumes nommés** (`pgdata`).

**Prouve** : FR-001 à FR-004, FR-019, FR-020 · SC-007, SC-008, SC-009.
La vérification des deux fichiers de racine **n'est portée par aucune tâche de la fiche `9f`** : sa
tâche `[TEST]` est à créer dans `tasks.md` (écart documentaire, Art. 7).

---

## Scénario 2 — Cœur : une commande démarre tout *(valide J2, critère A1)*

1. Copier `.env.example` en `.env` et renseigner les variables `QUADRA_` requises.
2. Lancer la commande de démarrage unique.
3. Chronométrer jusqu'à ce que toutes les sondes soient vertes.
4. Interroger les quatre routes publiées `/v1`, `/api`, `/ws` et `/grafana`.

**Attendu**

- Pile **entièrement saine en moins de 5 minutes**.
- Les 9 services attendus sont présents : `caddy`, `sglang`, `llama.cpp`, `postgres`, `redis`,
  `prometheus`, `alertmanager`, `grafana`, `dcgm-exporter`.
- Le point d'entrée TLS répond avec un **certificat valide**.
- Chacune des quatre routes atteint le service attendu ; une route non déclarée n'atteint **aucun**
  service interne. Une route acheminée peut répondre « non implémenté » — c'est le comportement
  attendu au jalon M0.

**Prouve** : critère **A1** · FR-005, FR-008, FR-009, FR-011 · SC-001.
Voir [`contracts/routes.md`](./contracts/routes.md), contrat 2.

---

## Scénario 3 — Exposition réseau *(valide le critère A2)*

1. Depuis une **autre machine**, balayer les ports de l'hôte.
2. Tenter de joindre directement un moteur d'inférence sur son port interne.
3. Tenter de joindre la base relationnelle et le cache.

**Attendu**

- **Parmi les ports des services de la pile, seul 443 répond** — celui de `caddy`.
- Les tentatives directes vers moteurs, base et cache **échouent** : ils ne sont joignables que depuis
  `quadra-net`.

**Prouve** : critère **A2** · FR-006, FR-007 · SC-002.
Voir [`contracts/routes.md`](./contracts/routes.md), contrat 1. Le statut de SSH, service de l'hôte,
est un arbitrage ouvert de `spec.md` et n'entre pas dans ce scénario.

---

## Scénario 4 — Épinglage *(valide le critère A3)*

1. Inspecter la définition de déploiement.
2. Contrôler automatiquement chaque référence d'image.
3. Rendre volontairement indisponible un digest et relancer.

**Attendu**

- **100 % des images** référencées par digest exact ; **aucune** référence mouvante.
- Digest indisponible → **échec explicite** nommant l'image, **aucune substitution**.

**Prouve** : critère **A3** · FR-012, FR-013 · SC-003.

---

## Scénario 5 — Configuration et exploitation *(valide J3)*

1. Retirer une variable `QUADRA_` requise du fichier d'environnement, démarrer.
2. Remettre une valeur invalide, démarrer.
3. Restaurer une configuration correcte.
4. Exercer les cibles : arrêter, consulter les journaux, lister l'état.

**Attendu**

- Le démarrage **s'interrompt**, avec un message nommant **la variable fautive et la correction
  attendue**. Aucun délai n'est mesuré : aucune source n'en fixe un.
- **Aucun service** laissé démarré après un échec de validation — la pile ne démarre jamais à moitié
  configurée.
- Chacune des quatre opérations d'exploitation dispose de sa cible.

**Prouve** : FR-014 à FR-016 · SC-006.

---

## Scénario 6 — Résilience *(valide FR-010)*

1. Redémarrer la machine.
2. Attendre le retour du système.
3. Vérifier l'état de la pile et l'intégrité des volumes.

**Attendu**

- La pile se **relance automatiquement**, sans intervention.
- Les données écrites avant le redémarrage sont **intactes**.

**Prouve** : FR-010 · SC-005, SC-007.

---

## Scénario 7 — Installation par un tiers *(valide SC-004)*

Faire réaliser les scénarios 2 et 5 par **une personne n'ayant jamais vu le projet**, avec pour seule
ressource `docs/install.md`.

**Attendu** : pile saine atteinte **sans qu'aucune question soit posée** au mainteneur.

**Prouve** : FR-017 · SC-004. C'est le critère le plus facile à croire acquis et le plus révélateur —
il valide l'Art. 9 (opérable par un seul).

---

## Scénario 8 — Retour arrière *(valide FR-021)*

1. Sur une pile saine, noter le digest en service d'un composant et le digest précédemment épinglé.
2. Dans le **fichier de digests, et lui seul**, re-pointer le digest précédent.
3. Redémarrer le service par **une seule commande**.
4. Vérifier, en fin de manœuvre, l'état de la pile et la liste des fichiers modifiés.

**Attendu**

- La pile retrouve l'état **sain**.
- **Une seule commande** a suffi ; **aucune image n'a été reconstruite**.
- **Aucun fichier autre que celui des digests** n'a été modifié.
- La version effectivement en service est **lisible depuis la définition de déploiement**.

**Prouve** : FR-021 · SC-010 (réf. `w10`). Voir [`contracts/routes.md`](./contracts/routes.md),
contrat 4. **Aucune tâche de la fiche `9f` ne porte cette preuve** : elle est à créer dans `tasks.md`
(écart documentaire, Art. 7).

---

## Récapitulatif critère → scénario

| Critère ou exigence | Scénario | Preuve |
| --- | --- | --- |
| **A1** — pile saine < 5 min, sondes vertes | 2 | réf. `9f` T10 |
| **A2** — seul 443 exposé, moteurs invisibles | 3 | réf. `9f` T10 |
| **A3** — tout épinglé | 4 | réf. `9f` T10 |
| Surface J3 (configuration, documentation) | 5, 7 | réf. `9f` T7, T9 |
| Résilience (SC-005, SC-007) | 6 | réf. `9f` T6 |
| Fichiers de gouvernance à la racine (SC-008, SC-009) | 1 | tâche `[TEST]` **à créer** — absente de `9f` |
| Retour arrière en une commande (SC-010) | 8 | tâche `[TEST]` **à créer** — absente de `9f` |
