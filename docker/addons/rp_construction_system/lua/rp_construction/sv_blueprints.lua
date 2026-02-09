--[[-----------------------------------------------------------------------
    RP Construction System - Sauvegarde/Chargement Blueprints (Server)
    Utilise duplicator pour sérialiser, charge en tant que ghosts
---------------------------------------------------------------------------]]

ConstructionSystem.Blueprints = ConstructionSystem.Blueprints or {}

local saveCooldowns = {}
local loadCooldowns = {}

---------------------------------------------------------------------------
-- SÉRIALISATION
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

local function DeserializeValue(val)
    if type(val) ~= "table" then return val end
    if val.__type == "Vector" then
        return Vector(val.x or 0, val.y or 0, val.z or 0)
    elseif val.__type == "Angle" then
        return Angle(val.p or 0, val.y or 0, val.r or 0)
    else
        local new = {}
        for k, v in pairs(val) do
            local numK = tonumber(k)
            new[numK or k] = DeserializeValue(v)
        end
        return new
    end
end

--- Vérifier si une entité est blacklistée
local function IsBlacklisted(ent)
    local class = ent:GetClass()

    -- Seules les classes autorisées
    if not ConstructionSystem.Config.AllowedClasses[class] then
        return true
    end

    -- Check patterns blacklist
    for _, pattern in ipairs(ConstructionSystem.Config.BlacklistedEntities) do
        if string.find(class, pattern, 1, true) then
            return true
        end
    end

    return false
end

--- Sérialise les props sélectionnés
function ConstructionSystem.Blueprints.Serialize(entities)
    if not entities or #entities == 0 then return nil, 0, 0 end

    local dupeData = { Entities = {}, Constraints = {} }

    -- Centre de la structure
    local center = Vector(0, 0, 0)
    for _, ent in ipairs(entities) do
        center = center + ent:GetPos()
    end
    center = center / #entities

    local constraintsSeen = {}
    for idx, ent in ipairs(entities) do
        if IsValid(ent) and not IsBlacklisted(ent) then
            local entData = {
                Class = ent:GetClass(),
                Model = ent:GetModel(),
                Pos = ent:GetPos() - center,
                Ang = ent:GetAngles(),
                Skin = ent:GetSkin(),
                Color = ent:GetColor(),
                Material = ent:GetMaterial(),
                CollisionGroup = ent:GetCollisionGroup(),
            }

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                entData.Frozen = not phys:IsMoveable()
                entData.Mass = phys:GetMass()
            end

            dupeData.Entities[idx] = entData

            -- Constraints
            local constraints = constraint.GetTable(ent)
            for _, con in pairs(constraints) do
                local conId = tostring(con.Type) .. "_"
                for i = 1, 4 do
                    local e = con["Ent" .. i]
                    if IsValid(e) then conId = conId .. e:EntIndex() .. "_" end
                end

                if not constraintsSeen[conId] then
                    constraintsSeen[conId] = true
                    local ent1Valid, ent2Valid = false, false
                    local idx1, idx2
                    for i, selEnt in ipairs(entities) do
                        if con.Ent1 == selEnt then ent1Valid = true; idx1 = i end
                        if con.Ent2 == selEnt then ent2Valid = true; idx2 = i end
                    end

                    if ent1Valid and ent2Valid then
                        table.insert(dupeData.Constraints, {
                            Type = con.Type, Ent1 = idx1, Ent2 = idx2,
                            Bone1 = con.Bone1 or 0, Bone2 = con.Bone2 or 0,
                            ForceLimit = con.forcelimit or 0, NoCollide = con.nocollide or false,
                        })
                    end
                end
            end
        end
    end

    local serialized = SerializeValue(dupeData)
    local json = util.TableToJSON(serialized)
    if not json then return nil, 0, 0 end

    local compressed = util.Compress(json)
    if not compressed then return nil, 0, 0 end

    local encoded = util.Base64Encode(compressed)
    return encoded, table.Count(dupeData.Entities), #dupeData.Constraints
end

--- Désérialise un blueprint (retourne les données, pas de spawn)
function ConstructionSystem.Blueprints.Deserialize(encodedData)
    if not encodedData or encodedData == "" then return nil, "Donnees vides" end

    local compressed = util.Base64Decode(encodedData)
    if not compressed then return nil, "Erreur decodage base64" end

    local json = util.Decompress(compressed)
    if not json then return nil, "Erreur decompression" end

    local serialized = util.JSONToTable(json)
    if not serialized then return nil, "Erreur parsing JSON" end

    local dupeData = DeserializeValue(serialized)
    if not dupeData or not dupeData.Entities then return nil, "Donnees corrompues" end

    return dupeData, nil
