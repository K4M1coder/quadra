# Phase 0 — Recherche : S03 Socle qualité & CI

Veille transverse : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md). Elle n'est pas dupliquée ici
(Art. 19), et **aucune de ses décisions D1–D6 ne couvre S03 en propre** — seule la conséquence
indirecte de D1 la touche (voir D-S03-5). Ce document ne traite que les décisions **propres à S03**.

---

## D-S03-1 — Définition unique des portes, sans mécanisme de comparaison

**Décision** : les portes de qualité sont déclarées **une seule fois** — les cibles du `Makefile`
(`9b` : `make lint / test / e2e / build / up`) — et la configuration locale comme la définition de
chaîne les **invoquent** au lieu de redéclarer des contrôles. **Aucun test de parité n'est écrit.**

**Rationale** : l'Art. 14 exige qu'« un commit vert en local prédise une CI verte ». Deux
configurations écrites séparément satisfont cette exigence le premier jour et la violent au premier
ajout de porte. Mais la réponse n'est pas de comparer deux listes : c'est de n'en avoir qu'une.
SC-005 le dit explicitement — l'équivalence est obtenue par **définition unique** versionnée et
invoquée de part et d'autre, et « aucun test de parité entre les deux n'est exigé : la constitution
demande l'équivalence, pas un mécanisme de comparaison ». Une comparaison automatisée serait par
ailleurs une seconde source de vérité sur ce que sont les portes (Art. 19).

**Portée** : l'équivalence couvre les portes de **rang 1 à 3** (Art. 8). Les portes 4 et 5 — bout en
bout et charge, canari — n'existent qu'à distance et sortent de l'équivalence par nature (FR-002,
Art. 23).

**Corollaire de revue** : une étape de chaîne qui **redéclare** un contrôle au lieu d'invoquer sa
cible réintroduit la divergence. C'est un constat de revue (Art. 16), pas un détail de style.

**Alternatives considérées** :

- *Test de parité comparant les listes résolues* — **écarté** : ni l'Art. 14 ni SC-005 ne l'exigent,
  et il ferait vivre la connaissance « quelles sont les portes » en deux endroits — la déclaration et
  la table de comparaison.
- *Deux configurations, discipline de revue* — écarté : la revue ne tient pas dans la durée, et
  l'écart est invisible tant qu'il ne se manifeste pas.
- *La chaîne appelle les portes locales* — séduisant mais écarté : rend la chaîne dépendante de
  l'outillage local et empêche d'ajouter des étapes qui n'ont de sens qu'à distance (construction
  d'images, bout en bout et charge).

---

## D-S03-2 — Le moteur factice est un paquet distribuable

**Décision** : `packages/fake-engine/` porte **son propre manifeste**, est versionné, et s'installe
comme dépendance de test par les autres specs.

**Rationale** : FR-012 exige une implémentation **unique** réutilisée par tous les tests
d'intégration. Un module rangé dans `tests/` serait copié dès que S04 en aurait besoin ailleurs, puis
divergerait. Or un moteur factice qui diverge du comportement réel **invalide silencieusement toute
la pyramide** — c'est le cas limite le plus dangereux identifié dans la spec.

**Conséquence** : le paquet a un cycle de vie propre (version, journal des modifications). Une
évolution du contrat d'inférence (S04) impose une évolution du paquet, visible et revuable.

**Alternatives considérées** :

- *Module dans `tests/`* — écarté pour la raison ci-dessus.
- *Conteneur seulement* — écarté : les tests unitaires du plan de contrôle doivent pouvoir
  l'instancier en processus, sans démarrer un conteneur.

---

## D-S03-3 — La chaîne d'intégration n'accède jamais à un GPU

**Décision** : contrainte d'architecture, pas limitation temporaire. Les vrais moteurs ne sont
exercés qu'au déploiement canari.

**Rationale** : Art. 8. Un GPU dans la chaîne la rendrait coûteuse, lente et indisponible, et surtout
**non reproductible** — les tests dépendraient d'un état matériel. Le prix à payer est que trois
exigences du projet échappent à la chaîne et doivent être prouvées au canari :

| Exigence | Spec | Pourquoi elle échappe à la chaîne |
| --- | --- | --- |
| Découverte de topologie matérielle | S06 (SC-001) | exige de vraies cartes appairées (`NVLink`) |
| Calibration du verdict de `fit` | S09 (SC-001) | exige 20 modèles mesurés |
| Débit additionné sur deux `host` | S20 (SC-001) | exige deux `host` réels |

**Ce point doit être dit explicitement** dans les plans concernés plutôt que laissé implicite — sans
quoi on croira ces critères couverts par la chaîne.

---

## D-S03-4 — Seuils de couverture : nécessaires, non suffisants

**Décision** : les seuils (**≥ 90 %** cœur, **≥ 70 %** ailleurs) sont **bloquants**, et la
documentation de contribution énonce explicitement qu'ils ne dispensent pas du cycle rouge → vert.

**Rationale** : la couverture mesure les lignes exécutées, pas les comportements vérifiés. Atteindre
90 % avec des tests sans assertion satisferait la lettre de l'Art. 10 en violant son esprit. Aucune
mécanique ne détecte cela de façon fiable — c'est donc une **limite assumée de l'automatisation**,
qui doit être nommée plutôt que masquée.

**Réserve** : le **chemin** de cette documentation n'est fixé par aucune source (`10b` ne prévoit à la
racine que `CONSTITUTION.md`, `CHANGELOG.md` et `runbooks/<incident>.md`). Il n'en est pas inventé
ici — ARBITRAGE 3.

