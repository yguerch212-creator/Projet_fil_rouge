# Guide Utilisateur - Système de Construction RP

## Prérequis

- Être connecté au serveur GMod DarkRP
- Avoir le Tool Gun dans l'inventaire

## Comment utiliser le système

### 1. Sélectionner des props

1. Équipe le **Tool Gun** (menu Q → Weapons)
2. Dans le menu de droite, ouvre la catégorie **"Construction RP"**
3. Sélectionne l'outil **"Blueprint Select"**
4. Pointe un prop et fais un **clic gauche** pour le sélectionner (halo bleu)
5. Pour sélectionner plusieurs props d'un coup, fais un **clic droit** (sélection par zone)
6. Pour vider ta sélection, appuie sur **R** (Reload)

### 2. Sauvegarder un blueprint

1. Après avoir sélectionné tes props, tape `construction_menu` en console ou utilise le bouton dans le panel du tool
2. Va dans l'onglet **"Sauvegarder"**
3. Entre un **nom** pour ton blueprint
4. Optionnel : ajoute une **description**
5. Clique sur **"SAUVEGARDER LE BLUEPRINT"**
6. Le coût de sauvegarde est de **$100** (monnaie DarkRP)

### 3. Charger un blueprint

1. Ouvre le menu (`construction_menu`)
2. Va dans l'onglet **"Mes Blueprints"**
3. Sélectionne un blueprint dans la liste
4. Clique sur **"Charger ($50)"**
5. Le blueprint sera spawné devant toi
6. Les props apparaissent progressivement (anti-lag)

### 4. Partager un blueprint

Le partage se fait via le système de permissions :
- **view** : le joueur peut voir le blueprint
- **use** : le joueur peut charger le blueprint
- **edit** : le joueur peut modifier le blueprint

Coût de partage : **$25**

### 5. Supprimer un blueprint

1. Ouvre le menu
2. Sélectionne le blueprint
3. Clique sur **"Supprimer"**
4. Confirme la suppression

## Limites

| Paramètre | Valeur |
|-----------|--------|
| Props max par blueprint | 50 |
| Blueprints max par joueur | 20 |
| Cooldown sauvegarde | 10 secondes |
| Cooldown chargement | 15 secondes |
| Rayon de sélection max | 500 unités |

## Raccourcis

| Action | Contrôle |
|--------|----------|
| Sélectionner/Désélectionner un prop | Clic gauche |
| Sélectionner par zone | Clic droit |
| Vider la sélection | R (Reload) |
| Ouvrir le menu | `construction_menu` en console |

## Commandes admin

| Commande | Description |
|----------|-------------|
| `construction_logs [n]` | Afficher les n derniers logs (superadmin) |
| `construction_stats` | Afficher les statistiques du système (superadmin) |

## FAQ

**Q: Mes props ne se sélectionnent pas**
R: Vérifie que tu es bien le propriétaire des props. Le système utilise CPPI pour vérifier l'ownership.

**Q: Le blueprint ne charge pas correctement**
R: Les props sont spawés par batch de 5 pour éviter les lags. Attends quelques secondes.

**Q: Je ne vois pas l'outil dans le Tool Gun**
R: Cherche dans la catégorie "Construction RP" dans le menu du Tool Gun.
