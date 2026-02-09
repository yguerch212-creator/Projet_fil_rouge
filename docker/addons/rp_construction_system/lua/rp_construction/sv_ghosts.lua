--[[-----------------------------------------------------------------------
    RP Construction System - Système de Ghosts (Server)
    Gère le spawn des fantômes et leur matérialisation via les caisses
---------------------------------------------------------------------------]]

ConstructionSystem.Ghosts = ConstructionSystem.Ghosts or {}

-- Groupes de ghosts actifs (groupID -> {ghosts})
local ActiveGroups = {}
local groupCounter = 0

---------------------------------------------------------------------------
-- SPAWN DES GHOSTS DEPUIS UN BLUEPRINT
---------------------------------------------------------------------------

--- Spawn les props fantômes d'un blueprint
function ConstructionSystem.Ghosts.SpawnFromBlueprint(ply, blueprintData, spawnPos)
    if not IsValid(ply) then return false, "Joueur invalide" end
    if not blueprintData or not blueprintData.Entities then return false, "Donnees corrompues" end

    local propCount = table.Count(blueprintData.Entities)
    if propCount == 0 then return false, "Blueprint vide" end

    -- Créer un groupe unique
    groupCounter = groupCounter + 1
    local groupID = ply:SteamID64() .. "_" .. groupCounter .. "_" .. os.time()

    ActiveGroups[groupID] = {
        owner = ply:SteamID64(),
        ownerName = ply:Nick(),
        ghosts = {},
        totalProps = propCount,
        materialized = 0,
    }

    -- Spawn les ghosts en batch
    local entityKeys = table.GetKeys(blueprintData.Entities)
    local index = 0
    local BATCH_SIZE = 5

    timer.Create("Construction_GhostSpawn_" .. groupID, 0, 0, function()
        for i = 1, BATCH_SIZE do
            index = index + 1
            if index > #entityKeys then
                timer.Remove("Construction_GhostSpawn_" .. groupID)
                DarkRP.notify(ply, 0, 5, "Blueprint charge en fantome : " .. propCount .. " props")
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
                        BlueprintID = 0,
                        GroupID = groupID,
                    })

                    ghost:Spawn()
                    ghost:Activate()

                    table.insert(ActiveGroups[groupID].ghosts, ghost)
                end
            end
        end
    end)

    return true, groupID
end

---------------------------------------------------------------------------
-- MATÉRIALISATION VIA USE
---------------------------------------------------------------------------

--- Hook global : quand un joueur Use un ghost
hook.Add("PlayerUse", "Construction_MaterializeGhost", function(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return end
    if ent:GetClass() ~= "construction_ghost" then return end

    -- Cooldown anti-spam
    if ply.LastGhostUse and ply.LastGhostUse > CurTime() then return end
    ply.LastGhostUse = CurTime() + 0.3

    -- Le joueur doit avoir une caisse active
    local crate = ply.ActiveCrate
    if not IsValid(crate) or crate:GetClass() ~= "construction_crate" then
        DarkRP.notify(ply, 1, 3, "Activez d'abord une caisse de materiaux (E sur la caisse)")
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
    if not crate:UseMaterial() then
        DarkRP.notify(ply, 1, 3, "Erreur materiaux")
        return
    end

    -- Matérialiser le ghost → vrai prop (le joueur qui pose en est le propriétaire)
    local prop = ent:Materialize(ply)

    if IsValid(prop) then
        -- Mettre à jour le groupe
        local groupID = ent:GetNWString("ghost_group_id", "")
        if ActiveGroups[groupID] then
            ActiveGroups[groupID].materialized = ActiveGroups[groupID].materialized + 1

            -- Vérifier si tout le groupe est matérialisé
            local remaining = 0
            for _, g in ipairs(ActiveGroups[groupID].ghosts) do
                if IsValid(g) then remaining = remaining + 1 end
            end

            if remaining == 0 then
                -- Blueprint entièrement construit !
                for _, p in ipairs(player.GetAll()) do
                    DarkRP.notify(p, 0, 5, "Construction terminee par " .. ply:Nick() .. " !")
                end
                ActiveGroups[groupID] = nil
            end
        end

        local remaining = crate:GetMaterials()
        ply:ChatPrint("[Construction] Prop materialise ! (" .. remaining .. " materiaux restants)")

        -- Log
        if ConstructionSystem.DB and ConstructionSystem.DB.IsConnected() then
            ConstructionSystem.DB.LogAction(ply, "materialize", 0, "ghost", "materialized by " .. ply:Nick())
        end
    end
end)

---------------------------------------------------------------------------
-- NETTOYAGE
---------------------------------------------------------------------------

--- Supprimer tous les ghosts d'un groupe
function ConstructionSystem.Ghosts.RemoveGroup(groupID)
    if not ActiveGroups[groupID] then return end

    for _, ghost in ipairs(ActiveGroups[groupID].ghosts) do
        if IsValid(ghost) then
            ghost:Remove()
        end
    end

    ActiveGroups[groupID] = nil
end

--- Nettoyer quand un joueur quitte (optionnel : garder les ghosts)
hook.Add("PlayerDisconnected", "Construction_GhostCleanup", function(ply)
    ply.ActiveCrate = nil
    -- On ne supprime PAS les ghosts quand le constructeur part
    -- D'autres joueurs peuvent encore les matérialiser
end)

print("[Construction] Module sv_ghosts charge")
