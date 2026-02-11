--[[-----------------------------------------------------------------------
    RP Construction System - Ghost Prop (Server)
    Prop fantôme non-solide, matérialisable via caisse
---------------------------------------------------------------------------]]

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel(self.GhostModel or "models/props_c17/oildrum001.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)

    self:DrawShadow(false)
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SetColor(Color(100, 180, 255, 100))

    self:SetNWString("ghost_model", self.GhostModel or self:GetModel())
    self:SetNWString("ghost_material", self.GhostMaterial or "")
    self:SetNWInt("ghost_skin", self.GhostSkin or 0)
    self:SetNWString("ghost_blueprint_owner", self.BlueprintOwner or "")
    self:SetNWString("ghost_group_id", self.GroupID or "")
end

function ENT:SetGhostData(data)
    self.GhostModel = data.Model
    self.GhostMaterial = data.Material or ""
    self.GhostSkin = data.Skin or 0
    self.BlueprintOwner = data.BlueprintOwner or ""
    self.GroupID = data.GroupID or ""
    self.GhostMass = data.Mass

    self:SetModel(data.Model)
    self:SetNWString("ghost_model", data.Model)
    self:SetNWString("ghost_material", data.Material or "")
    self:SetNWInt("ghost_skin", data.Skin or 0)
    self:SetNWString("ghost_blueprint_owner", data.BlueprintOwner or "")
    self:SetNWString("ghost_group_id", data.GroupID or "")

    if data.Skin and data.Skin > 0 then
        self:SetSkin(data.Skin)
    end
end

--- Matérialiser : transformer en vrai prop
function ENT:Materialize(ply)
    if not IsValid(ply) then return nil end

    local ent = ents.Create("prop_physics")
    if not IsValid(ent) then return nil end

    ent:SetModel(self:GetModel())
    ent:SetPos(self:GetPos())
    ent:SetAngles(self:GetAngles())
    ent:Spawn()
    ent:Activate()

    if self.GhostSkin and self.GhostSkin > 0 then
        ent:SetSkin(self.GhostSkin)
    end
    if self.GhostMaterial and self.GhostMaterial ~= "" then
        ent:SetMaterial(self.GhostMaterial)
    end

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        if self.GhostMass then phys:SetMass(self.GhostMass) end
    end

    if ent.CPPISetOwner then
        ent:CPPISetOwner(ply)
    end

    self:Remove()
    return ent
end
