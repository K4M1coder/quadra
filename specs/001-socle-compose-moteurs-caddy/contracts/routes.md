# Phase 1 — Contrat : surface réseau publiée par S01

**Portée du contrat.** S01 ne définit **aucun contrat applicatif** : ni schéma d'API, ni format de
message, ni modèle de données. Le contrat d'inférence est figé par **S04** (tâche T9, par un humain),
et c'est lui qui génère le client d'interface (Art. 19).

Ce que S01 contracte est la **surface réseau** : ce qui est joignable, depuis où, et où cela mène.
C'est ce que vérifie le critère A2.

---

## Contrat 1 — Exposition sur l'hôte

| Élément | Valeur contractuelle |
| --- | --- |
| Ports publiés sur l'hôte | **exactement un** : le port TLS (443) |
| Ports de moteurs | **aucun** |
| Ports de base relationnelle, de cache | **aucun** |
| Ports de collecte, de routage d'alertes, de visualisation | **aucun** |

**Vérification** : un balayage des ports de l'hôte, depuis l'extérieur, ne trouve que 443.
Toute autre découverte est un **échec du critère A2**.

**Justification** : les moteurs d'inférence n'exposent ni authentification ni TLS (propriété de
l'amont, Art. 6). L'isolation réseau est la seule protection correcte.

---

## Contrat 2 — Routes acheminées par le point d'entrée TLS

Le reverse proxy achemine quatre familles de chemins. **S01 garantit l'acheminement ; il ne garantit
pas le comportement du service de destination**, qui appartient à la spec correspondante.

| Famille | Destination interne | Contrat de contenu défini par |
| --- | --- | --- |
| Inférence | plan de contrôle | **S04** — contrat public de l'industrie, jamais étendu |
| Administration | plan de contrôle | **S04** et suivantes — surface propre au produit |
| Temps réel | plan de contrôle | **S05** (files), **S11** (abonnements par entité) |
| Tableaux de bord | visualisation | **S02** |

**Garanties de S01** :

- certificat TLS **obtenu et renouvelé automatiquement** ;
- chaque famille de chemins atteint le service attendu ;
- une requête vers une route non déclarée n'atteint **aucun** service interne.

**Non-garanties de S01** : les codes de retour, les schémas de corps, l'authentification. Une route
peut être acheminée et répondre « non implémenté » tant que la spec qui la porte n'est pas livrée —
c'est le comportement attendu au jalon M0.

---

## Contrat 3 — Flux réseau sortants autorisés

| Flux | Autorisé | Contrainte |
| --- | --- | --- |
| Téléchargement de modèles depuis le dépôt public | ✅ | plafonné en débit (S10) |
| Copie de sauvegarde hors machine | ✅ | S21 |
| Notifications d'alerte vers destinataires internes | ✅ | S02 |
| **Tout autre flux sortant** | ❌ | **interdit — Art. 1, aucune télémétrie** |

**Vérification** : observation des connexions sortantes en fonctionnement nominal. Toute
destination hors de cette liste est une **violation de l'Art. 1**.

---

## Contrat 4 — Cycle de vie de la pile

| Opération | Garantie |
| --- | --- |
| Démarrage | pile saine en **< 5 min** sur machine vierge, toutes sondes vertes |
| Configuration invalide | échec en **< 10 s**, variable fautive nommée, **aucun service démarré** |
| Redémarrage machine | pile relancée **sans intervention** |
| Arrêt / redémarrage | données des volumes nommés **intactes à 100 %** |
| Retour arrière | changement de digest + redémarrage — **une commande** |

Ces garanties sont celles des critères A1 et A3 de la spec, et sont prouvées par la tâche T10.
