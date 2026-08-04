# Phase 1 — Guide de validation : S02 Observabilité de base

Forme humaine de la tâche `[TEST]` **T8**, complétée par **T7** `[INT]`. La version automatisée en
dérive. Aucun code d'implémentation ici.

---

## Préconditions

| Élément | Attendu |
| --- | --- |
| S01 | livrée — les conteneurs d'observabilité démarrent |
| Matériel | 4 cartes GPU pour le scénario 2 ; les autres scénarios n'en exigent pas |
| Stockage de visualisation | **vide** pour le scénario 3 — c'est la condition du critère A2 |

---

## Scénario 1 — Toutes les cibles sont joignables *(critère A1)*

1. Démarrer la pile.
2. Consulter l'état des cibles de collecte.

**Attendu** — **100 %** des cibles déclarées à l'état joignable : plan de contrôle, moteurs,
exportateur matériel, la collecte elle-même.

**Prouve** : critère **A1** · FR-001, FR-002 · SC-001.

---

## Scénario 2 — Mesures matérielles par carte

1. Consulter les mesures de l'exportateur matériel.
2. Observer leur fréquence de rafraîchissement.

**Attendu** — température, puissance et mémoire vidéo disponibles **pour chacune des 4 cartes**,
rafraîchies au moins **une fois par seconde**.

**Prouve** : FR-003, FR-004 · SC-004.

> Sans GPU : la cible est signalée en échec **sans faire échouer les autres**. C'est le comportement
> attendu (cas limite de la spec), utile sur machine de développement.

---

## Scénario 3 — Tableaux de bord provisionnés *(critère A2)*

1. Repartir d'un **stockage de visualisation vide**.
2. Démarrer la pile.
3. Ouvrir l'outil de visualisation.

**Attendu** — source de données et **deux tableaux de bord** (matériel, moteurs) présents et
alimentés, **sans aucune action manuelle**.

**Prouve** : critère **A2** · FR-011, FR-013, FR-014 · SC-002.

---

## Scénario 4 — Le dépôt fait autorité *(le contrôle le plus important)*

1. Modifier un tableau de bord **à la main** dans l'interface de visualisation.
2. Redémarrer la pile.
3. Rouvrir le tableau de bord.

**Attendu** — la **définition versionnée du dépôt a été réappliquée** ; la modification manuelle **n'a
pas survécu**.

**Prouve** : FR-012 · SC-005 · Art. 19.

> C'est le scénario qui distingue un provisionnement conforme d'un simple import initial. Un import
> laisserait la modification en place et le test passerait « en apparence » — d'où l'étape 1, qui est
> indispensable.

---

## Scénario 5 — Conservation 90 jours *(critère A3)*

1. Interroger une mesure datée de **89 jours**.
2. Interroger une mesure datée de **91 jours**.

**Attendu** — la première est **lisible**, la seconde **ne l'est plus**.

**Prouve** : critère **A3** · FR-005 · SC-003.

---

## Scénario 6 — Persistance

1. Arrêter la pile, la redémarrer.
2. Interroger des mesures antérieures à l'arrêt.

**Attendu** — les mesures collectées avant l'arrêt sont **toujours présentes**.

**Prouve** : FR-006.

---

## Scénario 7 — Conformité des libellés *(Art. 1)*

1. Exécuter le contrôle automatisé de conformité des libellés.
2. Introduire volontairement une métrique portant un libellé à cardinalité libre.

**Attendu** — le contrôle ne trouve **aucune** donnée personnelle ni valeur à cardinalité libre sur
l'existant, et **rejette** la métrique introduite.

**Prouve** : FR-010 · SC-006. Voir [`contracts/metrics.md`](./contracts/metrics.md), contrat 2.

---

## Scénario 8 — Routage des alertes

1. Provoquer une alerte.
2. Observer son acheminement.
3. Rendre un destinataire injoignable, recommencer.

**Attendu** — l'alerte atteint ses destinataires selon sa gravité, avec un contenu issu d'un gabarit
versionné ; un échec d'acheminement est **observable** et **ne fait pas disparaître** l'alerte.

**Prouve** : FR-016, FR-017, FR-018 · SC-007.

---

## Scénario 9 — Source unique *(Art. 19)*

Inspecter les dépendances du projet.

**Attendu** — **aucun** second collecteur, **aucun** second magasin de séries temporelles. Tout
consommateur de métriques lit cette chaîne.

**Prouve** : FR-007 · contrat 6.

---

## Récapitulatif critère → scénario

| Critère du document | Scénario | Tâche |
| --- | --- | --- |
| **A1** — toutes les cibles joignables | 1, 2 | T8, T7 |
| **A2** — tableaux de bord auto-provisionnés | 3, 4 | T8 |
| **A3** — rétention 90 j | 5 | T8 |
| Persistance | 6 | T6 |
| Libellés sans PII | 7 | T1 + contrôle |
| Routage d'alertes | 8 | T5 |
| Source unique | 9 | transverse |
