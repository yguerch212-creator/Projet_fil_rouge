# 🎮 Guide Utilisateur — RP Construction System v2.2

## Prérequis

- Être connecté à un serveur GMod DarkRP avec l'addon installé
- Être au job **Constructeur** (ou un job autorisé) pour utiliser le SWEP
- Les caisses de matériaux sont achetables au menu F4

---

## Le SWEP Construction

Le SWEP `weapon_construction` est l'outil principal. Il est distribué automatiquement quand vous prenez le job Constructeur.

### Contrôles

| Action | Touche | Description |
|--------|--------|-------------|
| Sélectionner un prop | **Clic gauche** | Ajoute/retire le prop visé de la sélection (halo bleu) |
| Sélection par zone | **Clic droit** | Sélectionne tous les props dans un rayon autour du point visé |
| Ouvrir le menu | **Shift + Clic droit** | Ouvre l'interface blueprints |
| Décharger véhicule / Clear | **R** | Si vous visez un véhicule : décharge la caisse. Sinon : vide la sélection |

### HUD

Un petit panneau en bas à droite affiche :
- Le nombre de props sélectionnés / maximum
- Les raccourcis clavier

---

## Blueprints

### Sauvegarder

1. Sélectionnez vos props avec le SWEP (clic gauche ou droit)
2. Ouvrez le menu (**Shift + Clic droit**)
3. Allez dans l'onglet **Sauvegarder**
4. Entrez un nom (et optionnellement une description)
5. Choisissez un dossier (ou laissez à la racine)
6. Cliquez **Sauvegarder**

Les blueprints sont stockés **localement sur votre PC** dans :
```
garrysmod/data/construction_blueprints/
```

### Charger

1. Ouvrez le menu → onglet **Blueprints**
2. Naviguez dans vos dossiers
3. Sélectionnez un blueprint
4. Cliquez **Charger**
5. Un panneau de placement apparaît :
   - **Molette** : rotation
   - **Shift + Molette** : ajuster la hauteur
   - **Clic gauche** : confirmer le placement
   - **Clic droit** ou **Échap** : annuler

Les props apparaissent comme des **fantômes bleus translucides** (ghosts).

### Organiser

- Créez des dossiers pour organiser vos blueprints
- Naviguez avec le breadcrumb en haut du menu
- Les fichiers AdvDupe2 (`.txt`) copiés dans le dossier sont détectés automatiquement (badge orange **AD2**)

### Importer depuis AdvDupe2

1. Trouvez vos fichiers AD2 dans `garrysmod/data/advdupe2/`
2. Copiez les fichiers `.txt` dans `garrysmod/data/construction_blueprints/`
3. Ils apparaîtront dans le menu avec un badge **AD2**
4. Pas besoin d'avoir AdvDupe2 installé — le décodeur est embarqué

---

## Construction collaborative

### Le principe

1. Le **Constructeur** place un blueprint → fantômes holographiques bleus
2. **N'importe quel joueur** peut matérialiser ces fantômes avec une caisse
3. C'est un travail d'équipe !

### Étapes

1. **Acheter une caisse** : Menu F4 → Entities → Construction → Caisse de Matériaux
2. **Activer la caisse** : Approchez-vous et appuyez **E** sur la caisse
   - Message : *"Caisse activée ! (50 matériaux) - Visez un fantôme + E"*
3. **Matérialiser** : Approchez un fantôme bleu et appuyez **E**
   - Le fantôme devient un vrai prop solide
   - 1 matériau consommé par fantôme matérialisé
4. La caisse disparaît quand elle est vide

### Types de caisses

| Type | Matériaux | Usage |
|------|-----------|-------|
| **Grosse caisse** | 50 | Transportable en véhicule, pour les gros chantiers |
| **Petite caisse** | 15 | Usage sur place, pour les petits travaux |

---

## Transport en véhicule

Les grosses caisses (et les petites) peuvent être chargées dans des véhicules simfphys pour le transport logistique.

### Charger une caisse

1. Spawner un véhicule simfphys (Opel Blitz, CCKW 6x6, etc.)
2. Spawner une caisse de matériaux à proximité
3. Avec le **physgun**, attrapez la caisse et posez-la **sur/près du véhicule**
4. Le système détecte automatiquement le parenting et :
   - Place la caisse au bon endroit dans le cargo
   - Retire les collisions
   - Le 3D2D de la caisse disparaît

### Décharger une caisse

1. Équipez le **SWEP Construction**
2. **Visez le véhicule**
3. Appuyez **R**
4. La caisse apparaît à côté du véhicule, prête à l'emploi

### Véhicules compatibles

- **simfphys** (principal) : Opel Blitz WW2, CCKW 6x6, et tout véhicule simfphys
- **LVS** : Support basique (détection automatique)
- Les offsets de placement sont calibrés par modèle de véhicule

---

## Interface (Menu)

### Onglet Blueprints
- Liste de vos blueprints et dossiers
- Breadcrumb de navigation
- Badge **AD2** pour les imports AdvDupe2
- Badge nombre de props
- Boutons : Charger, Supprimer

### Onglet Sauvegarder
- Champ nom (obligatoire)
- Champ description (optionnel)
- Sélecteur de dossier
- Compteur de props sélectionnés
- Bouton Sauvegarder

### Onglet Paramètres
- Slider rayon de sélection (50-1000 unités)
- Préférences d'affichage

---

## Raccourcis récapitulatifs

| Touche | Contexte | Action |
|--------|----------|--------|
| **LMB** | SWEP en main | Sélectionner/désélectionner un prop |
| **RMB** | SWEP en main | Sélection par zone |
| **Shift+RMB** | SWEP en main | Ouvrir le menu |
| **R** | SWEP, vise véhicule | Décharger la caisse |
| **R** | SWEP, vise rien | Vider la sélection |
| **E** | Près d'une caisse | Activer la caisse |
| **E** | Caisse active + vise ghost | Matérialiser le fantôme |
| **Molette** | Mode placement | Rotation |
| **Shift+Molette** | Mode placement | Hauteur |
| **LMB** | Mode placement | Confirmer |
| **RMB/Échap** | Mode placement | Annuler |

---

## FAQ

**Q: Je ne vois pas le SWEP dans mon inventaire**
R: Vous devez être au job Constructeur. Le SWEP est distribué automatiquement au changement de job.

**Q: Mes props ne se sélectionnent pas**
R: Seuls les `prop_physics` dont vous êtes propriétaire (CPPI) sont sélectionnables.

**Q: Les fantômes sont là mais je ne peux pas les matérialiser**
R: Vous devez d'abord activer une caisse (E sur la caisse), puis viser le fantôme et appuyer E.

**Q: La caisse ne se charge pas dans le véhicule**
R: Utilisez le physgun pour coller la caisse au véhicule. Le système détecte automatiquement le parenting.

**Q: Où sont stockés mes blueprints ?**
R: Localement dans `garrysmod/data/construction_blueprints/`. Ils ne sont jamais envoyés au serveur de manière permanente.
