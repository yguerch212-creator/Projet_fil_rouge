# Guide d'Installation

## Prérequis

- Docker et Docker Compose installés
- ~10 GB d'espace disque (workshop addons)
- 3 GB RAM minimum pour le serveur GMod

## Installation rapide

### 1. Cloner le repository

```bash
git clone https://github.com/yguerch212-creator/Projet_fil_rouge.git
cd Projet_fil_rouge/docker
```

### 2. Configuration

Éditer les variables dans `docker-compose.yml` :

```yaml
environment:
  RCON_PASSWORD: "VotreMotDePasse"
  SERVER_NAME: "Votre Serveur RP"
  MAX_PLAYERS: "16"
  MAP: "rp_downtown_v4c_v2"
  WORKSHOP_COLLECTION: "2270926906"
```

Configurer MySQL dans `docker/addons/rp_construction_system/lua/rp_construction/sh_config.lua` :

```lua
ConstructionSystem.Config.DB = {
    Host = "gmod-mysql",    -- Nom du service Docker
    Port = 3306,
    User = "gmod_user",
    Password = "VotreMotDePasse",
    Database = "gmod_construction",
}
```

### 3. Installer MySQLOO

Télécharger le module MySQLOO 9.7 depuis [GitHub](https://github.com/FredyH/MySQLOO/releases) :

```bash
# Créer le dossier
mkdir -p lua-bin

# Copier gmsv_mysqloo_linux64.dll dans lua-bin/
# (il sera monté automatiquement dans le conteneur)
```

### 4. Lancer les services

```bash
docker compose up -d
```

Le premier démarrage prend ~8 minutes (téléchargement du workshop).

### 5. Vérifier

```bash
# Vérifier que les conteneurs sont up
docker compose ps

# Vérifier les logs GMod
docker compose logs gmod --tail=50

# Tester la connexion
python3 -c "import a2s; print(a2s.info(('127.0.0.1', 27015)))"
```

### 6. Se connecter en superadmin

Le SteamID configuré dans `sv_admin_setup.lua` sera automatiquement promu superadmin à la connexion.

## Structure Docker

```
docker/
├── docker-compose.yml          -- Orchestration des services
├── server-config/
│   └── server.cfg              -- Configuration serveur GMod
├── mysql-init/
│   └── init.sql                -- Schéma initial MySQL
├── lua-bin/
│   └── gmsv_mysqloo_linux64.dll -- Module MySQLOO
├── addons/
│   ├── rp_construction_system/ -- L'addon principal
│   └── darkrpmodification/     -- Configuration DarkRP
└── gamemodes/
    └── darkrp/                 -- Gamemode DarkRP
```

## Sauvegarder l'image Docker

Après le premier démarrage réussi, sauvegarder l'image pour éviter de re-télécharger le workshop :

```bash
docker commit gmod-server projetfilrouge/gmod-server:stable
```

## Dépannage

| Problème | Solution |
|----------|----------|
| Serveur ne démarre pas | Vérifier les logs : `docker compose logs gmod` |
| MySQLOO non trouvé | Vérifier que le .dll est dans `lua-bin/` et le volume est monté |
| DB non connectée | Vérifier que MySQL est UP : `docker compose logs mysql` |
| Workshop long à charger | Normal au premier démarrage (~5-8 min). Utiliser `docker commit` après |
