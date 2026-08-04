# Phase 1 — Modèle de données : S02 Observabilité de base

**S02 ne crée aucune table et aucune entité du domaine métier.** Ses objets sont **déclaratifs** et
vivent dans le dépôt. Ils se rattachent à l'**arbre de l'observation** de la taxonomie (`10a`) :
`Metric → Dashboard · Alert rule → Action (réversible) → Event /ws · Audit entry`. Aucune entité
n'est créée hors de cet arbre : un manque s'y ajoute par amendement (Art. 17), il ne naît pas
ici.

---

## Job de scrape

Composant scrapé périodiquement par Prometheus, déclaré dans `prometheus.yml`.

| Attribut | Type | Règle |
| --- | --- | --- |
| `job` | identifiant | snake_case, dérivé de la taxonomie (`10b`) |
| `target` | adresse interne à `quadra-net` | **jamais** un port publié sur l'hôte (`5b`) |
| `scrape_interval` | durée | **1 s** pour `dcgm-exporter`, **5 s** pour les autres (FR-003) |
| dernier état | énuméré | `up` · `down`, lisible dans `/targets` |
| raison d'échec | texte | obligatoire si `down` (FR-002) |

**Instances attendues (6 jobs, `5b` · FR-001)** : `gateway` · `node-A` (sglang GPU 0+1) · `node-B`
(sglang GPU 2) · `node-C` (llama.cpp GPU 3) · `dcgm-exporter` · `self`.

**Règle** : une cible `down` n'interrompt **pas** le scrape des autres (cas limite de la spec).

---

## `Metric`

Mesure nommée, porteuse de libellés. Entité de `10a`.

| Attribut | Règle |
| --- | --- |
| nom | `quadra_<entité>_<mesure>_<unité>` pour les métriques **propres au projet** (FR-008) |
| nom (amont) | **inchangé** pour les métriques empruntées aux moteurs (FR-009, Art. 6) |
| libellés | **liste blanche** : `lane`, `alias`, `node`, `host`, `key_id` (`10b`) |
| type | compteur · jauge · histogramme |

**Contrainte dure (FR-010)** : aucun libellé ne porte de donnée personnelle, de contenu de prompt ni
de valeur à cardinalité libre. À M0 cette contrainte est **une règle de nommage**, tenue par la
convention `10b` et par la revue (Art. 16) : aucun composant n'émet encore ces libellés, et `9g`
n'attache aucune preuve à ses consignes. La porte mécanique qui la vérifiera est rattachée à S03 ou à
S04 — voir les *Arbitrages ouverts* du plan.

**Familles peuplées à M0** : `dcgm-exporter` par carte (température, puissance, mémoire vidéo) ·
métriques natives des moteurs · santé du `gateway`.
**Familles déclarées ailleurs, scrapées sans changement de `prometheus.yml`** : requêtes, jetons,
`lane`, files (S04, S05) · budgets (S08) · `quadra_host_up`, débit par `instance` (S19, S20).

---

## `Dashboard`

Définition versionnée dans le dépôt, provisionnée automatiquement dans Grafana. Entité de `10a`.

| Attribut | Règle |
| --- | --- |
| fichier | `ds-<domaine>.json` sous `deploy/grafana/` (`10b`, `9g`) |
| datasource | Prometheus, la source unique, provisionnée elle aussi |
| autorité | **le dépôt** — réappliqué à chaque démarrage (FR-011, FR-012) |

**Instances livrées par S02 (2)** :

- **`ds-gpu.json`** — par carte GPU : température, puissance, mémoire vidéo (FR-013) ;
- **`ds-engines.json`** — TTFT, ITL, profondeur des files (FR-014).

**Cycle** : `définition dans le dépôt` → `provisionnée au démarrage` → `réappliquée à chaque
démarrage`. Une modification manuelle **ne survit pas** — c'est la propriété recherchée, pas un
effet de bord.

---

## Route de notification *(rattachée à `Alert rule`)*

Correspondance, dans `alertmanager.yml`, entre la gravité d'une alerte passée en `firing` et ses
destinataires. `10a` ne porte pas d'entité propre pour cette route : elle est rattachée à
`Alert rule`, et l'amendement éventuel est consigné dans les *Arbitrages ouverts* du plan (Art. 17).

| Attribut | Règle |
| --- | --- |
| gravité | critère de sélection de la route |
| destinataires | point de terminaison sortant · courriel (FR-016, `9g` : « route webhook + email ») |
| gabarit | versionné dans le dépôt (FR-017) |
| échec d'acheminement | **observable**, et ne fait pas disparaître l'alerte (FR-018) |

**Portée** : S02 fournit **le transport**. Les **règles** qui passent en `firing` sont créées par
S15 ; les seuils de `budget` qui en émettent viennent de S08. S02 ne définit aucune règle métier.

---

## Ce que S02 ne modélise pas

| Objet | Spec propriétaire |
| --- | --- |
| `Alert rule` elle-même, `Action` réversible, heatmap de charge | **S15** |
| `Trace` par requête, contenu des `prompts` | **S14** |
| `Audit entry` (hash chaîné, append-only) | **S13** |
| Santé agrégée, diagnostics, sauvegardes | **S21** |
| Toute table relationnelle | **S04** et suivantes |
| Porte mécanique de conformité des libellés | **S03** ou **S04** — à trancher (plan, *Arbitrages ouverts*) |
