# Phase 1 — Guide de validation : S02 Observabilité de base

Forme humaine de la tâche `[TEST]` **T8**, complétée par **T7** `[INT]`. La version automatisée en
dérive. Aucun code d'implémentation ici.

---

## Préconditions

| Élément | Attendu |
| --- | --- |
| S01 | livrée — Prometheus, Alertmanager, Grafana et `dcgm-exporter` démarrent sur `quadra-net` |
| Matériel | 4 cartes GPU pour le scénario 2 ; les autres scénarios n'en exigent pas |
| Stockage Grafana | **vide** pour le scénario 3 — c'est la condition du critère A2 |

Toutes les vérifications ci-dessous s'exécutent **en local** tant que S03 n'est pas livrée ; leur
sortie capturée fait foi (Art. 23).

---

## Scénario 1 — Toutes les cibles sont `up` *(critère A1)*

1. Démarrer la pile.
2. Consulter `/targets`.

**Attendu** — **100 %** des cibles déclarées à l'état `up` : `gateway`, `node-A`, `node-B`, `node-C`,
`dcgm-exporter`, `self`.

**Prouve** : critère **A1** · FR-001, FR-002 · SC-001.

---

## Scénario 2 — Mesures `dcgm-exporter` par carte

1. Consulter les mesures de `dcgm-exporter`.
2. Observer leur fréquence de rafraîchissement.

**Attendu** — température, puissance et mémoire vidéo disponibles **pour chacune des 4 cartes**,
rafraîchies au moins **une fois par seconde**.

**Prouve** : FR-003, FR-004 · SC-004.

> Sans GPU : la cible est `down` **sans faire échouer les autres**. C'est le comportement attendu
> (cas limite de la spec), utile sur machine de développement.

---

## Scénario 3 — `Dashboards` provisionnés *(critère A2)*

1. Repartir d'un **stockage Grafana vide**.
2. Démarrer la pile.
3. Ouvrir Grafana.

**Attendu** — datasource Prometheus et **deux `Dashboards`** (`ds-gpu.json`, `ds-engines.json`)
présents et alimentés, **sans aucune action manuelle**.

**Prouve** : critère **A2** · FR-011, FR-013, FR-014 · SC-002.

---

## Scénario 4 — Le dépôt fait autorité *(le contrôle le plus important)*

1. Modifier un `Dashboard` **à la main** dans Grafana.
2. Redémarrer la pile.
3. Rouvrir le `Dashboard`.

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

## Scénario 6 — Persistance de `promdata`

1. Arrêter la pile, la redémarrer.
2. Interroger des mesures antérieures à l'arrêt.

**Attendu** — les mesures collectées avant l'arrêt sont **toujours présentes** (volume `promdata`).

**Prouve** : FR-006.

---

## Scénario 7 — Routage des alertes

1. Provoquer une alerte, la porter en `firing`.
2. Observer son acheminement par Alertmanager.
3. Rendre un destinataire injoignable, recommencer.

**Attendu** — l'alerte atteint ses destinataires selon sa gravité, avec un contenu issu d'un gabarit
versionné ; un échec d'acheminement est **observable** et **ne fait pas disparaître** l'alerte.

**Prouve** : FR-016, FR-017, FR-018 · SC-007.

---

## Scénario 8 — Source unique *(Art. 19)*

Inspecter les dépendances du projet.

**Attendu** — **aucun** second collecteur, **aucun** second magasin de séries temporelles. Tout
consommateur de métriques lit ce Prometheus.

**Prouve** : FR-007 · contrat 6.

---

## Récapitulatif critère → scénario

| Critère du document | Scénario | Tâche |
| --- | --- | --- |
| **A1** — toutes les cibles `up` | 1, 2 | T8 `[TEST]`, T7 `[INT]` |
| **A2** — `Dashboards` auto-provisionnés | 3, 4 | T8 `[TEST]` |
| **A3** — rétention 90 j | 5 | T8 `[TEST]` |
| Persistance de `promdata` | 6 | `[TEST]` de ce scénario, charge absorbée par T6 ; T6 en est l'objet, pas la preuve |
| Routage d'alertes | 7 | `[TEST]` de ce scénario, charge absorbée par T8 ; T5 en est l'objet, pas la preuve |
| Source unique | 8 | transverse |

**Pas de scénario pour « labels = ids, jamais de PII ».** `9g` en fait une **consigne** et n'y attache
aucune preuve (« Critères → preuves : A1–A3 → T8 ») ; à M0 aucun composant n'émet `lane`, `alias`,
`node`, `host` ou `key_id`. La règle est portée par FR-010 et tenue par la convention `10b` et la
revue ; la porte mécanique appartient à S03 ou S04 — voir les *Arbitrages ouverts* du plan.
