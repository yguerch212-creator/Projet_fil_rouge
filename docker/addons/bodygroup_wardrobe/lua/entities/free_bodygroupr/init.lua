AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString( "open_freebodygroupr_window" )
util.AddNetworkString( "update_store_freebodygroupr" )

function ENT:Initialize()

	self:SetModel("models/props_c17/FurnitureDresser001a.mdl")
	
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	if ( SERVER ) then self:PhysicsInit( SOLID_VPHYSICS ) end
	local phys = self:GetPhysicsObject()
	if ( IsValid( phys ) ) then phys:Wake() end
	self:SetUseType(SIMPLE_USE)
end

function ENT:Think()

end

function ENT:Use(a, ply)
	net.Start( "open_freebodygroupr_window" )
	net.Send( ply )
end