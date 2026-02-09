# RP Construction System

Système de construction collaboratif pour DarkRP. Les constructeurs sauvegardent des blueprints, les chargent en fantômes, et tous les joueurs peuvent matérialiser les constructions avec des caisses de matériaux.

## Fonctionnalités

- **Blueprints** : Sélectionnez vos props, sauvegardez en base de données, rechargez-les à tout moment
- **Ghosts** : Les blueprints se chargent en props fantômes (transparents, non-solides)
- **Caisses de matériaux** : Achetez des caisses (F4) pour matérialiser les fantômes en vrais props
- **Collaboratif** : N'importe quel joueur peut aider à construire avec une caisse
- **SWEP dédié** : Outil de construction avec sélection (LMB), sélection zone (RMB), menu (Shift+RMB)
- **Sécurité** : Blacklist d'entités, rate limiting, vérification CPPI, seuls les `prop_physics` sont autorisés
- **Permissions** : Partage de blueprints entre joueurs (vue/utilisation/édition)
- **MySQL** : Stockage persistant via MySQLOO

## Installation

### Prérequis
- Serveur Garry's Mod avec **DarkRP**
- **MySQLOO 9.x** (`gmsv_mysqloo_linux.dll` dans `lua/bin/`)
- Base de données **MySQL 5.7+** ou **8.0**

### Étapes
1. Placez le dossier `rp_construction_system` dans `garrysmod/addons/`
2. Configurez la connexion MySQL dans `lua/rp_construction/sh_config.lua`
3. Les tables sont créées automatiquement au premier lancement
4. Ajoutez le job Constructeur dans votre configuration DarkRP (voir ci-dessous)

### Configuration DarkRP

**Job Constructeur** (dans `darkrp_customthings/jobs.lua`) :
```lua
TEAM_BUILDER = DarkRP.createJob("Constructeur", {
    color = Color(0, 100, 200, 255),
    model = "models/player/hostage/hostage_04.mdl",
    description = "Construisez des batiments pour les citoyens.",
    weapons = {},  -- Le SWEP est géré par l'addon (voir sh_config.lua)
    command = "constructeur",
    max = 4,
    salary = 65,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Civil",
})
```

**Caisse de matériaux** (dans `darkrp_customthings/entities.lua`) :
```lua
DarkRP.createEntity("Caisse de Materiaux", {
    ent = "construction_crate",
    model = "models/props_junk/wood_crate001a.mdl",
    price = 1,
    max = 2,
    cmd = "buycrate",
    allowed = {TEAM_BUILDER},
    category = "Construction",
})
```

## Configuration

Toute la configuration se fait dans `lua/rp_construction/sh_config.lua` :

| Paramètre | Défaut | Description |
|---|---|---|
| `MaxPropsPerBlueprint` | `150` | Max props par blueprint (0 = illimité) |
| `MaxBlueprintsPerPlayer` | `0` | Max blueprints par joueur (0 = illimité) |
| `MaxCratesPerPlayer` | `2` | Max caisses simultanées par joueur |
| `CrateMaxMaterials` | `30` | Matériaux par caisse |
| `CratePrice` | `1` | Prix d'une caisse (F4) |
| `SWEPJobs` | `{TEAM_BUILDER}` | Jobs qui reçoivent le SWEP automatiquement |
| `AllowedJobs` | `nil` | Jobs autorisés (nil = tout le monde) |
| `SelectionRadiusDefault` | `500` | Rayon de sélection par défaut |
| `SelectionRadiusMax` | `1000` | Rayon maximum |
| `CrateModel` | `wood_crate001a` | Modèle de la caisse (fallback HL2) |

### Ajouter des jobs existants

Pour que vos jobs existants reçoivent le SWEP, modifiez `sh_config.lua` :
```lua
-- Un seul job
ConstructionSystem.Config.SWEPJobs = {TEAM_BUILDER}

-- Plusieurs jobs
ConstructionSystem.Config.SWEPJobs = {TEAM_BUILDER, TEAM_ARCHITECT, TEAM_ENGINEER}
```

### Changer la limite de props

```lua
ConstructionSystem.Config.MaxPropsPerBlueprint = 200  -- ou 0 pour illimité
```

## Utilisation

### Constructeur
1. Devenez **Constructeur** (F4)
2. Équipez l'**Outil de Construction**
3. **LMB** sur des props pour les sélectionner (halo bleu)
4. **RMB** pour sélectionner tous les props dans un rayon
5. **Shift+RMB** pour ouvrir le menu
6. Sauvegardez votre blueprint → Chargez-le en fantômes

### Tout joueur
1. Achetez une **Caisse de Matériaux** (F4 → Entities → Construction)
2. Appuyez **E** sur la caisse pour l'activer
3. Appuyez **E** sur les fantômes pour les matérialiser
4. Chaque matérialisation consomme 1 matériau de la caisse

## Architecture

```
rp_construction_system/
├── lua/
│   ├── autorun/
│   │   ├── server/sv_construction_init.lua    -- Point d'entrée serveur
│   │   └── client/cl_construction_init.lua    -- Point d'entrée client
│   ├── rp_construction/
│   │   ├── sh_config.lua          -- Configuration partagée
│   │   ├── sv_database.lua        -- MySQL (MySQLOO)
│   │   ├── sv_selection.lua       -- Sélection de props (serveur)
│   │   ├── sv_blueprints.lua      -- Save/Load/Delete blueprints
│   │   ├── sv_ghosts.lua          -- Spawn & matérialisation des fantômes
│   │   ├── sv_permissions.lua     -- Partage de blueprints
│   │   ├── sv_security.lua        -- Rate limiting, admin commands
│   │   ├── sv_logging.lua         -- Logs serveur
│   │   ├── cl_selection.lua       -- Halos & HUD sélection (client)
│   │   └── cl_menu.lua            -- Interface Derma (client)
│   ├── weapons/
│   │   └── weapon_construction.lua -- SWEP Outil de Construction
│   └── entities/
│       ├── construction_ghost/     -- Entité fantôme (transparent, non-solide)
│       └── construction_crate/     -- Caisse de matériaux
└── README.md
```

## Base de données

3 tables créées automatiquement :
- `blueprints` — Données des blueprints (compressées)
- `blueprint_permissions` — Partage entre joueurs
- `blueprint_logs` — Historique des actions

## Licence

MIT
