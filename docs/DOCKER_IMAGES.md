# Gestion des Images Docker - Projet Fil Rouge

## Philosophie
Toujours maintenir une image Docker stable avec les addons pré-chargés.
Évite de re-télécharger ~8GB de workshop à chaque restart.

## Images disponibles

| Tag | Description | Date |
|-----|------------|------|
| `projetfilrouge/gmod-server:jour1-stable` | Base GMod + DarkRP + 101 addons workshop | 2026-02-07 |

## Commandes utiles

### Sauvegarder l'état actuel
```bash
docker commit gmod-server projetfilrouge/gmod-server:TAG
```

### Lister les images
```bash
docker images | grep projetfilrouge
```

### Restaurer depuis une image stable
Modifier `docker-compose.yml` :
```yaml
image: projetfilrouge/gmod-server:jour1-stable
```
au lieu de :
```yaml
image: ceifa/garrysmod:latest
```

### Exporter/Importer une image (backup)
```bash
# Export
docker save projetfilrouge/gmod-server:jour1-stable | gzip > backups/gmod-jour1-stable.tar.gz

# Import
docker load < backups/gmod-jour1-stable.tar.gz
```

## Workflow
1. Faire des changements (addons, config, etc.)
2. Tester que tout fonctionne
3. `docker commit gmod-server projetfilrouge/gmod-server:TAG`
4. Documenter le nouveau tag ici
5. En cas de pépin : changer l'image dans docker-compose et restart
