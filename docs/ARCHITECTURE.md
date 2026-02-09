# Architecture Technique

## Vue d'ensemble

Le système de construction RP est un addon Garry's Mod intégré à DarkRP, utilisant une base de données MySQL pour la persistance des blueprints.

```
┌──────────────────────────────────────────────────────┐
│                    CLIENT (Joueur)                      │
│                                                         │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  │
│  │ cl_selection │  │  cl_menu    │  │  STOOL        │  │
│  │ (halo/HUD)  │  │  (Derma UI) │  │ (tool gun)   │  │
│  └──────┬──────┘  └──────┬──────┘  └──────┬───────┘  │
│         │                │                 │           │
└─────────┼────────────────┼─────────────────┼───────────┘
          │        NET MESSAGES              │
          │    (rate limited, validated)      │
┌─────────┼────────────────┼─────────────────┼───────────┐
│         ▼                ▼                 ▼           │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  │
│  │ sv_selection │  │sv_blueprints│  │ sv_security  │  │
│  │ (CPPI/owner)│  │(serialize)  │  │ (rate limit) │  │
│  └─────────────┘  └──────┬──────┘  └──────────────┘  │
│                          │                             │
│  ┌───────────────┐  ┌────▼──────┐  ┌──────────────┐  │
│  │sv_permissions │  │sv_database│  │  sh_config   │  │
│  │ (partage)     │  │ (MySQLOO) │  │ (partagé)    │  │
│  └───────────────┘  └────┬──────┘  └──────────────┘  │
│                          │                             │
│                   SERVER (GMod)                         │
└──────────────────────────┼─────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │   MySQL 8.0 │
                    │  (Docker)   │
                    └─────────────┘
```

## Structure des fichiers

```
rp_construction_system/
├── lua/
│   ├── autorun/
│   │   ├── server/
│   │   │   ├── sv_construction_init.lua    -- Point d'entrée serveur
│   │   │   └── sv_admin_setup.lua          -- Configuration superadmin
│   │   └── client/
│   │       └── cl_construction_init.lua    -- Point d'entrée client
│   ├── rp_construction/
│   │   ├── sh_config.lua                   -- Configuration partagée
│   │   ├── sv_database.lua                 -- Module MySQL (MySQLOO)
│   │   ├── sv_selection.lua                -- Gestion sélection serveur
│   │   ├── sv_blueprints.lua               -- Save/Load blueprints
│   │   ├── sv_permissions.lua              -- Partage entre joueurs
│   │   ├── sv_security.lua                 -- Sécurité et logging
│   │   ├── cl_selection.lua                -- Rendu visuel sélection
│   │   └── cl_menu.lua                     -- Interface Derma
│   └── weapons/
│       └── gmod_tool/
│           └── stools/
│               └── construction_select.lua -- STOOL sélection
```

## Base de données

### Table `blueprints`
| Colonne | Type | Description |
|---------|------|-------------|
| id | INT AUTO_INCREMENT | Identifiant unique |
| owner_steamid | VARCHAR(32) | SteamID du créateur |
| owner_name | VARCHAR(64) | Nom du créateur |
| name | VARCHAR(100) | Nom du blueprint |
| description | TEXT | Description |
| data | LONGTEXT | Données sérialisées (JSON compressé base64) |
| prop_count | INT | Nombre de props |
| constraint_count | INT | Nombre de constraints |
| is_public | TINYINT(1) | Blueprint public ou privé |
| created_at | TIMESTAMP | Date de création |
| updated_at | TIMESTAMP | Dernière modification |

### Table `blueprint_permissions`
| Colonne | Type | Description |
|---------|------|-------------|
| id | INT AUTO_INCREMENT | Identifiant unique |
| blueprint_id | INT | FK vers blueprints |
| target_steamid | VARCHAR(32) | SteamID du bénéficiaire |
| permission_level | ENUM | view, use, edit |
| granted_by | VARCHAR(32) | SteamID du donneur |
| granted_at | TIMESTAMP | Date d'attribution |

### Table `blueprint_logs`
| Colonne | Type | Description |
|---------|------|-------------|
| id | INT AUTO_INCREMENT | Identifiant unique |
| steamid | VARCHAR(32) | SteamID de l'acteur |
| player_name | VARCHAR(64) | Nom du joueur |
| action | ENUM | save, load, delete, share, unshare |
| blueprint_id | INT | Blueprint concerné |
| blueprint_name | VARCHAR(100) | Nom du blueprint |
| details | TEXT | Détails additionnels |
| created_at | TIMESTAMP | Date de l'action |

## Flux de données

### Sauvegarde d'un blueprint
1. Le joueur sélectionne des props avec le STOOL
2. Il ouvre le menu Derma et remplit le formulaire
3. Le client envoie `Construction_SaveBlueprint` (nom, description)
4. Le serveur vérifie : rate limit → job autorisé → argent → limites
5. `Serialize()` : copie les props (position relative, modèle, physique, constraints)
6. Compression : `util.TableToJSON()` → `util.Compress()` → `util.Base64Encode()`
7. `SaveBlueprint()` : INSERT en MySQL avec prepared statement
8. Log de l'action dans `blueprint_logs`

### Chargement d'un blueprint
1. Le joueur sélectionne un blueprint dans la liste
2. Le client envoie `Construction_LoadBlueprint` (ID)
3. Le serveur vérifie : rate limit → ownership/permissions → argent
4. `LoadBlueprint()` : SELECT en MySQL
5. `Deserialize()` : décode base64 → décompresse → parse JSON
6. Batch spawning : 5 props par tick via `timer.Create()`
7. Application des constraints (Weld, NoCollide)
8. Enregistrement dans le système Undo de GMod

## Sécurité

| Mesure | Implémentation |
|--------|---------------|
| SQL Injection | Prepared statements (MySQLOO) |
| Rate Limiting | Cooldowns par action + limite globale 60 req/min |
| Ownership | CPPI (FPP compatible) |
| Input Validation | Sanitization des strings, clamp des nombres |
| Access Control | Vérification permissions à chaque requête |
| Anti-Abuse | Restrictions par job, distance max, limites de props |
