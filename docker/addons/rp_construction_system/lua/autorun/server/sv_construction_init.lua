--[[-----------------------------------------------------------------------
    RP Construction System - Initialisation Serveur
    Point d'entrée principal, charge tous les modules dans le bon ordre
---------------------------------------------------------------------------]]

print("============================================")
print("[Construction] RP Construction System v1.0.0")
print("[Construction] Chargement des modules...")
print("============================================")

-- 1. Configuration partagée (shared)
AddCSLuaFile("rp_construction/sh_config.lua")
include("rp_construction/sh_config.lua")

-- 2. Enregistrer les net messages
for _, netMsg in ipairs(ConstructionSystem.NetMessages) do
    util.AddNetworkString(netMsg)
end
print("[Construction] " .. #ConstructionSystem.NetMessages .. " net messages enregistrés")

-- 3. Module base de données (server only)
include("rp_construction/sv_database.lua")

-- 4. Connexion à MySQL une fois le serveur prêt
hook.Add("InitPostEntity", "Construction_DBConnect", function()
    timer.Simple(5, function()
        print("[Construction] Connexion à MySQL...")
        ConstructionSystem.DB.Connect()
    end)
end)

-- Si le serveur est déjà chargé (hot reload via lua_openscript)
if game.SinglePlayer() or player.GetCount() > 0 then
    timer.Simple(2, function()
        print("[Construction] Hot reload détecté, connexion MySQL...")
        ConstructionSystem.DB.Connect()
    end)
end

print("[Construction] ✅ Initialisation serveur terminée")
