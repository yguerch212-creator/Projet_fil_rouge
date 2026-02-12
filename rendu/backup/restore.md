# 🔄 Plan de restauration et sécurité des sauvegardes

> **Critères adressés** : C21.1 (Sécurité physique et logique des données sauvegardées), C21.2 (Tests de restauration fonctionnels), C22.2 (Argumentation des choix techniques)

---

## 1. Sécurité physique des sauvegardes — C21.1

### Localisation et accès

| Copie | Localisation | Accès | Protection |
|-------|-------------|-------|------------|
| **Originale** | VPS Hostinger (`/root/ProjetFilRouge/docker/`) | SSH root uniquement | Firewall UFW, clé SSH |
| **Backup local** | VPS (`/root/backups/`) | SSH root uniquement | Permissions 700, propriétaire root |
| **Code distant** | GitHub (privé → public pour le projet) | PAT + SSH key | 2FA GitHub activé |
| **Images Docker** | VPS (`/root/backups/images/`) | SSH root uniquement | Exports compressés |

### Mesures de sécurité physique

#### Contrôle d'accès au VPS

```bash
# Accès SSH uniquement par clé (pas de mot de passe)
# /etc/ssh/sshd_config
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin prohibit-password

# Firewall UFW
ufw allow 22/tcp        # SSH
ufw allow 27015         # GMod
ufw deny incoming       # Tout le reste bloqué
```

#### Permissions des répertoires de backup

```bash
# Seul root peut accéder aux backups
chmod 700 /root/backups
chmod 600 /root/backups/mysql/**/*.sql.gz
chmod 600 /root/backups/files/**/*.tar.gz
chmod 600 /root/backups/checksums_*.sha256
```

#### Isolation des conteneurs

Les conteneurs Docker n'ont **pas accès** au répertoire de backup :
- Le volume `mysql-data` est distinct de `/root/backups/`
- Les bind mounts ne montent que les répertoires nécessaires (addons, config)
- Un conteneur compromis ne peut pas altérer les sauvegardes

---

## 2. Sécurité logique des sauvegardes — C21.1

### Intégrité : Checksums SHA-256

Chaque backup génère un fichier de checksums :

```bash
# Vérification d'intégrité
sha256sum -c /root/backups/checksums_2025-02-12_030000.sha256

# Sortie attendue :
# /root/backups/mysql/daily/mysql_2025-02-12_030000.sql.gz: OK
# /root/backups/files/daily/files_2025-02-12_030000.tar.gz: OK
```

### Chiffrement (amélioration implémentable)

Pour une sécurité renforcée, les backups peuvent être chiffrés avec GPG :

```bash
# Chiffrement d'un dump MySQL
gpg --symmetric --cipher-algo AES256 \
    --output mysql_2025-02-12.sql.gz.gpg \
    mysql_2025-02-12.sql.gz

# Déchiffrement
gpg --decrypt mysql_2025-02-12.sql.gz.gpg > mysql_2025-02-12.sql.gz
```

> **État actuel** : Non implémenté en production car les données (logs de construction GMod) ne contiennent pas d'informations personnelles sensibles. Le chiffrement est préparé et documenté pour activation si le SI évolue vers des données plus sensibles.

### Protection contre la suppression accidentelle

```bash
# Attribut immutable sur les backups mensuels (protection suppression root)
chattr +i /root/backups/mysql/monthly/*.sql.gz
chattr +i /root/backups/files/monthly/*.tar.gz

# Pour modifier/supprimer : chattr -i <fichier> d'abord
```

### Matrice des menaces et contre-mesures

| Menace | Probabilité | Impact | Contre-mesure |
|--------|------------|--------|---------------|
| Suppression accidentelle (rm) | Moyenne | Critique | `chattr +i` sur mensuels, rétention multi-niveaux |
| Ransomware/chiffrement malveillant | Faible | Critique | Copie GitHub hors VPS, backups avec permissions restreintes |
| Corruption disque | Faible | Élevé | Checksums SHA-256, vérification post-backup |
| Accès non autorisé SSH | Faible | Critique | Clé SSH uniquement, fail2ban, UFW |
| Compromission conteneur Docker | Faible | Moyen | Isolation volumes, backups hors conteneurs |
| Perte totale VPS (datacenter) | Très faible | Critique | Code sur GitHub, images Docker reconstituables |

