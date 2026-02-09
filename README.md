# Projet Fil Rouge - Système de Construction RP (Garry's Mod)

**Projet B3 Cybersécurité** — Addon DarkRP permettant de sauvegarder, partager et construire collaborativement des structures en jeu.

## Concept

Un système de construction roleplay inspiré de Minecraft : les joueurs peuvent sauvegarder des constructions en "blueprints", les charger en tant que **props fantômes** (schéma transparent), puis les matérialiser prop par prop à l'aide de **caisses de matériaux**. N'importe quel joueur peut aider à construire.

## Fonctionnalités

### Système de blueprints
- Sélection de props avec le SWEP "Outil de Construction" (LMB/RMB/Reload)
- Sauvegarde en base MySQL (sérialisation JSON + compression)
- Menu Derma intégré (Shift+RMB ou `construction_menu`)
- Gestion des blueprints : lister, charger, supprimer

### Construction collaborative
- Chargement d'un blueprint → apparition de **props fantômes** (bleutés, transparents, non-solides)
- **Caisse de Matériaux** (entité DarkRP, 30 matériaux par caisse)
- N'importe quel joueur peut activer une caisse (E) puis matérialiser les fantômes (E)
- Le prop matérialisé appartient au joueur qui l'a posé (ownership CPPI)
- Notification quand la construction est terminée

### Sécurité
- Seuls les `prop_physics` sont autorisés (blacklist money printers, etc.)
- Ownership CPPI : impossible de copier les props des autres
- Prepared statements MySQL (anti-injection SQL)
- Rate limiting sur toutes les actions
- Validation serveur systématique

### DarkRP
- Job **Constructeur** avec SWEP automatique
- Caisse de Matériaux dans le F4 → Entities → Construction ($1)
- Undo support (Ctrl+Z) pour fantômes et props matérialisés

## Stack technique

| Composant | Technologie |
|-----------|-------------|
| Serveur | Garry's Mod (Docker: ceifa/garrysmod) |
| Gamemode | DarkRP |
| Base de données | MySQL 8.0 (Docker) + MySQLOO 9.7 |
| Orchestration | Docker Compose |
| Langage | GLua (Garry's Mod Lua) |

## Structure de l'addon

```
rp_construction_system/
├── lua/
│   ├── autorun/
│   │   ├── server/sv_construction_init.lua   # Point d'entrée serveur
│   │   ├── server/sv_admin_setup.lua         # Config superadmin
│   │   └── client/cl_construction_init.lua   # Point d'entrée client
│   ├── rp_construction/
│   │   ├── sh_config.lua          # Config partagée (limites, BDD, etc.)
│   │   ├── sv_database.lua        # Module MySQL (CRUD, prepared statements)
│   │   ├── sv_selection.lua       # Sélection de props (serveur)
│   │   ├── sv_ghosts.lua          # Système de fantômes + matérialisation
│   │   ├── sv_blueprints.lua      # Save/Load blueprints
│   │   ├── sv_permissions.lua     # Partage entre joueurs
│   │   ├── sv_security.lua        # Rate limiting, logging admin
│   │   ├── sv_logging.lua         # Logging persistant
│   │   ├── cl_selection.lua       # Rendu sélection (client)
│   │   └── cl_menu.lua            # Interface Derma
│   ├── entities/
│   │   ├── construction_ghost/    # Prop fantôme (transparent, non-solide)
│   │   └── construction_crate/    # Caisse de matériaux (30 uses, 3D2D)
│   └── weapons/
│       └── weapon_construction.lua # SWEP du Constructeur
```

## Installation

Voir [docs/GUIDE_INSTALLATION.md](docs/GUIDE_INSTALLATION.md)

## Utilisation

Voir [docs/GUIDE_UTILISATEUR.md](docs/GUIDE_UTILISATEUR.md)

## Architecture

Voir [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## Avancement

| Jour | Tâche | État |
|------|-------|------|
| Jour 1 | Infrastructure Docker + DarkRP | ✅ |
| Jour 2 | Base de données MySQL (MySQLOO) | ✅ |
| Jour 3 | Système de sélection de props | ✅ |
| Jour 4 | Sauvegarde/Chargement blueprints | ✅ |
| Jour 5 | Interface utilisateur (Derma) | ✅ |
| Jour 6 | Permissions et partage | ✅ |
| Jour 7 | Logging et sécurité | ✅ |
| Jour 8 | Système de ghosts + caisses (v2.0) | ✅ |
| Jour 9 | Optimisation performance | ✅ |
| Jour 10 | Documentation et finalisation | ✅ |

## Configuration

Tout est configurable dans `sh_config.lua` :

```lua
ConstructionSystem.Config.MaxPropsPerBlueprint = 50
ConstructionSystem.Config.MaxBlueprintsPerPlayer = 20
ConstructionSystem.Config.CrateModel = "models/props_junk/wood_crate001a.mdl"
ConstructionSystem.Config.CrateMaxMaterials = 30
ConstructionSystem.Config.CratePrice = 1
ConstructionSystem.Config.SelectionRadius = 500
```

## Roadmap

- [ ] Paste à la position originale
- [ ] Preview du placement avant chargement
- [ ] Intégration camion simfphys (caisse transportable)
- [ ] Système de coûts configurable
- [ ] Blueprints publics / marketplace
