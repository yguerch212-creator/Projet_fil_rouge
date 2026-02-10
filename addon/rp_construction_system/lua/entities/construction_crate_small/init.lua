AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel(ConstructionSystem.Config.SmallCrateModel)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(25)
    end

    self.Materials = ConstructionSystem.Config.SmallCrateMaxMaterials
    self:SetNWInt("materials", self.Materials)
    self:SetNWInt("max_materials", ConstructionSystem.Config.SmallCrateMaxMaterials)
end

-- Permissions (même logique que la grosse caisse)
hook.Add("PhysgunPickup", "Construction_SmallCratePhysgun", function(ply, ent)
    if ent:GetClass() ~= "construction_crate_small" then return end
    if ent:GetNWBool("IsLoaded", false) then return false end
    local owner = ent:CPPIGetOwner()
    if IsValid(owner) and owner == ply then return true end
    if ply:IsAdmin() then return true end
end)

hook.Add("CanTool", "Construction_SmallCrateTool", function(ply, tr, tool)
    if not IsValid(tr.Entity) or tr.Entity:GetClass() ~= "construction_crate_small" then return end
    local ent = tr.Entity
    local owner = ent:CPPIGetOwner()
    local isOwner = (IsValid(owner) and owner == ply) or ply:IsAdmin()
    if tool == "remover" and isOwner then return true end
    if not isOwner then return false end
end)

hook.Add("GravGunPickupAllowed", "Construction_SmallCrateGravgun", function(ply, ent)
    if ent:GetClass() ~= "construction_crate_small" then return end
    if ent:GetNWBool("IsLoaded", false) then return false end
    return true
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

function ENT:CanPlayerUse(ply)
    local allowed = ConstructionSystem.Config.CrateAllowedJobs
    if not allowed then return true end
    local team = ply:Team()
    for _, jobId in ipairs(allowed) do
        if team == jobId then return true end
    end
    return false
end

function ENT:LoadOntoVehicle(vehicle)
    if not IsValid(vehicle) then return false end
    if self.LoadedVehicle then return false end

    self.LoadedVehicle = vehicle

    self:PhysicsDestroy()
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    self:SetParent(vehicle)

    local vMins, vMaxs = vehicle:OBBMins(), vehicle:OBBMaxs()
    local cMins, cMaxs = self:OBBMins(), self:OBBMaxs()
    local crateH = cMaxs.z - cMins.z
    local cargoX = vMins.x * 0.6
    local cargoZ = vMaxs.z - crateH - 5

    self:SetLocalPos(Vector(cargoX, 0, cargoZ))
    self:SetLocalAngles(Angle(0, 0, 0))

    -- Visible mais sans collision

    self:SetNWBool("IsLoaded", true)
    self:SetNWEntity("LoadedVehicle", vehicle)

    return true
end

function ENT:UnloadFromVehicle()
    if not self.LoadedVehicle then return false end

    local vehicle = self.LoadedVehicle
    self.LoadedVehicle = nil

    self:SetNWBool("IsLoaded", false)
    self:SetNWEntity("LoadedVehicle", NULL)

    self:SetParent(nil)

    local dropPos
    if IsValid(vehicle) then
        dropPos = vehicle:GetPos() + vehicle:GetRight() * 150 + Vector(0, 0, 50)
    else
        dropPos = self:GetPos() + Vector(0, 0, 50)
    end
    self:SetPos(dropPos)
    self:SetAngles(Angle(0, 0, 0))

    self:SetNoDraw(false)

    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(25)
        phys:EnableMotion(true)
        phys:Wake()
    end

    return true
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self.LastUse and self.LastUse > CurTime() then return end
    self.LastUse = CurTime() + 0.5

    if self:GetNWBool("IsLoaded", false) then return end

    if not self:CanPlayerUse(activator) then
        DarkRP.notify(activator, 1, 3, "Votre metier n'a pas acces aux caisses de materiaux !")
        return
    end

    if self.Materials <= 0 then
        DarkRP.notify(activator, 1, 3, "Caisse vide !")
        return
    end

    activator.ActiveCrate = self
    activator:SetNWEntity("ActiveCrate", self)
    DarkRP.notify(activator, 0, 4, "Petite caisse activee ! (" .. self.Materials .. " materiaux) - Visez un fantome + E")
end

function ENT:OnParented(parent)
    if not IsValid(parent) then return end
    if parent:GetClass() == "gmod_sent_vehicle_fphysics_base" then
        if not self.LoadedVehicle then
            timer.Simple(0, function()
                if not IsValid(self) or not IsValid(parent) then return end
                self:LoadOntoVehicle(parent)
            end)
        end
    end
end

function ENT:OnUnParented(parent)
    if self.LoadedVehicle then
        self.LoadedVehicle = nil
        self:SetNWBool("IsLoaded", false)
        self:SetNWEntity("LoadedVehicle", NULL)
        self:SetNoDraw(false)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetCollisionGroup(COLLISION_GROUP_NONE)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMass(25)
            phys:EnableMotion(true)
            phys:Wake()
        end
    end
end

function ENT:OnRemove()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.ActiveCrate == self then
            ply.ActiveCrate = nil
            ply:SetNWEntity("ActiveCrate", NULL)
        end
    end
end
