# Feature Specification: S21 — Durcissement : réglages, santé, sauvegardes, charge

**Feature Branch**: `021-durcissement-settings-sante-backups`

**Created**: 2026-08-01

**Status**: Draft

**Input**: Fiche 9z du document de référence « Quadra Document Complet.html » — Partie 9 (Réalisation). Spec S21 du plan de specs 9c : « Durcissement : settings, santé, sauvegardes, load-tests k6 », références 8g · 6g · W11 · W12, dépend de **toutes** les specs, effort ≈ 5 j-agent, phase 6 (cluster & durcissement), jalon produit M4 (V2 cluster). **Dernière spec du plan.**

## User Scenarios & Testing *(mandatory)*

Les parcours reprennent les jalons internes J1–J2 de la fiche 9z. Cette spec ferme le projet : elle
rend la plateforme **exploitable dans la durée par une seule personne** (Art. 9) et prouve qu'elle
survit aux incidents.

### User Story 1 - Surface : réglages versionnés et audités, santé agrégée (Priority: P1)

L'administrateur configure l'ensemble de la plateforme depuis un écran unique, et chaque modification
laisse une trace. Il dispose par ailleurs d'une vue de santé qui lui dit, d'un coup d'œil, si tout va
bien : versions déployées, espace disque, état des sauvegardes.

**Why this priority**: c'est la profondeur J1. Un réglage modifié sans trace est un incident
inexplicable trois mois plus tard ; une plateforme sans vue de santé oblige à inspecter chaque
composant à la main, ce qui contredit l'Art. 9.

**Independent Test**: modifier un réglage, retrouver la modification dans le journal d'audit avec son
auteur ; puis ouvrir la vue de santé et y trouver versions, disques et état des sauvegardes.

**Acceptance Scenarios**:

1. **Given** les réglages de la plateforme, **When** l'administrateur les consulte, **Then** il
   accède depuis un point unique aux familles de réglages du produit — tarification, puissance des
   cartes, durées de conservation, fournisseur d'identité, matériel.
2. **Given** un réglage, **When** l'administrateur le modifie, **Then** la modification est
   **versionnée** — la valeur précédente reste connue.
3. **Given** un réglage modifié, **When** on consulte le journal d'audit, **Then** on y trouve la
   modification avec son **auteur**, son **horodatage**, l'ancienne et la nouvelle valeur (Art. 4).
4. **Given** la plateforme, **When** l'administrateur ouvre la vue de santé, **Then** il y voit les
   **versions déployées**, l'**espace disque** de chaque volume, l'**état des sauvegardes** et les
   résultats des diagnostics.
5. **Given** un composant en défaut, **When** la santé est agrégée, **Then** l'état global le
   reflète — il ne peut pas être au vert alors qu'un composant est en échec.
6. **Given** un réglage invalide, **When** l'administrateur tente de l'enregistrer, **Then** il est
   **refusé** avec un motif explicite, sans laisser la plateforme dans un état intermédiaire.

---

### User Story 2 - Résilience : sauvegardes testées, incidents outillés (Priority: P2)

L'administrateur sait que ses données sont sauvegardées **hors de la machine**, et surtout qu'il a
déjà **restauré pour de vrai** — pas seulement copié. Face à un incident, il dispose d'une procédure
écrite plutôt que d'improviser.

**Why this priority**: c'est la profondeur J2 et la promesse la plus forte de la spec. Le document
est catégorique : **« une sauvegarde non testée en restauration n'est pas une sauvegarde »**. C'est
aussi ce qui rend l'Art. 9 tenable — un incident à 2 h du matin se traite avec un runbook, pas avec
de la mémoire.

**Independent Test**: déclencher une sauvegarde, la restaurer sur un environnement vierge par la
procédure documentée, et vérifier que les données critiques sont intégralement retrouvées.

**Acceptance Scenarios**:

1. **Given** la plateforme en fonctionnement, **When** la sauvegarde périodique s'exécute, **Then**
   elle capture les **données critiques** — accès et clés, consommation, votes, journal d'audit — et
   la **configuration**.
2. **Given** une sauvegarde produite, **When** elle est stockée, **Then** une copie est placée **hors
   de la machine**.
3. **Given** les modèles téléchargés, **When** la sauvegarde s'exécute, **Then** ils en sont
   **exclus** — ils sont re-téléchargeables et leurs empreintes d'intégrité sont en base.
