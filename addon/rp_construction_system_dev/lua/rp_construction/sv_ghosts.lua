--[[-----------------------------------------------------------------------
    RP Construction System - Système de Ghosts (Server)
---------------------------------------------------------------------------]]

ConstructionSystem.Ghosts = ConstructionSystem.Ghosts or {}

local ActiveGroups = {}
local groupCounter = 0

---------------------------------------------------------------------------
-- SPAWN DES GHOSTS
---------------------------------------------------------------------------

function ConstructionSystem.Ghosts.SpawnFromBlueprint(ply, blueprintData, spawnPos)
    if not IsValid(ply) then return false, "Joueur invalide" end
    if not blueprintData or not blueprintData.Entities then return false, "Donnees corrompues" end

    local propCount = table.Count(blueprintData.Entities)
    if propCount == 0 then return false, "Blueprint vide" end

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
                end
            end
        end
    end)

    return true, groupID
end

---------------------------------------------------------------------------
-- MATÉRIALISATION (via net message du client)
---------------------------------------------------------------------------

net.Receive("Construction_MaterializeGhost", function(len, ply)
    if not IsValid(ply) or not ply:Alive() then return end

    -- Cooldown
    if ply.LastGhostUse and ply.LastGhostUse > CurTime() then return end
    ply.LastGhostUse = CurTime() + 0.5

    -- Caisse
    local crate = ply.ActiveCrate
    if not IsValid(crate) or crate:GetClass() ~= "construction_crate" then
        ply.ActiveCrate = nil
        return
    end

    local mats = crate.Materials or 0
    if mats <= 0 then
        DarkRP.notify(ply, 1, 3, "Caisse vide !")
        ply.ActiveCrate = nil
        return
    end

    -- Trouver le ghost le plus proche dans la direction du joueur
    local eyePos = ply:EyePos()
    local aimVec = ply:GetAimVector()
    local bestGhost = nil
    local bestDist = 300

    for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
        if IsValid(ent) then
            local toEnt = ent:GetPos() - eyePos
            local dist = toEnt:Length()
            if dist < bestDist then
                local dot = aimVec:Dot(toEnt:GetNormalized())
                if dot > 0.85 then
                    bestDist = dist
                    bestGhost = ent
                end
            end
        end
    end

    if not IsValid(bestGhost) then
        DarkRP.notify(ply, 1, 2, "Aucun fantome en vue")
        return
    end

    -- Matérialiser
    crate:UseMaterial()
    local prop = bestGhost:Materialize(ply)

    if IsValid(prop) then
        undo.Create("Prop Materialise")
        undo.AddEntity(prop)
        undo.SetPlayer(ply)
        undo.Finish()
        ply:AddCleanup("props", prop)

        local remaining = crate.Materials or 0
        ply:ChatPrint("[Construction] Prop materialise ! (" .. remaining .. " materiaux restants)")

        -- Groupe
        local groupID = bestGhost:GetNWString("ghost_group_id", "")
        if ActiveGroups[groupID] then
            ActiveGroups[groupID].materialized = (ActiveGroups[groupID].materialized or 0) + 1

            local remainingGhosts = 0
            for _, g in ipairs(ActiveGroups[groupID].ghosts) do
                if IsValid(g) then remainingGhosts = remainingGhosts + 1 end
            end

            if remainingGhosts == 0 then
                for _, p in ipairs(player.GetAll()) do
                    DarkRP.notify(p, 0, 5, "Construction terminee !")
                end
                ActiveGroups[groupID] = nil
            end
        end
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

print("[Construction] Module sv_ghosts charge")
