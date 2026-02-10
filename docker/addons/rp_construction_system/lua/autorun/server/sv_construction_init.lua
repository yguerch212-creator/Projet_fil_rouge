--[[-----------------------------------------------------------------------
    RP Construction System - Point d'entrée serveur
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

-- 3. Module logging (en premier pour que les autres modules l'utilisent)
include("rp_construction/sv_logging.lua")

-- 4. Module base de données
include("rp_construction/sv_database.lua")

-- 4. Module sélection
include("rp_construction/sv_selection.lua")

-- 5. Module ghosts (fantômes)
include("rp_construction/sv_ghosts.lua")

-- 6. Module blueprints (save/load)
include("rp_construction/sv_blueprints.lua")

-- 7. Module permissions & partage
include("rp_construction/sv_permissions.lua")

-- 8. Module sécurité & logging
include("rp_construction/sv_security.lua")

-- 9. Fichiers client à envoyer
AddCSLuaFile("rp_construction/cl_selection.lua")
AddCSLuaFile("rp_construction/cl_ad2_decoder.lua")
AddCSLuaFile("rp_construction/cl_blueprints.lua")
AddCSLuaFile("rp_construction/cl_menu.lua")
AddCSLuaFile("rp_construction/cl_placement.lua")

-- 10. Ressources custom (modèles/textures à télécharger par le client)
-- SWEP blueprint model (attaché via SCK sur le viewmodel)
resource.AddFile("models/fortnitea31/weapons/misc/blueprint_pencil.mdl")
resource.AddFile("models/fortnitea31/weapons/misc/blueprint_pencil.vvd")
resource.AddFile("models/fortnitea31/weapons/misc/blueprint_pencil.phy")
resource.AddFile("models/fortnitea31/weapons/misc/blueprint_pencil.dx90.vtx")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_d.vmt")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_d.vtf")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_n.vmt")
resource.AddFile("materials/models/fortnitea31/weapons/misc/t_architecttools_n.vtf")
-- Caisse modèle + textures
resource.AddFile("models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl")
resource.AddFile("models/hts/ww2ns/props/dun/dun_wood_crate_03.vvd")
resource.AddFile("models/hts/ww2ns/props/dun/dun_wood_crate_03.phy")
resource.AddFile("models/hts/ww2ns/props/dun/dun_wood_crate_03.dx90.vtx")
resource.AddFile("materials/models/hts/ww2ns/props/dun/dun_wood_crate_01_col.vmt")
resource.AddFile("materials/models/hts/ww2ns/props/dun/dun_wood_crate_01_col.vtf")
resource.AddFile("materials/models/hts/ww2ns/props/dun/dun_wood_crate_01_nml.vtf")

-- 11. Connexion MySQL
hook.Add("InitPostEntity", "Construction_DBConnect", function()
    timer.Simple(5, function()
        print("[Construction] Connexion a MySQL...")
        ConstructionSystem.DB.Connect()
    end)
end)

-- Fallback : si InitPostEntity déjà passé (restart container)
timer.Simple(30, function()
    if not ConstructionSystem.DB.IsConnected() then
        print("[Construction] Connexion MySQL (delayed)...")
        ConstructionSystem.DB.Connect()
    end
end)

-- 11. Configuration des jobs SWEP après chargement DarkRP
hook.Add("loadCustomDarkRPItems", "Construction_SetupJobs", function()
    -- Configure les jobs qui reçoivent le SWEP automatiquement
    -- Par défaut: TEAM_BUILDER si il existe
    if TEAM_BUILDER and not ConstructionSystem.Config.SWEPJobs then
        ConstructionSystem.Config.SWEPJobs = {TEAM_BUILDER}
    end

    -- Configure les jobs autorisés (même liste par défaut)
    if not ConstructionSystem.Config.AllowedJobs and ConstructionSystem.Config.SWEPJobs then
        ConstructionSystem.Config.AllowedJobs = ConstructionSystem.Config.SWEPJobs
    end

    print("[Construction] Jobs SWEP: " .. (ConstructionSystem.Config.SWEPJobs and #ConstructionSystem.Config.SWEPJobs or 0) .. " job(s)")
end)

-- 12. Distribution SWEP au changement de job
hook.Add("OnPlayerChangedTeam", "Construction_GiveSWEP", function(ply, oldTeam, newTeam)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end

        -- Retirer le SWEP si l'ancien job l'avait
        if ply:HasWeapon("weapon_construction") then
            ply:StripWeapon("weapon_construction")
        end

        -- Donner si le nouveau job est dans la liste
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
