# ⚙️ Automatisation — Scripts, déploiement et CI/CD

## Objectif

Réduire les **interventions manuelles**, minimiser les **erreurs humaines** et accélérer le cycle de **déploiement** grâce à l'automatisation.

---

## État actuel

### Automatisations en place

| Domaine | Quoi | Comment | Fichier |
|---------|------|---------|---------|
| **Déploiement** | Lancement complet de l'infra | `docker compose up -d` | `docker-compose.yml` |
| **Dépendances** | Téléchargement Workshop automatique | Variable `ARGS` + `workshop_download_item` | `docker-compose.yml` |
| **Base de données** | Initialisation du schéma au premier lancement | Script dans `mysql-init/` | `mysql-init/` |
| **Healthcheck** | Vérification santé MySQL | `mysqladmin ping` toutes les 10s | `docker-compose.yml` |
| **Démarrage ordonné** | GMod attend MySQL ready | `depends_on: condition: service_healthy` | `docker-compose.yml` |
| **Distribution client** | Téléchargement auto des addons Workshop | `resource.AddWorkshop()` | `sv_workshop.lua` |
| **Configuration admin** | Auto-setup superadmin au premier lancement | `sv_admin_setup.lua` (version dev) | `sv_admin_setup.lua` |
| **Versioning** | Sauvegarde et historique du code | Git + GitHub | `.git/` |
| **Snapshots** | Sauvegarde d'état du serveur | `docker commit` (manuel) | — |

### Docker Compose : infrastructure as code

Le fichier `docker-compose.yml` est le cœur de l'automatisation. Une seule commande reconstruit l'ensemble de l'infrastructure :

```bash
# Déploiement complet (premier lancement ou mise à jour)
docker compose up -d

# Résultat :
# ✅ Container MySQL démarré avec healthcheck
# ✅ Schéma DB initialisé automatiquement (mysql-init/)
# ✅ Container GMod démarré après MySQL healthy
# ✅ Workshop Collection téléchargée
# ✅ Addon Workshop téléchargé (ID 3664157203)
# ✅ Addons montés via bind mount
# ✅ Configuration serveur appliquée
```

### resource.AddWorkshop : distribution automatique

Le fichier `sv_workshop.lua` force le téléchargement côté client des addons nécessaires :

```lua
resource.AddWorkshop("3664157203")   -- RP Construction System
resource.AddWorkshop("3008026539")   -- Content pack WW2
resource.AddWorkshop("773402917")    -- AdvDupe2
```

Les joueurs reçoivent automatiquement les modèles et le contenu à la connexion, sans action de leur part.

### sv_admin_setup.lua : configuration initiale automatique

Au premier lancement (version dev), le script détecte s'il n'y a pas de superadmin configuré et applique automatiquement la configuration de base. Cela évite de devoir se connecter manuellement à la console RCON pour la configuration initiale.

---

## Améliorations réalisées

### 1. De l'image brute au déploiement reproductible

**Avant** (début du projet) :
```bash
# Installation manuelle, longue, sujette aux erreurs
docker run ceifa/garrysmod ...
# Attendre 10 min le téléchargement Workshop
# Configurer manuellement DarkRP
# Installer manuellement MySQLOO
# Créer manuellement la base de données
# Copier manuellement l'addon
```

**Après** (état actuel) :
```bash
# Une commande, tout est automatisé
docker compose up -d
# Infrastructure complète en ~30 secondes (image pré-commitée)
```

Le passage de commandes manuelles à Docker Compose a **éliminé les erreurs de configuration** et réduit le temps de déploiement de ~15 minutes à ~30 secondes.

### 2. Snapshots Docker : rollback instantané

La stratégie de `docker commit` après chaque étape stable permet un rollback instantané :

```bash
# En cas de problème, revenir à l'état précédent :
# 1. Changer le tag dans docker-compose.yml
image: projetfilrouge/gmod-server:v2.1-stable  # au lieu de v2.2-vehicles

# 2. Redéployer
docker compose up -d
# Serveur restauré en ~30 secondes
```

### 3. Bind mounts : déploiement à chaud

Les addons et la configuration sont en **bind mount**, ce qui permet de modifier le code sans reconstruire l'image :

```bash
# Modifier un fichier Lua
vim docker/addons/rp_construction_system/lua/rp_construction/sv_ghosts.lua

# Appliquer immédiatement
docker restart gmod-server
# Les changements sont actifs en ~15 secondes
```

Ce workflow a été essentiel pendant le développement itératif : correction rapide des bugs, test immédiat, sans cycle de build.

### 4. Publication Workshop automatisée

La compilation et la publication de l'addon sur le Steam Workshop suivent un processus reproductible :

```powershell
# 1. Compiler le GMA
.\gmad.exe create -folder "rp_construction_system_workshop" -out "rp_construction_system.gma"

# 2. Publier / Mettre à jour
.\gmpublish.exe update -id 3664157203 -addon "rp_construction_system.gma"
```

---

## Perspectives d'évolution

### Court terme

- **Script de backup automatisé** :
  ```bash
  #!/bin/bash
  # backup.sh — à planifier via cron
  docker commit gmod-server projetfilrouge/gmod-server:backup-$(date +%Y%m%d)
  docker exec gmod-mysql mysqldump -u root -p*** gmod_construction > backup-$(date +%Y%m%d).sql
  ```

- **Restart automatique** :
  ```yaml
  # docker-compose.yml
  services:
    gmod:
      restart: unless-stopped
    mysql:
      restart: unless-stopped
  ```

### Moyen terme

- **CI/CD avec GitHub Actions** :
  - Linting Lua automatique sur chaque push (`glualint`)
  - Compilation GMA automatique
  - Déploiement automatique sur le VPS via SSH (après validation)
  - Notifications Discord sur chaque déploiement

- **Script de déploiement** :
  ```bash
  #!/bin/bash
  # deploy.sh
  cd /root/ProjetFilRouge
  git pull origin main
  docker restart gmod-server
  echo "Deployed $(git log --oneline -1)"
  ```

### Long terme

- **Infrastructure as Code complète** : Terraform ou Ansible pour provisionner le VPS lui-même
- **Pipeline de tests** : tests Lua automatisés en environnement Docker isolé avant déploiement en production
- **Blue/Green deployment** : deux instances du serveur, basculement sans downtime
- **Gestion des secrets** : vault ou variables d'environnement chiffrées au lieu de mots de passe en clair dans le compose
