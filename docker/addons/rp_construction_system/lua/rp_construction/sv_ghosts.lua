--[[-----------------------------------------------------------------------
    RP Construction System - Système de Ghosts (Server)
    Gère le spawn des fantômes et leur matérialisation via les caisses
---------------------------------------------------------------------------]]

ConstructionSystem.Ghosts = ConstructionSystem.Ghosts or {}

local ActiveGroups = {}
local groupCounter = 0

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

--- Trouver le ghost le plus proche dans la direction du regard
local function FindGhostInSight(ply, maxDist)
    maxDist = maxDist or 500
    local eyePos = ply:EyePos()
    local aimVec = ply:GetAimVector()

    local bestGhost = nil
    local bestScore = 0

    for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
        if IsValid(ent) then
            local entPos = ent:GetPos()
            local toEnt = entPos - eyePos
            local dist = toEnt:Length()

            if dist < maxDist then
                local dir = toEnt:GetNormalized()
                local dot = aimVec:Dot(dir)

                -- Plus le ghost est proche et aligné, meilleur le score
                -- dot > 0.95 = ~18 degrés de tolérance
                if dot > 0.95 then
                    local score = dot * (1 - dist / maxDist)
                    if score > bestScore then
                        bestScore = score
                        bestGhost = ent
                    end
                end
            end
        end
    end

    return bestGhost
end

---------------------------------------------------------------------------
-- SPAWN DES GHOSTS
---------------------------------------------------------------------------

function ConstructionSystem.Ghosts.SpawnFromBlueprint(ply, blueprintData, spawnPos)
    if not IsValid(ply) then return false, "Joueur invalide" end
    if not blueprintData or not blueprintData.Entities then return false, "Donnees corrompues" end

    local propCount = table.Count(blueprintData.Entities)
    if propCount == 0 then return false, "Blueprint vide" end

    ConstructionSystem.Log.Info("SpawnGhosts: " .. ply:Nick() .. " charge " .. propCount .. " ghosts a " .. tostring(spawnPos))

    groupCounter = groupCounter + 1
    local groupID = ply:SteamID64() .. "_" .. groupCounter .. "_" .. os.time()

    ActiveGroups[groupID] = {
        owner = ply:SteamID64(),
        ownerName = ply:Nick(),
        ghosts = {},
        totalProps = propCount,
        materialized = 0,
    }

    local entityKeys = table.GetKeys(blueprintData.Entities)
    local index = 0
    local BATCH_SIZE = 5
    local spawnedGhosts = {}

    timer.Create("Construction_GhostSpawn_" .. groupID, 0, 0, function()
        for i = 1, BATCH_SIZE do
            index = index + 1
            if index > #entityKeys then
                timer.Remove("Construction_GhostSpawn_" .. groupID)

                if IsValid(ply) then
                    undo.Create("Blueprint Fantome")
                    for _, ghost in ipairs(spawnedGhosts) do
                        if IsValid(ghost) then
                            undo.AddEntity(ghost)
                        end
                    end
                    undo.SetPlayer(ply)
                    undo.SetCustomUndoText("Undone Blueprint Fantome (" .. propCount .. " props)")
                    undo.Finish()
                end

                ConstructionSystem.Log.Info("SpawnGhosts: " .. propCount .. " ghosts spawnes (groupe " .. groupID .. ")")
                DarkRP.notify(ply, 0, 5, "Blueprint fantome charge : " .. propCount .. " props")
                return
            end

            local key = entityKeys[index]
            local entData = blueprintData.Entities[key]

            if entData and entData.Model then
                local ghost = ents.Create("construction_ghost")
                if IsValid(ghost) then
                    ghost:SetPos(spawnPos + (entData.Pos or Vector(0, 0, 0)))
                    ghost:SetAngles(entData.Ang or Angle(0, 0, 0))

                    ghost:SetGhostData({
                        Model = entData.Model,
                        Material = entData.Material,
                        Skin = entData.Skin,
                        Mass = entData.Mass,
                        BlueprintOwner = ply:Nick(),
                        GroupID = groupID,
                    })

                    ghost:Spawn()
                    ghost:Activate()

                    table.insert(ActiveGroups[groupID].ghosts, ghost)
                    table.insert(spawnedGhosts, ghost)

                    ConstructionSystem.Log.Debug("Ghost spawne: " .. entData.Model .. " a " .. tostring(ghost:GetPos()))
                else
                    ConstructionSystem.Log.Error("Echec creation ghost pour " .. entData.Model)
                end
            end
        end
    end)

    return true, groupID
