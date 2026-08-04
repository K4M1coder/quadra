# Phase 0 — Recherche : S03 Socle qualité & CI

Veille transverse : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md).
Ce document ne traite que les décisions **propres à S03**.

---

## D-S03-1 — Source unique de déclaration des portes, parité vérifiée par test

**Décision** : les portes de qualité sont déclarées **une seule fois** ; la configuration locale et
la chaîne distante consomment cette déclaration. Un test dédié compare les deux listes **résolues**
et échoue si elles divergent.

**Rationale** : l'Art. 14 exige qu'« un commit vert en local prédise une CI verte ». Deux
configurations écrites séparément satisfont cette exigence le premier jour et la violent au premier
ajout de porte — sans que personne le remarque, puisque le symptôme est une CI qui échoue *après*
un local vert, ce qu'on attribue d'abord à autre chose. Le test de parité transforme une intention
en propriété vérifiée (SC-005).

**Alternatives considérées** :

- *Deux configurations, discipline de revue* — écarté : la revue ne tient pas dans la durée, et
  l'écart est invisible tant qu'il ne se manifeste pas.
- *La chaîne distante appelle les portes locales* — séduisant mais écarté : rend la chaîne dépendante
  de l'outillage local et empêche d'ajouter des étapes qui n'ont de sens qu'à distance (construction
  d'images, bout en bout).

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

**Rationale** : Art. 8. Un GPU en intégration continue rendrait la chaîne coûteuse, lente et
indisponible, et surtout **non reproductible** — les tests dépendraient d'un état matériel. Le prix
à payer est que trois exigences du projet échappent à la chaîne et doivent être prouvées au canari :

| Exigence | Spec | Pourquoi elle échappe à la chaîne |
| --- | --- | --- |
| Découverte de topologie matérielle | S06 (SC-001) | exige de vraies cartes appairées |
| Calibration du verdict de tenue mémoire | S09 (SC-001) | exige 20 modèles mesurés |
| Débit additionné sur deux machines | S20 (SC-001) | exige deux hôtes réels |

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

**Alternatives considérées** :

- *Test de mutation* — écarté pour l'instant (Art. 20) : coût d'exécution élevé, et aucun jalon ne
  l'exige. À reconsidérer si des tests sans assertion apparaissent réellement.
- *Ne pas fixer de seuil* — écarté : la constitution les impose.

---

## D-S03-5 — Bases éphémères aux majeures de production

**Décision** : les bases éphémères des tests d'intégration utilisent **les majeures retenues en
production** (base relationnelle 18.x, cache 8.x), conformément à D1.

**Rationale** : c'est le seul point où D1 touche S03. Tester contre une majeure antérieure ferait
passer des tests qui échoueraient en production — exactement le mode de défaillance que
l'intégration continue est censée empêcher.

---

## D-S03-6 — Le client d'interface est généré, la génération est vérifiée

**Décision** : le client d'accès au serveur est **généré** depuis le contrat d'interface, dans un
répertoire dont le nom signale qu'il ne s'édite pas. La chaîne **régénère et compare** — une
divergence échoue.

**Rationale** : l'Art. 19 exige que le contrat soit la source unique. Générer une fois puis éditer à
la main est le mode de dégradation naturel ; seule la régénération vérifiée l'empêche. C'est aussi ce
qui rend vrai le critère A1 de S11 (« client 100 % généré ») dans la durée, et pas seulement au
premier jour.

**Note** : le **contrat lui-même** est figé par S04 (tâche T9, par un humain). S03 fournit le
mécanisme de génération et sa vérification, pas le contrat.

---

## Ce que S03 ne décide pas

| Sujet | Spec propriétaire |
| --- | --- |
| Contenu du contrat d'interface | **S04** |
| Source de la matrice de permissions et tests générés | **S13** |
| Scénarios de charge métier | **S21** |
| Quels changements traversent les 3 chemins à revue humaine | **S04**, **S08**, **S12** |

Aucun `NEEDS CLARIFICATION` ne subsiste.
