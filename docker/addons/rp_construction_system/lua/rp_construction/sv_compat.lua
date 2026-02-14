--[[-----------------------------------------------------------------------
    RP Construction System - Compatibilité Gamemode (Server)
    Fournit des wrappers pour fonctionner en DarkRP ET Sandbox
---------------------------------------------------------------------------]]

ConstructionSystem.Compat = ConstructionSystem.Compat or {}

--- Détecte si on est en DarkRP
function ConstructionSystem.Compat.IsDarkRP()
    -- Check multiple indicators since DarkRP table may load late
    if DarkRP ~= nil then return true end
    local gm = engine and engine.ActiveGamemode and engine.ActiveGamemode() or ""
    if gm == "darkrp" or gm == "DarkRP" then return true end
    -- Check if DarkRP gamemode folder exists
    if file.IsDir("gamemodes/darkrp", "GAME") then
        -- Only count as DarkRP if it's the active gamemode
        return GAMEMODE and GAMEMODE.Name and string.lower(GAMEMODE.Name) == "darkrp"
    end
    return false
end

--- Notification universelle (DarkRP.notify fallback → ChatPrint)
--- @param ply Player
--- @param msgType number 0=info, 1=error
--- @param duration number
--- @param text string
function ConstructionSystem.Compat.Notify(ply, msgType, duration, text)
    if not IsValid(ply) then return end

    if DarkRP and DarkRP.notify then
        ConstructionSystem.Compat.Notify(ply, msgType, duration, text)
    else
        local prefix = (msgType == 1) and "[!] " or "[i] "
        ply:ChatPrint(prefix .. text)
    end
end

--- Vérifie si un joueur possède une entité (CPPI → Sandbox → fallback)
function ConstructionSystem.Compat.IsOwner(ply, ent)
    if not IsValid(ent) or not IsValid(ply) then return false end

    -- CPPI (FPP et autres prop protections)
    if ent.CPPIGetOwner then
        local owner = ent:CPPIGetOwner()
        if IsValid(owner) then
            return owner == ply
        end
    end

    -- Sandbox: tout le monde peut toucher ses props (singleplayer = toujours owner)
    if game.SinglePlayer() then return true end

    -- Sandbox multiplayer: check Spawn Flags / Admin
    if ply:IsAdmin() or ply:IsSuperAdmin() then return true end

    -- Dernière tentative : si pas de protection, autoriser
    if not ent.CPPIGetOwner then return true end

    return false
end

--- Vérifie si un joueur peut utiliser le système (job check DarkRP-aware)
function ConstructionSystem.Compat.CanUse(ply)
    if not IsValid(ply) or not ply:Alive() then return false end

    -- En Sandbox ou si AllowedJobs est nil → tout le monde peut
    if not ConstructionSystem.Compat.IsDarkRP() then return true end

    local allowed = ConstructionSystem.Config.AllowedJobs
    if not allowed then return true end

    return table.HasValue(allowed, ply:Team())
end

--- Vérifie si un joueur peut utiliser les caisses
function ConstructionSystem.Compat.CanUseCrate(ply)
    if not IsValid(ply) then return false end

    -- En Sandbox → tout le monde peut
    if not ConstructionSystem.Compat.IsDarkRP() then return true end

    local allowed = ConstructionSystem.Config.CrateAllowedJobs
    if not allowed then return true end

    return table.HasValue(allowed, ply:Team())
end

print("[Construction] Module sv_compat chargé (DarkRP + Sandbox)")
