# Projet Fil Rouge — Système de Construction RP (Garry's Mod)

**Projet B3 Cybersécurité** — Mise en place d'un environnement de développement complet (Docker, MySQL, DarkRP) et développement d'un addon Garry's Mod de construction collaborative.

## Objectif

Documenter l'ensemble du processus de création d'un addon Garry's Mod professionnel, de l'infrastructure serveur jusqu'au produit fini publiable sur le Steam Workshop :

1. **Environnement Docker** — Conteneurisation d'un serveur Garry's Mod + MySQL
2. **Configuration DarkRP** — Serveur de test réaliste avec jobs, entités, catégories
3. **Développement addon** — Système de construction RP collaboratif
4. **Tests & Remédiation** — Debug en conditions réelles, résolution d'erreurs
5. **Documentation** — Guides d'installation, d'utilisation, architecture technique

## Structure du projet

```
ProjetFilRouge/
├── addon/rp_construction_system/    # 🎯 Addon standalone (workshop-ready)
│   ├── lua/                         #    Code source complet
│   ├── sql/schema.sql               #    Schéma base de données
│   └── README.md                    #    Documentation addon
├── docker/                          # 🐳 Environnement de développement
│   ├── docker-compose.yml           #    Orchestration GMod + MySQL
│   ├── addons/                      #    Addons montés dans le container
│   │   ├── rp_construction_system/  #    Addon (copie de dev)
│   │   └── darkrpmodification/      #    Config DarkRP (jobs, entities)
│   ├── gamemodes/                   #    DarkRP gamemode
│   └── lua-bin/                     #    MySQLOO binaires
├── docs/                            # 📚 Documentation technique
│   ├── ARCHITECTURE.md              #    Architecture du système
│   ├── GUIDE_INSTALLATION.md        #    Guide d'installation Docker
│   └── GUIDE_UTILISATEUR.md         #    Guide d'utilisation en jeu
├── schemas/                         #    Schémas et diagrammes
├── screenshots/                     #    Captures d'écran
├── scripts/                         #    Scripts utilitaires
├── livrables/                       #    Documents de rendu
└── README.md                        #    Ce fichier
```

## Acheminement du projet

### Phase 1 — Infrastructure Docker

Création d'un environnement de développement conteneurisé pour isoler le serveur de test :

