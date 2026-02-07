-- Initialisation serveur
print("[Construction] Loading server files...")
include("construction/shared/sh_config.lua")
AddCSLuaFile("construction/shared/sh_config.lua")
include("construction/server/sv_database.lua")
print("[Construction] Server loaded")
