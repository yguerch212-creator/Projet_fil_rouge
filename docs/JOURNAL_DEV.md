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
