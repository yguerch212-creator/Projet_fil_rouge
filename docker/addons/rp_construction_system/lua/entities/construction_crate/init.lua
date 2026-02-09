--[[-----------------------------------------------------------------------
    RP Construction System - Caisse de Matériaux (Server)
    Contient X matériaux pour matérialiser des props fantômes
    
    Flow:
    1. Joueur Use sur la caisse → il "prend" la caisse (lié au joueur)
    2. Joueur Use sur un ghost → le ghost se matérialise, -1 matériau
---------------------------------------------------------------------------]]

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel(ConstructionSystem.Config.CrateModel)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
    end

    -- Matériaux restants
    self.Materials = ConstructionSystem.Config.CrateMaxMaterials
    self:SetNWInt("materials", self.Materials)
    self:SetNWInt("max_materials", ConstructionSystem.Config.CrateMaxMaterials)
end

function ENT:GetMaterials()
    return self.Materials or 0
end

function ENT:UseMaterial()
    if self.Materials <= 0 then return false end
    self.Materials = self.Materials - 1
    self:SetNWInt("materials", self.Materials)

    -- Supprimer la caisse si vide
    if self.Materials <= 0 then
        timer.Simple(0.5, function()
            if IsValid(self) then
                self:Remove()
            end
        end)
    end

    return true
end

--- Interaction Use : le joueur prend/active la caisse
function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end

    -- Cooldown anti-spam
    if self.LastUse and self.LastUse > CurTime() then return end
    self.LastUse = CurTime() + 0.5

    if self.Materials <= 0 then
        DarkRP.notify(activator, 1, 3, "Caisse vide !")
        return
    end

    -- Lier le joueur à cette caisse
    activator.ActiveCrate = self

    DarkRP.notify(activator, 0, 4, "Caisse activee ! (" .. self.Materials .. " materiaux) - Appuyez E sur un prop fantome")
    activator:ChatPrint("[Construction] Caisse activee avec " .. self.Materials .. " materiaux. Visez un prop fantome et appuyez E.")
end

function ENT:OnRemove()
    -- Délier tous les joueurs qui avaient cette caisse
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.ActiveCrate == self then
            ply.ActiveCrate = nil
        end
    end
end
