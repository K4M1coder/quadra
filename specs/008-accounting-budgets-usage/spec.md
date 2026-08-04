# Feature Specification: S08 — Accounting + budgets + usage

**Feature Branch**: `008-accounting-budgets-usage`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9m du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S08 du plan de specs 9c : « Accounting + budgets + usage », références 8f · W5 · 5c (requests), dépend de S04, effort ≈ 7.5 j-agent, phase 3 (produit modèles), jalon produit M2 (V1 équipe). **Revue humaine obligatoire** sur le calcul de coût (Art. 8 — chemin « facturation »).

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J3 de la fiche 9m. Cette spec est le **registre
économique** de la plateforme : elle transforme chaque requête servie en une ligne d'usage
attribuable et facturable, et rend les budgets opérants.

### User Story 1 - Fondations : chaque requête laisse une ligne, chaque modèle a un tarif (Priority: P1)

L'administrateur dispose d'un registre où chaque requête servie apparaît comme une ligne unique —
avec ses jetons consommés, sa durée et son issue — et d'une table de tarifs par modèle servi.

**Why this priority**: c'est la profondeur J1. Sans registre ni tarif, il n'y a ni coût, ni budget,
ni consommation à restituer. C'est aussi la fondation de S14 (traces), qui enrichit les mêmes lignes.

**Independent Test**: servir un lot de requêtes, puis vérifier que le registre contient exactement
une ligne par requête, avec les jetons d'entrée, les jetons de sortie, la durée, le modèle, la lane
et le code de retour — sans qu'aucun coût soit encore calculé.

**Acceptance Scenarios**:

1. **Given** des requêtes servies, **When** chacune se termine, **Then** le registre contient
   **exactement une ligne par requête**, portant la clé, le modèle, la lane, les jetons d'entrée et
   de sortie, la durée et le code de retour.
2. **Given** un modèle servi, **When** l'administrateur consulte les tarifs, **Then** un tarif lui est
   associé, exprimé par million de jetons, **distinctement en entrée et en sortie**.
3. **Given** l'écriture d'une ligne d'usage, **When** elle a lieu, **Then** elle se produit **hors du
   chemin critique** de la requête : la latence perçue par le client n'en dépend pas.
4. **Given** un registre couvrant plusieurs mois, **When** on l'interroge, **Then** son organisation
   permet de détacher les périodes anciennes sans réécrire les données courantes.
5. **Given** la politique de conservation, **When** on l'applique, **Then** les lignes d'usage sont
   conservées **24 mois**.

---

### User Story 2 - Cœur : le coût est exact et les budgets agissent (Priority: P2)

L'administrateur constate que le coût de chaque requête est calculé exactement à partir du tarif du
modèle, que la consommation remonte de la clé vers la team puis l'organisation, et que les budgets
déclenchent avertissement puis blocage aux seuils convenus.

**Why this priority**: c'est la profondeur J2 et le cœur de la spec — elle porte les critères A1 et
A2. C'est aussi le **chemin à revue humaine** : une erreur de calcul de coût est une erreur de
facturation interne, silencieuse et cumulative.

**Independent Test**: soumettre un jeu de requêtes de volumes connus, comparer le coût calculé à un
résultat de référence établi indépendamment, puis faire franchir à un budget les trois seuils et
vérifier l'effet obtenu à chacun.

**Acceptance Scenarios**:

1. **Given** une requête de volume connu et un tarif connu, **When** le coût est calculé, **Then**
   il est **exact** — identique au centime près à un résultat de référence calculé indépendamment.
2. **Given** un coût comportant des arrondis, **When** on agrège de nombreuses requêtes, **Then** la
   somme des coûts reste exacte : la règle d'arrondi est définie et ne dérive pas par accumulation.
3. **Given** une consommation attribuée à une clé, **When** on consulte la consommation de sa team
   puis de son organisation, **Then** elle y **remonte** par agrégation — l'attribution suit la
   hiérarchie clé → team → organisation.
4. **Given** un budget dont la consommation atteint **80 %**, **When** le seuil est franchi,
   **Then** une **notification par courriel** est envoyée.
5. **Given** un budget dont la consommation atteint **90 %**, **When** le seuil est franchi,
   **Then** une **alerte** est levée et une bannière est présentée aux utilisateurs concernés.
6. **Given** un budget dont la consommation atteint **100 %**, **When** une nouvelle requête arrive,
   **Then** elle est **refusée** avec le code canonique de dépassement de budget.
7. **Given** des budgets définis à plusieurs niveaux, **When** ils s'appliquent, **Then** **le
   plafond le plus bas l'emporte**.
