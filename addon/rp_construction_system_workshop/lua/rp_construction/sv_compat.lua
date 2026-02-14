--[[-----------------------------------------------------------------------
    RP Construction System - Compatibilité Gamemode (Server)
    Fournit des wrappers pour fonctionner en DarkRP ET Sandbox
    Pas de détection gamemode — tout est graceful fallback
---------------------------------------------------------------------------]]

ConstructionSystem.Compat = ConstructionSystem.Compat or {}

--- Notification universelle (DarkRP.notify fallback → ChatPrint)
function ConstructionSystem.Compat.Notify(ply, msgType, duration, text)
    if not IsValid(ply) then return end

    if DarkRP and DarkRP.notify then
        DarkRP.notify(ply, msgType, duration, text)
    else
        local prefix = (msgType == 1) and "[!] " or "[i] "
        ply:ChatPrint(prefix .. text)
    end
end

--- Vérifie si un joueur possède une entité
function ConstructionSystem.Compat.IsOwner(ply, ent)
    if not IsValid(ent) or not IsValid(ply) then return false end

    -- CPPI (FPP et autres prop protections)
    if ent.CPPIGetOwner then
        local owner = ent:CPPIGetOwner()
        if IsValid(owner) then
            return owner == ply
        end
    end

    -- Singleplayer = toujours owner
    if game.SinglePlayer() then return true end

    -- Admin/SuperAdmin = toujours owner
    if ply:IsAdmin() or ply:IsSuperAdmin() then return true end

    -- Pas de système de protection → autoriser (Sandbox sans FPP)
    if not ent.CPPIGetOwner then return true end

    return false
end

--- Vérifie si un joueur peut utiliser le système
function ConstructionSystem.Compat.CanUse(ply)
    if not IsValid(ply) or not ply:Alive() then return false end

    local allowed = ConstructionSystem.Config.AllowedJobs
    if not allowed then return true end -- Pas de restriction = tout le monde

    -- Si la table est vide, autoriser aussi
    if #allowed == 0 then return true end

    return table.HasValue(allowed, ply:Team())
end

--- Vérifie si un joueur peut utiliser les caisses
function ConstructionSystem.Compat.CanUseCrate(ply)
    if not IsValid(ply) then return false end

    local allowed = ConstructionSystem.Config.CrateAllowedJobs
    if not allowed then return true end
    if #allowed == 0 then return true end

    return table.HasValue(allowed, ply:Team())
end

print("[Construction] Module sv_compat charge (universel)")
