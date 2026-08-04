# Phase 0 — Recherche : S02 Observabilité de base

Veille transverse : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md) (§1 versions, §7 décisions).
Ce document ne traite que les décisions **propres à S02**.

---

## D-S02-1 — Provisionnement réappliqué à chaque démarrage

**Décision** : le provisionnement **réapplique** les définitions versionnées à chaque démarrage. Ce
n'est pas un import initial.

**Rationale** : c'est la seule lecture de l'Art. 19 qui tienne. Un import unique laisse une
modification faite à la main dans l'interface survivre indéfiniment — le dépôt cesse alors d'être la
source de vérité sans que personne s'en aperçoive, jusqu'au jour où un tableau de bord affiche autre
chose que ce que le code dit. Le comportement est **vérifiable** : modifier, redémarrer, constater le
retour à la version du dépôt (SC-005).

**Alternatives considérées** :

- *Import initial puis liberté* — écarté : divergence garantie à terme, sans signal.
- *Interface en lecture seule* — écarté : trop rigide, empêche l'exploration ponctuelle. La
  réapplication autorise l'exploration **et** garantit le retour à la référence.

---

## D-S02-2 — Cadences dissymétriques : 1 s pour le matériel, 5 s ailleurs

**Décision** : interroger l'exportateur matériel à 1 seconde, les autres cibles à 5 secondes.

**Rationale** : valeurs du déploiement de référence du document, et le compromis se justifie. Un pic
thermique ou une pointe de puissance sur une carte GPU se joue à l'échelle de la seconde — l'échantillonner
à 5 s le rend invisible. À l'inverse, interroger les moteurs à 1 s ajoute une charge inutile sur le
chemin qu'on cherche précisément à ne pas perturber (Art. 2).

**Conséquence** : la cardinalité de la série matérielle est ~5× celle des autres. Acceptable : elle
est bornée par le nombre de cartes (4), pas par le trafic.

---

## D-S02-3 — Contrôle de conformité des libellés en intégration continue

**Décision** : un contrôle automatisé rejette toute métrique dont un libellé porte une donnée
personnelle ou une valeur à cardinalité libre.

**Rationale** : l'Art. 1 interdit la sortie de données ; une série temporelle qui porterait un
identifiant de requête ou un extrait de prompt **est** une fuite, et durable — la rétention est de
90 jours. Le contrôle en revue humaine ne suffit pas : le risque apparaît à chaque nouvelle métrique
émise par une spec ultérieure. En faire une porte mécanique (Art. 8) le rend permanent.

**Effet de bord bénéfique** : c'est aussi la protection contre l'explosion de cardinalité, qui est le
mode de défaillance classique d'une chaîne de collecte.

**Liste blanche retenue** : `lane`, `alias`, `node`, `host`, `key_id` — tous des identifiants stables
et bornés (convention 10b).

---

## D-S02-4 — Réexposer les métriques amont sans renommage

**Décision** : les métriques exposées nativement par les moteurs sont réexposées **telles quelles**.

**Rationale** : Art. 6. Renommer pour « harmoniser » avec la convention du projet serait un fork
déguisé : la correspondance avec la documentation amont serait rompue, et chaque montée de version
du moteur exigerait de réviser la table de correspondance. La convention `quadra_*` s'applique aux
métriques **propres au projet**, pas à celles qu'on emprunte.

**Conséquence assumée** : deux conventions de nommage coexistent dans la chaîne de collecte. C'est
voulu et lisible — le préfixe indique l'origine.

---

## D-S02-5 — Aucun tableau de bord pour des métriques inexistantes

**Décision** : S02 livre exactement deux tableaux de bord — matériel et moteurs — qui portent sur des
métriques **réellement peuplées au jalon M0**.

**Rationale** : Art. 20. Créer un tableau de bord « requêtes » ou « budgets » à M0 produirait des
panneaux vides pendant plusieurs jalons, ce qui érode la confiance dans l'outil et donne l'illusion
d'une couverture. Les specs qui émettent ces métriques (S04, S05, S08) apporteront leurs vues.

**Point important** : aucune modification de configuration ne sera nécessaire pour les collecter,
**à condition** que la convention de nommage soit respectée. C'est ce qui rend l'ajout gratuit.

---

## Écart de majeures — conséquence opérationnelle de D1

La décision D1 retient l'amont courant (collecte 3.x LTS, visualisation 13.x) là où le document
épingle des majeures antérieures.

**Conséquence concrète pour T1 et T2** : le format de configuration et les options de rétention ont
évolué entre les majeures. La tâche doit être écrite **pour la version retenue**, en consultant sa
documentation, et non transposée depuis un exemple correspondant à l'ancienne majeure. C'est un piège
d'implémentation réel : les exemples les plus répandus en ligne portent encore sur la majeure
précédente.

Aucun `NEEDS CLARIFICATION` ne subsiste.
