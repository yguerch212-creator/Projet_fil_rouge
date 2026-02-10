--[[-----------------------------------------------------------------------
    RP Construction System - Blueprints (Server)
    
    Les sauvegardes sont LOCALES (côté client dans data/).
    Le serveur gère uniquement :
    - La sérialisation des props sélectionnés → envoi au client
    - La réception des données blueprint pour le placement (ghosts)
    - La validation de sécurité (blacklist, limites props)
---------------------------------------------------------------------------]]

ConstructionSystem.Blueprints = ConstructionSystem.Blueprints or {}

local saveCooldowns = {}
local loadCooldowns = {}

---------------------------------------------------------------------------
-- SÉRIALISATION (serveur → client)
---------------------------------------------------------------------------

local function SerializeValue(val)
    local t = type(val)
    if t == "Vector" then
        return {__type = "Vector", x = val.x, y = val.y, z = val.z}
    elseif t == "Angle" then
        return {__type = "Angle", p = val.p, y = val.y, r = val.r}
    elseif t == "table" then
        local new = {}
        for k, v in pairs(val) do
            new[tostring(k)] = SerializeValue(v)
        end
        return new
    else
        return val
    end
end

--- Vérifier si une entité est blacklistée
local function IsBlacklisted(ent)
    local class = ent:GetClass()
    if not ConstructionSystem.Config.AllowedClasses[class] then return true end
    for _, pattern in ipairs(ConstructionSystem.Config.BlacklistedEntities) do
        if string.find(class, pattern, 1, true) then return true end
    end
    return false
end

--- Sérialise les props sélectionnés en données blueprint
function ConstructionSystem.Blueprints.Serialize(entities)
    if not entities or #entities == 0 then return nil, 0 end

    local data = { Entities = {} }

    -- Centre de la structure (position absolue sauvegardée pour "paste at original pos")
    local center = Vector(0, 0, 0)
    for _, ent in ipairs(entities) do
        center = center + ent:GetPos()
    end
    center = center / #entities

    -- Sauvegarder la position absolue du centre
    data.OriginalCenter = center

    local count = 0
    for idx, ent in ipairs(entities) do
        if IsValid(ent) and not IsBlacklisted(ent) then
            local entData = {
                Class = ent:GetClass(),
                Model = ent:GetModel(),
                Pos = ent:GetPos() - center,
                Ang = ent:GetAngles(),
                Skin = ent:GetSkin(),
                Material = ent:GetMaterial(),
            }

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                entData.Frozen = not phys:IsMoveable()
                entData.Mass = phys:GetMass()
            end

            data.Entities[idx] = entData
            count = count + 1
        end
    end

    return data, count
end

---------------------------------------------------------------------------
-- VALIDATION DES DONNÉES BLUEPRINT (reçues du client)
---------------------------------------------------------------------------

local function ValidateBlueprintData(data)
    if not data or type(data) ~= "table" then return false, "Données invalides" end
    if not data.Entities or type(data.Entities) ~= "table" then return false, "Pas d'entités" end

    local count = 0
    for key, entData in pairs(data.Entities) do
        if type(entData) ~= "table" then continue end
        count = count + 1

        -- Vérifier que c'est un prop_physics (ou pas de classe = par défaut prop_physics)
        if entData.Class and entData.Class ~= "prop_physics" then
            return false, "Classe interdite: " .. tostring(entData.Class)
        end

        -- Vérifier le modèle
        if not entData.Model or type(entData.Model) ~= "string" then
            return false, "Modèle manquant"
        end

        -- Vérifier les positions (accepte Vector ou table avec x/y/z)
        if not entData.Pos then
            return false, "Position manquante"
        end
    end

    -- Vérifier la limite de props
    local maxProps = ConstructionSystem.Config.MaxPropsPerBlueprint
    if maxProps > 0 and count > maxProps then
        return false, "Trop de props (" .. count .. "/" .. maxProps .. ")"
    end

    if count == 0 then return false, "Blueprint vide" end

    return true, count
end

