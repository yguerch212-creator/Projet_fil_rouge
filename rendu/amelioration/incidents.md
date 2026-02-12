# 🚨 Gestion d'incidents — Procédures et retour d'expérience

## Objectif

Définir les procédures de **détection, diagnostic et résolution** des incidents, ainsi que le **retour d'expérience** (post-mortem) pour éviter leur récurrence.

---

## Classification des incidents

### Niveaux de gravité

| Niveau | Nom | Description | Temps de réponse cible |
|--------|-----|-------------|------------------------|
| P1 | **Critique** | Serveur inaccessible, perte de données | < 15 min |
| P2 | **Majeur** | Fonctionnalité clé cassée (blueprints, caisses) | < 1h |
| P3 | **Mineur** | Bug cosmétique, performance dégradée | < 24h |
| P4 | **Amélioration** | Suggestion, optimisation | Planifié |

### Matrice des risques

| Risque | Probabilité | Impact | Gravité | Mitigation |
|--------|-------------|--------|---------|------------|
| Crash serveur GMod | Moyenne | P1 | Élevée | Restart Docker automatique, image commitée |
| Panne MySQL | Faible | P2 | Moyenne | Healthcheck, addon fonctionne sans DB |
| Corruption Workshop (~8 Go) | Faible | P1 | Élevée | Image Docker commitée avec Workshop |
| Exploit net message | Faible | P2 | Moyenne | Rate limiting, validation serveur |
| Perte VPS | Très faible | P1 | Critique | Git + images Docker exportables |
| Bug Lua bloquant | Moyenne | P2 | Moyenne | Rollback via Git, restart serveur |

---

## Procédures de résolution

### P1 — Serveur inaccessible

```
1. DIAGNOSTIC
   $ docker ps                          # Le container tourne-t-il ?
   $ docker logs --tail 50 gmod-server  # Erreur au démarrage ?
   $ docker stats                       # Ressources saturées ?

2. RÉSOLUTION
   Cas A — Container arrêté :
   $ docker compose up -d

   Cas B — Container en erreur :
   $ docker compose down && docker compose up -d

   Cas C — Image corrompue :
   Modifier docker-compose.yml → image: projetfilrouge/gmod-server:v2.2-vehicles
   $ docker compose up -d

   Cas D — VPS saturé (RAM) :
   $ docker stats  # Identifier le container gourmand
   $ docker restart gmod-server

3. VÉRIFICATION
   $ docker ps                          # Container UP ?
   $ docker logs -f gmod-server         # Logs de démarrage OK ?
   Connexion au serveur depuis le client GMod
```

### P2 — Fonctionnalité cassée

```
1. DIAGNOSTIC
   $ docker logs --tail 100 gmod-server | grep "ERROR\|error\|LUA"
   Identifier le fichier Lua en cause dans les logs

2. RÉSOLUTION
   Cas A — Bug dans l'addon :
   $ cd /root/ProjetFilRouge
   $ git log --oneline -5              # Dernier commit ?
   $ git diff HEAD~1                   # Changement récent ?
   $ git revert HEAD                   # Annuler si nécessaire
   $ docker restart gmod-server

   Cas B — Problème de configuration :
   Vérifier sh_config.lua, jobs.lua, entities.lua
   $ docker restart gmod-server

   Cas C — MySQL down :
   $ docker inspect gmod-mysql --format='{{.State.Health.Status}}'
   $ docker restart gmod-mysql
   L'addon continue de fonctionner sans DB (mode dégradé)

3. VÉRIFICATION
   Se connecter au serveur et tester la fonctionnalité
   Les clients doivent se reconnecter (cache Lua)
```

### P3 — Bug mineur / Performance

```
1. DIAGNOSTIC
   Consulter les logs serveur et les logs applicatifs
   $ construction_logs 20              # En console serveur (superadmin)

2. RÉSOLUTION
   Corriger dans le code source (bind mount → effet immédiat au restart)
   $ docker restart gmod-server

3. SUIVI
   Documenter dans le journal de développement
   Commit + push vers GitHub
```

---

## Incidents rencontrés et résolus

### Retour d'expérience du projet

Voici les incidents réels rencontrés au cours du développement, leur diagnostic et leur résolution :

| # | Incident | Gravité | Cause racine | Résolution | Temps |
|---|----------|---------|-------------- |------------|-------|
| 1 | MySQLOO ne charge pas | P2 | Binaire 32-bit au lieu de 64-bit | Remplacement par `gmsv_mysqloo_linux64.dll` | 2h |
| 2 | Workshop re-téléchargé à chaque restart | P3 | Utilisation de `docker restart` au lieu de l'image commitée | `docker commit` après premier démarrage | 1h |
| 3 | Variables d'env pas prises en compte | P3 | `docker restart` ne relit pas le compose | Utilisation systématique de `docker compose up -d` | 30min |
| 4 | Viewmodel invisible côté client | P2 | `resource.AddFile` ne fonctionne pas avec bind mounts Docker | Publication Workshop + `resource.AddWorkshop` | 3h |
| 5 | `SWEP:Reload()` jamais appelé serveur | P2 | `ClipSize = -1` → moteur Source skip le Reload serveur | Net message client → serveur | 2h |
| 6 | Ghost physics après `SetParent()` | P2 | Physique non désactivée après parenting | `phys:EnableMotion(false)` | 1h |
| 7 | Caisse téléportée après `SetParent(nil)` | P2 | Source restaure la position pré-parenting | `timer.Simple(0)` + `SetPos(dropPos)` | 1h30 |
| 8 | Petite caisse ne matérialise pas | P2 | Vérification de classe uniquement sur `construction_crate` | Ajout `construction_crate_small` dans la condition | 15min |
| 9 | Fichiers `.sw.vtx` bloquent gmad | P3 | Extensions non supportées par la whitelist gmad | Suppression des fichiers + `.gitignore` | 10min |
| 10 | Addons Workshop pas dans le menu Tools | P3 | `workshop_download_item` ne monte pas les GMA dans le container | Extraction manuelle + bind mount | 1h |

### Leçons tirées

1. **Toujours vérifier l'architecture** (32-bit vs 64-bit) avant d'installer un module
2. **`docker compose up -d`** est la seule commande fiable pour appliquer les changements
3. **Le moteur Source a des comportements non documentés** → tester chaque hypothèse, ne pas se fier à la "logique"
4. **Les bind mounts Docker ont des limitations** avec le système de distribution de fichiers de GMod
5. **Documenter chaque incident** immédiatement → évite de perdre du temps à redécouvrir le même bug
6. **Le stockage local client** élimine toute une catégorie d'incidents côté serveur (corruption de blueprints, sauvegarde, etc.)

---

## Perspectives d'évolution

### Court terme

- **Restart automatique** : politique `restart: unless-stopped` dans Docker Compose pour redémarrage auto après crash
- **Script de diagnostic** : script bash regroupant les commandes de diagnostic (`docker ps`, `logs`, `stats`, `healthcheck`)

### Moyen terme

- **Alerting** : webhook Discord/Telegram en cas de container `unhealthy` ou de crash
- **Runbook** : documentation formelle des procédures de résolution pour chaque type d'incident
- **Tests automatisés** : scripts de test Lua pour valider les fonctionnalités critiques avant déploiement

### Long terme

- **Post-mortem formel** : template de post-mortem pour chaque incident P1/P2, avec timeline, cause racine, et actions correctives
- **Chaos engineering** : tests de résilience (kill container, saturation mémoire, coupure réseau) pour valider les procédures
