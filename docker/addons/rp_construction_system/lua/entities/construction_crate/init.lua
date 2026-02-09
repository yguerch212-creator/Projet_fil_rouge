AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    local preferred = ConstructionSystem.Config.CrateModelPreferred
    local fallback = ConstructionSystem.Config.CrateModel
    local model = util.IsValidModel(preferred) and preferred or fallback

    self:SetModel(model)
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

    -- Track ownership (DarkRP sets CPPIGetOwner after spawn)
    timer.Simple(0.1, function()
        if not IsValid(self) then return end
        local owner = self:CPPIGetOwner and self:CPPIGetOwner()
        if IsValid(owner) then
            self.SID = owner:SteamID64()
        end
    end)
end

---------------------------------------------------------------------------
-- PERMISSIONS : Physgun / Toolgun / Gravgun (via hooks)
---------------------------------------------------------------------------

hook.Add("PhysgunPickup", "Construction_CratePhysgun", function(ply, ent)
    if ent:GetClass() ~= "construction_crate" then return end
    if ent.SID == ply:SteamID64() or ply:IsAdmin() then return true end
    return false
end)

hook.Add("CanTool", "Construction_CrateTool", function(ply, tr, tool)
    if not IsValid(tr.Entity) or tr.Entity:GetClass() ~= "construction_crate" then return end
    local ent = tr.Entity
    if tool == "remover" then
        if ent.SID == ply:SteamID64() or ply:IsAdmin() then return true end
        return false
    end
    return false  -- Pas d'autres tools sur les caisses
end)

hook.Add("GravGunPickupAllowed", "Construction_CrateGravgun", function(ply, ent)
    if ent:GetClass() == "construction_crate" then return true end
end)

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

function ENT:SpawnFunction(ply, tr, ClassName)
    if not tr.Hit then return end
    local ent = ents.Create(ClassName)
    ent:SetPos(tr.HitPos + tr.HitNormal * 20)
    ent.SID = ply:SteamID64()
    ent:Spawn()
    ent:Activate()
    return ent
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
