--[[-----------------------------------------------------------------------
    RP Construction System - Sauvegarde/Chargement Blueprints (Server)
    Utilise duplicator.Copy/Paste pour sérialiser/recréer des structures
---------------------------------------------------------------------------]]

require("duplicator")

ConstructionSystem.Blueprints = ConstructionSystem.Blueprints or {}

-- Cooldowns
local saveCooldowns = {}
local loadCooldowns = {}

---------------------------------------------------------------------------
-- SÉRIALISATION
---------------------------------------------------------------------------

--- Convertit les Vectors et Angles en tables simples pour JSON
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

--- Reconvertit les tables en Vectors et Angles
local function DeserializeValue(val)
    if type(val) ~= "table" then return val end

    if val.__type == "Vector" then
        return Vector(val.x or 0, val.y or 0, val.z or 0)
    elseif val.__type == "Angle" then
        return Angle(val.p or 0, val.y or 0, val.r or 0)
    else
        local new = {}
        for k, v in pairs(val) do
            -- Restaurer les clés numériques
            local numK = tonumber(k)
            new[numK or k] = DeserializeValue(v)
        end
        return new
    end
end

--- Sérialise les props sélectionnés en JSON compressé
function ConstructionSystem.Blueprints.Serialize(entities)
    if not entities or #entities == 0 then return nil, 0, 0 end

    -- Utiliser duplicator.Copy sur la première entité (copie récursive des constraints)
    local dupeData = {
        Entities = {},
        Constraints = {}
    }

    -- Calculer le centre de la structure
    local center = Vector(0, 0, 0)
    for _, ent in ipairs(entities) do
        center = center + ent:GetPos()
    end
    center = center / #entities

    -- Copier chaque entité manuellement (plus fiable que duplicator.Copy pour notre cas)
    local constraintsSeen = {}
    for idx, ent in ipairs(entities) do
        if IsValid(ent) and ent:GetClass() == "prop_physics" then
            local entData = {
                Class = ent:GetClass(),
                Model = ent:GetModel(),
                Pos = ent:GetPos() - center, -- Position relative au centre
                Ang = ent:GetAngles(),
                Skin = ent:GetSkin(),
                Color = ent:GetColor(),
                Material = ent:GetMaterial(),
                CollisionGroup = ent:GetCollisionGroup(),
            }

            -- Infos physiques
            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                entData.Frozen = not phys:IsMoveable()
                entData.Mass = phys:GetMass()
            end

            dupeData.Entities[idx] = entData

            -- Récupérer les constraints de cette entité
            local constraints = constraint.GetTable(ent)
            for _, con in pairs(constraints) do
                -- Identifier de façon unique la constraint
                local conId = tostring(con.Type) .. "_"
                for i = 1, 4 do
                    local e = con["Ent" .. i]
                    if IsValid(e) then
                        conId = conId .. e:EntIndex() .. "_"
                    end
                end

                if not constraintsSeen[conId] then
                    constraintsSeen[conId] = true

                    -- Vérifier que les deux entités de la constraint sont dans notre sélection
                    local ent1Valid = false
                    local ent2Valid = false
                    for _, selEnt in ipairs(entities) do
                        if con.Ent1 == selEnt then ent1Valid = true end
                        if con.Ent2 == selEnt then ent2Valid = true end
                    end

                    if ent1Valid and ent2Valid then
                        -- Trouver les index dans notre table
                        local idx1, idx2
                        for i, e in ipairs(entities) do
                            if e == con.Ent1 then idx1 = i end
                            if e == con.Ent2 then idx2 = i end
                        end

                        table.insert(dupeData.Constraints, {
                            Type = con.Type,
                            Ent1 = idx1,
                            Ent2 = idx2,
                            Bone1 = con.Bone1 or 0,
                            Bone2 = con.Bone2 or 0,
                            ForceLimit = con.forcelimit or 0,
                            NoCollide = con.nocollide or false,
                        })
                    end
                end
            end
        end
    end

    -- Sérialiser
    local serialized = SerializeValue(dupeData)
    local json = util.TableToJSON(serialized)
    if not json then return nil, 0, 0 end

    -- Compresser
    local compressed = util.Compress(json)
    if not compressed then return nil, 0, 0 end

    -- Encoder en base64 pour stockage MySQL (LONGTEXT)
    local encoded = util.Base64Encode(compressed)

    local propCount = table.Count(dupeData.Entities)
    local constraintCount = #dupeData.Constraints

    return encoded, propCount, constraintCount