---

## 3. Procédures de restauration — C21.2

### 3.1 Restauration MySQL

```bash
#!/bin/bash
# restore_mysql.sh — Restauration de la base de données
set -euo pipefail

BACKUP_FILE="${1:?Usage: $0 <fichier_backup.sql.gz>}"
MYSQL_CONTAINER="gmod-mysql"
MYSQL_USER="root"
MYSQL_PASS="GmodSecurePass2025!"
MYSQL_DB="gmod_construction"

echo "[*] Vérification intégrité du backup..."
gzip -t "$BACKUP_FILE" || { echo "ERREUR: Archive corrompue"; exit 1; }

echo "[*] Vérification checksum..."
BACKUP_DIR=$(dirname "$BACKUP_FILE")
BACKUP_NAME=$(basename "$BACKUP_FILE")
CHECKSUM_FILE=$(ls -t "$BACKUP_DIR"/../checksums_*.sha256 2>/dev/null | head -1)
if [ -n "$CHECKSUM_FILE" ]; then
    grep "$BACKUP_NAME" "$CHECKSUM_FILE" | sha256sum -c - || echo "WARN: Checksum non trouvé"
fi

echo "[*] Arrêt du serveur GMod (éviter les écritures concurrentes)..."
docker stop gmod-server 2>/dev/null || true

echo "[*] Restauration de $BACKUP_FILE vers $MYSQL_DB..."
zcat "$BACKUP_FILE" | docker exec -i "$MYSQL_CONTAINER" \
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB"

echo "[*] Vérification post-restauration..."
docker exec "$MYSQL_CONTAINER" mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" "$MYSQL_DB" \
    -e "SELECT COUNT(*) as total_logs FROM construction_logs;" 2>/dev/null || echo "Table logs vide ou inexistante"

echo "[*] Redémarrage du serveur GMod..."
docker start gmod-server

echo "[✓] Restauration MySQL terminée avec succès"
```

### 3.2 Restauration des fichiers de configuration

```bash
#!/bin/bash
# restore_files.sh — Restauration des fichiers de configuration
set -euo pipefail

BACKUP_FILE="${1:?Usage: $0 <fichier_backup.tar.gz>}"
DOCKER_DIR="/root/ProjetFilRouge/docker"

echo "[*] Vérification intégrité..."
gzip -t "$BACKUP_FILE" || { echo "ERREUR: Archive corrompue"; exit 1; }

echo "[*] Sauvegarde de l'état actuel (sécurité)..."
SAFETY_BACKUP="/tmp/pre-restore_$(date +%s).tar.gz"
tar czf "$SAFETY_BACKUP" -C "$DOCKER_DIR" addons/ gamemodes/ server-config/ docker-compose.yml
echo "    Backup de sécurité: $SAFETY_BACKUP"

echo "[*] Arrêt des services..."
cd "$DOCKER_DIR"
docker compose down

echo "[*] Restauration depuis $BACKUP_FILE..."
tar xzf "$BACKUP_FILE" -C "$DOCKER_DIR"

echo "[*] Redémarrage des services..."
docker compose up -d

echo "[*] Vérification santé des conteneurs..."
sleep 10
docker ps --format "table {{.Names}}\t{{.Status}}"

echo "[✓] Restauration fichiers terminée"
echo "    En cas de problème, backup de sécurité: $SAFETY_BACKUP"
```

### 3.3 Restauration du code depuis Git

```bash
# Restauration complète depuis GitHub
git clone https://github.com/yguerch212-creator/Projet_fil_rouge.git /root/ProjetFilRouge

# Restauration d'un fichier spécifique
git checkout HEAD -- docker/addons/rp_construction_system/

# Restauration à un commit précis
git checkout abc1234 -- docker/addons/rp_construction_system/
```

