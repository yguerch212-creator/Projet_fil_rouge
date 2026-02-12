# 🔄 Redondance, réplication et clustering — C5

> **C5.1** — Pertinence des améliorations proposées (matrice de risques, solutions)
> **C5.2** — Qualité du PCA modifié (continuité opérationnelle)

---

## 1. Matrice de risques (C5.1)

### Identification des actifs critiques

| Actif | Criticité | Propriétaire | Données |
|-------|-----------|-------------|---------|
| Serveur GMod | Critique | Admin serveur | État du jeu, joueurs connectés |
| Base MySQL | Haute | Admin serveur | Logs, historique des actions |
| Code addon (Lua) | Haute | Développeur | Code source, configuration |
| Images Docker | Haute | Admin serveur | ~8 Go Workshop + modules |
| Configuration DarkRP | Moyenne | Admin serveur | Jobs, entities, shipments |
| Blueprints joueurs | Basse (côté client) | Joueurs | Fichiers `.dat` locaux |

### Matrice de risques

| # | Risque | Probabilité | Impact | Gravité | Stratégie de mitigation |
|---|--------|-------------|--------|---------|------------------------|
| R1 | **Crash du serveur GMod** | Moyenne | Critique | 🔴 Élevée | Restart auto Docker (`restart: unless-stopped`), snapshots Docker |
| R2 | **Panne MySQL** | Faible | Haute | 🟠 Moyenne | Healthcheck Docker, mode dégradé (addon fonctionne sans DB) |
| R3 | **Corruption Workshop (~8 Go)** | Faible | Critique | 🔴 Élevée | Workshop commitée dans l'image Docker, rollback instantané |
| R4 | **Perte complète du VPS** | Très faible | Critique | 🔴 Critique | Git distant (GitHub), export images Docker, dumps SQL |
| R5 | **Exploitation de vulnérabilité net message** | Faible | Haute | 🟠 Moyenne | Rate limiting, validation serveur, logging |
| R6 | **Bug Lua bloquant (addon cassé)** | Moyenne | Haute | 🟠 Moyenne | Rollback Git, snapshots Docker, tests pré-déploiement |
| R7 | **Saturation mémoire VPS** | Faible | Haute | 🟠 Moyenne | Limites Docker (`mem_limit`), monitoring `docker stats` |
| R8 | **Perte de données MySQL** | Faible | Moyenne | 🟡 Faible | Volume Docker persistant, dumps réguliers |

### Solutions de redondance proposées

| Risque | Solution en place | Amélioration proposée |
|--------|-------------------|----------------------|
| R1 | `docker compose up -d` manuel | `restart: unless-stopped` + script watchdog |
| R2 | Healthcheck MySQL 10s | Réplication master-slave MySQL |
| R3 | Image Docker commitée (8 Go inclus) | Push vers Docker Hub / registry privé |
| R4 | Git + GitHub | + Export images Docker + dump SQL vers S3/Backblaze |
| R5 | Rate limiting `sv_security.lua` | WAF niveau réseau (iptables) |
| R6 | Git revert | Pipeline CI/CD avec tests avant déploiement |
| R7 | `mem_limit: 3g` / `mem_limit: 512m` | Alerting Prometheus quand RAM > 80% |
| R8 | Volume Docker local | Dump MySQL automatisé (cron) + réplication |

---

## 2. Plan de Continuité d'Activité — PCA (C5.2)

### Objectifs du PCA

| Métrique | Objectif actuel | Objectif cible |
|----------|----------------|----------------|
| **RTO** (Recovery Time Objective) | < 5 min (restart Docker) | < 2 min (restart auto) |
| **RPO** (Recovery Point Objective) | Dernier commit Git | < 1h (dumps MySQL horaires) |
| **Disponibilité cible** | 95% | 99% |
| **MTTR** (Mean Time To Repair) | ~10 min (diagnostic + restart) | < 5 min (procédure documentée) |

### Scénarios de continuité

#### Scénario 1 : Crash du container GMod

```
Détection : Docker healthcheck ou absence de joueurs
Temps de détection : < 30 secondes (avec restart: unless-stopped)
Action automatique : Docker redémarre le container
Action manuelle (si échec) :
  $ docker compose down && docker compose up -d
RTO : < 2 minutes
Impact : Déconnexion temporaire des joueurs, reconnexion automatique
```

#### Scénario 2 : Panne MySQL

```
Détection : Healthcheck mysqladmin ping (toutes les 10s)
Impact immédiat : L'addon passe en mode dégradé (pas de logs DB)
  → Les fonctionnalités core (blueprints, ghosts, caisses) continuent
  → Seul le logging en DB est interrompu
Action : docker restart gmod-mysql
RTO : < 1 minute
RPO : Aucune perte (logs console toujours actifs)
```

