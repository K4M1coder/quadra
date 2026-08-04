# Phase 1 — Contrat : surface de métriques et provisionnement (S02)

S02 n'expose **aucune API applicative** et n'écrit **aucun code applicatif**. Ce qu'elle contracte,
ce sont deux choses que **toutes les autres specs devront respecter** : la forme des métriques
qu'elles émettent, et le fait que le dépôt fait autorité sur les `Dashboards`.

Ce contrat est **transverse** : il engage S04, S05, S06, S08, S15, S19 et S20, qui émettront des
métriques dans cette chaîne.

---

## Contrat 1 — Nommage des métriques

| Cas | Forme imposée |
| --- | --- |
| Métrique **propre au projet** | `quadra_<entité>_<mesure>_<unité>` |
| Métrique **empruntée à un moteur** | **inchangée**, telle qu'émise par l'amont |

- `<entité>` provient de la **taxonomie du domaine** `10a` — pas d'un nom inventé (Art. 12, Art. 17).
- `<unité>` est explicite (`_seconds`, `_total`, `_bytes`…).
- Renommer une métrique du projet est un **amendement du vocabulaire**, pas un refactoring.
- Renommer une métrique amont est **interdit** (Art. 6) : cela romprait la correspondance avec sa
  documentation d'origine et transformerait chaque montée de version en travail de reprise.

---

## Contrat 2 — Libellés : liste blanche et cardinalité bornée

**Libellés autorisés** : `lane` · `alias` · `node` · `host` · `key_id` (`10b`).

| Interdiction | Raison |
| --- | --- |
| Donnée personnelle | Art. 1 — une série est conservée 90 jours : c'est une fuite durable |
| Contenu de prompt, même tronqué | Art. 1 |
| Identifiant de requête | cardinalité non bornée — fait exploser `promdata` |
| Adresse, chemin, texte saisi | cardinalité non bornée |

**Statut du contrat** : c'est une **règle normative**, contraignante pour toute spec consommatrice.
`9g` en fait une **consigne** (« labels = ids, jamais de PII ») et n'y attache aucune preuve, `5c`
la redit (« Jamais de PII dans les métriques Prometheus »).

**Comment elle est tenue, jalon par jalon** :

| Jalon | Sujets émettant ces libellés | Régime |
| --- | --- | --- |
| **M0** (S02) | **aucun** | convention `10b` + revue (Art. 16) — S02 n'écrit aucun module de contrôle (Art. 20) |
| **M1–M2** (S04, S05, S08) | `lane`, `alias`, `key_id`, `budget` | **porte mécanique** à rattacher à S03 ou S04 — à trancher, voir les *Arbitrages ouverts* du plan |

**Engagement pour les specs consommatrices** : une métrique qui ne respecte pas cette liste blanche
est **non conforme** et doit être refusée en revue dès aujourd'hui ; dès que la porte mécanique
existe, elle la fait échouer.

---

## Contrat 3 — Jobs et intervalles de scrape *(`5b`, FR-001, FR-003)*

| Job | `scrape_interval` |
| --- | --- |
| `dcgm-exporter` | **1 s** |
| `gateway`, `node-A` (sglang GPU 0+1), `node-B` (sglang GPU 2), `node-C` (llama.cpp GPU 3), `self` | **5 s** |

Les cibles sont **internes à `quadra-net`** — jamais un port publié sur l'hôte (`5b` : « aucun port
moteur exposé »).

**Garantie** : une cible `down` est signalée dans `/targets` avec sa raison et **n'interrompt pas** le
scrape des autres.

---

## Contrat 4 — Conservation

| Élément | Valeur |
| --- | --- |
| Rétention des séries | **90 jours** (`5b`, `5c`) |
| Persistance | volume `promdata`, survit au redémarrage de la pile |
| Purge | automatique au-delà de la rétention |

**Vérifiable** : une mesure de 89 jours est lisible, une mesure de 91 jours ne l'est plus (SC-003).

**Périmètre** : cette rétention ne concerne **que** les séries temporelles. Les autres conservations
du projet appartiennent à leurs specs — lignes d'usage 24 mois (S08), contenus de prompts 30 j (S14),
journal d'audit 2 ans (S13), résultats de lots 7 j (S18).

---

## Contrat 5 — Le dépôt fait autorité sur les `Dashboards`

| Règle | Conséquence |
| --- | --- |
| Toute définition vit **dans le dépôt**, sous `deploy/grafana/` | revuable comme du code (`9g`) |
| Provisionnement **réappliqué à chaque démarrage** | une modification manuelle dans Grafana **ne survit pas** |
| Nommage `ds-<domaine>.json` | `10b` |

**Ce n'est pas un import initial.** La distinction est le cœur du contrat : un import laisserait le
dépôt et l'affichage diverger silencieusement. Vérifié par SC-005 — modifier, redémarrer, constater
le retour à la définition versionnée.

---

## Contrat 6 — Source unique de métriques

**Aucun composant du projet ne constitue une seconde chaîne de mesure** (Art. 19).

| Consommateur | Ce qu'il fait |
| --- | --- |
| `Dashboards` Grafana (S02) | lisent ce Prometheus |
| Hub d'observabilité (S15) | lit ce Prometheus |
| Vue de santé agrégée (S21) | lit ce Prometheus |
| `Trace` par requête (S14) | **réutilise les mesures déjà émises**, sans réinstrumenter |

**Vérifiable** : inspection des dépendances — aucun second collecteur, aucun second magasin de
séries temporelles.

---

## Contrat 7 — Flux sortants

| Flux | Autorisé |
| --- | --- |
| Notification d'alerte vers destinataire interne | ✅ |
| Télémétrie, statistiques d'usage, rapport d'erreur vers un tiers | ❌ **jamais** (Art. 1) |

**Garantie sur l'échec** : un échec d'acheminement de notification est lui-même **observable** et ne
fait **pas** disparaître l'alerte sous-jacente.
