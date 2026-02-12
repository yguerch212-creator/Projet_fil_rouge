# 📊 Monitoring — Supervision et alertes

## Objectif

Mettre en place une **supervision** de l'infrastructure et de l'application permettant de détecter les anomalies, diagnostiquer les problèmes et anticiper les pannes.

---

## État actuel

### Niveaux de monitoring

| Niveau | Quoi | Comment | Statut |
|--------|------|---------|--------|
| **Infrastructure** | Santé des containers Docker | `docker ps`, `docker stats`, healthcheck MySQL | ✅ En place |
| **Application** | Actions joueurs, erreurs Lua | Module `sv_logging.lua` (console + MySQL) | ✅ En place |
| **Réseau** | Port 27015 accessible | Test manuel, logs serveur | ⚠️ Manuel |
| **Performance** | RAM, CPU, latence | `docker stats`, `htop` sur le VPS | ⚠️ Manuel |

### Monitoring applicatif : sv_logging.lua

Le module de logging intégré à l'addon trace toutes les actions significatives :

```
[Construction] [SAVE] Player "Thomas" saved blueprint "base_militaire" (45 props)
[Construction] [LOAD] Player "Thomas" loaded blueprint "base_militaire"
[Construction] [MATERIALIZE] Player "Alex" materialized ghost (crate: 49 remaining)
[Construction] [VEHICLE] Player "Thomas" loaded crate onto sim_fphy_codww2opel
```

**Double destination** (version dev) :
- **Console serveur** : visibilité immédiate pour l'admin
- **Base MySQL** (`blueprint_logs`) : historique persistant, requêtable

**Données loguées** :

| Champ | Contenu |
|-------|---------|
| `steamid` | Identifiant unique du joueur |
| `player_name` | Nom affiché |
| `action` | Type d'action (save, load, delete, share, materialize) |
| `blueprint_name` | Nom du blueprint concerné |
| `details` | Contexte additionnel (JSON) |
| `created_at` | Horodatage précis |

### Monitoring infrastructure : Docker

#### Healthcheck MySQL

Le container MySQL vérifie sa propre santé toutes les 10 secondes :

```yaml
healthcheck:
  test: mysqladmin ping -h localhost
  interval: 10s
  timeout: 5s
  retries: 3
```

Docker marque le container comme `unhealthy` après 3 échecs consécutifs. Le serveur GMod dépend de cet état pour démarrer.

#### Limites de ressources

Les containers sont limités pour éviter qu'un service ne monopolise les ressources du VPS :

| Container | RAM max | CPU max |
|-----------|---------|---------|
| `gmod-server` | 3 Go | 2 CPUs |
| `gmod-mysql` | 512 Mo | 0.5 CPU |
| VPS total | 16 Go | — |

#### Commandes de supervision

```bash
# État des containers
docker ps

# Consommation temps réel
docker stats

# Logs du serveur GMod
docker logs -f gmod-server

# Logs MySQL
docker logs -f gmod-mysql

# Vérifier le healthcheck
docker inspect gmod-mysql --format='{{.State.Health.Status}}'
```

### Monitoring applicatif : commandes admin

L'addon fournit des commandes console pour les superadmins :

| Commande | Description |
|----------|-------------|
| `construction_logs [n]` | Affiche les n derniers logs d'actions (nécessite MySQL) |
| `construction_stats` | Statistiques générales du système |

---

## Améliorations réalisées

### 1. Logging structuré

Au début du projet, le logging se faisait uniquement en console avec des `print()` simples. L'évolution vers un module `sv_logging.lua` dédié a apporté :

- **Format standardisé** : `[Construction] [ACTION] Message` pour filtrer facilement
- **Persistence en DB** : les logs survivent aux redémarrages du serveur
- **Requêtabilité** : possibilité d'interroger l'historique via SQL
- **Contexte enrichi** : SteamID, nom, détails JSON pour chaque action

### 2. Rate limiting comme indicateur

Le système de rate limiting (`sv_security.lua`) joue un double rôle :

- **Sécurité** : empêche le spam et les abus
- **Monitoring** : les rejets de rate limit sont loggés, permettant de détecter les comportements anormaux (tentatives de triche, bots)

```
[Construction] [SECURITY] Rate limit hit for STEAM_0:0:12345 on action "save" (cooldown: 10s)
```

### 3. Auto-reconnexion MySQL

Le module `sv_database.lua` implémente une reconnexion automatique :

- Tentative de connexion au démarrage (délai de 5s après `InitPostEntity`)
- En cas d'échec : retry toutes les 30 secondes
- Log de chaque tentative et de chaque reconnexion réussie

Cela évite les interruptions de service si MySQL redémarre temporairement.

---

## Perspectives d'évolution

### Court terme

- **Alertes par webhook** : notification Discord/Telegram quand un container passe en `unhealthy` ou quand le serveur GMod crashe
- **Dashboard Docker** : installation de Portainer pour une interface web de supervision

### Moyen terme

- **Stack de monitoring** : déploiement de Prometheus + Grafana pour la collecte de métriques et la visualisation :
  - Métriques Docker (CPU, RAM, réseau par container)
  - Métriques applicatives (nombre de joueurs, actions par minute, ghosts actifs)
  - Métriques MySQL (requêtes/s, connexions actives, slow queries)
- **Centralisation des logs** : ELK Stack (Elasticsearch + Logstash + Kibana) ou Loki + Grafana pour agréger et rechercher dans les logs

### Long terme

- **Alerting avancé** : règles Prometheus AlertManager pour les seuils critiques (RAM > 80%, latence > 100ms, rate limit > 10/min pour un joueur)
- **Uptime monitoring externe** : service type UptimeRobot pour surveiller le port 27015 depuis l'extérieur
