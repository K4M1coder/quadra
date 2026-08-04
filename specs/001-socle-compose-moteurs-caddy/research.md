# Phase 0 — Recherche : S01 Socle compose + moteurs + Caddy

Veille transverse (versions amont, moteurs, écarts) : [`specs/RESEARCH-STACK.md`](../RESEARCH-STACK.md).
Ce document ne traite que les décisions **propres à S01**.

---

## D-S01-1 — Composition de conteneurs plutôt qu'orchestrateur

**Décision** : décrire l'ensemble des services dans une **composition de conteneurs unique**, sur une
machine unique.

**Rationale** : l'Art. 9 l'impose explicitement (« pas de K8s sous 3 machines »). Le bénéfice n'est
pas idéologique : une composition se lit en entier dans un fichier, démarre d'une commande, et
s'arrête d'une commande — ce qui est la définition opérationnelle de « opérable par un seul ». Un
orchestrateur ajouterait un plan de contrôle à opérer *en plus* de celui qu'on construit.

**Alternatives considérées** :

- *Orchestrateur de cluster* — écarté par l'Art. 9. Le document prévoit de le **réévaluer** au-delà de
  3 machines, pas de l'anticiper (Art. 20).
- *Unités de service système sur l'hôte* — écarté : perd l'isolation réseau qui garantit le critère
  A2 (moteurs invisibles), et rend l'épinglage par digest inapplicable.

---

## D-S01-2 — Épinglage par digest, pas par tag

**Décision** : chaque image est référencée par **digest exact**. Le démarrage échoue si un digest
n'est pas disponible ; aucune substitution n'est tentée.

**Rationale** : c'est le critère A3 et l'Art. 11. Un tag, même d'apparence figée, peut être
repoussé sur un autre contenu — l'épinglage par tag donne l'illusion de la reproductibilité sans la
propriété. Surtout, le digest est **la condition du canari et du retour arrière** : sans lui, « revenir
à la version d'avant » n'a pas de référent.

**Conséquence pratique** : un fichier unique (`deploy/digests.yml`) porte la correspondance
composant → digest, de sorte que la montée de version soit un changement localisé et revuable
(Art. 19). C'est aussi le **seul** fichier que le retour arrière modifie : re-pointer le digest
précédemment épinglé, redémarrer, une commande, aucune reconstruction (FR-021, prouvé par SC-010).
`w10` écrit « re-pointer le tag précédent » ; le référent retenu ici est le **digest**, ce qui est plus
strict et ne change pas la procédure.

**Alternatives considérées** :

- *Tags de version sémantique* — insuffisant (mutable), retenu seulement comme **commentaire** à côté
  du digest, pour la lisibilité humaine.
- *Construction locale des images* — écarté : contredirait l'Art. 6 (consommer l'amont tel quel) et
  déplacerait la charge de maintenance sur le projet.

---

## D-S01-3 — Un seul port publié, réseau interne isolé

**Décision** : seul le reverse proxy `caddy` publie un port sur l'hôte — 443. Tous les autres services
communiquent sur le réseau interne `quadra-net`, **sans publication**.

**Rationale** : critère A2. Les moteurs d'inférence **n'exposent ni authentification ni TLS** — c'est
une propriété de l'amont, pas un défaut à corriger (Art. 6). La seule protection correcte est donc
l'isolation réseau. Publier un port de moteur, même « seulement en local », exposerait une inférence
non authentifiée.

**Vérification** : automatisable — un balayage des ports de l'hôte ne doit trouver, **parmi les ports
des services de la pile**, que 443 (réf. `9f` T10, SC-002). Le statut de SSH, service de l'hôte, reste
un arbitrage ouvert de `spec.md` et ne relève pas de ce critère.

---

## D-S01-4 — Validation de configuration au démarrage, partagée avec S04

**Décision** : la validation du fichier d'environnement est **du code du plan de contrôle**, invoqué
au démarrage, et non un script de déploiement séparé.

