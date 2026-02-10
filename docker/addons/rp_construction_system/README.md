# RP Construction System

Addon Garry's Mod pour DarkRP — système de construction collaboratif par blueprints.

Un Constructeur sélectionne des props, sauvegarde un blueprint, le place comme fantômes holographiques, puis n'importe quel joueur peut matérialiser les fantômes avec des caisses de matériaux.

## Fonctionnalités

- **SWEP Construction** — outil dédié pour sélectionner, sauvegarder et placer des blueprints
- **Blueprints locaux** — sauvegardés côté client dans `garrysmod/data/construction_blueprints/`, illimité
- **Dossiers** — organisez vos blueprints en sous-dossiers (comme AdvDupe2)
- **Compatible AdvDupe2** — importez vos fichiers `.txt` AdvDupe2 en les copiant dans le dossier blueprints
- **Placement avancé** — prévisualisation holographique, rotation molette, ajustement hauteur, position originale
- **Construction collaborative** — les fantômes sont visibles par tous, n'importe qui avec une caisse peut matérialiser
- **Caisses de matériaux** — entité DarkRP achetable au F4, nécessaire pour matérialiser les fantômes
- **Interface moderne** — UI dark avec sidebar, navigation par dossiers, badges AD2, breadcrumb
- **Sécurité** — rate limiting, validation serveur, blacklist de classes, vérification des jobs

## Installation

### Workshop (recommandé)
1. Ajoutez l'addon à votre collection Workshop
2. Ajoutez la collection à votre serveur via `host_workshop_collection`

### Manuel
1. Copiez le dossier `rp_construction_system` dans `garrysmod/addons/`
2. Redémarrez le serveur

### Configuration DarkRP
Ajoutez le job Constructeur dans `darkrpmodification/lua/darkrp_customthings/jobs.lua` :
```lua
TEAM_BUILDER = DarkRP.createJob("Constructeur", {
    color = Color(0, 153, 204),
    model = "models/player/hostage/hostage_04.mdl",
    description = "Construisez des structures pour la ville.",
    weapons = {"weapon_construction"},
    command = "constructeur",
    max = 3,
    salary = 65,
    admin = 0,
    vote = false,
    category = "Citoyens",
})
```

Ajoutez la caisse dans `darkrpmodification/lua/darkrp_customthings/entities.lua` :
```lua
DarkRP.createEntity("Caisse de Matériaux", {
    ent = "construction_crate",
    model = "models/props_junk/wood_crate001a.mdl",
    price = 500,
    max = 2,
    cmd = "buycrate",
    category = "Construction",
})
```

## Utilisation

### Sélection (SWEP)
| Action | Commande |
|--------|----------|
| Sélectionner/Désélectionner un prop | LMB (clic gauche) |
| Sélectionner par rayon | RMB (clic droit) |
| Vider la sélection | R (reload) |
| Ouvrir le menu | Shift + RMB |

### Sauvegarde & Chargement
1. Sélectionnez vos props avec le SWEP
2. Ouvrez le menu → onglet **Sauvegarder**
3. Nommez votre blueprint → **Sauvegarder**
4. Pour charger : onglet **Blueprints** → sélectionnez → **Charger**

### Placement
| Action | Commande |
|--------|----------|
| Rotation | Molette |
| Ajuster hauteur | Shift + Molette |
| Confirmer | LMB |
| Annuler | RMB ou Échap |
| Position originale | Checkbox dans le panneau |

### Construction
1. Le Constructeur place un blueprint (fantômes holographiques)
2. Un joueur achète une **Caisse de Matériaux** (F4 → Entities)
3. Appuyez **E** sur la caisse pour l'activer
4. Appuyez **E** sur les fantômes pour les matérialiser en vrais props

## Stockage des blueprints

Les blueprints sont sauvegardés **localement** sur le PC du joueur :
```
garrysmod/data/construction_blueprints/
├── ma_maison.dat
├── garage.dat
├── bases/
│   ├── base_militaire.dat
│   └── bunker.dat
└── imports/
    └── mon_dupe_ad2.txt    ← fichier AdvDupe2 importé
```

- Format natif : `.dat` (JSON lisible)
- Sous-dossiers supportés pour l'organisation
- Pas de limite de sauvegardes

## Compatibilité AdvDupe2

Les fichiers `.txt` d'AdvDupe2 sont **directement compatibles** :

1. Allez dans `garrysmod/data/advdupe2/`
2. Copiez vos fichiers `.txt`
3. Collez-les dans `garrysmod/data/construction_blueprints/` (ou un sous-dossier)
4. Ils apparaissent automatiquement dans le menu avec un badge orange **AD2**
5. Le chargement convertit automatiquement le format AD2 vers notre système
6. La **Position originale** est préservée — le blueprint se place exactement là où il a été sauvegardé dans AD2

> Le décodeur AD2 est embarqué dans l'addon — pas besoin d'avoir AdvDupe2 installé sur le serveur.
> Basé sur le codec AdvDupe2 ([Apache 2.0](https://github.com/wiremod/advdupe2) — wiremod/advdupe2).

## Configuration

Tout se configure dans `lua/rp_construction/sh_config.lua` :

| Option | Défaut | Description |
|--------|--------|-------------|
| `MaxPropsPerBlueprint` | 150 | Limite de props par blueprint |
| `MaxCratesPerPlayer` | 2 | Nombre max de caisses par joueur |
| `CrateMaxMaterials` | 30 | Matériaux par caisse |
| `SelectionRadiusDefault` | 500 | Rayon de sélection par défaut |
| `SWEPJobs` | `{"constructeur"}` | Jobs autorisés à utiliser le SWEP |
| `CrateModel` | `wood_crate001a.mdl` | Modèle de la caisse (configurable) |

## Architecture

```
rp_construction_system/
├── lua/
│   ├── autorun/
│   │   ├── client/cl_construction_init.lua
│   │   └── server/sv_construction_init.lua
│   ├── rp_construction/
│   │   ├── sh_config.lua          — Configuration partagée
│   │   ├── sv_blueprints.lua      — Sérialisation & validation
│   │   ├── sv_ghosts.lua          — Gestion des fantômes
│   │   ├── sv_selection.lua       — Sélection serveur
│   │   ├── sv_permissions.lua     — Partage blueprints
│   │   ├── sv_security.lua        — Rate limiting & sécurité
│   │   ├── sv_logging.lua         — Logs serveur
│   │   ├── sv_database.lua        — MySQL (optionnel)
│   │   ├── cl_blueprints.lua      — Stockage local + import AD2
│   │   ├── cl_ad2_decoder.lua     — Décodeur AdvDupe2 embarqué
│   │   ├── cl_menu.lua            — Interface Derma
│   │   ├── cl_placement.lua       — Prévisualisation placement
│   │   └── cl_selection.lua       — Rendu sélection (halos)
│   ├── entities/
│   │   ├── construction_ghost/    — Entité fantôme
│   │   └── construction_crate/    — Caisse de matériaux
│   └── weapons/
│       └── weapon_construction.lua — SWEP Construction
└── sql/
    └── schema.sql                 — Schéma DB optionnel (logs)
```

## Base de données (optionnel)

Le système fonctionne **sans base de données**. Le schéma SQL dans `sql/schema.sql` est optionnel et sert uniquement pour les logs serveur et un futur système de partage entre joueurs.

## Crédits

- Décodeur AdvDupe2 basé sur [wiremod/advdupe2](https://github.com/wiremod/advdupe2) (Apache 2.0)
- Panel de placement inspiré par l'interface AdvDupe2

## Licence

MIT
