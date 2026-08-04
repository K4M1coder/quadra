# Veille technique transverse — état de l'art au 2026-08

**Statut** : note de recherche partagée par les 21 plans (S01–S21).
**Raison d'être** : l'**Art. 22** exige de vérifier l'existant *avant* toute implémentation non
triviale et de consigner ce qui est **réutilisé, imité ou écarté, avec la raison**. L'**Art. 19**
interdit de dupliquer cette information dans 21 plans : cette note est la **source unique**, chaque
plan y renvoie.

**Portée** : ce document **constate** l'état de l'amont et **signale** les écarts avec le document de
référence. Il ne décide rien : figer une version relève de l'**Art. 11** et toute évolution passe par
le workflow de bascule (canari GPU 3 puis rollback par ré-étiquetage). Les arbitrages marqués
**« décision mainteneur »** sont à trancher avant le jalon concerné.

---

## 1. Écart de versions — document de référence (5a) vs amont au 2026-08

Le document a été rédigé sur un instantané antérieur. Les familles majeures ont bougé.

| Composant | Épinglé dans le document (5a) | Amont au 2026-08 | Écart | Impact |
| --- | --- | --- | --- | --- |
| PostgreSQL | 16 | **18.4** stable (19 en bêta) | 2 majeures | **décision mainteneur** |
| Redis | 7 | **8.8 / 8.10** | 1 majeure | **décision mainteneur** |
| Grafana | 11 | **13.0** | 2 majeures | **décision mainteneur** |
| Prometheus | 2 | **3.13.1 LTS** | 1 majeure | **décision mainteneur** |
| Caddy | 2 | 2.11.2 | patch | aucun — même famille |
| SGLang | 0.5 | 0.5.8 | patch | préciser le patch à l'épinglage |
| React | 19 | 19.2.7 | patch | aucun |
| llama.cpp | b4102 | releases `b####` continues | à revérifier | vérifier la disponibilité du tag |
| CUDA / pilote | 12.6 / 560 | versions ultérieures disponibles | majeur | **conserver** — voir ci-dessous |

### Lecture

- **Conserver le pilote GPU et CUDA tels qu'épinglés.** Le document identifie explicitement « une
  seule combinaison validée » comme **le risque de la phase 1**. Monter de version sans banc de
  validation transformerait un risque connu en panne inexpliquée. L'Art. 11 protège précisément ce
  cas : l'épinglage est *la condition* du canari et du retour arrière.
- **PostgreSQL, Redis, Grafana, Prometheus relèvent d'un arbitrage.** Deux majeures de retard sur un
  composant de données n'est pas neutre à 27 semaines de projet : au jalon M4, l'écart sera plus
  grand encore. Deux options cohérentes avec la constitution :
  1. **Épingler l'amont actuel dès S01** — le projet démarre à jour, et l'Art. 11 fige ensuite.
  2. **Épingler les versions du document** — fidélité au document (Art. 7), avec une montée de
     version planifiée comme un changement à part entière (workflow de bascule).
  L'option 1 est la moins coûteuse **maintenant** (aucun code n'existe) et la plus coûteuse **plus
  tard**. À trancher avant S01, car S01 fige la définition de déploiement.
- Ne pas confondre « épinglé » et « ancien » : l'Art. 11 exige un tag ou une empreinte exacte, pas une
  version vieille.

---

## 2. Moteurs d'inférence — choix du document confirmé

**Réutilisé tel quel (Art. 6)** : SGLang comme moteur principal, llama.cpp pour le format de fichier
unique.

L'état de l'art au 2026 confirme le choix et sa raison :

- **SGLang** l'emporte sur la **latence** et la **réutilisation de préfixe**, ce qui correspond
  exactement au profil de Quadra : chat multi-tours et agents partageant un prompt système.
- **vLLM** l'emporte sur le **débit brut à grand lot** et la largeur du support matériel.
- La pratique établie consiste à **faire tourner les deux derrière une passerelle** — c'est
  précisément l'architecture de S07 (contrat de driver + moteurs interchangeables).