**Rationale** : l'Art. 19. S04 devra de toute façon valider sa configuration à l'exécution ; écrire
un validateur en script pour S01 puis un second en Python pour S04 créerait deux vérités sur les
mêmes variables. Le coût d'anticipation est nul — c'est le même besoin, pas une abstraction
spéculative (donc pas une violation de l'Art. 20).

**Comportement exigé** : le démarrage **s'interrompt**, le message nomme **la variable fautive et la
correction attendue**, et **aucun service n'est laissé démarré** (FR-015, SC-006). **Aucun délai
chiffré n'est exigé** : ni la fiche `9f`, ni `10b`, ni la constitution n'en fixent un, et SC-006 est
vérifiable sans. Ne pas en introduire un.

**Alternatives considérées** :

- *Validation par le moteur de composition* — trop pauvre : détecte une variable absente, pas une
  valeur invalide, et ne produit pas de message actionnable.
- *Pas de validation* — écarté : produit exactement le mode de défaillance que la spec interdit, une
  pile à moitié configurée.

---

## D-S01-5 — Répertoires d'observabilité créés vides par S01, peuplés par S02

**Décision** : S01 crée les points de montage de la configuration d'observabilité ; **S02 en fournit
le contenu**.

**Rationale** : évite que deux specs se disputent les mêmes fichiers, et respecte la frontière posée
dans les deux specs (*S01 démarre les conteneurs, S02 les configure*). Sans cette règle, la
définition de déploiement de S01 contiendrait des cibles de collecte, ce qui appartient à S02.

---

## D-S01-6 — `/data/offload` provisionné mais non monté

**Décision** : le volume `/data/offload` est **créé** par S01 et **monté par aucun moteur**.

**Rationale** : `5b` le prévoit dans le déploiement de référence, mais l'Art. 3 impose que l'`offload`
soit opt-in par job (S18) et l'Art. 20 interdit d'implémenter le mécanisme avant le jalon qui l'exige.
Provisionner le stockage est une décision d'infrastructure ; l'activer est une décision produit. Les
deux sont séparées.

**Réserve** : la lettre de l'Art. 20 proscrit toute anticipation, y compris celle-ci. La provision est
donc **consignée comme réserve** au Constitution Check de `plan.md` (ligne Art. 20) et adressée au
mainteneur, plutôt que présentée comme conforme.

---

## D-S01-7 — Fichiers de gouvernance à la racine

**Décision** : `CONSTITUTION.md` et `CHANGELOG.md` vivent **à la racine** du dépôt et sont livrés par
S01, avec l'arborescence et le README (réf. `9f` T1).

**Rationale** : `10b` fixe la racine du dépôt — « `CONSTITUTION.md` · `CHANGELOG.md` (Keep a
Changelog) » — et le § Governance de la constitution confie explicitement la production de
`CONSTITUTION.md` à S01. L'Art. 13 exige le changelog dans le changement même qui livre le
comportement.

**Conséquence Art. 19** : `CONSTITUTION.md` est une **copie de référence**, jamais un original ; sa
source est `.specify/memory/constitution.md`. Les deux copies portent la même version et un
contrôle automatisé échoue à la moindre divergence (FR-019, SC-008). Amender la constitution passe par
l'outil de gouvernance, jamais par la copie.

**Alternative considérée** : *une seule copie, la source uniquement* — écarté : `10b` impose la
racine, et c'est la copie de racine qui est injectée dans le contexte des agents. La duplication est
donc contrainte, ce qui rend le contrôle d'égalité de version obligatoire plutôt qu'optionnel.

---

## Décisions de la veille transverse applicables à S01

Les six décisions D1–D6 de `specs/RESEARCH-STACK.md` §7 ont été **tranchées le 2026-08-01**. Elles ne
sont pas recopiées ici (Art. 19) :

| Réf | Portée | Effet sur S01 |
| --- | --- | --- |
| **D1** | Postgres, Redis, Grafana, Prometheus, Caddy, React | **s'applique** — versions retenues dans `plan.md` |
| **D2** | pilote GPU / CUDA (560 / 12.6) | **s'applique** — conservées, révision au canari seulement |
| **D3** · **D4** | tenue mémoire (S09) | ne couvre pas S01 |
| **D5** | classement de l'arène (S16) | ne couvre pas S01 |
| **D6** | surface des lots (S04, S18) | ne couvre pas S01 |

---

## Points laissés ouverts — arbitrage mainteneur

Ils **bloquent la rédaction de la définition de déploiement** ; `spec.md` § « Arbitrages ouverts » en
est la source.

| Point | Effet si non tranché |
| --- | --- |
| **Version de `dcgm-exporter`** — `5a` n'en épingle aucune et la portée de D1 ne couvre pas ce composant | Son service ne peut pas être écrit : FR-012 exige un digest exact pour **toute** image. Écrire une borne ouverte violerait l'Art. 11 dans le fichier même qui porte le critère A3. |
| **Tag `llama.cpp b4102`** — « à revérifier » (`RESEARCH-STACK.md` §1) | Si le tag n'existe plus, FR-013 devient vrai au premier démarrage et le critère A1 échoue pour une cause documentaire. |

Aucun `NEEDS CLARIFICATION` ne subsiste : la spec S01 n'en comportait aucun, et les sept décisions
ci-dessus sont tranchées.
