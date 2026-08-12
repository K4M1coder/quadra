# Phase 1 — Guide de validation : S03 Socle qualité & CI

Forme humaine de la tâche `[TEST]` de `9h` (réf. `9h` T10). La version automatisée en dérive. Aucun
code d'implémentation ici.

---

## Préconditions

| Élément | Attendu |
| --- | --- |
| Dépôt | cloné, **aucune porte encore installée** pour le scénario 1 |
| Machine | **sans GPU** — c'est le point : tout doit passer sans matériel |
| S01 | utile mais **non requis** — S03 est parallélisable ; seuls les scénarios 6 et 10 consomment la définition de déploiement (ARBITRAGE 4) |
| Forge | **non requise** — aucun scénario ne suppose une plateforme d'intégration nommée (ARBITRAGE 1). En son absence, « la chaîne s'exécute » se lit « les portes s'exécutent en local et font foi » (Art. 23) |

---

## Scénario 1 — Les portes locales refusent le non conforme *(critère A1)*

Tenter de valider, successivement :

1. un fichier **mal formaté** ;
2. du code du plan de contrôle **mal typé** ;
3. un fichier contenant un **secret en clair** ;
4. un message de validation **hors convention** ;
5. un message conventionnel **sans `scope` de spec** (par exemple `feat: ...` au lieu de
   `feat(S03): ...`).

**Attendu** — les cinq tentatives sont **refusées**, et le refus **identifie le fichier** en cause.
Aucune n'atteint le dépôt distant.

**Prouve** : critère **A1** · FR-001, FR-003, FR-004, FR-006 · SC-001.

> FR-006 borne l'exigence à l'identification du **fichier** : la qualité rédactionnelle des messages
> d'outillage n'est pas une exigence de S03 — l'outillage restitue la sortie de ses propres contrôles
> telle quelle.

---

## Scénario 2 — Définition unique des portes *(SC-005)*

1. Relever la liste des portes de rang 1 à 3 exécutées en local.
2. Relever celle exécutée par la définition de chaîne.
3. Ajouter une porte à la **définition unique** (une cible du `Makefile`).
4. Réexécuter les deux relevés.

**Attendu** — les deux listes coïncident aux étapes 1–2 **sans qu'aucun contrôle ne soit déclaré deux
fois**, et la porte ajoutée à l'étape 3 apparaît **des deux côtés** sans qu'aucune configuration ait
été éditée deux fois.

**Prouve** : FR-002, FR-020 · SC-005 · Art. 14.

> **Aucun test de parité n'est attendu** : SC-005 exige l'équivalence par définition unique, pas un
> mécanisme de comparaison. Ce qui doit être vérifié ici est l'**absence de seconde déclaration** —
> une étape de chaîne qui redéclare un contrôle au lieu d'invoquer sa cible est un constat de revue
> (Art. 16).

---

## Scénario 3 — Le moteur factice, sans GPU *(critère A3)*

Sur une machine **sans GPU** :

1. Démarrer le moteur factice.
2. Demander une complétion **en flux**.
3. Imposer une latence de premier jeton et une latence inter-jetons.
4. Injecter une erreur choisie.
5. Demander une représentation vectorielle.

**Attendu** — réponse **jeton par jeton** au format d'un moteur réel ; latences **respectées** ;
erreur **fidèlement reproduite** ; représentation vectorielle au format attendu.

**Prouve** : critère **A3** · FR-007 à FR-011 · SC-003, SC-004.
Voir [`contracts/fake-engine.md`](./contracts/fake-engine.md).

---

## Scénario 4 — Unicité du moteur factice

1. Rechercher dans le dépôt un second simulateur du contrat d'inférence.
2. Vérifier que le paquet porte **son propre manifeste** et s'installe comme dépendance.

**Attendu** — **aucun** second simulateur ; le moteur factice est **installable**, pas copiable.

**Prouve** : FR-012 · Art. 19.

---

## Scénario 5 — Seuils de couverture bloquants *(critère A2)*

1. Soumettre un changement conforme.
2. Soumettre un changement faisant passer la couverture du **cœur sous 90 %**.
3. Soumettre un changement faisant passer la couverture **hors cœur sous 70 %**.

**Attendu** — seule la première soumission est acceptée ; les deux autres **font échouer la chaîne**
et **bloquent la fusion**, avec la valeur mesurée en sortie capturée.

**Prouve** : critère **A2** · FR-015 · SC-002.

---

## Scénario 6 — Ordre des portes et environnement éphémère

1. Déclencher la chaîne sur un changement conforme.
2. Observer l'ordre d'exécution.
3. Vérifier l'état des ressources après la dernière étape.

**Attendu** — ordre respecté : style et formatage → typage → tests + couverture → sécurité →
construction des images → **bout en bout et charge**. Le dernier maillon est **une seule étape**, sur
**un seul** environnement éphémère, **entièrement détruit** ; aucune ressource résiduelle entre deux
exécutions.

**Prouve** : FR-013, FR-017 · SC-007.

---

## Scénario 7 — Aucun accès GPU

Inspecter l'environnement d'exécution de **chaque** étape de la chaîne.

**Attendu** — **100 %** des étapes s'exécutent sans GPU disponible.

**Prouve** : FR-016 · SC-004 · Art. 8.

---

## Scénario 8 — Sécurité continue

