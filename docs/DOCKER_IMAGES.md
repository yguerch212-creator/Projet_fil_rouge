# 🐳 Gestion des Images Docker — Projet Fil Rouge

## Philosophie

Le serveur Garry's Mod télécharge ~8 Go de contenu Workshop au premier démarrage (~101 addons). Pour éviter de re-télécharger à chaque rebuild, on **sauvegarde l'état du container** via `docker commit` après chaque étape stable.

Les images Docker servent de **snapshots** du serveur à des moments clés du développement. En cas de problème, on peut revenir à n'importe quel état antérieur en changeant le tag dans `docker-compose.yml`.

### Ce que l'image contient vs ce qui est monté

| Élément | Stockage | Raison |
|---------|----------|--------|
| Serveur GMod + SteamCMD | **Image** (commitée) | Lourd (~5 Go), ne change pas |
| Workshop Collection (101 addons) | **Image** (commitée) | ~8 Go, évite le re-téléchargement |
| Addon RP Construction System | **Bind mount** (`./addons/`) | Modifié fréquemment en dev |
| DarkRP Modification | **Bind mount** (`./addons/`) | Config jobs, entities |
| MySQLOO binaire | **Bind mount** (`./lua-bin/`) | Module externe |
| server.cfg | **Bind mount** (`./server-config/`) | Configuration serveur |
| Données de jeu persistantes | **Volume nommé** (`gmod-server-data`) | Sauvegardes, maps, cache |

> Les bind mounts sont **prioritaires** sur le contenu de l'image. L'addon dans `docker/addons/rp_construction_system/` est toujours la version à jour, même si l'image commitée contient une ancienne version.

---

## Images disponibles

### Images stables (production)

| Tag | Description | Étape | Taille |
|-----|------------|-------|--------|
| `v1.0-base` | GMod + DarkRP + 101 addons Workshop téléchargés | Étape 1 | ~5 Go |
| `v1.0-final` | Base finalisée, structure validée | Étape 1 | ~5 Go |
| `v1.1-mysql` | + MySQLOO 64-bit installé + schéma DB créé | Étape 2 | ~5 Go |
| `v2-stable` | Refonte v2.0 : SWEP + ghost entities + caisses de matériaux | Étape 7 | ~5 Go |
| `v2.1-stable` | + Sous-dossiers, import AD2, UI dark theme, petite caisse | Étape 8-9 | ~5 Go |
| `v2.2-vehicles` | + Véhicules simfphys, offsets calibrés, viewmodel Fortnite | Étape 10-11 | ~6.5 Go |

### Images intermédiaires (debug/dev)

| Tag | Description |
|-----|------------|
| `v2-placement` | Dev : tests du système de placement |
| `v2-working` | Dev : version de travail avant stabilisation |

### Tags hérités (ancienne convention)

Les tags suivants utilisent l'ancienne convention `jourX-stable` et correspondent aux images sémantiques :

| Ancien tag | Équivalent | Statut |
|------------|-----------|--------|
| `jour1-stable` | `v1.0-base` | Peut être supprimé |
| `jour1-final` | `v1.0-final` | Peut être supprimé |
| `jour2-stable` | `v1.1-mysql` | ⚠️ Actuellement utilisée par le container |
| `jour7-stable` | `v2-stable` | Peut être supprimé |

> **Note** : Le container tourne actuellement sur `jour2-stable` (= `v1.1-mysql`). Le contenu récent (addon v2.2, véhicules, Workshop) est monté via bind mounts et n'a pas besoin d'être dans l'image.

---

## Configuration actuelle

### docker-compose.yml (extrait)

```yaml
services:
  gmod:
    image: projetfilrouge/gmod-server:jour2-stable
    container_name: gmod-server
    ports: ["27015:27015/udp", "27015:27015/tcp"]
    mem_limit: 3G
    environment:
      - GAMEMODE=darkrp
      - MAP=falaise_lbrp_v1
      - ARGS=+host_workshop_collection 2270926906 +workshop_download_item 4000 3664157203 +workshop_download_item 4000 773402917 +workshop_download_item 4000 104576786 +workshop_download_item 4000 1491950332
    volumes:
      - gmod-server-data:/home/gmod/server/garrysmod
      - ./addons:/home/gmod/server/garrysmod/addons
      - ./lua-bin:/home/gmod/server/garrysmod/lua/bin
      - ./server-config/server.cfg:/home/gmod/server/garrysmod/cfg/server.cfg
```

### Addons Workshop forcés

| ID | Addon | Raison |
|----|-------|--------|
| `2270926906` | Collection serveur | 101 addons (maps, modèles, content packs) |
| `3664157203` | RP Construction System | Notre addon (viewmodel Fortnite Builder) |
| `773402917` | Advanced Duplicator 2 | Outil de duplication |
| `104576786` | Standing Pose Tool | Pose ragdolls (screenshots) |
| `1491950332` | Bodygroup Wardrobe | Changement bodygroups |

---

## Commandes

### Sauvegarder l'état actuel

```bash
# Après une étape stable
docker commit gmod-server projetfilrouge/gmod-server:TAG

# Exemple
docker commit gmod-server projetfilrouge/gmod-server:v2.3-workshop
```

### Lister les images

```bash
docker images | grep projetfilrouge
```

### Restaurer depuis une image stable

Modifier le tag dans `docker-compose.yml` puis :

```bash
docker compose up -d
```

> **Important** : Utiliser `docker compose up -d` (pas `docker restart`) pour appliquer les changements de variables d'environnement ou d'image.

### Exporter / Importer (backup)

```bash
# Export (compressé)
docker save projetfilrouge/gmod-server:v2.2-vehicles | gzip > backups/gmod-v2.2-vehicles.tar.gz

# Import
docker load < backups/gmod-v2.2-vehicles.tar.gz
```

### Nettoyage des anciennes images

```bash
# Voir l'espace occupé
docker system df

# Supprimer une image spécifique
docker rmi projetfilrouge/gmod-server:jour1-stable

# Supprimer toutes les images non utilisées
docker image prune -a
```

> ⚠️ Ne pas supprimer l'image actuellement référencée dans `docker-compose.yml` ni celle utilisée par le container en cours d'exécution.

---

## Workflow

1. Développer et tester les changements (via bind mounts, pas besoin de rebuild)
2. Quand une étape est stable et validée :
   ```bash
   docker commit gmod-server projetfilrouge/gmod-server:vX.Y-description
   ```
3. Documenter le nouveau tag dans ce fichier
4. En cas de problème : changer l'image dans `docker-compose.yml` → `docker compose up -d`

### Quand commiter une nouvelle image ?

- ✅ Après installation d'un nouveau module dans le container (pas en bind mount)
- ✅ Après téléchargement de nouveaux addons Workshop
- ✅ Avant une modification risquée
- ❌ Pas besoin pour les changements d'addon (bind mount)
- ❌ Pas besoin pour les changements de config DarkRP (bind mount)
