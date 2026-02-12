# 📓 Journal de Développement — RP Construction System

> Journal chronologique du développement de l'addon, organisé par étapes. Chaque étape documente les fonctionnalités ajoutées, les problèmes rencontrés et les solutions apportées.
>
> 🔗 **[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3664157203)** — Addon publié (ID 3664157203)

---

## 📋 Table des matières

- [Étape 1 — Infrastructure Docker + DarkRP](#étape-1--infrastructure-docker--darkrp)
- [Étape 2 — Base de données MySQL](#étape-2--base-de-données-mysql)
- [Étape 3 — Système de sélection + Blueprints + Interface](#étape-3--système-de-sélection--blueprints--interface)
- [Étape 4 — Permissions, sécurité, partage](#étape-4--permissions-sécurité-partage)
- [Étape 5 — Refonte v2.0 : SWEP + Ghosts + Caisses](#étape-5--refonte-v20--swep--ghosts--caisses)
- [Étape 6 — Refonte v2.1 : Dossiers, AD2, UI](#étape-6--refonte-v21--dossiers-ad2-ui)
- [Étape 7 — Véhicules simfphys v2.2](#étape-7--véhicules-simfphys-v22)
- [Étape 8 — Publication Workshop & Finalisation](#étape-8--publication-workshop--finalisation)
- [Récapitulatif](#récapitulatif)

---

## Étape 1 — Infrastructure Docker + DarkRP

**Objectif** : Mettre en place un serveur Garry's Mod DarkRP conteneurisé sur un VPS.

**Réalisations :**
- Installation Docker sur VPS Hostinger (16 Go RAM, Ubuntu)
- Recherche et test de l'image `ceifa/garrysmod` (seule image Docker GMod maintenue)
- Création du `docker-compose.yml` avec deux services : GMod + MySQL 8.0
- Configuration réseau Docker interne (GMod ↔ MySQL via hostname `gmod-mysql`)
- Premier démarrage : téléchargement de la Workshop Collection 2270926906 (~101 addons, ~8 Go)
- Sauvegarde de l'état via `docker commit` pour éviter le re-téléchargement
- Installation du gamemode DarkRP + `darkrpmodification`
- Configuration initiale : jobs, catégories d'entités, settings serveur
- Création de la structure du projet Git

**Images Docker** : `v1.0-base`, `v1.0-final`

**Problème rencontré** : `docker restart` ne relit pas les variables d'environnement du compose. Il faut utiliser `docker compose up -d` pour appliquer les changements (map, args, etc.).

---

## Étape 2 — Base de données MySQL

**Objectif** : Intégrer MySQL pour le logging et le futur partage de blueprints.

**Réalisations :**
- Installation de MySQLOO 9.7.6 via bind mount dans `lua/bin/`
- Configuration partagée dans `sh_config.lua` (host, port, user, database)
- Module `sv_database.lua` : connexion avec auto-reconnect (5s délai + fallback 30s)
- Schéma BDD : 3 tables
  - `blueprint_logs` — historique des actions (save, load, delete, share)
  - `shared_blueprints` — futur partage entre joueurs
  - `blueprint_permissions` — permissions de partage (view, use, edit)
- Toutes les requêtes utilisent des **prepared statements** (protection SQL injection)

**Image Docker** : `v1.1-mysql`

**Problème rencontré** : Le binaire MySQLOO 32-bit (`gmsv_mysqloo_linux.dll`) ne fonctionne pas dans le container Docker qui tourne en 64-bit. Solution : utiliser le binaire 64-bit `gmsv_mysqloo_linux64.dll`.

---

## Étape 3 — Système de sélection + Blueprints + Interface

**Objectif** : Développer le cœur du système — sélection de props, sauvegarde/chargement de blueprints.

**Réalisations :**
- SWEP `weapon_construction` : arme dédiée distribuée automatiquement aux jobs autorisés
  - LMB : sélectionner/désélectionner un prop (halo bleu)
  - RMB : sélection par zone (rayon configurable 50-1000 unités)
  - Shift+RMB : ouvrir le menu blueprints
  - R : vider la sélection
- Sérialisation custom des props :
  - Positions relatives au "HeadEnt" (premier prop sélectionné)
  - Vector/Angle → conversion en table JSON → `util.Compress()` → `util.Base64Encode()`
  - Reconstruction via `RebuildVectors()` au chargement
- Interface Derma : 3 onglets (Mes Blueprints, Sauvegarder, Infos)
- Vérification d'ownership CPPI : seuls les props dont le joueur est propriétaire sont sélectionnables (compatible FPP)
- Synchronisation client/serveur de la sélection via net messages

---

## Étape 4 — Permissions, sécurité, partage

**Objectif** : Sécuriser le système et ajouter le partage entre joueurs.

**Réalisations :**
- Système de permissions à 3 niveaux : view, use, edit
- Partage de blueprints entre joueurs via SteamID
- Interface Derma pour la gestion des permissions
- Rate limiting global : 60 requêtes/minute par joueur
- Cooldowns par action : sauvegarde (10s), chargement (15s)
- Blacklist de classes d'entités interdites dans les blueprints :
  - `money_printer`, `darkrp_money`, `drug_lab`, `gun_lab`, `spawned_shipment`, etc.
- Restrictions par job DarkRP configurables
- Commandes admin : `construction_logs [n]`, `construction_stats`
- Logging de toutes les actions en console + base de données

---

## Étape 5 — Refonte v2.0 : SWEP + Ghosts + Caisses

**Objectif** : Refactoring majeur — passer d'un système de spawn direct à un système de construction collaborative avec fantômes et caisses de matériaux.

### Nouveau flow de jeu
1. Le Constructeur sélectionne des props et sauvegarde un blueprint
2. Il charge le blueprint → des **props fantômes** (translucides, bleutés) apparaissent
3. N'importe quel joueur achète une **Caisse de Matériaux** (F4 → Entities)
4. Le joueur active la caisse (E) puis vise un fantôme (E) → le prop se matérialise
5. Le prop matérialisé appartient au joueur qui l'a construit

### Entités créées
- `construction_ghost` : prop fantôme (RENDERMODE_TRANSALPHA, SOLID_NONE, couleur bleue translucide)
- `construction_crate` : grosse caisse de matériaux (50 matériaux, compteur 3D2D au-dessus)

### Optimisations
- Rendu ghosts : pas de halo (trop lourd en grand nombre) → changement de couleur + RENDERMODE_TRANSALPHA
- HUD ghost : cache de 200ms pour éviter les recalculs
- Batch spawning des ghosts : 5 props par tick pour éviter les freezes
- Undo support (touche Z) pour les fantômes et les props matérialisés

### Bugs corrigés
| Bug | Cause | Solution |
|-----|-------|----------|
| `GetMaterials()` erreur | Conflit avec méthode native `Entity:GetMaterials()` | Renommé en `GetRemainingMats()` |
| `base_gltransfer` introuvable | Classe de base inexistante | Changé pour `base_anim` |
| `IN_USE` non détecté | `KeyPress`/`Think` ne captent pas `IN_USE` côté serveur | Client `Think` + `input.IsKeyDown(KEY_E)` + net message |
| ActiveCrate non synchronisée | Le client ne connaissait pas l'état de la caisse active | Ajout de `SetNWEntity("ActiveCrate", crate)` |
| Props non freezés au chargement | Les props matérialisés bougeaient | `EnableMotion(false)` systématique |

**Image Docker** : `v2-stable`

---

## Étape 6 — Refonte v2.1 : Dossiers, AD2, UI

**Objectif** : Améliorer l'expérience utilisateur — organisation des blueprints, import AdvDupe2, nouvelle interface.

**Réalisations :**
- **Sous-dossiers** : création, navigation, suppression de dossiers dans l'interface
- **Navigation breadcrumb** : chemin cliquable en haut du menu pour remonter dans l'arborescence
- **Import AdvDupe2** :
  - Décodeur binaire AD2 embarqué dans `cl_ad2_decoder.lua`
  - Supporte les formats rev4 et rev5
  - Détection automatique des fichiers `.txt` copiés dans le dossier blueprints
  - Badge orange **AD2** dans l'interface pour distinguer les imports
  - **Pas de dépendance** sur AdvDupe2 — le décodeur est autonome
- **Refonte UI** :
  - Dark theme moderne avec sidebar
  - Panneau de placement style AdvDupe2 (rotation molette, hauteur Shift+molette, position originale)
  - Badges : nombre de props par blueprint, AD2 pour les imports
- **Petite caisse** (`construction_crate_small`) : 15 matériaux, pour les petits travaux
- **Modèles de caisses custom** :
  - Grosse caisse : `dun_wood_crate_03.mdl` (WW2 content pack)
  - Petite caisse : `r_crate_pak50mm_stacked.mdl` (WW2 content pack)
- **Blueprints locaux** : migration du stockage serveur (MySQL) vers stockage **local client** dans `data/construction_blueprints/`

**Image Docker** : `v2.1-stable`

---

## Étape 7 — Véhicules simfphys v2.2

**Objectif** : Permettre le transport logistique des caisses de matériaux en véhicule.

**Réalisations :**
- Nouveaux modules : `sv_vehicles.lua` (serveur) + `cl_vehicles.lua` (client)
- Détection automatique du type de véhicule :
  - simfphys (`gmod_sent_vehicle_fphysics_base`)
  - LVS (`lvs_*`)
  - Source natifs (`IsVehicle()`)
- Système d'attachement :
  - `SetParent(vehicle)` + `SetLocalPos(offset)` + `phys:EnableMotion(false)`
  - `SetSolid(SOLID_NONE)` pour éviter les collisions pendant le transport
- Offsets calibrés par modèle de véhicule :
  - Opel Blitz WW2 : `Vector(-80, 0, 35)`
  - CCKW 6x6 : `Vector(-100, 0, 45)`
  - Autres : offset calculé depuis les bounds du modèle
- Maximum **2 caisses par véhicule** (décalées `y ± 20`)
- Net message `Construction_VehicleReload` : touche R pour charger/décharger
- HUD véhicule côté client : instructions contextuelles
- `PlayerBindPress` + `"+reload"` pour la détection de la touche R côté client

### Bugs rencontrés et résolus

| Bug | Cause | Solution |
|-----|-------|----------|
| `SWEP:Reload()` jamais appelé serveur | `Primary.ClipSize = -1` → le moteur Source n'appelle pas `Reload()` serveur | Net message depuis `SWEP:Reload()` client uniquement |
| `KeyPress` ne capte pas `IN_RELOAD` | Hook `KeyPress` ne transmet pas ce flag avec une SWEP active | Abandonné au profit du net message |
| Ghost physics après `SetParent()` | La physique reste active après le parenting | `phys:EnableMotion(false)` (pas `PhysicsDestroy()` qui cause des crashs) |
| `SetParent(nil)` restaure l'ancienne position | Le moteur Source sauvegarde la position locale au moment du parenting | Sauvegarder `GetPos()` avant, puis `timer.Simple(0)` → `SetPos(dropPos)` |

**Image Docker** : `v2.2-vehicles`

---

## Étape 8 — Publication Workshop & Finalisation

**Objectif** : Publier l'addon sur le Steam Workshop et finaliser le projet.

**Réalisations :**
- Création du fichier `addon.json` requis par gmad (titre, tags, ignore list)
- Suppression des fichiers `.sw.vtx` (non supportés par la whitelist gmad)
- Compilation du `.gma` via `gmad.exe create`
- Publication sur le Steam Workshop via `gmpublish.exe` → **[ID 3664157203](https://steamcommunity.com/sharedfiles/filedetails/?id=3664157203)**
- Création de l'icône 512x512 (PNG + JPG) pour la page Workshop
- Page Workshop publique avec description bilingue FR/EN, captures d'écran et vidéo
- Séparation de l'addon en **deux versions** :
  - **Workshop** (standalone) : sans MySQL, sans `sv_admin_setup.lua`, viewmodel Fortnite Builder
  - **Dev** : avec MySQL, logging DB, auto-config admin, viewmodel fallback `c_slam.mdl`
- Basculement du viewmodel serveur vers `v_fortnite_builder.mdl` (fonctionnel via Workshop)
- Ajout de `+workshop_download_item 4000 3664157203` dans les arguments Docker
- Ajout de `resource.AddWorkshop()` pour forcer le téléchargement client des addons
- Installation d'addons utilitaires sur le serveur : AdvDupe2, Bodygroup Wardrobe, Standing Pose Tool

### Bug corrigé
- **Petite caisse ne matérialisait pas les ghosts** : `sv_ghosts.lua` vérifiait uniquement `crate:GetClass() ~= "construction_crate"`, rejetant la classe `construction_crate_small`. Corrigé pour accepter les deux classes.

---

## Récapitulatif

### Versions

| Version | Étape | Changement majeur |
|---------|-------|-------------------|
| v1.0 | 1-2 | Infrastructure Docker + MySQL |
| v1.1 | 2 | MySQLOO intégré |
| v2.0 | 3-5 | SWEP + Ghosts + Caisses (refonte complète) |
| v2.1 | 6 | Dossiers, import AD2, UI dark theme, petite caisse |
| v2.2 | 7-8 | Véhicules simfphys, publication Workshop |

### Images Docker

| Tag | Étape |
|-----|-------|
| `v1.0-base` / `v1.0-final` | 1 |
| `v1.1-mysql` | 2 |
| `v2-stable` | 5 |
| `v2.1-stable` | 6 |
| `v2.2-vehicles` | 7 |

### Statistiques du code

| Métrique | Valeur |
|----------|--------|
| Fichiers Lua | 16 modules + SWEP + 3 entités (9 fichiers) |
| Net messages | 16 |
| Entités custom | 3 (ghost, crate, crate_small) |
| Lignes de config | ~120 (sh_config.lua) |
| Tables MySQL | 3 (optionnel) |