end

---------------------------------------------------------------------------
-- NET RECEIVERS
---------------------------------------------------------------------------

--- Sauvegarder un blueprint
net.Receive("Construction_SaveBlueprint", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    if saveCooldowns[ply] and saveCooldowns[ply] > CurTime() then
        DarkRP.notify(ply, 1, 3, "Attends avant de sauvegarder !")
        return
    end
    saveCooldowns[ply] = CurTime() + ConstructionSystem.Config.SaveCooldown

    local name = net.ReadString()
    local description = net.ReadString()

    -- Validation
    if not name or #name < 1 or #name > ConstructionSystem.Config.MaxNameLength then
        DarkRP.notify(ply, 1, 3, "Nom invalide (1-" .. ConstructionSystem.Config.MaxNameLength .. " caracteres)")
        return
    end
    name = string.gsub(name, "[^%w%s_%-%.%(%)%[%]]", "")

    description = description or ""
    if #description > ConstructionSystem.Config.MaxDescLength then
        description = string.sub(description, 1, ConstructionSystem.Config.MaxDescLength)
    end

    -- Vérifier le nombre de blueprints (0 = illimité)
    ConstructionSystem.DB.CountPlayerBlueprints(ply, function(count)
        local maxBP = ConstructionSystem.Config.MaxBlueprintsPerPlayer
        if maxBP > 0 and count >= maxBP then
            DarkRP.notify(ply, 1, 3, "Limite de blueprints atteinte (" .. maxBP .. ")")
            return
        end

        local entities = ConstructionSystem.Selection.GetEntities(ply)
        if #entities == 0 then
            DarkRP.notify(ply, 1, 3, "Aucun prop selectionne !")
            return
        end

        local data, propCount, constraintCount = ConstructionSystem.Blueprints.Serialize(entities)
        if not data then
            DarkRP.notify(ply, 1, 3, "Erreur de serialisation")
            return
        end

        ConstructionSystem.DB.SaveBlueprint(ply, name, description, data, propCount, constraintCount, function(success, id, err)
            if success then
                DarkRP.notify(ply, 0, 5, "Blueprint '" .. name .. "' sauvegarde ! (" .. propCount .. " props)")
                ConstructionSystem.Selection.Clear(ply)
            else
                DarkRP.notify(ply, 1, 4, "Erreur sauvegarde : " .. tostring(err))
            end
        end)
    end)
end)