4. **Given** une sauvegarde, **When** son cycle se déroule, **Then** il suit la machine à états
   normative : planifiée → en cours → **vérifiée**, ou **échouée** avec alerte.
5. **Given** une sauvegarde, **When** elle est produite, **Then** elle n'est considérée comme valide
   qu'une fois **vérifiée** — une copie non vérifiée n'est pas une sauvegarde.
6. **Given** une sauvegarde vérifiée, **When** l'administrateur suit la **procédure documentée** de
   restauration sur un environnement vierge, **Then** les données critiques sont **intégralement
   retrouvées**.
7. **Given** la restauration, **When** elle est exercée, **Then** elle l'est **périodiquement** — au
   moins une fois par trimestre — et le résultat est consigné.
8. **Given** un incident courant — carte GPU perdue, machine perdue, disque plein — **When**
   l'administrateur le rencontre, **Then** une **procédure écrite** lui indique quoi faire.
9. **Given** les scénarios de charge du projet, **When** ils sont rejoués avant une mise en service,
   **Then** ils montrent qu'une rafale d'agents **n'affame pas** la lane interactive.
10. **Given** les scénarios de charge, **When** on les consulte, **Then** ils sont **versionnés dans
    le dépôt**, rejouables à l'identique.

---

### Edge Cases

- **La sauvegarde échoue silencieusement** : impossible — un échec fait passer la sauvegarde à l'état
  échoué et **déclenche une alerte**. L'absence de sauvegarde récente est elle-même un défaut de
  santé.
- **La destination de sauvegarde est pleine ou injoignable** : la sauvegarde échoue explicitement et
  l'alerte le signale, plutôt que d'écraser une sauvegarde valide.
- **La restauration réussit mais les données sont incomplètes** : c'est pourquoi la vérification
  porte sur le **contenu restauré**, pas sur la réussite de la copie.
- **Un réglage est modifié pendant un incident** : la version précédente reste connue, ce qui permet
  de revenir en arrière et d'expliquer après coup.
- **Deux administrateurs modifient le même réglage simultanément** : la dernière modification
  l'emporte, mais les deux figurent au journal d'audit.
- **Les scénarios de charge sont exécutés sur une plateforme en production** : ils sont destinés à un
  environnement dédié — les exécuter en production dégraderait précisément ce qu'ils prétendent
  mesurer.
- **Une durée de conservation est raccourcie** : l'effet sur les données déjà stockées est indiqué
  **avant** validation — un raccourcissement provoque une purge (Art. 3).
- **La vue de santé est elle-même indisponible** : son indisponibilité doit être distinguable d'un
  état sain.

## Requirements *(mandatory)*

### Functional Requirements

#### Réglages (J1)

- **FR-001**: Le système DOIT offrir un **point d'accès unique** aux familles de réglages du
  produit : tarification, puissance des cartes, durées de conservation, fournisseur d'identité,
  matériel.
- **FR-002**: Toute modification d'un réglage DOIT être **versionnée** : la valeur précédente reste
  connue.
- **FR-003**: Toute modification d'un réglage DOIT produire une **entrée d'audit** portant l'auteur,
  l'horodatage, l'ancienne et la nouvelle valeur (Art. 4).
- **FR-004**: Un réglage invalide DOIT être **refusé** avec un motif explicite, sans laisser la
  plateforme dans un état intermédiaire.
- **FR-005**: Le raccourcissement d'une durée de conservation DOIT indiquer son **effet sur les
  données déjà stockées avant validation** (Art. 3).

#### Santé et diagnostics (J1)

- **FR-006**: Le système DOIT exposer un **état de santé agrégé** couvrant les versions déployées,
  l'espace disque de chaque volume, l'état des sauvegardes et les résultats des diagnostics.
- **FR-007**: L'état agrégé NE DOIT **pas** être au vert lorsqu'un composant est en échec.
- **FR-008**: L'**indisponibilité** de la vue de santé DOIT être distinguable d'un état sain.
- **FR-009**: L'absence de **sauvegarde récente** DOIT constituer un défaut de santé.

#### Sauvegardes (J2)

- **FR-010**: Le système DOIT produire une **sauvegarde périodique** des données critiques — accès et
  clés, consommation, votes, journal d'audit — et de la configuration.
