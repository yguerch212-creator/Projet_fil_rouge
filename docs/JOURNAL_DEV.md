# Journal de Développement

## 7 Février 2026 - Jour 1 : Setup Infrastructure Docker

### Objectif
Mettre en place l'infrastructure de base : serveur GMod via Docker + base de données MySQL.

### Actions réalisées

#### Phase 1.1 - Préparation Environnement
- Création de la structure de dossiers du projet
- Initialisation du repository Git
- Configuration du .gitignore
- Premier push sur GitHub

#### Phase 1.2 - Configuration Docker Compose
- Création du `docker-compose.yml` avec deux services :
  - **gmod-server** : Image `ceifa/garrysmod` (serveur GMod dédié)
  - **gmod-mysql** : MySQL 8.0 pour la persistance des données
- Limites de ressources configurées (3GB RAM max pour GMod, 512MB pour MySQL)
- Création du schéma SQL initial avec 3 tables :
  - `blueprints` : Stockage des constructions sauvegardées
  - `permissions` : Gestion des droits utilisateurs
  - `blueprint_logs` : Historique des actions

#### Phase 1.3 - Installation DarkRP
- Installation de DarkRP (gamemode roleplay)
- Configuration basique du serveur
- Téléchargement d'Advanced Duplicator 2 comme référence technique

### Ressources utilisées
- Image Docker : https://github.com/ceifa/garrysmod-docker
- Collection Workshop : ID 2270926906
- Advanced Duplicator 2 : https://steamcommunity.com/sharedfiles/filedetails/?id=773402917

### Environnement
- VPS Hostinger 16GB RAM
- Ubuntu Linux
- Docker Compose

### Prochaines étapes
- Vérifier que le serveur GMod démarre correctement
- Tester la connexion MySQL
- Installer DarkRP et les addons de base

---

## 9 Février 2026 - Jour 2 : MySQLOO + Module Base de Données

### Objectif
Installer MySQLOO et développer le module de base de données pour l'addon de construction.

### Actions réalisées

#### Phase 2.1 - Installation MySQLOO
- Téléchargement de MySQLOO 9.7.6 depuis GitHub (module binaire Linux 64-bit)
- Installation dans `garrysmod/lua/bin/` via volume Docker
- Vérification du chargement via RCON : `require("mysqloo")` OK
- Configuration du volume `lua-bin` dans docker-compose pour la persistance

#### Phase 2.2 - Configuration centralisée
- Création de `sh_config.lua` (shared config) :
  - Paramètres de limites (max props, max blueprints)
  - Coûts DarkRP (sauvegarde, chargement, partage)
  - Cooldowns anti-spam
  - Configuration base de données
  - Liste des net messages

#### Phase 2.3 - Module Database (sv_database.lua)
- Architecture complète du module database avec MySQLOO :
  - **Connexion** : auto-reconnect toutes les 30s en cas d'échec
  - **Init Tables** : création automatique des 3 tables au démarrage
  - **CRUD Blueprints** : Save, Load, Update, Delete avec prepared statements
  - **Permissions** : Share, Unshare avec niveaux (view/use/edit)
  - **Requêtes** : GetPlayerBlueprints, GetSharedBlueprints, GetPublicBlueprints
  - **Logging** : toutes les actions sont loguées dans blueprint_logs
  - **Sécurité** : prepared statements pour prévenir les injections SQL

#### Phase 2.4 - Tests et validation
- Connexion MySQLOO -> MySQL testée via RCON
- Insertion test réussie (prepared statement)
- Vérification des 3 tables créées avec le bon schéma
- Nettoyage des données de test

### Schéma de base de données

```
blueprints (id, owner_steamid, owner_name, name, description, data, prop_count, constraint_count, is_public, created_at, updated_at)
blueprint_permissions (id, blueprint_id, target_steamid, permission_level, granted_by, granted_at)
blueprint_logs (id, steamid, player_name, action, blueprint_id, blueprint_name, details, created_at)
```

### Environnement
- MySQLOO 9.7.6
- MySQL 8.0 (Docker)
- Prepared statements pour toutes les requêtes

### Prochaines étapes
- Jour 3 : Système de sélection de props (traces, sélection zone, copie duplicator)
