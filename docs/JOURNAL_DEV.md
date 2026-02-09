# Journal de Développement

## Jour 1 - Infrastructure Docker + DarkRP
- Mise en place Docker Compose (ceifa/garrysmod + MySQL 8.0)
- Installation DarkRP, configuration serveur
- Workshop collection (101 addons)
- Addon `darkrpmodification` : jobs, catégories, settings
- Image Docker sauvegardée : `jour1-stable`, `jour1-final`

## Jour 2 - Base de données MySQL
- Installation MySQLOO 9.7.6 (module binaire Linux 64-bit)
- Configuration partagée `sh_config.lua`
- Module `sv_database.lua` : connexion auto-reconnect, CRUD blueprints, permissions, logging
- Schéma BDD : 3 tables (blueprints, blueprint_permissions, blueprint_logs)
- Prepared statements pour la sécurité SQL
- Image Docker : `jour2-stable`

## Jour 3-5 - Système de sélection + Blueprints + Interface
- SWEP `weapon_construction` : arme dédiée au job Constructeur
  * LMB: sélectionner/désélectionner un prop
  * RMB: sélection par zone (rayon configurable)
  * Shift+RMB: ouvrir le menu blueprints
  * Reload: vider la sélection
- Sérialisation custom : Vectors/Angles → JSON → compression → base64
- Menu Derma : 3 onglets (Mes Blueprints, Sauvegarder, Infos)
- Vérification ownership CPPI (prop protection compatible)

## Jour 6-7 - Permissions, sécurité, partage
- Partage de blueprints entre joueurs (view/use/edit)
- Rate limiting global (60 req/min)
- Restriction par job (CanTool hook)
- Commandes admin : `construction_logs`, `construction_stats`

## Jour 8-10 - Système de construction RP (v2.0)
### Refactoring majeur : système de ghosts + caisses de matériaux

**Nouveau flow de jeu :**
1. Le Constructeur sélectionne des props et sauvegarde un blueprint
2. Il charge le blueprint → des **props fantômes** (transparents, bleutés) apparaissent
3. Il achète une **Caisse de Matériaux** (F4 → Entities → Construction, $1)
4. N'importe quel joueur active la caisse (E) puis vise un fantôme (E) → le prop se matérialise
5. Le prop matérialisé appartient au joueur qui l'a posé

**Entités créées :**
- `construction_ghost` : prop fantôme (RENDERMODE_TRANSALPHA, non-solide)
- `construction_crate` : caisse de matériaux (30 uses, compteur 3D2D)

**Sécurité :**
- Seuls les `prop_physics` autorisés (blacklist money printers, shipments, etc.)
- Ownership CPPI : impossible de sélectionner les props des autres
- Rate limiting sur toutes les actions
- Validation serveur de chaque matérialisation

**Optimisations :**
- Pas de halo (trop lourd) → simple changement de couleur
- HUD ghost : cache 200ms
- Batch spawning des ghosts (5/tick)
- Undo support pour fantômes et props matérialisés

**Bugs corrigés :**
- `GetMaterials()` conflit avec méthode native Entity → renommé
- `base_gltransfer` n'existe pas → `base_anim`
- KeyPress/Think ne détectent pas IN_USE → client Think + input.IsKeyDown(KEY_E) + net message
- NWEntity sync pour ActiveCrate (client ne connaissait pas l'état serveur)
- Props ghostés au chargement → frozen par défaut