- **FR-011**: Une copie de chaque sauvegarde DOIT être placée **hors de la machine**.
- **FR-012**: Les modèles téléchargés DOIVENT être **exclus** des sauvegardes : ils sont
  re-téléchargeables et leurs empreintes d'intégrité sont conservées en base.
- **FR-013**: Le cycle d'une sauvegarde DOIT suivre la machine à états normative : planifiée → en
  cours → **vérifiée**, ou **échouée avec alerte**.
- **FR-014**: Une sauvegarde NE DOIT être considérée comme valide qu'une fois **vérifiée** ; la
  vérification porte sur le **contenu restauré**, non sur la réussite de la copie.
- **FR-015**: Un échec de sauvegarde DOIT **déclencher une alerte** — il NE DOIT jamais être
  silencieux.
- **FR-016**: Une destination de sauvegarde pleine ou injoignable DOIT faire échouer explicitement
  l'opération, **sans écraser** une sauvegarde valide.

#### Restauration (J2)

- **FR-017**: Le système DOIT fournir une **procédure documentée** de restauration menant d'un
  environnement vierge aux données critiques intégralement retrouvées.
- **FR-018**: La restauration DOIT être **exercée périodiquement** — au moins une fois par
  trimestre — et son résultat **consigné**.
- **FR-019**: L'état des sauvegardes et la date du dernier exercice de restauration DOIVENT être
  visibles dans la vue de santé.

#### Incidents et charge (J2)

- **FR-020**: Le projet DOIT fournir une **procédure écrite** pour les incidents courants : carte GPU
  perdue, machine perdue, disque plein.
- **FR-021**: Les **scénarios de charge** du projet DOIVENT être **versionnés dans le dépôt** et
  rejouables à l'identique.
- **FR-022**: Les scénarios de charge DOIVENT être **rejoués avant chaque mise en service** et
  démontrer qu'une rafale d'agents **n'affame pas** la lane interactive (Art. 2).
- **FR-023**: Les scénarios de charge DOIVENT s'exécuter sur un **environnement dédié**, jamais sur
  la plateforme de production.

#### Preuves (J3)

- **FR-024**: La restauration effective, l'absence de famine sous charge et l'audit systématique des
  réglages DOIVENT être prouvés par des tests dédiés, la restauration étant **scriptée** et rejouable.

### Hors périmètre *(Art. 20 — YAGNI)*

- Les **fonctionnalités** réglées par ces réglages — tarification (**S08**), puissance et placement
  (**S06**), durées de conservation (**S08**, **S14**, **S18**), fournisseur d'identité (**S12**) —
  appartiennent à leurs specs. S21 fournit **le point de réglage**, pas le comportement réglé.
- Le **mécanisme d'audit** lui-même → **S13**, où S21 émet ses entrées.
- La **collecte de métriques** et les tableaux de bord → **S02** ; le **hub** et les règles d'alerte
  → **S15**. La vue de santé de S21 est un **agrégat d'exploitation**, pas une seconde chaîne
  d'observabilité.
- Le **drainage** d'une carte ou d'une machine sur incident → **S06**, **S19**. S21 fournit la
  **procédure**, pas le mécanisme.
- L'**outillage** de charge et la chaîne d'intégration → **S03**. S21 **versionne les scénarios** et
  les rejoue.
- La **mise à jour des moteurs** et le retour arrière : relèvent du workflow d'exploitation, rendu
  possible par l'épinglage (Art. 11) posé dès **S01**.

### Key Entities

- **Réglage** : paramètre de configuration de la plateforme, identifié, **versionné** et **audité** à
  chaque modification.
- **État de santé** : agrégat d'exploitation couvrant versions, disques, sauvegardes et diagnostics.
  Ne peut être au vert si un composant est en échec.
- **Sauvegarde** : copie périodique des données critiques et de la configuration, placée hors
  machine. États : planifiée → en cours → vérifiée · échouée. **Non vérifiée = non valide.**
- **Procédure d'incident** : marche à suivre écrite pour un incident courant identifié.
- **Scénario de charge** : jeu d'appels versionné, rejouable, servant à prouver l'absence de famine
  de la lane interactive.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001** *(critère A1 du document)*: Une restauration depuis sauvegarde, effectuée sur un
  environnement vierge en suivant **uniquement la procédure documentée**, retrouve **100 %** des
  données critiques — et l'exercice est **rejoué au moins une fois par trimestre**, avec son
  résultat consigné.
