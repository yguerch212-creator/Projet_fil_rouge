# 🧪 Scénario de test complet — Démonstration end-to-end

> **Critères adressés** : C21.2 (Tests de restauration fonctionnels), C22.1 (Clarté, rigueur et structure du propos)

---

## Contexte du test

**Date** : Février 2025  
**Environnement** : VPS Hostinger (16 Go RAM, Ubuntu 22.04)  
**Infrastructure** : Docker Compose (GMod + MySQL)  
**Objectif** : Valider le plan de sauvegarde et restauration de bout en bout

---

## Scénario 1 : Corruption de la base de données MySQL

### Situation initiale

```bash
# État de la base avant le test
$ docker exec gmod-mysql mysql -uroot -pGmodSecurePass2025! gmod_construction \
    -e "SELECT COUNT(*) as logs FROM construction_logs;"
+------+
| logs |
+------+
|   47 |
+------+
```

### Étape 1 — Sauvegarde

```bash
$ /root/scripts/backup.sh daily
[2025-02-12 03:00:01] ========== DÉBUT SAUVEGARDE ==========
[2025-02-12 03:00:01] Espace disque disponible: 12847Mo
[2025-02-12 03:00:02] Sauvegarde MySQL : gmod_construction
[2025-02-12 03:00:03] MySQL OK : mysql_2025-02-12_030000.sql.gz (4.2K)
[2025-02-12 03:00:03] Sauvegarde fichiers de configuration et addon
[2025-02-12 03:00:04] Fichiers OK : files_2025-02-12_030000.tar.gz (1.8M)
[2025-02-12 03:00:04] Génération des checksums SHA-256
[2025-02-12 03:00:04] Checksums : checksums_2025-02-12_030000.sha256
[2025-02-12 03:00:05] Nettoyage terminé (rétention: 7j daily, 3 mois monthly)
[2025-02-12 03:00:05] ========== FIN SAUVEGARDE ==========
```

### Étape 2 — Simulation de corruption

```bash
# Suppression simulée des données (environnement de test)
$ docker exec gmod-mysql mysql -uroot -pGmodSecurePass2025! gmod_construction \
    -e "DROP TABLE construction_logs;"

# Vérification : table absente
$ docker exec gmod-mysql mysql -uroot -pGmodSecurePass2025! gmod_construction \
    -e "SHOW TABLES;"
+------------------------------+
| Tables_in_gmod_construction  |
+------------------------------+
| construction_blueprints      |
+------------------------------+
# → construction_logs a disparu
```

### Étape 3 — Restauration

```bash
$ /root/scripts/restore_mysql.sh /root/backups/mysql/daily/mysql_2025-02-12_030000.sql.gz
[*] Vérification intégrité du backup...
[*] Arrêt du serveur GMod (éviter les écritures concurrentes)...
gmod-server
[*] Restauration de mysql_2025-02-12_030000.sql.gz vers gmod_construction...
[*] Vérification post-restauration...
+------------+
| total_logs |
+------------+
|         47 |
+------------+
[*] Redémarrage du serveur GMod...
gmod-server
[✓] Restauration MySQL terminée avec succès
```

### Résultat

| Vérification | Attendu | Obtenu | Statut |
|-------------|---------|--------|--------|
| Table `construction_logs` existe | Oui | Oui | ✅ |
| Nombre d'enregistrements | 47 | 47 | ✅ |
| Serveur GMod fonctionnel | Oui | Oui | ✅ |
| Durée totale restauration | < 30 min | ~3 min | ✅ |

---

## Scénario 2 : Suppression accidentelle de l'addon

### Situation initiale

```bash
$ ls /root/ProjetFilRouge/docker/addons/rp_construction_system/
lua/  README.md  addon.json  sql/
```

### Étape 1 — Simulation de suppression

```bash
# Suppression accidentelle de l'addon
$ rm -rf /root/ProjetFilRouge/docker/addons/rp_construction_system/

# Le serveur GMod ne charge plus l'addon
$ docker exec gmod-server ls garrysmod/addons/ | grep construction
# → aucun résultat
```

### Étape 2 — Restauration via Git

```bash
$ cd /root/ProjetFilRouge
$ git checkout HEAD -- docker/addons/rp_construction_system/

$ ls docker/addons/rp_construction_system/
lua/  README.md  addon.json  sql/
```

### Étape 3 — Redémarrage du serveur

```bash
$ docker restart gmod-server
# Le bind mount recharge automatiquement l'addon
```

### Résultat

| Vérification | Attendu | Obtenu | Statut |
|-------------|---------|--------|--------|
| Fichiers addon restaurés | Tous | Tous | ✅ |
| Serveur charge l'addon | Oui | Oui | ✅ |
| Blueprints joueurs intacts | Oui | Oui (côté client) | ✅ |
| Durée totale | < 10 min | ~2 min | ✅ |

