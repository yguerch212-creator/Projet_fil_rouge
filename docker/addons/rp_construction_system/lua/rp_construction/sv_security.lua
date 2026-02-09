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
-- ADMIN : Commande pour voir les logs récents
---------------------------------------------------------------------------

concommand.Add("construction_logs", function(ply, cmd, args)
    -- Seulement pour les superadmins (ou la console)
    if IsValid(ply) and not ply:IsSuperAdmin() then
        ply:ChatPrint("[Construction] Acces refuse - superadmin requis")
        return
    end

    local limit = tonumber(args[1]) or 20

    if not ConstructionSystem.DB.IsConnected() then
        local target = IsValid(ply) and ply or nil
        if target then target:ChatPrint("[Construction] Database non connectee") end
        print("[Construction] Database non connectee")
        return
    end

    local q = ConstructionSystem.DB.GetDB():prepare(
        "SELECT steamid, player_name, action, blueprint_name, details, created_at FROM blueprint_logs ORDER BY created_at DESC LIMIT ?"
    )
    q:setNumber(1, math.Clamp(limit, 1, 100))
    q.onSuccess = function(self, data)
        local output = "\n=== CONSTRUCTION LOGS (last " .. #data .. ") ===\n"
        for _, log in ipairs(data) do
            output = output .. string.format("[%s] %s (%s): %s '%s' %s\n",
                log.created_at or "",
                log.player_name or "",
                log.steamid or "",
                log.action or "",
                log.blueprint_name or "",
                log.details or ""
            )
        end
        output = output .. "=== END LOGS ===\n"

        if IsValid(ply) then
            ply:ChatPrint(output)
        end
        print(output)
    end
    q.onError = function(self, err)
        print("[Construction] Log query error: " .. err)
    end
    q:start()
end)

--- Commande admin : stats
concommand.Add("construction_stats", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    if not ConstructionSystem.DB.IsConnected() then
        print("[Construction] Database non connectee")
        return
    end

    local q = ConstructionSystem.DB.GetDB():query([[
        SELECT
            (SELECT COUNT(*) FROM blueprints) as total_blueprints,
            (SELECT COUNT(DISTINCT owner_steamid) FROM blueprints) as unique_builders,
            (SELECT SUM(prop_count) FROM blueprints) as total_props,
            (SELECT COUNT(*) FROM blueprint_logs) as total_logs,
            (SELECT COUNT(*) FROM blueprint_permissions) as total_shares
    ]])
    q.onSuccess = function(self, data)
        if data and data[1] then
            local s = data[1]
            local output = string.format(
                "\n=== CONSTRUCTION STATS ===\nBlueprints: %s\nBuilders: %s\nTotal props: %s\nLogs: %s\nShares: %s\n========================\n",
                s.total_blueprints or 0, s.unique_builders or 0,
                s.total_props or 0, s.total_logs or 0, s.total_shares or 0
            )
            if IsValid(ply) then ply:ChatPrint(output) end
            print(output)
        end
    end
    q:start()
end)

---------------------------------------------------------------------------
-- CLEANUP
---------------------------------------------------------------------------

hook.Add("PlayerDisconnected", "Construction_SecurityCleanup", function(ply)
    local key = ply:SteamID64()
    globalRateLimit[key] = nil
end)

print("[Construction] Module sv_security chargé")
