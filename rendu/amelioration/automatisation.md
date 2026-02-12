# ⚙️ Automatisation des tâches d'administration — C8

> **C8.1** — Conformité du script à l'étude de cas
> **C8.2** — Argumentation de la technologie utilisée (efficacité, performance)

---

## 1. Scripts d'administration (C8.1)

### Script 1 : Backup automatisé (`backup.sh`)

Script de sauvegarde complète de l'infrastructure : images Docker, base de données, configuration.

```bash
#!/bin/bash
# =============================================================================
# backup.sh — Sauvegarde automatisée de l'infrastructure GMod
# =============================================================================
# Usage : ./backup.sh [--full|--db-only|--image-only]
# Planification recommandée : cron quotidien à 04:00
# =============================================================================

set -euo pipefail

# --- Configuration ---
BACKUP_DIR="/root/backups"
COMPOSE_DIR="/root/ProjetFilRouge/docker"
MYSQL_CONTAINER="gmod-mysql"
MYSQL_USER="root"
MYSQL_PASS="GmodSecurePass2025!"
MYSQL_DB="gmod_construction"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d-%H%M%S)
LOG_FILE="${BACKUP_DIR}/backup-${DATE}.log"

# --- Fonctions ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_disk_space() {
    local available=$(df -BG "$BACKUP_DIR" | tail -1 | awk '{print $4}' | tr -d 'G')
    if [ "$available" -lt 20 ]; then
        log "⚠️  ATTENTION: Espace disque faible (${available}G disponible)"
        return 1
    fi
    log "✅ Espace disque OK (${available}G disponible)"
}

backup_mysql() {
    log "📦 Sauvegarde MySQL..."
    local dump_file="${BACKUP_DIR}/mysql-${DATE}.sql.gz"
    
    docker exec "$MYSQL_CONTAINER" mysqldump \
        -u "$MYSQL_USER" -p"$MYSQL_PASS" \
        --single-transaction \
        --routines \
        --triggers \
        "$MYSQL_DB" | gzip > "$dump_file"
    
    local size=$(du -sh "$dump_file" | cut -f1)
    log "✅ Dump MySQL: $dump_file ($size)"
}

backup_docker_image() {
    log "📦 Sauvegarde image Docker..."
    local image_file="${BACKUP_DIR}/gmod-image-${DATE}.tar.gz"
    
    # Commit l'état actuel du container
    docker commit gmod-server "projetfilrouge/gmod-server:backup-${DATE}"
    
    # Export compressé
    docker save "projetfilrouge/gmod-server:backup-${DATE}" | gzip > "$image_file"
    
    local size=$(du -sh "$image_file" | cut -f1)
    log "✅ Image Docker: $image_file ($size)"
    
    # Nettoyage du tag temporaire
    docker rmi "projetfilrouge/gmod-server:backup-${DATE}" 2>/dev/null || true
}

backup_config() {
    log "📦 Sauvegarde configuration..."
    local config_file="${BACKUP_DIR}/config-${DATE}.tar.gz"
    
    tar -czf "$config_file" \
        -C /root/ProjetFilRouge \
        docker/docker-compose.yml \
        docker/addons/darkrpmodification/ \
        docker/addons/rp_construction_system/ \
        docker/mysql-init/
    
    local size=$(du -sh "$config_file" | cut -f1)
    log "✅ Configuration: $config_file ($size)"
}

cleanup_old_backups() {
    log "🧹 Nettoyage des backups > ${RETENTION_DAYS} jours..."
    local count=$(find "$BACKUP_DIR" -name "*.gz" -mtime +"$RETENTION_DAYS" | wc -l)
    find "$BACKUP_DIR" -name "*.gz" -mtime +"$RETENTION_DAYS" -delete
    find "$BACKUP_DIR" -name "*.log" -mtime +"$RETENTION_DAYS" -delete
    log "✅ $count fichiers supprimés"
}

# --- Exécution ---
mkdir -p "$BACKUP_DIR"
log "🚀 Début de la sauvegarde ($DATE)"

check_disk_space || exit 1

case "${1:---full}" in
    --full)
        backup_mysql
        backup_docker_image
        backup_config
        ;;
    --db-only)
        backup_mysql
        ;;
    --image-only)
        backup_docker_image
        ;;
esac

cleanup_old_backups

log "✅ Sauvegarde terminée avec succès"
log "📊 Espace utilisé: $(du -sh $BACKUP_DIR | cut -f1)"
```

### Script 2 : Healthcheck et alerting (`healthcheck.sh`)

Script de vérification de l'état de l'infrastructure avec notification en cas de problème.

