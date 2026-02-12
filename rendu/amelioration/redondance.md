# 🔄 Redondance — Disponibilité et résilience

## Objectif

Assurer la **continuité de service** du serveur de jeu et la **protection des données** en cas de panne matérielle, logicielle ou humaine.

---

## État actuel

### Redondance des données

| Donnée | Stratégie de redondance | Niveau |
|--------|------------------------|--------|
| Code source addon | Git + GitHub (distant) | ✅ Élevé |
| Configuration DarkRP | Git + GitHub | ✅ Élevé |
| docker-compose.yml | Git + GitHub | ✅ Élevé |
| Images Docker | Snapshots locaux (`docker commit`) | ⚠️ Moyen |
| Base MySQL | Volume Docker local (`./mysql-data/`) | ⚠️ Moyen |
| Workshop Collection (~8 Go) | Commitée dans l'image Docker | ✅ Élevé |
| Blueprints joueurs | Stockage local côté client | ℹ️ Hors périmètre serveur |

### Points forts actuels

- **Git comme source de vérité** : tout le code, la configuration et la documentation sont versionnés. En cas de perte du VPS, un `git clone` + `docker compose up -d` reconstruit l'environnement complet.
- **Images Docker commitées** : après chaque étape stable, l'état du container est sauvegardé (`docker commit`). Cela évite de re-télécharger ~8 Go de Workshop à chaque rebuild et permet un rollback rapide (voir [DOCKER_IMAGES.md](../../docs/DOCKER_IMAGES.md)).
- **Volume nommé** (`gmod-server-data`) : les données persistantes du serveur (cache, maps) survivent aux redémarrages du container.
- **Séparation bind mount / image** : le code addon est en bind mount (modifiable sans rebuild), tandis que le contenu lourd (Workshop) est dans l'image (stable, pas de re-téléchargement).

### Points à améliorer

- **Images Docker uniquement locales** : si le VPS tombe, les images sont perdues. Pas de push vers un registry distant.
- **MySQL sans réplication** : une seule instance, pas de slave/replica.
- **Pas de backup automatisé** : les sauvegardes d'images et de base de données sont manuelles.

---

## Améliorations réalisées

### 1. Stratégie de snapshots Docker

Au cours du projet, une convention de nommage sémantique a été mise en place pour les images Docker :

```
projetfilrouge/gmod-server:v{major}.{minor}-{description}
```

Chaque étape du développement correspond à un snapshot :

| Image | Contenu sauvegardé |
|-------|--------------------|
| `v1.0-base` | GMod + DarkRP + 101 addons Workshop |
| `v1.1-mysql` | + MySQLOO 64-bit |
| `v2-stable` | + Addon v2.0 (ghosts + caisses) |
| `v2.1-stable` | + Import AD2, UI refonte |
| `v2.2-vehicles` | + Véhicules simfphys |

Cela permet un **rollback immédiat** en changeant simplement le tag dans `docker-compose.yml`.

### 2. Blueprints côté client

La décision architecturale de stocker les blueprints **localement sur le PC du joueur** (dans `data/construction_blueprints/`) plutôt que sur le serveur a un impact direct sur la redondance :

- **Avantage** : aucune donnée joueur à sauvegarder côté serveur, pas de risque de perte massive en cas de panne serveur.
- **Inconvénient** : le joueur est responsable de ses propres sauvegardes. S'il perd son PC, il perd ses blueprints.

Ce choix a été fait consciemment pour simplifier l'infrastructure et réduire la surface de risque côté serveur.

### 3. Healthcheck MySQL

Le container MySQL intègre un **healthcheck** natif :

```yaml
healthcheck:
  test: mysqladmin ping -h localhost
  interval: 10s
  timeout: 5s
  retries: 3
```

Le serveur GMod (`depends_on: mysql: condition: service_healthy`) ne démarre que lorsque MySQL est prêt. Cela évite les erreurs de connexion au démarrage.

---

## Perspectives d'évolution

### Court terme

- **Backup automatisé** : script cron pour exporter les images Docker et les dumps MySQL vers un stockage distant (voir [Plan de sauvegarde](../backup/))
- **Push des images vers un registry** : Docker Hub ou registry privé pour avoir les snapshots hors du VPS

### Moyen terme

- **Réplication MySQL** : ajout d'un slave MySQL en lecture seule (Docker Compose multi-service)
- **Stockage distribué des blueprints** : système de partage serveur (tables `shared_blueprints` et `blueprint_permissions` déjà prévues dans le schéma SQL)

### Long terme

- **Infrastructure multi-nœuds** : déploiement sur plusieurs VPS avec load balancing
- **Sauvegarde géographiquement distribuée** : backups sur un second datacenter
