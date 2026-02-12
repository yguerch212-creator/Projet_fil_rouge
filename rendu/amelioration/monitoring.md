# 📊 Monitoring et performances — C6

> **C6.1** — Pertinence du choix de l'outil de monitoring (SLA, PRA)
> **C6.2** — Sélection des données à monitorer

---

## 1. Définition des SLA et PRA (C6.1)

### SLA (Service Level Agreement)

Engagements de niveau de service définis pour l'infrastructure du serveur de jeu :

| Métrique SLA | Objectif | Mesure | Outil |
|-------------|----------|--------|-------|
| **Disponibilité** | ≥ 95% (hors maintenance planifiée) | Uptime mensuel | UptimeRobot / ping externe |
| **Temps de réponse** | Latence < 100ms (réseau) | Ping serveur | Monitoring réseau |
| **Temps de démarrage** | < 2 min après arrêt | Logs Docker timestamps | `docker logs` |
| **Capacité joueurs** | 32 slots simultanés | Compteur Source Engine | Query port 27015 |
| **Perte de données** | RPO < 1h pour MySQL | Dernière sauvegarde | Script cron dump SQL |

### PRA (Plan de Reprise d'Activité)

Le PRA définit les procédures de reprise après sinistre, complémentaire au PCA (voir [redondance.md](redondance.md)) :

| Scénario | RTO cible | RPO cible | Procédure |
|----------|-----------|-----------|-----------|
| Crash container | < 2 min | 0 (état en mémoire perdu) | Restart auto Docker |
| Panne MySQL | < 1 min | 0 (mode dégradé immédiat) | Healthcheck + restart |
| Perte VPS | < 30 min | < 1h (dernier dump) | Rebuild depuis Git + image + dump |
| Bug bloquant | < 5 min | 0 | Git revert + restart |
| Corruption image Docker | < 5 min | Dernier snapshot | Rollback tag image |

### Choix de l'outil de monitoring — Argumentation

#### Comparatif des solutions envisagées

| Critère | Docker natif | Prometheus + Grafana | Portainer | Zabbix |
|---------|-------------|---------------------|-----------|--------|
| **Coût** | Gratuit (inclus) | Gratuit (open source) | Gratuit (CE) | Gratuit (open source) |
| **Complexité** | Très faible | Moyenne | Faible | Élevée |
| **Ressources** | Aucune | ~500 Mo RAM | ~200 Mo RAM | ~1 Go RAM |
| **Métriques Docker** | ✅ Basique | ✅ Complet | ✅ Bon | ✅ Complet |
| **Métriques applicatives** | ❌ | ✅ Custom | ❌ | ✅ Custom |
| **Alerting** | ❌ | ✅ AlertManager | ✅ Webhooks | ✅ Intégré |
| **Dashboard** | CLI uniquement | ✅ Grafana | ✅ Web UI | ✅ Web UI |
| **Adapté au projet** | Phase dev | Phase production | Phase intermédiaire | Surdimensionné |

#### Solution retenue : monitoring multi-couches

**Phase actuelle (développement)** : Docker natif + logging applicatif intégré
- Justification : pas de surcharge mémoire sur un VPS partagé, suffisant pour le développement
- Le serveur de jeu utilise déjà 3 Go RAM, MySQL 512 Mo → peu de marge pour des agents monitoring lourds

**Phase cible (production)** : Prometheus + Grafana + AlertManager
- Justification : solution standard de l'industrie, open source, écosystème riche
- `cAdvisor` pour les métriques Docker (CPU, RAM, réseau par container)
- Exporteur custom Lua pour les métriques applicatives GMod
- AlertManager pour les notifications Discord/Telegram
- Grafana pour les dashboards visuels

Cette approche progressive permet d'adapter le monitoring à la maturité de l'infrastructure sans gaspiller des ressources.

---

## 2. Données à monitorer (C6.2)

### Couche infrastructure

| Métrique | Source | Seuil d'alerte | Criticité |
|----------|--------|----------------|-----------|
| **CPU par container** | `docker stats` / cAdvisor | > 80% pendant 5 min | 🟠 Haute |
| **RAM par container** | `docker stats` / cAdvisor | > 90% du `mem_limit` | 🔴 Critique |
| **RAM GMod** | `docker stats` | > 2.7 Go (sur 3 Go limit) | 🔴 Critique |
| **RAM MySQL** | `docker stats` | > 450 Mo (sur 512 Mo limit) | 🟠 Haute |
| **Espace disque** | `df -h` / node_exporter | > 85% | 🔴 Critique |
| **État container** | `docker ps` / healthcheck | Container `unhealthy` ou `exited` | 🔴 Critique |
| **Réseau** | `docker stats` / iptables | Trafic anormal (> 100 Mbps) | 🟠 Haute |
| **Latence MySQL** | Healthcheck interval | Ping > 5s | 🟠 Haute |