--- Reconstruit les Vector/Angle depuis les tables sérialisées
local function RebuildVectors(data)
    if not data or not data.Entities then return data end

    -- Rebuild OriginalCenter
    if data.OriginalCenter then
        if type(data.OriginalCenter) == "Vector" then
            -- Déjà un Vector, rien à faire
        elseif type(data.OriginalCenter) == "table" then
            data.OriginalCenter = Vector(
                tonumber(data.OriginalCenter.x) or 0,
                tonumber(data.OriginalCenter.y) or 0,
                tonumber(data.OriginalCenter.z) or 0
            )
        elseif type(data.OriginalCenter) == "string" then
            -- util.TableToJSON sérialise les Vectors comme strings "x y z"
            local parts = string.Explode(" ", data.OriginalCenter)
            data.OriginalCenter = Vector(
                tonumber(parts[1]) or 0,
                tonumber(parts[2]) or 0,
                tonumber(parts[3]) or 0
            )
        else
            data.OriginalCenter = Vector(0, 0, 0)
        end
    end

    for key, entData in pairs(data.Entities) do
        if type(entData) ~= "table" then continue end
        -- Rebuild Pos
        if entData.Pos then
            if type(entData.Pos) == "string" then
                local p = string.Explode(" ", entData.Pos)
                entData.Pos = Vector(tonumber(p[1]) or 0, tonumber(p[2]) or 0, tonumber(p[3]) or 0)
            elseif type(entData.Pos) == "table" then
                entData.Pos = Vector(tonumber(entData.Pos.x) or 0, tonumber(entData.Pos.y) or 0, tonumber(entData.Pos.z) or 0)
            end
        end
        -- Rebuild Ang
        if entData.Ang then
            if type(entData.Ang) == "string" then
                local a = string.Explode(" ", entData.Ang)
                entData.Ang = Angle(tonumber(a[1]) or 0, tonumber(a[2]) or 0, tonumber(a[3]) or 0)
            elseif type(entData.Ang) == "table" then
                entData.Ang = Angle(tonumber(entData.Ang.p) or 0, tonumber(entData.Ang.y) or 0, tonumber(entData.Ang.r) or 0)
            end
        end
    end

    return data
end

---------------------------------------------------------------------------
-- NET: SAUVEGARDER (serveur sérialise → envoie au client pour stockage local)
---------------------------------------------------------------------------