**Conséquence pour S07** : le contrat de driver n'est pas une abstraction spéculative (ce qui
tomberait sous l'Art. 20), c'est la pratique dominante du domaine. Le driver vLLM optionnel prévu par
le document est justifié.

---

## 3. Estimation de tenue mémoire — S09, risque de la phase 3

**Formule de référence du domaine** : `VRAM ≈ poids + cache de contexte + surcharge d'exécution`,
avec une surcharge usuellement estimée à **15–25 %** pour le cache et le cadre d'exécution.

Points vérifiés qui affectent directement S09 :

- Le cache de contexte croît **linéairement** avec la longueur de contexte **et** la taille de lot —
  le verdict de tenue doit donc être calculé **pour une longueur de contexte visée**, ce que la spec
  exige déjà (FR-006).
- Le cache de contexte est lui-même **quantifiable** (8 bits ≈ moitié de la mémoire, 4 bits ≈ quart),
  et les deux moteurs retenus le supportent. **Ce paramètre est absent du document.** Il change
  matériellement le verdict : un modèle « ne tient pas » en cache 16 bits peut « tenir » en 8 bits.
  → **À arbitrer dans le plan S09** : soit le verdict suppose une quantification de cache fixée et le
  documente, soit il l'expose comme paramètre. Ignorer la question produirait des verdicts faux dans
  un sens conservateur.
- La marge de **8 %** retenue par le document est **inférieure** à la fourchette usuelle de 15–25 %.
  Ce n'est pas nécessairement une erreur — la marge du document porte peut-être sur un périmètre
  différent — mais **la calibration sur 20 modèles mesurés (T3) doit trancher**. C'est le risque
  identifié de la phase 3, et cette note en confirme le bien-fondé.

---

## 4. Classement de l'arène — S16, écart méthodologique réel

Le document spécifie `update_elo()` avec **K=32**, c'est-à-dire un **Elo en ligne** classique.

**L'état de l'art a évolué** : les arènes de référence ont abandonné l'Elo en ligne au profit d'un
modèle **Bradley-Terry** ajusté sur **l'ensemble** des comparaisons par paires, présenté ensuite sur
une échelle de type Elo pour la lisibilité.

Raisons documentées de ce changement, toutes applicables à Quadra :

| Point | Elo en ligne (K=32) | Bradley-Terry ajusté |
| --- | --- | --- |
| Sensibilité à l'**ordre** des votes | **oui** — deux ordres donnent deux classements | non |
| Intervalles d'incertitude | non fournis | fournis |
| Coût de calcul | incrémental, trivial | réajustement global |
| Gestion des **égalités** | ad hoc | mal gérée aussi — limite connue des deux |

**Pertinence pour Quadra** : le volume de votes d'une équipe interne sera **faible**. C'est
exactement le régime où la sensibilité à l'ordre est la plus visible et où un intervalle
d'incertitude est le plus utile — la spec S16 exige d'ailleurs déjà d'afficher le **nombre de votes**
fondant chaque rang (FR-016), pour la même raison.

→ **Décision mainteneur, à porter dans le plan S16.** Deux options défendables :

1. **Conserver l'Elo K=32** — fidèle au document, incrémental, trivial à tester par fichiers de
   référence (Art. 10), cohérent avec l'Art. 9 (simplicité). Accepter la sensibilité à l'ordre, la
   documenter.
2. **Ajuster un Bradley-Terry** — méthode courante aujourd'hui, ordre-indépendante, fournit
   l'incertitude. Recalcul global à chaque vote, mais sur un volume interne c'est négligeable.

Dans les deux cas, l'exigence de la spec reste **l'exactitude vérifiable par fichiers de référence**
(SC-002) — elle ne présuppose pas la méthode, ce qui rend l'arbitrage possible sans réécrire la spec.

---

## 5. Contrat des lots asynchrones — S18, écart de contrat à lever

Le document décrit `POST /v1/batches` recevant « fichiers + modèle + prompt ». Le contrat public
réel, que S04 s'engage à respecter **sans extension** (« /v1 : contrat OpenAI, jamais étendu »,
convention 10b), a une forme précise :

- entrée = **fichier JSONL téléversé au préalable**, une requête par ligne, chacune portant un
  `custom_id` **unique** ;
