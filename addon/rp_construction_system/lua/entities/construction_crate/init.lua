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
-- PERMISSIONS
---------------------------------------------------------------------------

hook.Add("PhysgunPickup", "Construction_CratePhysgun", function(ply, ent)
    if ent:GetClass() ~= "construction_crate" then return end
    if ent:GetNWBool("IsLoaded", false) then return false end
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
    if ent:GetClass() ~= "construction_crate" then return end
    if ent:GetNWBool("IsLoaded", false) then return false end
    return true
end)

---------------------------------------------------------------------------
-- FONCTIONS DE BASE
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

function ENT:CanPlayerUse(ply)
    local allowed = ConstructionSystem.Config.CrateAllowedJobs
    if not allowed then return true end
    for _, jobId in ipairs(allowed) do
        if ply:Team() == jobId then return true end
    end
    return false
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
    DarkRP.notify(activator, 0, 4, "Caisse activee ! (" .. self.Materials .. " materiaux) - Visez un fantome + E")
end

---------------------------------------------------------------------------
-- VÉHICULE : CHARGEMENT / DÉCHARGEMENT
-- Approche simple : pas de PhysicsDestroy/Init, juste toggle solid + parent
---------------------------------------------------------------------------

local CARGO_POS = Vector(-80, 0, 45)

function ENT:LoadCrate()
    local parent = self:GetParent()
    if not IsValid(parent) then return end
    if self:GetNWBool("IsLoaded", false) then return end

    -- Désactiver physique
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:Sleep()
    end

    -- No-collide
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    -- Placer correctement
    self:SetLocalPos(CARGO_POS)
    self:SetLocalAngles(Angle(0, 0, 0))

    -- Marquer comme chargée
    self:SetNWBool("IsLoaded", true)
    self:SetNWEntity("LoadedVehicle", parent)
end

function ENT:UnloadCrate()
    if not self:GetNWBool("IsLoaded", false) then return end

    local vehicle = self:GetParent()
    local savedMats = self.Materials

    -- Reset NW
    self:SetNWBool("IsLoaded", false)
    self:SetNWEntity("LoadedVehicle", NULL)

    -- Détacher
    self:SetParent(nil)

    -- Position à côté du véhicule
    if IsValid(vehicle) then
        self:SetPos(vehicle:GetPos() + vehicle:GetRight() * 150 + Vector(0, 0, 50))
    end
    self:SetAngles(Angle(0, 0, 0))

    -- Réactiver physique
    self:SetSolid(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(true)
        phys:Wake()
    end

    -- Restaurer matériaux (au cas où)
    self.Materials = savedMats
    self:SetNWInt("materials", savedMats)
end

---------------------------------------------------------------------------
-- THINK : détection automatique du parent véhicule
---------------------------------------------------------------------------

function ENT:Think()
    local parent = self:GetParent()

    -- Parentée à un simfphys mais pas encore "loaded" → charger
    if IsValid(parent) and parent:GetClass() == "gmod_sent_vehicle_fphysics_base" then
        if not self:GetNWBool("IsLoaded", false) then
            self:LoadCrate()
        end
    end

    -- Était chargée mais parent disparu → restaurer
    if self:GetNWBool("IsLoaded", false) and not IsValid(self:GetParent()) then
        self:UnloadCrate()
    end

    self:NextThink(CurTime() + 0.5)
    return true
end

---------------------------------------------------------------------------
-- CLEANUP
---------------------------------------------------------------------------

function ENT:OnRemove()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.ActiveCrate == self then
            ply.ActiveCrate = nil
            ply:SetNWEntity("ActiveCrate", NULL)
        end
    end
end
