# 🏗️ RP Construction System — Addon Garry's Mod

**Version 2.2** | DarkRP Compatible | Standalone Workshop-Ready

Système de construction collaborative pour serveurs Garry's Mod DarkRP. Un Constructeur sélectionne des props, les sauvegarde en blueprint, les place comme fantômes holographiques, puis n'importe quel joueur peut matérialiser ces fantômes avec des caisses de matériaux. Les caisses peuvent être transportées en véhicule simfphys pour la logistique.

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
- **Chargement** — Physgun la caisse près du véhicule, le système auto-détecte via Think loop
- **Déchargement** — Visez le véhicule avec le SWEP et appuyez R
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
1. Abonnez-vous à l'addon sur le Steam Workshop
2. Ajoutez l'ID Workshop à votre collection serveur via `host_workshop_collection`
3. Le contenu (modèles des caisses) nécessite le [content pack WW2](https://steamcommunity.com/sharedfiles/filedetails/?id=3008026539)

### Manuel
1. Téléchargez/clonez ce dépôt
2. Copiez le dossier `rp_construction_system` dans `garrysmod/addons/`
3. Redémarrez le serveur
4. Assurez-vous que les joueurs ont le content pack pour les modèles de caisses

---

## ⚙️ Configuration DarkRP

### Job Constructeur

Ajoutez dans `darkrpmodification/lua/darkrp_customthings/jobs.lua` :

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

> **Note** : `TEAM_BUILDER` est le Team ID 10 par défaut. Adaptez selon votre serveur.

### Entités F4

Ajoutez dans `darkrpmodification/lua/darkrp_customthings/entities.lua` :

```lua
DarkRP.createEntity("Caisse de Matériaux", {
    ent = "construction_crate",
    model = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl",
    price = 500,
    max = 2,
    cmd = "buycrate",
    category = "Construction",
})

DarkRP.createEntity("Petite Caisse", {
    ent = "construction_crate_small",
    model = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl",
    price = 250,
    max = 3,
    cmd = "buysmallcrate",
    category = "Construction",
})
```

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
2. Physgun la caisse près du véhicule → chargement automatique
3. Conduisez jusqu'au chantier
4. Visez le véhicule avec le SWEP et appuyez **R** pour décharger

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
- **Modèles WW2** — Caisses et véhicules issus de packs Workshop WW2 (content pack [3008026539](https://steamcommunity.com/sharedfiles/filedetails/?id=3008026539))
- **Viewmodel** — `v_fortnite_builder.mdl` (Workshop) / `c_slam.mdl` (dev fallback)
- **Panel de placement** — Inspiré de l'interface AdvDupe2

---

## 📄 License

MIT
