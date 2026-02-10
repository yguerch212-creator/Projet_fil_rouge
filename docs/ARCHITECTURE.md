# 🏗️ Architecture Technique — RP Construction System v2.2

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                       CLIENT (Joueur)                           │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ cl_selection  │  │   cl_menu    │  │  cl_placement      │   │
│  │ (halos/HUD)  │  │ (Derma UI)   │  │  (ghost preview)   │   │
│  └──────┬───────┘  └──────┬───────┘  └────────┬───────────┘   │
│         │                 │                    │               │
│  ┌──────┴─────────┐  ┌───┴────────────┐                      │
│  │ cl_blueprints  │  │ cl_ad2_decoder │                      │
│  │ (local save)   │  │ (import AD2)   │                      │
│  └────────────────┘  └────────────────┘                      │
│                                                                 │
│  Stockage: data/construction_blueprints/*.dat (JSON local)     │
└───────────────────────┬─────────────────────────────────────────┘
                        │  NET MESSAGES (rate limited, validated)
┌───────────────────────┴─────────────────────────────────────────┐
│                       SERVEUR (GMod)                            │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ sv_selection  │  │sv_blueprints │  │   sv_ghosts        │   │
│  │ (CPPI/owner) │  │ (serialize)  │  │ (spawn/materialize)│   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ sv_security   │  │ sv_database  │  │   sv_logging       │   │
│  │ (rate limit)  │  │ (MySQLOO)    │  │  (console + DB)    │   │
│  └──────────────┘  └──────┬───────┘  └────────────────────┘   │
│                            │                                    │
│  Entités: construction_ghost | construction_crate (x2)         │
│  SWEP: weapon_construction                                      │
│  Config: sh_config.lua (partagé client+serveur)                │
└────────────────────────────┼────────────────────────────────────┘
                             │
                      ┌──────┴──────┐
                      │  MySQL 8.0  │
                      │ (optionnel) │
                      └─────────────┘
```

## Structure des fichiers

```
rp_construction_system/
├── lua/
│   ├── autorun/
│   │   ├── client/
│   │   │   └── cl_construction_init.lua    — Init client, includes
│   │   └── server/
│   │       ├── sv_construction_init.lua    — Init serveur, net strings, jobs
│   │       └── sv_admin_setup.lua          — Superadmin auto-config
│   ├── rp_construction/
│   │   ├── sh_config.lua          — Config partagée (limites, jobs, DB, net)
│   │   ├── sv_blueprints.lua      — Serialize/Deserialize, validation, RebuildVectors
│   │   ├── sv_ghosts.lua          — Spawn/remove ghost entities, matérialisation
│   │   ├── sv_selection.lua       — Toggle/radius/clear, vérification CPPI
│   │   ├── sv_permissions.lua     — Partage blueprints entre joueurs
│   │   ├── sv_security.lua        — Rate limiting (60 req/min), job check
│   │   ├── sv_logging.lua         — Logs console + DB optionnelle
│   │   ├── sv_database.lua        — MySQLOO connection, CRUD, prepared statements
│   │   ├── cl_blueprints.lua      — Stockage local data/, dossiers, CRUD fichiers
│   │   ├── cl_ad2_decoder.lua     — Décodeur binaire AD2 rev4/5 embarqué
│   │   ├── cl_menu.lua            — Interface Derma complète (sidebar, breadcrumb)
│   │   ├── cl_placement.lua       — ClientsideModel preview, rotation, hauteur
│   │   └── cl_selection.lua       — Rendu halos bleus, HUD compteur
│   ├── entities/
│   │   ├── construction_ghost/    — Fantôme holographique (SOLID_NONE, bleu)
│   │   │   ├── shared.lua
│   │   │   ├── init.lua           — Matérialisation, timer auto-remove
│   │   │   └── cl_init.lua        — Rendu translucide bleu
│   │   ├── construction_crate/    — Grosse caisse (50 matériaux)
│   │   │   ├── shared.lua
│   │   │   ├── init.lua           — Use, LoadCrate, UnloadCrate, Think auto-detect
│   │   │   └── cl_init.lua        — 3D2D horizontal (barre, compteur)
│   │   └── construction_crate_small/ — Petite caisse (15 matériaux)
│   │       ├── shared.lua
│   │       ├── init.lua           — Même logique que grosse caisse
│   │       └── cl_init.lua        — 3D2D adapté
│   └── weapons/
│       └── weapon_construction.lua — SWEP: LMB sel, RMB zone, Shift+RMB menu, R véhicule
├── models/                         — Modèles custom (viewmodel, caisses)
├── materials/                      — Textures des modèles
└── sql/
    └── schema.sql                  — Schéma DB optionnel (logs, futur sharing)
```

## Entités custom

| Entité | Type | Solid | Rôle |
|--------|------|-------|------|
| `construction_ghost` | Scripted | SOLID_NONE | Fantôme holographique bleu, matérialisable par Use + caisse |
| `construction_crate` | DarkRP Entity | SOLID_VPHYSICS | Grosse caisse 50 matériaux, transportable en véhicule |
| `construction_crate_small` | DarkRP Entity | SOLID_VPHYSICS | Petite caisse 15 matériaux |
| `weapon_construction` | SWEP | — | Outil du Constructeur, distribué automatiquement au job |

## Flux de données

### 1. Sauvegarde d'un blueprint

```
Joueur sélectionne props (LMB/RMB) → cl_selection halos
    ↓
Shift+RMB → cl_menu.lua → onglet Sauvegarder
    ↓
Client envoie "Construction_SaveBlueprint" (nom, desc, dossier)
    ↓
sv_security: rate limit check → sv_blueprints: Serialize()
    ↓
Serialize: position relative au HeadEnt, modèle, angles, physique
    ↓
Serveur envoie "Construction_SaveToClient" (données JSON)
    ↓
cl_blueprints: file.Write("construction_blueprints/nom.dat", json)
```

### 2. Chargement d'un blueprint

```
cl_menu → sélectionne blueprint → cl_blueprints: file.Read()
    ↓
Client envoie "Construction_LoadBlueprint" (données JSON)
    ↓
sv_security: rate limit → sv_blueprints: ValidateBlueprintData()
    ↓
Validation: classes autorisées, nombre props, données cohérentes
    ↓
sv_blueprints: RebuildVectors() (string "x y z" → Vector)
    ↓
Serveur envoie "Construction_SendPreview" → client
    ↓
cl_placement: preview holographique (ClientsideModels)
    ↓
Joueur confirme (LMB) → "Construction_ConfirmPlacement"
    ↓
sv_ghosts: SpawnGhosts() → construction_ghost entities
```

### 3. Matérialisation

```
Joueur Use (E) sur caisse → caisse.ActiveCrate = self
    ↓
Joueur Use (E) sur ghost → "Construction_MaterializeGhost"
    ↓
sv_ghosts: vérification ActiveCrate IsValid + matériaux > 0
    ↓
crate:UseMaterial() → materials -= 1
    ↓
ghost:Materialize() → spawn prop_physics réel, remove ghost
```

### 4. Véhicule (chargement/déchargement)

```
CHARGEMENT (automatique via Think):
Joueur physgun caisse sur véhicule → SetParent() par engine
    ↓
construction_crate:Think() (toutes les 0.5s)
    ↓
Détecte parent = gmod_sent_vehicle_fphysics_base + pas loaded
    ↓
LoadCrate(): phys:EnableMotion(false), SOLID_NONE, SetLocalPos(offset)
    ↓
NWBool "IsLoaded" = true → client cache 3D2D

DÉCHARGEMENT (touche R via net message):
Client SWEP:Reload() → net "Construction_VehicleReload"
    ↓
Serveur: trace → trouve véhicule → cherche caisse loaded dessus
    ↓
UnloadCrate(): SetParent(nil), timer.Simple(0) → SetPos(dropPos)
    ↓
Restore: SOLID_VPHYSICS, phys:EnableMotion(true), phys:Wake()
```

## Net messages

| Message | Direction | Données | Description |
|---------|-----------|---------|-------------|
| `Construction_OpenMenu` | S → C | — | Force l'ouverture du menu |
| `Construction_SaveBlueprint` | C → S | nom, desc, dossier | Demande sérialisation |
| `Construction_SaveToClient` | S → C | JSON compressé | Données pour stockage local |
| `Construction_LoadBlueprint` | C → S | JSON du blueprint | Envoi pour validation |
| `Construction_SelectToggle` | C → S | Entity | Toggle sélection d'un prop |
| `Construction_SelectRadius` | C → S | Vector, UInt(10) | Sélection par rayon |
| `Construction_SelectClear` | C → S | — | Vider la sélection |
| `Construction_RequestSync` | C → S | — | Demande sync sélection |
| `Construction_SyncSelection` | S → C | Table d'entities | Liste props sélectionnés |
| `Construction_SendPreview` | S → C | Données validées | Preview pour placement |
| `Construction_ConfirmPlacement` | C → S | Vector, Angle | Position finale confirmée |
| `Construction_CancelPlacement` | C → S | — | Annuler le placement |
| `Construction_MaterializeGhost` | C → S | Entity ghost | Matérialiser un fantôme |
| `Construction_VehicleReload` | C → S | — | R: décharger véhicule ou clear |

## Base de données (optionnelle)

Le système fonctionne **entièrement sans DB**. Les blueprints sont stockés localement côté client.

La DB optionnelle (MySQL 8.0 via MySQLOO) fournit :

### Tables

**`blueprint_logs`** — Historique des actions
| Colonne | Type | Description |
|---------|------|-------------|
| id | INT AUTO_INCREMENT | ID unique |
| steamid | VARCHAR(32) | SteamID de l'acteur |
| player_name | VARCHAR(64) | Nom du joueur |
| action | ENUM | save, load, delete, share |
| blueprint_name | VARCHAR(100) | Nom du blueprint |
| details | TEXT | Détails additionnels |
| created_at | TIMESTAMP | Date de l'action |

**`shared_blueprints`** et **`blueprint_permissions`** — Prévu pour le futur système de partage serveur.

### Connexion

```lua
-- sh_config.lua
ConstructionSystem.Config.DB = {
    Host = "gmod-mysql",  -- Hostname Docker
    Port = 3306,
    User = "gmod_user",
    Password = "...",
    Database = "gmod_construction",
}
```

Connexion via `InitPostEntity` + 5s delay + fallback 30s.

## Sécurité

| Mesure | Implémentation |
|--------|---------------|
| Rate Limiting | Cooldowns par action (save 10s, load 15s) + 60 req/min global |
| SQL Injection | Prepared statements MySQLOO exclusivement |
| Input Validation | Longueur strings, clamp nombres, classes autorisées |
| Ownership | CPPI via CPPIGetOwner() — compatible FPP |
| Blacklist | Classes interdites (money_printer, drug_lab, etc.) |
| Job Restrictions | AllowedJobs, SWEPJobs, CrateAllowedJobs configurables |
| Client/Serveur | Aucune confiance client — tout re-validé serveur |