- **Image** : `ceifa/garrysmod` (serveur Garry's Mod Linux)
- **Base de données** : MySQL 8.0 (container séparé)
- **Orchestration** : Docker Compose avec volumes nommés et bind mounts
- **Workshop** : Collection de 101 addons (~8 Go) chargée au démarrage
- **Snapshots** : Images Docker commitées après chaque étape stable

```yaml
# Résumé docker-compose.yml
services:
  gmod-server:
    image: ceifa/garrysmod
    ports: ["27015:27015/tcp", "27015:27015/udp"]
    mem_limit: 3g
  gmod-mysql:
    image: mysql:8.0
    mem_limit: 512m
```

### Phase 2 — Configuration DarkRP

Mise en place d'un serveur DarkRP réaliste pour tester l'addon en conditions réelles :

- **Gamemode** : DarkRP avec `darkrpmodification` (addon séparé, jamais modifier le core)
- **Jobs** : Constructeur (TEAM_BUILDER) avec SWEP automatique
- **Entités** : Caisse de Matériaux dans le menu F4
- **Admin** : Superadmin via hook Lua (plus fiable que `users.txt`)
- **MySQLOO 9.7** : Binaire 64-bit dans `lua/bin/` pour la connexion MySQL

### Phase 3 — Développement de l'addon

Développement itératif avec tests à chaque étape :

| Jour | Réalisation |
|------|-------------|
| Jour 1 | Infrastructure Docker, structure addon, DarkRP |
| Jour 2 | Module MySQL (CRUD, prepared statements, logging) |
| Jour 3 | Système de sélection de props (CPPI, halos) |
| Jour 4-5 | Sérialisation blueprints (JSON + compression) |
| Jour 6 | Permissions et partage entre joueurs |
| Jour 7 | Sécurité (rate limiting, blacklist, admin commands) |
| Jour 8 | Refonte v2.0 : SWEP + Ghosts + Caisses |
| Jour 9 | Placement avancé (preview, offsets, panneau AdvDupe2-style) |
| Jour 10 | Sauvegardes locales, UI moderne, documentation |

### Phase 4 — Tests & Remédiation

Problèmes rencontrés et résolus :

- **Image Docker** : `ceifa/garrysmod` (et non `ceifa/garrysmod-docker` qui n'existe pas)
- **MySQLOO** : Binaire 64-bit requis, connecté via hostname Docker `gmod-mysql`
- **Workshop** : ~8 Go de contenu, nécessite des snapshots Docker pour éviter le re-téléchargement
- **Entités DarkRP** : `base_gltransfer` n'existe pas → utiliser `base_anim`
- **Ghost interaction** : `SOLID_NONE` empêche le Use natif → détection custom input
- **FPP** : Les entités custom nécessitent `CPPIGetOwner()` pour les permissions
- **Sérialisation** : Vector/Angle deviennent des tables en JSON → reconstruction nécessaire
- **file.Append** : Ne fonctionne pas dans un container Docker → logs alternatifs
- **Séparation client/serveur** : Stricte pour la sécurité (aucune préférence client côté serveur)

### Phase 5 — Addon finalisé

L'addon (`addon/rp_construction_system/`) est **standalone** et prêt pour le Steam Workshop :

- Sauvegarde locale illimitée (côté client)
- Validation serveur stricte de chaque blueprint reçu
- UI moderne avec panneau de placement avancé
- Configuration simple via `sh_config.lua`
- Schéma SQL fourni pour les serveurs avec base de données
- Documentation complète dans le README de l'addon

## Stack technique

| Composant | Technologie |
|---|---|
| Serveur | Garry's Mod (Docker: `ceifa/garrysmod`) |
| Gamemode | DarkRP |
| Base de données | MySQL 8.0 + MySQLOO 9.7 |
| Orchestration | Docker Compose |
| Langage | GLua (Garry's Mod Lua) |
| Versioning | Git + GitHub |

## Configuration de l'addon

Tout est configurable dans `addon/rp_construction_system/lua/rp_construction/sh_config.lua` :

```lua
ConstructionSystem.Config.MaxPropsPerBlueprint = 150  -- Max props (0 = illimité)
ConstructionSystem.Config.MaxCratesPerPlayer = 2      -- Max caisses par joueur
ConstructionSystem.Config.CrateMaxMaterials = 30      -- Matériaux par caisse
ConstructionSystem.Config.CratePrice = 1              -- Prix F4
ConstructionSystem.Config.SelectionRadiusMax = 1000   -- Rayon max sélection
```

Voir le [README de l'addon](addon/rp_construction_system/README.md) pour la documentation complète.

## Documentation

- [Guide d'installation](docs/GUIDE_INSTALLATION.md) — Docker, MySQL, DarkRP
- [Guide d'utilisation](docs/GUIDE_UTILISATEUR.md) — Utilisation en jeu
- [Architecture](docs/ARCHITECTURE.md) — Architecture technique détaillée
- [Images Docker](docs/DOCKER_IMAGES.md) — Snapshots et gestion des images

## Roadmap

- [x] Infrastructure Docker + MySQL
- [x] Système de sélection de props
- [x] Sauvegarde/chargement blueprints
- [x] Interface utilisateur (Derma)
- [x] Système de ghosts + caisses
- [x] Placement avancé (preview, offsets, rotation)
- [x] Sauvegardes locales (client)
- [x] UI moderne
- [ ] Intégration camion simfphys (caisse transportable)
- [ ] Système de coûts configurable
- [ ] Blueprints partagés / marketplace
- [ ] Publication Steam Workshop