**Alternatives considérées** :

- *Test de mutation* — écarté pour l'instant (Art. 20) : coût d'exécution élevé, et aucun jalon ne
  l'exige. À reconsidérer si des tests sans assertion apparaissent réellement.
- *Ne pas fixer de seuil* — écarté : la constitution les impose.

---

## D-S03-5 — Bases éphémères aux majeures de production

**Décision** : les bases éphémères des tests d'intégration utilisent **les majeures retenues en
production** (base relationnelle 18.x, cache 8.x), conformément à D1.

**Rationale** : c'est le seul point où D1 touche S03. Tester contre une majeure antérieure ferait
passer des tests qui échoueraient en production — exactement le mode de défaillance que la chaîne
d'intégration est censée empêcher.

---

## D-S03-6 — Chaîne spécifiée indépendamment de son exécuteur ; topologie gardée localement

**Décision** : la chaîne est décrite par ses **portes, leur ordre et leur effet**, sans désigner de
plateforme d'hébergement du dépôt ni d'exécuteur. Le fichier de définition est nommé `ci.yaml`
(`9b`) ; **son emplacement et sa plateforme ne le sont pas**. La topologie de fusion de l'Art. 23 est
outillée en deux couches : une **garde locale versionnée** qui refuse toute validation dont la branche
courante est `test` ou `master` et toute promotion qui saute un maillon, et les **protections de
branche de la forge** qui expriment la même règle dès qu'une forge existe.

**Rationale** : aucune source du projet ne nomme de forge — le document de référence est muet,
`RESEARCH-STACK.md` ne traite pas la plateforme d'intégration, et la constitution constate le régime
dégradé « ni chaîne d'intégration, ni dépôt distant à ce jour ». Choisir un exécuteur serait une
décision de plan sans source (Art. 7) : elle est portée en **ARBITRAGE 1**, le plus urgent du lot
puisque FR-029 et FR-030 la supposent tranchée.

Corollaire : la conformité à l'Art. 23 ne peut pas reposer sur une configuration que personne ne peut
écrire aujourd'hui. La garde **locale** est ce qui rend FR-029 opposable dès maintenant, dans le
régime local que l'Art. 23 lui-même prévoit. Une conformité affirmée sans outil est exactement le
défaut que cette décision corrige.

**Alternatives considérées** :

- *Nommer une forge et son chemin d'atelier* — écarté : décision sans source, et elle rendrait le
  plan faux dès qu'une autre forge serait choisie.
- *Attendre ARBITRAGE 1 pour outiller la topologie* — écarté : l'Art. 23 est en vigueur maintenant,
  et le régime local est précisément le cas qu'il nomme.

**Ce que cette décision remplace** : la génération vérifiée du client d'interface, précédemment
décidée ici, **sort du périmètre de S03**. Elle appartient à **S11** (`9p` tâche T2, critère A1
« Client API 100 % généré (openapi-typescript) », jalon **M2** en `9e`). `9h` borne `ui/` à « eslint
flat, prettier, vitest, playwright », et à **M0 il n'existe aucun contrat à générer** : le contrat
`/v1` est figé par S04 à M1.

---

## D-S03-7 — L'étape de charge appartient à la chaîne

