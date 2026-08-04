# Phase 1 — Contrat : surface réseau publiée par S01

**Portée du contrat.** S01 ne définit **aucun contrat applicatif** : ni schéma d'API, ni format de
message, ni modèle de données. Le contrat d'inférence est figé par **S04** (réf. `9i` T9 — « contrat
OpenAPI `/v1` figé (humain) »), et c'est lui qui génère le client d'interface (Art. 19).

Ce que S01 contracte est la **surface réseau** : ce qui est joignable, depuis où, et où cela mène.
C'est ce que vérifie le critère A2.

---

## Contrat 1 — Exposition sur l'hôte

| Élément | Valeur contractuelle |
| --- | --- |
| Ports publiés sur l'hôte par la pile | **exactement un** : 443, celui de `caddy` |
| Ports de moteurs | **aucun** — joignables uniquement depuis `quadra-net` |
| Ports de base relationnelle, de cache | **aucun** |
| Ports de collecte, de routage d'alertes, de visualisation | **aucun** |

**Vérification** : un balayage des ports de l'hôte, depuis l'extérieur, ne trouve **parmi les ports des
services de la pile** que 443. Toute autre découverte est un **échec du critère A2**. Le périmètre du
contrat est celui de la pile : le statut de SSH, service de l'hôte que `5b` § Sécurité place à côté de
`:443`, est un arbitrage ouvert de `spec.md` et n'entre pas dans ce contrat.

**Justification** : les moteurs d'inférence n'exposent ni authentification ni TLS (propriété de
l'amont, Art. 6). L'isolation réseau est la seule protection correcte.

---

## Contrat 2 — Routes acheminées par le point d'entrée TLS

Le reverse proxy achemine quatre familles de chemins. **S01 garantit l'acheminement ; il ne garantit
pas le comportement du service de destination**, qui appartient à la spec correspondante.

| Chemin (`10b`) | Famille | Destination interne | Contrat de contenu défini par |
| --- | --- | --- | --- |
| `/v1` | inférence | plan de contrôle | **S04** — contrat public de l'industrie, jamais étendu |
| `/api` | administration | plan de contrôle | **S04** et suivantes — surface propre au produit |
| `/ws` | temps réel | plan de contrôle | **S05** (files), **S11** (abonnements par entité) |
| `/grafana` | tableaux de bord | visualisation | **S02** |

**Garanties de S01** :

- certificat TLS **obtenu et renouvelé automatiquement** ;
- chaque famille de chemins atteint le service attendu ;
- une requête vers une route non déclarée n'atteint **aucun** service interne.

**Non-garanties de S01** : les codes de retour, les schémas de corps, l'authentification. Une route
peut être acheminée et répondre « non implémenté » tant que la spec qui la porte n'est pas livrée —
c'est le comportement attendu au jalon M0.

---

## Contrat 3 — Flux réseau sortants autorisés

L'Art. 1 protège un périmètre : **l'infrastructure**. Le contrat distingue donc ce qui **en sort** de ce
qui **y circule** — la confusion des deux élargirait l'article au lieu de l'appliquer.

### Sortie hors de l'infrastructure — une seule, et rien d'autre

| Flux | Autorisé | Contrainte |
| --- | --- | --- |
| Téléchargement de modèles depuis le dépôt public | ✅ | plafonné en débit (S10) |
| **Tout autre flux sortant hors de l'infrastructure** | ❌ | **interdit — Art. 1, aucune télémétrie, jamais** |

### Flux internes à l'infrastructure

Ils sortent du réseau `quadra-net`, pas du périmètre que l'Art. 1 protège.

| Flux | Autorisé | Contrainte |
| --- | --- | --- |
| Notifications d'alerte vers destinataires internes | ✅ | S02 |
| Copie de sauvegarde vers le NAS du réseau local | ✅ | destination **dans l'infrastructure** (`5b` place le NAS à côté de `node-01`) — **jamais hors site, jamais un service en nuage** ; `prompts` et réponses **exclus du dump** ; `/data/models` **exclu** (re-téléchargeable, `checksum` en base) ; contenu **pseudonyme** ; **chiffrement au repos** sur la destination. Planification, vérification et restauration relèvent de **S21** ; S01 se borne à ne pas l'empêcher. |

**Vérification** : observation des connexions sortantes en fonctionnement nominal. Toute destination
hors de l'infrastructure autre que le dépôt public de modèles est une **violation de l'Art. 1**.

---

## Contrat 4 — Cycle de vie de la pile

| Opération | Garantie | Critère de succès |
| --- | --- | --- |
| Démarrage | pile saine en **< 5 min** sur machine vierge, toutes sondes vertes | SC-001 |
| Configuration invalide | démarrage **interrompu**, variable fautive **et correction attendue** nommées, **aucun service démarré** — la pile ne démarre jamais à moitié configurée. Aucun délai n'est contracté : aucune source n'en fixe un. | SC-006 |
| Redémarrage machine | pile relancée **sans intervention** | SC-005 |
| Arrêt / redémarrage | données des volumes nommés **intactes à 100 %** | SC-007 |
| Retour arrière | re-pointer le digest **précédemment épinglé** dans le fichier de digests, puis redémarrer — **une seule commande**, aucune reconstruction d'image, **aucun autre fichier modifié** | SC-010 |

Démarrage, redémarrage machine et persistance relèvent du critère **A1** et sont prouvés par la preuve
machine vierge (réf. `9f` T10). La validation de configuration relève de la surface **J3** (réf. `9f`
T7). Le **retour arrière** (réf. `w10`) n'est couvert par **aucune tâche de la fiche `9f`** : sa preuve
`[TEST]` est à créer dans `tasks.md`, écart documentaire consigné (Art. 7).
