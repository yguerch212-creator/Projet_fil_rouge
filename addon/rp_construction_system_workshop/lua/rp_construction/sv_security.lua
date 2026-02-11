--[[-----------------------------------------------------------------------
    RP Construction System - Sécurité & Logging (Server)
    Couche de sécurité additionnelle et monitoring
---------------------------------------------------------------------------]]

ConstructionSystem.Security = ConstructionSystem.Security or {}

---------------------------------------------------------------------------
-- ANTI-ABUSE : Monitoring global des net messages
---------------------------------------------------------------------------

local globalRateLimit = {} -- ply -> {count, resetTime}
local MAX_REQUESTS_PER_MINUTE = 60

--- Vérifie si un joueur dépasse le rate limit global
function ConstructionSystem.Security.CheckGlobalRate(ply)
    if not IsValid(ply) then return false end

    local key = ply:SteamID64()
    local now = CurTime()

    if not globalRateLimit[key] or globalRateLimit[key].resetTime < now then
        globalRateLimit[key] = {count = 0, resetTime = now + 60}
    end

    globalRateLimit[key].count = globalRateLimit[key].count + 1

    if globalRateLimit[key].count > MAX_REQUESTS_PER_MINUTE then
        print("[Construction] RATE LIMIT: " .. ply:Nick() .. " (" .. ply:SteamID() .. ") - " .. globalRateLimit[key].count .. " req/min")
        return false
    end

    return true
end

---------------------------------------------------------------------------
-- HOOK : Restriction du tool par job
---------------------------------------------------------------------------

hook.Add("CanTool", "Construction_RestrictTool", function(ply, tr, toolname)
    if toolname ~= "construction_select" then return end

    local allowed = ConstructionSystem.Config.AllowedJobs
    if allowed then
        if not table.HasValue(allowed, ply:Team()) then
            DarkRP.notify(ply, 1, 3, "Seuls certains jobs peuvent utiliser cet outil !")
            return false
        end
    end
end)

---------------------------------------------------------------------------
-- HOOK : Limiter le nombre de props spawnable via blueprint
---------------------------------------------------------------------------

hook.Add("PlayerSpawnProp", "Construction_PropLimit", function(ply, model)
    -- On laisse le gamemode gérer les limites de base
    -- Ceci est un hook de monitoring
end)

---------------------------------------------------------------------------
-- ADMIN : Commandes (DB désactivée dans la version Workshop)
---------------------------------------------------------------------------

concommand.Add("construction_logs", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("[Construction] Acces refuse - superadmin requis")
        return
    end
    local msg = "[Construction] Logs: base de donnees non disponible dans la version Workshop"
    if IsValid(ply) then ply:ChatPrint(msg) end
    print(msg)
end)

concommand.Add("construction_stats", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local msg = "[Construction] Stats: base de donnees non disponible dans la version Workshop"
    if IsValid(ply) then ply:ChatPrint(msg) end
    print(msg)
end)

---------------------------------------------------------------------------
-- CLEANUP
---------------------------------------------------------------------------

hook.Add("PlayerDisconnected", "Construction_SecurityCleanup", function(ply)
    local key = ply:SteamID64()
    globalRateLimit[key] = nil
end)

print("[Construction] Module sv_security chargé")