8. **Given** une requête **en vol** au moment où le budget est atteint, **When** le seuil est
   franchi, **Then** elle **n'est pas interrompue** — le blocage n'est jamais rétroactif.
9. **Given** une clé dont le budget est épuisé, **When** son état est évalué, **Then** elle passe à
   **suspendue**, conformément à la machine à états normative, et redevient active si le budget est
   relevé ou renouvelé.

---

### User Story 3 - Surface : je consulte et j'exporte la consommation (Priority: P3)

Un responsable d'équipe consulte la consommation de sa team — par clé, par modèle, par période — et
en exporte le détail dans un fichier tabulaire pour son propre suivi.

**Why this priority**: c'est la profondeur J3. Elle rend la comptabilité utile aux utilisateurs plutôt
qu'aux seuls administrateurs, et porte le critère A3.

**Independent Test**: consulter la consommation agrégée d'une team, puis exporter la même période et
comparer ligne à ligne le fichier exporté aux données du registre.

**Acceptance Scenarios**:

1. **Given** de la consommation enregistrée, **When** un responsable consulte la vue de
   consommation, **Then** il voit les dépenses ventilées **par clé, par team et par modèle**, sur la
   période choisie.
2. **Given** la vue de consommation, **When** elle s'affiche, **Then** elle présente l'évolution dans
   le temps sous forme graphique en plus des totaux.
3. **Given** une période sélectionnée, **When** l'utilisateur exporte, **Then** il obtient un fichier
   tabulaire dont le contenu est **identique** aux données du registre — aucune valeur recalculée ni
   arrondie différemment.
4. **Given** un export portant sur un volume important, **When** il est produit, **Then** il est
   **transmis au fil de l'eau** sans exiger de charger l'intégralité en mémoire.
5. **Given** un utilisateur, **When** il consulte la consommation, **Then** il ne voit que le
   périmètre auquel ses droits lui donnent accès.

---

### Edge Cases

- **Une requête échoue ou est annulée en cours de génération** : les jetons réellement consommés sont
  comptabilisés ; la règle appliquée est explicite et testée, pour éviter qu'une annulation devienne
  un moyen d'échapper au comptage.
- **Le tarif d'un modèle change en cours de mois** : les requêtes déjà enregistrées conservent le
  coût calculé au moment du service — aucun recalcul rétroactif.
- **Un modèle est servi sans tarif défini** : la situation est signalée explicitement plutôt que
  comptabilisée à zéro, ce qui masquerait une consommation réelle.
- **L'écriture d'une ligne d'usage échoue** : la perte est détectée et signalée — une requête servie
  mais non comptabilisée est une perte de recette et une atteinte à l'Art. 4 (tout est tracé).
- **Deux requêtes se terminent simultanément près d'un seuil de budget** : le franchissement est
  détecté une seule fois ; les notifications ne sont pas dupliquées.
- **La consommation dépasse largement 100 %** (rafale terminée avant la prise en compte) : le
  dépassement est enregistré tel quel et visible — il n'est ni tronqué ni masqué.
- **Un export est demandé pendant que de nouvelles requêtes arrivent** : l'export porte sur une
  période close et reste cohérent avec elle.
- **Une partition ancienne est détachée** : les exports portant sur cette période l'indiquent
  clairement plutôt que de retourner un résultat vide silencieux.

## Requirements *(mandatory)*

### Functional Requirements

#### Registre d'usage et tarifs (J1)

- **FR-001**: Le système DOIT enregistrer **une ligne d'usage par requête servie**, portant la clé,
  le modèle, la lane, les jetons d'entrée, les jetons de sortie, la durée et le code de retour.
- **FR-002**: L'enregistrement DOIT se faire **hors du chemin critique** de la requête : la latence
  perçue par le client NE DOIT pas en dépendre.
- **FR-003**: Le système DOIT détecter et signaler l'échec d'un enregistrement — une requête servie
  mais non comptabilisée NE DOIT pas passer inaperçue (Art. 4).
- **FR-004**: Le registre DOIT être organisé par période mensuelle, de sorte qu'une période ancienne
  puisse être détachée sans réécrire les données courantes.
- **FR-005**: Les lignes d'usage DOIVENT être conservées **24 mois**.
- **FR-006**: Le système DOIT maintenir un **tarif par modèle servi**, exprimé par million de jetons,
  **distinctement en entrée et en sortie**, administrable.

#### Calcul de coût (J2 — chemin à revue humaine)

- **FR-007**: Le système DOIT calculer le coût de chaque requête à partir du tarif du modèle et des
  jetons réellement consommés, **exactement** — au centime près.