- un fichier ne cible **qu'un seul modèle** ; le corps de chaque ligne reprend les paramètres du
  point de terminaison sous-jacent ;
- paramètre de **fenêtre d'exécution** (valeur usuelle : 24 h) ;
- **statuts** propres au lot (validation → … → terminé) ;
- sortie = **deux identifiants de fichier** — résultats et erreurs.

**Écart à lever, et il est structurant** :

1. Le contrat réel suppose un **téléversement de fichier** préalable, donc une surface de gestion de
   fichiers que ni le document ni les specs ne prévoient.
2. La spec S18 fixe une disponibilité des résultats de **7 jours** et une notification à la fin ;
   le contrat public expose des **identifiants de fichier** et une fenêtre de 24 h. Les deux ne se
   contredisent pas nécessairement, mais l'articulation doit être décidée.
3. Les **statuts** du contrat public et la machine à états normative du projet (accepté → planifié →
   en cours ⇄ en cession → terminé) doivent être **mis en correspondance** explicitement.

→ **Décision mainteneur, à porter dans les plans S18 et S04.** Trois options :

- **(a) Compatibilité stricte** — implémenter le contrat public à l'identique, y compris le
  téléversement de fichiers. Conforme à la promesse « le SDK standard fonctionne sans modification »
  (critère A1 de S04), mais élargit S18 au-delà de son estimation de 6 j-agent.
- **(b) Surface propre** — exposer les lots sous la surface d'administration (`/api`) plutôt que sous
  `/v1`, ce que la convention 10b autorise explicitement (« le custom vit sous /api »). Le contrat
  public reste intact et non étendu ; on renonce à la compatibilité SDK **sur les lots seulement**.
- **(c) Les deux** — surface propre d'abord, compatibilité publique ensuite si le besoin apparaît
  (Art. 20).

**L'option (b) semble la plus cohérente** avec la convention de nommage du projet et avec l'Art. 20,
mais elle contredit la mention de `/v1/batches` en 4d : c'est **le document lui-même qui est
ambigu** sur ce point, et l'arbitrage revient au mainteneur.

---

## 6. Passerelle et schéma de clés — inspiration confirmée

Le document cite une passerelle open source comme source du schéma de clés. La vérification confirme
que l'approche est celle du domaine : **point d'entrée unique compatible avec le contrat standard**,
apportant authentification unifiée, limitation de débit, suivi de dépense, routage et journal
d'audit — soit exactement le périmètre de S04 + S08 + S13.

**Réutilisé** : le modèle conceptuel (clé → limites → budget → routage).
**Écarté** : l'adoption de la passerelle elle-même comme dépendance. Raison : Quadra a besoin du
**plan de contrôle** (lanes, superviseur, catalogue matériel-aware) qu'aucune passerelle générique ne
fournit, et l'Art. 6 limite le code custom à ce plan de contrôle — pas à réimplémenter un proxy
générique. C'est cohérent : on emprunte le **design**, pas le composant.

---

## 7. Décisions — **arbitrées le 2026-08-01**

Statut : **tranchées** par le mainteneur sur recommandation. Elles sont reprises telles quelles dans
le plan de chaque spec concernée. Revenir sur l'une d'elles est possible — c'est un changement de
plan, pas un amendement de la constitution — mais doit être fait explicitement et propagé.

| # | Décision | Spec | Jalon |
| --- | --- | --- | --- |
| **D1** | **Épingler l'amont actuel** — Postgres 18.x, Redis 8.x, Grafana 13.x, Prometheus 3.x LTS | S01, S02 | M0 |
| **D2** | **Conserver le pilote GPU et CUDA du document** (560 / 12.6) | S01 | M0 |
| **D3** | **Exposer la quantification du cache de contexte en paramètre** du verdict de tenue | S09 | M2 |
| **D4** | **La marge de tenue mémoire est tranchée par la calibration** sur 20 modèles mesurés | S09 | M2 |
| **D5** | **Conserver l'Elo en ligne K=32** | S16 | M3 |
| **D6** | **Exposer les lots sous la surface d'administration**, pas sous la surface publique | S04, S18 | M1 (contrat) |

