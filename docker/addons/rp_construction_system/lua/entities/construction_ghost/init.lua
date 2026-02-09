--[[-----------------------------------------------------------------------
    RP Construction System - Ghost Prop (Server)
    Prop fantôme côté serveur
---------------------------------------------------------------------------]]

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel(self.GhostModel or "models/props_c17/oildrum001.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)         -- Non-solide
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) -- Pas de collision

    -- NetworkVars pour les données du blueprint
    self:SetNWString("ghost_model", self.GhostModel or self:GetModel())
    self:SetNWString("ghost_material", self.GhostMaterial or "")
    self:SetNWInt("ghost_skin", self.GhostSkin or 0)
    self:SetNWString("ghost_blueprint_owner", self.BlueprintOwner or "")
    self:SetNWInt("ghost_blueprint_id", self.BlueprintID or 0)
    self:SetNWString("ghost_group_id", self.GroupID or "")
end

function ENT:SetGhostData(data)
    self.GhostModel = data.Model
    self.GhostMaterial = data.Material or ""
    self.GhostSkin = data.Skin or 0
    self.BlueprintOwner = data.BlueprintOwner or ""
    self.BlueprintID = data.BlueprintID or 0
    self.GroupID = data.GroupID or ""
    self.GhostMass = data.Mass

    self:SetModel(data.Model)
    self:SetNWString("ghost_model", data.Model)
    self:SetNWString("ghost_material", data.Material or "")
    self:SetNWInt("ghost_skin", data.Skin or 0)
    self:SetNWString("ghost_blueprint_owner", data.BlueprintOwner or "")
    self:SetNWInt("ghost_blueprint_id", data.BlueprintID or 0)
    self:SetNWString("ghost_group_id", data.GroupID or "")

    if data.Skin and data.Skin > 0 then
        self:SetSkin(data.Skin)
    end
end

--- Matérialiser ce ghost en vrai prop
function ENT:Materialize(ply)
    if not IsValid(ply) then return nil end

    local ent = ents.Create("prop_physics")
    if not IsValid(ent) then return nil end

    ent:SetModel(self:GetModel())
    ent:SetPos(self:GetPos())
    ent:SetAngles(self:GetAngles())
    ent:Spawn()
    ent:Activate()

    -- Propriétés
    if self.GhostSkin and self.GhostSkin > 0 then
        ent:SetSkin(self.GhostSkin)
    end
    if self.GhostMaterial and self.GhostMaterial ~= "" then
        ent:SetMaterial(self.GhostMaterial)
    end

    -- Physique
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false) -- Frozen par défaut
        if self.GhostMass then
            phys:SetMass(self.GhostMass)
        end
    end

    -- Ownership : le joueur qui matérialise possède le prop
    if ent.CPPISetOwner then
        ent:CPPISetOwner(ply)
    end

    -- Supprimer le ghost
    self:Remove()

    return ent
end

--- Interaction : Use
function ENT:Use(activator, caller)
    -- L'interaction Use sur les ghosts est gérée par sv_ghosts.lua
    -- via un hook global (plus flexible)
end

function ENT:Think()
end
