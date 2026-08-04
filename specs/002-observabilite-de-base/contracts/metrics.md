# Phase 1 — Contrat : surface de métriques et provisionnement (S02)

S02 n'expose **aucune API applicative**. Ce qu'elle contracte, ce sont deux choses que **toutes les
autres specs devront respecter** : la forme des métriques qu'elles émettent, et le fait que le dépôt
fait autorité sur les tableaux de bord.

Ce contrat est **transverse** : il engage S04, S05, S06, S08, S15, S19 et S20, qui émettront des
métriques dans cette chaîne.

---

## Contrat 1 — Nommage des métriques

| Cas | Forme imposée |
| --- | --- |
| Métrique **propre au projet** | `quadra_<entité>_<mesure>_<unité>` |
| Métrique **empruntée à un moteur** | **inchangée**, telle qu'émise par l'amont |

- `<entité>` provient de la **taxonomie du domaine** — pas d'un nom inventé (Art. 12, Art. 17).
- `<unité>` est explicite (`_seconds`, `_total`, `_bytes`…).
- Renommer une métrique du projet est un **amendement du vocabulaire**, pas un refactoring.
- Renommer une métrique amont est **interdit** (Art. 6) : cela romprait la correspondance avec sa
  documentation d'origine et transformerait chaque montée de version en travail de reprise.

---

## Contrat 2 — Libellés : liste blanche et cardinalité bornée

**Libellés autorisés** : `lane` · `alias` · `node` · `host` · `key_id`.

| Interdiction | Raison |
| --- | --- |
| Donnée personnelle | Art. 1 — une série est conservée 90 jours : c'est une fuite durable |
| Contenu de prompt, même tronqué | Art. 1 |
| Identifiant de requête | cardinalité non bornée — fait exploser le stockage |
| Adresse, chemin, texte saisi | cardinalité non bornée |

**Application** : contrôle **mécanique** en intégration continue (Art. 8), pas en revue humaine. La
revue ne tient pas dans la durée, car le risque réapparaît à chaque nouvelle métrique émise par une
spec ultérieure.

**Engagement pour les specs consommatrices** : une métrique qui ne respecte pas cette liste blanche
**fait échouer la porte** et ne peut pas être fusionnée.

---

## Contrat 3 — Cadences de collecte

| Cible | Cadence |
| --- | --- |
| Exportateur matériel GPU | **1 s** |
| Plan de contrôle, moteurs, collecte elle-même | **5 s** |

**Garantie** : une cible injoignable est signalée avec sa raison et **n'interrompt pas** la collecte
des autres.

---

## Contrat 4 — Conservation

| Élément | Valeur |
| --- | --- |
| Rétention des séries | **90 jours** |
| Persistance | volume dédié, survit au redémarrage de la pile |
| Purge | automatique au-delà de la rétention |

**Vérifiable** : une mesure de 89 jours est lisible, une mesure de 91 jours ne l'est plus (SC-003).

**Périmètre** : cette rétention ne concerne **que** les séries temporelles. Les autres conservations
du projet appartiennent à leurs specs — lignes d'usage 24 mois (S08), contenus de prompts 30 j (S14),
journal d'audit 2 ans (S13), résultats de lots 7 j (S18).

---

## Contrat 5 — Le dépôt fait autorité sur les tableaux de bord

| Règle | Conséquence |
| --- | --- |
| Toute définition vit **dans le dépôt** | revuable comme du code |
| Provisionnement **réappliqué à chaque démarrage** | une modification manuelle **ne survit pas** |
| Nommage `ds-<domaine>.json` | convention 10b |

**Ce n'est pas un import initial.** La distinction est le cœur du contrat : un import laisserait le
dépôt et l'affichage diverger silencieusement. Vérifié par SC-005 — modifier, redémarrer, constater
le retour à la définition versionnée.

---

## Contrat 6 — Source unique de métriques

**Aucun composant du projet ne constitue une seconde chaîne de mesure** (Art. 19).

| Consommateur | Ce qu'il fait |
| --- | --- |
| Tableaux de bord (S02) | lisent cette chaîne |
| Hub d'observabilité (S15) | lit cette chaîne |
| Vue de santé agrégée (S21) | lit cette chaîne |
| Traces par requête (S14) | **réutilisent les mesures déjà émises**, sans réinstrumenter |

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
