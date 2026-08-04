# Phase 1 — Modèle de données : S03 Socle qualité & CI

**S03 ne crée aucune table et aucune entité du domaine métier.** Ses objets appartiennent à l'**arbre
de la méthode** de la taxonomie : `Constitution → Spec → Plan → Jalon → Tâche`. Ils décrivent
**comment on construit**, pas ce que le produit manipule.

---

## Porte de qualité

Contrôle mécanique franchi ou non. Unité fondamentale de l'Art. 8.

| Attribut | Type | Règle |
| --- | --- | --- |
| `nom` | identifiant | unique dans la déclaration |
| `versant` | énuméré | plan de contrôle · interface · transverse |
| `rang` | entier | position dans l'ordre imposé (FR-013) |
| `bloquante` | booléen | **toujours vrai** — une porte rouge arrête le fil (FR-014) |
| `portée` | énuméré | locale · distante · **les deux** |

**Ordre normatif (FR-013)** : style et format → typage → tests et couverture → contrôles de
sécurité → construction des images → parcours de bout en bout.

**Invariant central (FR-002)** : l'ensemble des portes de portée « locale » et celui de portée
« distante » sont **déclarés une seule fois** et comparés par test (SC-005). Une divergence est un
échec, pas un avertissement.

---

## Seuil de couverture

Valeur plancher associée à un périmètre de code.

| Périmètre | Seuil | Nature |
| --- | --- | --- |
| **Cœur** — authentification, quotas, comptabilité | **≥ 90 %** | bloquant |
| Hors cœur | **≥ 70 %** | bloquant |

**Règles** :

- La valeur est **mesurée par l'outillage**, jamais annoncée — « un chiffre sans sortie capturée est
  une opinion » (Art. 10).
- Le seuil est **nécessaire mais non suffisant** : il ne prouve pas que les tests assertent. Le cycle
  rouge → vert reste dû (voir `research.md` D-S03-4).
- Les valeurs sont fixées par la **constitution**, pas négociables spec par spec.

---

## Moteur factice

Simulateur du contrat d'inférence. **Paquet distribuable**, consommé par S04 à S20.

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

**Cycle de vie** : versionné indépendamment. Une évolution du contrat d'inférence (S04) impose une
évolution du paquet, visible en revue.

Détail de la surface : [`contracts/fake-engine.md`](./contracts/fake-engine.md).

---

## Étape de chaîne

Maillon ordonné de la chaîne d'intégration.

| Attribut | Règle |
| --- | --- |
| `rang` | conforme à l'ordre normatif |
| `condition de réussite` | explicite et mécanique |
| `effet sur la fusion` | **bloque** en cas d'échec |
| `accès GPU` | **jamais** (Art. 8) |

**Étape particulière — bout en bout** : s'exécute sur un **environnement éphémère complet** associé
au moteur factice, **détruit** en fin d'exécution (FR-017, SC-007).

---

## Niveau de la pyramide de tests

Les neuf niveaux exigés par l'Art. 10, rendus **exécutables** par S03 (FR-021). S03 fournit le
moyen ; les tests eux-mêmes appartiennent aux specs métier.

| Niveau | Rendu exécutable par | Consommé surtout par |
| --- | --- | --- |
| Unitaires (fonctions pures) | outillage du plan de contrôle | S08 coût · S09 tenue mémoire · S16 classement |
| Intégration (bases éphémères) | bases éphémères | S04, S08, S13 |
| Contrat (clients réels) | outillage de contrat | **S04** |
| Bout en bout (parcours) | environnement éphémère + moteur factice | S09, S11, S12 |
| Charge | outillage de charge | **S05**, **S21** |
| Sécurité | analyse statique + audits | transverse |
| Fichiers de référence | comparaison figée | **S08** facturation · **S16** classement |
| Générés depuis une source | mécanisme de génération | **S13** permissions |
| Résilience | environnement éphémère | S10, S19, S20, S21 |

---

## Ce que S03 ne modélise pas

| Objet | Spec propriétaire |
| --- | --- |
| Contrat d'interface (contenu) | **S04** |
| Source des permissions et tests générés | **S13** |
| Scénarios de charge métier | **S21** |
| Toute entité du domaine, toute table | **S04** et suivantes |