**Décision** : le dernier maillon de la chaîne est une **porte unique** — bout en bout **et** charge —
exécutée sur le même environnement éphémère et contre le même moteur factice. Un scénario de charge en
échec fait échouer la chaîne et bloque la fusion.

**Rationale** : la porte 4 de l'Art. 8 dit « e2e + charge sur compose éphémère » et `9b` « e2e + k6 ·
compose éphémère · moteur factice ». Déclarer k6 en dépendance transverse sans lui donner d'étape
laissait une porte constitutionnelle non outillée : **une dépendance sans porte n'est pas une porte**.
FR-013, FR-027 et SC-010 alignent la spec sur la constitution.

**Borne de périmètre** : S03 rend l'étape exécutable et y place le **minimum qui prouve la porte**.
Les scénarios eux-mêmes vivent dans `k6/<lane>-<scénario>.js` (`10b`) et sont versionnés par **S21**
(jalon M4), qui les rejoue **sans en créer un second jeu** (Art. 19).

**Alternatives considérées** :

- *Une septième étape de charge distincte du bout en bout* — écarté : l'Art. 8 et `9b` en font un seul
  maillon sur le même environnement éphémère ; deux étapes exigeraient de démarrer deux fois cet
  environnement.
- *Charge indicative, non bloquante* — écarté : l'Art. 8 en fait une porte, et rien ne fusionne tant
  qu'une porte est rouge (FR-014).

---

## D-S03-8 — La définition de la chaîne est épinglée comme ce qu'elle produit

**Décision** : chaque action, outil ou image qu'une étape **consomme** est référencée par tag exact ou
empreinte. Un référencement flottant — `:latest`, une branche, un intervalle ouvert — fait échouer la
chaîne. Le contrôle tourne en **porte locale** et en **étape**, pour que le refus survienne avant
l'envoi.

**Rationale** : l'Art. 11 épingle « toute image, dépendance **ou action CI** ». L'étiquetage
reproductible des images construites (FR-019) ne couvre que la sortie ; sans FR-026, la chaîne
elle-même flotte, et l'on obtient une chaîne non reproductible qui garde des artefacts
reproductibles. SC-011 exige 100 % : la porte ne connaît pas d'exception.

**Trois épinglages à ne pas confondre** : dépendances (verrou reproductible) · images **construites**
(version + empreinte, FR-019) · briques **consommées** par la chaîne (FR-026).

**Alternatives considérées** :

- *Épinglage vérifié en revue seulement* — écarté : l'Art. 8 veut des portes mécaniques, et un
  `:latest` ajouté sous pression passe une revue.
- *Épinglage limité aux images* — écarté : l'Art. 11 nomme explicitement les actions.

---

## Points non tranchés

Ils ne sont pas des décisions et ne figurent pas ci-dessus. Les **huit** arbitrages ouverts sont
consignés dans [`spec.md`](./spec.md), section « Arbitrages en attente » — registre unique —, et
rappelés par leurs incidences dans [`plan.md`](./plan.md) et [`tasks.md`](./tasks.md) : forge et
exécuteur (1) · rattachement de `alembic check` à S03 ou S04 (2) · chemin du guide du contributeur (3) ·
FR-017 et la dépendance à S01 (4) · amendement de `10a` si les portes doivent devenir des entités (5) ·
`10a` annonce 22 articles au lieu de 23 (6) · écart d'effort 10.0 j contre « ≈ 6.5 j » (7) · `10b` fixe
« tâches : `S<nn>-T<n>` » quand le format Spec Kit prévaut (8).

---

## Ce que S03 ne décide pas

| Sujet | Spec propriétaire | Jalon |
| --- | --- | --- |
| Contenu du contrat d'interface | **S04** | M1 |
| Génération du client d'interface et sa vérification | **S11** (`9p` T2) | M2 |
| Source de la matrice de permissions et tests générés | **S13** | M2 |
| Fichiers de référence de facturation | **S08** | M2 |
| Scénarios de charge | **S21** | M4 |
| Tests de résilience | **S19**, **S20**, **S21** | M4 |
| Quelles specs traversent les trois chemins à revue humaine | **chaque spec** qui touche l'un des chemins nommés par l'Art. 8 (auth, facturation, proxy streaming) — S03 fournit le mécanisme, ne fige aucune liste | — |

Aucun `NEEDS CLARIFICATION` ne subsiste.
