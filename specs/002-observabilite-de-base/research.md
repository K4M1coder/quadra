# Phase 0 — Recherche : S02 Observabilité de base

Veille transverse : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md) (§1 versions, §7 décisions).
Ce document ne traite que les décisions **propres à S02**.

---

## D-S02-1 — Provisionnement réappliqué à chaque démarrage

**Décision** : le provisionnement **réapplique** les définitions versionnées à chaque démarrage. Ce
n'est pas un import initial.

**Rationale** : c'est la seule lecture de l'Art. 19 qui tienne. Un import unique laisse une
modification faite à la main dans Grafana survivre indéfiniment — le dépôt cesse alors d'être la
source de vérité sans que personne s'en aperçoive, jusqu'au jour où un `Dashboard` affiche autre
chose que ce que le dépôt dit. Le comportement est **vérifiable** : modifier, redémarrer, constater le
retour à la version du dépôt (SC-005).

**Alternatives considérées** :

- *Import initial puis liberté* — écarté : divergence garantie à terme, sans signal.
- *Grafana en lecture seule* — écarté : trop rigide, empêche l'exploration ponctuelle. La
  réapplication autorise l'exploration **et** garantit le retour à la référence.

---

## D-S02-2 — Cadences dissymétriques : 1 s pour `dcgm-exporter`, 5 s ailleurs

**Décision** : scraper `dcgm-exporter` à 1 seconde, les autres jobs à 5 secondes (`5b`).

**Rationale** : valeurs du déploiement de référence du document, et le compromis se justifie. Un pic
thermique ou une pointe de puissance sur une carte GPU se joue à l'échelle de la seconde — l'échantillonner
à 5 s le rend invisible. À l'inverse, scraper les moteurs à 1 s ajoute une charge inutile sur le
chemin qu'on cherche précisément à ne pas perturber (Art. 2).

**Conséquence** : la cardinalité de la série matérielle est ~5× celle des autres. Acceptable : elle
est bornée par le nombre de cartes (4), pas par le trafic.

---

## D-S02-3 — Libellés = identifiants : une **règle** à M0, pas un module

**Décision** : la contrainte « labels = ids, jamais de PII » (`9g`, `5c`) est posée comme **règle de
nommage normative**, portée par la liste blanche de `10b` et par la revue (Art. 16). S02 **n'écrit
aucun module** de contrôle et **aucune porte mécanique** de libellés.

**Rationale** : l'Art. 1 interdit la sortie de données ; une série temporelle qui porterait un
identifiant de requête ou un extrait de prompt **est** une fuite, et durable — la rétention est de
90 jours. La règle est donc dure. Mais elle n'a **aucun sujet à vérifier à M0** : les libellés visés
(`lane`, `alias`, `node`, `host`, `key_id`) sont émis par S04, S05 et S08, en M1–M2 (`9c`), et à M0
aucun composant ne les produit. `9g` demande une consigne, pas une tâche — sa table le dit
explicitement (« Critères → preuves : A1–A3 → T8 »). Écrire le module ici serait du code avant le
jalon qui l'exige (Art. 20), et ≈ 0.5 j hors des ≈ 3 j-agent budgétés.

**Où la porte doit atterrir** : **S03** (socle qualité, où elle rejoint les autres portes de l'Art. 8)
ou **S04** (première métrique métier émise). À trancher — voir les *Arbitrages ouverts* du plan.

**Effet de bord bénéfique de la règle** : c'est aussi la protection contre l'explosion de cardinalité,
qui est le mode de défaillance classique d'un Prometheus.

**Liste blanche retenue** : `lane`, `alias`, `node`, `host`, `key_id` — tous des identifiants stables
et bornés (`10b`).

---

## D-S02-4 — Réexposer les métriques amont sans renommage

**Décision** : les métriques exposées nativement par les moteurs sont réexposées **telles quelles**.

**Rationale** : Art. 6. Renommer pour « harmoniser » avec la convention du projet serait un fork
déguisé : la correspondance avec la documentation amont serait rompue, et chaque montée de version
du moteur exigerait de réviser la table de correspondance. La convention `quadra_*` s'applique aux
métriques **propres au projet**, pas à celles qu'on emprunte.

**Conséquence assumée** : deux conventions de nommage coexistent dans Prometheus. C'est voulu et
lisible — le préfixe indique l'origine.

---

## D-S02-5 — Aucun `Dashboard` pour des métriques inexistantes

**Décision** : S02 livre exactement deux `Dashboards` — `ds-gpu.json` et `ds-engines.json` — qui
portent sur des métriques **réellement peuplées au jalon M0**.

**Rationale** : Art. 20. Créer un `Dashboard` « requêtes » ou « budgets » à M0 produirait des
panneaux vides pendant plusieurs jalons, ce qui érode la confiance dans l'outil et donne l'illusion
d'une couverture. Les specs qui émettent ces métriques (S04, S05, S08) apporteront leurs vues.

**Point important** : aucune modification de `prometheus.yml` ne sera nécessaire pour les scraper,
**à condition** que la convention de nommage soit respectée. C'est ce qui rend l'ajout gratuit.

---

## D-S02-6 — Cibles de scrape : la topologie `5b`, pas les noms `vllm-*` de `6e`

**Décision** : `prometheus.yml` déclare six jobs — `gateway`, `node-A` (sglang GPU 0+1), `node-B`
(sglang GPU 2), `node-C` (llama.cpp GPU 3), `dcgm-exporter`, `self` — conformément au déploiement de
référence `5b` et à FR-001.

**Rationale** : `6e` liste `vllm-qwen:8000`, `vllm-mistral:8001`, `llamacpp-gpu3:8002`, alors que
`5b` décrit trois nœuds d'inférence sglang/llama.cpp et que `5a` fait de sglang le **moteur
principal**. Les noms `vllm-*` sont un **état antérieur** de l'étude préliminaire : les recopier
figerait un moteur que le document ne retient qu'en driver optionnel (`7f`). Écart documentaire dû
(Art. 7), consigné dans les *Arbitrages ouverts* du plan.

**Garantie conservée de `6e`** : les cadences (5 s / 1 s DCGM) et le principe « aucune seconde chaîne
de métriques » sont reprises telles quelles.

---

## Écart de majeures — conséquence opérationnelle de D1

La décision D1 retient l'amont courant (Prometheus 3.x LTS, Grafana 13.x) là où `5a` épingle
prometheus 2 et grafana 11.

**Conséquence concrète pour T1 et T2** : le format de `prometheus.yml` et les options de rétention ont
évolué entre les majeures. La tâche doit être écrite **pour la version retenue**, en consultant sa
documentation, et non transposée depuis un exemple correspondant à l'ancienne majeure. C'est un piège
d'implémentation réel : les exemples les plus répandus en ligne portent encore sur la majeure
précédente.

**Point resté ouvert** : D1 ne nomme pas alertmanager dans sa *Portée*, et ni `5a` ni la table §1 de
la veille ne lui donnent de version. Le digest à épingler est **à trancher** — voir les *Arbitrages
ouverts* du plan.

Aucun `NEEDS CLARIFICATION` ne subsiste.
