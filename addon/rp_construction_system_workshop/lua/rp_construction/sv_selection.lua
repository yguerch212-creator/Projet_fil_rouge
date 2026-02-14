--[[-----------------------------------------------------------------------
    RP Construction System - Système de Sélection (Server)
    Gère la sélection de props par joueur côté serveur
---------------------------------------------------------------------------]]

ConstructionSystem.Selection = ConstructionSystem.Selection or {}

-- Table des sélections par joueur (SteamID64 -> table d'entités)
local PlayerSelections = {}

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

--- Vérifie si un joueur peut utiliser le système de construction
local function CanUseConstruction(ply)
    return ConstructionSystem.Compat.CanUse(ply)
end

--- Vérifie si un joueur possède une entité
local function IsOwner(ply, ent)
    return ConstructionSystem.Compat.IsOwner(ply, ent)
end

--- Retourne la clé unique du joueur pour le stockage
local function PlayerKey(ply)
    return ply:SteamID64()
end

---------------------------------------------------------------------------
-- API SELECTION
---------------------------------------------------------------------------

--- Obtenir la sélection actuelle d'un joueur
function ConstructionSystem.Selection.Get(ply)
    local key = PlayerKey(ply)
    if not PlayerSelections[key] then
        PlayerSelections[key] = {}
    end
    return PlayerSelections[key]
end

--- Nombre de props sélectionnés
function ConstructionSystem.Selection.Count(ply)
    local sel = ConstructionSystem.Selection.Get(ply)
    local count = 0
    for entIdx, _ in pairs(sel) do
        local ent = Entity(entIdx)
        if IsValid(ent) then
            count = count + 1
        else
            sel[entIdx] = nil -- nettoyage
        end
    end
    return count
end

--- Vérifier si une entité est sélectionnée
function ConstructionSystem.Selection.IsSelected(ply, ent)
    if not IsValid(ent) then return false end
    local sel = ConstructionSystem.Selection.Get(ply)
    return sel[ent:EntIndex()] ~= nil
end

--- Ajouter une entité à la sélection
function ConstructionSystem.Selection.Add(ply, ent)
    if not IsValid(ent) then return false end
    if ent:GetClass() ~= "prop_physics" then return false end
    if not IsOwner(ply, ent) then return false end

    local maxProps = ConstructionSystem.Config.MaxPropsPerBlueprint
    if maxProps > 0 then
        local count = ConstructionSystem.Selection.Count(ply)
        if count >= maxProps then
            return false, "Limite de props atteinte (" .. maxProps .. ")"
        end
    end

    local sel = ConstructionSystem.Selection.Get(ply)
    sel[ent:EntIndex()] = true

    -- Notifier le client
    ConstructionSystem.Selection.SyncToClient(ply)
    return true
end

--- Retirer une entité de la sélection
function ConstructionSystem.Selection.Remove(ply, ent)
    if not IsValid(ent) then return false end
    local sel = ConstructionSystem.Selection.Get(ply)
    sel[ent:EntIndex()] = nil

    ConstructionSystem.Selection.SyncToClient(ply)
    return true
end

--- Toggle une entité (ajouter/retirer)
function ConstructionSystem.Selection.Toggle(ply, ent)
    if ConstructionSystem.Selection.IsSelected(ply, ent) then
        return ConstructionSystem.Selection.Remove(ply, ent)
    else
        return ConstructionSystem.Selection.Add(ply, ent)
    end
end

--- Sélectionner tous les props dans un rayon
function ConstructionSystem.Selection.AddInRadius(ply, center, radius)
    local maxRadius = ConstructionSystem.Config.SelectionRadiusMax or 2000
    local minRadius = ConstructionSystem.Config.SelectionRadiusMin or 50
    radius = math.Clamp(radius or ConstructionSystem.Config.SelectionRadiusDefault, minRadius, maxRadius)

    local ents_found = ents.FindInSphere(center, radius)
    local added = 0

    for _, ent in ipairs(ents_found) do
        if ent:GetClass() == "prop_physics" and IsOwner(ply, ent) then
            local ok = ConstructionSystem.Selection.Add(ply, ent)
            if ok then added = added + 1 end
        end
    end

    return added
end

--- Vider toute la sélection
function ConstructionSystem.Selection.Clear(ply)
    local key = PlayerKey(ply)
    PlayerSelections[key] = {}

    ConstructionSystem.Selection.SyncToClient(ply)
end

--- Obtenir la liste des entités valides sélectionnées
function ConstructionSystem.Selection.GetEntities(ply)
    local sel = ConstructionSystem.Selection.Get(ply)
    local entities = {}

    for entIdx, _ in pairs(sel) do
        local ent = Entity(entIdx)
        if IsValid(ent) and ent:GetClass() == "prop_physics" then
            table.insert(entities, ent)
        else
            sel[entIdx] = nil
        end
    end

    return entities
end

---------------------------------------------------------------------------
-- SYNCHRONISATION CLIENT
---------------------------------------------------------------------------

--- Envoie la liste des entités sélectionnées au client
function ConstructionSystem.Selection.SyncToClient(ply)
    if not IsValid(ply) then return end

    local sel = ConstructionSystem.Selection.Get(ply)
    local entIds = {}

    for entIdx, _ in pairs(sel) do
        if IsValid(Entity(entIdx)) then
            table.insert(entIds, entIdx)
        end
    end

    net.Start("Construction_SyncSelection")
    net.WriteUInt(#entIds, 10) -- max 1024 entités
    for _, id in ipairs(entIds) do
        net.WriteUInt(id, 13) -- max 8192 entity index
    end
    net.Send(ply)
end

---------------------------------------------------------------------------
-- NET RECEIVERS
---------------------------------------------------------------------------

-- Cooldowns
local selectCooldowns = {}

--- Toggle sélection d'un prop (clic gauche tool)
net.Receive("Construction_SelectToggle", function(len, ply)
    if not CanUseConstruction(ply) then return end

    -- Rate limit
    if selectCooldowns[ply] and selectCooldowns[ply] > CurTime() then return end
    selectCooldowns[ply] = CurTime() + 0.1 -- 100ms cooldown

    local entIdx = net.ReadUInt(13)
    local ent = Entity(entIdx)

    if not IsValid(ent) then return end

    local ok, err = ConstructionSystem.Selection.Toggle(ply, ent)
    if not ok and err then
        ConstructionSystem.Compat.Notify(ply, 1, 3, err)
    end
end)

--- Sélection par rayon (clic droit tool)
net.Receive("Construction_SelectRadius", function(len, ply)
    if not CanUseConstruction(ply) then return end

    if selectCooldowns[ply] and selectCooldowns[ply] > CurTime() then return end
    selectCooldowns[ply] = CurTime() + 1 -- 1s cooldown

    local center = net.ReadVector()
    local radius = net.ReadUInt(10) -- max 1024

    -- Validation
    local maxRadius = ConstructionSystem.Config.SelectionRadiusMax or 2000
    local minRadius = ConstructionSystem.Config.SelectionRadiusMin or 50
    radius = math.Clamp(radius, minRadius, maxRadius)

    -- Vérifier que le centre est pas trop loin du joueur
    if center:Distance(ply:GetPos()) > 2000 then return end

    local added = ConstructionSystem.Selection.AddInRadius(ply, center, radius)
    ConstructionSystem.Compat.Notify(ply, 0, 3, added .. " prop(s) ajouté(s) à la sélection")
end)

--- Vider la sélection (reload tool)
net.Receive("Construction_SelectClear", function(len, ply)
    if not CanUseConstruction(ply) then return end
    ConstructionSystem.Selection.Clear(ply)
    ConstructionSystem.Compat.Notify(ply, 0, 3, "Sélection vidée")
end)

--- Demande de sync (quand le client rejoint ou ouvre le menu)
net.Receive("Construction_RequestSync", function(len, ply)
    if not CanUseConstruction(ply) then return end
    ConstructionSystem.Selection.SyncToClient(ply)
end)

---------------------------------------------------------------------------
-- CLEANUP
---------------------------------------------------------------------------

-- Nettoyer quand un joueur quitte
hook.Add("PlayerDisconnected", "Construction_ClearSelection", function(ply)
    local key = PlayerKey(ply)
    PlayerSelections[key] = nil
    selectCooldowns[ply] = nil
end)

-- Nettoyer si une entité sélectionnée est supprimée
hook.Add("EntityRemoved", "Construction_CleanSelection", function(ent)
    if ent:GetClass() ~= "prop_physics" then return end
    local entIdx = ent:EntIndex()
    for _, sel in pairs(PlayerSelections) do
        sel[entIdx] = nil
    end
end)

print("[Construction] Module sv_selection chargé")
