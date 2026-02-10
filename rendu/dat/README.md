# Dossier d'Architecture Technique (DAT)

## Système de Construction RP — Garry's Mod

**Projet Fil Rouge — B3 Cybersécurité, Efrei Bordeaux**

*Dernière modification : février 2026*

*Statut : Finalisé — v2.2*

*Modèle de référence : [bflorat/modele-da](https://github.com/bflorat/modele-da)*

---

Ce dossier est constitué de cinq vues :

1. [Vue applicative](#1-vue-applicative) — Contexte, objectifs, acteurs, architecture fonctionnelle
2. [Vue développement](#2-vue-développement) — Architecture logicielle, pile technique, patterns
3. [Vue infrastructure](#3-vue-infrastructure) — Hébergement, Docker, déploiement, disponibilité
4. [Vue dimensionnement](#4-vue-dimensionnement) — Performances, stockage, capacité
5. [Vue sécurité](#5-vue-sécurité) — Menaces, mesures, contrôle d'accès, audit

---

# 1. Vue applicative

## 1.1. Documentation de référence

| N° | Version | Titre / URL | Détail |
|----|---------|-------------|--------|
| 1 | — | [Garry's Mod Wiki](https://wiki.facepunch.com/gmod/) | Référence officielle GLua, entités, hooks, net library |
| 2 | 2.14.1 | [DarkRP](https://github.com/FPtje/DarkRP) | Gamemode roleplay, système de jobs, entités F4 |
| 3 | 9.7.6 | [MySQLOO](https://github.com/FredyH/MySQLOO) | Module binaire Lua pour requêtes MySQL asynchrones |
| 4 | — | [AdvDupe2](https://github.com/wiremod/advdupe2) | Référence pour le format de sérialisation (codec) |
| 5 | — | [simfphys](https://github.com/DevulTj/simfphys_base) | Framework véhicules physiques réalistes |
| 6 | — | [ceifa/garrysmod](https://hub.docker.com/r/ceifa/garrysmod) | Image Docker officielle serveur GMod |

## 1.2. Contexte général

### 1.2.1. Objectifs

Le projet répond à un double objectif :

**Objectif pédagogique** : Démontrer des compétences transversales en infrastructure (Docker), développement (GLua), base de données (MySQL), sécurité applicative et documentation technique, dans le cadre d'un Projet Fil Rouge B3 Cybersécurité.

**Objectif fonctionnel** : Développer un addon Garry's Mod autonome (publiable sur le Steam Workshop) qui introduit un système de **construction collaborative RP** sur des serveurs DarkRP. Un joueur au rôle de Constructeur sélectionne des props existants, les sauvegarde en « blueprint », puis les place comme fantômes holographiques. N'importe quel joueur peut ensuite matérialiser ces fantômes en utilisant des caisses de matériaux, créant un gameplay collaboratif de construction.

### 1.2.2. Existant

Avant ce projet, les outils de construction sur Garry's Mod se limitent à :

- **AdvDupe2** : Outil de duplication individuel. Pas de dimension collaborative, pas de matérialisation progressive, pas de gestion de ressources.
- **Precision Tool / Stacker** : Outils de positionnement, sans notion de blueprint ni de collaboration.
- **Build servers** : Serveurs sandbox sans gameplay RP — la construction n'a aucune dimension économique ou collaborative.

**Ce qui manque** : Un système qui intègre la construction dans le gameplay RP (jobs, économie, collaboration entre joueurs, logistique de transport).

### 1.2.3. Positionnement

L'addon s'inscrit comme une **extension DarkRP** qui ajoute un nouveau métier (Constructeur) et des entités interactives. Il est conçu pour être :

- **Standalone** : Aucune dépendance externe (pas besoin d'AdvDupe2, MySQLOO optionnel)
- **Workshop-ready** : Publiable et installable comme n'importe quel addon
- **Configurable** : Adaptable à n'importe quel serveur DarkRP (jobs, prix, limites)

### 1.2.4. Acteurs

#### Acteurs internes

| Acteur | Description | Population | Localisation |
|--------|-------------|------------|--------------|
| Constructeur | Joueur au job dédié. Sélectionne des props, crée des blueprints, place des fantômes. | 1-3 par serveur (configurable) | Client GMod |
| Joueur standard | Tout joueur connecté. Peut acheter et utiliser des caisses pour matérialiser des fantômes. | 2-64 | Client GMod |
| Administrateur serveur | Installe, configure l'addon, gère les permissions et les jobs DarkRP. | 1-2 | Console serveur / RCON |

#### Acteurs externes

| Acteur | Description | Population | Localisation |
|--------|-------------|------------|--------------|
| Steam Workshop | Plateforme de distribution de l'addon et du contenu (modèles, textures). | — | CDN Valve |
| MySQL | Base de données optionnelle pour les logs d'audit. | 1 instance | Container Docker |

### 1.2.5. Nature et sensibilité des données

| Donnée | Finalité | Classification | D | I | C | T |
|--------|----------|---------------|---|---|---|---|
| Blueprints (fichiers .dat) | Sauvegarde des constructions | Public | Moyen | Moyen | Faible | Faible |
| SteamID joueurs | Identification des propriétaires | Interne | Faible | Élevé | Moyen | Moyen |
| Logs d'actions (DB) | Audit, modération | Interne | Faible | Élevé | Moyen | Élevé |
| Configuration addon (sh_config.lua) | Paramétrage serveur | Interne | Élevé | Élevé | Moyen | Faible |
| Credentials MySQL | Accès base de données | Confidentiel | Moyen | Élevé | Élevé | Moyen |

*Légende : (D)isponibilité (I)ntégrité (C)onfidentialité (T)raçabilité — Faible / Moyen / Élevé*

## 1.3. Contraintes

### 1.3.1. Contraintes budgétaires

- **VPS Hostinger** : 16 Go RAM, seul serveur disponible. Pas de second serveur pour la redondance.
- **Aucun coût additionnel** : Pas de licence, pas de service cloud payant. Uniquement des outils open-source.

### 1.3.2. Contraintes planning

- Projet réalisé sur environ 12 étapes de développement.
- Deadline de rendu : 22/02/2026.

### 1.3.3. Contraintes techniques

- **Moteur Source** : Garry's Mod tourne sur le moteur Source (2004), avec ses limitations (pas de multithreading Lua, tick rate fixe, limite de 2048 entités).
- **GLua** : Langage basé sur Lua 5.1 avec des extensions spécifiques au moteur Source. Pas de typage statique, pas de modules npm/pip.
- **Docker** : L'image `ceifa/garrysmod` est la seule image Docker maintenue pour GMod. Les bind mounts ne supportent pas `resource.AddFile` (les fichiers custom ne sont pas servis aux clients).
- **Net library** : Les messages réseau GMod sont limités à 64 Ko par message et doivent être déclarés côté serveur via `util.AddNetworkString`.

### 1.3.4. Contraintes juridiques

- Les modèles 3D utilisés (caisses WW2, viewmodel Fortnite) sont issus du Steam Workshop sous licence communautaire.
- Le décodeur AdvDupe2 est sous licence Apache 2.0 (attribution requise).
- L'addon est publié sous licence MIT.

## 1.4. Exigences

### 1.4.1. Exigences fonctionnelles

| ID | Exigence | Priorité |
|----|----------|----------|
| EF-01 | Un joueur autorisé peut sélectionner des `prop_physics` dont il est propriétaire | Critique |
| EF-02 | Les props sélectionnés peuvent être sérialisés en blueprint (positions relatives, modèles, angles) | Critique |
| EF-03 | Les blueprints sont sauvegardés localement sur le PC du joueur (illimité) | Critique |
| EF-04 | Un blueprint chargé génère des fantômes holographiques visibles par tous | Critique |
| EF-05 | N'importe quel joueur avec une caisse active peut matérialiser un fantôme | Critique |
| EF-06 | Les caisses sont achetables au menu F4 DarkRP | Importante |
| EF-07 | Les caisses peuvent être transportées dans des véhicules simfphys | Importante |
| EF-08 | L'import de fichiers AdvDupe2 (.txt) est supporté sans dépendance | Souhaitable |
| EF-09 | L'interface permet l'organisation en sous-dossiers | Souhaitable |

### 1.4.2. Exigences d'interopérabilité

| Système | Type de compatibilité | Détail |
|---------|----------------------|--------|
| DarkRP | Intégration native | Jobs, entités F4, monnaie, TEAM_ IDs |
| FPP (Falco's Prop Protection) | Compatibilité CPPI | Hooks PhysgunPickup, CanTool, GravGunPickup |
| simfphys | Intégration véhicules | SetParent, offsets calibrés, détection par classe |
| LVS | Support basique | Détection automatique, offsets par défaut |
| AdvDupe2 | Import fichiers | Décodeur binaire embarqué (rev4/5) |

### 1.4.3. Exigences de modes dégradés

| Composant absent | Comportement |
|-----------------|--------------|
| MySQL / MySQLOO | L'addon fonctionne normalement. Seuls les logs DB sont désactivés. |
| simfphys | Tout fonctionne sauf le transport en véhicule. |
| FPP | La vérification d'ownership est désactivée (tout joueur peut sélectionner tout prop). |
| Content pack WW2 | Les caisses apparaissent comme des ERROR models. Fonctionnel mais visuellement cassé. |

## 1.5. Architecture cible

### 1.5.1. Architecture applicative générale

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
│  Stockage local: data/construction_blueprints/*.dat (JSON)     │
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
│  sh_config.lua (partagé client+serveur)        │               │
└────────────────────────────────────────────────┼───────────────┘
                                                 │
                                          ┌──────┴──────┐
                                          │  MySQL 8.0  │
                                          │ (optionnel) │
                                          └─────────────┘
```

### 1.5.2. Inventaire des modules

| Module | Côté | Rôle | Lignes (approx.) |
|--------|------|------|-------------------|
| `sh_config.lua` | Partagé | Configuration centralisée (limites, jobs, DB, net messages) | ~100 |
| `sv_blueprints.lua` | Serveur | Sérialisation/désérialisation, validation des données, RebuildVectors | ~350 |
| `sv_ghosts.lua` | Serveur | Spawn/suppression des ghost entities, matérialisation | ~200 |
| `sv_selection.lua` | Serveur | Toggle/radius/clear, vérification ownership CPPI | ~150 |
| `sv_permissions.lua` | Serveur | Partage de blueprints entre joueurs | ~100 |
| `sv_security.lua` | Serveur | Rate limiting (60 req/min), commandes admin | ~130 |
| `sv_logging.lua` | Serveur | Logs console + DB optionnelle | ~50 |
| `sv_database.lua` | Serveur | Connexion MySQLOO, CRUD, prepared statements | ~350 |
| `sv_vehicles.lua` | Serveur | Attach/detach caisses sur véhicules, offsets calibrés | ~200 |
| `cl_blueprints.lua` | Client | Stockage local data/, gestion fichiers, dossiers | ~200 |
| `cl_ad2_decoder.lua` | Client | Décodeur binaire AdvDupe2 rev4/5 (décompression, parsing) | ~300 |
| `cl_menu.lua` | Client | Interface Derma complète (sidebar, breadcrumb, 3 onglets) | ~500 |
| `cl_placement.lua` | Client | Preview ClientsideModel, rotation, hauteur, confirmation | ~250 |
| `cl_selection.lua` | Client | Rendu halos bleus, HUD compteur de sélection | ~100 |
| `cl_vehicles.lua` | Client | HUD véhicule (instructions), bind PlayerBindPress | ~80 |
| `weapon_construction.lua` | Partagé | SWEP : LMB sélection, RMB zone, Shift+RMB menu, R véhicule | ~200 |

**Total estimé** : ~3 260 lignes de code GLua

### 1.5.3. Entités custom

| Entité | Type | Base | Solid | Rôle |
|--------|------|------|-------|------|
| `construction_ghost` | Scripted | `base_anim` | SOLID_NONE | Fantôme holographique translucide bleu. Matérialisable via Use + caisse active. Timer auto-remove configurable. |
| `construction_crate` | Scripted | `base_anim` | SOLID_VPHYSICS | Grosse caisse (50 matériaux). Activable via Use. Transportable en véhicule simfphys. Affichage 3D2D (barre de progression + compteur). |
| `construction_crate_small` | Scripted | `base_anim` | SOLID_VPHYSICS | Petite caisse (15 matériaux). Même logique que la grosse caisse, modèle et capacité différents. |

### 1.5.4. Matrice des flux applicatifs

| Source | Destination | Protocole | Message | Mode |
|--------|-------------|-----------|---------|------|
| Client | Serveur | Net (UDP) | `Construction_SelectToggle` | Écriture |
| Client | Serveur | Net (UDP) | `Construction_SelectRadius` | Écriture |
| Client | Serveur | Net (UDP) | `Construction_SelectClear` | Écriture |
| Client | Serveur | Net (UDP) | `Construction_SaveBlueprint` | Écriture |
| Client | Serveur | Net (UDP) | `Construction_LoadBlueprint` | Écriture |
| Client | Serveur | Net (UDP) | `Construction_ConfirmPlacement` | Écriture |
| Client | Serveur | Net (UDP) | `Construction_CancelPlacement` | Écriture |
| Client | Serveur | Net (UDP) | `Construction_MaterializeGhost` | Écriture |
| Client | Serveur | Net (UDP) | `Construction_VehicleReload` | Écriture |
| Client | Serveur | Net (UDP) | `Construction_RequestSync` | Lecture |
| Serveur | Client | Net (UDP) | `Construction_SyncSelection` | Lecture |
| Serveur | Client | Net (UDP) | `Construction_SaveToClient` | Lecture |
| Serveur | Client | Net (UDP) | `Construction_SendPreview` | Lecture |
| Serveur | Client | Net (UDP) | `Construction_OpenMenu` | Appel |
| Serveur | MySQL | TCP 3306 | Requêtes SQL (prepared statements) | Lecture/Écriture |
| Client | Disque local | Fichier | `data/construction_blueprints/*.dat` | Lecture/Écriture |

---

# 2. Vue développement

## 2.1. Pile logicielle

### 2.1.1. Filière technique retenue

| Composant | Technologie | Version | Justification |
|-----------|-------------|---------|---------------|
| Langage | GLua (Garry's Mod Lua) | Lua 5.1 | Seul langage supporté par le moteur Source/GMod. Pas de choix alternatif. |
| Gamemode | DarkRP | 2.14.x | Standard de facto pour le roleplay GMod (~80% des serveurs RP). Écosystème mature, documentation riche. |
| Module DB | MySQLOO | 9.7.6 | Seul module MySQL maintenu pour GMod. Alternative : SQLite natif, mais limité en fonctionnalités. |
| BDD | MySQL | 8.0 | Robuste, documenté, compatible MySQLOO. Alternative : MariaDB (compatible). |
| Conteneurisation | Docker + Compose | 24.x | Reproductibilité, isolation, snapshots via `docker commit`. |
| Image Docker | `ceifa/garrysmod` | latest | Seule image Docker maintenue activement pour les serveurs GMod. |
| Versioning | Git + GitHub | — | Standard, gratuit, public. |
| Véhicules | simfphys | — | Framework véhicules le plus utilisé sur GMod (~90% des serveurs RP avec véhicules). |

### 2.1.2. Dépendances

| Dépendance | Rôle | Version | Obligatoire ? |
|------------|------|---------|---------------|
| Garry's Mod (serveur dédié) | Runtime | dernière | Oui |
| DarkRP | Gamemode RP | 2.14.x | Oui |
| MySQLOO | Connecteur MySQL | 9.7.6 | Non (logs seulement) |
| MySQL 8.0 | Base de données | 8.0 | Non |
| simfphys | Véhicules physiques | dernière | Non (transport caisses) |
| Content pack WW2 (Workshop 3008026539) | Modèles 3D caisses | — | Oui (visuels) |

## 2.2. Architecture logicielle

### 2.2.1. Principes ayant dicté les choix

1. **Séparation stricte client/serveur** : Le client n'a aucune autorité. Chaque action est envoyée par net message et re-validée côté serveur (permissions, rate limit, ownership, limites). Le client gère uniquement l'affichage et le stockage local.

2. **Configuration centralisée** : Un seul fichier `sh_config.lua` partagé client+serveur. Toutes les limites, cooldowns, jobs, modèles y sont définis. Pas de valeurs hardcodées dans le code.

3. **Pas de dépendances** : L'addon embarque son propre décodeur AdvDupe2 au lieu de dépendre de l'installation d'AdvDupe2. MySQL est optionnel. L'addon fonctionne en standalone.

4. **Prefixage des fichiers** : Convention `sv_` (serveur), `cl_` (client), `sh_` (partagé) pour une identification immédiate du contexte d'exécution.

5. **Sécurité by design** : Rate limiting, validation d'entrées, blacklists, CPPI ownership intégrés dès la conception, pas ajoutés après coup.

### 2.2.2. Patterns notables

| Pattern | Utilisation | Détail |
|---------|-------------|--------|
| Observer (hooks) | Sécurité, intégration DarkRP | `CanTool`, `PhysgunPickup`, `PlayerLoadout` pour intercepter les actions |
| Command (net messages) | Toute communication C→S | Le client envoie une commande, le serveur l'exécute après validation |
| Strategy (offsets véhicules) | Transport caisses | Table de lookup `CargoOffsets[class]` avec fallback sur calcul dynamique via OBB |
| Factory (entités) | Spawn de ghosts/caisses | `ents.Create()` avec configuration dynamique depuis le blueprint |
| Singleton (config) | Configuration globale | `ConstructionSystem.Config` accessible partout |

### 2.2.3. Gestion de la robustesse

**Gestion des erreurs** :
- Chaque `net.Receive` vérifie `IsValid(ply)` et le rate limit avant toute logique
- Les accès fichiers (client) sont wrappés dans des vérifications d'existence
- Les requêtes MySQL ont des callbacks `onError` avec logging

**Gestion de la concurrence** :
- Un seul joueur peut sélectionner un prop donné à la fois (table `SelectedBy`)
- Rate limiting global (60 req/min) empêche le flooding
- Cooldowns par action (save: 10s, load: 15s) empêchent les requêtes multiples

**Modes dégradés** :
- Si MySQLOO n'est pas installé ou la connexion échoue → logs console uniquement
- Si le véhicule est supprimé pendant le transport → la caisse est automatiquement déparentée via Think loop
- Si un blueprint contient des classes non autorisées → les props concernés sont ignorés (pas de crash)

### 2.2.4. Gestion de la configuration

Toute la configuration est centralisée dans `sh_config.lua` :

```lua
ConstructionSystem.Config = {
    -- Limites
    MaxPropsPerBlueprint = 150,
    MaxCratesPerPlayer = 2,
    MaxNameLength = 50,
    MaxDescLength = 200,

    -- Cooldowns (secondes)
    SaveCooldown = 10,
    LoadCooldown = 15,

    -- Sélection
    SelectionRadiusMin = 50,
    SelectionRadiusMax = 1000,
    SelectionRadiusDefault = 500,

    -- Caisses
    CrateModel = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl",
    CrateMaxMaterials = 50,
    SmallCrateModel = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl",
    SmallCrateMaxMaterials = 15,

    -- Jobs (nil = tout le monde)
    AllowedJobs = nil,
    SWEPJobs = nil,
    CrateAllowedJobs = nil,

    -- Blacklist
    BlacklistedEntities = {"money_printer", "drug_lab", ...},
    AllowedClasses = {["prop_physics"] = true},

    -- DB (optionnelle)
    DB = {Host = "gmod-mysql", Port = 3306, ...},
}
```

L'administrateur serveur modifie uniquement ce fichier pour adapter l'addon à son serveur.

### 2.2.5. Versioning et branches

- **Branche unique** : `main` (pas de branches feature pour un projet solo)
- **Commits conventionnels** : `feat:`, `fix:`, `docs:`, `refactor:`
- **Tags Docker** : Chaque état stable est sauvegardé via `docker commit` (v1.0-base, v1.1-mysql, v2-stable, v2.1-stable, v2.2-vehicles)

## 2.3. Flux de données détaillés

### 2.3.1. Sauvegarde d'un blueprint

```
1. Joueur sélectionne des props (LMB/RMB sur le SWEP)
   → Client: halos bleus, HUD compteur
   → Serveur: table SelectedProps[ply] mise à jour

2. Joueur ouvre le menu (Shift+RMB) → onglet Sauvegarder
   → Client: cl_menu.lua affiche l'interface Derma

3. Joueur entre un nom + description → clic "Sauvegarder"
   → Client envoie net "Construction_SaveBlueprint"
   → Données: nom (string), description (string), dossier (string)

4. Serveur reçoit le message
   → sv_security: vérification rate limit (cooldown 10s)
   → sv_blueprints: Serialize()
     - HeadEnt = premier prop sélectionné
     - Pour chaque prop: position relative à HeadEnt, modèle, angles, frozen state
     - Résultat: table Lua → util.TableToJSON()

5. Serveur renvoie les données au client
   → net "Construction_SaveToClient" (JSON compressé si > 64Ko)

6. Client reçoit et sauvegarde
   → cl_blueprints: file.Write("construction_blueprints/<dossier>/<nom>.dat", json)
   → Notification de succès
```

### 2.3.2. Chargement et placement

```
1. Client lit le fichier .dat local → file.Read()
   → Parse JSON → envoie net "Construction_LoadBlueprint"

2. Serveur valide le blueprint
   → ValidateBlueprintData(): classes autorisées, nombre de props, données cohérentes
   → RebuildVectors(): conversion "x y z" strings → Vector()
   → Renvoie net "Construction_SendPreview"

3. Client affiche la prévisualisation
   → cl_placement.lua: ClientsideModels positionnés autour du curseur
   → Rotation (molette), hauteur (Shift+molette)

4. Joueur confirme (LMB)
   → net "Construction_ConfirmPlacement" (position, angle)

5. Serveur spawn les ghosts
   → sv_ghosts: SpawnGhosts() — batch de 5 par tick (anti-lag)
   → Chaque ghost: construction_ghost entity (SOLID_NONE, bleu translucide)
```

### 2.3.3. Matérialisation

```
1. Joueur Use (E) sur une caisse
   → Serveur: ply.ActiveCrate = crate (NWEntity)

2. Joueur Use (E) sur un ghost
   → Client envoie net "Construction_MaterializeGhost"

3. Serveur vérifie:
   → ActiveCrate IsValid, matériaux > 0, ghost IsValid
   → crate:UseMaterial() → matériaux -= 1
   → ghost:Materialize() → spawn prop_physics réel
   → Le prop appartient au joueur (CPPI ownership)
   → Ghost supprimé, effet sonore + particules
```

### 2.3.4. Transport véhicule

```
CHARGEMENT (touche R):
1. Client: SWEP:Reload() → net "Construction_VehicleReload"
2. Serveur: trace du joueur → véhicule simfphys détecté
3. Recherche caisse non-chargée à proximité (500 unités)
4. LoadCrate():
   - crate:SetParent(vehicle)
   - phys:EnableMotion(false), SetSolid(SOLID_NONE)
   - SetLocalPos(offset calibré par modèle)
   - NWBool "IsLoaded" = true

DÉCHARGEMENT (touche R):
1. Client: SWEP:Reload() → net "Construction_VehicleReload"
2. Serveur: trace → véhicule → cherche caisse chargée
3. UnloadCrate():
   - Calcul dropPos (côté du véhicule)
   - SetParent(nil) → timer.Simple(0) → SetPos(dropPos)
   - Restore: SOLID_VPHYSICS, EnableMotion(true), Wake()
```

---

# 3. Vue infrastructure

## 3.1. Architecture d'hébergement

### 3.1.1. Serveur physique

| Caractéristique | Valeur |
|----------------|--------|
| Fournisseur | Hostinger |
| Type | VPS KVM |
| OS | Ubuntu (Linux 6.8.0) |
| RAM totale | 16 Go |
| CPU | Multi-core (détail non spécifié) |
| Stockage | SSD |
| IP publique | Fixe |
| Localisation | Europe |

### 3.1.2. Architecture Docker

```
VPS Hostinger (16 Go RAM)
│
├── Container: gmod-server
│   ├── Image: projetfilrouge/gmod-server:v2.2-vehicles
│   ├── Ports: 27015 TCP/UDP (Source Engine)
│   ├── Limites: 3 Go RAM, 2 CPUs
│   ├── Volumes:
│   │   ├── gmod-server-data (named) → /home/gmod/server
│   │   ├── ./addons → /home/gmod/server/garrysmod/addons (bind)
│   │   ├── ./gamemodes/darkrp → gamemodes/darkrp (bind)
│   │   ├── ./lua-bin → lua/bin (bind)
│   │   ├── ./server-config/server.cfg → cfg/server.cfg (bind)
│   │   └── ./download → garrysmod/download (bind)
│   ├── Env:
│   │   ├── GAMEMODE=darkrp
│   │   ├── MAP=falaise_lbrp_v1
│   │   └── ARGS=+host_workshop_collection 2270926906
│   └── Restart: unless-stopped
│
├── Container: gmod-mysql
│   ├── Image: mysql:8.0
│   ├── Port: 3306 (interne Docker)
│   ├── Limites: 512 Mo RAM, 0.5 CPU
│   ├── Volumes:
│   │   ├── ./mysql-data → /var/lib/mysql (bind)
│   │   └── ./mysql-init → /docker-entrypoint-initdb.d (bind)
│   ├── Healthcheck: mysqladmin ping (30s interval)
│   └── Restart: unless-stopped
│
└── Volume nommé: gmod-server-data
```

### 3.1.3. Justification des choix d'infrastructure

| Choix | Justification | Alternatives considérées |
|-------|---------------|-------------------------|
| Docker | Isolation, reproductibilité, snapshots via `docker commit` | Installation native (rejetée : non reproductible, pollution du VPS) |
| `ceifa/garrysmod` | Seule image Docker maintenue pour GMod | `cm2network/steamcmd` (rejetée : pas spécifique GMod, configuration manuelle) |
| MySQL 8.0 | Robuste, compatible MySQLOO, container Docker officiel | SQLite (rejetée : pas d'accès concurrent, pas de requêtes distantes), PostgreSQL (rejetée : pas de module GMod) |
| Volume nommé + bind mounts | Le volume nommé persiste les données workshop (~8 Go). Les bind mounts permettent l'édition live des addons/config. | Volumes nommés uniquement (rejeté : pas d'édition live en dev) |
| `docker commit` pour snapshots | Évite de re-télécharger ~8 Go de Workshop à chaque rebuild | Docker registry privé (rejeté : surcoût, complexité inutile) |

## 3.2. Composants d'infrastructure

| Composant | Rôle | Version | Environnement |
|-----------|------|---------|---------------|
| Docker Engine | Conteneurisation | 24.x | VPS Ubuntu |
| Docker Compose | Orchestration | v2 | VPS Ubuntu |
| Garry's Mod Dedicated Server | Serveur de jeu | Build récent | Container `gmod-server` |
| DarkRP | Gamemode RP | 2.14.x | Addon dans container |
| MySQL Server | Base de données | 8.0 | Container `gmod-mysql` |
| MySQLOO | Module Lua binaire | 9.7.6 | Bind mount lua/bin |
| Workshop Collection | 101 addons (~8 Go) | — | Stocké dans volume nommé |

## 3.3. Matrice des flux techniques

| ID | Source | Destination | Réseau | Protocole | Port | Chiffré ? |
|----|--------|-------------|--------|-----------|------|-----------|
| F1 | Client GMod | gmod-server | Internet | UDP (Source Engine) | 27015 | Non (protocole Source) |
| F2 | Client GMod | gmod-server | Internet | TCP (RCON) | 27015 | Non |
| F3 | gmod-server | gmod-mysql | Docker bridge | TCP (MySQL) | 3306 | Non (réseau interne) |
| F4 | Client GMod | Steam Workshop | Internet | HTTPS | 443 | Oui |
| F5 | Admin | VPS | Internet | SSH | 22 | Oui |

## 3.4. Déploiement

### 3.4.1. Déploiement initial

```bash
# 1. Cloner le dépôt
git clone https://github.com/[repo].git
cd ProjetFilRouge/docker

# 2. Démarrer l'infrastructure
docker compose up -d

# 3. Attendre le téléchargement Workshop (~5-10 min)
docker logs -f gmod-server

# 4. Sauvegarder l'image avec Workshop
docker commit gmod-server projetfilrouge/gmod-server:stable

# 5. Modifier docker-compose.yml pour utiliser l'image commitée
# image: projetfilrouge/gmod-server:stable
```

### 3.4.2. Mise à jour de l'addon

```bash
# 1. Modifier les fichiers Lua dans docker/addons/rp_construction_system/
# 2. Le serveur charge automatiquement les fichiers au prochain changelevel
# 3. Les clients doivent se reconnecter pour recevoir les fichiers mis à jour
```

### 3.4.3. Points importants

- `docker restart` ne recharge **pas** les variables d'environnement du compose. Toujours utiliser `docker compose up -d` pour les changements de configuration.
- `resource.AddFile` ne fonctionne pas avec les bind mounts Docker. Les modèles custom doivent être distribués via Workshop.
- Le client GMod cache agressivement les fichiers Lua. Après une modification serveur, le client doit se reconnecter (`retry` en console).

## 3.5. Disponibilité

| Métrique | Valeur | Justification |
|----------|--------|---------------|
| Plage de fonctionnement | 24/7 | Serveur de jeu, joueurs à toute heure |
| SLA visé | ~95% | Projet de développement, pas de production critique |
| MTTR estimé | < 30 min | Restauration via `docker compose up -d` avec image commitée |
| RPO | 0 (blueprints) | Les blueprints sont stockés localement sur le PC du joueur |
| RPO | ~24h (logs DB) | Pas de réplication MySQL |
| Redondance | Aucune | Contrainte budgétaire — un seul VPS |

---

# 4. Vue dimensionnement

## 4.1. Contraintes

### 4.1.1. Contraintes de stockage

| Donnée | Taille unitaire | Volume estimé | Croissance |
|--------|----------------|---------------|------------|
| Workshop Collection | ~8 Go | Fixe | ~100 Mo/mois (mises à jour) |
| Image Docker commitée | ~10 Go | 1 par version stable | ~10 Go par snapshot |
| Blueprints (client) | 1-50 Ko par fichier | Illimité par joueur | Variable |
| Logs MySQL | ~100 octets par entrée | ~10 000 entrées/mois | Linéaire |
| MySQL data files | ~50 Mo | Fixe | Faible |

### 4.1.2. Contraintes mémoire

| Composant | Alloué | Utilisé estimé | Justification |
|-----------|--------|----------------|---------------|
| Container GMod | 3 Go max | 1.5-2.5 Go | Source Engine + 101 addons Workshop + Lua VM |
| Container MySQL | 512 Mo max | 100-200 Mo | Base quasi-vide (optionnelle) |
| VPS total | 16 Go | ~12 Go disponible (hors OS) | Marge confortable |

### 4.1.3. Contraintes réseau

| Flux | Bande passante estimée | Détail |
|------|----------------------|--------|
| Gameplay Source Engine | 20-100 Kbps par joueur | Protocole UDP Source, tick rate 33 |
| Net messages addon | < 5 Kbps par joueur | Messages courts, rate limited |
| Workshop download (initial) | ~8 Go (one-time) | Téléchargement au premier lancement |
| MySQL | Négligeable | Réseau Docker interne, requêtes légères |

## 4.2. Exigences de performance

### 4.2.1. Temps de réponse

| Action | Temps acceptable | Temps mesuré | Détail |
|--------|-----------------|-------------|--------|
| Sélection d'un prop (LMB) | < 100 ms | ~50 ms | Net message + réponse serveur |
| Ouverture du menu | < 200 ms | ~100 ms | Lecture fichiers locaux + affichage Derma |
| Sauvegarde blueprint | < 2 s | ~500 ms | Sérialisation serveur + écriture client |
| Chargement blueprint (50 props) | < 3 s | ~1 s | Validation serveur + spawn ghosts (batch 5/tick) |
| Matérialisation d'un ghost | < 200 ms | ~100 ms | Spawn prop + suppression ghost |
| Chargement caisse véhicule | < 500 ms | ~200 ms | SetParent + physics disable |

### 4.2.2. Limites du système

| Paramètre | Limite | Raison |
|-----------|--------|--------|
| Props par blueprint | 150 (configurable) | Performance serveur + limite entités Source (~2048) |
| Caisses par joueur | 2 | Éviter l'encombrement + performance |
| Caisses par véhicule | 2 | Espace cargo limité, offsets calibrés |
| Net messages | 60 req/min par joueur | Anti-spam |
| Rayon de sélection | 50-1000 unités | UInt(10) côté net = max 1023 |
| Taille nom blueprint | 50 caractères | Limitation UI + validation |

## 4.3. Dimensionnement cible

| Ressource | Besoin | Configuration actuelle | Marge |
|-----------|--------|----------------------|-------|
| RAM serveur GMod | 1.5-2.5 Go | 3 Go max | +20-50% |
| CPU serveur GMod | 1-1.5 cores | 2 cores | +33-50% |
| RAM MySQL | 100-200 Mo | 512 Mo max | +150% |
| Stockage Docker | ~20 Go | SSD VPS | OK |
| Joueurs simultanés | 2-10 (dev) | MAXPLAYERS=2 (dev) | Configurable jusqu'à 64 |

---

# 5. Vue sécurité

## 5.1. Analyse des menaces

### 5.1.1. Surface d'attaque

| Vecteur | Risque | Probabilité | Impact |
|---------|--------|-------------|--------|
| Net message flooding | Saturation serveur, crash | Élevée | Élevé |
| Injection de données blueprint | Spawn d'entités interdites (money_printer, etc.) | Moyenne | Élevé |
| SQL injection via MySQLOO | Accès/modification de la base | Faible | Critique |
| Usurpation d'ownership CPPI | Sélection de props d'autres joueurs | Faible | Moyen |
| Exploit via entités custom | Crash serveur, manipulation de state | Faible | Élevé |
| RCON brute force | Accès admin au serveur | Moyenne | Critique |
| Exploitation Docker | Escape du container | Très faible | Critique |

### 5.1.2. Données sensibles

| Donnée | Stockage | Niveau de confidentialité | Mesures |
|--------|----------|--------------------------|---------|
| Mot de passe RCON | server.cfg (container) | Confidentiel | Non exposé aux joueurs, accès SSH uniquement |
| Credentials MySQL | sh_config.lua (serveur) | Confidentiel | Fichier serveur uniquement (`AddCSLuaFile` non appelé pour ce contenu). En production : variables d'environnement recommandées |
| SteamID joueurs | Mémoire serveur + logs DB | Interne | Information semi-publique sur Steam |
| Blueprints | Client local | Public | Données non sensibles (positions de props) |

## 5.2. Mesures de sécurité implémentées

### 5.2.1. Rate Limiting

```
Couche 1 : Rate limit global
  → 60 requêtes/minute par joueur (tous net messages confondus)
  → Compteur réinitialisé chaque minute
  → Dépassement → message ignoré + log serveur

Couche 2 : Cooldowns par action
  → Sauvegarde : 10 secondes
  → Chargement : 15 secondes
  → Véhicule : 1 seconde
  → Dépassement → notification au joueur + refus

Couche 3 : Nettoyage
  → PlayerDisconnected → suppression du compteur (pas de fuite mémoire)
```

### 5.2.2. Validation des entrées

| Donnée | Validation | Mesure |
|--------|-----------|--------|
| Nom de blueprint | `string.sub(name, 1, 50)` | Troncature à 50 caractères |
| Description | `string.sub(desc, 1, 200)` | Troncature à 200 caractères |
| Rayon de sélection | `math.Clamp(radius, 50, 1000)` | Borné aux limites config |
| Nombre de props | `#props <= MaxPropsPerBlueprint` | Rejet si dépassement |
| Classe d'entité | `AllowedClasses[class]` | Seul `prop_physics` autorisé |
| Modèle | Vérification d'existence | `util.IsValidModel(model)` |
| Entity références | `IsValid(ent)` | Vérification avant chaque opération |

### 5.2.3. Blacklist d'entités

```lua
BlacklistedEntities = {
    "prop_physics_multiplayer",
    "money_printer", "darkrp_money", "spawned_money",
    "spawned_shipment", "spawned_weapon",
    "drug_lab", "gun_lab", "microwave",
    "bitminers_"  -- pattern matching
}
```

Toute tentative de sauvegarder un blueprint contenant une classe blacklistée est rejetée côté serveur.

### 5.2.4. SQL Injection

- **Toutes les requêtes** utilisent des **prepared statements** MySQLOO
- Aucune concaténation de chaînes dans les requêtes SQL
- Exemple :
```lua
local q = db:prepare("INSERT INTO blueprint_logs (steam_id, player_name, action) VALUES (?, ?, ?)")
q:setString(1, ply:SteamID())
q:setString(2, ply:Nick())
q:setString(3, action)
q:start()
```

### 5.2.5. Contrôle d'accès

| Contrôle | Implémentation | Granularité |
|----------|---------------|-------------|
| Ownership CPPI | `ent:CPPIGetOwner() == ply` | Par prop individuel |
| Restriction job SWEP | `SWEPJobs` config + hook `PlayerLoadout` | Par job DarkRP |
| Restriction job caisses | `CrateAllowedJobs` + hook `CanPlayerUse` | Par job DarkRP |
| F4 entity spawn | `allowed = {TEAM_X}` dans DarkRP entities.lua | Par job DarkRP |
| FPP hooks | `PhysgunPickup`, `CanTool`, `GravGunPickupAllowed` | Par entité + propriétaire |
| Commandes admin | `ply:IsSuperAdmin()` | Par rang |
| Caisses chargées | `IsLoaded` NWBool → physgun/gravgun bloqué | Par état de la caisse |

### 5.2.6. Intégrité client/serveur

Le principe fondamental : **le client n'a jamais raison**.

| Action client | Vérification serveur |
|--------------|---------------------|
| Sélectionner un prop | IsValid(ent), ent:GetClass() == "prop_physics", CPPIGetOwner == ply |
| Sauvegarder | Rate limit, props valides, ownership, nombre max |
| Charger un blueprint | Rate limit, ValidateBlueprintData (classes, limites, cohérence) |
| Confirmer placement | Rate limit, données preview existent, position valide |
| Matérialiser | ActiveCrate IsValid, matériaux > 0, ghost IsValid |
| Véhicule reload | Rate limit, trace valide, véhicule simfphys, caisse à proximité |

### 5.2.7. Sécurité Docker

| Mesure | Détail |
|--------|--------|
| Limites de ressources | `mem_limit: 3G`, `cpus: 2.0` pour GMod ; `mem_limit: 512M` pour MySQL |
| Réseau isolé | MySQL uniquement accessible via le réseau Docker interne (pas de port exposé en production) |
| Healthcheck | MySQL ping toutes les 30s, restart automatique si échec |
| Données persistantes | Bind mounts pour les données modifiables, volume nommé pour le Workshop |
| Pas de `--privileged` | Containers en mode non-privilégié |

## 5.3. Traçabilité et audit

### 5.3.1. Logs serveur (console)

Chaque action significative est loguée en console serveur :
```
[Construction] Player "John" (STEAM_0:0:12345) saved blueprint "maison" (45 props)
[Construction] Player "Jane" (STEAM_0:1:67890) materialized ghost #123
[Construction] RATE LIMIT: Player "Spammer" (STEAM_0:0:99999) - 61 req/min
```

### 5.3.2. Logs base de données (optionnel)

Table `blueprint_logs` :

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | BIGINT AUTO_INCREMENT | Identifiant unique |
| `steam_id` | VARCHAR(32) | SteamID de l'acteur |
| `player_name` | VARCHAR(64) | Nom du joueur |
| `action` | VARCHAR(32) | Type d'action (save, load, delete, share) |
| `details` | TEXT | Détails supplémentaires (nom blueprint, nombre props) |
| `ip_address` | VARCHAR(45) | Adresse IP du joueur |
| `created_at` | TIMESTAMP | Date/heure de l'action |

Index : `steam_id`, `action`, `created_at` pour des requêtes d'audit performantes.

### 5.3.3. Commandes d'audit admin

| Commande | Accès | Description |
|----------|-------|-------------|
| `construction_logs [n]` | Superadmin | Affiche les n derniers logs (défaut: 20, max: 100) |
| `construction_stats` | Superadmin | Statistiques globales (blueprints, builders, props, logs, partages) |

---

# Glossaire

| Terme | Définition |
|-------|------------|
| **Blueprint** | Sauvegarde sérialisée d'un ensemble de props (positions, modèles, angles). Stocké en JSON dans un fichier `.dat` sur le PC du joueur. |
| **Ghost / Fantôme** | Entité `construction_ghost` — prop holographique bleu translucide, non-solide. Représente un prop à construire. |
| **Matérialisation** | Action de transformer un ghost en vrai `prop_physics` solide, en consommant 1 matériau d'une caisse. |
| **Caisse de matériaux** | Entité `construction_crate` ou `construction_crate_small` — conteneur de matériaux achetable au F4, utilisable pour matérialiser des ghosts. |
| **SWEP** | Scripted Weapon — arme Lua custom dans GMod. Ici : `weapon_construction`. |
| **CPPI** | Common Prop Protection Interface — API standard pour vérifier la propriété des entités (compatible FPP, SPP, etc.). |
| **DarkRP** | Gamemode roleplay pour Garry's Mod. Système de jobs, économie, entités F4. |
| **simfphys** | Framework de véhicules physiques réalistes pour GMod. |
| **Net message** | Message réseau envoyé entre client et serveur via la net library de GMod (UDP). |
| **GLua** | Garry's Mod Lua — dialecte Lua 5.1 avec extensions Source Engine. |
| **Bind mount** | Volume Docker monté depuis un chemin du host vers le container. |
| **MySQLOO** | Module binaire (.dll) pour GMod permettant des requêtes MySQL asynchrones. |
| **Rate limiting** | Mécanisme limitant le nombre de requêtes par unité de temps pour prévenir les abus. |
| **Prepared statement** | Requête SQL précompilée avec paramètres. Prévient l'injection SQL. |
| **FPP** | Falco's Prop Protection — système de protection des props intégré à DarkRP. |
