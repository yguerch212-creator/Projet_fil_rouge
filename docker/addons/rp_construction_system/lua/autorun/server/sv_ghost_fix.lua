-- HOTFIX v2: Force materialize le ghost le plus proche
timer.Simple(5, function()
    net.Receive("Construction_MaterializeGhost", function(len, ply)
        if not IsValid(ply) then return end

        local ok, err = pcall(function()
            -- Cooldown
            if ply.LastGhostUse and ply.LastGhostUse > CurTime() then return end
            ply.LastGhostUse = CurTime() + 0.5

            -- Caisse
            local crate = ply.ActiveCrate
            if not IsValid(crate) then
                ply:ChatPrint("[SV] Pas de caisse!")
                return
            end

            if crate:GetMaterials() <= 0 then
                ply:ChatPrint("[SV] Caisse vide!")
                return
            end

            -- Ghost le plus proche (skip OBB, juste distance)
            local eyePos = ply:EyePos()
            local closest = nil
            local closestDist = 300

            for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
                if IsValid(ent) then
                    local d = eyePos:Distance(ent:GetPos())
                    if d < closestDist then
                        closestDist = d
                        closest = ent
                    end
                end
            end

            if not IsValid(closest) then
                ply:ChatPrint("[SV] Pas de ghost proche!")
                return
            end

            -- Matérialiser directement
            crate:UseMaterial()
            local prop = closest:Materialize(ply)

            if IsValid(prop) then
                undo.Create("Prop Materialise")
                undo.AddEntity(prop)
                undo.SetPlayer(ply)
                undo.Finish()
                ply:AddCleanup("props", prop)
                ply:ChatPrint("[SV] OK! " .. crate:GetMaterials() .. " mat restants")
            else
                ply:ChatPrint("[SV] Echec materialize!")
            end
        end)

        if not ok then
            ply:ChatPrint("[SV] ERREUR: " .. tostring(err))
        end
    end)

    print("[Construction] HOTFIX v2 loaded")
end)
