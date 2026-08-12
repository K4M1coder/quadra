# Phase 1 — Modèle de données : S03 Socle qualité & CI

**S03 ne crée aucune table et aucune entité nouvelle.** Elle introduit **un seul objet** rattaché à la
taxonomie de `10a` — le **moteur factice**, qui expose le contrat d'un `engine` de l'arbre d'exécution
sans en être une `instance`.

**Ce qui n'est pas modélisé, et pourquoi** : les **portes**, leurs **seuils** et les **étapes** de la
chaîne ne sont pas des entités du domaine. L'arbre de la méthode de `10a` s'arrête à `Tâche Tn`
(`Constitution → Spec S01–S21 → Plan → Jalon interne J1–J4 → Tâche Tn`), et l'Art. 17 interdit de
faire naître dans le code un concept absent de la taxonomie. Ils restent des **propriétés de la
chaîne**, décrites par les exigences de [`spec.md`](./spec.md) et par
[`contracts/quality-gates.md`](./contracts/quality-gates.md) — jamais par une table, jamais par une
classe d'entité. Les modéliser exigerait un **amendement préalable** de `10a` (ARBITRAGE 5).

---

## Moteur factice

Simulateur du contrat d'inférence. **Paquet distribuable**, consommé par S04 à S20.

**Rattachement à `10a`** : il expose le contrat d'un `engine` de l'arbre d'exécution
(`Cluster → Host → Node → Engine → Instance`) **sans être une `instance`** — il ne sert aucun `alias`
en production et ne réside sur aucun `node`. Aucun état de `10d` ne lui est attribué : il n'est ni
`loading`, ni `ready`, ni `evicted` ; ces états appartiennent aux `instance` réelles.

| Attribut | Type | Règle |
| --- | --- | --- |
| `capacités exposées` | ensemble | complétion conversationnelle · **flux** · représentations vectorielles (FR-008, FR-011) |
| `latence du premier jeton` | durée **paramétrable** | rend les tests déterministes (FR-009) |
| `latence inter-jetons` | durée **paramétrable** | idem |
| `erreur injectée` | erreur choisie ou aucune | vérifie le comportement du plan de contrôle en cas de défaillance (FR-010) |
| `exécution` | mode | en processus **ou** conteneurisé |

**Contraintes** :

- **Une seule implémentation dans tout le projet** (FR-012, Art. 19).
- **Aucun GPU requis** (FR-007).
- Le format des réponses est **celui des moteurs réels** — une divergence invalide silencieusement
  toute la pyramide de tests (cas limite de la spec).
- Les paramètres sont réglables **par test**, pas globalement : deux tests d'un même fichier doivent
  pouvoir simuler des conditions différentes.

**Cycle de vie** : versionné indépendamment. Une évolution du contrat d'inférence (S04) impose une
évolution du paquet, visible en revue.

Détail de la surface : [`contracts/fake-engine.md`](./contracts/fake-engine.md).

---

## Annexe — Rattachement des niveaux de la pyramide de tests

**Ce n'est pas une entité** : c'est une table de rattachement, donnée pour situer ce que S03 pose et
ce qu'elle ne pose pas. La liste des neuf niveaux est celle de l'Art. 10 ; la profondeur est celle de
FR-021, bornée par le jalon courant (Art. 20).

| Niveau (Art. 10) | Posé par | Jalon |
| --- | --- | --- |
| Unitaires (fonctions pures) | **S03** — outillage du plan de contrôle | M0 |
| Intégration (bases éphémères) | **S03** — bases éphémères aux majeures de production | M0 |
| Bout en bout (parcours) | **S03** — environnement éphémère + moteur factice | M0 |
| **Charge** | **S03** — étape exécutable et porte bloquante (FR-027) ; scénarios par S21 | M0 (porte) · M4 (scénarios) |
| Sécurité | **S03** — analyse statique + audits de dépendances | M0 |
| Contrat (clients standards réels contre la surface publique) | **S04** | M1 |
| Fichiers de référence (facturation au centime) | **S08** | M2 |
| Générés depuis une source unique (matrice de permissions) | **S13** | M2 |
| Résilience (coupure / reprise, kill `worker`, restauration de sauvegarde) | **S19**, **S20**, **S21** | M4 |

S03 ne préempte ni l'outillage ni les jeux d'essai des quatre derniers niveaux (Art. 20).

---

## Ce que S03 ne modélise pas

| Objet | Spec propriétaire |
| --- | --- |
| Portes, seuils et étapes comme entités | **aucune** — hors taxonomie `10a`, amendement requis (ARBITRAGE 5) |
| Contrat d'interface (contenu) | **S04** |
| Client d'interface généré | **S11** |
| Source des permissions et tests générés | **S13** |
| Scénarios de charge | **S21** |
| Toute entité du domaine, toute table | **S04** et suivantes |
