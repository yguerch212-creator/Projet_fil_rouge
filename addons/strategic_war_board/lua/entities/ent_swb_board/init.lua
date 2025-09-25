AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_c17/frame002a.mdl") -- cadre/tableau simple
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
end

-- Utilisation: ouvre l’UI côté client (proto)
function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    net.Start("swb_open_ui")
    net.Send(activator)
end