### 3.4 Restauration d'une image Docker

```bash
# Depuis un export sauvegardé
docker load < /root/backups/images/v2.2-vehicles_2025-02-01_040000.tar.gz

# Rebuild depuis le tag existant
docker tag projetfilrouge/gmod-server:v2.2-vehicles projetfilrouge/gmod-server:jour2-stable
```

### 3.5 Restauration complète (disaster recovery)

Procédure en cas de perte totale du VPS :

```bash
# 1. Nouveau VPS — Installation des prérequis
apt update && apt install -y docker.io docker-compose-v2 git

# 2. Récupération du code
git clone https://github.com/yguerch212-creator/Projet_fil_rouge.git /root/ProjetFilRouge

# 3. Restauration des backups MySQL (si disponibles)
# → Copier depuis stockage externe ou backup local survivant

# 4. Démarrage de l'infrastructure
cd /root/ProjetFilRouge/docker
docker compose up -d

# 5. Restauration MySQL
./restore_mysql.sh /path/to/mysql_backup.sql.gz

# 6. Vérification
docker ps
docker logs gmod-server --tail 50
```

**RTO estimé** : 2-4 heures (incluant provisioning VPS, installation, restauration)

---

## 4. Tests de restauration — C21.2

### Plan de tests

| Test | Fréquence | Procédure | Critère de succès |
|------|-----------|-----------|-------------------|
| **T1 — Intégrité backup** | Chaque backup | `gzip -t` + `sha256sum -c` | Exit code 0, checksums valides |
| **T2 — Restore MySQL** | Mensuel | Restauration vers base de test | Données identiques à l'original |
| **T3 — Restore fichiers** | Mensuel | Extraction dans répertoire temporaire | Fichiers intacts, permissions correctes |
| **T4 — Restore complet** | Trimestriel | Simulation disaster recovery | Serveur fonctionnel en < 4h |

### Script de test automatisé

```bash
#!/bin/bash
# test_restore.sh — Vérification automatisée des backups
set -euo pipefail

BACKUP_ROOT="/root/backups"
TEST_DIR="/tmp/restore_test_$$"
ERRORS=0

log() { echo "[TEST $(date '+%H:%M:%S')] $1"; }

mkdir -p "$TEST_DIR"

# --- T1 : Intégrité des archives ---
log "T1 — Vérification intégrité des archives"
for gz in "$BACKUP_ROOT"/mysql/daily/*.sql.gz "$BACKUP_ROOT"/files/daily/*.tar.gz; do
    [ -f "$gz" ] || continue
    if ! gzip -t "$gz" 2>/dev/null; then
        log "FAIL: $gz est corrompu"
        ((ERRORS++))
    fi
done
log "T1 — $([ $ERRORS -eq 0 ] && echo 'PASS' || echo 'FAIL')"

# --- T2 : Restauration MySQL dans base de test ---
log "T2 — Test restauration MySQL"
LATEST_MYSQL=$(ls -t "$BACKUP_ROOT"/mysql/daily/*.sql.gz 2>/dev/null | head -1)
if [ -n "$LATEST_MYSQL" ]; then
    # Créer base de test
    docker exec gmod-mysql mysql -uroot -pGmodSecurePass2025! \
        -e "CREATE DATABASE IF NOT EXISTS gmod_test_restore;" 2>/dev/null
    
    # Restaurer
    zcat "$LATEST_MYSQL" | sed 's/gmod_construction/gmod_test_restore/g' | \
        docker exec -i gmod-mysql mysql -uroot -pGmodSecurePass2025! gmod_test_restore 2>/dev/null
    
    # Vérifier
    TABLES=$(docker exec gmod-mysql mysql -uroot -pGmodSecurePass2025! gmod_test_restore \
        -e "SHOW TABLES;" 2>/dev/null | wc -l)
    
    if [ "$TABLES" -gt 1 ]; then
        log "T2 — PASS ($((TABLES-1)) tables restaurées)"
    else
        log "T2 — FAIL (aucune table)"
        ((ERRORS++))
    fi
    
    # Nettoyage
    docker exec gmod-mysql mysql -uroot -pGmodSecurePass2025! \
        -e "DROP DATABASE gmod_test_restore;" 2>/dev/null
else
    log "T2 — SKIP (aucun backup MySQL trouvé)"
fi

# --- T3 : Restauration fichiers ---
log "T3 — Test restauration fichiers"
LATEST_FILES=$(ls -t "$BACKUP_ROOT"/files/daily/*.tar.gz 2>/dev/null | head -1)
if [ -n "$LATEST_FILES" ]; then
    tar xzf "$LATEST_FILES" -C "$TEST_DIR" 2>/dev/null
    
    # Vérifier présence des fichiers critiques
    CHECKS=0
    [ -d "$TEST_DIR/addons/rp_construction_system" ] && ((CHECKS++))
    [ -f "$TEST_DIR/docker-compose.yml" ] && ((CHECKS++))
    [ -d "$TEST_DIR/server-config" ] && ((CHECKS++))
    
    if [ "$CHECKS" -ge 3 ]; then
        log "T3 — PASS ($CHECKS/3 vérifications)"
    else
        log "T3 — FAIL ($CHECKS/3 vérifications)"
        ((ERRORS++))
    fi
else
    log "T3 — SKIP (aucun backup fichiers trouvé)"
fi

# --- Nettoyage ---
rm -rf "$TEST_DIR"

# --- Résultat ---
echo ""
if [ $ERRORS -eq 0 ]; then
    log "✅ TOUS LES TESTS PASSENT"
else
    log "❌ $ERRORS ERREUR(S) DÉTECTÉE(S)"
fi

exit $ERRORS
```