- **FR-008**: La règle d'arrondi DOIT être définie explicitement et NE DOIT pas produire de dérive
  par accumulation sur un grand nombre de requêtes.
- **FR-009**: Le calcul de coût DOIT être une fonction **pure et testable isolément**, indépendante
  de l'état du système.
- **FR-010**: Un changement de tarif NE DOIT **jamais** entraîner de recalcul rétroactif des
  requêtes déjà enregistrées.
- **FR-011**: Un modèle servi sans tarif défini DOIT produire un **signalement explicite**, jamais un
  coût nul silencieux.
- **FR-012**: Les jetons réellement consommés par une requête **échouée ou annulée** DOIVENT être
  comptabilisés selon une règle explicite et testée.

#### Budgets (J2)

- **FR-013**: Le système DOIT agréger la consommation selon la hiérarchie **clé → team →
  organisation**.
- **FR-014**: Le système DOIT déclencher une **notification par courriel** au franchissement de
  **80 %** d'un budget.
- **FR-015**: Le système DOIT lever une **alerte** et présenter une **bannière** au franchissement de
  **90 %**.
- **FR-016**: Le système DOIT **refuser** les nouvelles requêtes au franchissement de **100 %**, avec
  le code canonique de dépassement de budget.
- **FR-017**: Lorsque plusieurs budgets s'appliquent, **le plafond le plus bas DOIT l'emporter**.
- **FR-018**: Le blocage NE DOIT **jamais** être rétroactif : une requête en vol n'est pas
  interrompue par le franchissement d'un seuil.
- **FR-019**: Le franchissement d'un seuil NE DOIT déclencher sa notification **qu'une seule fois**,
  y compris lorsque plusieurs requêtes se terminent simultanément.
- **FR-020**: Une clé dont le budget est épuisé DOIT passer à l'état **suspendue** conformément à la
  machine à états normative, et redevenir active si le budget est relevé ou renouvelé.
- **FR-021**: Un dépassement au-delà de 100 % DOIT être enregistré et **visible** tel quel, sans
  troncature.

#### Consultation et export (J3)

- **FR-022**: Le système DOIT présenter la consommation ventilée **par clé, par team et par modèle**,
  sur une période choisie.
- **FR-023**: La vue de consommation DOIT présenter l'évolution temporelle sous forme graphique en
  plus des totaux.
- **FR-024**: Le système DOIT permettre d'**exporter** la consommation dans un format tabulaire dont
  le contenu est **identique** aux données du registre — aucune valeur recalculée.
- **FR-025**: L'export DOIT être transmis **au fil de l'eau**, sans charger l'intégralité du jeu de
  données en mémoire.
- **FR-026**: Un utilisateur NE DOIT voir que le périmètre de consommation auquel ses droits lui
  donnent accès.

#### Observabilité (transverse)

- **FR-027**: Le système DOIT exposer, comme métriques du projet, le **total de jetons** ventilé par
  clé, modèle et sens, et le **taux de consommation de budget** par team.

#### Preuves (J4)

- **FR-028**: L'exactitude du calcul de coût DOIT être prouvée par des **fichiers de référence**
  comparés au centime.
- **FR-029**: L'égalité entre l'export et le registre DOIT être prouvée par comparaison automatisée.

### Hors périmètre *(Art. 20 — YAGNI)*

- L'**application** des limites de débit, du cap de concurrence et le refus au moment de la requête →
  **S04**. S08 **calcule et alimente** les budgets ; S04 les **applique** sur le chemin de la requête.
- Les **traces détaillées** par étape et la conservation du contenu des prompts → **S14**, qui
  enrichit les mêmes lignes d'usage.
- Le **contrôle d'accès** déterminant qui voit quelle consommation → **S13**. S08 respecte le
  périmètre ; S13 le définit.
- La **coquille d'interface** et le client généré → **S11**.
- Les **règles d'alerte** configurables et leurs actions automatiques → **S15**. S08 émet le
  franchissement de seuil ; S15 permet d'en dériver des règles.
- La **facturation externe** (émission de factures, paiement) : hors périmètre du produit — il s'agit
  d'une **refacturation interne**.
- Le **détail des jobs par lot** et leur coût spécifique → **S18**, qui produit des requêtes
  comptabilisées par S08 comme les autres.

### Key Entities

- **Ligne d'usage** : une requête servie = une ligne. Attributs : clé, modèle, lane, jetons d'entrée,
  jetons de sortie, durée, code de retour, coût. Organisée par période mensuelle, conservée 24 mois.
