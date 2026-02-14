-- Admin Setup - Superadmin persistant
-- Ce fichier s'exécute au démarrage du serveur

local SUPERADMINS = {
    ["STEAM_0:0:189623672"] = "superadmin", -- Owner
}

hook.Add("PlayerInitialSpawn", "SetupAdmins", function(ply)
    local steamid = ply:SteamID()
    if SUPERADMINS[steamid] then
        timer.Simple(1, function()
            if IsValid(ply) then
                ply:SetUserGroup(SUPERADMINS[steamid])
                print("[AdminSetup] " .. ply:Nick() .. " -> " .. SUPERADMINS[steamid])
            end
        end)
    end
end)

print("[AdminSetup] Module chargé - " .. table.Count(SUPERADMINS) .. " admin(s) configuré(s)")