end

--- Désérialise et spawn les props d'un blueprint
function ConstructionSystem.Blueprints.Deserialize(ply, encodedData, spawnPos)
    if not IsValid(ply) then return false, "Joueur invalide" end
    if not encodedData or encodedData == "" then return false, "Données vides" end

    -- Décoder base64
    local compressed = util.Base64Decode(encodedData)
    if not compressed then return false, "Erreur décodage base64" end

    -- Décompresser
    local json = util.Decompress(compressed)
    if not json then return false, "Erreur décompression" end

    -- Parser JSON
    local serialized = util.JSONToTable(json)
    if not serialized then return false, "Erreur parsing JSON" end

    -- Restaurer les types
    local dupeData = DeserializeValue(serialized)
    if not dupeData or not dupeData.Entities then return false, "Données corrompues" end

    -- Vérifier les limites
    local propCount = table.Count(dupeData.Entities)
    if propCount > ConstructionSystem.Config.MaxPropsPerBlueprint then
        return false, "Blueprint trop gros (" .. propCount .. " props)"
    end

    -- Spawn les props en batch pour éviter les lags
    local createdEntities = {}
    local index = 0
    local entityKeys = table.GetKeys(dupeData.Entities)
    local totalEntities = #entityKeys
    local BATCH_SIZE = 5

    timer.Create("Construction_Spawn_" .. ply:SteamID64(), 0, 0, function()
        if not IsValid(ply) then
            timer.Remove("Construction_Spawn_" .. ply:SteamID64())
            -- Cleanup les entités déjà créées
            for _, ent in pairs(createdEntities) do
                if IsValid(ent) then ent:Remove() end
            end
            return
        end

        for i = 1, BATCH_SIZE do
            index = index + 1
            if index > totalEntities then
                timer.Remove("Construction_Spawn_" .. ply:SteamID64())

                -- Appliquer les constraints après avoir tout spawné
                ConstructionSystem.Blueprints.ApplyConstraints(ply, dupeData.Constraints, createdEntities)

                -- Undo
                undo.Create("Blueprint")
                    for _, ent in pairs(createdEntities) do
                        if IsValid(ent) then
                            undo.AddEntity(ent)
                            ply:AddCleanup("blueprints", ent)
                        end
                    end
                    undo.SetPlayer(ply)
                    undo.SetCustomUndoText("Undone Blueprint")
                undo.Finish()

                DarkRP.notify(ply, 0, 4, "Blueprint charge : " .. totalEntities .. " props")
                return
            end

            local key = entityKeys[index]
            local entData = dupeData.Entities[key]

            if entData and entData.Model then
                local ent = ents.Create(entData.Class or "prop_physics")
                if IsValid(ent) then
                    ent:SetModel(entData.Model)
                    ent:SetPos(spawnPos + (entData.Pos or Vector(0, 0, 0)))
                    ent:SetAngles(entData.Ang or Angle(0, 0, 0))
                    ent:Spawn()
                    ent:Activate()

                    -- Propriétés
                    if entData.Skin and entData.Skin > 0 then ent:SetSkin(entData.Skin) end
                    if entData.Material and entData.Material ~= "" then ent:SetMaterial(entData.Material) end
                    if entData.Color then ent:SetColor(entData.Color) end
                    if entData.CollisionGroup then ent:SetCollisionGroup(entData.CollisionGroup) end

                    -- Physique
                    local phys = ent:GetPhysicsObject()
                    if IsValid(phys) then
                        if entData.Mass then phys:SetMass(entData.Mass) end
                        -- Freeze tous les props par défaut pour éviter qu'ils tombent
                        phys:EnableMotion(false)
                        phys:Sleep()
                    end

                    -- Ownership
                    if ent.CPPISetOwner then
                        ent:CPPISetOwner(ply)
                    end

                    createdEntities[key] = ent
                end
            end
        end
    end)

    return true, nil
