# Phase 1 — Guide de validation : S03 Socle qualité & CI

Forme humaine de la tâche `[TEST]` **T10**. La version automatisée en dérive. Aucun code
d'implémentation ici.

---

## Préconditions

| Élément | Attendu |
| --- | --- |
| Dépôt | cloné, **aucune porte encore installée** pour le scénario 1 |
| Machine | **sans GPU** — c'est le point : tout doit passer sans matériel |
| S01 | utile mais **non requis** — S03 est parallélisable ; seul le scénario 6 consomme la définition de déploiement |

---

## Scénario 1 — Les portes locales refusent le non conforme *(critère A1)*

Tenter de valider, successivement :

1. un fichier **mal formaté** ;
2. du code du plan de contrôle **mal typé** ;
3. un fichier contenant un **secret en clair** ;
4. un message de validation **hors convention**.

**Attendu** — les quatre tentatives sont **refusées**, chacune avec un message nommant **le fichier
et la règle**. Aucune n'atteint le dépôt distant.

**Prouve** : critère **A1** · FR-001, FR-003, FR-004, FR-006 · SC-001.

---

## Scénario 2 — Parité locale ↔ distante *(le contrôle le plus fragile)*

1. Exécuter le test de parité des portes.
2. **Ajouter une porte** à la déclaration, côté distant uniquement.
3. Réexécuter.

**Attendu** — le test passe à l'étape 1 et **échoue à l'étape 3**, en nommant la porte absente en
local.

**Prouve** : FR-002 · SC-005 · Art. 14.

> Ce scénario est le seul qui vérifie une **propriété du processus** plutôt qu'un comportement du
> produit. Sans lui, la parité se dégrade sans signal : on ne s'en aperçoit qu'en voyant une chaîne
> distante rouge après un local vert, ce qu'on impute d'abord à autre chose.

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
3. Vérifier l'état des ressources après l'étape de bout en bout.

**Attendu** — ordre respecté : style → typage → tests + couverture → sécurité → construction →
bout en bout. L'environnement éphémère est **entièrement détruit** ; aucune ressource résiduelle
entre deux exécutions.

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

## Scénario 9 — Client d'interface généré

1. Régénérer le client depuis le contrat d'interface.
2. Comparer au client présent dans le dépôt.
3. Éditer le client à la main, relancer la chaîne.

**Attendu** — étapes 1–2 : identiques. Étape 3 : la chaîne **échoue**.

**Prouve** : Art. 19 · prépare le critère A1 de **S11**.

---

## Récapitulatif critère → scénario

| Critère du document | Scénario | Tâche |
| --- | --- | --- |
| **A1** — une porte locale refuse le non conforme | 1 | T3, T10 |
| **A2** — chaîne rouge sous les seuils | 5 | T2, T8, T10 |
| **A3** — moteur factice : flux, latence, erreurs | 3 | T6, T7, T10 |
| Parité locale ↔ distante | 2 | T3, T8 |
| Unicité du moteur factice | 4 | T6 |
| Ordre des portes, environnement éphémère | 6 | T8, T9 |
| Aucun GPU | 7 | T8, T9 |
| Sécurité continue | 8 | T8 |
| Client généré | 9 | T4 |
