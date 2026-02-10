# 🔧 Guide d'Installation — RP Construction System v2.2

## Prérequis

- Serveur Garry's Mod avec **DarkRP**
- (Optionnel) MySQL 8.0 + MySQLOO pour les logs
- (Optionnel) simfphys pour le transport en véhicule
- Content pack WW2 pour les modèles de caisses : [Workshop 3008026539](https://steamcommunity.com/sharedfiles/filedetails/?id=3008026539)

---

## Installation de l'addon

### Méthode 1 : Steam Workshop (recommandé)

1. Abonnez-vous à l'addon sur le Steam Workshop
2. Ajoutez l'ID à votre collection serveur :
   ```
   +host_workshop_collection VOTRE_COLLECTION_ID
   ```
3. Redémarrez le serveur

### Méthode 2 : Installation manuelle

1. Téléchargez ou clonez le dépôt
2. Copiez le dossier `rp_construction_system/` dans `garrysmod/addons/`
3. **Si vous n'utilisez pas MySQL** (cas le plus courant) :
   - Supprimez `lua/rp_construction/sv_database.lua`
   - Supprimez `sql/schema.sql`
   - La section `DB` dans `sh_config.lua` sera ignorée
4. Redémarrez le serveur

### Vérification

En console serveur, vous devriez voir :
```
[Construction] RP Construction System v2.0.0 chargé
[Construction] Jobs SWEP: 1 job(s)
[Construction] Jobs Caisses: 1 job(s)
```

---

## Configuration DarkRP

### 1. Attribuer le SWEP à un job

Le SWEP `weapon_construction` peut être attribué à **n'importe quel job DarkRP existant**. Ajoutez `"weapon_construction"` dans la table `weapons` du job souhaité :

```lua
-- Exemple dans darkrpmodification/lua/darkrp_customthings/jobs.lua
TEAM_ARCHITECT = DarkRP.createJob("Architecte", {
    -- ... vos paramètres existants ...
    weapons = {"weapon_construction"},  -- Ajouter cette ligne
    -- ...
})
```

> **Note** : Si `SWEPJobs` dans `sh_config.lua` est `nil`, l'addon détecte automatiquement le premier job possédant `weapon_construction`.

### 2. Entités F4 (caisses)

Dans `darkrpmodification/lua/darkrp_customthings/entities.lua` :

```lua
DarkRP.createEntity("Grosse Caisse de Materiaux", {
    ent = "construction_crate",
    model = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl",
    price = 500,            -- Ajustez le prix
    max = 2,
    cmd = "buycrate",
    allowed = {TEAM_BUILDER},  -- Restreindre aux Constructeurs
    category = "Construction",
})

DarkRP.createEntity("Petite Caisse de Materiaux", {
    ent = "construction_crate_small",
    model = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl",
    price = 250,
    max = 4,
    cmd = "buysmallcrate",
    allowed = {TEAM_BUILDER},
    category = "Construction",
})
```

### 3. Ajouter d'autres jobs

Pour autoriser plusieurs jobs :

```lua
-- Dans entities.lua
allowed = {TEAM_BUILDER, TEAM_ARCHITECT, TEAM_ENGINEER},

-- Dans sh_config.lua (après le chargement des jobs)
ConstructionSystem.Config.CrateAllowedJobs = {TEAM_BUILDER, TEAM_ARCHITECT}
ConstructionSystem.Config.SWEPJobs = {TEAM_BUILDER, TEAM_ARCHITECT}
```

---

## Configuration de l'addon

Tout se configure dans `lua/rp_construction/sh_config.lua`.

### Paramètres principaux

```lua
-- Limites
Config.MaxPropsPerBlueprint = 150   -- Max props par blueprint
Config.MaxCratesPerPlayer = 2        -- Max caisses simultanées

-- Cooldowns (secondes)
Config.SaveCooldown = 10
Config.LoadCooldown = 15

-- Sélection
Config.SelectionRadiusDefault = 500  -- Rayon par défaut
Config.SelectionRadiusMax = 1000     -- Rayon maximum

-- Caisses
Config.CrateMaxMaterials = 50        -- Matériaux grosse caisse
Config.SmallCrateMaxMaterials = 15   -- Matériaux petite caisse
Config.CratePrice = 1                -- Prix F4 grosse
Config.SmallCratePrice = 1           -- Prix F4 petite

-- Jobs (nil = tout le monde)
Config.AllowedJobs = nil             -- Jobs autorisés à utiliser le système
Config.SWEPJobs = nil                -- Jobs recevant le SWEP automatiquement
Config.CrateAllowedJobs = nil        -- Jobs autorisés pour les caisses
```

> **Note** : Si `SWEPJobs` est `nil`, l'addon détecte automatiquement `TEAM_BUILDER` s'il existe.

### Modèles de caisses

Les modèles sont configurables si vous préférez d'autres caisses :

```lua
Config.CrateModel = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl"
Config.SmallCrateModel = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl"
```

### Sécurité

```lua
-- Classes interdites dans les blueprints
Config.BlacklistedEntities = {
    "money_printer", "darkrp_money", "drug_lab", "gun_lab", ...
}

-- Seuls les prop_physics sont autorisés
Config.AllowedClasses = { ["prop_physics"] = true }
```

---

## Base de données (optionnelle)

L'addon fonctionne **entièrement sans base de données**. La DB est optionnelle et sert pour les logs et le futur partage.

### Installation MySQL

1. Installez MySQL 8.0 (ou utilisez Docker)
2. Créez la base de données :
   ```sql
   CREATE DATABASE gmod_construction;
   CREATE USER 'gmod_user'@'%' IDENTIFIED BY 'VotreMotDePasse';
   GRANT ALL ON gmod_construction.* TO 'gmod_user'@'%';
   ```
3. Importez le schéma :
   ```bash
   mysql -u root -p gmod_construction < sql/schema.sql
   ```

### Installation MySQLOO

1. Téléchargez [MySQLOO 9.7](https://github.com/FredyH/MySQLOO/releases)
2. Prenez le binaire **64-bit** : `gmsv_mysqloo_linux64.dll`
3. Placez-le dans `garrysmod/lua/bin/`

### Configuration

Dans `sh_config.lua` :

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

Pour un environnement de développement conteneurisé :

### docker-compose.yml

```yaml
services:
  gmod:
    image: ceifa/garrysmod
    container_name: gmod-server
    ports:
      - "27015:27015/udp"
      - "27015:27015/tcp"
    mem_limit: 3G
    environment:
      - GAMEMODE=darkrp
      - MAP=votre_map
      - ARGS=+host_workshop_collection VOTRE_COLLECTION
    volumes:
      - gmod-data:/home/gmod/server/garrysmod
      - ./addons:/home/gmod/server/garrysmod/addons
      - ./lua-bin:/home/gmod/server/garrysmod/lua/bin
    depends_on:
      mysql:
        condition: service_healthy

  mysql:
    image: mysql:8.0
    container_name: gmod-mysql
    mem_limit: 512M
    environment:
      MYSQL_ROOT_PASSWORD: "VotreMotDePasse"
      MYSQL_DATABASE: gmod_construction
      MYSQL_USER: gmod_user
      MYSQL_PASSWORD: "VotreMotDePasse"
    healthcheck:
      test: mysqladmin ping -h localhost
      interval: 10s
      timeout: 5s
      retries: 3

volumes:
  gmod-data:
```

### Sauvegarder l'image

Après le premier démarrage (téléchargement Workshop ~8 Go) :

```bash
docker commit gmod-server projetfilrouge/gmod-server:stable
```

> **Important** : Utilisez `docker compose up -d` (pas `docker restart`) pour appliquer les changements de variables d'environnement.

---

## Dépannage

| Problème | Solution |
|----------|----------|
| SWEP pas dans l'inventaire | Vérifiez que `weapons = {"weapon_construction"}` est dans le job |
| Caisses pas dans le F4 | Vérifiez `entities.lua` dans darkrpmodification |
| MySQLOO ne charge pas | Vérifiez le binaire 64-bit dans `lua/bin/` |
| Modèles de caisses invisibles | Installez le content pack WW2 (Workshop 3008026539) |
| `docker restart` ne prend pas les changements | Utilisez `docker compose up -d` à la place |
| Client ne voit pas les changements Lua | Le joueur doit se reconnecter (disconnect + retry) |
| Caisse ne se charge pas dans le véhicule | Posez la caisse près du véhicule, visez avec le SWEP et appuyez R |

---

## Commandes admin

| Commande | Rôle | Description |
|----------|------|-------------|
| `construction_logs [n]` | Superadmin | Afficher les n derniers logs |
| `construction_stats` | Superadmin | Statistiques du système |