end

---------------------------------------------------------------------------
-- MATÉRIALISATION : KeyPress + FindGhostInSight
---------------------------------------------------------------------------

hook.Add("KeyPress", "Construction_GhostMaterialize", function(ply, key)
    if key ~= IN_USE then return end

    -- Cooldown
    if ply.LastGhostUse and ply.LastGhostUse > CurTime() then return end

    -- D'abord, vérifier si le joueur regarde un ghost
    local ghost = FindGhostInSight(ply, 500)

    if not IsValid(ghost) then
        -- Pas de ghost en vue, laisser le Use normal se produire (caisse, etc.)
        return
    end

    -- Ghost trouvé ! Appliquer le cooldown
    ply.LastGhostUse = CurTime() + 0.5

    ConstructionSystem.Log.Debug("Ghost vise par " .. ply:Nick() .. ": " .. tostring(ghost) .. " a " .. tostring(ghost:GetPos()))

    -- Le joueur doit avoir une caisse active
    local crate = ply.ActiveCrate
    if not IsValid(crate) or crate:GetClass() ~= "construction_crate" then
        DarkRP.notify(ply, 1, 3, "Activez d'abord une caisse (E sur la caisse)")
        ply.ActiveCrate = nil
        ConstructionSystem.Log.Debug("Pas de caisse active pour " .. ply:Nick())
        return
    end

    if crate:GetMaterials() <= 0 then
        DarkRP.notify(ply, 1, 3, "Caisse vide !")
        ply.ActiveCrate = nil
        return
    end

    -- Consommer un matériau
    if not crate:UseMaterial() then
        ConstructionSystem.Log.Error("Echec UseMaterial pour " .. ply:Nick())
        return
    end

    ConstructionSystem.Log.Info("Materialise: " .. ply:Nick() .. " materialise " .. ghost:GetModel() .. " (caisse: " .. crate:GetMaterials() .. " restants)")

    -- Matérialiser
    local prop = ghost:Materialize(ply)

    if IsValid(prop) then
        undo.Create("Prop Materialise")
        undo.AddEntity(prop)
        undo.SetPlayer(ply)
        undo.Finish()

        ply:AddCleanup("props", prop)

        local remaining = crate:GetMaterials()
        ply:ChatPrint("[Construction] Prop materialise ! (" .. remaining .. " materiaux restants)")

        -- Groupe
        local groupID = ghost:GetNWString("ghost_group_id", "")
        if ActiveGroups[groupID] then
            ActiveGroups[groupID].materialized = (ActiveGroups[groupID].materialized or 0) + 1

            local remaining_ghosts = 0
            for _, g in ipairs(ActiveGroups[groupID].ghosts) do
                if IsValid(g) then remaining_ghosts = remaining_ghosts + 1 end
            end

            if remaining_ghosts == 0 then
                for _, p in ipairs(player.GetAll()) do
                    DarkRP.notify(p, 0, 5, "Construction terminee !")
                end
                ConstructionSystem.Log.Info("Groupe " .. groupID .. " entierement materialise !")
                ActiveGroups[groupID] = nil
            end
        end
    else
        ConstructionSystem.Log.Error("Echec Materialize pour ghost " .. tostring(ghost))
    end
end)

---------------------------------------------------------------------------
-- NETTOYAGE
---------------------------------------------------------------------------

function ConstructionSystem.Ghosts.RemoveGroup(groupID)
    if not ActiveGroups[groupID] then return end
    for _, ghost in ipairs(ActiveGroups[groupID].ghosts) do
        if IsValid(ghost) then ghost:Remove() end
    end
    ActiveGroups[groupID] = nil
end

hook.Add("PlayerDisconnected", "Construction_GhostCleanup", function(ply)
    ply.ActiveCrate = nil
end)

ConstructionSystem.Log.Info("Module sv_ghosts charge")