#### Scénario 3 : Perte complète du VPS

```
Détection : Monitoring externe (ping port 27015)
Plan de reprise :
  1. Provisionner un nouveau VPS (Hostinger, ~10 min)
  2. Installer Docker + Docker Compose (~5 min)
  3. git clone https://github.com/yguerch212-creator/Projet_fil_rouge.git
  4. Restaurer l'image Docker depuis le backup exporté
     $ docker load < backup-gmod-v2.2-vehicles.tar
  5. Restaurer le dump MySQL
     $ docker exec -i gmod-mysql mysql -u root -p < backup.sql
  6. docker compose up -d
RTO : < 30 minutes
RPO : Dernier backup (objectif : < 1 heure)
```

#### Scénario 4 : Corruption de l'addon (bug bloquant)

```
Détection : Erreurs Lua dans les logs serveur, signalements joueurs
Action immédiate :
  $ cd /root/ProjetFilRouge
  $ git log --oneline -5       # Identifier le commit fautif
  $ git revert HEAD            # Annuler le dernier commit
  $ docker restart gmod-server
RTO : < 5 minutes
RPO : Aucune perte (Git conserve tout l'historique)
Alternative : Changer le tag Docker dans docker-compose.yml
  image: projetfilrouge/gmod-server:v2.1-stable
```

### Redondance des données — État actuel

| Donnée | Stockage primaire | Redondance | Niveau |
|--------|------------------|------------|--------|
| Code source addon | Bind mount VPS | Git + GitHub (distant) | ✅ Élevé |
| Configuration DarkRP | Bind mount VPS | Git + GitHub | ✅ Élevé |
| docker-compose.yml | VPS | Git + GitHub | ✅ Élevé |
| Images Docker (8 Go) | Stockage local VPS | `docker commit` (local) | ⚠️ Moyen |
| Base MySQL | Volume Docker local | Aucune réplication | ⚠️ Moyen |
| Workshop Collection | Dans l'image Docker | Commitée = persistante | ✅ Élevé |
| Blueprints joueurs | PC client (`data/`) | Hors périmètre serveur | ℹ️ N/A |

### Améliorations réalisées pour la continuité

#### 1. Stratégie de snapshots Docker (rollback instantané)

Convention de nommage sémantique :

```
projetfilrouge/gmod-server:v{major}.{minor}-{description}
```

| Image | Contenu | Taille |
|-------|---------|--------|
| `v1.0-base` | GMod + DarkRP + 101 addons Workshop | ~8 Go |
| `v1.1-mysql` | + MySQLOO 64-bit | ~8.1 Go |
| `v2-stable` | + Addon v2.0 (ghosts + caisses) | ~8.1 Go |
| `v2.1-stable` | + Import AD2, UI refonte | ~8.1 Go |
| `v2.2-vehicles` | + Véhicules simfphys | ~8.2 Go |

**Rollback** : changer le tag dans `docker-compose.yml` → `docker compose up -d` → serveur restauré en ~30 secondes.

#### 2. Mode dégradé MySQL

L'addon a été conçu pour fonctionner **sans base de données**. Si MySQL est indisponible :
- Les blueprints continuent de fonctionner (stockage client)
- Les ghosts et caisses fonctionnent normalement
- Seul le logging en base est désactivé (les logs console restent actifs)

Ce design élimine MySQL comme **SPOF** (Single Point of Failure) pour les fonctionnalités critiques.

#### 3. Healthcheck et démarrage ordonné

```yaml
# docker-compose.yml
services:
  mysql:
    healthcheck:
      test: mysqladmin ping -h localhost
      interval: 10s
      timeout: 5s
      retries: 3
  gmod:
    depends_on:
      mysql:
        condition: service_healthy
```

Le serveur GMod ne démarre que lorsque MySQL est `healthy`, évitant les erreurs de connexion au démarrage.

### Perspectives de clustering

| Horizon | Solution | Bénéfice |
|---------|----------|----------|
| Court terme | `restart: unless-stopped` dans Docker Compose | Restart automatique après crash |
| Moyen terme | Réplication MySQL master-slave (Docker Compose) | Lecture sur slave, failover |
| Moyen terme | Push images vers Docker Hub | Redondance géographique des snapshots |
| Long terme | Docker Swarm / Kubernetes | Orchestration multi-nœuds, HA |
| Long terme | Multi-VPS avec load balancer | Haute disponibilité géographique |