### Couche applicative (serveur GMod)

| Métrique | Source | Seuil d'alerte | Criticité |
|----------|--------|----------------|-----------|
| **Joueurs connectés** | Query port 27015 | 0 pendant heures de pointe | 🟡 Info |
| **Actions/minute** | `sv_logging.lua` (MySQL) | > 100/min (possible abus) | 🟠 Haute |
| **Rate limit hits** | `sv_security.lua` | > 10 rejets/min pour 1 joueur | 🟠 Haute |
| **Erreurs Lua** | Console serveur (`ERROR`) | Toute erreur | 🟡 Moyenne |
| **Ghosts actifs** | `sv_ghosts.lua` | > 200 simultanés (perf) | 🟠 Haute |
| **Blueprints chargés** | `sv_blueprints.lua` | > 500 props en 1 blueprint | 🟡 Info |
| **Net messages/s** | Monitoring réseau GMod | > 50/s pour 1 joueur | 🔴 Critique |

### Couche base de données

| Métrique | Source | Seuil d'alerte | Criticité |
|----------|--------|----------------|-----------|
| **Connexions actives** | `SHOW PROCESSLIST` | > 10 connexions | 🟠 Haute |
| **Slow queries** | `slow_query_log` | > 5 requêtes > 1s/heure | 🟠 Haute |
| **Taille base** | `information_schema` | > 1 Go | 🟡 Info |
| **Requêtes/seconde** | `SHOW STATUS` | > 100 QPS | 🟡 Info |
| **Uptime** | `mysqladmin status` | Restart inattendu | 🔴 Critique |

---

## 3. Monitoring en place

### Monitoring applicatif : sv_logging.lua

Le module de logging intégré à l'addon trace toutes les actions significatives :

```
[Construction] [SAVE] Player "Thomas" saved blueprint "base_militaire" (45 props)
[Construction] [LOAD] Player "Thomas" loaded blueprint "base_militaire"
[Construction] [MATERIALIZE] Player "Alex" materialized ghost (crate: 49 remaining)
[Construction] [VEHICLE] Player "Thomas" loaded crate onto sim_fphy_codww2opel
[Construction] [SECURITY] Rate limit hit for STEAM_0:0:12345 on "save" (cooldown: 10s)
```

**Double destination** (version dev) :
- **Console serveur** : visibilité immédiate pour l'admin
- **Base MySQL** (`blueprint_logs`) : historique persistant, requêtable via SQL

**Données loguées** :

| Champ | Type | Contenu |
|-------|------|---------|
| `steamid` | VARCHAR | Identifiant unique du joueur |
| `player_name` | VARCHAR | Nom affiché |
| `action` | ENUM | save, load, delete, share, materialize |
| `blueprint_name` | VARCHAR | Nom du blueprint concerné |
| `details` | JSON | Contexte additionnel |
| `created_at` | TIMESTAMP | Horodatage précis |

### Monitoring infrastructure : Docker natif

```bash
# État des containers et healthcheck
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Consommation temps réel (CPU, RAM, réseau, I/O)
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Vérifier le healthcheck MySQL
docker inspect gmod-mysql --format='{{.State.Health.Status}}'

# Logs temps réel du serveur
docker logs -f --tail 100 gmod-server | grep -E "ERROR|Construction|LUA"
```

### Commandes admin in-game

| Commande | Description | Accès |
|----------|-------------|-------|
| `construction_logs [n]` | Affiche les n derniers logs (MySQL) | Superadmin |
| `construction_stats` | Statistiques générales | Superadmin |

---

## 4. Architecture de monitoring cible

```
┌─────────────────────────────────────────────────────┐
│                    VPS Hostinger                     │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ GMod     │  │ MySQL    │  │ Prometheus       │  │
│  │ Server   │  │ 8.0      │  │ + cAdvisor       │  │
│  │ (3 Go)   │  │ (512 Mo) │  │ + AlertManager   │  │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘  │
│       │              │                 │             │
│       │    Métriques Docker + MySQL    │             │
│       └──────────────┼─────────────────┘             │
│                      │                               │
│              ┌───────┴────────┐                      │
│              │    Grafana     │                      │
│              │  (Dashboards)  │                      │
│              └───────┬────────┘                      │
└──────────────────────┼───────────────────────────────┘
                       │
              Alertes Discord / Telegram
```

### Dashboards Grafana prévus

1. **Vue d'ensemble** : état des containers, uptime, joueurs connectés
2. **Performances** : CPU/RAM par container, latence MySQL, I/O disque
3. **Application** : actions/minute, rate limit hits, erreurs Lua, ghosts actifs
4. **Sécurité** : tentatives bloquées, net messages anormaux, IP suspectes
