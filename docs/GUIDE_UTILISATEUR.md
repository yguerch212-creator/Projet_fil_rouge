# 🎮 Guide Utilisateur — RP Construction System v2.2

> 🔗 **[Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3664157203)** — Addon publié (ID 3664157203)

---

## 📋 Table des matières

- [Prérequis](#prérequis)
- [Le SWEP Construction](#le-swep-construction)
- [Blueprints](#blueprints)
- [Construction collaborative](#construction-collaborative)
- [Transport en véhicule](#transport-en-véhicule)
- [Interface (Menu)](#interface-menu)
- [Raccourcis récapitulatifs](#raccourcis-récapitulatifs)
- [FAQ](#faq)

---

## Prérequis

- Être connecté à un serveur GMod DarkRP avec l'addon installé
- Être au **job autorisé** (configuré par l'admin du serveur) pour recevoir le SWEP
- Les caisses de matériaux sont achetables au menu F4 (par les jobs autorisés ou tout le monde, selon la config serveur)
- Content pack WW2 recommandé pour les modèles de caisses : [Workshop 3008026539](https://steamcommunity.com/sharedfiles/filedetails/?id=3008026539)

---

## Le SWEP Construction

Le SWEP `weapon_construction` est l'outil principal du système. Il est distribué automatiquement quand vous prenez un job autorisé.

### Contrôles

| Action | Touche | Description |
|--------|--------|-------------|
| Sélectionner un prop | **Clic gauche** | Ajoute/retire le prop visé de la sélection (halo bleu) |
| Sélection par zone | **Clic droit** | Sélectionne tous les props dans un rayon autour du point visé |
| Ouvrir le menu | **Shift + Clic droit** | Ouvre l'interface blueprints (sauvegarde, chargement, paramètres) |
| Décharger véhicule | **R** | Visez un véhicule chargé → décharge la caisse à côté |
| Vider la sélection | **R** | Sans viser de véhicule → désélectionne tous les props |

### HUD

Un panneau en bas à droite affiche en permanence :
- Le nombre de props sélectionnés / maximum autorisé
- Les raccourcis clavier disponibles

---

## Blueprints

### Sauvegarder un blueprint

1. **Sélectionnez** vos props avec le SWEP (clic gauche un par un, ou clic droit pour une zone)
2. **Ouvrez le menu** (Shift + Clic droit)
3. Allez dans l'onglet **Sauvegarder**
4. Entrez un **nom** (obligatoire) et une **description** (optionnel)
5. Choisissez un **dossier** (ou laissez à la racine)
6. Cliquez **Sauvegarder**

Les blueprints sont stockés **localement sur votre PC** dans :
```
garrysmod/data/construction_blueprints/
```

> Vos blueprints ne sont jamais envoyés au serveur de manière permanente. Ils restent sur votre machine.

### Charger un blueprint

1. Ouvrez le menu (Shift + Clic droit) → onglet **Blueprints**
2. Naviguez dans vos dossiers si nécessaire
3. Sélectionnez un blueprint dans la liste
4. Cliquez **Charger**
5. Un **panneau de placement** apparaît avec les contrôles :

| Action | Touche | Description |
|--------|--------|-------------|
| Rotation | **Molette** | Tourne le blueprint sur l'axe vertical |
| Ajuster la hauteur | **Shift + Molette** | Monte ou descend le blueprint |
| Position originale | **Checkbox** | Place le blueprint aux coordonnées exactes de sauvegarde |
| Confirmer | **Clic gauche** | Pose les fantômes holographiques à l'emplacement choisi |
| Annuler | **Clic droit** ou **Échap** | Annule le placement |

Les props apparaissent comme des **fantômes bleus translucides** (ghosts), en attente de matérialisation.

> **Annuler des ghosts déjà posés** : Appuyez sur **Z** (Undo GMod) pour supprimer le dernier groupe de fantômes posé.

### Organiser vos blueprints

- **Créez des dossiers** directement dans le menu pour organiser vos sauvegardes
- **Naviguez** avec le breadcrumb en haut du menu (cliquez sur les noms de dossiers)
- Les blueprints affichent un **badge** avec le nombre de props qu'ils contiennent

### Importer depuis AdvDupe2

Vous avez des fichiers AdvDupe2 existants ? Importez-les facilement :

1. Trouvez vos fichiers AD2 dans `garrysmod/data/advdupe2/`
2. Copiez les fichiers `.txt` dans `garrysmod/data/construction_blueprints/`
3. Ils apparaîtront dans le menu avec un badge orange **AD2**
4. **Pas besoin d'avoir AdvDupe2 installé** — le décodeur est embarqué dans l'addon

---

## Construction collaborative

### Le principe

C'est un **travail d'équipe** :

1. Le **Constructeur** (job avec le SWEP) sélectionne des props, sauvegarde un blueprint, et le place sur la map → des fantômes holographiques bleus apparaissent
2. **N'importe quel joueur** (pas seulement le Constructeur) peut acheter une caisse de matériaux et matérialiser les fantômes
3. Chaque fantôme matérialisé consomme 1 matériau de la caisse

### Étapes de la construction

**Côté Constructeur :**
1. Sélectionnez les props à reproduire (LMB / RMB)
2. Sauvegardez en blueprint (Shift+RMB → Sauvegarder)
3. Chargez le blueprint (Shift+RMB → Blueprints → Charger)
4. Placez les fantômes à l'emplacement voulu (molette pour tourner, LMB pour confirmer)

**Côté ouvrier (tout joueur) :**
1. **Acheter une caisse** : Menu F4 → Entities → Construction
2. **Activer la caisse** : Approchez-vous et appuyez **E**
   - Message : *"Caisse activée ! (50 matériaux) - Visez un fantôme + E"*
3. **Matérialiser** : Approchez un fantôme bleu, visez-le et appuyez **E**
   - Le fantôme se transforme en vrai prop solide
   - 1 matériau consommé par prop
4. La caisse **disparaît automatiquement** quand elle est vide

### Types de caisses

| Type | Matériaux | Transportable | Usage |
|------|-----------|---------------|-------|
| **Grosse caisse** | 50 | ✅ En véhicule simfphys | Gros chantiers, logistique longue distance |
| **Petite caisse** | 15 | ❌ Sur place uniquement | Petits travaux, réparations rapides |

> Les deux types de caisses peuvent matérialiser les fantômes de la même manière.

---

## Transport en véhicule

Les **grosses caisses** peuvent être chargées dans des véhicules simfphys pour le transport logistique jusqu'au chantier. Maximum **2 caisses par véhicule** (décalées gauche/droite).

### Charger une caisse

1. Spawner un véhicule simfphys (Opel Blitz WW2, CCKW 6x6, etc.)
2. Posez une **grosse caisse** à proximité du véhicule (dans un rayon d'environ 200 unités)
3. Équipez le **SWEP Construction**
4. **Visez le véhicule** et appuyez **R**
5. La caisse se charge automatiquement à l'arrière du véhicule
6. Vous pouvez charger une **2ème caisse** de la même manière

### Décharger une caisse

1. Équipez le **SWEP Construction**
2. **Visez le véhicule** chargé
3. Appuyez **R**
4. La caisse apparaît à côté du véhicule, prête à l'emploi

### Véhicules compatibles

| Type | Exemples | Support |
|------|----------|---------|
| **simfphys** | Opel Blitz WW2, CCKW 6x6, tout simfphys | ✅ Principal — offsets calibrés par modèle |
| **LVS** | Véhicules `lvs_*` | ✅ Basique — offset calculé automatiquement |
| **Source natifs** | Jeep, Airboat | ✅ Basique — offset par défaut |

---

## Interface (Menu)

Ouvrez le menu avec **Shift + Clic droit** (SWEP en main).

### Onglet Blueprints
- **Liste** de vos blueprints et dossiers sauvegardés
- **Breadcrumb** de navigation en haut (cliquez pour remonter)
- **Badge orange AD2** pour les fichiers importés depuis AdvDupe2
- **Badge** avec le nombre de props par blueprint
- **Boutons** : Charger, Supprimer, Créer dossier

### Onglet Sauvegarder
- **Nom** (obligatoire, 50 caractères max)
- **Description** (optionnel, 200 caractères max)
- **Sélecteur de dossier** de destination
- **Compteur** de props actuellement sélectionnés
- **Bouton Sauvegarder**

### Onglet Paramètres
- **Slider rayon de sélection** : ajustez le rayon du clic droit (50 à 1000 unités)
- Préférences d'affichage

---

## Raccourcis récapitulatifs

### SWEP en main

| Touche | Action |
|--------|--------|
| **Clic gauche** | Sélectionner / désélectionner un prop |
| **Clic droit** | Sélection par zone (rayon configurable) |
| **Shift + Clic droit** | Ouvrir le menu blueprints |
| **R** (vise véhicule) | Charger ou décharger une caisse |
| **R** (vise rien) | Vider toute la sélection |

### Mode placement (après chargement d'un blueprint)

| Touche | Action |
|--------|--------|
| **Molette** | Rotation du blueprint |
| **Shift + Molette** | Ajuster la hauteur |
| **Clic gauche** | Confirmer le placement → spawn des fantômes |
| **Clic droit / Échap** | Annuler le placement |

### Interaction caisses et fantômes

| Touche | Contexte | Action |
|--------|----------|--------|
| **E** | Près d'une caisse | Activer la caisse (la sélectionner comme source de matériaux) |
| **E** | Caisse active + vise un fantôme | Matérialiser le fantôme en prop réel |
| **Z** | Après avoir posé des fantômes | Annuler (Undo) le dernier groupe de ghosts |

---

## FAQ

**Q: Je ne vois pas le SWEP dans mon inventaire**
R: Vous devez être au job autorisé par l'admin du serveur. Le SWEP est distribué automatiquement au changement de job. Si vous ne savez pas quel job, demandez à l'admin.

**Q: Mon personnage tient un C4/SLAM au lieu d'un plan d'architecte**
R: Le viewmodel custom nécessite l'addon Workshop. Abonnez-vous à l'addon sur le [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3664157203) et reconnectez-vous.

**Q: Mes props ne se sélectionnent pas**
R: Seuls les `prop_physics` dont vous êtes **propriétaire** sont sélectionnables. Vous ne pouvez pas sélectionner les props des autres joueurs.

**Q: Les fantômes sont là mais je ne peux pas les matérialiser**
R: Assurez-vous d'avoir **d'abord activé une caisse** (appuyez E sur la caisse). Ensuite, visez un fantôme bleu et appuyez E. Vérifiez aussi que la caisse a encore des matériaux.

**Q: La petite caisse ne matérialise pas les fantômes**
R: Ce bug a été corrigé. Assurez-vous que votre serveur utilise la dernière version de l'addon.

**Q: La caisse ne se charge pas dans le véhicule**
R: Vérifiez que : (1) c'est une **grosse caisse**, (2) elle est posée **à proximité** du véhicule, (3) vous avez le **SWEP en main**, (4) vous **visez le véhicule** et appuyez **R**. Les petites caisses ne sont pas transportables.

**Q: Où sont stockés mes blueprints ?**
R: Localement sur votre PC dans `garrysmod/data/construction_blueprints/`. Ils ne sont jamais envoyés au serveur de manière permanente.

**Q: Comment importer mes fichiers AdvDupe2 ?**
R: Copiez vos fichiers `.txt` depuis `garrysmod/data/advdupe2/` dans `garrysmod/data/construction_blueprints/`. Ils seront détectés automatiquement avec un badge orange AD2.

**Q: Les caisses sont invisibles**
R: Installez le [content pack WW2](https://steamcommunity.com/sharedfiles/filedetails/?id=3008026539) qui contient les modèles des caisses.

**Q: Combien de caisses max dans un véhicule ?**
R: 2 caisses maximum par véhicule, décalées gauche et droite à l'arrière.

**Q: Tout le monde peut matérialiser les fantômes ?**
R: Oui ! N'importe quel joueur possédant une caisse de matériaux activée peut matérialiser les fantômes, pas seulement le Constructeur. C'est le principe de la construction collaborative.
