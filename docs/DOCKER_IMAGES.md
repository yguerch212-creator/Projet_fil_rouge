# Gestion des Images Docker - Projet Fil Rouge

## Philosophie
Toujours maintenir une image Docker stable avec les addons pré-chargés.
Évite de re-télécharger ~8GB de workshop à chaque restart.

## Images disponibles

| Tag | Description | Étape |
|-----|------------|-------|
| `projetfilrouge/gmod-server:v1.0-base` | Base GMod + DarkRP + 101 addons workshop | Étape 1 |
| `projetfilrouge/gmod-server:v1.0-final` | Base finalisée | Étape 1 |
| `projetfilrouge/gmod-server:v1.1-mysql` | + MySQLOO 64-bit + schéma DB | Étape 2 |
| `projetfilrouge/gmod-server:v2-stable` | Refonte SWEP + ghosts + caisses | Étape 7 |
| `projetfilrouge/gmod-server:v2.1-stable` | + Dossiers, AD2 import, UI refonte | Étape 8-9 |
| `projetfilrouge/gmod-server:v2.2-vehicles` | + Véhicules simfphys, viewmodel Fortnite | Étape 10-11 |

> **Note** : Les tags locaux peuvent encore porter les anciens noms (`jour1-stable`, etc.). Les noms sémantiques ci-dessus sont la convention à suivre.

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
image: projetfilrouge/gmod-server:v2.2-vehicles
```

### Exporter/Importer une image (backup)
```bash
# Export
docker save projetfilrouge/gmod-server:v2.2-vehicles | gzip > backups/gmod-v2.2-vehicles.tar.gz

# Import
docker load < backups/gmod-v2.2-vehicles.tar.gz
```

## Workflow
1. Faire des changements (addons, config, etc.)
2. Tester que tout fonctionne
3. `docker commit gmod-server projetfilrouge/gmod-server:TAG`
4. Documenter le nouveau tag ici
5. En cas de pépin : changer l'image dans docker-compose et restart
