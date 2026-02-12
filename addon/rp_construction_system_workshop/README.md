# 🏗️ RP Construction System — Version Workshop

**Version 2.2** | DarkRP Compatible | Standalone Workshop-Ready

> ✅ **Ceci est la version Workshop**, prête à publier sur le Steam Workshop ou à installer manuellement dans `garrysmod/addons/`. Aucune dépendance externe (pas de MySQL, pas de MySQLOO). Pour la version développement avec intégration MySQL et logging en base de données, voir [`addon/rp_construction_system_dev/`](../rp_construction_system_dev/).

Système de construction collaborative pour serveurs Garry's Mod DarkRP. Un Constructeur sélectionne des props, les sauvegarde en blueprint, les place comme fantômes holographiques, puis n'importe quel joueur peut matérialiser ces fantômes avec des caisses de matériaux. Les caisses peuvent être transportées en véhicule simfphys pour la logistique.

### Différences avec la version Dev

| | Workshop (ce dossier) | Dev |
|---|---|---|
| MySQL / MySQLOO | ❌ Pas nécessaire | ✅ Inclus |
| Logging | Console uniquement | Console + MySQL |
| `sv_admin_setup.lua` | ❌ Absent | ✅ Auto-config |
| `sql/schema.sql` | ❌ Absent | ✅ Schéma fourni |
| Viewmodel | `v_fortnite_builder.mdl` | `c_slam.mdl` (fallback) |
| Destination | Steam Workshop / addons/ | Serveur Docker (bind mount) |

---

## 📋 Table des matières