```bash
#!/bin/bash
# =============================================================================
# healthcheck.sh — Vérification de santé de l'infrastructure
# =============================================================================
# Usage : ./healthcheck.sh
# Planification recommandée : cron toutes les 5 minutes
# =============================================================================

set -euo pipefail

# --- Configuration ---
DISCORD_WEBHOOK=""  # Remplir avec l'URL du webhook Discord
LOG_FILE="/var/log/gmod-healthcheck.log"
ALERT_COOLDOWN=300  # Secondes entre deux alertes identiques
ALERT_STATE_FILE="/tmp/gmod-alert-state"

# --- Fonctions ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local message="$1"
    local alert_key="$2"
    
    # Cooldown : éviter le spam d'alertes
    if [ -f "${ALERT_STATE_FILE}-${alert_key}" ]; then
        local last_alert=$(cat "${ALERT_STATE_FILE}-${alert_key}")
        local now=$(date +%s)
        if [ $((now - last_alert)) -lt $ALERT_COOLDOWN ]; then
            return  # Alerte déjà envoyée récemment
        fi
    fi
    
    log "🚨 ALERTE: $message"
    date +%s > "${ALERT_STATE_FILE}-${alert_key}"
    
    # Notification Discord (si webhook configuré)
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -s -H "Content-Type: application/json" \
            -d "{\"content\": \"🚨 **Alerte GMod** : ${message}\"}" \
            "$DISCORD_WEBHOOK" > /dev/null
    fi
}

check_container() {
    local name="$1"
    local status=$(docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null || echo "not_found")
    
    if [ "$status" != "running" ]; then
        send_alert "Container $name est $status" "container-${name}"
        return 1
    fi
    return 0
}

check_mysql_health() {
    local health=$(docker inspect -f '{{.State.Health.Status}}' gmod-mysql 2>/dev/null || echo "unknown")
    
    if [ "$health" != "healthy" ]; then
        send_alert "MySQL healthcheck: $health" "mysql-health"
        return 1
    fi
    return 0
}

check_memory() {
    local container="$1"
    local limit_mb="$2"
    local threshold=90  # Pourcentage
    
    local usage_bytes=$(docker stats --no-stream --format "{{.MemUsage}}" "$container" 2>/dev/null | awk -F'/' '{print $1}' | tr -d ' ')
    
    # Convertir en Mo (approximatif)
    local usage_mb=$(echo "$usage_bytes" | sed 's/GiB/*1024/;s/MiB//;s/KiB/\/1024/' | bc 2>/dev/null || echo 0)
    
    local percent=$((usage_mb * 100 / limit_mb))
    
    if [ "$percent" -gt "$threshold" ]; then
        send_alert "Container $container utilise ${percent}% de la RAM (${usage_mb}Mo / ${limit_mb}Mo)" "memory-${container}"
        return 1
    fi
    return 0
}

check_disk() {
    local usage=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')
    
    if [ "$usage" -gt 85 ]; then
        send_alert "Espace disque critique : ${usage}% utilisé" "disk-usage"
        return 1
    fi
    return 0
}

# --- Exécution ---
errors=0

check_container "gmod-server" || ((errors++))
check_container "gmod-mysql" || ((errors++))
check_mysql_health || ((errors++))
check_memory "gmod-server" 3072 || ((errors++))
check_memory "gmod-mysql" 512 || ((errors++))
check_disk || ((errors++))

if [ $errors -eq 0 ]; then
    log "✅ Tous les checks OK"
else
    log "⚠️  $errors check(s) en échec"
fi

exit $errors
```

### Script 3 : Déploiement automatisé (`deploy.sh`)

```bash
#!/bin/bash
# =============================================================================
# deploy.sh — Déploiement automatisé de l'addon
# =============================================================================
# Usage : ./deploy.sh [--restart|--update|--rollback <tag>]
# =============================================================================

set -euo pipefail

REPO_DIR="/root/ProjetFilRouge"
COMPOSE_DIR="${REPO_DIR}/docker"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

deploy_update() {
    log "📥 Pull des dernières modifications..."
    cd "$REPO_DIR"
    git pull origin main
    
    log "🔄 Redémarrage du serveur..."
    cd "$COMPOSE_DIR"
    docker restart gmod-server
    
    log "✅ Déployé : $(git log --oneline -1)"
}

deploy_rollback() {
    local tag="$1"
    log "⏪ Rollback vers l'image $tag..."
    
    cd "$COMPOSE_DIR"
    sed -i "s|image: projetfilrouge/gmod-server:.*|image: projetfilrouge/gmod-server:${tag}|" docker-compose.yml
    docker compose up -d
    
    log "✅ Rollback effectué vers $tag"
}

deploy_restart() {
    log "🔄 Redémarrage simple..."
    cd "$COMPOSE_DIR"
    docker compose restart
    log "✅ Serveurs redémarrés"
}

case "${1:---restart}" in
    --update)   deploy_update ;;
    --rollback) deploy_rollback "${2:-v2.2-vehicles}" ;;
    --restart)  deploy_restart ;;
    *)          echo "Usage: $0 [--restart|--update|--rollback <tag>]" ;;
esac
```

### Planification cron