Introduire une dépendance affectée par une **vulnérabilité connue**.

**Attendu** — la chaîne **échoue** et **nomme la dépendance**.

**Prouve** : FR-018 · SC-006 · Art. 21.

---

## Scénario 9 — Topologie de fusion gardée *(SC-009)*

1. Se placer sur `test`, puis sur `master`, et tenter de valider un commit sur chacune.
2. Tenter de promouvoir une branche `NNN-slug` directement vers `test`, en sautant `dev`.
3. Tenter de faire entrer une branche `NNN-slug` dans `dev` alors qu'une porte de rang 1 à 3 est
   rouge.

**Attendu** — les trois tentatives sont **refusées**. `dev` ne s'atteint que par demande de fusion aux
portes de rang 1 à 3 vertes ; `master` que par promotion depuis `test` ; aucune promotion ne saute un
maillon.

**Prouve** : FR-029, FR-030 · SC-009 · Art. 23.

> La garde est **indépendante de la plateforme** : les étapes 1 et 2 se vérifient dès aujourd'hui par
> la garde locale versionnée, sans dépôt distant. L'étape 3 se vérifie par la garde locale en régime
> local, et par les protections de branche de la forge dès qu'une forge existe (ARBITRAGE 1).

---

## Scénario 10 — La charge est une porte *(SC-010)*

1. Exécuter la dernière étape sur un changement conforme et constater que le volet de **charge**
   s'exécute sur **le même** environnement éphémère et contre **le même** moteur factice.
2. Faire échouer délibérément un scénario de charge.

**Attendu** — à l'étape 2, la chaîne **échoue** et la fusion est **bloquée**, au même titre qu'un test
unitaire rouge. La charge n'est ni ignorée, ni consignée comme mesure indicative.

**Prouve** : FR-013, FR-027 · SC-010 · Art. 8 porte 4 · `9b` « e2e + k6 ».

> Les scénarios vivent dans `k6/<lane>-<scénario>.js` (`10b`). S03 en pose le **minimum qui prouve la
> porte** ; **S21** les versionne sans en créer un second jeu (Art. 19).

---

## Scénario 11 — Épinglage de la définition de la chaîne *(SC-011)*

1. Parcourir la définition de chaîne et vérifier qu'aucune action, aucun outil, aucune image
   consommée n'est référencé par `:latest`, par une branche ou par un intervalle ouvert.
2. Introduire délibérément un tel référencement flottant et relancer.

**Attendu** — à l'étape 1, **100 %** des références sont des tags exacts ou des empreintes. À
l'étape 2, le refus survient **avant l'envoi** (porte locale) et la chaîne **échoue**.

**Prouve** : FR-026 · SC-011 · Art. 11 (« toute image, dépendance ou action CI EST épinglée »).

> À distinguer de FR-019, qui étiquette les images **construites**. Ici, ce sont les briques
> **consommées** par la chaîne.

---

## Scénario 12 — Cohérence des migrations

1. Exécuter la chaîne telle quelle à **M0** : aucune migration n'existe encore, le schéma arrivant
   avec S04 (`9c`, jalon M1).
2. Vérifier que le contrôle de cohérence est bien **présent et actif**, non neutralisé.

**Attendu** — à l'étape 1, la porte **réussit à vide**. À l'étape 2, elle est déclarée et exécutée au
rang 3, donc dans l'ensemble couvert par l'équivalence locale ↔ chaîne — pas commentée « en
attendant ».

**Prouve** : FR-028 · `9b` « `alembic check` » · ARBITRAGE 2 (rattachement à S03 ou S04, non tranché).

---

## Récapitulatif critère → scénario

| Critère ou exigence | Source | Scénario | Réf. de traçabilité |
| --- | --- | --- | --- |
| **A1** — une porte locale refuse le non conforme | `9h` | 1 | réf. `9h` T3, T10 |
| Équivalence locale ↔ chaîne par définition unique | Art. 14 · SC-005 | 2 | réf. `9h` T3, T8 |
| **A3** — moteur factice : flux, latence, erreurs | `9h` | 3 | réf. `9h` T6, T7, T10 |
| Unicité du moteur factice | Art. 19 · FR-012 | 4 | réf. `9h` T6 |
| **A2** — chaîne rouge sous les seuils | `9h` | 5 | réf. `9h` T2, T8, T10 |
| Ordre des portes, environnement éphémère détruit | FR-013, FR-017 | 6 | réf. `9h` T8, T9 |
| Aucun GPU | consigne `9h` · Art. 8 | 7 | réf. `9h` T8, T9 |
| Sécurité continue | Art. 21 | 8 | réf. `9h` T8 |
| Topologie de fusion gardée | Art. 23 · SC-009 | 9 | *aucune tâche de `9h`* — exigence postérieure au document |
| La charge est une porte | Art. 8 porte 4 · `9b` · SC-010 | 10 | réf. `9h` T9 |
| Épinglage de la définition de chaîne | Art. 11 · SC-011 | 11 | réf. `9h` T8 |
| Cohérence des migrations | `9b` · FR-028 | 12 | réf. `9h` T8 |

Les `Tn` cités sont des **références de traçabilité** vers les tâches de la fiche `9h`, pas des
identifiants de tâches : ceux-ci vivent dans [`tasks.md`](./tasks.md).