### D1 — épingler l'amont actuel

*Retenu* : partir des versions courantes plutôt que de celles du document.

*Raison* : aucun code n'existe encore — c'est le seul moment où la montée est gratuite. Dans six
mois, l'écart sera de trois majeures sur Postgres et le coût sera réel. L'Art. 11 n'exige pas des
versions **anciennes**, il exige des versions **figées** : on épingle par digest l'amont d'aujourd'hui.

*Portée* : Postgres, Redis, Grafana, Prometheus, Caddy, React. **Ne s'applique pas** au couple
pilote/CUDA (voir D2), ni aux moteurs d'inférence, dont la version reste celle validée par le banc.

*Conséquence* : la table de dépendances 5a du document est **périmée sur ces quatre lignes**. Le
fichier de digests du dépôt fait foi (Art. 19), et cet écart avec le document est consigné ici.

### D2 — conserver le pilote GPU et CUDA du document

*Retenu* : ne pas monter de version.

*Raison* : le document désigne « une seule combinaison validée » comme **le risque de la phase 1**.
D1 et D2 peuvent sembler contradictoires ; ils ne le sont pas. Les composants de D1 sont
interchangeables derrière des interfaces stables et testables sans GPU. Le couple pilote/CUDA est le
seul élément de la pile qu'on **ne peut pas valider en intégration continue** (Art. 8 : la CI ne
touche jamais un GPU). Ce qu'on ne peut pas tester, on ne le change pas sans banc.

*Révision* : au canari, sur banc dédié — jamais par opportunité.

### D3 — quantification du cache de contexte exposée en paramètre

*Retenu* : le verdict de tenue prend la quantification du cache comme **entrée**, au même titre que
la longueur de contexte et la quantification des poids.

*Raison* : les deux moteurs retenus la supportent, et son effet est de premier ordre — un modèle qui
« ne tient pas » en cache 16 bits peut « tenir » en 8 bits. La figer implicitement produirait des
verdicts faux dans le sens conservateur, c'est-à-dire des modèles déclarés inutilisables alors qu'ils
fonctionnent. Or le verdict sert précisément à décider d'un téléchargement de plusieurs dizaines de
gigaoctets.

*Conséquence pour S09* : `FR-006` prend un paramètre de plus. La fonction reste **pure et
déterministe** (FR-009), donc calibrable et testable unitairement.

### D4 — la marge est tranchée par la calibration

*Retenu* : ne pas figer la marge dans le plan. La campagne de calibration sur 20 modèles mesurés
(tâche T3 de S09) **produit** la valeur.

*Raison* : la marge de 8 % du document est inférieure à la fourchette usuelle de 15–25 %, sans qu'on
puisse savoir si les deux portent sur le même périmètre. Trancher à l'aveugle entre deux chiffres
dont on ignore la comparabilité serait arbitraire. L'exigence vérifiable de la spec est la
**concordance 20/20** (SC-001) : c'est elle qui contraint la marge, pas l'inverse.

*Conséquence* : la marge est une **sortie** de la calibration, consignée dans le plan S09 une fois
mesurée. Si la calibration ne converge pas à 20/20, c'est le modèle de calcul qu'il faut revoir, pas
la marge qu'il faut gonfler.

### D5 — conserver l'Elo en ligne K=32

*Retenu* : la méthode du document, malgré l'évolution de l'état de l'art vers Bradley-Terry.

*Raison* : l'Art. 9 tranche — entre deux conceptions qui satisfont les critères d'acceptation, la
plus simple gagne, et la complexité se justifie par un critère mesurable, jamais par une généralité
supposée. L'Elo incrémental est trivial à tester par fichiers de référence (exigence SC-002), tient
en quelques lignes, et se comprend sans bagage statistique. Le classement sert ici à **orienter une
décision d'adoption au sein d'une équipe**, pas à publier un palmarès public.

*Limite acceptée et à documenter dans l'interface* : la sensibilité à l'ordre des votes. Elle est
partiellement compensée par `FR-016` (afficher le nombre de votes fondant chaque rang), qui est le
garde-fou honnête en régime de faible volume.

