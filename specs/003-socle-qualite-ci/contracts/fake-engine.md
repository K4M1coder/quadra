# Phase 1 — Contrat : moteur d'inférence factice (S03)

**Consommateurs** : S04 à S20. C'est le contrat le plus transverse du projet après celui des
métriques — presque toute la pyramide de tests en dépend.

**Nature** : paquet **distribuable et versionné**, installable comme dépendance de test. Ce n'est
**pas** un fichier de test à copier (FR-012, Art. 19).

**Rattachement à la taxonomie (`10a`, Art. 17)** : il expose le contrat d'un `engine` de l'arbre
d'exécution (`Cluster → Host → Node → Engine → Instance`) **sans être une `instance`** — il ne sert
aucun `alias` en production et ne réside sur aucun `node`. Aucun état de `10d` ne lui est attribué.

---

## Contrat 1 — Surface d'inférence simulée

Le moteur factice expose **le même contrat que les moteurs réels**, afin que le plan de contrôle ne
sache pas qu'il parle à un simulateur.

| Capacité | Exigence |
| --- | --- |
| Complétion conversationnelle | réponse conforme au contrat d'inférence standard |
| **Flux** | réponse **jeton par jeton**, même format qu'un moteur réel (FR-008) |
| Représentations vectorielles | format attendu (FR-011) |

**Invariant** : toute divergence de format avec un moteur réel est un **défaut du moteur factice**,
pas une particularité acceptable. Une divergence invalide silencieusement la pyramide entière.

**Contrainte** : fonctionne **sans GPU** (FR-007).

---

## Contrat 2 — Paramètres de simulation

C'est ce qui distingue un simulateur utile d'un bouchon : les tests **choisissent** le comportement
plutôt que de le subir.

| Paramètre | Effet | Pourquoi |
| --- | --- | --- |
| **Latence du premier jeton** | délai avant le premier jeton | rend déterministes les tests de S04 (proxy de flux) et S05 (anti-famine) |
| **Latence inter-jetons** | cadence de production | permet de simuler un modèle lent sans en avoir un |
| **Erreur injectée** | produit une défaillance choisie | vérifie le comportement du plan de contrôle en cas de panne moteur (S04, S07) |

**Règle** : ces paramètres sont **réglables par test**, pas globalement. Deux tests du même fichier
doivent pouvoir simuler des conditions différentes.

**Conséquence** : aucune instabilité de test liée au temps n'est acceptable dans le projet — la
latence étant choisie, un test instable est un défaut, pas une fatalité (cas limite de la spec).

---

## Contrat 3 — Modes d'exécution

| Mode | Usage | Consommateur type |
| --- | --- | --- |
| **En processus** | tests unitaires et d'intégration rapides | plan de contrôle |
| **Conteneurisé** | environnement éphémère du dernier maillon | étape **bout en bout et charge**, S11, S12 |

Les deux modes exposent **la même surface** et **les mêmes paramètres**.

**Un seul environnement, un seul moteur factice pour le dernier maillon** : le volet de **charge**
s'exécute sur le **même** environnement éphémère et contre la **même** instanciation du moteur factice
que le volet de bout en bout (FR-017, FR-027 ; Art. 8 porte 4 « e2e + charge sur compose éphémère »).
Les scénarios de charge vivent dans `k6/<lane>-<scénario>.js` (`10b`) et sont versionnés par **S21**,
qui les rejoue sans créer un second jeu (Art. 19) — le moteur factice ne change pas pour autant.

---

## Contrat 4 — Unicité

| Règle | Conséquence |
| --- | --- |
| **Une seule implémentation** dans le dépôt | aucune spec n'écrit son propre simulateur |
| Paquet **versionné** | une évolution est visible et revuable |
| Évolution du contrat d'inférence (S04) | impose une évolution **du paquet**, pas des copies |

**Vérifiable** : une recherche dans le dépôt ne doit trouver **aucun** second simulateur de contrat
d'inférence.

---

## Contrat 5 — Ce que le moteur factice ne simule **pas**

Borne explicite, pour éviter qu'il devienne un second produit (Art. 20).

| Hors périmètre | Où c'est traité |
| --- | --- |
| Consommation mémoire réaliste, `fit` VRAM | canari — S06, S09 |
| Topologie matérielle, appairage de cartes (`NVLink`) | canari — S06 |
| Débit réel, comportement sous lot continu | canari — S20 |
| Qualité des réponses générées | sans objet — le contenu simulé n'a pas de sens sémantique |

**Ce que la porte de charge mesure — et ne mesure pas** : l'étape de charge (FR-027) exerce le **plan
de contrôle** contre le moteur factice — files, `lane`, refus, annulation. Elle ne mesure **aucun
débit réel de moteur** : cela exige du matériel et relève du canari. Un scénario de charge qui
prétendrait mesurer un débit produirait un chiffre faux.

**Règle** : ce qui ne peut pas être simulé fidèlement **ne doit pas l'être approximativement**. Un
simulateur qui prétendrait estimer la mémoire produirait des tests verts et une production fausse.