--- Charger un blueprint → envoyer preview au client
net.Receive("Construction_LoadBlueprint", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    if loadCooldowns[ply] and loadCooldowns[ply] > CurTime() then
        DarkRP.notify(ply, 1, 3, "Attends avant de charger !")
        return
    end
    loadCooldowns[ply] = CurTime() + ConstructionSystem.Config.LoadCooldown

    local blueprintId = net.ReadUInt(32)

    ConstructionSystem.DB.LoadBlueprint(blueprintId, ply, function(blueprint, err)
        if not blueprint then
            DarkRP.notify(ply, 1, 4, err or "Blueprint introuvable")
            return
        end

        -- Désérialiser
        local dupeData, deserErr = ConstructionSystem.Blueprints.Deserialize(blueprint.data)
        if not dupeData then
            DarkRP.notify(ply, 1, 4, "Erreur chargement : " .. tostring(deserErr))
            return
        end

        -- Préparer les données légères pour le client (modèles + positions relatives)
        local previewData = { Entities = {} }
        for key, entData in pairs(dupeData.Entities) do
            previewData.Entities[key] = {
                Model = entData.Model,
                Pos = entData.Pos,
                Ang = entData.Ang,
                Skin = entData.Skin,
                Material = entData.Material,
            }
        end

        -- Compresser et envoyer au client
        local json = util.TableToJSON(previewData)
        local compressed = util.Compress(json)

        if not compressed then
            DarkRP.notify(ply, 1, 4, "Erreur compression preview")
            return
        end

        -- Stocker les données complètes pour le spawn (quand le client confirme)
        ply.PendingBlueprint = {
            id = blueprintId,
            data = dupeData,
        }

        net.Start("Construction_SendPreview")
        net.WriteUInt(blueprintId, 32)
        net.WriteUInt(#compressed, 32)
        net.WriteData(compressed, #compressed)
        net.Send(ply)
    end)
end)

--- Confirmer le placement → spawn des GHOSTS
net.Receive("Construction_ConfirmPlacement", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    local blueprintId = net.ReadUInt(32)
    local spawnPos = net.ReadVector()
    local rotation = net.ReadFloat()

    -- Vérifier que le joueur a bien un blueprint en attente
    if not ply.PendingBlueprint or ply.PendingBlueprint.id ~= blueprintId then
        DarkRP.notify(ply, 1, 3, "Aucun blueprint en attente")
        return
    end

    -- Validation: position pas trop loin du joueur
    if spawnPos:Distance(ply:GetPos()) > 5000 then
        DarkRP.notify(ply, 1, 3, "Position trop éloignée")
        return
    end

    -- Appliquer la rotation aux données
    local dupeData = ply.PendingBlueprint.data
    local rotatedData = { Entities = {}, Constraints = dupeData.Constraints }
    local rad = math.rad(rotation)
    local cos, sin = math.cos(rad), math.sin(rad)

    for key, entData in pairs(dupeData.Entities) do
        local newData = table.Copy(entData)
        -- Rotation du vecteur offset
        if newData.Pos then
            local ox, oy = newData.Pos.x or 0, newData.Pos.y or 0
            newData.Pos = Vector(ox * cos - oy * sin, ox * sin + oy * cos, newData.Pos.z or 0)
        end
        -- Rotation de l'angle
        if newData.Ang then
            newData.Ang = Angle(newData.Ang.p or 0, (newData.Ang.y or 0) + rotation, newData.Ang.r or 0)
        end
        rotatedData.Entities[key] = newData
    end

    -- Spawn des GHOSTS à la position confirmée
    local ok, groupID = ConstructionSystem.Ghosts.SpawnFromBlueprint(ply, rotatedData, spawnPos)
    if not ok then
        DarkRP.notify(ply, 1, 4, "Erreur spawn : " .. tostring(groupID))
    end

    ply.PendingBlueprint = nil
end)

--- Annuler le placement
net.Receive("Construction_CancelPlacement", function(len, ply)
    if not IsValid(ply) then return end
    ply.PendingBlueprint = nil
end)

--- Supprimer un blueprint
net.Receive("Construction_DeleteBlueprint", function(len, ply)
    if not IsValid(ply) then return end
    local blueprintId = net.ReadUInt(32)

    ConstructionSystem.DB.DeleteBlueprint(blueprintId, ply, function(success, err)
        if success then
            DarkRP.notify(ply, 0, 3, "Blueprint supprime")
            ConstructionSystem.Blueprints.SendList(ply)
        else
            DarkRP.notify(ply, 1, 3, err or "Erreur suppression")
        end
    end)
end)

--- Demander la liste
net.Receive("Construction_RequestBlueprints", function(len, ply)
    if not IsValid(ply) then return end
    ConstructionSystem.Blueprints.SendList(ply)
end)

--- Envoyer la liste au client
function ConstructionSystem.Blueprints.SendList(ply)
    if not IsValid(ply) then return end

    ConstructionSystem.DB.GetPlayerBlueprints(ply, function(blueprints)
        net.Start("Construction_SendBlueprints")
        net.WriteUInt(#blueprints, 8)

        for _, bp in ipairs(blueprints) do
            net.WriteUInt(tonumber(bp.id) or 0, 32)
            net.WriteString(bp.name or "")
            net.WriteString(bp.description or "")
            net.WriteUInt(tonumber(bp.prop_count) or 0, 10)
            net.WriteUInt(tonumber(bp.constraint_count) or 0, 10)
            net.WriteBool(tonumber(bp.is_public) == 1)
            net.WriteString(bp.created_at or "")
        end

        net.Send(ply)
    end)
end

--- Net: ouvrir le menu (relay serveur -> client)
net.Receive("Construction_OpenMenu", function(len, ply)
    if not IsValid(ply) then return end
    net.Start("Construction_OpenMenu")
    net.Send(ply)
end)

--- Cleanup cooldowns
hook.Add("PlayerDisconnected", "Construction_ClearBPCooldowns", function(ply)
    saveCooldowns[ply] = nil
    loadCooldowns[ply] = nil
end)

print("[Construction] Module sv_blueprints charge")
