--[[-----------------------------------------------------------------------
    RP Construction System - Permissions & Partage (Server)
    Gère le partage de blueprints entre joueurs
---------------------------------------------------------------------------]]

ConstructionSystem.Permissions = ConstructionSystem.Permissions or {}

---------------------------------------------------------------------------
-- NET RECEIVERS
---------------------------------------------------------------------------

--- Partager un blueprint
net.Receive("Construction_ShareBlueprint", function(len, ply)
    if not IsValid(ply) then return end

    local blueprintId = net.ReadUInt(32)
    local targetName = net.ReadString()
    local permLevel = net.ReadString()

    -- Validation
    if not blueprintId or blueprintId == 0 then return end
    if not permLevel or (permLevel ~= "view" and permLevel ~= "use" and permLevel ~= "edit") then
        permLevel = "use"
    end

    -- Sanitize
    targetName = string.gsub(string.Trim(targetName), "[^%w%s_%-]", "")
    if #targetName < 1 then
        ConstructionSystem.Compat.Notify(ply, 1, 3, "Nom de joueur invalide")
        return
    end

    -- Vérifier le coût
    if not ply:canAfford(ConstructionSystem.Config.ShareCost) then
        ConstructionSystem.Compat.Notify(ply, 1, 3, "Pas assez d'argent ! ($" .. ConstructionSystem.Config.ShareCost .. " requis)")
        return
    end

    -- Trouver le joueur cible par nom
    local targetPly = nil
    for _, p in ipairs(player.GetAll()) do
        if string.lower(p:Nick()) == string.lower(targetName) or p:SteamID() == targetName then
            targetPly = p
            break
        end
    end

    if not IsValid(targetPly) then
        ConstructionSystem.Compat.Notify(ply, 1, 3, "Joueur '" .. targetName .. "' introuvable (doit etre connecte)")
        return
    end

    if targetPly == ply then
        ConstructionSystem.Compat.Notify(ply, 1, 3, "Tu ne peux pas partager avec toi-meme !")
        return
    end

    -- Partager
    ply:addMoney(-ConstructionSystem.Config.ShareCost)

    ConstructionSystem.DB.ShareBlueprint(blueprintId, ply, targetPly:SteamID(), permLevel, function(success, err)
        if success then
            ConstructionSystem.Compat.Notify(ply, 0, 4, "Blueprint partage avec " .. targetPly:Nick() .. " (" .. permLevel .. ")")
            ConstructionSystem.Compat.Notify(targetPly, 0, 4, ply:Nick() .. " a partage un blueprint avec toi !")
        else
            ply:addMoney(ConstructionSystem.Config.ShareCost)
            ConstructionSystem.Compat.Notify(ply, 1, 3, err or "Erreur de partage")
        end
    end)
end)

print("[Construction] Module sv_permissions chargé")
