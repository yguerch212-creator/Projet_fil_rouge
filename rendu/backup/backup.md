# 📦 Plan de sauvegarde

> **Critères adressés** : C20.1 (Adéquation aux contraintes et enjeux du SI), C20.2 (Conformité aux exigences de continuité d'activité), C22.2 (Argumentation des choix techniques)

---

## 1. Classification des données — C20.1

### Matrice de criticité

| Donnée | Type | Criticité | RPO | Méthode de sauvegarde |
|--------|------|-----------|-----|----------------------|
| Base MySQL (`gmod_construction`) | Données applicatives | 🔴 Critique | < 1h | `mysqldump` horaire |
| Addon Lua (code source) | Code métier | 🔴 Critique | < 5 min | Git + GitHub (temps réel) |
| Configuration DarkRP | Configuration | 🟠 Élevée | < 24h | Backup fichiers quotidien |
| docker-compose.yml | Infrastructure | 🟠 Élevée | < 24h | Git versionné |
| server.cfg | Configuration serveur | 🟡 Moyenne | < 24h | Backup fichiers quotidien |
| Images Docker taguées | Infrastructure | 🟡 Moyenne | N/A | Tags immutables, rebuild possible |
| Logs serveur | Traces | 🟢 Faible | N/A | Rotation logrotate, non sauvegardés |

### Volumétrie

```
Données MySQL :         ~50 Mo (dump compressé : ~5 Mo)
Fichiers de config :    ~2 Mo
Addon complet :         ~500 Ko
Total par backup :      ~8 Mo compressé
Espace mensuel :        ~2 Go (avec rétention 7j + 1 mensuelle)
```

---

## 2. Politique de sauvegarde — C20.1

### Règle 3-2-1 (adaptée)

La stratégie s'inspire de la **règle 3-2-1** recommandée par l'ANSSI :

| Principe | Implémentation | Justification |
|----------|---------------|---------------|
| **3 copies** | Original + backup local + GitHub | Minimum recommandé |
| **2 supports différents** | Disque VPS + dépôt Git distant | Supports physiquement distincts |
| **1 copie hors site** | GitHub (code) | Protection contre sinistre VPS |

> **Limite budget** : pas de stockage cloud dédié (S3, Backblaze). GitHub couvre le code source. Pour MySQL, la copie reste sur le même VPS dans un répertoire séparé. Amélioration future : export chiffré vers stockage distant.

### Types de sauvegarde

| Type | Cible | Fréquence | Outil | Rétention |
|------|-------|-----------|-------|-----------|
| **Complète** | MySQL + fichiers | Quotidien 03h00 | Script `backup.sh` | 7 jours |
| **Incrémentale** | Code source | Temps réel | Git commits | Illimité |
| **Snapshot MySQL** | Base de données | Horaire | `mysqldump` via cron | 24h (24 fichiers) |
| **Mensuelle** | Tout | 1er du mois | Script `backup.sh --full` | 3 mois |

---

## 3. Schéma de flux des sauvegardes — C20.1

```
┌─────────────────────────────────────────────────────────┐
│                    VPS Hostinger                        │
│                                                         │
│  ┌──────────────┐    mysqldump     ┌─────────────────┐  │
│  │  MySQL 8.0   │ ──────────────→  │  /backup/mysql/  │  │
│  │  (Container)  │   horaire       │  hourly/*.sql.gz │  │
│  └──────────────┘                  │  daily/*.sql.gz  │  │
│                                    └─────────────────┘  │
│  ┌──────────────┐    tar + gzip    ┌─────────────────┐  │
│  │  Fichiers    │ ──────────────→  │  /backup/files/  │  │
│  │  Config/Addon │   quotidien     │  daily/*.tar.gz  │  │
│  └──────────────┘                  └─────────────────┘  │
│                                                         │
│  ┌──────────────┐    git push      ┌─────────────────┐  │
│  │  Repo local  │ ──────────────→  │  GitHub (distant)│  │
│  │  /ProjetFR/  │   temps réel     │  Code + Docs     │  │
│  └──────────────┘                  └─────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Cron scheduler                                   │   │
│  │  0 * * * *  → backup_mysql_hourly.sh              │   │
│  │  0 3 * * *  → backup.sh (full daily)              │   │
│  │  0 4 1 * *  → backup.sh --full (mensuelle)        │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## 4. Continuité d'activité — C20.2

### Scénarios de perte et réponse

| Scénario | Données perdues | Procédure de reprise | RTO estimé |
|----------|----------------|---------------------|------------|
| **Corruption MySQL** | Tables applicatives | Restauration dernier dump horaire | 10 min |
| **Suppression accidentelle addon** | Fichiers Lua | `git checkout` depuis GitHub | 5 min |
| **Crash conteneur GMod** | État mémoire | Redémarrage Docker Compose | 2 min |
| **Panne VPS complète** | Tout le système | Nouveau VPS + restore depuis backups | 2-4 heures |
| **Corruption docker-compose** | Orchestration | `git checkout` + redémarrage | 5 min |

### Matrice RPO/RTO par composant

| Composant | RPO cible | RPO réel | RTO cible | RTO réel |
|-----------|-----------|----------|-----------|----------|
| MySQL | < 1h | 1h (dumps horaires) | < 30 min | ~10 min |
| Code addon | < 5 min | ~temps réel (Git) | < 10 min | ~5 min |
| Configuration | < 24h | 24h (backup quotidien) | < 30 min | ~15 min |
| Infrastructure complète | < 24h | 24h | < 4h | ~2-4h |

### Mode dégradé

En cas de perte partielle, le système peut fonctionner en mode dégradé :

1. **Perte MySQL uniquement** → Le serveur GMod fonctionne, l'addon fonctionne (blueprints sont côté client), seuls les logs sont indisponibles
2. **Perte addon uniquement** → Redéploiement immédiat depuis GitHub, aucune perte de blueprints (stockées côté client dans `data/`)
3. **Perte configuration DarkRP** → Jobs et entités à reconfigurer, mais templates disponibles dans le repo Git

> **Point clé architectural** : Le choix de stocker les blueprints **côté client** (fichiers `.dat` locaux) rend le système intrinsèquement résilient. Même une perte totale du serveur ne détruit aucun blueprint joueur.

---

## 5. Script de sauvegarde — C20.1, C20.2

### `backup.sh`

```bash
#!/bin/bash
# =============================================================================
# backup.sh — Script de sauvegarde automatisé
# Projet Fil Rouge — RP Construction System
# =============================================================================

set -euo pipefail

# --- Configuration ---
BACKUP_ROOT="/root/backups"
DOCKER_DIR="/root/ProjetFilRouge/docker"
MYSQL_CONTAINER="gmod-mysql"
MYSQL_USER="root"
MYSQL_PASS="GmodSecurePass2025!"
MYSQL_DB="gmod_construction"
RETENTION_DAILY=7
RETENTION_MONTHLY=3
DATE=$(date +%Y-%m-%d_%H%M%S)
LOG_FILE="/var/log/backup-gmod.log"

# --- Fonctions ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_disk_space() {
    local available_mb
    available_mb=$(df "$BACKUP_ROOT" --output=avail -BM | tail -1 | tr -d 'M ')
    if [ "$available_mb" -lt 500 ]; then
        log "ERREUR: Espace disque insuffisant (${available_mb}Mo < 500Mo)"
        exit 1
    fi
    log "Espace disque disponible: ${available_mb}Mo"
}

