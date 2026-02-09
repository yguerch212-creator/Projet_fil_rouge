# 🏗️ RP Construction System - Projet Fil Rouge

## Description

Addon Garry's Mod pour serveur DarkRP permettant aux joueurs de créer, sauvegarder et partager des blueprints de construction. Système complet avec base de données MySQL, gestion des permissions et interface utilisateur intuitive.

**Projet réalisé dans le cadre du Projet Fil Rouge - B3 Cybersécurité**

## 🎯 Fonctionnalités

- **Blueprints** : Sauvegarde et chargement de constructions complexes
- **Base de données MySQL** : Stockage persistant des blueprints et permissions
- **Système de permissions** : Partage de blueprints entre joueurs
- **Logs d'activité** : Traçabilité complète des actions
- **Interface DarkRP** : Intégration native avec le gamemode DarkRP
- **Job Constructeur** : Rôle dédié avec outils spécialisés

## 🏗️ Architecture

```
ProjetFilRouge/
├── docker/                    # Infrastructure Docker
│   ├── docker-compose.yml     # GMod Server + MySQL
│   ├── addons/                # Addons montés dans le serveur
│   │   ├── rp_construction_system/  # Addon principal
│   │   └── darkrpmodification/      # Config DarkRP
│   ├── gamemodes/             # DarkRP gamemode
│   ├── server-config/         # server.cfg
│   └── mysql-init/            # Schema SQL initial
├── addon/                     # Source de l'addon (développement)
│   └── rp_construction_system/
├── docs/                      # Documentation
├── schemas/                   # Schémas SQL
├── screenshots/               # Captures d'écran
└── scripts/                   # Scripts utilitaires
```

## 🐳 Infrastructure Docker

| Service | Image | Port | RAM |
|---------|-------|------|-----|
| GMod Server | ceifa/garrysmod:latest | 27015 (UDP/TCP) | 3GB max |
| MySQL 8.0 | mysql:8.0 | 3306 | 512MB max |

### Démarrage rapide

```bash
cd docker/
docker compose up -d
```

### Image Docker stable

Une image Docker pré-configurée avec tous les addons workshop est disponible localement :
```bash
# Restaurer depuis l'image stable
docker commit gmod-server projetfilrouge/gmod-server:TAG
```

Voir [docs/DOCKER_IMAGES.md](docs/DOCKER_IMAGES.md) pour la gestion complète.

## 🗄️ Base de données

### Tables

| Table | Description |
|-------|-------------|
| `blueprints` | Stockage des blueprints (JSON sérialisé) |
| `permissions` | Droits de partage entre joueurs |
| `blueprint_logs` | Journal d'activité (création, modification, suppression) |

### Connexion MySQL

- **Host** : gmod-mysql (réseau Docker interne)
- **Database** : gmod_construction
- **User** : gmod_user

## 🎮 Configuration serveur

- **Gamemode** : DarkRP
- **Map** : gm_construct
- **Workshop Collection** : [2270926906](https://steamcommunity.com/sharedfiles/filedetails/?id=2270926906)
- **Véhicules** : Activés (Jeep, Airboat, Jalopy)
- **Job custom** : Constructeur (outils de construction)

## 📋 Stack technique

- **Langage** : Lua / GLua (Garry's Mod Lua)
- **Serveur** : Source Dedicated Server (srcds)
- **Base de données** : MySQL 8.0 via MySQLOO
- **Conteneurisation** : Docker / Docker Compose
- **Versioning** : Git / GitHub
- **OS** : Ubuntu Server (VPS)

## 📅 Planning

| Phase | Description | Statut |
|-------|-------------|--------|
| Jour 1 | Infrastructure Docker + Base addon | ✅ |
| Jour 2 | MySQLOO + Module base de données | ✅ |
| Jour 3 | Système de sélection de props | 🔜 |
| Jour 4 | Sauvegarde/Chargement blueprints | 🔜 |
| Jour 5 | Interface utilisateur (Derma) | 🔜 |
| Jour 6 | Permissions et partage | 🔜 |
| Jour 7 | Logging et sécurité | 🔜 |
| Jour 8 | Tests et optimisation | 🔜 |
| Jour 9 | Documentation technique | 🔜 |
| Jour 10 | Finalisation et rendu | 🔜 |

## 📝 Journal de développement

Voir [docs/JOURNAL_DEV.md](docs/JOURNAL_DEV.md)

## 📄 Licence

Projet académique - B3 Cybersécurité