---

## Scénario 3 : Restauration fichiers de configuration

### Simulation

```bash
# Corruption du docker-compose.yml
$ echo "invalid yaml" > /root/ProjetFilRouge/docker/docker-compose.yml

# Docker Compose ne peut plus démarrer
$ cd /root/ProjetFilRouge/docker && docker compose up -d
# → Error: yaml: unmarshal errors
```

### Restauration

```bash
# Méthode 1 : Git (rapide)
$ git checkout HEAD -- docker/docker-compose.yml

# Méthode 2 : Backup fichiers (si Git indisponible)
$ tar xzf /root/backups/files/daily/files_2025-02-12_030000.tar.gz \
    -C /root/ProjetFilRouge/docker/ docker-compose.yml

# Redémarrage
$ docker compose up -d
# → Les deux services démarrent correctement
```

### Résultat

| Vérification | Attendu | Obtenu | Statut |
|-------------|---------|--------|--------|
| docker-compose.yml valide | Oui | Oui | ✅ |
| Services démarrés | 2/2 | 2/2 | ✅ |
| Durée totale | < 5 min | ~1 min | ✅ |

---

## Synthèse des tests

| Scénario | Type de perte | Méthode de restauration | RTO cible | RTO réel | Données perdues |
|----------|--------------|------------------------|-----------|----------|-----------------|
| **S1** | Base MySQL corrompue | Dump SQL + script | < 30 min | 3 min | 0 (RPO < 1h) |
| **S2** | Addon supprimé | Git checkout | < 10 min | 2 min | 0 |
| **S3** | Config corrompue | Git / tar backup | < 5 min | 1 min | 0 |

### Observations

1. **Le RTO réel est très inférieur au RTO cible** dans tous les scénarios, grâce aux scripts automatisés et à la taille réduite des données.

2. **Git est la première ligne de défense** pour tout ce qui est versionné (code, config, docker-compose). Les backups fichiers servent de filet de sécurité si le repo est compromis.

3. **Les blueprints joueurs sont naturellement protégés** : stockés côté client dans `data/construction_blueprints/`, ils ne dépendent pas du serveur. Ce choix architectural est un atout majeur pour la résilience.

4. **Le mode dégradé fonctionne** : même sans MySQL, le serveur GMod et l'addon fonctionnent (seuls les logs sont indisponibles).

---

## Préparation à la soutenance — C22.3

### Questions anticipées du jury

**Q1 : Pourquoi ne pas utiliser un stockage cloud pour les backups ?**
> Budget contraint (VPS mutualisé). Pour ~8 Mo de données, le coût d'un S3 n'est pas justifié. GitHub couvre le code. Évolution prévue si passage en production.

**Q2 : Comment garantissez-vous que les backups ne sont pas eux-mêmes corrompus ?**
> Triple vérification : `gzip -t` (intégrité archive), checksums SHA-256 (intégrité contenu), tests de restauration mensuels (fonctionnalité).

**Q3 : Que se passe-t-il si le VPS est totalement perdu ?**
> Le code est sur GitHub (restauration < 5 min). MySQL est perdu jusqu'au dernier dump copié hors VPS. RTO total estimé : 2-4h avec un nouveau VPS. Amélioration : export chiffré des dumps vers stockage distant.

**Q4 : Les données sont-elles conformes RGPD ?**
> Les seules données stockées sont des SteamID (pseudonymes publics) et des logs de construction (actions en jeu). Pas de données personnelles sensibles au sens du RGPD. Néanmoins, les bonnes pratiques sont appliquées : accès restreint, chiffrement documenté, rétention limitée.

**Q5 : Pourquoi des backups horaires pour MySQL et quotidiens pour les fichiers ?**
> La base MySQL est la seule donnée qui change fréquemment (logs en temps réel). Les fichiers de configuration changent rarement (uniquement lors de modifications manuelles). La fréquence est adaptée au rythme de modification de chaque type de donnée.

**Q6 : Comment testez-vous automatiquement les restaurations ?**
> Le script `test_restore.sh` vérifie l'intégrité des archives, restaure MySQL dans une base de test temporaire, et extrait les fichiers dans un répertoire temp. Exécution mensuelle via cron. Les résultats sont loggés.

**Q7 : Quelle est la différence entre votre RPO et RTO ?**
> RPO = perte de données maximale acceptable (1h pour MySQL, temps réel pour le code Git). RTO = temps pour remettre en service (3-30 min selon le scénario). Le RPO dépend de la fréquence de backup, le RTO dépend de la vitesse de restauration.
