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
| `nom` | identifiant | dérivé de la taxonomie, snake_case, unique dans la composition |
| `image` | référence | **digest exact obligatoire** ; toute référence mouvante est rejetée (Art. 11) |
| `réseau` | référence | réseau interne unique ; **aucun port publié** sauf le reverse proxy |
| `sonde de santé` | définition | obligatoire pour **tout** service (FR-009) |
| `dépendances` | liste | services dont l'état sain conditionne le démarrage |
| `politique de redémarrage` | énuméré | assure la reprise après défaillance et après redémarrage machine (FR-010) |
| `volumes montés` | liste | volumes nommés uniquement |

**Instances attendues** (9) : reverse proxy · moteur principal · moteur format fichier unique · base
relationnelle · cache · collecte de métriques · routage d'alertes · visualisation · exportateur de
métriques GPU.

**États observables** : `démarrage` → `sain` · `en échec` (sonde rouge) · `redémarrage`.
Ce ne sont pas des états du domaine : ce sont ceux du moteur de conteneurs.

---

## Volume nommé

Espace de stockage persistant, distinct par usage.

| Volume | Usage | Note |
| --- | --- | --- |
| `models` | poids des modèles téléchargés | ~1,8 To ; **exclu des sauvegardes** (S21) car re-téléchargeable |
| `offload` | débordement mémoire | ~400 Go ; **créé mais monté par aucun service** — attend S18 (Art. 3, Art. 20) |
| `pgdata` | données relationnelles | sauvegardé (S21) |
| `promdata` | séries temporelles de métriques | rétention 90 j, configurée par S02 |

**Règle** : volumes **nommés** exclusivement — la persistance doit survivre à la recréation des
conteneurs (SC-007). Aucun montage anonyme.

---

## Route publiée

Correspondance entre un chemin exposé sur le point d'entrée TLS et le service interne qui le sert.

| Route | Destination | Introduite par |
| --- | --- | --- |
| inférence | plan de contrôle | contrat figé par **S04** |
| administration | plan de contrôle | **S04** et suivantes |
| temps réel | plan de contrôle | **S05**, **S11** |
| tableaux de bord | visualisation | **S02** |

**S01 déclare les routes ; il n'en définit pas le contrat.** Le contrat d'interface est figé par S04
(tâche T9, par un humain). C'est la frontière qui évite que S01 anticipe une surface qu'il ne
spécifie pas.

---

## Variable d'environnement

Paramètre de configuration nommé, documenté, validé au démarrage.

| Attribut | Règle |
| --- | --- |
| `nom` | UPPER_SNAKE, préfixé du nom du projet (convention 10b) |
| `requise` | booléen — si requise et absente, le démarrage échoue |
| `valeur par défaut` | présente dans l'exemplaire d'exemple quand elle existe |
| `description` | obligatoire dans l'exemplaire d'exemple |
| `secret` | si vrai, l'exemplaire ne contient qu'une **valeur factice explicitement marquée** (Art. 21) |

**Validation** : échec en moins de 10 s, message nommant la variable fautive **et** la correction
attendue ; aucun service laissé démarré (FR-015, SC-006).

---

## Référence d'image épinglée

Objet transverse, source unique des versions (Art. 19).

| Attribut | Règle |
| --- | --- |
| `composant` | nom du service |
| `digest` | empreinte exacte — **seul champ faisant foi** |
| `version lisible` | commentaire humain, **jamais** utilisé pour résoudre l'image |
| `licence` | consignée (5a) pour la conformité |

**Contrainte** : un contrôle automatisé (T10) rejette toute référence dépourvue de digest.
**Retour arrière** : changer le digest et redémarrer — c'est le « rollback en une commande » de
l'Art. 9, rendu possible par l'Art. 11.
