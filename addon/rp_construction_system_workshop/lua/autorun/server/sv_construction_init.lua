--[[-----------------------------------------------------------------------
    RP Construction System - Point d'entrée serveur (Workshop)
    Charge tous les modules dans le bon ordre
---------------------------------------------------------------------------]]

-- 1. Fichier partagé
AddCSLuaFile("rp_construction/sh_config.lua")
include("rp_construction/sh_config.lua")

print("[Construction] ===================================")
print("[Construction] RP Construction System v" .. ConstructionSystem.Config.Version)
print("[Construction] Chargement des modules serveur...")
print("[Construction] ===================================")

-- 2. Enregistrer les net messages
for _, msg in ipairs(ConstructionSystem.NetMessages) do
    util.AddNetworkString(msg)
end
print("[Construction] " .. #ConstructionSystem.NetMessages .. " net messages enregistres")

-- 3. Module logging
include("rp_construction/sv_logging.lua")

-- 4. Module sélection
include("rp_construction/sv_selection.lua")

-- 5. Module ghosts (fantômes)
include("rp_construction/sv_ghosts.lua")

-- 6. Module blueprints (save/load)
include("rp_construction/sv_blueprints.lua")

-- 7. Module permissions & partage
include("rp_construction/sv_permissions.lua")

-- 8. Module sécurité
include("rp_construction/sv_security.lua")

-- 9. Module véhicules (simfphys + LVS + Source)
include("rp_construction/sv_vehicles.lua")

-- 10. Fichiers client à envoyer
AddCSLuaFile("rp_construction/cl_selection.lua")
AddCSLuaFile("rp_construction/cl_ad2_decoder.lua")
AddCSLuaFile("rp_construction/cl_blueprints.lua")
AddCSLuaFile("rp_construction/cl_menu.lua")
AddCSLuaFile("rp_construction/cl_placement.lua")
AddCSLuaFile("rp_construction/cl_vehicles.lua")

-- 11. Configuration des jobs SWEP après chargement DarkRP
hook.Add("loadCustomDarkRPItems", "Construction_SetupJobs", function()
    if TEAM_BUILDER and not ConstructionSystem.Config.SWEPJobs then
        ConstructionSystem.Config.SWEPJobs = {TEAM_BUILDER}
    end

    if not ConstructionSystem.Config.AllowedJobs and ConstructionSystem.Config.SWEPJobs then
        ConstructionSystem.Config.AllowedJobs = ConstructionSystem.Config.SWEPJobs
    end

    if not ConstructionSystem.Config.CrateAllowedJobs and ConstructionSystem.Config.SWEPJobs then
        ConstructionSystem.Config.CrateAllowedJobs = ConstructionSystem.Config.SWEPJobs
    end

    print("[Construction] Jobs SWEP: " .. (ConstructionSystem.Config.SWEPJobs and #ConstructionSystem.Config.SWEPJobs or 0) .. " job(s)")
    print("[Construction] Jobs Caisses: " .. (ConstructionSystem.Config.CrateAllowedJobs and #ConstructionSystem.Config.CrateAllowedJobs or 0) .. " job(s)")
end)

-- 12. Distribution SWEP au changement de job
hook.Add("OnPlayerChangedTeam", "Construction_GiveSWEP", function(ply, oldTeam, newTeam)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end

        if ply:HasWeapon("weapon_construction") then
            ply:StripWeapon("weapon_construction")
        end

        local swepJobs = ConstructionSystem.Config.SWEPJobs
        if swepJobs then
            for _, team in ipairs(swepJobs) do
                if newTeam == team then
                    ply:Give("weapon_construction")
                    break
                end
            end
        end
    end)
end)

-- 13. Distribution SWEP au spawn
hook.Add("PlayerLoadout", "Construction_Loadout", function(ply)
    local swepJobs = ConstructionSystem.Config.SWEPJobs
    if not swepJobs then return end

    for _, team in ipairs(swepJobs) do
        if ply:Team() == team then
            ply:Give("weapon_construction")
            return
        end
    end
end)

print("[Construction] Serveur initialise !")
