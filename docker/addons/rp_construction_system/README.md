# RP Construction System

Système de construction collaboratif pour Garry's Mod DarkRP. Les constructeurs sauvegardent des blueprints localement, les chargent en fantômes via un système de placement avancé, et tous les joueurs peuvent matérialiser les constructions avec des caisses de matériaux.

## Fonctionnalités

- **Blueprints locaux** : Sauvegarde illimitée dans `data/construction_blueprints/` (côté client)
- **Placement avancé** : Preview holographique avec panneau de contrôle complet (style AdvDupe2)
  - Offsets X/Y/Z, rotation Pitch/Yaw/Roll
  - Option "Position originale" pour recoller au même endroit
  - Opacité et vitesse des fantômes configurables
  - Options de collage (constraints, parenting, freeze state)
- **Ghosts collaboratifs** : Les blueprints se chargent en props fantômes (transparents, non-solides)
- **Caisses de matériaux** : Achetez des caisses (F4) pour matérialiser les fantômes en vrais props
- **SWEP dédié** : Outil de construction avec sélection (LMB), sélection zone (RMB), menu (Shift+RMB)
- **Sécurité** : Validation serveur stricte (blacklist d'entités, limite props, vérification classes)
- **MySQL optionnel** : Logs d'activité et futur système de partage (schéma fourni dans `sql/`)

## Prérequis

- Serveur Garry's Mod avec **DarkRP**
- **MySQLOO 9.x** (optionnel, pour les logs serveur)
- Base de données **MySQL 5.7+** ou **MariaDB 10.2+** (optionnel)

## Installation

1. Placez le dossier `rp_construction_system` dans `garrysmod/addons/`
2. *(Optionnel)* Configurez MySQL dans `lua/rp_construction/sh_config.lua`
3. *(Optionnel)* Exécutez `sql/schema.sql` pour créer les tables de logs
4. Ajoutez le job et l'entité dans votre configuration DarkRP (voir ci-dessous)
5. Redémarrez le serveur

### Configuration DarkRP

**Job Constructeur** (dans `darkrp_customthings/jobs.lua`) :
```lua
TEAM_BUILDER = DarkRP.createJob("Constructeur", {
    color = Color(0, 100, 200, 255),
    model = "models/player/hostage/hostage_04.mdl",
    description = "Construisez des batiments pour les citoyens.",
    weapons = {"weapon_construction"},
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

## Configuration serveur

Toute la configuration se fait dans `lua/rp_construction/sh_config.lua` :

| Paramètre | Défaut | Description |
|---|---|---|
| `MaxPropsPerBlueprint` | `150` | Max props par blueprint (0 = illimité) |
| `MaxCratesPerPlayer` | `2` | Max caisses simultanées par joueur |
| `CrateMaxMaterials` | `30` | Matériaux par caisse |
| `CratePrice` | `1` | Prix d'une caisse (F4) |
| `SelectionRadiusDefault` | `500` | Rayon de sélection par défaut |
| `SelectionRadiusMax` | `1000` | Rayon maximum autorisé |
| `CrateModel` | `wood_crate001a` | Modèle de la caisse (HL2) |
| `SaveCooldown` | `10` | Cooldown sauvegarde (secondes) |
| `LoadCooldown` | `15` | Cooldown chargement (secondes) |

### Ajouter des jobs

Ajoutez `"weapon_construction"` dans le champ `weapons` de n'importe quel job DarkRP existant :
```lua
weapons = {"weapon_construction"},
```

### Changer la limite de props

```lua
ConstructionSystem.Config.MaxPropsPerBlueprint = 200  -- ou 0 pour illimité
```

### Sécurité

Le serveur **valide chaque blueprint** reçu du client :
- Seuls les `prop_physics` sont autorisés
- Blacklist d'entités (money printers, armes, shipments...)
- Limite de taille : 512 KB max par blueprint
- Limite de distance : 5000 unités max du joueur pour le placement
- Rate limiting sur les sauvegardes et chargements

**Aucune donnée client ne modifie la configuration serveur.** Les préférences (rayon de sélection, opacité fantômes) restent 100% côté client.

## Utilisation

### Constructeur
1. Devenez **Constructeur** (F4)
2. Équipez l'**Outil de Construction**
3. **LMB** sur des props pour les sélectionner (halo bleu)
4. **RMB** pour sélectionner tous les props dans un rayon
5. **Shift+RMB** pour ouvrir le menu
6. Onglet **Sauvegarder** → donnez un nom → sauvegarde locale
7. Onglet **Blueprints** → sélectionnez → **Charger**

### Placement
1. Après chargement, un panneau de placement apparaît à droite
2. **Appuyez F3** pour libérer la souris
3. Réglez les offsets (X/Y/Z, rotation) via les sliders
4. Cochez "Position originale" pour recoller au même endroit
5. Cliquez **Confirmer** dans le panneau
6. Les fantômes apparaissent à la position confirmée

### Construction collaborative
1. Le constructeur charge un blueprint (fantômes bleus)
2. N'importe quel joueur achète une **Caisse de Matériaux** (F4 → Entities)
3. **E** sur la caisse pour l'activer
4. **E** sur les fantômes pour les matérialiser en vrais props
5. Chaque matérialisation consomme 1 matériau

## Architecture

```
rp_construction_system/
├── lua/
│   ├── autorun/
│   │   ├── server/sv_construction_init.lua    -- Point d'entrée serveur
│   │   └── client/cl_construction_init.lua    -- Point d'entrée client
│   ├── rp_construction/
│   │   ├── sh_config.lua          -- Configuration partagée
│   │   ├── sv_database.lua        -- MySQL (MySQLOO) - optionnel
│   │   ├── sv_selection.lua       -- Sélection de props (serveur)
│   │   ├── sv_blueprints.lua      -- Sérialisation, validation, spawn ghosts
│   │   ├── sv_ghosts.lua          -- Gestion des groupes de fantômes
│   │   ├── sv_permissions.lua     -- Partage de blueprints (futur)
│   │   ├── sv_security.lua        -- Rate limiting, commandes admin
│   │   ├── sv_logging.lua         -- Logs serveur
│   │   ├── cl_blueprints.lua      -- Stockage local (data/)
│   │   ├── cl_selection.lua       -- Halos & HUD sélection
│   │   ├── cl_menu.lua            -- Interface principale (Derma)
│   │   └── cl_placement.lua       -- Système de placement + panneau
│   ├── weapons/
│   │   └── weapon_construction.lua -- SWEP Outil de Construction
│   └── entities/
│       ├── construction_ghost/     -- Entité fantôme
│       └── construction_crate/     -- Caisse de matériaux
├── sql/
│   └── schema.sql                 -- Schéma MySQL (optionnel)
└── README.md
```

### Séparation Client / Serveur

| Composant | Client | Serveur |
|---|---|---|
| Sauvegardes | ✅ Stockage local `data/` | Sérialise les props |
| Chargement | Lit fichier local, envoie | ✅ Valide + spawne ghosts |
| Placement | ✅ Preview, offsets, UI | Reçoit position finale |
| Sélection | Halos visuels | ✅ Tracking des entités |
| Rayon sélection | ✅ Préférence locale | Clampé par config |
| Sécurité | — | ✅ Blacklist, limites, rate limit |

## Base de données (optionnel)

Le schéma SQL est fourni dans `sql/schema.sql`. Il crée 3 tables :
- `blueprint_logs` — Historique des actions (save/load)
- `shared_blueprints` — Blueprints partagés (futur)
- `blueprint_permissions` — Permissions de partage (futur)

Le script est **safe à exécuter** sur une base existante (`IF NOT EXISTS`).

## Crédits

- Panneau de placement inspiré d'[Advanced Duplicator 2](https://github.com/wiremod/advdupe2) (Apache 2.0)
- Développé pour Garry's Mod / DarkRP

## Licence

MIT