backup_mysql() {
    local dest="$BACKUP_ROOT/mysql/daily"
    mkdir -p "$dest"
    
    log "Sauvegarde MySQL : $MYSQL_DB"
    docker exec "$MYSQL_CONTAINER" mysqldump \
        -u"$MYSQL_USER" -p"$MYSQL_PASS" \
        --single-transaction \
        --routines \
        --triggers \
        "$MYSQL_DB" | gzip > "$dest/mysql_${DATE}.sql.gz"
    
    # Vérification intégrité
    if gzip -t "$dest/mysql_${DATE}.sql.gz" 2>/dev/null; then
        local size
        size=$(du -h "$dest/mysql_${DATE}.sql.gz" | cut -f1)
        log "MySQL OK : mysql_${DATE}.sql.gz ($size)"
    else
        log "ERREUR: Archive MySQL corrompue !"
        rm -f "$dest/mysql_${DATE}.sql.gz"
        exit 1
    fi
}

backup_mysql_hourly() {
    local dest="$BACKUP_ROOT/mysql/hourly"
    mkdir -p "$dest"
    
    log "Sauvegarde MySQL horaire"
    docker exec "$MYSQL_CONTAINER" mysqldump \
        -u"$MYSQL_USER" -p"$MYSQL_PASS" \
        --single-transaction \
        "$MYSQL_DB" | gzip > "$dest/mysql_hourly_${DATE}.sql.gz"
    
    # Garder seulement les 24 dernières
    ls -t "$dest"/mysql_hourly_*.sql.gz 2>/dev/null | tail -n +25 | xargs -r rm
    log "Nettoyage horaire : conservation des 24 derniers dumps"
}

