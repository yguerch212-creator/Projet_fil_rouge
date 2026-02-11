# Cahier des Charges

## Système de Construction RP — Addon Garry's Mod

**Projet Fil Rouge — B3 Cybersécurité, Efrei Bordeaux**

*Date de rédaction : février 2026*

*Version : 1.0 — Finalisé*

---

## Table des matières

1. [Présentation générale du projet](#1-présentation-générale-du-projet)
2. [Contexte et origine du besoin](#2-contexte-et-origine-du-besoin)
3. [Objectifs du projet](#3-objectifs-du-projet)
4. [Périmètre du projet](#4-périmètre-du-projet)
5. [Description fonctionnelle](#5-description-fonctionnelle)
6. [Exigences techniques](#6-exigences-techniques)
7. [Contraintes](#7-contraintes)
8. [Livrables attendus](#8-livrables-attendus)
9. [Planning prévisionnel](#9-planning-prévisionnel)
10. [Critères de réception](#10-critères-de-réception)
11. [Risques identifiés](#11-risques-identifiés)
12. [Annexes](#12-annexes)

---

# 1. Présentation générale du projet

## 1.1. Intitulé

**RP Construction System** — Addon de construction collaborative pour Garry's Mod DarkRP.

## 1.2. Commanditaire

Projet académique — Projet Fil Rouge, B3 Cybersécurité, Efrei Bordeaux.

## 1.3. Résumé

Conception, développement et déploiement d'un addon Garry's Mod qui introduit un système de construction collaborative sur des serveurs DarkRP. L'addon permet à un joueur au rôle de Constructeur de sélectionner des props, de les sauvegarder en « blueprint », puis de les placer comme fantômes holographiques. N'importe quel joueur peut ensuite matérialiser ces fantômes en utilisant des caisses de matériaux. Les caisses sont transportables en véhicule pour la logistique.

Le projet inclut l'infrastructure d'hébergement (Docker), la base de données (MySQL), la sécurité applicative et la documentation technique complète.

## 1.4. Public cible

- **Administrateurs de serveurs DarkRP** : installation et configuration de l'addon
- **Joueurs Garry's Mod** : utilisation du système de construction en jeu
- **Communauté Workshop** : addon publiable sur le Steam Workshop

---

# 2. Contexte et origine du besoin

## 2.1. Contexte

Garry's Mod est un jeu sandbox multijoueur basé sur le moteur Source. Le mode DarkRP (Dark Roleplay) est le gamemode le plus populaire, avec un système de jobs, d'économie et d'entités interactives. Des milliers de serveurs DarkRP existent, chacun avec ses addons personnalisés.

## 2.2. Constat

Les outils de construction existants sur Garry's Mod présentent des limites :

| Outil existant | Limitation |
|----------------|-----------|
| **AdvDupe2** | Duplication individuelle — un seul joueur duplique et place. Pas de collaboration, pas de gestion de ressources, pas d'intégration RP. |
| **Precision Tool** | Positionnement précis, mais pas de sauvegarde ni de collaboration. |
| **Build servers** | Serveurs sandbox sans gameplay RP — construction libre sans objectif ni économie. |

**Ce qui manque** : un système qui transforme la construction en activité collaborative intégrée au gameplay RP, avec des rôles (constructeur), des ressources (caisses de matériaux), de la logistique (transport en véhicule) et de la progression (fantômes → props réels).

## 2.3. Origine du besoin

Le projet répond à un double besoin :

1. **Besoin pédagogique** : démontrer des compétences en infrastructure (Docker), développement (GLua), base de données (MySQL), sécurité applicative et documentation — dans le cadre du Projet Fil Rouge B3 Cybersécurité.

2. **Besoin communautaire** : proposer un addon original, standalone, publiable sur le Steam Workshop, qui enrichit le gameplay DarkRP avec une mécanique de construction collaborative inédite.

---

# 3. Objectifs du projet

## 3.1. Objectifs fonctionnels

| ID | Objectif | Priorité |
|----|----------|----------|
| OF-01 | Permettre la sélection de props existants par un joueur autorisé | Critique |
| OF-02 | Sauvegarder un ensemble de props sous forme de blueprint (fichier local) | Critique |
| OF-03 | Charger un blueprint et afficher des fantômes holographiques | Critique |
| OF-04 | Matérialiser les fantômes via des caisses de matériaux (gameplay collaboratif) | Critique |
| OF-05 | Proposer une interface utilisateur intuitive (SWEP + menu Derma) | Importante |
| OF-06 | Supporter le transport de caisses en véhicule simfphys | Importante |
| OF-07 | Importer les fichiers AdvDupe2 sans dépendance externe | Souhaitable |
| OF-08 | Organiser les blueprints en sous-dossiers | Souhaitable |

## 3.2. Objectifs techniques

| ID | Objectif | Priorité |
|----|----------|----------|
| OT-01 | Déployer l'infrastructure sur Docker (GMod + MySQL) | Critique |
| OT-02 | Assurer la séparation stricte client/serveur | Critique |
| OT-03 | Implémenter des mesures de sécurité (rate limiting, validation, blacklist) | Critique |
| OT-04 | Rendre l'addon standalone (pas de dépendances obligatoires) | Importante |
| OT-05 | Rendre l'addon configurable (un seul fichier de configuration) | Importante |
| OT-06 | Documenter l'architecture, l'installation et l'utilisation | Importante |

## 3.3. Objectifs pédagogiques

| ID | Compétence visée | Détail |
|----|-----------------|--------|
| OP-01 | Infrastructure & DevOps | Conteneurisation Docker Compose, volumes, networking |
| OP-02 | Développement logiciel | Architecture client/serveur en GLua (~3 200 lignes) |
| OP-03 | Base de données | MySQL 8.0, schéma relationnel, prepared statements |
| OP-04 | Sécurité applicative | Rate limiting, injection SQL, validation, CPPI |
| OP-05 | Documentation technique | DAT, guides, architecture, cahier des charges |
| OP-06 | Résolution de problèmes | Debug sur stack complexe (Docker + Source Engine + Lua) |

---

# 4. Périmètre du projet

## 4.1. Dans le périmètre

| Composant | Description |
|-----------|-------------|
| Addon GLua | SWEP, 3 entités custom, 16 modules (sv_/cl_/sh_), ~3 200 lignes |
| Infrastructure Docker | docker-compose.yml, 2 containers (GMod + MySQL), volumes |
| Base de données | Schéma MySQL (3 tables), module MySQLOO (optionnel) |
| Documentation | README projet, README addon (bilingue), DAT, guides, CDC |
| Intégration DarkRP | Jobs, entités F4, TEAM_ IDs, darkrpmodification |
| Intégration simfphys | Chargement/déchargement caisses, offsets calibrés |
| Sécurité | Rate limiting, validation, blacklist, CPPI, prepared statements |

## 4.2. Hors périmètre

| Élément | Raison |
|---------|--------|
| Système monétaire (coût par prop) | Reporté — à ajouter ultérieurement si besoin |
| Partage de blueprints entre joueurs (via serveur) | Tables DB prévues mais fonctionnalité non implémentée |
| Support LVS avancé | Détection automatique OK, mais pas d'offsets calibrés par modèle |
| Tests automatisés / CI-CD | Pas d'outillage de test unitaire pour GLua |
| Haute disponibilité / redondance | Contrainte budgétaire — un seul VPS |
| Application web / panel admin | Hors scope — gestion via console et RCON |

---

# 5. Description fonctionnelle

## 5.1. Cas d'utilisation principaux

### CU-01 : Sélectionner des props

**Acteur** : Constructeur (joueur au job autorisé)
**Prérequis** : Le joueur possède le SWEP `weapon_construction`
**Scénario** :
1. Le joueur vise un `prop_physics` dont il est propriétaire
2. Clic gauche → le prop est ajouté à la sélection (halo bleu)
3. Clic gauche sur un prop déjà sélectionné → il est retiré
4. Clic droit → tous les props dans un rayon configurable sont sélectionnés
5. Touche R → vide la sélection

**Vérifications serveur** : ownership CPPI, classe autorisée, rate limit

### CU-02 : Sauvegarder un blueprint

**Acteur** : Constructeur
**Prérequis** : Au moins 1 prop sélectionné
**Scénario** :
1. Shift + Clic droit → ouvre le menu
2. Onglet « Sauvegarder » → entre un nom et une description optionnelle
3. Choix du dossier de destination
4. Clic « Sauvegarder »
5. Le serveur sérialise les props (positions relatives, modèles, angles)
6. Les données sont renvoyées au client qui les écrit dans `data/construction_blueprints/<nom>.dat`

**Vérifications serveur** : rate limit (10s), props valides, ownership, nombre max (150)

### CU-03 : Charger un blueprint et placer des fantômes

**Acteur** : Constructeur
**Prérequis** : Au moins 1 blueprint sauvegardé
**Scénario** :
1. Ouvrir le menu → onglet « Blueprints »
2. Naviguer dans les dossiers, sélectionner un blueprint
3. Clic « Charger »
4. Le client envoie les données au serveur pour validation
5. Le serveur renvoie les données validées pour la prévisualisation
6. Le joueur voit un aperçu holographique qu'il peut positionner :
   - Molette : rotation
   - Shift + Molette : hauteur
   - Checkbox : position originale
7. Clic gauche → confirme le placement
8. Le serveur spawn les ghost entities (batch de 5 par tick)

**Vérifications serveur** : rate limit (15s), ValidateBlueprintData (classes, limites, cohérence)

### CU-04 : Matérialiser un fantôme

**Acteur** : Tout joueur
**Prérequis** : Une caisse de matériaux active + un fantôme visible
**Scénario** :
1. Le joueur achète une caisse au menu F4 (Entities → Construction)
2. Appuie E sur la caisse → activation (NWEntity ActiveCrate)
3. Approche un fantôme bleu, appuie E
4. Le fantôme devient un vrai `prop_physics` solide
5. 1 matériau consommé de la caisse
6. Le prop appartient au joueur qui l'a matérialisé

**Vérifications serveur** : caisse valide, matériaux > 0, ghost valide, rate limit

### CU-05 : Transporter des caisses en véhicule

**Acteur** : Tout joueur avec le SWEP
**Prérequis** : Un véhicule simfphys + une caisse à proximité
**Scénario** :
1. Le joueur pose une caisse près d'un véhicule simfphys
2. Équipe le SWEP, vise le véhicule, appuie R
3. La caisse se charge automatiquement (SetParent, physique désactivée)
4. Le joueur conduit le véhicule jusqu'au chantier
5. Vise le véhicule, appuie R → la caisse est déchargée à côté

**Vérifications serveur** : véhicule simfphys valide, caisse à proximité (500u), max 2 par véhicule

### CU-06 : Importer un fichier AdvDupe2

**Acteur** : Constructeur
**Prérequis** : Un fichier `.txt` AdvDupe2 dans le dossier blueprints
**Scénario** :
1. Le joueur copie un fichier AD2 dans `data/construction_blueprints/`
2. Le fichier apparaît dans le menu avec un badge orange « AD2 »
3. Sélection + clic « Charger » → décodage binaire embarqué (pas besoin d'AD2 installé)
4. Suite identique au CU-03

## 5.2. Diagramme des cas d'utilisation (textuel)

```
                    ┌─────────────────────────────────┐
                    │        Constructeur              │
                    │   (job DarkRP autorisé)          │
                    └──────┬──────────────────────────┘
                           │
           ┌───────────────┼───────────────────┐
           │               │                   │
     ┌─────▼─────┐  ┌─────▼──────┐  ┌────────▼────────┐
     │ Sélection  │  │ Sauvegarde │  │   Chargement    │
     │  de props  │  │ blueprint  │  │  + Placement    │
     └────────────┘  └────────────┘  └─────────────────┘

                    ┌─────────────────────────────────┐
                    │        Tout joueur               │
                    └──────┬──────────────────────────┘
                           │
           ┌───────────────┼───────────────────┐
           │               │                   │
     ┌─────▼─────┐  ┌─────▼──────┐  ┌────────▼────────┐
     │ Achat      │  │ Matériali- │  │   Transport     │
     │ caisse F4  │  │ sation     │  │   véhicule      │
     └────────────┘  └────────────┘  └─────────────────┘

                    ┌─────────────────────────────────┐
                    │     Administrateur serveur       │
                    └──────┬──────────────────────────┘
                           │
           ┌───────────────┼───────────────────┐
           │               │                   │
     ┌─────▼─────┐  ┌─────▼──────┐  ┌────────▼────────┐
     │ Config     │  │ Logs /     │  │   Gestion       │
     │ sh_config  │  │ Audit      │  │   jobs/perms    │
     └────────────┘  └────────────┘  └─────────────────┘
```

## 5.3. Règles métier

| ID | Règle | Détail |
|----|-------|--------|
| RM-01 | Seuls les `prop_physics` sont sélectionnables | Aucune autre classe d'entité (NPC, véhicule, arme) |
| RM-02 | Un joueur ne peut sélectionner que ses propres props | Vérification CPPI ownership |
| RM-03 | Les blueprints sont stockés localement | Pas de stockage serveur — le joueur est propriétaire de ses données |
| RM-04 | La matérialisation consomme 1 matériau par prop | Quand la caisse est vide, elle est retirée |
| RM-05 | Le prop matérialisé appartient au joueur qui l'a construit | Pas au constructeur qui a placé le blueprint |
| RM-06 | Maximum 2 caisses chargées par véhicule | Décalage gauche/droite pour le placement |
| RM-07 | Les entités blacklistées sont interdites dans les blueprints | money_printer, drug_lab, etc. |
| RM-08 | Maximum 150 props par blueprint | Configurable, pour la performance serveur |

---

# 6. Exigences techniques

## 6.1. Exigences d'infrastructure

| ID | Exigence | Détail |
|----|----------|--------|
| ET-01 | Conteneurisation Docker | L'ensemble de l'infrastructure doit être déployable via `docker compose up -d` |
| ET-02 | Isolation des services | Le serveur GMod et MySQL doivent être dans des containers séparés |
| ET-03 | Persistance des données | Les données Workshop (~8 Go) doivent survivre aux redémarrages (volume nommé) |
| ET-04 | Snapshots Docker | L'état du serveur doit être sauvegardable via `docker commit` |
| ET-05 | Limites de ressources | GMod ≤ 3 Go RAM, MySQL ≤ 512 Mo RAM |

## 6.2. Exigences de développement

| ID | Exigence | Détail |
|----|----------|--------|
| ED-01 | Séparation client/serveur | Fichiers préfixés sv_/cl_/sh_. Le client n'a aucune autorité. |
| ED-02 | Configuration centralisée | Un seul fichier `sh_config.lua` pour tous les paramètres |
| ED-03 | Addon standalone | Aucune dépendance obligatoire (MySQLOO, simfphys, AD2 = optionnels) |
| ED-04 | Workshop-ready | L'addon doit être publiable sur le Steam Workshop sans modification |
| ED-05 | Compatibilité DarkRP | Intégration native avec les jobs, entités F4, système économique |
| ED-06 | Compatibilité FPP | Hooks CPPI pour la prop protection |

## 6.3. Exigences de sécurité

| ID | Exigence | Détail |
|----|----------|--------|
| ES-01 | Rate limiting | Maximum 60 requêtes/minute par joueur, cooldowns par action |
| ES-02 | Validation serveur | Toute donnée client est re-validée côté serveur |
| ES-03 | Injection SQL | Prepared statements exclusivement (aucune concaténation) |
| ES-04 | Blacklist entités | Les classes dangereuses sont interdites dans les blueprints |
| ES-05 | Contrôle d'accès | Restrictions par job DarkRP (SWEP, caisses, F4) |
| ES-06 | Traçabilité | Logs console + DB de toutes les actions significatives |

## 6.4. Exigences de performance

| ID | Exigence | Détail |
|----|----------|--------|
| EP-01 | Sélection < 100 ms | Net message aller-retour |
| EP-02 | Sauvegarde < 2 s | Sérialisation + écriture fichier |
| EP-03 | Chargement < 3 s | Pour un blueprint de 50 props |
| EP-04 | Matérialisation < 200 ms | Par ghost individuel |
| EP-05 | Pas de lag serveur | Batch spawning (5 ghosts/tick) pour les gros blueprints |

## 6.5. Exigences d'ergonomie

| ID | Exigence | Détail |
|----|----------|--------|
| EE-01 | SWEP intuitif | LMB/RMB/Shift+RMB/R — contrôles standards GMod |
| EE-02 | HUD informatif | Compteur de sélection, raccourcis affichés |
| EE-03 | Menu moderne | Dark theme, sidebar, breadcrumb, badges |
| EE-04 | Feedback immédiat | Notifications visuelles pour chaque action |
| EE-05 | Prévisualisation | Aperçu holographique avant le placement définitif |

---

# 7. Contraintes

## 7.1. Contraintes techniques

| Contrainte | Impact | Mitigation |
|-----------|--------|------------|
| Moteur Source (2004) | Pas de multithreading Lua, limite ~2048 entités, tick rate fixe | Batch spawning, limites configurables |
| GLua (Lua 5.1) | Pas de typage, pas de modules externes, pas d'async natif | Callbacks MySQLOO, conventions de code strictes |
| Net library (64 Ko max) | Blueprints volumineux doivent être compressés | Compression util.Compress + découpage si nécessaire |
| Bind mounts Docker | `resource.AddFile` ne fonctionne pas → clients ne reçoivent pas les fichiers custom | Modèle fallback en dev, Workshop en production |
| Cache Lua client | Le client ne reçoit les MAJ qu'après reconnexion | Documentation du comportement, `retry` en console |

## 7.2. Contraintes budgétaires

| Ressource | Contrainte | Solution |
|-----------|-----------|----------|
| VPS | 1 seul serveur Hostinger 16 Go RAM | Docker Compose sur un seul hôte |
| Licences | Aucun budget | Uniquement des outils open-source/gratuits |
| Hébergement | Pas de CDN, pas de FastDL dédié | Workshop pour la distribution des assets |

## 7.3. Contraintes organisationnelles

| Contrainte | Détail |
|-----------|--------|
| Projet individuel | Un seul développeur |
| Durée limitée | ~12 étapes de développement |
| Deadline fixe | 22/02/2026 |

---

# 8. Livrables attendus

## 8.1. Livrables techniques

| Livrable | Format | Description |
|----------|--------|-------------|
| Addon `rp_construction_system` | Dossier Lua/models/materials | Addon complet, standalone, Workshop-ready |
| Infrastructure Docker | `docker-compose.yml` + configs | Environnement de développement reproductible |
| Schéma SQL | `sql/schema.sql` | 3 tables (logs, blueprints partagés, permissions) |
| Configuration DarkRP | `darkrpmodification/` | Jobs, entités F4, catégories |
| Dépôt Git | GitHub public | Code source versionné, commits professionnels |

## 8.2. Livrables documentaires

| Livrable | Localisation | Description |
|----------|-------------|-------------|
| README Projet | `README.md` (racine) | Présentation complète du parcours B3 |
| README Addon | `addon/.../README.md` | Documentation standalone bilingue FR/EN |
| DAT | `rendu/dat/` | Dossier d'Architecture Technique (5 vues) |
| Cahier des Charges | `rendu/cdc/` | Ce document |
| Plan de sauvegarde | `rendu/backup/` | Stratégie et procédures de backup |
| Compte-rendu d'amélioration | `rendu/amelioration/` | Axes d'amélioration (4 thèmes) |
| Architecture | `docs/ARCHITECTURE.md` | Diagrammes, flux, net messages |
| Guide d'installation | `docs/GUIDE_INSTALLATION.md` | Guide admin serveur |
| Guide d'utilisation | `docs/GUIDE_UTILISATEUR.md` | Guide joueur |

## 8.3. Images Docker

| Tag | Description |
|-----|------------|
| `v1.0-base` | GMod + DarkRP + 101 addons Workshop |
| `v1.1-mysql` | + MySQLOO + schéma SQL |
| `v2-stable` | Refonte v2.0 (SWEP + ghosts + caisses) |
| `v2.1-stable` | + Import AD2, dossiers, UI refonte |
| `v2.2-vehicles` | + Véhicules simfphys (version finale) |

---

# 9. Planning prévisionnel

| Étape | Contenu | Livrables |
|-------|---------|-----------|
| 1 | Infrastructure Docker, structure projet | docker-compose.yml, repo Git |
| 2 | Configuration DarkRP, MySQL, MySQLOO | darkrpmodification, schéma SQL |
| 3 | Système de sélection (STOOL initial) | sv_selection, cl_selection |
| 4 | Sérialisation, blueprints, interface Derma | sv_blueprints, cl_menu |
| 5 | Permissions et partage | sv_permissions |
| 6 | Sécurité (rate limiting, blacklist, validation) | sv_security |
| 7 | Refonte v2.0 : SWEP + ghosts + caisses | weapon_construction, entities |
| 8 | Placement avancé, UI moderne, import AD2 | cl_placement, cl_ad2_decoder |
| 9 | Sauvegardes locales, dossiers | cl_blueprints |
| 10 | Véhicules simfphys v2.2 | sv_vehicles, cl_vehicles |
| 11 | Finalisation, tests, documentation | Tous les docs, images Docker |

---

# 10. Critères de réception

## 10.1. Critères fonctionnels

| ID | Critère | Validation |
|----|---------|-----------|
| CR-01 | Un constructeur peut sélectionner des props et sauvegarder un blueprint | Test manuel en jeu |
| CR-02 | Le blueprint peut être rechargé et des fantômes sont affichés | Test manuel |
| CR-03 | Un joueur avec une caisse peut matérialiser un fantôme | Test manuel |
| CR-04 | Les caisses sont achetables au F4 DarkRP | Test manuel |
| CR-05 | Les caisses se chargent/déchargent des véhicules simfphys | Test manuel |
| CR-06 | L'import AdvDupe2 fonctionne sans AD2 installé | Test avec fichier .txt AD2 |
| CR-07 | L'interface est fonctionnelle (menu, dossiers, badges) | Test manuel |

## 10.2. Critères techniques

| ID | Critère | Validation |
|----|---------|-----------|
| CR-08 | `docker compose up -d` démarre l'infrastructure complète | Commande unique |
| CR-09 | L'addon fonctionne sans MySQL (mode dégradé) | Test sans container MySQL |
| CR-10 | Le rate limiting bloque les requêtes excessives | Test de flooding |
| CR-11 | Les entités blacklistées sont rejetées | Test avec money_printer |
| CR-12 | Les prepared statements sont utilisés exclusivement | Revue de code |
| CR-13 | L'addon est standalone (pas de dépendance obligatoire) | Installation sur serveur vierge |

## 10.3. Critères documentaires

| ID | Critère | Validation |
|----|---------|-----------|
| CR-14 | README addon bilingue FR/EN | Relecture |
| CR-15 | DAT couvrant les 5 vues | Relecture |
| CR-16 | Guide d'installation permettant un déploiement depuis zéro | Test par un tiers |
| CR-17 | Guide utilisateur couvrant tous les cas d'utilisation | Relecture |

---

# 11. Risques identifiés

| ID | Risque | Probabilité | Impact | Mitigation |
|----|--------|-------------|--------|------------|
| R-01 | Mise à jour GMod cassant l'addon | Faible | Élevé | Code robuste, pas de hacks, hooks standards |
| R-02 | Image Docker `ceifa/garrysmod` non maintenue | Faible | Élevé | Snapshots `docker commit`, possibilité de migrer vers image custom |
| R-03 | Workshop indisponible (Valve) | Très faible | Moyen | Assets embarqués dans l'addon (modèles, textures) |
| R-04 | Performance avec beaucoup de ghosts | Moyenne | Moyen | Batch spawning, limite 150 props/blueprint configurable |
| R-05 | Incompatibilité avec d'autres addons | Moyenne | Faible | Namespace `ConstructionSystem`, hooks spécifiques, pas de globals pollués |
| R-06 | Exploit via net messages malformés | Faible | Élevé | Validation systématique, rate limiting, blacklist |
| R-07 | Perte de données MySQL | Moyenne | Faible | DB optionnelle, blueprints en local, `docker commit` pour backup |
| R-08 | Dépassement du planning | Moyenne | Moyen | Priorisation (critiques d'abord), scope modulable |

---

# 12. Annexes

## 12.1. Stack technique

| Composant | Technologie | Version |
|-----------|-------------|---------|
| Serveur de jeu | Garry's Mod Dedicated Server | Dernière |
| Gamemode | DarkRP | 2.14.x |
| Langage | GLua (Lua 5.1) | — |
| Base de données | MySQL | 8.0 |
| Module DB | MySQLOO | 9.7.6 |
| Conteneurisation | Docker + Compose | 24.x |
| Image Docker | `ceifa/garrysmod` | latest |
| Véhicules | simfphys | Dernière |
| Versioning | Git + GitHub | — |
| OS serveur | Ubuntu Linux | 6.8.0 |

## 12.2. Références

| Document | Localisation |
|----------|-------------|
| README Projet Fil Rouge | `README.md` (racine) |
| README Addon (bilingue) | `addon/rp_construction_system/README.md` |
| Architecture technique | `docs/ARCHITECTURE.md` |
| Guide d'installation | `docs/GUIDE_INSTALLATION.md` |
| Guide d'utilisation | `docs/GUIDE_UTILISATEUR.md` |
| DAT | `rendu/dat/README.md` |
| Schéma SQL | `addon/.../sql/schema.sql` |
| Configuration | `addon/.../lua/rp_construction/sh_config.lua` |

## 12.3. Métriques du projet

| Métrique | Valeur |
|----------|--------|
| Lignes de code GLua | ~3 200 |
| Modules Lua | 16 fichiers |
| Entités custom | 3 (ghost, crate, crate_small) |
| Net messages | 16 types |
| Tables MySQL | 3 |
| Images Docker | 5 versions |
| Commits Git | ~30 |
| Addons Workshop | 101 (collection serveur) |