- [Fonctionnalités](#-fonctionnalités)
- [Installation](#-installation)
- [Configuration DarkRP](#-configuration-darkrp)
- [Configuration de l'addon](#-configuration-de-laddon)
- [Utilisation](#-utilisation)
- [Architecture technique](#-architecture-technique)
- [Net messages](#-net-messages)
- [Véhicules](#-véhicules)
- [Permissions et sécurité](#-permissions-et-sécurité)
- [Base de données (optionnelle)](#-base-de-données-optionnelle)
- [Crédits](#-crédits)
- [License](#-license)

---

## ✨ Fonctionnalités

### SWEP Construction (`weapon_construction`)
- **Clic gauche** — Sélectionner/Désélectionner un prop (halo bleu)
- **Clic droit** — Sélection par rayon (tous les props dans un rayon configurable)
- **Shift + Clic droit** — Ouvrir le menu blueprints
- **R (Reload)** — Décharger une caisse du véhicule visé, ou vider la sélection
- **HUD intégré** — Compteur de props sélectionnés, raccourcis affichés

### Blueprints
- **Sauvegarde locale** illimitée — Fichiers `.dat` (JSON) dans `data/construction_blueprints/`
- **Sous-dossiers** — Organisation libre, navigation par breadcrumb
- **Import AdvDupe2** — Copiez vos fichiers `.txt` AD2, ils sont détectés automatiquement (badge orange **AD2**)
- **Position originale** — Option pour placer le blueprint à ses coordonnées d'origine
- **Décodeur AD2 embarqué** — Pas besoin d'avoir AdvDupe2 installé sur le serveur

### Placement avancé
- **Prévisualisation holographique** — Ghost entities bleus translucides
- **Rotation** — Molette de souris
- **Ajustement hauteur** — Shift + Molette
- **Position originale** — Checkbox dans le panneau de placement
- **Confirmation/Annulation** — LMB pour confirmer, RMB/Échap pour annuler

### Construction collaborative
- Les fantômes sont visibles par **tous les joueurs**
- N'importe qui avec une **caisse de matériaux active** peut matérialiser les fantômes
- Appuyez **E** sur la caisse pour l'activer, puis **E** sur un fantôme pour le construire
- Chaque matérialisation consomme 1 matériau de la caisse

### Caisses de matériaux
| Type | Modèle | Matériaux | Prix F4 |
|------|--------|-----------|---------|
| Grosse caisse | `dun_wood_crate_03.mdl` | 50 | Configurable (défaut: 1$) |
| Petite caisse | `r_crate_pak50mm_stacked.mdl` | 15 | Configurable (défaut: 1$) |

Les grosses caisses sont transportables en véhicule simfphys.

### Véhicules simfphys
- **Chargement** — Équipez le SWEP, visez le véhicule avec une caisse à proximité, appuyez **R**
- **Déchargement** — Visez le véhicule avec le SWEP et appuyez **R**
- **Offsets calibrés** — Positions de cargo par modèle (WW2 Opel, CCKW 6x6, etc.)
- **2 caisses max** par véhicule (décalées gauche/droite)
- **Support LVS** — Documenté et détectable, offsets par défaut basés sur les bounds du modèle

### Interface
- **Dark theme** moderne avec sidebar
- **Navigation par dossiers** avec breadcrumb
- **Badges** : AD2 (import AdvDupe2), nombre de props
- **Onglets** : Blueprints, Sauvegarder, Paramètres

---

## 📦 Installation

### Workshop (recommandé)
1. Abonnez-vous à l'addon sur le [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3664157203)
2. Ajoutez l'ID Workshop (`3664157203`) à votre collection serveur ou via `host_workshop_collection`
3. Le contenu (modèles des caisses) nécessite le [content pack WW2](https://steamcommunity.com/sharedfiles/filedetails/?id=3008026539)

### Manuel
1. Téléchargez/clonez ce dépôt
2. Copiez le dossier `rp_construction_system_workshop` dans `garrysmod/addons/`
3. Redémarrez le serveur
4. Assurez-vous que les joueurs ont le content pack pour les modèles de caisses

> **Note** : Cette version Workshop ne contient pas de module MySQL — aucun fichier à supprimer.

### Compilation GMA (pour publication Workshop)

Pour créer le fichier `.gma` nécessaire à la publication Workshop :

```powershell
# Depuis le dossier bin de Garry's Mod
.\gmad.exe create -folder "chemin\vers\rp_construction_system_workshop" -out "chemin\vers\rp_construction_system.gma"
```

> **Important** : Les fichiers `.sw.vtx` ne sont pas supportés par gmad et ont été retirés du projet. Si gmad signale des fichiers "Not allowed by whitelist", supprimez-les du dossier avant de recompiler.

---

## ⚙️ Configuration DarkRP

### Attribuer le SWEP à un job

Le SWEP `weapon_construction` peut être attribué à **n'importe quel job DarkRP existant**. Ajoutez simplement `"weapon_construction"` dans la table `weapons` du job souhaité :

```lua
-- Exemple : l'ajouter à un job existant (jobs.lua)
TEAM_ARCHITECT = DarkRP.createJob("Architecte", {
    -- ... vos paramètres existants ...
    weapons = {"weapon_construction"},  -- Ajouter cette ligne
    -- ...
})
```

Pour attribuer le SWEP à **plusieurs jobs**, ajoutez-le dans chaque définition de job, puis configurez `sh_config.lua` :

```lua
-- sh_config.lua
ConstructionSystem.Config.SWEPJobs = {TEAM_ARCHITECT, TEAM_ENGINEER}
```

> **Note** : Si `SWEPJobs` est `nil`, l'addon détecte automatiquement le premier job qui possède `weapon_construction` dans ses armes.

### Caisses de matériaux (entités F4)

Ajoutez dans `darkrpmodification/lua/darkrp_customthings/entities.lua` :

```lua
DarkRP.createEntity("Caisse de Matériaux", {
    ent = "construction_crate",
    model = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl",
    price = 500,
    max = 2,
    cmd = "buycrate",
    allowed = {TEAM_ARCHITECT},  -- Restreindre aux jobs autorisés
    category = "Construction",
})

DarkRP.createEntity("Petite Caisse", {
    ent = "construction_crate_small",
    model = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl",
    price = 250,
    max = 3,
    cmd = "buysmallcrate",
    allowed = {TEAM_ARCHITECT},  -- Même restriction
    category = "Construction",
})
```

Le champ `allowed` contrôle quels jobs voient les caisses dans le menu F4. Omettez-le pour les rendre disponibles à tous.

---

## 🔧 Configuration de l'addon

Tout se configure dans `lua/rp_construction/sh_config.lua` :

### Limites

| Option | Défaut | Description |
|--------|--------|-------------|
| `MaxPropsPerBlueprint` | `150` | Nombre max de props par blueprint (0 = illimité) |
| `MaxCratesPerPlayer` | `2` | Nombre max de caisses simultanées par joueur |
| `MaxNameLength` | `50` | Longueur max du nom de blueprint |
| `MaxDescLength` | `200` | Longueur max de la description |

### Cooldowns

| Option | Défaut | Description |
|--------|--------|-------------|
| `SaveCooldown` | `10` | Secondes entre chaque sauvegarde |
| `LoadCooldown` | `15` | Secondes entre chaque chargement |

### Sélection

| Option | Défaut | Description |
|--------|--------|-------------|
| `SelectionRadiusMin` | `50` | Rayon minimum de sélection par zone |
| `SelectionRadiusMax` | `1000` | Rayon maximum (limité à 1023 pour le net) |
| `SelectionRadiusDefault` | `500` | Rayon par défaut |

### Caisses

| Option | Défaut | Description |
|--------|--------|-------------|
| `CrateModel` | `dun_wood_crate_03.mdl` | Modèle de la grosse caisse |
| `CrateMaxMaterials` | `50` | Matériaux par grosse caisse |
| `CratePrice` | `1` | Prix DarkRP de la grosse caisse |
| `SmallCrateModel` | `r_crate_pak50mm_stacked.mdl` | Modèle de la petite caisse |
| `SmallCrateMaxMaterials` | `15` | Matériaux par petite caisse |
| `SmallCratePrice` | `1` | Prix DarkRP de la petite caisse |

### Jobs & Permissions

| Option | Défaut | Description |
|--------|--------|-------------|
| `AllowedJobs` | `nil` | Table de TEAM_ IDs autorisés (`nil` = tout le monde) |
| `SWEPJobs` | `nil` | Jobs recevant le SWEP automatiquement |
| `CrateAllowedJobs` | `nil` | Jobs autorisés à utiliser les caisses (`nil` = tout le monde) |

### Sécurité

| Option | Description |
|--------|-------------|
| `BlacklistedEntities` | Classes d'entités interdites dans les blueprints |
| `AllowedClasses` | Seul `prop_physics` est autorisé par défaut |

### Base de données

| Option | Défaut | Description |
|--------|--------|-------------|
| `DB.Host` | `gmod-mysql` | Hostname MySQL (Docker) |
| `DB.Port` | `3306` | Port MySQL |
| `DB.User` | `gmod_user` | Utilisateur MySQL |
| `DB.Password` | — | Mot de passe MySQL |
| `DB.Database` | `gmod_construction` | Nom de la base |

---

## 🎮 Utilisation

### Sélection de props

| Action | Contrôle |
|--------|----------|
| Sélectionner/Désélectionner un prop | LMB (clic gauche) |
| Sélection par rayon | RMB (clic droit) |
| Vider la sélection | R (si pas de véhicule visé) |
| Ouvrir le menu | Shift + RMB |

### Sauvegarde & Chargement

1. Sélectionnez vos props avec le SWEP
2. Ouvrez le menu (Shift + RMB) → onglet **Sauvegarder**
3. Nommez votre blueprint → **Sauvegarder**
4. Pour charger : onglet **Blueprints** → sélectionnez → **Charger**

### Placement

| Action | Contrôle |
|--------|----------|
| Rotation | Molette |
| Ajuster hauteur | Shift + Molette |
| Confirmer le placement | LMB |
| Annuler | RMB ou Échap |
| Position originale | Checkbox dans le panneau |

### Construction

1. Le Constructeur place un blueprint → fantômes holographiques bleus
2. Un joueur achète une **Caisse de Matériaux** (F4 → Entities → Construction)
3. Appuyez **E** sur la caisse pour l'activer
4. Approchez un fantôme et appuyez **E** pour le matérialiser

### Transport en véhicule

1. Spawner un véhicule simfphys (ex: Opel WW2, CCKW 6x6)
2. Posez une caisse à proximité du véhicule
3. Équipez le SWEP, visez le véhicule et appuyez **R** pour charger
4. Conduisez jusqu'au chantier
5. Visez le véhicule avec le SWEP et appuyez **R** pour décharger

### Stockage des blueprints

```
garrysmod/data/construction_blueprints/
├── ma_maison.dat               ← Blueprint natif (JSON)
├── garage.dat
├── bases/
│   ├── base_militaire.dat
│   └── bunker.dat
└── imports/
    └── mon_dupe_ad2.txt        ← Fichier AdvDupe2 importé (auto-détecté)
```

---

## 🏗️ Architecture technique

### Structure des fichiers

```
rp_construction_system/
├── lua/
│   ├── autorun/
│   │   ├── client/cl_construction_init.lua     — Init client
│   │   └── server/
│   │       ├── sv_construction_init.lua        — Init serveur + net strings
│   │       └── sv_admin_setup.lua              — Superadmin auto-config
│   ├── rp_construction/
│   │   ├── sh_config.lua          — Configuration partagée (client+serveur)
│   │   ├── sv_blueprints.lua      — Sérialisation, validation, spawn
│   │   ├── sv_ghosts.lua          — Gestion des ghost entities
│   │   ├── sv_selection.lua       — Logique de sélection serveur
│   │   ├── sv_permissions.lua     — Système de partage
│   │   ├── sv_security.lua        — Rate limiting, validation
│   │   ├── sv_logging.lua         — Logs serveur (console + DB)
│   │   ├── sv_database.lua        — Module MySQLOO (optionnel)
│   │   ├── sv_vehicles.lua        — Attach/detach caisses sur véhicules
│   │   ├── cl_blueprints.lua      — Stockage local, gestion fichiers
│   │   ├── cl_ad2_decoder.lua     — Décodeur AdvDupe2 embarqué
│   │   ├── cl_menu.lua            — Interface Derma complète
│   │   ├── cl_placement.lua       — Preview holographique, placement
│   │   ├── cl_selection.lua       — Rendu halos, HUD sélection
│   │   └── cl_vehicles.lua        — HUD véhicule, bind reload
│   ├── entities/
│   │   ├── construction_ghost/    — Entité fantôme (non-solide, translucide)
│   │   ├── construction_crate/    — Grosse caisse (50 matériaux)
│   │   └── construction_crate_small/ — Petite caisse (15 matériaux)
│   └── weapons/
│       └── weapon_construction.lua — SWEP principal
└── sql/
    └── schema.sql                 — Schéma DB optionnel
```

### Séparation client/serveur

| Préfixe | Exécution | Rôle |
|---------|-----------|------|
| `sv_` | Serveur uniquement | Logique métier, validation, DB |
| `cl_` | Client uniquement | Interface, rendu, stockage local |
| `sh_` | Les deux | Configuration partagée |

Le client n'a **aucune autorité**. Chaque action est envoyée par net message et **re-validée** côté serveur (permissions, rate limit, ownership, limites).

---

## 📡 Net messages

| Message | Direction | Description |
|---------|-----------|-------------|
| `Construction_OpenMenu` | S → C | Ouvrir le menu chez le client |
| `Construction_SaveBlueprint` | C → S | Demande de sérialisation d'un blueprint |
| `Construction_SaveToClient` | S → C | Données sérialisées renvoyées pour stockage local |
| `Construction_LoadBlueprint` | C → S | Envoi d'un blueprint local pour validation + spawn |
| `Construction_SelectToggle` | C → S | Toggle sélection d'un prop |
| `Construction_SelectRadius` | C → S | Sélection par rayon (position + rayon) |
| `Construction_SelectClear` | C → S | Vider la sélection |
| `Construction_RequestSync` | C → S | Demande de synchronisation de la sélection |
| `Construction_SyncSelection` | S → C | Envoi de la liste des props sélectionnés |
| `Construction_SendPreview` | S → C | Données validées pour la prévisualisation |
| `Construction_ConfirmPlacement` | C → S | Confirmer la position de placement |
| `Construction_CancelPlacement` | C → S | Annuler le placement |
| `Construction_MaterializeGhost` | C → S | Matérialiser un ghost avec la caisse |
| `Construction_AttachCrate` | C → S | Charger une caisse dans un véhicule |
| `Construction_DetachCrate` | C → S | Décharger une caisse d'un véhicule |
| `Construction_VehicleReload` | C → S | Touche R : décharger véhicule ou clear sélection |

---

## 🚛 Véhicules

### Véhicules supportés

**simfphys** (support principal) :
- `sim_fphy_codww2opel` — Opel Blitz WW2
- `sim_fphy_codww2opel_ammo` — Opel Blitz WW2 (munitions)
- `simfphys_cbww2_cckw6x6` — CCKW 6x6 US Army
- `simfphys_cbww2_cckw6x6_ammo` — CCKW 6x6 (munitions)
- Tout véhicule simfphys (offset par défaut basé sur les bounds du modèle)

**LVS** (support secondaire, documenté) :
- Détection automatique des classes `lvs_*`
- Offset par défaut calculé depuis les bounds du modèle

**Source natifs** :
- Détection via `ent:IsVehicle()`
- Offset par défaut

### Offsets personnalisés

Ajoutez vos propres véhicules dans `sv_vehicles.lua` :
```lua
ConstructionSystem.Vehicles.CargoOffsets["mon_vehicule_class"] = {
    pos = Vector(-80, 0, 35),  -- x=avant, y=gauche, z=haut
    ang = Angle(0, 0, 0)
}
```

---

## 🔒 Permissions et sécurité

### Rate Limiting
- Chaque action a un cooldown configurable
- Protection contre le spam de net messages

### Validation serveur
- Chaque blueprint reçu est validé : classes autorisées, nombre de props, données cohérentes
- Les strings sont sanitizées (longueur, caractères)
- Les nombres sont clampés aux bornes configurées

### Blacklist
- Classes d'entités interdites (money_printer, drug_lab, etc.)
- Seuls les `prop_physics` sont autorisés dans les blueprints

### FPP/CPPI
- Hooks `PhysgunPickup`, `CanTool`, `GravGunPickupAllowed` pour les caisses
- Vérification `CPPIGetOwner()` pour la propriété

### Restrictions par job
- Le SWEP peut être restreint à certains jobs DarkRP
- Les caisses peuvent être restreintes séparément

---

## 🗄️ Base de données (optionnelle)

Le système fonctionne **entièrement sans base de données**. Les blueprints sont stockés localement sur le PC du joueur.

Le schéma SQL dans `sql/schema.sql` est optionnel et fournit :

- **`blueprint_logs`** — Historique des actions (sauvegarde, chargement, suppression)
- **`shared_blueprints`** — (Futur) Blueprints partagés entre joueurs
- **`blueprint_permissions`** — (Futur) Permissions de partage (view, use, edit)

### Installation

```sql
CREATE DATABASE gmod_construction;
mysql -u root -p gmod_construction < sql/schema.sql
```

Configurez les identifiants dans `sh_config.lua` → section `DB`.

---

## 🙏 Crédits

- **Décodeur AdvDupe2** — Basé sur [wiremod/advdupe2](https://github.com/wiremod/advdupe2) (Apache 2.0)
- **Viewmodel** — `v_fortnite_builder.mdl` (Workshop) / `c_slam.mdl` (dev fallback)
- **Panel de placement** — Inspiré de l'interface AdvDupe2

---

## 📄 License

Libre pour le serveur Labguette Military RP. Pour toute autre utilisation, contactez l'auteur : Discord `thomaslewis5395`

---
---

# 🇬🇧 English Version

# 🏗️ RP Construction System — Garry's Mod Addon

**Version 2.2** | DarkRP Compatible | Standalone Workshop-Ready

Collaborative construction system for Garry's Mod DarkRP servers. A Builder selects props, saves them as blueprints, places them as holographic ghosts, then any player can materialize those ghosts using material crates. Crates can be transported in simfphys vehicles for logistics.

---

## ✨ Features

### Construction SWEP (`weapon_construction`)
- **Left click** — Select/Deselect a prop (blue halo)
- **Right click** — Radius selection (all props within a configurable radius)
- **Shift + Right click** — Open blueprints menu
- **R (Reload)** — Unload crate from targeted vehicle, or clear selection
- **Integrated HUD** — Selected props counter, shortcuts displayed

### Blueprints
- **Unlimited local saves** — `.dat` files (JSON) in `data/construction_blueprints/`
- **Subfolders** — Free organization, breadcrumb navigation
- **AdvDupe2 import** — Copy your AD2 `.txt` files, auto-detected (orange **AD2** badge)
- **Original position** — Option to place blueprint at original coordinates
- **Embedded AD2 decoder** — No need for AdvDupe2 installed on server

### Advanced Placement
- **Holographic preview** — Blue translucent ghost entities
- **Rotation** — Mouse wheel
- **Height adjustment** — Shift + Mouse wheel
- **Original position** — Checkbox in placement panel
- **Confirm/Cancel** — LMB to confirm, RMB/Escape to cancel

### Collaborative Construction
- Ghosts are visible to **all players**
- Anyone with an **active material crate** can materialize ghosts
- Press **E** on crate to activate, then **E** on ghost to build
- Each materialization consumes 1 material from the crate

### Material Crates
| Type | Model | Materials | F4 Price |
|------|-------|-----------|----------|
| Large crate | `dun_wood_crate_03.mdl` | 50 | Configurable (default: $1) |
| Small crate | `r_crate_pak50mm_stacked.mdl` | 15 | Configurable (default: $1) |

Large crates are transportable in simfphys vehicles.

### simfphys Vehicles
- **Loading** — Equip the SWEP, aim at the vehicle with a crate nearby, press **R**
- **Unloading** — Aim at vehicle with SWEP and press **R**
- **Calibrated offsets** — Cargo positions per vehicle model (WW2 Opel, CCKW 6x6, etc.)
- **LVS support** — Documented and detectable, default offsets based on model bounds

### Interface
- **Modern dark theme** with sidebar
- **Folder navigation** with breadcrumb
- **Badges**: AD2 (AdvDupe2 import), prop count
- **Tabs**: Blueprints, Save, Settings

---

## 📦 Installation

### Workshop (recommended)
1. Subscribe to the addon on the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3664157203)
2. Add the Workshop ID (`3664157203`) to your server collection or via `host_workshop_collection`
3. Content (crate models) requires the [WW2 content pack](https://steamcommunity.com/sharedfiles/filedetails/?id=3008026539)

### Manual
1. Download/clone this repository
2. Copy the `rp_construction_system_workshop` folder to `garrysmod/addons/`
3. Restart the server
4. Ensure players have the content pack for crate models

> **Note**: This Workshop version has no MySQL module — nothing to remove.

### GMA Compilation (for Workshop publishing)

To create the `.gma` file required for Workshop publishing:

```powershell
# From Garry's Mod bin folder
.\gmad.exe create -folder "path\to\rp_construction_system_workshop" -out "path\to\rp_construction_system.gma"
```

> **Important**: `.sw.vtx` files are not supported by gmad and have been removed from the project.

---

## ⚙️ DarkRP Configuration

### Assign the SWEP to a job

Add `"weapon_construction"` to the `weapons` table of any existing DarkRP job:

```lua
-- Example: add to an existing job (jobs.lua)
TEAM_ARCHITECT = DarkRP.createJob("Architect", {
    -- ... your existing settings ...
    weapons = {"weapon_construction"},  -- Add this line
    -- ...
})
```

For **multiple jobs**, add it to each job definition and configure `sh_config.lua`:

```lua
-- sh_config.lua
ConstructionSystem.Config.SWEPJobs = {TEAM_ARCHITECT, TEAM_ENGINEER}
```

### Material Crates (F4 entities)

Add to `darkrpmodification/lua/darkrp_customthings/entities.lua`:

```lua
DarkRP.createEntity("Material Crate", {
    ent = "construction_crate",
    model = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl",
    price = 500,
    max = 2,
    cmd = "buycrate",
    allowed = {TEAM_ARCHITECT},  -- Restrict to allowed jobs
    category = "Construction",
})

DarkRP.createEntity("Small Crate", {
    ent = "construction_crate_small",
    model = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl",
    price = 250,
    max = 3,
    cmd = "buysmallcrate",
    allowed = {TEAM_ARCHITECT},  -- Same restriction
    category = "Construction",
})
```

The `allowed` field controls which jobs see crates in the F4 menu. Omit it to make them available to everyone.

---

## 🔧 Addon Configuration

All settings in `lua/rp_construction/sh_config.lua`:

| Option | Default | Description |
|--------|---------|-------------|
| `MaxPropsPerBlueprint` | `150` | Max props per blueprint (0 = unlimited) |
| `MaxCratesPerPlayer` | `2` | Max simultaneous crates per player |
| `SaveCooldown` | `10` | Seconds between saves |
| `LoadCooldown` | `15` | Seconds between loads |
| `CrateMaxMaterials` | `50` | Materials per large crate |
| `SmallCrateMaxMaterials` | `15` | Materials per small crate |
| `AllowedJobs` | `nil` | Allowed TEAM_ IDs (`nil` = everyone) |
| `SWEPJobs` | `nil` | Jobs that auto-receive the SWEP |
| `CrateAllowedJobs` | `nil` | Jobs allowed to use crates (`nil` = everyone) |
| `BlacklistedEntities` | table | Blocked entity classes in blueprints |

---

## 🎮 Usage

### Selection
| Action | Control |
|--------|---------|
| Select/deselect a prop | Left click |
| Radius selection | Right click |
| Clear selection | R (if not aiming at vehicle) |
| Open menu | Shift + Right click |

### Placement
| Action | Control |
|--------|---------|
| Rotate | Mouse wheel |
| Adjust height | Shift + Mouse wheel |
| Confirm | Left click |
| Cancel | Right click or Escape |

### Construction
1. Builder places blueprint → blue holographic ghosts
2. Player buys a **Material Crate** (F4 → Entities → Construction)
3. Press **E** on crate to activate
4. Approach ghost and press **E** to materialize

### Vehicle Transport
1. Spawn a simfphys vehicle (e.g. WW2 Opel, CCKW 6x6)
2. Place a crate near the vehicle
3. Equip the SWEP, aim at the vehicle and press **R** to load
4. Drive to construction site
5. Aim at vehicle with SWEP and press **R** to unload

---

## 🏗️ Technical Architecture

### File Structure

```
rp_construction_system/
├── lua/
│   ├── autorun/          — Entry points (client + server init)
│   ├── rp_construction/  — Core modules (13 files, sv_/cl_/sh_ prefix)
│   ├── entities/         — 3 custom entities (ghost, crate, crate_small)
│   └── weapons/          — SWEP weapon_construction
├── models/               — Custom models (viewmodel, crates)
├── materials/            — Model textures
└── sql/schema.sql        — Optional DB schema
```

### Client/Server Separation

| Prefix | Runs on | Role |
|--------|---------|------|
| `sv_` | Server only | Business logic, validation, DB |
| `cl_` | Client only | UI, rendering, local storage |
| `sh_` | Both | Shared configuration |

The client has **zero authority**. Every action is sent via net message and **re-validated** server-side.

---

## 🔒 Security

- **Rate limiting** — Configurable cooldowns per action
- **Server validation** — Every blueprint is validated: allowed classes, prop count, data integrity
- **Blacklist** — Forbidden entity classes (money_printer, drug_lab, etc.)
- **FPP/CPPI** — PhysgunPickup, CanTool, GravGunPickupAllowed hooks for crates
- **Job restrictions** — SWEP and crates can be restricted to specific DarkRP jobs
- **SQL injection** — Prepared statements exclusively (MySQLOO)

---

## 🗄️ Database (optional)

The system works **entirely without a database**. Blueprints are stored locally on the player's PC.

The optional SQL schema provides logging and future sharing features.

---

## 🚛 Supported Vehicles

**simfphys** (primary):
- Opel Blitz WW2, CCKW 6x6, and any simfphys vehicle
- Per-model calibrated cargo offsets

**LVS** (secondary, documented):
- Auto-detection of `lvs_*` classes
- Default offset from model bounds

Custom offsets can be added for any vehicle model.

---

## 🙏 Credits

- **AdvDupe2 decoder** — Based on [wiremod/advdupe2](https://github.com/wiremod/advdupe2) (Apache 2.0)
- **Viewmodel** — `v_fortnite_builder.mdl` (Workshop) / `c_slam.mdl` (dev fallback)
- **Placement panel** — Inspired by AdvDupe2 interface

---

## 📄 License

Libre pour le serveur Labguette Military RP. Pour toute autre utilisation, contactez l'auteur : Discord `thomaslewis5395`