end

--- Appliquer les constraints entre les props créés
function ConstructionSystem.Blueprints.ApplyConstraints(ply, constraints, createdEntities)
    if not constraints then return end

    for _, con in ipairs(constraints) do
        local ent1 = createdEntities[con.Ent1]
        local ent2 = createdEntities[con.Ent2]

        if IsValid(ent1) and IsValid(ent2) then
            if con.Type == "Weld" then
                constraint.Weld(ent1, ent2, con.Bone1 or 0, con.Bone2 or 0, con.ForceLimit or 0, con.NoCollide or false)
            elseif con.Type == "NoCollide" then
                constraint.NoCollide(ent1, ent2, con.Bone1 or 0, con.Bone2 or 0)
            elseif con.Type == "Rope" then
                -- Les ropes nécessitent plus de données, on les skip pour le moment
            end
        end
    end
end

---------------------------------------------------------------------------
-- NET RECEIVERS
---------------------------------------------------------------------------

--- Sauvegarder un blueprint depuis la sélection
net.Receive("Construction_SaveBlueprint", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    -- Rate limit
    if saveCooldowns[ply] and saveCooldowns[ply] > CurTime() then
        DarkRP.notify(ply, 1, 3, "Attends avant de sauvegarder !")
        return
    end
    saveCooldowns[ply] = CurTime() + ConstructionSystem.Config.SaveCooldown

    -- Lire les données
    local name = net.ReadString()
    local description = net.ReadString()

    -- Validation nom
    if not name or #name < 1 or #name > ConstructionSystem.Config.MaxNameLength then
        DarkRP.notify(ply, 1, 3, "Nom invalide (1-" .. ConstructionSystem.Config.MaxNameLength .. " caracteres)")
        return
    end
    name = string.gsub(name, "[^%w%s_%-%.%(%)%[%]]", "") -- sanitize

    -- Validation description
    description = description or ""
    if #description > ConstructionSystem.Config.MaxDescLength then
        description = string.sub(description, 1, ConstructionSystem.Config.MaxDescLength)
    end

    -- Vérifier le coût
    if not ply:canAfford(ConstructionSystem.Config.SaveCost) then
        DarkRP.notify(ply, 1, 3, "Pas assez d'argent ! ($" .. ConstructionSystem.Config.SaveCost .. " requis)")
        return
    end

    -- Vérifier le nombre de blueprints
    ConstructionSystem.DB.CountPlayerBlueprints(ply, function(count)
        if count >= ConstructionSystem.Config.MaxBlueprintsPerPlayer then
            DarkRP.notify(ply, 1, 3, "Limite de blueprints atteinte (" .. ConstructionSystem.Config.MaxBlueprintsPerPlayer .. ")")
            return
        end

        -- Récupérer les entités sélectionnées
        local entities = ConstructionSystem.Selection.GetEntities(ply)
        if #entities == 0 then
            DarkRP.notify(ply, 1, 3, "Aucun prop selectionne !")
            return
        end

        -- Sérialiser
        local data, propCount, constraintCount = ConstructionSystem.Blueprints.Serialize(entities)
        if not data then
            DarkRP.notify(ply, 1, 3, "Erreur de serialisation")
            return
        end

        -- Retirer l'argent
        ply:addMoney(-ConstructionSystem.Config.SaveCost)

        -- Sauvegarder en base
        ConstructionSystem.DB.SaveBlueprint(ply, name, description, data, propCount, constraintCount, function(success, id, err)
            if success then
                DarkRP.notify(ply, 0, 5, "Blueprint '" .. name .. "' sauvegarde ! (" .. propCount .. " props, $" .. ConstructionSystem.Config.SaveCost .. ")")
                -- Vider la sélection après sauvegarde
                ConstructionSystem.Selection.Clear(ply)
            else
                -- Rembourser si erreur
                ply:addMoney(ConstructionSystem.Config.SaveCost)
                DarkRP.notify(ply, 1, 4, "Erreur sauvegarde : " .. tostring(err))
            end
        end)
    end)
end)

