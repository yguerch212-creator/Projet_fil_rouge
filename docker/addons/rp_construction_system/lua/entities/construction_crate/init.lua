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
        phys:SetMass(50)
    end

    self.Materials = ConstructionSystem.Config.CrateMaxMaterials
    self:SetNWInt("materials", self.Materials)
    self:SetNWInt("max_materials", ConstructionSystem.Config.CrateMaxMaterials)
end

---------------------------------------------------------------------------
-- PERMISSIONS : FPP gère via CPPIGetOwner (DarkRP set automatiquement)
-- On ajoute juste PhysgunPickup sur l'entité pour que FPP autorise le proprio
---------------------------------------------------------------------------

hook.Add("PhysgunPickup", "Construction_CratePhysgun", function(ply, ent)
    if ent:GetClass() ~= "construction_crate" then return end
    local owner = ent:CPPIGetOwner()
    if IsValid(owner) and owner == ply then return true end
    if ply:IsAdmin() then return true end
end)

hook.Add("CanTool", "Construction_CrateTool", function(ply, tr, tool)
    if not IsValid(tr.Entity) or tr.Entity:GetClass() ~= "construction_crate" then return end
    local ent = tr.Entity
    local owner = ent:CPPIGetOwner()
    local isOwner = (IsValid(owner) and owner == ply) or ply:IsAdmin()
    if tool == "remover" and isOwner then return true end
    if not isOwner then return false end
end)

hook.Add("GravGunPickupAllowed", "Construction_CrateGravgun", function(ply, ent)
    if ent:GetClass() == "construction_crate" then return true end
end)

---------------------------------------------------------------------------
-- FONCTIONS
---------------------------------------------------------------------------

function ENT:GetRemainingMats()
    return self.Materials or 0
end

function ENT:UseMaterial()
    if self.Materials <= 0 then return false end
    self.Materials = self.Materials - 1
    self:SetNWInt("materials", self.Materials)

    if self.Materials <= 0 then
        timer.Simple(0.5, function()
            if IsValid(self) then self:Remove() end
        end)
    end

    return true
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self.LastUse and self.LastUse > CurTime() then return end
    self.LastUse = CurTime() + 0.5

    if self.Materials <= 0 then
        DarkRP.notify(activator, 1, 3, "Caisse vide !")
        return
    end

    activator.ActiveCrate = self
    activator:SetNWEntity("ActiveCrate", self)
    DarkRP.notify(activator, 0, 4, "Caisse activee ! (" .. self.Materials .. " materiaux) - Visez un fantome + E")
end

function ENT:OnRemove()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.ActiveCrate == self then
            ply.ActiveCrate = nil
            ply:SetNWEntity("ActiveCrate", NULL)
        end
    end
end