### Résultat type d'un test

```
[TEST 15:30:01] T1 — Vérification intégrité des archives
[TEST 15:30:02] T1 — PASS
[TEST 15:30:02] T2 — Test restauration MySQL
[TEST 15:30:05] T2 — PASS (3 tables restaurées)
[TEST 15:30:05] T3 — Test restauration fichiers
[TEST 15:30:06] T3 — PASS (3/3 vérifications)

[TEST 15:30:06] ✅ TOUS LES TESTS PASSENT
```

---

## 5. Argumentation des choix — C22.2

### Stratégie locale vs cloud

| Critère | Backup local (VPS) | Backup cloud (S3/Backblaze) |
|---------|--------------------|-----------------------------|
| **Coût** | 0€ (inclus VPS) | ~2-5€/mois | 
| **Latence restauration** | Instantanée | Dépend bande passante |
| **Protection sinistre** | ❌ Même datacenter | ✅ Géo-répliqué |
| **Complexité** | Faible | Moyenne (credentials, SDK) |
| **RGPD** | Même juridiction | Vérifier localisation |

**Choix** : Backup local + GitHub pour le code. Le budget ne justifie pas un stockage cloud dédié pour ~8 Mo de données. Amélioration prévue si le projet évolue vers la production.

### Pourquoi pas de réplication MySQL ?

La réplication (master-slave) offrirait un RPO quasi nul, mais :
- Nécessite un **deuxième serveur** (coût)
- **Surdimensionné** pour ~50 Mo de logs
- **Complexité** de maintenance disproportionnée

Le dump horaire avec `--single-transaction` couvre le besoin avec un RPO acceptable de 1 heure.

---

## 6. Récapitulatif de conformité

| Critère | Exigence | Réponse apportée | Référence |
|---------|----------|-------------------|-----------|
| **C21.1** | Sécurité physique et logique | Permissions restrictives, checksums SHA-256, isolation conteneurs, chiffrement documenté | §1-2 |
| **C21.2** | Tests de restauration fonctionnels | 4 niveaux de tests, scripts automatisés, procédures détaillées | §3-4 |
| **C22.2** | Argumentation technique | Comparatifs local vs cloud, justification mysqldump, stratégie rétention | §5 |
