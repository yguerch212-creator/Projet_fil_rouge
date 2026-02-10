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

function ENT:CanPlayerUse(ply)
    local allowed = ConstructionSystem.Config.CrateAllowedJobs
    if not allowed then return true end -- nil = tout le monde
    local team = ply:Team()
    for _, jobId in ipairs(allowed) do
        if team == jobId then return true end
    end
    return false
end

function ENT:Use(activator, caller)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self.LastUse and self.LastUse > CurTime() then return end
    self.LastUse = CurTime() + 0.5

    -- Pas d'interaction quand chargée sur un véhicule
    if self:GetNWBool("IsLoaded", false) then return end

    -- Vérification du job
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
-- CHARGEMENT / DÉCHARGEMENT VÉHICULE
---------------------------------------------------------------------------

-- Offsets de placement par modèle de véhicule (LocalPos dans le cargo)
-- Opel Blitz: OBB -133 à +108 X, -46 à +46 Y, 0 à 115 Z
local VehicleCargoOffsets = {
    ["models/codww2blitz.mdl"]         = Vector(-80, 0, 45),
    ["models/codww2blitzammo.mdl"]     = Vector(-80, 0, 45),
    ["models/cckw6x6.mdl"]            = Vector(-80, 0, 45),
    ["models/cckw6x6ammo.mdl"]        = Vector(-80, 0, 45),
}
local DefaultCargoOffset = Vector(-80, 0, 45)

function ENT:LoadOntoVehicle(vehicle)
    if not IsValid(vehicle) then return false end
    if self.LoadedVehicle then return false end

    self.LoadedVehicle = vehicle

    -- Sauvegarder le modèle original pour le respawn
    self._OrigModel = self:GetModel()

    -- 1. Détacher si déjà parenté à autre chose
    local curParent = self:GetParent()
    if IsValid(curParent) and curParent ~= vehicle then
        self:SetParent(nil)
    end

    -- 2. Détruire la physique
    self:PhysicsDestroy()

    -- 3. No-collide
    self:SetSolid(SOLID_NONE)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    -- 4. Attacher au véhicule (si pas déjà)
    if self:GetParent() ~= vehicle then
        self:SetParent(vehicle)
    end

    -- 5. Placement par modèle de véhicule
    local vModel = vehicle:GetModel() or ""
    local offset = VehicleCargoOffsets[vModel] or DefaultCargoOffset
    self:SetLocalPos(offset)
    self:SetLocalAngles(Angle(0, 0, 0))

    -- 5. NW vars
    self:SetNWBool("IsLoaded", true)
    self:SetNWEntity("LoadedVehicle", vehicle)

    return true
end

function ENT:UnloadFromVehicle()
    if not self.LoadedVehicle then return false end

    local vehicle = self.LoadedVehicle
    self.LoadedVehicle = nil

    -- NW vars
    self:SetNWBool("IsLoaded", false)
    self:SetNWEntity("LoadedVehicle", NULL)

    -- Détacher AVANT de recréer la physique
    self:SetParent(nil)

    -- Réapparaître à côté du véhicule
    local dropPos
    if IsValid(vehicle) then
        dropPos = vehicle:GetPos() + vehicle:GetRight() * 150 + Vector(0, 0, 50)
    else
        dropPos = self:GetPos() + Vector(0, 0, 50)
    end
    self:SetPos(dropPos)
    self:SetAngles(Angle(0, 0, 0))

    -- Recréer le modèle + physique from scratch
    self:SetModel(self._OrigModel or ConstructionSystem.Config.CrateModel)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:SetNoDraw(false)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetMass(50)
        phys:EnableMotion(true)
        phys:Wake()
    end

    return true
end

function ENT:OnRemove()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply.ActiveCrate == self then
            ply.ActiveCrate = nil
            ply:SetNWEntity("ActiveCrate", NULL)
        end
    end
end
