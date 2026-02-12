# 🚨 Gestion des incidents — C7

> **C7.1** — Définition d'une procédure efficace de gestion des incidents
> **C7.2** — Réduction des interruptions de service

---

## 1. Procédure de gestion des incidents (C7.1)

### Classification des incidents

| Niveau | Nom | Description | Temps de réponse | Escalade |
|--------|-----|-------------|------------------|----------|
| **P1** | Critique | Serveur inaccessible, perte de données | < 15 min | Immédiate |
| **P2** | Majeur | Fonctionnalité clé cassée | < 1h | Si non résolu en 30 min |
| **P3** | Mineur | Bug cosmétique, performance dégradée | < 24h | Planifiée |
| **P4** | Amélioration | Suggestion, optimisation | Sprint suivant | Non |

### Processus de gestion des incidents (inspiré ITIL)

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Détection│───▸│Classific.│───▸│Diagnostic│───▸│Résolution│───▸│  Clôture │
│          │    │          │    │          │    │          │    │          │
│ - Alert  │    │ - P1→P4  │    │ - Logs   │    │ - Fix    │    │ - Doc    │
│ - Logs   │    │ - Impact │    │ - Stats  │    │ - Rollbk │    │ - RCA    │
│ - Users  │    │ - Urgence│    │ - Tests  │    │ - Patch  │    │ - Leçons │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### Procédures détaillées par niveau

#### Procédure P1 — Serveur inaccessible

```
1. DÉTECTION (< 30s)
   Source : Docker healthcheck / ping externe / signalement joueur
   
2. DIAGNOSTIC (< 5 min)
   $ docker ps                          # Le container tourne-t-il ?
   $ docker logs --tail 50 gmod-server  # Erreur au démarrage ?
   $ docker stats                       # Ressources saturées ?
   $ docker inspect gmod-mysql --format='{{.State.Health.Status}}'

3. RÉSOLUTION (< 10 min)
   Cas A — Container arrêté :
     $ docker compose up -d
   
   Cas B — Container en erreur (boucle de crash) :
     $ docker compose down && docker compose up -d
   
   Cas C — Image corrompue :
     Modifier docker-compose.yml → tag précédent (ex: v2.1-stable)
     $ docker compose up -d
   
   Cas D — VPS saturé (RAM/CPU) :
     $ docker stats  # Identifier le container gourmand
     $ docker restart gmod-server

4. VÉRIFICATION
   $ docker ps                          # Container UP + healthy ?
   $ docker logs -f gmod-server         # Logs de démarrage normaux ?
   Connexion test depuis un client GMod
   
5. DOCUMENTATION
   Remplir le formulaire de post-mortem (voir section 3)
```

#### Procédure P2 — Fonctionnalité cassée

```
1. DIAGNOSTIC
   $ docker logs --tail 100 gmod-server | grep -E "ERROR|error|LUA"
   Identifier le fichier Lua et la ligne en cause

2. RÉSOLUTION
   Cas A — Bug récent (dernier commit) :
     $ cd /root/ProjetFilRouge
     $ git log --oneline -5              # Identifier le commit
     $ git diff HEAD~1                   # Voir le changement
     $ git revert HEAD                   # Annuler si nécessaire
     $ docker restart gmod-server
   
   Cas B — Problème de configuration :
     Vérifier sh_config.lua, jobs.lua, entities.lua
     $ docker restart gmod-server
   
   Cas C — MySQL down (mode dégradé) :
     $ docker restart gmod-mysql
     Note : l'addon continue de fonctionner sans DB

3. VÉRIFICATION
   Tester la fonctionnalité concernée en jeu
   Note : les clients doivent se reconnecter (cache Lua)
```

#### Procédure P3 — Bug mineur

```
1. DIAGNOSTIC
   Consulter les logs serveur et applicatifs
   $ construction_logs 20  # En console serveur (superadmin)

2. RÉSOLUTION
   Corriger dans le code source (bind mount → effet au restart)
   $ docker restart gmod-server

3. SUIVI
   Documenter dans le journal de développement
   $ git add -A && git commit -m "fix: description" && git push
```

---

## 2. Réduction des interruptions de service (C7.2)

### Mesures préventives en place

| Mesure | Interruption évitée | Temps gagné |
|--------|---------------------|-------------|
| **Healthcheck MySQL** | GMod démarre avant MySQL ready | ~30s par démarrage |
| **`depends_on: service_healthy`** | Erreurs de connexion DB au boot | ~1 min par démarrage |
| **Mode dégradé sans MySQL** | Panne MySQL → addon inaccessible | 100% du downtime MySQL |
| **Snapshots Docker** | Rebuild complet après corruption | ~15 min par incident |
| **Bind mounts** | Rebuild image pour chaque modif | ~10 min par déploiement |
| **Rate limiting** | Crash serveur par spam | Prévient les P1 |
| **Validation serveur net messages** | Exploit → crash ou corruption | Prévient les P1/P2 |
| **Git versioning** | Perte de code / rollback impossible | Temps de réécriture |

