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
AddCSLuaFile("rp_construction/cl_menu.lua")

-- 10. Connexion MySQL
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

print("[Construction] Serveur initialise !")