net.Receive("Construction_SaveBlueprint", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    if saveCooldowns[ply] and saveCooldowns[ply] > CurTime() then
        DarkRP.notify(ply, 1, 3, "Attends avant de sauvegarder !")
        return
    end
    saveCooldowns[ply] = CurTime() + ConstructionSystem.Config.SaveCooldown

    local name = net.ReadString()
    local description = net.ReadString()

    -- Validation nom
    if not name or #name < 1 or #name > ConstructionSystem.Config.MaxNameLength then
        DarkRP.notify(ply, 1, 3, "Nom invalide (1-" .. ConstructionSystem.Config.MaxNameLength .. " caractères)")
        return
    end
    name = string.gsub(name, "[^%w%s_%-%.%(%)%[%]]", "")

    description = description or ""
    if #description > ConstructionSystem.Config.MaxDescLength then
        description = string.sub(description, 1, ConstructionSystem.Config.MaxDescLength)
    end

    -- Récupérer les props sélectionnés
    local entities = ConstructionSystem.Selection.GetEntities(ply)
    if #entities == 0 then
        DarkRP.notify(ply, 1, 3, "Aucun prop sélectionné !")
        return
    end

    -- Sérialiser
    local data, propCount = ConstructionSystem.Blueprints.Serialize(entities)
    if not data then
        DarkRP.notify(ply, 1, 3, "Erreur de sérialisation")
        return
    end

    -- Préparer le blueprint complet
    local blueprint = {
        name = name,
        description = description,
        prop_count = propCount,
        created_at = os.date("%Y-%m-%d %H:%M"),
        version = ConstructionSystem.Config.Version,
        data = data,
    }

    -- Sérialiser pour envoi
    local serialized = SerializeValue(blueprint)
    local json = util.TableToJSON(serialized)
    local compressed = util.Compress(json)

    if not compressed then
        DarkRP.notify(ply, 1, 3, "Erreur compression")
        return
    end

    -- Envoyer au client pour stockage local
    net.Start("Construction_SaveToClient")
    net.WriteString(name)
    net.WriteUInt(propCount, 10)
    net.WriteUInt(#compressed, 32)
    net.WriteData(compressed, #compressed)
    net.Send(ply)

    ConstructionSystem.Selection.Clear(ply)
    DarkRP.notify(ply, 0, 5, "Blueprint '" .. name .. "' sérialisé (" .. propCount .. " props) - Sauvegarde locale")

    -- Log serveur (optionnel, si DB connectée)
    if ConstructionSystem.DB and ConstructionSystem.DB.IsConnected() then
        ConstructionSystem.DB.Log(ply, "save", "Blueprint '" .. name .. "' (" .. propCount .. " props)")
    end
end)

---------------------------------------------------------------------------
-- NET: CHARGER (client envoie les données → serveur valide → preview/ghosts)
---------------------------------------------------------------------------

net.Receive("Construction_LoadBlueprint", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    if loadCooldowns[ply] and loadCooldowns[ply] > CurTime() then
        DarkRP.notify(ply, 1, 3, "Attends avant de charger !")
        return
    end
    loadCooldowns[ply] = CurTime() + ConstructionSystem.Config.LoadCooldown

    -- Recevoir les données compressées du client
    local dataLen = net.ReadUInt(32)

    -- Sécurité: limiter la taille (max 512KB)
    if dataLen > 524288 then
        DarkRP.notify(ply, 1, 3, "Fichier trop volumineux")
        return
    end

    local compressed = net.ReadData(dataLen)
    if not compressed then
        DarkRP.notify(ply, 1, 3, "Données corrompues")
        return
    end

    local json = util.Decompress(compressed)
    if not json then
        DarkRP.notify(ply, 1, 3, "Erreur décompression")
        return
    end

    local blueprint = util.JSONToTable(json)
    if not blueprint or not blueprint.data or not blueprint.data.Entities then
        DarkRP.notify(ply, 1, 3, "Blueprint invalide")
        return
    end

    -- Valider côté serveur AVANT de reconstruire (blacklist, limites)
    local valid, result = ValidateBlueprintData(blueprint.data)
    if not valid then
        DarkRP.notify(ply, 1, 4, "Blueprint rejeté: " .. tostring(result))
        return
    end

    -- Reconstruire les Vector/Angle après validation
    local dupeData = RebuildVectors(blueprint.data)

    print("[Construction] OriginalCenter after rebuild: " .. tostring(dupeData.OriginalCenter) .. " type: " .. type(dupeData.OriginalCenter))

    -- Préparer la preview pour le client (données légères)
    local previewData = {
        Entities = {},
        OriginalCenter = dupeData.OriginalCenter,
    }
    for key, entData in pairs(dupeData.Entities) do
        previewData.Entities[key] = {
            Model = entData.Model,
            Pos = entData.Pos,
            Ang = entData.Ang,
            Skin = entData.Skin,
            Material = entData.Material,
        }
    end

    local previewJson = util.TableToJSON(previewData)
    local previewCompressed = util.Compress(previewJson)

    if not previewCompressed then
        DarkRP.notify(ply, 1, 4, "Erreur preview")
        return
    end

    -- Stocker les données complètes pour le spawn
    ply.PendingBlueprint = {
        data = dupeData,
        name = blueprint.name or "Sans nom",
    }

    -- Envoyer la preview au client
    net.Start("Construction_SendPreview")
    net.WriteUInt(0, 32)  -- pas d'ID (stockage local)
    net.WriteUInt(#previewCompressed, 32)
    net.WriteData(previewCompressed, #previewCompressed)
    net.Send(ply)
end)

---------------------------------------------------------------------------
-- NET: CONFIRMER PLACEMENT → SPAWN GHOSTS
---------------------------------------------------------------------------

net.Receive("Construction_ConfirmPlacement", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    local _ = net.ReadUInt(32)  -- blueprintId (legacy, ignoré)
    local spawnPos = net.ReadVector()
    local rotation = net.ReadFloat()

    if not ply.PendingBlueprint then
        DarkRP.notify(ply, 1, 3, "Aucun blueprint en attente")
        return
    end

    -- Validation: position pas trop loin
    if spawnPos:Distance(ply:GetPos()) > 5000 then
        DarkRP.notify(ply, 1, 3, "Position trop éloignée")
        return
    end

    local dupeData = ply.PendingBlueprint.data
    local bpName = ply.PendingBlueprint.name

    -- Appliquer la rotation
    local rotatedData = { Entities = {} }
    local rad = math.rad(rotation)
    local cos, sin = math.cos(rad), math.sin(rad)

    for key, entData in pairs(dupeData.Entities) do
        local newData = table.Copy(entData)
        if newData.Pos then
            local ox, oy = newData.Pos.x or 0, newData.Pos.y or 0
            newData.Pos = Vector(ox * cos - oy * sin, ox * sin + oy * cos, newData.Pos.z or 0)
        end
        if newData.Ang then
            newData.Ang = Angle(newData.Ang.p or 0, (newData.Ang.y or 0) + rotation, newData.Ang.r or 0)
        end
        rotatedData.Entities[key] = newData
    end

    -- Spawn des GHOSTS
    local ok, groupID = ConstructionSystem.Ghosts.SpawnFromBlueprint(ply, rotatedData, spawnPos)
    if ok then
        -- Log
        if ConstructionSystem.DB and ConstructionSystem.DB.IsConnected() then
            ConstructionSystem.DB.Log(ply, "load", "Ghosts placés: '" .. bpName .. "'")
        end
    else
        DarkRP.notify(ply, 1, 4, "Erreur spawn: " .. tostring(groupID))
    end

    ply.PendingBlueprint = nil
end)

---------------------------------------------------------------------------
-- NET: ANNULER PLACEMENT
---------------------------------------------------------------------------

net.Receive("Construction_CancelPlacement", function(len, ply)
    if not IsValid(ply) then return end
    ply.PendingBlueprint = nil
end)

---------------------------------------------------------------------------
-- CLEANUP
---------------------------------------------------------------------------

hook.Add("PlayerDisconnected", "Construction_ClearBPCooldowns", function(ply)
    saveCooldowns[ply] = nil
    loadCooldowns[ply] = nil
    ply.PendingBlueprint = nil
end)

print("[Construction] Module sv_blueprints chargé")
