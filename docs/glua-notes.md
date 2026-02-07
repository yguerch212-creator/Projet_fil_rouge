# GLua / Garry's Mod Lua - Notes de recherche

## Architecture fondamentale

### 3 Realms (États Lua séparés)
- **SERVER** : Logique serveur, physique, entités, base de données. Variable globale `SERVER == true`
- **CLIENT** : Rendu, HUD, UI (Derma/VGUI), input joueur. Variable globale `CLIENT == true`
- **MENU** : Menu principal (isolé, pas d'interaction avec server/client)

### Communication client ↔ serveur
- **net library** : Méthode principale. Limite 64KB par message.
  - Server: `util.AddNetworkString("nom")` pour précacher
  - Send: `net.Start("nom")` → `net.WriteString/Int/Entity/Table...` → `net.Send(player)` ou `net.Broadcast()`
  - Receive: `net.Receive("nom", function(len, ply) ... end)`
  - **SÉCURITÉ** : Ne jamais faire confiance au client ! Toujours valider côté serveur.

### Hooks (Événements)
- `hook.Add("EventName", "UniqueID", function(...) end)` - Écouter un événement
- `hook.Run("EventName", ...)` - Déclencher un événement custom
- `hook.Remove("EventName", "UniqueID")` - Retirer un hook
- Retourner une valeur dans un hook empêche les hooks suivants de s'exécuter
- Hooks gamemode (GM:EventName) s'exécutent APRÈS les hooks hook.Add

### Hooks importants pour notre addon
- `PlayerInitialSpawn(ply)` - Joueur rejoint (spawn initial)
- `PlayerSpawn(ply)` - Chaque spawn
- `PlayerDeath(victim, inflictor, attacker)` - Mort
- `PlayerDisconnected(ply)` - Déconnexion
- `Think()` - Chaque tick serveur
- `PlayerSpawnProp(ply, model)` - Spawn de prop (return true/false)
- `CanTool(ply, trace, tool)` - Permission d'utiliser un outil

## Structure des fichiers addon

```
addon_name/
├── addon.json           -- Métadonnées
└── lua/
    ├── autorun/         -- Chargé automatiquement (shared)
    │   ├── client/      -- Autorun client seulement
    │   └── server/      -- Autorun server seulement
    ├── entities/        -- Scripted Entities (SENTs)
    │   └── my_entity/
    │       ├── shared.lua (ou init.lua + cl_init.lua)
    ├── weapons/         -- Scripted Weapons (SWEPs)
    ├── effects/         -- Effets visuels Lua
    └── vgui/            -- Éléments UI custom
```

### AddCSLuaFile
- Serveur doit appeler `AddCSLuaFile("chemin.lua")` pour envoyer des fichiers au client
- `AddCSLuaFile()` sans arg = le fichier courant
- `include("chemin.lua")` pour charger un fichier

## Scripted Entities (SENTs)
- `ENT.Type` : "anim" (physique), "point" (logique), "brush" (trigger), "nextbot" (NPC)
- `ENT.Base` : Entité parente (souvent "base_anim")
- Fonctions clés : `Initialize()`, `Think()`, `Use()`, `OnTakeDamage()`, `Draw()`
- `self:SetModel()`, `self:PhysicsInit()`, `self:SetSolid()`

## Net Library - Pattern typique pour notre addon
```lua
-- Server
util.AddNetworkString("Construction_SaveBlueprint")
util.AddNetworkString("Construction_LoadBlueprint")

net.Receive("Construction_SaveBlueprint", function(len, ply)
    if not IsValid(ply) then return end
    if not ply:IsAdmin() then return end -- TOUJOURS vérifier
    local name = net.ReadString()
    local data = net.ReadTable()
    -- Sauvegarder en BDD...
end)

-- Client
net.Start("Construction_SaveBlueprint")
    net.WriteString(blueprintName)
    net.WriteTable(blueprintData)
net.SendToServer()
```

## Simfphys Vehicles
- Repo: github.com/Blu-x92/simfphys_base
- Système de véhicules réalistes pour GMod
- Utilise son propre système physique (pas les véhicules Source natifs)
- Entités custom basées sur `simfphys_base`
- Possibilité d'intégrer des blueprints de véhicules dans notre addon
- Workshop ID: 771487490 (base), nombreux packs de véhicules disponibles
- Hooks simfphys intéressants pour intégration future

## DarkRP

### Configuration
- **Ne JAMAIS modifier les fichiers core** → utiliser darkrpmodification addon
- darkrpmodification: https://github.com/FPtje/darkrpmodification
- Fichiers de config dans `lua/darkrp_config/settings.lua`
- Custom things dans `lua/darkrp_customthings/` (jobs, shipments, entities, vehicles)

### Activer les véhicules
- Dans settings.lua : `GM.Config.vehicles = true`
- Ou en console : `darkrp_config vehicles 1`
- Créer véhicules custom dans `lua/darkrp_customthings/vehicles.lua`

### Véhicules DarkRP
```lua
DarkRP.createVehicle({
    name = "Jeep",
    model = "models/buggy.mdl",
    price = 600,
    allowed = {TEAM_MEDIC, TEAM_GUN}
})
```

### Jobs DarkRP
```lua
TEAM_BUILDER = DarkRP.createJob("Constructeur", {
    color = Color(0, 128, 255),
    model = {"models/player/eli.mdl"},
    description = "Construis des structures pour la ville",
    weapons = {"weapon_physgun", "gmod_tool"},
    command = "builder",
    max = 3,
    salary = 65,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Civil"
})
```

## MySQLOO 9 - Documentation complète

### Installation
- Télécharger `gmsv_mysqloo_linux64.dll` dans `garrysmod/lua/bin/`
- Repo: github.com/FredyH/MySQLOO

### Connexion
```lua
require("mysqloo")
local db = mysqloo.connect("host", "user", "password", "database", 3306)
db.onConnected = function() print("DB Connected!") end
db.onConnectionFailed = function(_, err) print("DB Error: " .. err) end
db:connect()
```

### Queries
```lua
local q = db:query("SELECT * FROM blueprints WHERE player_steamid = '" .. db:escape(steamid) .. "'")
q.onSuccess = function(_, data)
    for _, row in ipairs(data) do
        print(row.blueprint_name)
    end
end
q.onError = function(_, err, sql)
    print("Query error: " .. err .. " (" .. sql .. ")")
end
q:start()
```

### Prepared Queries (anti-injection SQL)
```lua
local pq = db:prepare("INSERT INTO blueprints (player_steamid, player_name, blueprint_name, blueprint_data, prop_count) VALUES(?, ?, ?, ?, ?)")
pq:setString(1, steamid)
pq:setString(2, name)
pq:setString(3, blueprintName)
pq:setString(4, util.TableToJSON(data))
pq:setNumber(5, propCount)
pq.onSuccess = function(q) print("Inserted! ID: " .. q:lastInsert()) end
pq.onError = function(_, err) print("Error: " .. err) end
pq:start()
```

### Transactions (atomique)
```lua
local tr = db:createTransaction()
tr:addQuery(db:query("DELETE FROM blueprints WHERE id = 5"))
tr:addQuery(db:query("INSERT INTO blueprint_logs ..."))
tr.onSuccess = function() print("Transaction OK") end
tr.onError = function(_, err) print("Transaction failed: " .. err) end
tr:start()
```

### États
- `mysqloo.DATABASE_CONNECTED` / `DATABASE_NOT_CONNECTED`
- `mysqloo.QUERY_COMPLETE` / `QUERY_RUNNING` / `QUERY_WAITING`

## Simfphys Vehicles

### Structure d'un véhicule simfphys
- Fichier Lua dans `lua/autorun/` 
- Définir `light_table` (phares, feux arrière, clignotants)
- Définir `V` (table véhicule) avec Members: Mass, WheelRadius, Suspension, Engine, Gears
- `list.Set("simfphys_vehicles", "nom_unique", V)` pour enregistrer

### Paramètres clés
- `Mass` : Masse du véhicule
- `PeakTorque` : Couple moteur (vitesse des roues)
- `MaxGrip` : Adhérence (trop haut = tonneau)
- `PowerBias` : 1=propulsion, -1=traction, 0=4x4
- `Gears` : Table des rapports de vitesse
- `FuelType` : FUELTYPE_PETROL / FUELTYPE_DIESEL
- `SeatOffset` : Position du siège conducteur
- `PassengerSeats` : Table des sièges passagers

### Intégration possible avec notre addon
- Sauvegarder des "blueprints" de véhicules customisés
- Modifier les paramètres via interface Derma
- Permissions par job DarkRP

## DarkRP Configuration Complète

### Problème véhicules "disabled"
Le setting clé est `GM.Config.adminvehicles` :
- `0` = tout le monde peut spawn
- `1` = admin+
- `2` = superadmin+  
- `3` = rcon only (DÉFAUT!)

→ Il faut mettre `GM.Config.adminvehicles = 0` dans settings.lua

### Autres settings importants
- `GM.Config.vehicles = true` (activer les véhicules)
- `GM.Config.allowvehicleowning = true` (posséder un véhicule)
- `GM.Config.maxvehicles = 5` (max véhicules par joueur)
- `GM.Config.adminweapons` : 0=admins, 1=superadmins, 2=personne, 3=tout le monde
- `GM.Config.adminsents` : 0=tous, 1=admin+, 2=superadmin+, 3=rcon

### Catégories DarkRP
Les jobs custom DOIVENT avoir une catégorie existante. Créer dans `categories.lua` :
```lua
DarkRP.createCategory{
    name = "Civil",
    categorises = "jobs",
    startExpanded = true,
    color = Color(0, 128, 255, 255),
    canSee = function(ply) return true end,
    sortOrder = 100,
}
```

### darkrpmodification structure complète
```
darkrpmodification/
└── lua/
    ├── darkrp_config/
    │   ├── settings.lua      -- GM.Config.* overrides
    │   └── disabled_defaults.lua  -- disable default jobs/entities
    └── darkrp_customthings/
        ├── categories.lua    -- IMPORTANT: catégories pour jobs/entities
        ├── jobs.lua          -- Custom jobs
        ├── vehicles.lua      -- Custom vehicles
        ├── shipments.lua     -- Custom shipments
        ├── entities.lua      -- Custom entities
        ├── ammo.lua          -- Custom ammo
        ├── agendas.lua       -- Custom agendas
        ├── doorgroups.lua    -- Door groups
        └── groupchats.lua    -- Group chats
```

## DarkRP Custom Entities
```lua
DarkRP.createEntity("Blueprint Station", {
    ent = "rp_blueprint_station",     -- classe de l'entité
    model = "models/props_c17/consolebox01a.mdl",
    price = 500,
    max = 1,
    cmd = "buyblueprintstation",
    allowed = {TEAM_BUILDER},
    category = "Construction",        -- doit exister dans categories.lua
    sortOrder = 100,
})
```

## Derma/VGUI (Interface Utilisateur)
- **CLIENT SIDE ONLY** — jamais dans HUDPaint
- `DFrame` : fenêtre principale (canvas)
- `DButton` : bouton cliquable (DoClick callback)
- `DTextEntry` : champ texte (OnEnter callback)
- `DListView` : liste avec colonnes
- `DScrollPanel` : panel scrollable
- `DColorMixer` : sélecteur de couleur
- `Panel:Paint(w, h)` : override pour custom rendering
- `draw.RoundedBox(radius, x, y, w, h, color)` : rectangle arrondi
- Scaling : utiliser `ScrW()` et `ScrH()` pour adapter à toutes résolutions

### Pattern menu blueprint
```lua
-- CLIENT
local function OpenBlueprintMenu()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Blueprints")
    frame:SetSize(ScrW() * 0.4, ScrH() * 0.5)
    frame:Center()
    frame:MakePopup()
    
    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:AddColumn("Nom")
    list:AddColumn("Props")
    list:AddColumn("Date")
    
    -- Demander les données au serveur
    net.Start("Construction_RequestBlueprints")
    net.SendToServer()
    
    net.Receive("Construction_SendBlueprints", function()
        local data = net.ReadTable()
        for _, bp in ipairs(data) do
            list:AddLine(bp.name, bp.prop_count, bp.created_at)
        end
    end)
end
```

## Optimisation GLua
- Mettre les fonctions globales en local : `local pairs = pairs`
- Éviter `table.HasValue()` → utiliser une table lookup
- `timer.Simple` plutôt que busy-wait
- `IsValid()` avant toute opération sur une entité
- Net messages : utiliser `WriteUInt` avec le bon nombre de bits plutôt que `WriteInt`

## Système duplicator (CŒUR DU PROJET)
La lib `duplicator` est native à GMod — c'est ce qu'utilise AdvDupe2 en interne.

### Copier des props + constraints
```lua
-- Copie une entité et TOUTES ses entités contraintes
local dupeData = duplicator.Copy(entity)
-- Retourne: { Entities = {}, Constraints = {}, Mins = Vector, Maxs = Vector }
```

### Coller (recréer) des props
```lua
-- Recrée les entités + constraints depuis une table
local createdEnts, createdConstraints = duplicator.Paste(player, entityList, constraintList)
```

### Copier une seule entité (sans constraints)
```lua
local entData = duplicator.CopyEntTable(entity)
-- Retourne EntityCopyData: Pos, Class, Model, Skin, PhysicsObjects, etc.
```

### Pattern pour notre addon : Sérialisation blueprint
```lua
-- 1. Sélectionner les props du joueur dans une zone
local props = ents.FindInSphere(center, radius)
local playerProps = {}
for _, ent in ipairs(props) do
    if ent:GetClass() == "prop_physics" and ent:CPPIGetOwner() == player then
        table.insert(playerProps, ent)
    end
end

-- 2. Copier avec duplicator
local dupeData = duplicator.Copy(playerProps[1]) -- copie récursive des contraints

-- 3. Sérialiser en JSON pour MySQL
local json = util.TableToJSON(dupeData)
local compressed = util.Compress(json) -- LZMA compression

-- 4. Stocker en base (le blob compressé ou le JSON)
-- Via MySQLOO prepared statement pour éviter injection

-- 5. Pour restaurer :
local json = util.Decompress(compressed)
local dupeData = util.JSONToTable(json)
duplicator.Paste(player, dupeData.Entities, dupeData.Constraints)
```

**ATTENTION** : `util.TableToJSON` ne supporte PAS les Vectors/Angles natifs ! Il faut les convertir en tables avant sérialisation :
```lua
-- Vector(1,2,3) → {x=1, y=2, z=3} manuellement
-- Angle(0,90,0) → {p=0, y=90, r=0} manuellement
-- AdvDupe2 gère ça dans CopyEntTable avec des types SERIAL
```

## Constraints (assembler des structures)
```lua
-- Weld : souder deux entités
constraint.Weld(ent1, ent2, bone1, bone2, forceLimit, noCollide, deleteOnBreak)
-- forceLimit = 0 → indestructible

-- NoCollide : désactiver collision entre 2 ents
constraint.NoCollide(ent1, ent2, bone1, bone2)

-- Rope : corde entre deux entités  
constraint.Rope(ent1, ent2, bone1, bone2, lpos1, lpos2, length, addLength, forceLimit, width, material, rigid, color)

-- Axis : pivot/rotation
constraint.Axis(ent1, ent2, bone1, bone2, lpos1, lpos2, forceLimit, torqueLimit, friction, noCollide)

-- Obtenir toutes les constraints d'une entité
local constraints = constraint.GetTable(entity)

-- Vérifier si une entité a des constraints
local hasConstraints = constraint.HasConstraints(entity)
```

## Traces (sélection par le joueur)
```lua
-- Eye trace basique (ce que le joueur regarde)
local tr = util.TraceLine({
    start = player:GetShootPos(),
    endpos = player:GetShootPos() + player:GetAimVector() * 10000,
    filter = player
})
-- tr.Hit, tr.HitPos, tr.Entity, tr.HitNormal, tr.PhysicsBone

-- Trace avec filtre par classe
local tr = util.TraceLine({
    start = ply:GetShootPos(),
    endpos = ply:GetShootPos() + ply:GetAimVector() * 10000,
    filter = function(ent) return ent:GetClass() == "prop_physics" end
})

-- Trace avec whitelist
local tr = util.TraceLine({
    start = ply:GetShootPos(),
    endpos = ply:GetShootPos() + ply:GetAimVector() * 10000,
    filter = { "prop_physics" },
    whitelist = true
})
```

## SENT (Scripted Entities) — Pour notre Blueprint Station
Structure d'un SENT dans un addon :
```
lua/entities/rp_blueprint_station/
  shared.lua  -- ou init.lua + cl_init.lua + shared.lua
```

### shared.lua (fichier unique)
```lua
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Blueprint Station"
ENT.Author = "MonNom"
ENT.Spawnable = true
ENT.Category = "Construction RP"

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "OwnerName")
    self:NetworkVar("Int", 0, "BlueprintCount")
end

function ENT:Initialize()
    self:SetModel("models/props_c17/consolebox01a.mdl")
    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
    end
end

function ENT:Use(activator, caller)
    if SERVER and IsValid(activator) and activator:IsPlayer() then
        -- Ouvrir le menu blueprint
        net.Start("Construction_OpenMenu")
        net.Send(activator)
    end
end

-- CLIENT
function ENT:Draw()
    self:DrawModel()
    -- 3D2D text au dessus de l'entité
    if CLIENT then
        local pos = self:GetPos() + Vector(0, 0, 30)
        local ang = self:GetAngles()
        cam.Start3D2D(pos, Angle(0, ang.y - 90, 90), 0.1)
            draw.SimpleText("Blueprint Station", "DermaLarge", 0, 0, Color(255,255,255), TEXT_ALIGN_CENTER)
        cam.End3D2D()
    end
end
```

## NetworkVar (Data Tables) — Variables réseau sur entités
```lua
function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "Amount")    -- self:SetAmount() / self:GetAmount()
    self:NetworkVar("String", 0, "Name")     -- max 512 chars !
    self:NetworkVar("Int", 0, "Level")
    self:NetworkVar("Bool", 0, "Active")
    self:NetworkVar("Vector", 0, "TargetPos")
    self:NetworkVar("Entity", 0, "Owner")
end
-- Ces variables sont automatiquement synchronisées server → client
```

## STOOL (Sandbox Tool)
```
lua/weapons/gmod_tool/stools/construction_tool.lua
```
```lua
TOOL.Category = "Construction RP"
TOOL.Name = "#tool.construction_tool.name"
TOOL.ClientConVar["mode"] = "select"

if CLIENT then
    language.Add("tool.construction_tool.name", "Construction Tool")
    language.Add("tool.construction_tool.desc", "Select and save props as blueprints")
end

function TOOL:LeftClick(trace)
    -- Sélectionner un prop
    if not IsValid(trace.Entity) then return false end
    if trace.Entity:GetClass() ~= "prop_physics" then return false end
    if SERVER then
        -- Logique de sélection
    end
    return true
end

function TOOL:RightClick(trace)
    -- Sauvegarder le blueprint
    return true
end

function TOOL:Reload(trace)
    -- Reset sélection
    return true
end
```

## DarkRP Custom Chat Commands
```lua
-- SERVERSIDE (sv_commands.lua dans un module DarkRP)
local function SaveBlueprint(ply, args)
    if args == "" then return "" end
    -- Logique de sauvegarde...
    DarkRP.notify(ply, 0, 4, "Blueprint sauvegardé !")
    return ""
end
DarkRP.defineChatCommand("saveblueprint", SaveBlueprint)

-- SHARED (sh_commands.lua)
DarkRP.declareChatCommand{
    command = "saveblueprint",
    description = "Sauvegarder un blueprint",
    delay = 2 -- cooldown anti-spam
}
```

## DarkRP Categories (FIX BUG)
```lua
-- categories.lua dans darkrpmodification/lua/darkrp_customthings/
DarkRP.createCategory{
    name = "Civil",
    categorises = "jobs",
    startExpanded = true,
    color = Color(0, 107, 0, 255),
    canSee = function(ply) return true end,
    sortOrder = 100,
}

DarkRP.createCategory{
    name = "Construction",
    categorises = "entities",
    startExpanded = true,
    color = Color(0, 100, 200, 255),
    sortOrder = 50,
}

DarkRP.createCategory{
    name = "Transport",
    categorises = "vehicles",
    startExpanded = true,
    color = Color(200, 100, 0, 255),
    sortOrder = 100,
}
```

## DarkRP Hooks importants
```
-- Hooks de permission (retourner false pour bloquer)
DarkRP.canChangeJob(ply, jobTable, force)
DarkRP.CanDropWeapon(ply, weapon)
DarkRP.CanVote(ply, voteType, target)

-- Hooks d'événements
DarkRP.PlayerBoughtDoor(ply, ent, price)
DarkRP.PlayerBoughtVehicle(ply, ent, entTable, price)  
DarkRP.TeamChanged(ply, before, after)
DarkRP.PlayerWalletChanged(ply, amount, wallet)
DarkRP.PlayerGetSalary(ply, amount)
DarkRP.DatabaseInitialized()  -- safe pour faire des queries

-- Hook F4 menu (CLIENT)
hook.Add("F4MenuTabs", "ConstructionTab", function()
    local panel = vgui.Create("DPanel")
    -- ... construire l'interface
    DarkRP.addF4MenuTab("Construction", panel)
end)
```

## DarkRP Player Functions
```lua
-- Argent
ply:getDarkRPVar("money")  -- lire l'argent (shared)
ply:canAfford(500)          -- peut-il payer ? (shared)
ply:addMoney(100)           -- ajouter (server only)
ply:addMoney(-500)          -- retirer (server only)

-- DarkRP vars disponibles :
-- money, salary, rpname, job, HasGunlicense, Arrested
-- wanted, wantedReason, AFK, AFKDemoted, Energy (hunger)
-- hitTarget, hitPrice, lastHitTime

-- Job
ply:Team()                  -- numéro de team (TEAM_CITIZEN etc)
ply:getDarkRPVar("job")     -- nom du job (string)
```

## Prop Ownership (CPPI / FPP)
```lua
-- Vérifier le propriétaire d'un prop (compatible FPP)
local owner = entity:CPPIGetOwner()
if owner == player then
    -- C'est son prop
end

-- Définir le propriétaire (après spawn server-side)
entity:CPPISetOwner(player)
```

## Undo System
```lua
-- Après avoir spawné des props, permettre l'undo
undo.Create("Blueprint Paste")
    for _, ent in pairs(createdEntities) do
        undo.AddEntity(ent)
    end
    undo.SetPlayer(player)
    undo.SetCustomUndoText("Undone Blueprint")
undo.Finish()

-- Cleanup (quand le joueur quitte)
player:AddCleanup("blueprints", entity)
```

## HUD Drawing (CLIENT)
```lua
hook.Add("HUDPaint", "ConstructionHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    -- Background box
    draw.RoundedBox(8, 10, ScrH() - 110, 200, 100, Color(30, 30, 30, 200))
    
    -- Text
    draw.SimpleText("Mode: Construction", "DermaDefault", 20, ScrH() - 100, Color(255, 255, 255))
    draw.SimpleText("Props: 5/20", "DermaDefault", 20, ScrH() - 80, Color(200, 200, 200))
    draw.SimpleText("Budget: $500", "DermaDefault", 20, ScrH() - 60, Color(100, 255, 100))
end)
```

## Sécurité Addon GMod

### Règle d'or : NE JAMAIS FAIRE CONFIANCE AU CLIENT

### Validation net messages (pattern)
```lua
-- Rate limiting par joueur
local cooldowns = {}
net.Receive("Construction_SaveBlueprint", function(len, ply)
    -- 1. Rate limit
    if cooldowns[ply] and cooldowns[ply] > CurTime() then return end
    cooldowns[ply] = CurTime() + 2 -- 2 sec cooldown
    
    -- 2. Validation permissions
    if not IsValid(ply) or not ply:Alive() then return end
    if ply:Team() ~= TEAM_BUILDER then return end
    
    -- 3. Validation données
    local name = net.ReadString()
    if #name < 1 or #name > 50 then return end
    name = string.gsub(name, "[^%w%s_-]", "") -- sanitize
    
    -- 4. Validation financière
    local cost = 100
    if not ply:canAfford(cost) then
        DarkRP.notify(ply, 1, 4, "Pas assez d'argent !")
        return
    end
    
    -- 5. Logique métier (seulement ici !)
    ply:addMoney(-cost)
    -- ... sauvegarder le blueprint
end)
```

### SQL Injection Prevention (MySQLOO)
```lua
-- MAUVAIS
db:query("SELECT * FROM blueprints WHERE owner = '" .. steamid .. "'")

-- BON - Prepared statements
local q = db:prepare("SELECT * FROM blueprints WHERE owner_steamid = ?")
q:setString(1, ply:SteamID())
q.onSuccess = function(self, data) ... end
q:start()
```

### Checklist sécurité addon
- [ ] Toute logique importante est SERVER SIDE
- [ ] Chaque net.Receive a un rate limiter
- [ ] Chaque net.Receive valide IsValid(ply) et permissions
- [ ] Pas de RunString() avec input utilisateur
- [ ] Pas de sql.Query() avec concaténation → prepared statements
- [ ] Pas de credentials dans les fichiers shared/client
- [ ] Limites sur les quantités (max props, max blueprints, etc.)

## Envoi de grosses données (>64kb)
Le net library a une limite de 64kb. Pour les gros blueprints :
```lua
-- Pattern : JSON → Compress → Chunk → Send
local function SendLargeData(ply, netName, data)
    local json = util.TableToJSON(data)
    local compressed = util.Compress(json)
    local len = #compressed
    
    -- Envoyer en chunks de 60000 bytes
    local chunks = math.ceil(len / 60000)
    for i = 1, chunks do
        local startByte = (i - 1) * 60000 + 1
        local endByte = math.min(i * 60000, len)
        local chunk = string.sub(compressed, startByte, endByte)
        
        net.Start(netName)
        net.WriteUInt(chunks, 8)     -- nombre total de chunks
        net.WriteUInt(i, 8)          -- numéro du chunk
        net.WriteUInt(#chunk, 16)    -- taille du chunk
        net.WriteData(chunk, #chunk)
        net.Send(ply)
    end
end
```

## PhysObj (Physique)
```lua
local phys = entity:GetPhysicsObject()
if IsValid(phys) then
    phys:EnableMotion(false)  -- freeze
    phys:EnableMotion(true)   -- unfreeze
    phys:Wake()               -- réveiller (commence à simuler)
    phys:SetVelocity(Vector(0, 0, 100))  -- lancer en l'air
    phys:IsMoveable()         -- est-il mobile ?
    phys:GetMass()
    phys:SetMass(50)
end
```

## Recherche d'entités dans une zone
```lua
-- Toutes les entités dans un rayon
local ents_list = ents.FindInSphere(centerPos, radius)

-- Dans une boîte
local ents_list = ents.FindInBox(mins, maxs)

-- Par classe
local all_props = ents.FindByClass("prop_physics")

-- Par modèle
local all_barrels = ents.FindByModel("models/props_c17/oildrum001.mdl")
```

## OOP / Metatables en GLua
```lua
-- Pattern classe
local Blueprint = {}
Blueprint.__index = Blueprint

function Blueprint.new(name, owner)
    local self = setmetatable({}, Blueprint)
    self.name = name
    self.owner = owner
    self.props = {}
    self.created_at = os.time()
    return self
end

function Blueprint:AddProp(model, pos, ang)
    table.insert(self.props, {model = model, pos = pos, ang = ang})
end

function Blueprint:GetPropCount()
    return #self.props
end

function Blueprint:Serialize()
    return util.TableToJSON({
        name = self.name,
        owner = self.owner,
        props = self.props,
        created_at = self.created_at
    })
end
```

## Notifications et feedback joueur
```lua
-- DarkRP notification (SERVER → CLIENT)
DarkRP.notify(player, type, duration, message)
-- type: 0 = NOTIFY_GENERIC, 1 = NOTIFY_ERROR, 2 = NOTIFY_UNDO, 3 = NOTIFY_HINT, 4 = NOTIFY_CLEANUP

-- Chat coloré (CLIENT)
chat.AddText(Color(0, 255, 0), "[Construction] ", Color(255, 255, 255), "Blueprint sauvegardé !")

-- Notification GMod native (CLIENT)
notification.AddLegacy("Blueprint sauvegardé !", NOTIFY_GENERIC, 5)
surface.PlaySound("buttons/button15.wav")
```

## DarkRP F4 Menu — Onglet custom
```lua
-- cl_f4tab.lua (module DarkRP, côté client)
hook.Add("F4MenuTabs", "ConstructionTab", function()
    local panel = vgui.Create("DPanel")
    panel:Dock(FILL)
    
    local label = vgui.Create("DLabel", panel)
    label:SetText("Système de Construction")
    label:SetFont("DermaLarge")
    label:Dock(TOP)
    label:SetContentAlignment(5)
    label:SetTall(40)
    
    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:AddColumn("Nom")
    list:AddColumn("Props")
    list:AddColumn("Coût")
    
    -- Récupérer les blueprints depuis le serveur
    net.Start("Construction_RequestBlueprints")
    net.SendToServer()
    
    DarkRP.addF4MenuTab("Construction", panel)
end)
```

## Derma Avancé
```lua
-- DPropertySheet (onglets)
local tabs = vgui.Create("DPropertySheet", frame)
tabs:Dock(FILL)
tabs:AddSheet("Blueprints", blueprintPanel, "icon16/brick.png")
tabs:AddSheet("Paramètres", settingsPanel, "icon16/cog.png")

-- DComboBox (dropdown)
local combo = vgui.Create("DComboBox", panel)
combo:SetValue("Choisir un blueprint")
combo:AddChoice("Maison simple", "house_simple")
combo:AddChoice("Garage", "garage")
combo.OnSelect = function(self, index, value, data)
    print("Sélectionné:", value, data)
end

-- DNumSlider
local slider = vgui.Create("DNumSlider", panel)
slider:SetText("Nombre max de props")
slider:SetMin(1)
slider:SetMax(100)
slider:SetDecimals(0)
slider:SetValue(20)

-- Docking system
panel:Dock(FILL)    -- remplit tout l'espace
panel:Dock(TOP)     -- en haut
panel:Dock(LEFT)    -- à gauche
panel:DockMargin(5, 5, 5, 5) -- marges
panel:DockPadding(10, 10, 10, 10) -- padding interne
```

## Bugs connus à fixer
1. **Véhicules "disabled"** : `GM.Config.adminvehicles = 0` (pas 3!)
2. **Catégorie manquante** : Créer `categories.lua` avec catégories "Civil", "Construction", "Transport"
3. **users.txt permission** : Utiliser le script Lua sv_admin_setup.lua plutôt que le fichier

## Simfphys → DarkRP Integration
**IMPORTANT** : Les véhicules simfphys ne sont PAS des véhicules Valve (`prop_vehicle_*`).
→ `DarkRP.createVehicle()` NE MARCHE PAS avec simfphys !

### Solution : système custom
```lua
-- Pour spawner un véhicule simfphys :
simfphys.SpawnVehicleSimple("sim_fphys_jeep", spawnPos, spawnAngle)

-- Pour l'intégrer à DarkRP, il faut :
-- 1. Un DarkRP entity custom (pas vehicle)
-- 2. Ou un module DarkRP avec chat command (/buyvehicle)
-- 3. Ou un onglet F4 custom avec boutons d'achat
-- Le spawn utilise simfphys.SpawnVehicleSimple() côté serveur
-- Le paiement utilise ply:canAfford() + ply:addMoney(-prix)
```

## Batch Spawning (anti-lag)
Pour spawner beaucoup de props (gros blueprints) sans freeze :
```lua
-- Pattern : spawner X props par tick
local function BatchSpawn(props, player, callback)
    local index = 0
    local total = #props
    local BATCH_SIZE = 5  -- props par tick
    
    timer.Create("BatchSpawn_" .. player:SteamID64(), 0, 0, function()
        for i = 1, BATCH_SIZE do
            index = index + 1
            if index > total then
                timer.Remove("BatchSpawn_" .. player:SteamID64())
                if callback then callback() end
                return
            end
            -- Spawner le prop
            local p = props[index]
            local ent = ents.Create("prop_physics")
            ent:SetModel(p.model)
            ent:SetPos(p.pos)
            ent:SetAngles(p.ang)
            ent:Spawn()
            ent:GetPhysicsObject():EnableMotion(false)
        end
    end)
end
```

## CanTool Hook (restriction par job)
```lua
hook.Add("CanTool", "RestrictConstructionTool", function(ply, tr, toolname)
    if toolname == "construction_tool" then
        if ply:Team() ~= TEAM_BUILDER then
            DarkRP.notify(ply, 1, 4, "Seul le Constructeur peut utiliser cet outil !")
            return false
        end
    end
end)
```

## MySQLOO Connection Pattern
```lua
require("mysqloo")

local db

local function ConnectToDatabase()
    db = mysqloo.connect("127.0.0.1", "gmod_user", "password", "gmod_construction", 3306)
    
    function db:onConnected()
        print("[Construction] MySQL connecté - v" .. self:serverVersion())
        -- Créer les tables si nécessaire
        InitializeTables()
    end
    
    function db:onConnectionFailed(err)
        print("[Construction] MySQL ERREUR: " .. err)
        -- Retry après 30 secondes
        timer.Simple(30, ConnectToDatabase)
    end
    
    db:connect()
end

-- Vérifier la connexion avant chaque query
local function IsConnected()
    return db and db:status() == mysqloo.DATABASE_CONNECTED
end

-- Query wrapper avec auto-reconnect
local function Query(sql, callback, errorCallback)
    if not IsConnected() then
        ConnectToDatabase()
        timer.Simple(2, function() Query(sql, callback, errorCallback) end)
        return
    end
    
    local q = db:query(sql)
    q.onSuccess = function(self, data)
        if callback then callback(data) end
    end
    q.onError = function(self, err)
        print("[Construction] SQL Error: " .. err)
        if errorCallback then errorCallback(err) end
    end
    q:start()
end
```

## Structure d'addon GMod (Loading Order)
```
addons/rp_construction_system/
├── addon.json                          -- metadata
├── lua/
│   ├── autorun/                        -- SHARED (client+server) auto-loaded
│   │   ├── client/                     -- CLIENT only auto-loaded
│   │   └── server/                     -- SERVER only auto-loaded
│   │       └── sv_construction_init.lua  -- point d'entrée serveur
│   ├── entities/                       -- SENTs
│   │   └── rp_blueprint_station/
│   │       └── shared.lua
│   ├── weapons/                        -- SWEPs
│   │   └── gmod_tool/stools/
│   │       └── construction_tool.lua   -- notre tool custom
│   └── rp_construction/                -- code principal
│       ├── sh_config.lua               -- configuration shared
│       ├── sv_database.lua             -- MySQLOO queries
│       ├── sv_blueprints.lua           -- logique blueprints
│       ├── sv_permissions.lua          -- système de permissions
│       └── cl_menu.lua                 -- interface VGUI
```

**Loading order** : autorun files chargés alphabétiquement (A→Z)
- `autorun/` = shared
- `autorun/server/` = server only
- `autorun/client/` = client only
- entities/ et weapons/ chargés par le gamemode automatiquement

## ConVars (Configuration)
```lua
-- Créer une ConVar serveur (archivée, répliquée au client)
local cv_maxprops = CreateConVar("construction_maxprops", "20", 
    {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED},
    "Nombre max de props par blueprint")

-- Lire la valeur
local max = cv_maxprops:GetInt()

-- ConVar client seulement
local cv_showgrid = CreateClientConVar("construction_showgrid", "1", true, false, "Afficher la grille")
```

## Resource Distribution (contenu custom)
```lua
-- Forcer le client à télécharger un addon Workshop
resource.AddWorkshop("1234567890")

-- Forcer le téléchargement d'un fichier custom
resource.AddFile("materials/my_addon/icon.png")
resource.AddFile("sound/my_addon/build.wav")
```

## Error Handling
```lua
-- pcall : appel protégé (ne crash pas le serveur)
local success, err = pcall(function()
    -- code risqué
    db:query("...")
end)
if not success then
    print("[Construction] Erreur: " .. tostring(err))
end

-- xpcall avec traceback
local success, err = xpcall(function()
    -- code risqué
end, function(err)
    return err .. "\n" .. debug.traceback()
end)

-- ErrorNoHaltWithStack : log erreur sans crash
ErrorNoHaltWithStack("[Construction] Quelque chose a mal tourné\n")
```

## Player Lifecycle Hooks (Server)
```lua
-- Quand un joueur rejoint pour la première fois
hook.Add("PlayerInitialSpawn", "Construction_Init", function(ply)
    -- Charger ses données depuis MySQL
    LoadPlayerData(ply)
end)

-- Quand un joueur se déconnecte
hook.Add("PlayerDisconnected", "Construction_Save", function(ply)
    -- Sauvegarder ses données
    SavePlayerData(ply)
    -- Nettoyer ses props temporaires
    CleanupPlayerProps(ply)
end)

-- Quand le joueur change de job DarkRP
hook.Add("OnPlayerChangedTeam", "Construction_JobChange", function(ply, before, after)
    if after ~= TEAM_BUILDER then
        -- Retirer l'accès aux outils de construction
    end
end)
```

## Requêtes Brave utilisées : ~42/1000
