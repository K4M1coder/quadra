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

**Conséquence pratique** : un fichier unique porte la correspondance composant → digest, de sorte que
la montée de version soit un changement localisé et revuable (Art. 19).

**Alternatives considérées** :

- *Tags de version sémantique* — insuffisant (mutable), retenu seulement comme **commentaire** à côté
  du digest, pour la lisibilité humaine.
- *Construction locale des images* — écarté : contredirait l'Art. 6 (consommer l'amont tel quel) et
  déplacerait la charge de maintenance sur le projet.

---

## D-S01-3 — Un seul port publié, réseau interne isolé

**Décision** : seul le reverse proxy publie un port sur l'hôte. Tous les autres services communiquent
sur un réseau interne à la composition, **sans publication**.

**Rationale** : critère A2. Les moteurs d'inférence **n'exposent ni authentification ni TLS** — c'est
une propriété de l'amont, pas un défaut à corriger (Art. 6). La seule protection correcte est donc
l'isolation réseau. Publier un port de moteur, même « seulement en local », exposerait une inférence
non authentifiée.

**Vérification** : automatisable — un balayage des ports de l'hôte ne doit trouver que le port TLS
(T10).

---

## D-S01-4 — Validation de configuration au démarrage, partagée avec S04

**Décision** : la validation du fichier d'environnement est **du code du plan de contrôle**, invoqué
au démarrage, et non un script de déploiement séparé.

**Rationale** : l'Art. 19. S04 devra de toute façon valider sa configuration à l'exécution ; écrire
un validateur en script pour S01 puis un second en Python pour S04 créerait deux vérités sur les
mêmes variables. Le coût d'anticipation est nul — c'est le même besoin, pas une abstraction
spéculative (donc pas une violation de l'Art. 20).

**Comportement exigé** : échec en moins de 10 secondes, message nommant **la variable fautive et la
correction attendue**, et **aucun service laissé démarré** (SC-006).

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

## D-S01-6 — Volume d'offload provisionné mais non monté

**Décision** : le volume dédié au débordement mémoire est **créé** par S01 et **monté par aucun
moteur**.

**Rationale** : le document le prévoit dans le déploiement de référence, mais l'Art. 3 impose que
l'offload soit opt-in par job (S18) et l'Art. 20 interdit d'implémenter le mécanisme avant le jalon
qui l'exige. Provisionner le stockage est une décision d'infrastructure ; l'activer est une décision
produit. Les deux sont séparées.

---

## Points laissés ouverts — arbitrage mainteneur

Repris de la veille transverse, rappelés ici car ils **bloquent la rédaction de la définition de
déploiement** :

| Réf | Question | Effet si non tranché |
| --- | --- | --- |
| **D1** | Épingler l'amont actuel (Postgres 18.4, Redis 8.8+, Grafana 13, Prometheus 3.13 LTS) ou les versions du document (16, 7, 11, 2) ? | La composition ne peut pas être écrite : ce sont les digests qu'elle contient. |
| **D2** | Confirmer le maintien du pilote GPU / CUDA épinglés (**recommandé**) ? | Risque de convertir le risque connu de la phase 1 en panne inexpliquée. |

Aucun autre `NEEDS CLARIFICATION` ne subsiste : la spec S01 n'en comportait aucun, et les six
décisions ci-dessus sont tranchées.
