--[[-----------------------------------------------------------------------
    RP Construction System - Système de Ghosts (Server)
    Gère le spawn des fantômes et leur matérialisation via les caisses
    
    Les ghosts sont SOLID_NONE donc le Use natif ne marche pas.
    On utilise KeyPress + trace pour détecter l'interaction.
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

    -- Spawn en batch
    local entityKeys = table.GetKeys(blueprintData.Entities)
    local index = 0
    local BATCH_SIZE = 5
    local spawnedGhosts = {}

    timer.Create("Construction_GhostSpawn_" .. groupID, 0, 0, function()
        for i = 1, BATCH_SIZE do
            index = index + 1
            if index > #entityKeys then
                timer.Remove("Construction_GhostSpawn_" .. groupID)

                -- Undo : permet au constructeur de retirer les ghosts
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
-- MATÉRIALISATION : KeyPress + Trace (pas Use natif)
---------------------------------------------------------------------------

hook.Add("KeyPress", "Construction_GhostMaterialize", function(ply, key)
    if key ~= IN_USE then return end

    -- Cooldown
    if ply.LastGhostUse and ply.LastGhostUse > CurTime() then return end
    ply.LastGhostUse = CurTime() + 0.3

    -- Trace depuis les yeux du joueur
    local eyePos = ply:EyePos()
    local aimVec = ply:GetAimVector()

    -- Chercher le ghost le plus proche dans la direction du regard
    -- (car les ghosts sont SOLID_NONE, le trace normal ne les touche pas)
    local bestGhost = nil
    local bestDot = 0.98
    local bestDist = 500

    for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
        if IsValid(ent) then
            local toEnt = (ent:GetPos() - eyePos):GetNormalized()
            local dot = aimVec:Dot(toEnt)
            local dist = eyePos:Distance(ent:GetPos())

            if dot > bestDot and dist < bestDist then
                bestDot = dot
                bestDist = dist
                bestGhost = ent
            end
        end
    end

    if not IsValid(bestGhost) then return end

    -- Le joueur doit avoir une caisse active
    local crate = ply.ActiveCrate
    if not IsValid(crate) or crate:GetClass() ~= "construction_crate" then
        DarkRP.notify(ply, 1, 3, "Activez d'abord une caisse (E sur la caisse)")
        ply.ActiveCrate = nil
        return
    end

    -- Vérifier les matériaux
    if crate:GetMaterials() <= 0 then
        DarkRP.notify(ply, 1, 3, "Caisse vide !")
        ply.ActiveCrate = nil
        return
    end

    -- Consommer un matériau
    if not crate:UseMaterial() then return end

    -- Matérialiser (le prop appartient au joueur qui pose)
    local prop = bestGhost:Materialize(ply)

    if IsValid(prop) then
        -- Undo pour le prop matérialisé
        undo.Create("Prop Materialise")
        undo.AddEntity(prop)
        undo.SetPlayer(ply)
        undo.Finish()

        -- Cleanup
        ply:AddCleanup("props", prop)

        local remaining = crate:GetMaterials()
        ply:ChatPrint("[Construction] Prop materialise ! (" .. remaining .. " materiaux restants)")

        -- Mettre à jour le groupe
        local groupID = bestGhost:GetNWString("ghost_group_id", "")
        if ActiveGroups[groupID] then
            ActiveGroups[groupID].materialized = (ActiveGroups[groupID].materialized or 0) + 1

            -- Compter les ghosts restants
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

        -- Log
        if ConstructionSystem.DB and ConstructionSystem.DB.IsConnected() then
            ConstructionSystem.DB.LogAction(ply, "materialize", 0, "ghost", "by " .. ply:Nick())
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
