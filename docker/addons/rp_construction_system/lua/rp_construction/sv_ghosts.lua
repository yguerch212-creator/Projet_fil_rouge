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

--- Trouver le ghost que le joueur vise (ray vs OBB)
local function FindGhostInSight(ply, maxDist)
    maxDist = maxDist or 500
    local eyePos = ply:EyePos()
    local aimVec = ply:GetAimVector()

    local bestGhost = nil
    local bestDist = maxDist

    for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
        if IsValid(ent) then
            local dist = eyePos:Distance(ent:GetPos())
            if dist < bestDist then
                -- Utiliser IntersectRayWithOBB pour tester si le ray touche la bounding box
                local mins, maxs = ent:GetModelBounds()
                if mins and maxs then
                    -- Agrandir un peu la hitbox pour plus de tolérance
                    mins = mins - Vector(5, 5, 5)
                    maxs = maxs + Vector(5, 5, 5)

                    local hitPos = util.IntersectRayWithOBB(eyePos, aimVec * maxDist, ent:GetPos(), ent:GetAngles(), mins, maxs)

                    if hitPos then
                        local hitDist = eyePos:Distance(hitPos)
                        if hitDist < bestDist then
                            bestDist = hitDist
                            bestGhost = ent
                        end
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

--- Net receiver : le client envoie quand il appuie E en regardant un ghost
net.Receive("Construction_MaterializeGhost", function(len, ply)
    print("[SV_GHOST] Net received from " .. ply:Nick())

    if not IsValid(ply) or not ply:Alive() then
        print("[SV_GHOST] STOP: player invalid or dead")
        return
    end

    -- Cooldown
    if ply.LastGhostUse and ply.LastGhostUse > CurTime() then
        print("[SV_GHOST] STOP: cooldown")
        return
    end
    ply.LastGhostUse = CurTime() + 0.3

    -- Vérifier caisse
    local crate = ply.ActiveCrate
    print("[SV_GHOST] Crate: " .. tostring(crate) .. " valid=" .. tostring(IsValid(crate)))
    if not IsValid(crate) or crate:GetClass() ~= "construction_crate" then
        DarkRP.notify(ply, 1, 3, "Activez d'abord une caisse (E sur la caisse)")
        ply.ActiveCrate = nil
        print("[SV_GHOST] STOP: no valid crate")
        return
    end

    print("[SV_GHOST] Materials: " .. crate:GetMaterials())
    if crate:GetMaterials() <= 0 then
        DarkRP.notify(ply, 1, 3, "Caisse vide !")
        ply.ActiveCrate = nil
        return
    end

    -- Trouver le ghost côté serveur
    local ghost = FindGhostInSight(ply, 300)
    print("[SV_GHOST] FindGhostInSight result: " .. tostring(ghost))

    -- Debug: log all ghosts and OBB test
    local eyePos = ply:EyePos()
    local aimVec = ply:GetAimVector()
    for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
        if IsValid(ent) then
            local mins, maxs = ent:GetModelBounds()
            local dist = eyePos:Distance(ent:GetPos())
            local hitPos = nil
            if mins and maxs then
                hitPos = util.IntersectRayWithOBB(eyePos, aimVec * 300, ent:GetPos(), ent:GetAngles(), mins - Vector(5,5,5), maxs + Vector(5,5,5))
            end
            print("[SV_GHOST]   ghost=" .. tostring(ent) .. " dist=" .. math.floor(dist) .. " hit=" .. tostring(hitPos ~= nil) .. " mins=" .. tostring(mins) .. " maxs=" .. tostring(maxs))
        end
    end

    if not IsValid(ghost) then
        DarkRP.notify(ply, 1, 2, "Aucun fantome en vue (serveur)")
        print("[SV_GHOST] STOP: no ghost in sight (server-side)")
        return
    end

    -- Consommer un matériau
    if not crate:UseMaterial() then
        print("[SV_GHOST] STOP: UseMaterial failed")
        return
    end

    -- Matérialiser
    print("[SV_GHOST] Materializing " .. ghost:GetModel())
    local prop = ghost:Materialize(ply)

    if IsValid(prop) then
        print("[SV_GHOST] SUCCESS: " .. tostring(prop))
        undo.Create("Prop Materialise")
        undo.AddEntity(prop)
        undo.SetPlayer(ply)
        undo.Finish()

        ply:AddCleanup("props", prop)

        local remaining = crate:GetMaterials()
        ply:ChatPrint("[Construction] Prop materialise ! (" .. remaining .. " materiaux restants)")

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
                ActiveGroups[groupID] = nil
            end
        end
    else
        print("[SV_GHOST] FAIL: Materialize returned nil")
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
