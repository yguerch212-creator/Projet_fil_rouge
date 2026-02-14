--[[-----------------------------------------------------------------------
    RP Construction System - Point d'entrée serveur
    Charge tous les modules dans le bon ordre
    Compatible DarkRP + Sandbox (aucune détection gamemode nécessaire)
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

-- 3. Module compatibilité (wrappers Notify, IsOwner, etc.)
include("rp_construction/sv_compat.lua")

-- 4. Module logging
include("rp_construction/sv_logging.lua")

-- 5. Module base de données
include("rp_construction/sv_database.lua")

-- 6. Module sélection
include("rp_construction/sv_selection.lua")

-- 7. Module ghosts (fantômes)
include("rp_construction/sv_ghosts.lua")

-- 8. Module blueprints (save/load)
include("rp_construction/sv_blueprints.lua")

-- 9. Module permissions & partage
include("rp_construction/sv_permissions.lua")

-- 10. Module sécurité
include("rp_construction/sv_security.lua")

-- 11. Module véhicules (simfphys + LVS + Source)
include("rp_construction/sv_vehicles.lua")

-- 12. Fichiers client à envoyer
AddCSLuaFile("rp_construction/cl_selection.lua")
AddCSLuaFile("rp_construction/cl_ad2_decoder.lua")
AddCSLuaFile("rp_construction/cl_blueprints.lua")
AddCSLuaFile("rp_construction/cl_menu.lua")
AddCSLuaFile("rp_construction/cl_placement.lua")
AddCSLuaFile("rp_construction/cl_vehicles.lua")

-- 13. Ressources custom
resource.AddFile("models/weapons/v_fortnite_builder.mdl")
resource.AddFile("models/weapons/v_fortnite_builder.vvd")
resource.AddFile("models/weapons/v_fortnite_builder.dx90.vtx")
resource.AddFile("models/weapons/v_fortnite_builder.sw.vtx")
resource.AddFile("models/weapons/v_fortnite_builder.dx80.vtx")
resource.AddFile("models/weapons/w_fortnite_builder.mdl")
resource.AddFile("models/weapons/w_fortnite_builder.vvd")
resource.AddFile("models/weapons/w_fortnite_builder.phy")
resource.AddFile("models/weapons/w_fortnite_builder.dx90.vtx")
resource.AddFile("models/weapons/w_fortnite_builder.sw.vtx")
resource.AddFile("models/weapons/w_fortnite_builder.dx80.vtx")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_d.vmt")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_d.vtf")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_d_wood.vmt")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_d_wood.vtf")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_d_stone.vmt")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_d_stone.vtf")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_d_metal.vmt")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_d_metal.vtf")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_n.vmt")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_n.vtf")
resource.AddFile("models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl")
resource.AddFile("models/hts/ww2ns/props/dun/dun_wood_crate_03.vvd")
resource.AddFile("models/hts/ww2ns/props/dun/dun_wood_crate_03.phy")
resource.AddFile("models/hts/ww2ns/props/dun/dun_wood_crate_03.dx90.vtx")
resource.AddFile("materials/models/hts/ww2ns/props/dun/dun_wood_crate_01_col.vmt")
resource.AddFile("materials/models/hts/ww2ns/props/dun/dun_wood_crate_01_col.vtf")
resource.AddFile("materials/models/hts/ww2ns/props/dun/dun_wood_crate_01_nml.vtf")
resource.AddFile("models/props_supplies/german/r_crate_pak50mm_stacked.mdl")
resource.AddFile("models/props_supplies/german/r_crate_pak50mm_stacked.vvd")
resource.AddFile("models/props_supplies/german/r_crate_pak50mm_stacked.phy")
resource.AddFile("models/props_supplies/german/r_crate_pak50mm_stacked.dx90.vtx")
resource.AddFile("materials/models/props_supplies/german/r_crate_pak50mm.vmt")
resource.AddFile("materials/models/props_supplies/german/r_crate_pak50mm.vtf")
resource.AddFile("materials/models/props_supplies/german/r_crate_pak50mm_normal.vtf")

---------------------------------------------------------------------------
-- 14. CONNEXION MySQL (graceful — si mysqloo absent, on continue sans)
---------------------------------------------------------------------------

hook.Add("InitPostEntity", "Construction_DBConnect", function()
    timer.Simple(5, function()
        -- Vérifier si mysqloo est disponible AVANT de tenter la connexion
        local ok = pcall(require, "mysqloo")
        if not ok then
            print("[Construction] MySQLOO non disponible - mode hors-ligne (normal en Sandbox)")
            return
        end
        print("[Construction] Connexion a MySQL...")
        ConstructionSystem.DB.Connect()
    end)
end)

timer.Simple(30, function()
    if ConstructionSystem.DB and not ConstructionSystem.DB.IsConnected() then
        local ok = pcall(require, "mysqloo")
        if ok then
            print("[Construction] Connexion MySQL (delayed)...")
            ConstructionSystem.DB.Connect()
        end
    end
end)

---------------------------------------------------------------------------
-- 15. DISTRIBUTION SWEP — fonctionne dans tous les gamemodes
---------------------------------------------------------------------------

-- DarkRP: configurer les jobs après chargement
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
end)

-- DarkRP: changement de job
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

-- Spawn: donner le SWEP selon le contexte
-- Si SWEPJobs est configuré (DarkRP) → vérifier le job
-- Si SWEPJobs est nil (Sandbox ou pas de restriction) → donner à tout le monde
hook.Add("PlayerLoadout", "Construction_Loadout", function(ply)
    local swepJobs = ConstructionSystem.Config.SWEPJobs
    if not swepJobs then
        -- Pas de restriction de job → tout le monde reçoit le SWEP
        ply:Give("weapon_construction")
        return
    end
    for _, team in ipairs(swepJobs) do
        if ply:Team() == team then
            ply:Give("weapon_construction")
            return
        end
    end
end)

print("[Construction] Serveur initialise !")
