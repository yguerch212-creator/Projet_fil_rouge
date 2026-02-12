# 🔧 Guide d'Installation — RP Construction System v2.2

> 🔗 **[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3664157203)** — Addon publié (ID 3664157203)

---

## 📋 Table des matières

- [Prérequis](#prérequis)
- [Installation de l'addon](#installation-de-laddon)
- [Configuration DarkRP](#configuration-darkrp)
- [Configuration de l'addon](#configuration-de-laddon)
- [Forcer le téléchargement Workshop côté client](#forcer-le-téléchargement-workshop-côté-client)
- [Base de données (optionnelle)](#base-de-données-optionnelle)
- [Installation Docker (développement)](#installation-docker-développement)
- [Dépannage](#dépannage)
- [Commandes admin](#commandes-admin)

---

## Prérequis

### Serveur
- Serveur Garry's Mod avec **DarkRP** (gamemode + darkrpmodification)
- (Optionnel) **MySQL 8.0** + **MySQLOO** pour les logs en base de données
- (Optionnel) **simfphys** pour le transport de caisses en véhicule

### Clients (joueurs)
- Content pack WW2 pour les modèles de caisses : [Workshop 3008026539](https://steamcommunity.com/sharedfiles/filedetails/?id=3008026539)
- S'abonner à l'addon Workshop pour recevoir le viewmodel et les modèles custom

### Deux versions disponibles

| Version | Dossier | Usage |
|---------|---------|-------|
| **Workshop** (recommandée) | `addon/rp_construction_system_workshop/` | Standalone, aucune dépendance externe |
| **Dev** | `addon/rp_construction_system_dev/` | Avec MySQL, logging DB, auto-config admin |

La version Workshop est celle publiée sur le Steam Workshop. La version Dev est utilisée dans l'environnement Docker de développement.

---

## Installation de l'addon

### Méthode 1 : Steam Workshop (recommandé)

1. Abonnez-vous à l'addon sur le [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3664157203)
2. Ajoutez l'addon au serveur :
   ```
   # Dans les arguments de lancement du serveur :
   +workshop_download_item 4000 3664157203
   ```
   Ou ajoutez l'ID à votre collection Workshop si vous en utilisez une.
3. Redémarrez le serveur

### Méthode 2 : Installation manuelle

1. Téléchargez ou clonez le [dépôt GitHub](https://github.com/yguerch212-creator/Projet_fil_rouge)
2. Copiez le dossier `addon/rp_construction_system_workshop/` dans `garrysmod/addons/`
3. Redémarrez le serveur

> **Note** : La version Workshop ne contient pas de module MySQL — rien à configurer. Pour la version dev avec MySQL/logging, utilisez `addon/rp_construction_system_dev/` et consultez la section [Base de données](#base-de-données-optionnelle).

### Vérification

En console serveur, vous devriez voir au démarrage :

```
[Construction] RP Construction System v2.2 chargé
[Construction] Jobs SWEP: 1 job(s)
[Construction] Jobs Caisses: 1 job(s)
```

---

## Configuration DarkRP

### 1. Attribuer le SWEP à un job

Le SWEP `weapon_construction` peut être attribué à **n'importe quel job DarkRP existant**. Ajoutez `"weapon_construction"` dans la table `weapons` du job souhaité :

```lua
-- darkrpmodification/lua/darkrp_customthings/jobs.lua
-- Exemple : ajouter le SWEP à un job "Architecte"
TEAM_ARCHITECT = DarkRP.createJob("Architecte", {
    color = Color(0, 100, 200, 255),
    model = "models/player/hostage/hostage_04.mdl",
    description = "Vous construisez des bâtiments pour les citoyens.",
    weapons = {"weapon_construction"},  -- ← Le SWEP Construction
    command = "architecte",
    max = 4,
    salary = 65,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Civil",
})
```

> **Note** : Si `SWEPJobs` dans `sh_config.lua` est `nil`, l'addon détecte automatiquement le premier job qui possède `weapon_construction` dans ses armes.

### 2. Caisses de matériaux (entités F4)

Dans `darkrpmodification/lua/darkrp_customthings/entities.lua` :

```lua
DarkRP.createEntity("Grosse Caisse de Materiaux", {
    ent = "construction_crate",
    model = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl",
    price = 500,
    max = 2,
    cmd = "buycrate",
    allowed = {TEAM_ARCHITECT},     -- Adaptez à vos jobs
    category = "Construction",
})

DarkRP.createEntity("Petite Caisse de Materiaux", {
    ent = "construction_crate_small",
    model = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl",
    price = 250,
    max = 4,
    cmd = "buysmallcrate",
    allowed = {TEAM_ARCHITECT},     -- Adaptez à vos jobs
    category = "Construction",
})
```

Le champ `allowed` contrôle quels jobs voient les caisses dans le menu F4. Omettez-le pour les rendre disponibles à tous.

### 3. Plusieurs jobs

Pour autoriser plusieurs jobs à utiliser le système :

```lua
-- Dans entities.lua — qui peut acheter les caisses
allowed = {TEAM_ARCHITECT, TEAM_ENGINEER, TEAM_BUILDER},

-- Dans sh_config.lua — qui reçoit le SWEP automatiquement
ConstructionSystem.Config.SWEPJobs = {TEAM_ARCHITECT, TEAM_ENGINEER}

-- Dans sh_config.lua — qui peut utiliser les caisses (nil = tout le monde)
ConstructionSystem.Config.CrateAllowedJobs = {TEAM_ARCHITECT, TEAM_ENGINEER}
```

---

## Configuration de l'addon

Tout se configure dans `lua/rp_construction/sh_config.lua` :

### Limites

| Option | Défaut | Description |
|--------|--------|-------------|
| `MaxPropsPerBlueprint` | `150` | Max props par blueprint (0 = illimité) |
| `MaxCratesPerPlayer` | `2` | Max caisses simultanées par joueur |
| `MaxNameLength` | `50` | Longueur max du nom de blueprint |
| `MaxDescLength` | `200` | Longueur max de la description |

### Cooldowns

| Option | Défaut | Description |
|--------|--------|-------------|
| `SaveCooldown` | `10s` | Délai entre chaque sauvegarde |
| `LoadCooldown` | `15s` | Délai entre chaque chargement |

### Sélection

| Option | Défaut | Description |
|--------|--------|-------------|
| `SelectionRadiusMin` | `50` | Rayon minimum de sélection par zone |
| `SelectionRadiusMax` | `1000` | Rayon maximum |
| `SelectionRadiusDefault` | `500` | Rayon par défaut |

### Caisses

| Option | Défaut | Description |
|--------|--------|-------------|
| `CrateMaxMaterials` | `50` | Matériaux par grosse caisse |
| `SmallCrateMaxMaterials` | `15` | Matériaux par petite caisse |

### Jobs & Permissions

| Option | Défaut | Description |
|--------|--------|-------------|
| `AllowedJobs` | `nil` | Jobs autorisés (nil = tout le monde) |
| `SWEPJobs` | `nil` | Jobs recevant le SWEP automatiquement |
| `CrateAllowedJobs` | `nil` | Jobs autorisés pour les caisses |

### Sécurité

```lua
-- Classes interdites dans les blueprints
Config.BlacklistedEntities = {
    "money_printer", "darkrp_money", "spawned_money",
    "spawned_shipment", "spawned_weapon",
    "drug_lab", "gun_lab", "microwave"
}

-- Seuls les prop_physics sont autorisés
Config.AllowedClasses = { ["prop_physics"] = true }
```

### Modèles de caisses

Configurables si vous préférez d'autres modèles :

```lua
Config.CrateModel = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl"
Config.SmallCrateModel = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl"
```

> Les modèles par défaut nécessitent le [content pack WW2](https://steamcommunity.com/sharedfiles/filedetails/?id=3008026539). Si vos joueurs ne l'ont pas, les caisses seront invisibles — changez les modèles ou ajoutez le content pack à votre collection.

---

## Forcer le téléchargement Workshop côté client

Pour que les joueurs téléchargent automatiquement les addons nécessaires en se connectant, créez un fichier `resource.AddWorkshop` côté serveur :

```lua
-- garrysmod/addons/votre_addon/lua/autorun/server/sv_workshop.lua
resource.AddWorkshop("3664157203")   -- RP Construction System (viewmodel + modèles)
resource.AddWorkshop("3008026539")   -- Content pack WW2 (modèles caisses)
```

Cela force le client à télécharger les GMA Workshop lors de la connexion au serveur.

---

## Base de données (optionnelle)

> **Cette section concerne uniquement la version Dev.** La version Workshop fonctionne entièrement sans base de données.

L'addon fonctionne **entièrement sans base de données**. La DB est optionnelle et sert pour les logs et le futur système de partage.

### Installation MySQL

1. Installez MySQL 8.0 (ou utilisez Docker) :
   ```sql
   CREATE DATABASE gmod_construction;
   CREATE USER 'gmod_user'@'%' IDENTIFIED BY 'VotreMotDePasse';
   GRANT ALL ON gmod_construction.* TO 'gmod_user'@'%';
   ```
2. Importez le schéma :
   ```bash
   mysql -u root -p gmod_construction < sql/schema.sql
   ```

### Installation MySQLOO

1. Téléchargez [MySQLOO 9.7](https://github.com/FredyH/MySQLOO/releases)
2. Prenez le binaire **64-bit** : `gmsv_mysqloo_linux64.dll`
3. Placez-le dans `garrysmod/lua/bin/`

> ⚠️ Le binaire **32-bit** (`gmsv_mysqloo_linux.dll`) ne fonctionnera pas si votre serveur tourne en 64-bit (cas de Docker `ceifa/garrysmod`).

### Configuration

Dans `sh_config.lua` (version dev uniquement) :

```lua
Config.DB = {
    Host = "localhost",        -- ou "gmod-mysql" en Docker
    Port = 3306,
    User = "gmod_user",
    Password = "VotreMotDePasse",
    Database = "gmod_construction",
}
```

---

## Installation Docker (développement)

Pour reproduire l'environnement de développement conteneurisé utilisé dans ce projet :

### docker-compose.yml

```yaml
services:
  gmod:
    image: projetfilrouge/gmod-server:jour2-stable  # Image avec Workshop pré-téléchargé
    container_name: gmod-server
    ports:
      - "27015:27015/udp"
      - "27015:27015/tcp"
    mem_limit: 3G
    cpus: 2
    environment:
      - GAMEMODE=darkrp
      - MAP=falaise_lbrp_v1
      - ARGS=+host_workshop_collection 2270926906 +workshop_download_item 4000 3664157203
    volumes:
      - gmod-server-data:/home/gmod/server                              # Données persistantes
      - ./addons:/home/gmod/server/garrysmod/addons                     # Addons (bind mount)
      - ./gamemodes/darkrp:/home/gmod/server/garrysmod/gamemodes/darkrp # DarkRP gamemode
      - ./lua-bin:/home/gmod/server/garrysmod/lua/bin                   # MySQLOO
      - ./server-config/server.cfg:/home/gmod/server/garrysmod/cfg/server.cfg
    depends_on:
      mysql:
        condition: service_healthy

  mysql:
    image: mysql:8.0
    container_name: gmod-mysql
    mem_limit: 512M
    cpus: 0.5
    environment:
      MYSQL_ROOT_PASSWORD: "VotreMotDePasse"
      MYSQL_DATABASE: gmod_construction
      MYSQL_USER: gmod_user
      MYSQL_PASSWORD: "VotreMotDePasse"
    volumes:
      - ./mysql-data:/var/lib/mysql
      - ./mysql-init:/docker-entrypoint-initdb.d
    healthcheck:
      test: mysqladmin ping -h localhost
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  gmod-server-data:
```

### Premier démarrage

```bash
# Démarrer les services
docker compose up -d

# Le premier démarrage télécharge ~8 Go de Workshop (5-10 min)
docker logs -f gmod-server

# Une fois le serveur prêt, sauvegarder l'image
docker commit gmod-server projetfilrouge/gmod-server:v1.0-base
```

Les démarrages suivants utilisent l'image commitée et sont quasi-instantanés.

### Commandes courantes

```bash
# Démarrer / Appliquer les changements du compose
docker compose up -d

# Redémarrer (sans relire le compose)
docker restart gmod-server

# Logs en temps réel
docker logs -f gmod-server

# Console RCON
docker exec -it gmod-server rcon -H 127.0.0.1 -p 27015 -P VotreRconPassword
```

> **Important** : Utilisez `docker compose up -d` (pas `docker restart`) pour appliquer les changements de variables d'environnement, d'image ou de map. `docker restart` ne relit pas le fichier compose.

---

## Dépannage

| Problème | Cause | Solution |
|----------|-------|----------|
| SWEP pas dans l'inventaire | Le job n'a pas le SWEP | Ajoutez `weapons = {"weapon_construction"}` dans la définition du job |
| Caisses pas dans le F4 | Config manquante | Ajoutez les entités dans `entities.lua` (voir section Configuration DarkRP) |
| Viewmodel C4/SLAM au lieu du plan | Addon Workshop pas téléchargé | Abonnez-vous au Workshop (ID 3664157203) + ajoutez `resource.AddWorkshop("3664157203")` |
| Modèles de caisses invisibles | Content pack manquant | Installez le [content pack WW2](https://steamcommunity.com/sharedfiles/filedetails/?id=3008026539) |
| Petite caisse ne matérialise pas | Bug corrigé en v2.2.1 | Mettez à jour l'addon (le fix est dans la dernière version) |
| MySQLOO ne charge pas | Mauvais binaire | Vérifiez : `gmsv_mysqloo_linux64.dll` (64-bit) dans `lua/bin/` |
| `docker restart` ne prend pas les changements | Comportement normal | Utilisez `docker compose up -d` pour relire le compose |
| Client ne voit pas les modifs Lua | Cache client | Le joueur doit se reconnecter (`disconnect` puis `retry` en console) |
| Caisse ne se charge pas dans le véhicule | Mauvaise manipulation | Posez la caisse près du véhicule, équipez le SWEP, visez le véhicule, appuyez R |
| Props ne se sélectionnent pas | Pas propriétaire | Seuls les `prop_physics` dont vous êtes propriétaire (CPPI) sont sélectionnables |

---

## Commandes admin

| Commande | Rôle requis | Description |
|----------|-------------|-------------|
| `construction_logs [n]` | Superadmin | Afficher les n derniers logs (nécessite MySQL) |
| `construction_stats` | Superadmin | Statistiques du système |