- **Tarif** : prix par million de jetons associé à un modèle servi, distinct en entrée et en sortie.
- **Budget** : plafond de dépense exprimé en monnaie, attaché à une clé, une team ou une
  organisation, avec ses seuils de 80 %, 90 % et 100 %. *Terme normatif — « limite » (ambigu) et
  « cap » (réservé à la concurrence) sont des synonymes interdits (Art. 12).*
- **Export** : restitution tabulaire d'une période, **égale au registre** par construction.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Le coût calculé d'une requête est **exact au centime** :
  il coïncide à **±0** avec un résultat de référence établi indépendamment, sur l'intégralité du jeu
  de cas de référence.
- **SC-002** *(critère A2)*: Le franchissement de **80 %** produit une notification, celui de
  **90 %** une alerte avec bannière, celui de **100 %** un refus — **100 %** des cas, et **une seule
  fois** par franchissement.
- **SC-003** *(critère A3)*: L'export d'une période est **identique** aux données du registre pour
  cette période : une comparaison automatisée ligne à ligne ne trouve **aucun** écart.
- **SC-004**: La somme des coûts de **10 000** requêtes agrégées est exacte : l'écart avec la somme
  de référence est **nul** — aucune dérive d'arrondi.
- **SC-005**: L'ajout de la comptabilisation n'augmente pas la latence perçue par le client : la
  latence mesurée avec et sans enregistrement est **statistiquement indiscernable**.
- **SC-006**: **Zéro** requête servie sans ligne d'usage correspondante ; tout échec
  d'enregistrement est détecté et signalé.
- **SC-007**: Un changement de tarif ne modifie **aucune** ligne déjà enregistrée.
- **SC-008**: Une requête en vol n'est **jamais** interrompue par le franchissement d'un budget.
- **SC-009**: La consommation d'une clé se retrouve **intégralement** dans les totaux de sa team puis
  de son organisation — l'agrégation ne perd ni ne double aucune ligne.
- **SC-010**: Un export portant sur une période de **plusieurs millions de lignes** aboutit sans
  saturation de mémoire.
- **SC-011**: La couverture de test du module de comptabilité est **≥ 90 %** (Art. 10 — périmètre
  cœur).

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9m) |
| --- | --- | --- |
| A1 — coût exact (±0) | SC-001, SC-004, SC-007 | T11 `[TEST]` fichiers de référence de facturation — **revue humaine** |
| A2 — seuils 80 / 90 / 100 % | SC-002, SC-008 | T12 `[TEST]` seuils |
| A3 — export = données du registre | SC-003, SC-010 | T12 `[TEST]` export = registre |
| Enregistrement hors chemin critique | SC-005, SC-006 | T3 métrage hors chemin critique · T10 `[INT]` passerelle → métrage (S04) |
| Agrégation hiérarchique | SC-009 | T5 taux de consommation + héritage |
| Couverture du cœur | SC-011 | Portes de couverture de S03 |

**Revue humaine obligatoire** (Art. 8) : le **calcul de coût** (T4) est relu ligne à ligne par un
humain, en plus des portes mécaniques et des fichiers de référence.

## Assumptions

- **Dépendance à S04** : la passerelle fournit, à la fin de chaque requête, les éléments à
  comptabiliser (clé, modèle, lane, jetons, durée, code). S08 ne se place pas sur le chemin de la
  requête : il consomme un événement de fin.
- **Répartition des rôles sur les budgets** : **S08 calcule** le taux de consommation et déclenche les
  seuils ; **S04 refuse** la requête au moment où elle se présente. Cette séparation évite de placer
  une agrégation sur le chemin critique.
- **Refacturation interne, pas facturation externe** : le produit ne vise pas l'émission de factures
  ni l'encaissement. La monnaie sert à répartir un coût réel entre équipes.
- **Tarifs administrés, pas déduits** : les tarifs sont saisis et versionnés ; ils ne sont pas
  calculés à partir de la consommation électrique ou d'un coût matériel amorti.
- **Conservation** : 24 mois pour les lignes d'usage, avec détachement des périodes anciennes
  (valeur fixée par le document, 5c). Les autres conservations du projet appartiennent à leurs specs.
- **Exactitude « ±0 » signifie au centime** : le critère A1 est interprété comme une égalité exacte
  avec un résultat de référence exprimé dans la plus petite unité monétaire, et non comme une
  tolérance relative. C'est ce que rend vérifiable la preuve par fichiers de référence.
- **Le seuil de 100 % suspend la clé, il ne la révoque pas** : conformément à la machine à états
  normative, la suspension est réversible ; la révocation reste une décision administrateur.
- **Profondeur du jalon M2** : la spec est **complète à M2**. La vue de consommation appartient à
  cette profondeur et se pose dans la coquille d'interface de S11, disponible au même jalon.