```cron
# Backup quotidien à 04:00
0 4 * * * /root/scripts/backup.sh --full >> /var/log/backup.log 2>&1

# Backup MySQL seul toutes les 6 heures
0 */6 * * * /root/scripts/backup.sh --db-only >> /var/log/backup.log 2>&1

# Healthcheck toutes les 5 minutes
*/5 * * * * /root/scripts/healthcheck.sh >> /var/log/healthcheck.log 2>&1

# Nettoyage des logs Docker chaque dimanche
0 3 * * 0 docker system prune -f >> /var/log/docker-cleanup.log 2>&1
```

---

## 2. Argumentation technologique (C8.2)

### Choix de Bash pour les scripts d'administration

| Critère | Bash | Python | PowerShell | Ansible |
|---------|------|--------|------------|---------|
| **Disponible nativement** | ✅ Oui (Linux) | ⚠️ Souvent oui | ❌ Non (Linux) | ❌ Installation requise |
| **Intégration Docker** | ✅ CLI native | ⚠️ Via subprocess/SDK | ⚠️ Via module | ✅ Module dédié |
| **Intégration système** | ✅ Excellente | ⚠️ Bonne | ❌ Limitée (Linux) | ✅ Bonne |
| **Courbe d'apprentissage** | Faible | Moyenne | Moyenne | Élevée |
| **Complexité du projet** | Faible → adapté | Surdimensionné | Non pertinent | Surdimensionné |
| **Performance** | ✅ Directe | ⚠️ Interpréteur | ⚠️ Interpréteur | ⚠️ Couche d'abstraction |
| **Maintenance** | ✅ Simple | ✅ Simple | ❌ | ⚠️ Playbooks |

**Justification du choix de Bash** :

1. **Disponibilité native** : Bash est présent sur tous les systèmes Linux, y compris dans les containers Docker. Aucune dépendance à installer.

2. **Intégration directe avec Docker** : les commandes `docker`, `docker compose`, `docker stats` sont des commandes shell. Bash permet de les chaîner naturellement sans couche d'abstraction.

3. **Proportionnalité** : pour une infrastructure à 2 containers, Ansible ou Terraform seraient surdimensionnés. Bash offre la juste complexité pour le périmètre du projet.

4. **Robustesse** : `set -euo pipefail` garantit l'arrêt immédiat en cas d'erreur, évitant les exécutions partielles silencieuses.

5. **Planification cron** : les scripts Bash s'intègrent naturellement avec `cron`, le planificateur natif de Linux, sans daemon supplémentaire.

### Choix de Docker Compose comme outil d'orchestration

| Critère | Docker Compose | Docker Swarm | Kubernetes | Podman |
|---------|---------------|-------------|------------|--------|
| **Complexité** | Faible | Moyenne | Très élevée | Faible |
| **Ressources** | Aucune surcharge | ~200 Mo | ~1-2 Go | Aucune surcharge |
| **Multi-container** | ✅ | ✅ | ✅ | ✅ |
| **Scaling** | Manuel | ✅ Auto | ✅ Auto | Manuel |
| **HA / Clustering** | ❌ | ✅ | ✅ | ❌ |
| **Adapté au projet** | ✅ Parfait | Surdimensionné | Très surdimensionné | ✅ Alternative |

**Justification** : Docker Compose est le choix optimal pour une infrastructure à 2 services sur un seul VPS. Il offre :
- La déclaration de l'infrastructure en YAML (Infrastructure as Code)
- La gestion des dépendances entre services (`depends_on`)
- Les healthchecks natifs
- Les limites de ressources (`mem_limit`, `cpus`)
- Aucune surcharge mémoire (contrairement à Kubernetes qui consomme 1-2 Go de RAM juste pour le control plane)

### Choix de Git pour le versioning

| Aspect | Bénéfice pour l'automatisation |
|--------|-------------------------------|
| **Rollback instantané** | `git revert` ou `git checkout` → annuler un déploiement cassé |
| **Traçabilité** | Chaque modification est datée, signée, commentée |
| **Branches** | Possibilité de tester en parallèle (feature branches) |
| **Remote (GitHub)** | Sauvegarde off-site automatique à chaque `push` |
| **CI/CD** | GitHub Actions pour l'automatisation future (lint, tests, deploy) |

### Évolutions technologiques envisagées

| Horizon | Technologie | Cas d'usage | Justification |
|---------|-------------|-------------|---------------|
| Court terme | GitHub Actions | CI/CD (lint Lua, tests, deploy auto) | Gratuit, intégré à GitHub |
| Moyen terme | Prometheus + Grafana | Monitoring avancé | Standard industrie, open source |
| Moyen terme | Watchtower | Mise à jour auto des images | Léger, un seul container |
| Long terme | Docker Swarm | Clustering multi-nœuds | Si besoin de HA |
| Long terme | Terraform | Provisioning VPS | Si infrastructure multi-cloud |