- **SC-002** *(critère A2)*: Sous une rafale d'agents rejouée depuis les scénarios versionnés, le
  temps d'attente de la lane interactive **reste dans son seuil de service** — **zéro** famine.
- **SC-003** *(critère A3)*: **100 %** des modifications de réglage sont **versionnées** et
  retrouvables dans le journal d'audit avec auteur, horodatage, ancienne et nouvelle valeur.
- **SC-004**: **Zéro** échec de sauvegarde silencieux : tout échec déclenche une alerte et apparaît
  dans l'état de santé.
- **SC-005**: L'état de santé agrégé n'est **jamais** au vert alors qu'un composant est en échec.
- **SC-006**: Les modèles téléchargés représentent **zéro octet** dans les sauvegardes.
- **SC-007**: Une destination de sauvegarde indisponible n'entraîne **aucune** perte de sauvegarde
  valide antérieure.
- **SC-008**: Les procédures d'incident couvrent **les trois incidents courants** identifiés et
  permettent à un opérateur de les traiter sans connaissance implicite.
- **SC-009**: Les scénarios de charge sont **rejouables à l'identique** depuis le dépôt.
- **SC-010**: Un réglage invalide est refusé **sans** laisser la plateforme dans un état
  intermédiaire.
- **SC-011**: Un raccourcissement de durée de conservation présente son **effet sur les données
  existantes** avant validation.

### Traçabilité critère → preuve

| Critère du document | Critères de succès | Preuve (tâche de la fiche 9z) |
| --- | --- | --- |
| A1 — restauration testée et documentée | SC-001, SC-006, SC-007 | T6 `[TEST]` restauration scriptée · T5 procédure documentée |
| A2 — rafale d'agents sans famine de la lane interactive | SC-002, SC-009 | T9 `[TEST]` charge sans famine · T7 scénarios versionnés |
| A3 — réglages versionnés et audités | SC-003, SC-010, SC-011 | T9 `[TEST]` réglages audités · T2 réglage modifié → audit |
| Sauvegardes non silencieuses | SC-004, SC-005 | T4 sauvegarde périodique · T3 santé agrégée |
| Procédures d'incident | SC-008 | T8 procédures d'incident |

## Assumptions

- **Dépend de toutes les specs** : S21 est la spec de clôture. Elle agrège des éléments produits
  ailleurs — réglages des autres specs, santé des composants, sauvegarde des données de chacune. Elle
  n'introduit aucune fonctionnalité métier nouvelle.
- **« Une sauvegarde non testée en restauration n'est pas une sauvegarde »** : formulation du
  document, reprise comme exigence stricte (FR-014) et non comme recommandation. C'est pourquoi la
  vérification porte sur le **contenu restauré** et non sur la réussite de la copie : une copie
  réussie d'une base corrompue reste inutile.
- **Les modèles sont exclus des sauvegardes** : choix explicite du document. Ils représentent
  l'essentiel du volume, sont re-téléchargeables, et leurs empreintes d'intégrité sont conservées en
  base — ce qui rend la sauvegarde petite, donc réellement pratiquée (Art. 9).
- **Exercice de restauration trimestriel** : cadence fixée par le document. Une procédure jamais
  exercée est une procédure fausse ; sa date de dernier exercice est rendue visible (FR-019) pour que
  l'oubli se voie.
- **Les scénarios de charge s'exécutent sur un environnement dédié** : ajout de la spec (FR-023). Les
  exécuter en production dégraderait précisément ce qu'ils prétendent mesurer, et violerait l'Art. 2
  au passage.
- **La vue de santé est un agrégat, pas une seconde chaîne d'observabilité** : elle lit ce que S02 et
  S15 exposent déjà. C'est la même règle que celle imposée à S15 (Art. 19).
- **Le retour arrière en une commande repose sur l'épinglage** : l'Art. 11 en fait la condition, et
  l'épinglage est posé dès S01. S21 en dépend sans le réimplémenter.
- **Jalon M4** : la spec est **complète à M4**. Avec elle, l'intégralité du plan de specs S01–S21 est
  couverte.