backup_files() {
    local dest="$BACKUP_ROOT/files/daily"
    mkdir -p "$dest"
    
    log "Sauvegarde fichiers de configuration et addon"
    tar czf "$dest/files_${DATE}.tar.gz" \
        -C "$DOCKER_DIR" \
        --exclude='mysql-data' \
        --exclude='*.log' \
        addons/ \
        gamemodes/ \
        server-config/ \
        docker-compose.yml \
        2>/dev/null
    
    local size
    size=$(du -h "$dest/files_${DATE}.tar.gz" | cut -f1)
    log "Fichiers OK : files_${DATE}.tar.gz ($size)"
}

backup_docker_images() {
    local dest="$BACKUP_ROOT/images"
    mkdir -p "$dest"
    
    log "Export des images Docker taguées"
    for tag in v1.0-base v1.1-mysql v2-stable v2.1-stable v2.2-vehicles; do
        local image="projetfilrouge/gmod-server:$tag"
        if docker image inspect "$image" &>/dev/null; then
            docker save "$image" | gzip > "$dest/${tag}_${DATE}.tar.gz"
            log "Image exportée : $tag"
        fi
    done
}

generate_checksum() {
    log "Génération des checksums SHA-256"
    find "$BACKUP_ROOT" -name "*_${DATE}*" -type f | while read -r file; do
        sha256sum "$file" >> "$BACKUP_ROOT/checksums_${DATE}.sha256"
    done
    log "Checksums : checksums_${DATE}.sha256"
}

cleanup_old() {
    log "Nettoyage des anciennes sauvegardes"
    
    # Daily : garder N jours
    find "$BACKUP_ROOT/mysql/daily" -name "*.sql.gz" -mtime +$RETENTION_DAILY -delete 2>/dev/null
    find "$BACKUP_ROOT/files/daily" -name "*.tar.gz" -mtime +$RETENTION_DAILY -delete 2>/dev/null
    
    # Monthly : garder N mois
    find "$BACKUP_ROOT/mysql/monthly" -name "*.sql.gz" -mtime +$((RETENTION_MONTHLY * 30)) -delete 2>/dev/null
    find "$BACKUP_ROOT/files/monthly" -name "*.tar.gz" -mtime +$((RETENTION_MONTHLY * 30)) -delete 2>/dev/null
    
    # Checksums anciens
    find "$BACKUP_ROOT" -name "checksums_*.sha256" -mtime +$RETENTION_DAILY -delete 2>/dev/null
    
    log "Nettoyage terminé (rétention: ${RETENTION_DAILY}j daily, ${RETENTION_MONTHLY} mois monthly)"
}

# --- Main ---
main() {
    log "========== DÉBUT SAUVEGARDE =========="
    
    check_disk_space
    
    case "${1:-daily}" in
        hourly)
            backup_mysql_hourly
            ;;
        daily)
            backup_mysql
            backup_files
            generate_checksum
            cleanup_old
            ;;
        --full|monthly)
            backup_mysql
            backup_files
            backup_docker_images
            generate_checksum
            # Copie vers répertoire monthly
            mkdir -p "$BACKUP_ROOT/mysql/monthly" "$BACKUP_ROOT/files/monthly"
            cp "$BACKUP_ROOT/mysql/daily/mysql_${DATE}.sql.gz" "$BACKUP_ROOT/mysql/monthly/"
            cp "$BACKUP_ROOT/files/daily/files_${DATE}.tar.gz" "$BACKUP_ROOT/files/monthly/"
            cleanup_old
            ;;
        *)
            echo "Usage: $0 {hourly|daily|--full|monthly}"
            exit 1
            ;;
    esac
    
    log "========== FIN SAUVEGARDE =========="
}

