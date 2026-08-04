# Phase 1 — Contrat : definition of done mécanique (S03)

**Consommateurs** : **toutes** les specs du projet. C'est le contrat qui rend la delegation aux
agents possible — l'Art. 8 en fait la condition pour « ne relire à la main que auth, facturation et
proxy streaming ».

---

## Contrat 1 — Les cinq portes, dans l'ordre

L'ordre est **normatif** : chaque porte suppose la précédente franchie.

| Rang | Porte | Contenu | Où |
| --- | --- | --- | --- |
| 1 | **pre-commit** | style, format, **scan de secrets** | locale + distante |
| 2 | **types & tests** | typage strict · pyramide · **seuils de couverture** | locale + distante |
| 3 | **sécurité** | analyse statique · audits de dépendances | locale + distante |
| 4 | **build** | images étiquetées **version + empreinte** | distante |
| 5 | **e2e + charge** | environnement éphémère + moteur factice | distante |

*(La 5ᵉ porte de l'Art. 8, le **canari GPU**, est hors chaîne : elle relève de l'exploitation.)*

**Règle absolue** : **rien ne fusionne tant qu'une porte est rouge** (FR-014). Il n'existe pas de
contournement, pas de « on corrigera après ». Désactiver une porte pour faire passer un changement
est qualifié de **faute** par l'Art. 14, pas de mitigation.

---

## Contrat 2 — Parité locale ↔ distante

| Engagement | Vérification |
| --- | --- |
| Les portes de rang 1 à 3 s'exécutent **à l'identique** en local et à distance | test de parité automatisé |
| Un état **vert en local prédit** un état vert à distance | Art. 14 |
| Les portes 4 et 5 n'existent qu'à distance | par nature (images, environnement éphémère) |

**Mécanisme** : une **source unique** déclare les portes ; les deux configurations la consomment ; un
test compare les listes **résolues** et échoue si elles divergent (SC-005).

**Sans ce test, la parité se dégrade silencieusement** — le symptôme est une chaîne distante qui
échoue après un local vert, qu'on attribue d'abord à autre chose.

---

## Contrat 3 — Seuils de couverture

| Périmètre | Seuil | Statut |
| --- | --- | --- |
| **Cœur** — authentification, quotas, comptabilité | **≥ 90 %** | bloquant |
| Hors cœur | **≥ 70 %** | bloquant |

- **Mesurés par l'outillage**, avec sortie capturée. Un chiffre annoncé n'est pas une couverture.
- **Fixés par la constitution** — non négociables spec par spec.
- **Nécessaires, non suffisants** : le seuil ne prouve pas que les tests assertent. Le cycle
  rouge → vert reste dû pour tout comportement (Art. 10). C'est une limite assumée de
  l'automatisation, énoncée dans la documentation de contribution.

---

## Contrat 4 — Definition of done d'une tâche

Une tâche est terminée quand, **et seulement quand** :

1. style et typage **propres** ;
2. tests **écrits et verts** ;
3. couverture **au seuil** de son périmètre ;
4. contrat d'interface **inchangé ou versionné**.

**Propriété recherchée** : ces quatre points sont **mécaniquement vérifiables**. C'est ce qui permet
de confier une tâche à un agent et de ne pas relire chaque ligne — le critère remplace le jugement.

---

## Contrat 5 — Aucun accès GPU dans la chaîne

| Règle | Conséquence |
| --- | --- |
| La chaîne d'intégration **ne touche jamais un GPU** | contrainte d'architecture, pas limitation temporaire |
| Les vrais moteurs ne sont exercés **qu'au canari** | l'intégration continue reste rapide et reproductible |

**Trois exigences du projet échappent donc à la chaîne** et doivent être prouvées au canari — à dire
explicitement dans les plans concernés plutôt que de les croire couvertes :

| Exigence | Spec |
| --- | --- |
| Découverte de topologie matérielle | **S06** (SC-001) |
| Calibration du verdict de tenue mémoire (20 modèles mesurés) | **S09** (SC-001) |
| Débit additionné sur deux machines | **S20** (SC-001) |

---

## Contrat 6 — Les trois chemins à revue humaine

En **plus** des portes mécaniques, trois chemins exigent une relecture humaine ligne à ligne
(Art. 8) :

| Chemin | Spec qui le déclenche |
| --- | --- |
| **Authentification** | **S04** (T3–T5) · **S12** (flux de session) |
| **Facturation** | **S08** (calcul de coût) |
| **Proxy de flux** | **S04** (T10–T11) |

**S03 rend cette exigence visible dans le processus** ; ce sont les specs concernées qui la
déclenchent. S03 ne décide pas quel changement traverse ces chemins.

---

## Contrat 7 — Configuration versionnée

| Règle | Raison |
| --- | --- |
| **Toute** la configuration de portes est dans le dépôt | désactiver une porte devient un **diff visible en revue** |
| Aucune porte configurée hors du dépôt | sinon la désactivation est invisible |

C'est ce qui rend applicable l'Art. 16 : une porte rouge arrête le fil, et maquiller un échec se voit.
