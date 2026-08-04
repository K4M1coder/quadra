# Phase 1 — Modèle de données : S02 Observabilité de base

**S02 ne crée aucune table et aucune entité du domaine métier.** Ses objets sont **déclaratifs** et
vivent dans le dépôt. Ils se rattachent à l'**arbre de l'observation** de la taxonomie :
`Metric → Dashboard · Alert rule → Action · Audit entry`.

---

## Cible de collecte

Composant interrogé périodiquement.

| Attribut | Type | Règle |
| --- | --- | --- |
| `nom du travail` | identifiant | snake_case, dérivé de la taxonomie |
| `cible` | adresse interne | **jamais** un port publié sur l'hôte |
| `cadence` | durée | **1 s** pour le matériel GPU, **5 s** pour les autres (FR-003) |
| `dernier état` | énuméré | `joignable` · `en échec` |
| `raison d'échec` | texte | obligatoire si en échec (FR-002) |

**Instances attendues (4 familles)** : plan de contrôle · moteurs d'inférence · exportateur matériel
GPU · la collecte elle-même.

**Règle** : une cible injoignable n'interrompt **pas** la collecte des autres (cas limite de la spec).

---

## Métrique

Mesure nommée, porteuse de libellés.

| Attribut | Règle |
| --- | --- |
| `nom` | `quadra_<entité>_<mesure>_<unité>` pour les métriques **propres au projet** (FR-008) |
| `nom (amont)` | **inchangé** pour les métriques empruntées aux moteurs (FR-009, Art. 6) |
| `libellés` | **liste blanche** : `lane`, `alias`, `node`, `host`, `key_id` |
| `type` | compteur · jauge · histogramme |

**Contrainte dure (FR-010)** : aucun libellé ne porte de donnée personnelle, de contenu de prompt ni
de valeur à cardinalité libre. Vérifié mécaniquement (SC-006).

**Familles peuplées à M0** : matériel par carte (température, puissance, mémoire vidéo) · métriques
natives des moteurs · santé du plan de contrôle.
**Familles déclarées ailleurs, collectées sans changement de configuration** : requêtes, jetons,
lanes, files (S04, S05) · budgets (S08) · disponibilité d'hôte, débit par exemplaire (S19, S20).

---

## Tableau de bord

Définition versionnée dans le dépôt, provisionnée automatiquement.

| Attribut | Règle |
| --- | --- |
| `fichier` | `ds-<domaine>.json` (convention 10b) |
| `source de données` | la source unique, provisionnée elle aussi |
| `autorité` | **le dépôt** — réappliqué à chaque démarrage (FR-011, FR-012) |

**Instances livrées par S02 (2)** :

- **matériel** — par carte GPU : température, puissance, mémoire vidéo (FR-013) ;
- **moteurs** — latence du premier jeton, latence inter-jetons, profondeur des files (FR-014).

**Cycle** : `définition dans le dépôt` → `provisionnée au démarrage` → `réappliquée à chaque
démarrage`. Une modification manuelle **ne survit pas** — c'est la propriété recherchée, pas un
effet de bord.

---

## Route de notification

Correspondance entre la gravité d'une alerte et ses destinataires.

| Attribut | Règle |
| --- | --- |
| `gravité` | critère de sélection de la route |
| `destinataires` | point de terminaison sortant · courriel (FR-016) |
| `gabarit` | versionné dans le dépôt (FR-017) |
| `échec d'acheminement` | **observable**, et ne fait pas disparaître l'alerte (FR-018) |

**Portée** : S02 fournit **le transport**. Les **règles** qui déclenchent les alertes sont créées par
S15 ; les seuils de budget qui en émettent viennent de S08. S02 ne définit aucune règle métier.

---

## Ce que S02 ne modélise pas

| Objet | Spec propriétaire |
| --- | --- |
| Règle d'alerte, action automatique, carte de charge | **S15** |
| Trace par requête, contenu des prompts | **S14** |
| Journal d'audit des actions | **S13** |
| Santé agrégée, diagnostics, sauvegardes | **S21** |
| Toute table relationnelle | **S04** et suivantes |