*Révision* : si le volume de votes devient important ou si un désaccord sur le classement apparaît,
Bradley-Terry redevient le bon choix. La spec ne présuppose pas la méthode (SC-002 exige
l'exactitude, pas l'algorithme) : le basculement ne nécessitera pas de réécrire la spec.

### D6 — les lots vivent sous la surface d'administration

*Retenu* : exposer les lots asynchrones sous la **surface d'administration** du produit, **pas** sous
la surface d'inférence publique.

*Raison* : la convention de nommage 10b est explicite — « la surface publique suit le contrat de
l'industrie, **jamais étendu** ; le custom vit sous la surface d'administration ». Or le contrat
public réel des lots impose un téléversement de fichier préalable, un format ligne à ligne, une
fenêtre d'exécution et une sortie par identifiants de fichier — soit une surface de gestion de
fichiers qu'aucune spec ne prévoit et que l'Art. 20 interdit d'ajouter sans jalon l'exigeant.
Implémenter à moitié le contrat public serait pire que ne pas le prétendre : le SDK standard
échouerait de façon inattendue, ce qui contredirait la promesse du critère A1 de S04.

*Conséquence immédiate — à M1* : le contrat public figé par S04 (tâche T9) **ne déclare pas** de
route de lots. La mention de `/v1/batches` en 4d du document est **écartée**, et cet écart est
consigné ici. C'est la décision la plus urgente des six, parce qu'elle porte sur un contrat figé au
jalon M1 alors que son implémentation est à M3.

*Conséquence pour S18* : les exigences de la spec restent valides mot pour mot — elles ne nomment
aucune route. Seule l'adresse d'exposition change, ce qui est un détail de plan.

*Réversibilité* : si la compatibilité publique devient un besoin réel, elle s'ajoutera comme une
spec distincte, avec sa propre gestion de fichiers. C'est l'option (c) de l'analyse initiale,
différée conformément à l'Art. 20.

---

## Sources

- [SGLang — guide et versions](https://inference.net/content/sglang-complete-guide/) ·
  [notes de version NVIDIA](https://docs.nvidia.com/deeplearning/frameworks/sglang-release-notes/index.html)
- [vLLM vs SGLang 2026](https://www.yottalabs.ai/post/vllm-vs-sglang-which-inference-engine-should-you-use-in-2026) ·
  [comparatif production](https://particula.tech/blog/sglang-vs-vllm-inference-engine-comparison)
- [PostgreSQL — politique de versions](https://www.postgresql.org/support/versioning/) ·
  [cycle de vie](https://endoflife.date/postgresql)
- [Redis 8.8](https://redis.io/docs/latest/develop/whats-new/8-8/) ·
  [releases](https://github.com/redis/redis/releases)
- [Grafana 12.3](https://grafana.com/blog/grafana-12-3-release-all-the-latest-features/) ·
  [Prometheus 3.13.0](https://github.com/prometheus/prometheus/releases/tag/v3.13.0)
- [Caddy](https://en.wikipedia.org/wiki/Caddy_(web_server)) ·
  [React 19](https://scrimba.com/articles/react-19-whats-new-for-developers/)
- [Calcul mémoire du cache de contexte](https://lyceum.technology/magazine/kv-cache-memory-calculation-llm/) ·
  [dimensionnement VRAM](https://www.spheron.network/blog/gpu-memory-requirements-llm/) ·
  [quantification du cache — vLLM](https://docs.vllm.ai/en/latest/features/quantization/quantized_kvcache/)
- [Bradley-Terry vs Elo en arène](https://productleadersdayindia.org/blogs/lmarena-leaderboard/bradley-terry-vs-elo-arena-ranking-method.html) ·
  [méthodologie et limites](https://benchmarkingagents.com/chatbot-arena/)
- [Batch API — guide](https://developers.openai.com/api/docs/guides/batch) ·
  [référence de création](https://developers.openai.com/api/reference/resources/batches/methods/create)
- [Passerelles LLM auto-hébergées 2026](https://contabo.com/blog/best-llm-gateways/)