--- Charger un blueprint
net.Receive("Construction_LoadBlueprint", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    -- Rate limit
    if loadCooldowns[ply] and loadCooldowns[ply] > CurTime() then
        DarkRP.notify(ply, 1, 3, "Attends avant de charger !")
        return
    end
    loadCooldowns[ply] = CurTime() + ConstructionSystem.Config.LoadCooldown

    local blueprintId = net.ReadUInt(32)

    -- Vérifier le coût
    if not ply:canAfford(ConstructionSystem.Config.LoadCost) then
        DarkRP.notify(ply, 1, 3, "Pas assez d'argent ! ($" .. ConstructionSystem.Config.LoadCost .. " requis)")
        return
    end

    -- Charger depuis la base
    ConstructionSystem.DB.LoadBlueprint(blueprintId, ply, function(blueprint, err)
        if not blueprint then
            DarkRP.notify(ply, 1, 4, err or "Blueprint introuvable")
            return
        end

        -- Position de spawn : devant le joueur
        local tr = util.TraceLine({
            start = ply:EyePos(),
            endpos = ply:EyePos() + ply:GetAimVector() * 300,
            filter = ply
        })
        local spawnPos = tr.HitPos + Vector(0, 0, 50) -- 50 units au-dessus du sol pour éviter les props ghostés

        -- Retirer l'argent
        ply:addMoney(-ConstructionSystem.Config.LoadCost)

        -- Désérialiser et spawner
        local ok, spawnErr = ConstructionSystem.Blueprints.Deserialize(ply, blueprint.data, spawnPos)
        if not ok then
            ply:addMoney(ConstructionSystem.Config.LoadCost)
            DarkRP.notify(ply, 1, 4, "Erreur chargement : " .. tostring(spawnErr))
        end
    end)
end)

--- Supprimer un blueprint
net.Receive("Construction_DeleteBlueprint", function(len, ply)
    if not IsValid(ply) then return end

    local blueprintId = net.ReadUInt(32)

    ConstructionSystem.DB.DeleteBlueprint(blueprintId, ply, function(success, err)
        if success then
            DarkRP.notify(ply, 0, 3, "Blueprint supprime")
            -- Renvoyer la liste mise à jour
            ConstructionSystem.Blueprints.SendList(ply)
        else
            DarkRP.notify(ply, 1, 3, err or "Erreur suppression")
        end
    end)
end)

--- Demander la liste des blueprints
net.Receive("Construction_RequestBlueprints", function(len, ply)
    if not IsValid(ply) then return end
    ConstructionSystem.Blueprints.SendList(ply)
end)

--- Envoyer la liste des blueprints au client
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

--- Nettoyer les cooldowns quand un joueur quitte
hook.Add("PlayerDisconnected", "Construction_ClearBPCooldowns", function(ply)
    saveCooldowns[ply] = nil
    loadCooldowns[ply] = nil
end)

--- Net: ouvrir le menu (relayed du serveur au client)
net.Receive("Construction_OpenMenu", function(len, ply)
    if not IsValid(ply) then return end
    net.Start("Construction_OpenMenu")
    net.Send(ply)
end)

print("[Construction] Module sv_blueprints chargé")