### Métriques d'interruption du projet

| Période | Incidents P1 | Incidents P2 | Temps total d'interruption | MTTR moyen |
|---------|-------------|-------------|---------------------------|------------|
| Étape 1-3 (infra) | 2 | 3 | ~4h | ~45 min |
| Étape 4-5 (addon) | 0 | 4 | ~6h | ~90 min |
| Étape 6-7 (véhicules) | 0 | 3 | ~4.5h | ~90 min |
| **Post-optimisation** | 0 | 1 | ~15 min | ~15 min |

**Amélioration constatée** : le MTTR est passé de ~90 min à ~15 min grâce à :
- La documentation des procédures de résolution
- Les snapshots Docker permettant un rollback instantané
- Le mode dégradé MySQL éliminant un SPOF
- L'expérience accumulée sur les erreurs fréquentes

### Améliorations proposées pour réduire davantage les interruptions

| Amélioration | Impact sur MTTR | Impact sur disponibilité | Priorité |
|-------------|-----------------|-------------------------|----------|
| `restart: unless-stopped` | MTTR → ~30s (auto) | +3% disponibilité | 🔴 Haute |
| Alerting Discord/Telegram | Détection → < 1 min | Réduit temps de réaction | 🔴 Haute |
| Monitoring UptimeRobot | Détection externe | Détecte les pannes réseau | 🟠 Moyenne |
| Pipeline CI/CD (tests avant deploy) | Prévient les P2 | Élimine les bugs en prod | 🟠 Moyenne |
| Réplication MySQL | Élimine SPOF MySQL | +1% disponibilité | 🟡 Basse |

---

## 3. Incidents rencontrés — Retour d'expérience

### Tableau des incidents réels

| # | Incident | P | Cause racine | Résolution | Temps | Leçon |
|---|----------|---|-------------|------------|-------|-------|
| 1 | MySQLOO ne charge pas | P2 | Binaire 32-bit au lieu de 64-bit | Remplacement par `gmsv_mysqloo_linux64.dll` | 2h | Toujours vérifier l'architecture |
| 2 | Workshop re-téléchargé à chaque restart | P3 | `docker restart` ne restaure pas le FS | `docker commit` après premier démarrage | 1h | Comprendre le cycle de vie Docker |
| 3 | Variables d'env ignorées | P3 | `docker restart` ≠ `docker compose up -d` | Utiliser systématiquement `compose up -d` | 30min | Docker Compose = seule commande fiable |
| 4 | Viewmodel SWEP invisible | P2 | `resource.AddFile` ne fonctionne pas en bind mount | Publication Workshop + `resource.AddWorkshop` | 3h | Distribution GMod ≠ distribution fichiers classique |
| 5 | `SWEP:Reload()` jamais appelé serveur | P2 | `ClipSize = -1` → moteur Source skip le Reload | Net message client → serveur | 2h | Le moteur Source a des comportements non documentés |
| 6 | Ghost physics après `SetParent()` | P2 | Physique non désactivée après parenting | `phys:EnableMotion(false)` | 1h | Toujours désactiver la physique explicitement |
| 7 | Caisse téléportée après `SetParent(nil)` | P2 | Source restaure la position pré-parenting | `timer.Simple(0)` + `SetPos(dropPos)` | 1.5h | `SetParent(nil)` restaure la position originale |
| 8 | Petite caisse ne matérialise pas | P2 | Condition vérifie uniquement `construction_crate` | Ajout de `construction_crate_small` | 15min | Tester tous les variants |
| 9 | `.sw.vtx` bloque gmad | P3 | Extension non supportée par whitelist gmad | Suppression + `.gitignore` | 10min | Vérifier les contraintes de l'outil |
| 10 | Addons Workshop pas dans Tools menu | P3 | `workshop_download_item` ne monte pas les GMA | Extraction manuelle + bind mount | 1h | Docker a ses propres contraintes de FS |

### Template de post-mortem

Pour chaque incident P1/P2, un post-mortem est documenté :

```markdown
## Post-mortem — [Titre de l'incident]

**Date** : YYYY-MM-DD
**Durée** : X min
**Gravité** : P1/P2
**Impact** : Description de l'impact sur les joueurs/le service

### Timeline
- HH:MM — Détection (comment)
- HH:MM — Début diagnostic
- HH:MM — Cause identifiée
- HH:MM — Fix appliqué
- HH:MM — Service restauré

### Cause racine
Description technique de la cause

### Résolution
Actions prises pour résoudre

### Actions préventives
- [ ] Action 1 pour éviter la récurrence
- [ ] Action 2
```
