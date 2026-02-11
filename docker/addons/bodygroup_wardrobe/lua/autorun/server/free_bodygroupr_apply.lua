hook.Add( "PlayerSpawn", "ApplyFreeBodyGroupr", function( ply )

	print( ply:GetNWString( "free_bodygroupr_model" ) )

	timer.Simple( 0.05, function()
		if ply:GetNWString( "free_bodygroupr_model" ) != nil then
			ply:SetModel( ply:GetNWString( "free_bodygroupr_model", ply:GetModel() ) )
		end
		for k,v in pairs( ply:GetBodyGroups() ) do
			ply:SetBodygroup( v.id, ply:GetNWInt( "free_bodygroupr" .. v.id, 0 ) )
			ply:SetSkin( ply:GetNWInt("free_bodygroupr_skin") )
		end
	end )

end )

net.Receive( "update_store_freebodygroupr", function(l, ply) 

	local bg = net.ReadInt( 32 )
	local sg = net.ReadInt( 32 )
	local mod = net.ReadString()
	
	if bg == -5 then
		ply:SetSkin( sg )
		ply:SetNWInt( "free_bodygroupr_skin", sg )
	elseif bg == -10 then
		ply:SetModel( mod )
		ply:SetNWString( "free_bodygroupr_model", mod )
		for k, v in pairs( ply:GetBodyGroups() ) do
			ply:SetBodygroup( v.id, 0 )
			ply:SetNWInt( "free_bodygroupr" .. v.id, 0 )
		end
	else
		ply:SetBodygroup( bg, sg )
		ply:SetNWInt( "free_bodygroupr" .. bg, sg )
	end

end )

hook.Add( "PlayerChangedTeam", "ResetModelDarkRPFUCK", function( ply, old, new )

	ply:SetNWString( "free_bodygroupr_model", nil )

end )