main "$@"
```

### Planification cron

```cron
# Sauvegarde MySQL horaire
0 * * * * /root/scripts/backup.sh hourly >> /var/log/backup-gmod.log 2>&1

# Sauvegarde complète quotidienne à 03h00
0 3 * * * /root/scripts/backup.sh daily >> /var/log/backup-gmod.log 2>&1

# Sauvegarde mensuelle complète (avec images Docker)
0 4 1 * * /root/scripts/backup.sh --full >> /var/log/backup-gmod.log 2>&1
```

### Arborescence des sauvegardes

```
/root/backups/
├── mysql/
│   ├── hourly/          ← Dumps horaires (rotation 24)
│   │   ├── mysql_hourly_2025-02-12_140000.sql.gz
│   │   └── ...
│   ├── daily/           ← Dumps quotidiens (rétention 7j)
│   │   ├── mysql_2025-02-12_030000.sql.gz
│   │   └── ...
│   └── monthly/         ← Dumps mensuels (rétention 3 mois)
│       └── mysql_2025-02-01_040000.sql.gz
├── files/
│   ├── daily/           ← Archives config (rétention 7j)
│   │   ├── files_2025-02-12_030000.tar.gz
│   │   └── ...
│   └── monthly/
│       └── files_2025-02-01_040000.tar.gz
├── images/              ← Exports Docker (mensuel)
│   └── v2.2-vehicles_2025-02-01_040000.tar.gz
└── checksums_2025-02-12_030000.sha256
```

---

## 6. Argumentation des choix techniques — C22.2

### Pourquoi `mysqldump` ?

| Outil | Avantages | Inconvénients | Verdict |
|-------|-----------|---------------|---------|
| **mysqldump** | Natif MySQL, fiable, portable, SQL lisible | Lent sur grosses bases, lock possible | ✅ **Retenu** |
| **mysqlpump** | Parallélisme, plus rapide | Moins mature, bugs connus MySQL 8.0 | ❌ |
| **xtrabackup** | Backup à chaud, incrémental physique | Nécessite installation séparée, overkill pour ~50 Mo | ❌ |
| **Réplication MySQL** | Temps réel, aucune perte | Nécessite 2ème serveur, budget inadapté | ❌ Futur |

**Justification** : Pour une base de ~50 Mo, `mysqldump` avec `--single-transaction` offre un backup cohérent sans verrouillage, en quelques secondes. La complexité d'outils plus avancés n'est pas justifiée à cette échelle.

### Pourquoi `tar + gzip` pour les fichiers ?

| Outil | Avantages | Inconvénients | Verdict |
|-------|-----------|---------------|---------|
| **tar + gzip** | Universel, rapide, natif Linux | Pas d'incrémental natif | ✅ **Retenu** |
| **rsync** | Incrémental, efficace réseau | Nécessite destination réseau pour bénéfice | ❌ |
| **borgbackup** | Déduplication, chiffrement intégré | Installation supplémentaire, complexité | ❌ Futur |
| **restic** | Cloud-ready, déduplication | Nécessite backend distant | ❌ Futur |

**Justification** : Les fichiers de configuration totalisent ~2 Mo. L'overhead d'outils de déduplication n'est pas justifié. `tar + gzip` est fiable, vérifiable, et ne nécessite aucune dépendance.

### Pourquoi Git comme backup du code ?

Git n'est pas un outil de backup à proprement parler, mais pour le code source, il offre :
- **Historique complet** de chaque modification
- **Stockage distant** sur GitHub (hors site)
- **Intégrité cryptographique** (chaque commit est un hash SHA-1)
- **Restauration granulaire** (n'importe quel commit, n'importe quel fichier)

Pour le code Lua de l'addon, Git est **supérieur** à un backup fichier classique car il conserve l'historique des changements, pas seulement le dernier état.

---

## 7. Récapitulatif de conformité

| Critère | Exigence | Réponse apportée | Référence |
|---------|----------|-------------------|-----------|
| **C20.1** | Adéquation aux contraintes du SI | Classification par criticité, volumétrie, politique 3-2-1 adaptée au budget | §1-2 |
| **C20.2** | Continuité d'activité | RPO/RTO définis par composant, mode dégradé, scripts automatisés | §4-5 |
| **C22.2** | Argumentation technique | Tableaux comparatifs pour chaque outil, justification documentée | §6 |
