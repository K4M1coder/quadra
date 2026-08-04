# Phase 1 — Guide de validation : S01 Socle compose + moteurs + Caddy

Ce guide prouve que S01 est livrée. Il est la forme humaine de la tâche `[TEST]` **T10** ; la version
automatisée en dérive.

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

> Sans GPU, les scénarios 1, 3, 4 et 5 restent valides ; le scénario 2 signalera les services moteurs
> en échec, ce qui est le comportement attendu (cas limite documenté dans la spec).

---

## Scénario 1 — Fondations : les bases démarrent *(valide J1)*

1. Cloner le dépôt sur la machine vierge.
2. Lire le README racine.
3. Démarrer les services de données.

**Attendu**

- Le rôle de chaque répertoire de premier niveau est identifiable **sans poser de question**.
- Base relationnelle et cache atteignent l'état **sain**.
- Les données écrites persistent dans des **volumes nommés**.

**Prouve** : FR-001 à FR-004 · SC-007.

---

## Scénario 2 — Cœur : une commande démarre tout *(valide J2, critère A1)*

1. Copier l'exemplaire d'exemple du fichier d'environnement et le renseigner.
2. Lancer la commande de démarrage unique.
3. Chronométrer jusqu'à ce que toutes les sondes soient vertes.

**Attendu**

- Pile **entièrement saine en moins de 5 minutes**.
- Les 9 services attendus sont présents.
- Le point d'entrée TLS répond avec un **certificat valide**.

**Prouve** : critère **A1** · FR-005, FR-008, FR-009, FR-011 · SC-001.

---

## Scénario 3 — Exposition réseau *(valide le critère A2)*

1. Depuis une **autre machine**, balayer les ports de l'hôte.
2. Tenter de joindre directement un moteur d'inférence sur son port interne.
3. Tenter de joindre la base relationnelle et le cache.

**Attendu**

- **Seul le port TLS répond.**
- Les tentatives directes vers moteurs, base et cache **échouent**.

**Prouve** : critère **A2** · FR-006, FR-007 · SC-002.
Voir [`contracts/routes.md`](./contracts/routes.md), contrat 1.

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

1. Retirer une variable requise du fichier d'environnement, démarrer.
2. Remettre une valeur invalide, démarrer.
3. Restaurer une configuration correcte.
4. Exercer les cibles : arrêter, consulter les journaux, lister l'état.

**Attendu**

- Échec en **moins de 10 s**, message nommant **la variable fautive et la correction attendue**.
- **Aucun service** laissé démarré après un échec de validation.
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

## Récapitulatif critère → scénario

| Critère du document | Scénario | Tâche |
| --- | --- | --- |
| **A1** — pile saine < 5 min | 2 | T10 |
| **A2** — seul :443 exposé | 3 | T10 |
| **A3** — tout épinglé | 4 | T10 |
| Surface J3 (config, doc) | 5, 7 | T7, T9 |
| Résilience | 6 | T6 |
