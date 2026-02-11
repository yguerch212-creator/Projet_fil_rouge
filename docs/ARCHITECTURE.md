# 🏗️ Architecture Technique — RP Construction System v2.2

> 🔗 **[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3664157203)** — Addon publié (ID 3664157203)

---

## 📋 Table des matières

- [Vue d'ensemble](#vue-densemble)
- [Deux versions](#deux-versions)
- [Structure des fichiers](#structure-des-fichiers)
- [Entités custom](#entités-custom)
- [SWEP weapon_construction](#swep-weapon_construction)
- [Flux de données](#flux-de-données)
- [Net messages](#net-messages)
- [Base de données (optionnelle)](#base-de-données-optionnelle)
- [Sécurité](#sécurité)

---

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
│  ┌──────┴─────────┐  ┌───┴────────────┐  ┌───┴────────────┐  │
│  │ cl_blueprints  │  │ cl_ad2_decoder │  │  cl_vehicles   │  │
│  │ (local save)   │  │ (import AD2)   │  │ (HUD véhicule) │  │
│  └────────────────┘  └────────────────┘  └────────────────┘  │
│                                                                 │
│  Stockage: data/construction_blueprints/*.dat (JSON local)     │
└───────────────────────┬─────────────────────────────────────────┘
                        │  NET MESSAGES (16 types, rate limited)
┌───────────────────────┴─────────────────────────────────────────┐
│                       SERVEUR (GMod)                            │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ sv_selection  │  │sv_blueprints │  │   sv_ghosts        │   │
│  │ (CPPI/owner) │  │ (serialize)  │  │ (spawn/materialize)│   │
│  └──────────────┘  └──────────────┘  └────────────────────┘   │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │ sv_security   │  │ sv_vehicles  │  │   sv_database      │   │
│  │ (rate limit)  │  │ (simfphys)   │  │ (MySQLOO, opt.)    │   │
│  └──────────────┘  └──────────────┘  └────────┬───────────┘   │
│                                                │               │
│  ┌──────────────┐  ┌──────────────┐            │               │
│  │ sv_logging    │  │sv_permissions│            │               │
│  │ (console+DB) │  │ (partage)    │            │               │
│  └──────────────┘  └──────────────┘            │               │
│                                                │               │
│  Entités: construction_ghost | construction_crate (x2)         │
│  SWEP: weapon_construction                                      │
│  Config: sh_config.lua (partagé client+serveur)                │
└────────────────────────────────────────────────┼───────────────┘
                                                 │
                                          ┌──────┴──────┐
                                          │  MySQL 8.0  │
                                          │ (optionnel) │
                                          └─────────────┘
```

---

## Deux versions

L'addon existe en deux versions, avec des fichiers différents :

| Fichier | Dev | Workshop | Rôle |
|---------|-----|----------|------|
| `sv_database.lua` | ✅ | ❌ | Connexion MySQLOO, CRUD, prepared statements |
| `sv_admin_setup.lua` | ✅ | ❌ | Auto-configuration superadmin au premier lancement |
| `sql/schema.sql` | ✅ | ❌ | Schéma MySQL (tables logs, sharing, permissions) |
| `sh_config.lua` | Section DB | Pas de section DB | Configuration partagée |
| Viewmodel | `c_slam.mdl` (fallback) | `v_fortnite_builder.mdl` | Modèle première personne du SWEP |

Tous les autres fichiers (15 modules Lua, 3 entités, SWEP) sont **identiques** entre les deux versions.

---

## Structure des fichiers

```
rp_construction_system/
├── addon.json                          — Métadonnées Workshop (titre, tags, ignore)
├── lua/
│   ├── autorun/
│   │   ├── client/
│   │   │   └── cl_construction_init.lua    — Init client, includes des modules cl_
│   │   └── server/
│   │       ├── sv_construction_init.lua    — Init serveur, net strings, includes sv_
│   │       └── sv_admin_setup.lua          — [DEV] Superadmin auto-config
│   ├── rp_construction/
│   │   ├── sh_config.lua          — Config partagée (limites, jobs, DB, sécurité)
│   │   │
│   │   │  — SERVEUR —
│   │   ├── sv_blueprints.lua      — Serialize/Deserialize, validation, RebuildVectors
│   │   ├── sv_ghosts.lua          — Spawn/remove ghost entities, matérialisation
│   │   ├── sv_selection.lua       — Toggle/radius/clear, vérification CPPI ownership
│   │   ├── sv_vehicles.lua        — Attach/detach caisses sur véhicules simfphys/LVS
│   │   ├── sv_permissions.lua     — Partage blueprints entre joueurs
│   │   ├── sv_security.lua        — Rate limiting (60 req/min), job check, validation
│   │   ├── sv_logging.lua         — Logs console + DB optionnelle
│   │   ├── sv_database.lua        — [DEV] MySQLOO connection, CRUD, prepared statements
│   │   │
│   │   │  — CLIENT —
│   │   ├── cl_blueprints.lua      — Stockage local data/, dossiers, CRUD fichiers
│   │   ├── cl_ad2_decoder.lua     — Décodeur binaire AdvDupe2 rev4/5 embarqué
│   │   ├── cl_menu.lua            — Interface Derma complète (sidebar, breadcrumb, badges)
│   │   ├── cl_placement.lua       — ClientsideModel preview, rotation, hauteur
│   │   ├── cl_selection.lua       — Rendu halos bleus, HUD compteur
│   │   └── cl_vehicles.lua        — HUD véhicule, PlayerBindPress reload
│   │
│   ├── entities/
│   │   ├── construction_ghost/        — Fantôme holographique (SOLID_NONE, bleu)
│   │   │   ├── shared.lua
│   │   │   ├── init.lua               — Matérialisation → spawn prop_physics réel
│   │   │   └── cl_init.lua            — Rendu translucide bleu (RENDERMODE_TRANSALPHA)
│   │   ├── construction_crate/        — Grosse caisse (50 matériaux)
│   │   │   ├── shared.lua
│   │   │   ├── init.lua               — Use (activer), LoadCrate, UnloadCrate
│   │   │   └── cl_init.lua            — 3D2D horizontal (barre + compteur matériaux)
│   │   └── construction_crate_small/  — Petite caisse (15 matériaux)
│   │       ├── shared.lua
│   │       ├── init.lua               — Même logique, sans transport véhicule
│   │       └── cl_init.lua            — 3D2D adapté (dimensions réduites)
│   └── weapons/
│       └── weapon_construction.lua    — SWEP principal (détails ci-dessous)
│
├── models/                             — Modèles custom
│   ├── weapons/v_fortnite_builder.mdl  — Viewmodel (plan d'architecte)
│   ├── weapons/w_fortnite_builder.mdl  — Worldmodel
│   └── fortnitea31/...                 — Modèles blueprint/crayon
├── materials/                          — Textures (VMT/VTF)
└── sql/
    └── schema.sql                      — [DEV] Schéma DB (logs, futur sharing)
```

> Les fichiers marqués **[DEV]** sont présents uniquement dans la version développement.

---

## Entités custom

| Entité | Type | Solid | Rôle |
|--------|------|-------|------|
| `construction_ghost` | Scripted Entity | `SOLID_NONE` | Fantôme holographique bleu, matérialisable par Use + caisse active |
| `construction_crate` | Scripted Entity | `SOLID_VPHYSICS` | Grosse caisse 50 matériaux, transportable en véhicule simfphys |
| `construction_crate_small` | Scripted Entity | `SOLID_VPHYSICS` | Petite caisse 15 matériaux, usage sur place |

Les caisses sont vendables via le menu F4 DarkRP (configuration dans `darkrpmodification/lua/darkrp_customthings/entities.lua`).

---

## SWEP weapon_construction

| Action | Touche | Contexte | Implémentation |
|--------|--------|----------|----------------|
| Sélectionner un prop | LMB | Vise un prop_physics | `SWEP:PrimaryAttack()` → net `Construction_SelectToggle` |
| Sélection par zone | RMB | Sans Shift | `SWEP:SecondaryAttack()` → net `Construction_SelectRadius` |
| Ouvrir le menu | Shift+RMB | — | `SWEP:SecondaryAttack()` → `cl_menu` côté client |
| Décharger véhicule | R | Vise un véhicule | `SWEP:Reload()` [CLIENT] → net `Construction_VehicleReload` |
| Vider la sélection | R | Ne vise pas un véhicule | Même net message, le serveur décide |

**Viewmodel** : `v_fortnite_builder.mdl` (plan d'architecte Fortnite) via Workshop. Fallback `c_slam.mdl` en dev.

**Particularité** : `SWEP:Reload()` n'est jamais appelé côté serveur quand `Primary.ClipSize = -1`. La logique passe par un net message client → serveur.

---

## Flux de données

### 1. Sauvegarde d'un blueprint

```
Joueur sélectionne props (LMB/RMB) → cl_selection halos
    ↓
Shift+RMB → cl_menu.lua → onglet Sauvegarder
    ↓
Client envoie "Construction_SaveBlueprint" (nom, desc, dossier)
    ↓
sv_security: rate limit check (10s cooldown)
    ↓
sv_blueprints: Serialize() — position relative au HeadEnt, modèle, angles, physique
    ↓
Serveur envoie "Construction_SaveToClient" (données JSON compressées)
    ↓
cl_blueprints: file.Write("construction_blueprints/[dossier/]nom.dat", json)
```

### 2. Chargement d'un blueprint

```
cl_menu → sélectionne blueprint → cl_blueprints: file.Read()
    ↓
Client envoie "Construction_LoadBlueprint" (données JSON du fichier .dat)
    ↓
sv_security: rate limit (15s cooldown)
    ↓
sv_blueprints: ValidateBlueprintData()
    ├── Classes autorisées ? (seul prop_physics)
    ├── Nombre de props ≤ MaxPropsPerBlueprint ?
    ├── Aucune classe blacklistée ?
    └── Données cohérentes ? (modèle, positions, angles valides)
    ↓
sv_blueprints: RebuildVectors() — string "x y z" → Vector()
    ↓
Serveur envoie "Construction_SendPreview" → client
    ↓
cl_placement: preview holographique (ClientsideModels translucides)
    ├── Molette : rotation
    ├── Shift+Molette : hauteur
    └── Checkbox : position originale
    ↓
Joueur confirme (LMB) → "Construction_ConfirmPlacement" (Vector, Angle)
    ↓
sv_ghosts: SpawnGhosts() → construction_ghost entities (batch 5/tick)
```

### 3. Matérialisation

```
Joueur Use (E) sur caisse → crate:SetNWEntity("ActivePlayer", ply)
    ↓
Joueur Use (E) sur ghost → net "Construction_MaterializeGhost"
    ↓
sv_ghosts: vérifications
    ├── ActiveCrate IsValid ?
    ├── Matériaux restants > 0 ?
    ├── Ghost toujours valide ?
    └── Distance joueur ↔ ghost raisonnable ?
    ↓
crate:UseMaterial() → materials -= 1
    ↓
ghost:Materialize()
    ├── Spawn prop_physics réel (position, modèle, angles du ghost)
    ├── Freeze le prop
    ├── CPPISetOwner(joueur qui matérialise)
    └── Remove le ghost entity
```

### 4. Véhicule (chargement/déchargement)

```
CHARGEMENT (touche R, SWEP vise un véhicule):
Client SWEP:Reload() → net "Construction_VehicleReload"
    ↓
Serveur: trace → IsVehicle/simfphys/LVS détecté
    ↓
Cherche caisse dans un rayon de 200 unités du véhicule
    ↓
sv_vehicles: LoadCrate()
    ├── SetParent(vehicle)
    ├── SetLocalPos(offset calibré par modèle)
    ├── SetLocalAngles(offset.ang)
    ├── phys:EnableMotion(false) — désactive la physique
    ├── SetSolid(SOLID_NONE) — plus de collisions
    └── SetNWBool("IsLoaded", true) → client cache le 3D2D

DÉCHARGEMENT (touche R, SWEP vise un véhicule chargé):
Client SWEP:Reload() → net "Construction_VehicleReload"
    ↓
Serveur: trace → véhicule → cherche caisse parentée dessus
    ↓
sv_vehicles: UnloadCrate()
    ├── Sauvegarde position monde actuelle (GetPos)
    ├── SetParent(nil)
    ├── timer.Simple(0) → SetPos(dropPos côté véhicule)
    ├── SetSolid(SOLID_VPHYSICS)
    ├── phys:EnableMotion(true) + phys:Wake()
    └── SetNWBool("IsLoaded", false)
```

### Offsets véhicules calibrés

| Véhicule | Classe | Offset |
|----------|--------|--------|
| Opel Blitz WW2 | `sim_fphy_codww2opel` | `Vector(-80, 0, 35)` |
| Opel Blitz (munitions) | `sim_fphy_codww2opel_ammo` | `Vector(-80, 0, 35)` |
| CCKW 6x6 US Army | `simfphys_cbww2_cckw6x6` | `Vector(-100, 0, 45)` |
| CCKW 6x6 (munitions) | `simfphys_cbww2_cckw6x6_ammo` | `Vector(-100, 0, 45)` |
| Autre simfphys | `*` | Calculé depuis les bounds du modèle |
| LVS | `lvs_*` | Calculé depuis les bounds du modèle |
| Source natif | `IsVehicle()` | Offset par défaut |

Maximum **2 caisses par véhicule** (décalées gauche/droite : `y ± 20`).

---

## Net messages

16 net messages au total :

| Message | Direction | Données | Description |
|---------|-----------|---------|-------------|
| `Construction_OpenMenu` | S → C | — | Force l'ouverture du menu chez le client |
| `Construction_SaveBlueprint` | C → S | nom, desc, dossier | Demande de sérialisation des props sélectionnés |
| `Construction_SaveToClient` | S → C | JSON compressé | Données sérialisées renvoyées pour stockage local |
| `Construction_LoadBlueprint` | C → S | JSON du blueprint | Envoi d'un blueprint local pour validation + spawn |
| `Construction_SelectToggle` | C → S | Entity | Toggle sélection d'un prop |
| `Construction_SelectRadius` | C → S | Vector, UInt(10) | Sélection par rayon (position + rayon) |
| `Construction_SelectClear` | C → S | — | Vider la sélection |
| `Construction_RequestSync` | C → S | — | Demande de synchronisation de la sélection |
| `Construction_SyncSelection` | S → C | Table d'entities | Liste des props sélectionnés |
| `Construction_SendPreview` | S → C | Données validées | Preview validée pour le placement client |
| `Construction_ConfirmPlacement` | C → S | Vector, Angle | Confirmer la position de placement |
| `Construction_CancelPlacement` | C → S | — | Annuler le placement en cours |
| `Construction_MaterializeGhost` | C → S | Entity ghost | Matérialiser un fantôme avec la caisse active |
| `Construction_AttachCrate` | C → S | Entity crate, Entity vehicle | Charger une caisse dans un véhicule |
| `Construction_DetachCrate` | C → S | Entity vehicle | Décharger une caisse d'un véhicule |
| `Construction_VehicleReload` | C → S | — | Touche R : décharger véhicule ou clear sélection |

---

## Base de données (optionnelle)

Le système fonctionne **entièrement sans base de données**. Les blueprints sont stockés localement côté client dans `data/construction_blueprints/*.dat`.

La DB optionnelle (MySQL 8.0 via MySQLOO) est présente **uniquement dans la version dev** et fournit :

### Tables

**`blueprint_logs`** — Historique des actions

| Colonne | Type | Description |
|---------|------|-------------|
| id | INT AUTO_INCREMENT | ID unique |
| steamid | VARCHAR(32) | SteamID de l'acteur |
| player_name | VARCHAR(64) | Nom du joueur |
| action | ENUM | save, load, delete, share |
| blueprint_name | VARCHAR(100) | Nom du blueprint |
| details | TEXT | Détails additionnels (JSON) |
| created_at | TIMESTAMP | Date de l'action |

**`shared_blueprints`** et **`blueprint_permissions`** — Prévu pour le futur système de partage entre joueurs.

### Connexion

```lua
-- sh_config.lua (version dev uniquement)
ConstructionSystem.Config.DB = {
    Host = "gmod-mysql",  -- Hostname Docker
    Port = 3306,
    User = "gmod_user",
    Password = "...",
    Database = "gmod_construction",
}
```

Connexion automatique via `InitPostEntity` avec 5s de délai + reconnexion automatique toutes les 30s en cas d'échec.

---

## Sécurité

| Mesure | Implémentation | Fichier |
|--------|---------------|---------|
| Rate Limiting | Cooldowns par action (save 10s, load 15s) + 60 req/min global | `sv_security.lua` |
| SQL Injection | Prepared statements MySQLOO exclusivement | `sv_database.lua` |
| Input Validation | Longueur strings (50/200), clamp nombres, classes autorisées | `sv_security.lua`, `sv_blueprints.lua` |
| Ownership | CPPI via `CPPIGetOwner()` — compatible FPP | `sv_selection.lua` |
| Blacklist | Classes interdites : money_printer, drug_lab, gun_lab, etc. | `sh_config.lua` |
| Job Restrictions | AllowedJobs, SWEPJobs, CrateAllowedJobs configurables | `sh_config.lua`, `sv_security.lua` |
| Client/Serveur | Aucune confiance client — tout est re-validé côté serveur | Architecture globale |
| FPP Hooks | PhysgunPickup, CanTool, GravGunPickupAllowed pour les caisses | `sv_security.lua` |
| Net message size | Données compressées, limite de taille vérifiée avant envoi | `sv_blueprints.lua` |
