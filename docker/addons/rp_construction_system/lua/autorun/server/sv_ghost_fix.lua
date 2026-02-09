-- HOTFIX: Override net receiver pour Construction_MaterializeGhost
-- Ce fichier force le receiver avec ChatPrint debug

timer.Simple(5, function()
    net.Receive("Construction_MaterializeGhost", function(len, ply)
        if not IsValid(ply) then return end

        ply:ChatPrint("[SV] Net recu! Recherche ghost...")

        -- Cooldown
        if ply.LastGhostUse and ply.LastGhostUse > CurTime() then
            ply:ChatPrint("[SV] Cooldown actif")
            return
        end
        ply.LastGhostUse = CurTime() + 0.3

        -- Caisse
        local crate = ply.ActiveCrate
        if not IsValid(crate) then
            ply:ChatPrint("[SV] Pas de caisse active!")
            return
        end
        ply:ChatPrint("[SV] Caisse OK: " .. crate:GetMaterials() .. " mat")

        if crate:GetMaterials() <= 0 then
            ply:ChatPrint("[SV] Caisse vide!")
            ply.ActiveCrate = nil
            return
        end

        -- Ghost : chercher TOUS les ghosts et trouver le plus proche/visé
        local eyePos = ply:EyePos()
        local aimVec = ply:GetAimVector()
        local bestGhost = nil
        local bestDist = 300

        for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
            if IsValid(ent) then
                local dist = eyePos:Distance(ent:GetPos())
                ply:ChatPrint("[SV] Ghost " .. tostring(ent) .. " dist=" .. math.floor(dist))

                if dist < bestDist then
                    -- Test OBB
                    local mins, maxs = ent:GetModelBounds()
                    if mins and maxs then
                        local hitPos = util.IntersectRayWithOBB(eyePos, aimVec * 300, ent:GetPos(), ent:GetAngles(), mins - Vector(10,10,10), maxs + Vector(10,10,10))
                        ply:ChatPrint("[SV]   OBB hit=" .. tostring(hitPos ~= nil))
                        if hitPos then
                            bestDist = dist
                            bestGhost = ent
                        end
                    end
                end
            end
        end

        if not IsValid(bestGhost) then
            ply:ChatPrint("[SV] Aucun ghost vise cote serveur!")
            -- Fallback : prendre le plus proche
            local closest = nil
            local closestDist = 200
            for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
                if IsValid(ent) then
                    local d = eyePos:Distance(ent:GetPos())
                    if d < closestDist then
                        closestDist = d
                        closest = ent
                    end
                end
            end
            if IsValid(closest) then
                ply:ChatPrint("[SV] Fallback: ghost le plus proche a " .. math.floor(closestDist))
                bestGhost = closest
            else
                ply:ChatPrint("[SV] Aucun ghost dans 200 units!")
                return
            end
        end

        -- Matérialiser
        crate:UseMaterial()
        local prop = bestGhost:Materialize(ply)

        if IsValid(prop) then
            ply:ChatPrint("[SV] MATERIALISE! " .. prop:GetModel() .. " (" .. crate:GetMaterials() .. " mat restants)")

            undo.Create("Prop Materialise")
            undo.AddEntity(prop)
            undo.SetPlayer(ply)
            undo.Finish()

            ply:AddCleanup("props", prop)
        else
            ply:ChatPrint("[SV] ECHEC Materialize!")
        end
    end)

    print("[Construction] HOTFIX sv_ghost_fix.lua loaded - net receiver overridden")
end)
