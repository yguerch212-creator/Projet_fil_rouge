ENT.Type      = "anim"
ENT.Base      = "base_gmodentity"
ENT.PrintName = "Strategic War Board (proto)"
ENT.Author    = "Yanis Guerch"
ENT.Spawnable = true
ENT.Category  = "Strategic War Board"

-- Réseau : identifiant du net channel pour ouvrir l’UI
if SERVER then
    util.AddNetworkString("swb_open_ui")
end
