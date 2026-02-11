function OpenFreeBodyGrouprMenu()

	local RefreshBodygroups
	local cleanupElements = {}

	local ClosetWindow = vgui.Create( "DFrame" )
	ClosetWindow:SetSize( ScrW() * 0.9, ScrH() * 0.9 )
	ClosetWindow:Center()
	ClosetWindow:SetSize( ScrW() * 0.45, ScrH() * 0.9 )
	ClosetWindow:SetTitle( "" )
	ClosetWindow:MakePopup()
	ClosetWindow:SetDraggable( false )
	ClosetWindow:ShowCloseButton( false )
	function ClosetWindow:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 62, 129, 255 ) )
		draw.RoundedBox( 0, 0, 0, w, 24, Color( 0, 0, 0, 255 ) )
		draw.RoundedBox( 0, 0, h-48, w, 48, Color( 0, 0, 0, 255 ) )
		surface.SetFont( "Trebuchet18" )
		surface.SetTextColor( color_white )
		surface.SetTextPos( 5, h - 46 )
		surface.DrawText( "Rotate: Left click and horizontal drag" )
		surface.SetTextPos( 5, h - 33 )
		surface.DrawText( "Zoom: Left click and vertical drag" )
		surface.SetTextPos( 5, h - 20 )
		surface.DrawText( "Pan: Right click and drag" )
	end
	local cwsizew, cwsizeh = ClosetWindow:GetSize()
	
	local YourModel = vgui.Create( "DModelPanel", ClosetWindow )
	YourModel.CurrFOV = 70
	YourModel.CurrAng = 0
	YourModel.CamX = 0
	YourModel.CamY = 0
	YourModel:SetSize( cwsizew, cwsizeh - 72 )
	YourModel:SetPos( 0, 24 )
	YourModel:SetModel( LocalPlayer():GetModel() )
	function YourModel:Think()
		local pX, pY = self:GetParent():GetPos()
		local thisX, thisY, thisW, thisH = self:GetBounds()
		thisX = thisX + pX
		thisY = thisY + pY
		if gui.MouseX() < thisX or gui.MouseX() > thisX + thisW or gui.MouseY() < thisY or gui.MouseY() > thisY + thisH then
			if self.Rotating and not input.IsMouseDown( MOUSE_LEFT ) then
				self.Rotating = false 
			end
			if self.Panning and not input.IsMouseDown( MOUSE_RIGHT ) then
				self.Panning = false
			end
		end
	end
	function YourModel:LayoutEntity( ent )
		if ( self.bAnimated ) then
			self:RunAnimation()
		end

		local pX, pY = self:GetParent():GetPos()
		local thisX, thisY, thisW, thisH = self:GetBounds()
		thisX = pX + thisX
		thisY = pY + thisY

		if self.Rotating then
			local angDiff = gui.MouseX() - self.InitPos
			self.CurrAng = self.CurrAng + angDiff
			if self.CurrAng >= 360 then
				self.CurrAng = self.CurrAng - 360
			end
			if self.CurrAng < 0 then
				self.CurrAng = self.CurrAng + 360
			end

			local fovDiff = gui.MouseY() - self.InitFOV
			self.CurrFOV = self.CurrFOV + fovDiff
			self.CurrFOV = math.Clamp( self.CurrFOV, 10, 120 )

			self.InitPos = gui.MouseX()
			self.InitFOV = gui.MouseY()
		end

		if self.Panning then
			local xDiff = gui.MouseX() - self.InitCamX
			local yDiff = gui.MouseY() - self.InitCamY

			self.CamX = math.Clamp( self.CamX + gui.MouseX() - self.InitCamX, -80, 80 )
			self.CamY = math.Clamp( self.CamY + gui.MouseY() - self.InitCamY, -120, 120 )

			self.InitCamX = gui.MouseX()
			self.InitCamY = gui.MouseY()
		end

		ent:SetEyeTarget( ent:EyePos() + ent:GetForward() * 500 )
		ent:SetPos( Vector( self.CamX / 2, self.CamX / -2, self.CamY / 2 ) )
		ent:SetAngles( Angle( 0, self.CurrAng, 0 ) )
		self:SetFOV( self.CurrFOV )

	end
	function YourModel:PostDrawModel( ent )
		for k,v in pairs( ent:GetBodyGroups() ) do
			ent:SetBodygroup( k - 1, LocalPlayer():GetBodygroup( k - 1 ) )
		end
	end
	function YourModel:OnMousePressed( key )
		if key == MOUSE_LEFT then
			self.Rotating = true
			self.InitPos = gui.MouseX()
			self.InitFOV = gui.MouseY()
		end
		if key == MOUSE_RIGHT then
			self.Panning = true
			self.InitCamX = gui.MouseX()
			self.InitCamY = gui.MouseY()
		end
	end
	function YourModel:OnMouseReleased( key )
		if key == MOUSE_LEFT then
			self.Rotating = false
		end
		if key == MOUSE_RIGHT then
			self.Panning = false
		end
	end
	
	local TitleLabel = vgui.Create( "DLabel", ClosetWindow )
	TitleLabel:SetText( "Customize Your Appearance" )
	TitleLabel:SetPos( 5, 3 )
	TitleLabel:SetFont( "Trebuchet18" )
	TitleLabel:SizeToContents()
	TitleLabel:SetTextColor( Color( 255, 255, 255 ) )
	-------------------------------------
	local BodyGroupWindow = vgui.Create( "DFrame" )
	BodyGroupWindow:SetSize( ScrW() * 0.45, ScrH() * 0.9 )
	BodyGroupWindow:SetPos( ScrW() * 0.5, ScrH() * 0.05 )
	BodyGroupWindow:SetTitle( "" )
	BodyGroupWindow:MakePopup()
	BodyGroupWindow:SetDraggable( false )
	BodyGroupWindow:ShowCloseButton( false )
	local bgsizew, bgsizeh = BodyGroupWindow:GetSize()
	function BodyGroupWindow:Paint( w, h )
		draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 62, 129, 255 ) )
		draw.RoundedBox( 0, 0, 0, w, 24, Color( 0, 0, 0, 255 ) )
		draw.RoundedBox( 0, 0, h-48, w, 48, Color( 0, 0, 0, 255 ) )
	end
	
	local function ConstructBGString()
		local bodygroups = {}
		for k,v in pairs( LocalPlayer():GetBodyGroups() ) do
			bodygroups[k] = LocalPlayer():GetBodygroup( k - 1 )
		end
		return table.concat( bodygroups )
	end
	
	local ModelLabel
	local ModelCombo

	if DarkRP then
		if type( LocalPlayer():getJobTable().model ) == "table" then
			ModelCombo = vgui.Create( "DComboBox", BodyGroupWindow )
			ModelCombo:SetValue( LocalPlayer():GetModel() )
			ModelCombo:SetPos( bgsizew * 0.01, 32 )
			ModelCombo:SetSize( bgsizew * 0.4, 20 )
			ModelCombo:SetFont( "Trebuchet18" )
			for k,v in pairs( LocalPlayer():getJobTable().model ) do
				ModelCombo:AddChoice( v )
			end
			ModelCombo.OnSelect = function( self, index, value )
				net.Start( "update_store_freebodygroupr" )
					net.WriteInt( -10, 32 )
					net.WriteInt( -10, 32 ) --dude, fuck
					net.WriteString( ModelCombo:GetValue() )
				net.SendToServer()
				function YourModel:PostDrawModel( ent )
					self:SetModel( ModelCombo:GetValue() )
				end
				
				RefreshBodygroups()
			end
		else
			ModelLabel = vgui.Create( "DLabel", BodyGroupWindow )
			ModelLabel:SetText( LocalPlayer():GetModel() )
			ModelLabel:SetPos( bgsizew * 0.01, 32 )
			ModelLabel:SetFont( "Trebuchet18" )
			ModelLabel:SizeToContents()
			ModelLabel:SetTextColor( Color( 255, 255, 255 ) )
		end
	else
		ModelLabel = vgui.Create( "DLabel", BodyGroupWindow )
		ModelLabel:SetText( "Current model: " .. LocalPlayer():GetModel() )
		ModelLabel:SetPos( bgsizew * 0.01, 32 )
		ModelLabel:SetFont( "Trebuchet18" )
		ModelLabel:SizeToContents()
		ModelLabel:SetTextColor( Color( 255, 255, 255 ) )
	end
	
	local CloseButton = vgui.Create( "DButton", BodyGroupWindow )
	CloseButton:SetText( "X" )
	CloseButton:SetSize( 24, 24 )
	CloseButton:SetPos( bgsizew - 24, 0 )
	CloseButton:SetTextColor( Color( 193, 0, 0 ) )
	function CloseButton:DoClick()
		surface.PlaySound( "ui/buttonclick.wav" )
		BodyGroupWindow:Close()
		ClosetWindow:Close()
	end
	function CloseButton:Paint( w, h )
		if CloseButton:IsHovered() then
			draw.RoundedBox( 0, 0, 0, w, h, Color( 96, 0, 0, 255 ) )
			CloseButton:SetTextColor(Color(255,255,255))
		else
			draw.RoundedBox( 0, 0, 0, w, h, Color( 193, 0, 0, 255 ) )
			CloseButton:SetTextColor(Color(0,0,0))
		end
	end
	
	local ModelScroller = vgui.Create( "DScrollPanel", BodyGroupWindow )
	ModelScroller:SetSize( bgsizew, bgsizeh * ( bgsizeh / ( ScrH() * 1.1 ) ) )
	ModelScroller:SetPos( 0, 54 )
	
	--######################################################################
	RefreshBodygroups = function()
		-- clean up shit
		local gridx, gridy = 0, 0
		local labx, laby = 0, 0
		local rows = 0
		for k,v in pairs( cleanupElements ) do
			v:Remove()
		end

		for k,v in pairs( LocalPlayer():GetBodyGroups() ) do
			gridx, gridy = math.max( 0, gridx ), math.max( 0, gridy )
			
			local BGLabel = ModelScroller:Add( "DLabel" )
			BGLabel:SetText( v.id .. ": " .. v.name )
			BGLabel:SizeToContents()
			local buttonSize = bgsizeh * 0.025 --sanity var
			BGLabel:SetPos( bgsizew * 0.025, gridy + ( ( rows * buttonSize ) + ( rows * (bgsizeh * 0.008)  ) ) )
			BGLabel:SetTextColor( Color( 255, 255, 255 ) )
			labx, laby = BGLabel:GetPos()
			
			table.insert( cleanupElements, BGLabel )

			local BGGrid = ModelScroller:Add( "DGrid" )
			BGGrid:SetPos( bgsizew * 0.05, laby + 20 )
			BGGrid:SetSize( bgsizew * 0.8, buttonSize * rows )
			BGGrid:SetCols( 4 )
			BGGrid:SetRowHeight( bgsizeh * 0.03 )
			BGGrid:SetColWide( bgsizew * 0.225 )
			gridx, gridy = BGGrid:GetPos()
			
			table.insert( cleanupElements, BGGrid )
			
			for i=1, v.num do
				local BGButt = ModelScroller:Add( "DButton" )
				BGButt:SetText( i - 1 )
				BGButt:SetSize( bgsizew * 0.225, bgsizeh * 0.025 )
				BGGrid:AddItem( BGButt )
				BGButt.bgparent = k - 1
				BGButt.DoClick = function( self )
					net.Start( "update_store_freebodygroupr" )
						net.WriteInt( self.bgparent, 32 )
						net.WriteInt( self:GetValue(), 32)
					net.SendToServer()
					surface.PlaySound( "garrysmod/ui_click.wav" )
					function YourModel:PostDrawModel( ent )
						local bodygroups = {}
					
						ent:SetBodygroup( BGButt.bgparent, tonumber(BGButt:GetValue()) )
					end
					--[[
					timer.Simple( 0.1, function()
						ModelLabel:SetText( "Current model: " .. LocalPlayer():GetModel() .. " with bodygroups " .. ConstructBGString() .. " and skin " .. LocalPlayer():GetSkin() )
						ModelLabel:SizeToContents()
					end )
					]]
				end
				function BGButt:Paint( w, h )
					if BGButt:IsHovered() then
						draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 96, 0, 255 ) )
						BGButt:SetTextColor(Color(255,255,255))
					else
						draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 193, 0, 255 ) )
						BGButt:SetTextColor(Color(0,0,0))
					end
				end
				table.insert( cleanupElements, BGButt )
			end
			
			rows = math.ceil( v.num / 4 )
			
		end
		
		--skins
		local SLabel = ModelScroller:Add( "DLabel" )
		SLabel:SetText( "Skin" )
		local buttonSize = bgsizeh * 0.025 --sanity var
		SLabel:SetPos( bgsizew * 0.025, math.max(50, gridy) + ( ( rows * buttonSize ) + ( rows * (bgsizeh * 0.008)  ) ) )
		SLabel:SetTextColor( Color( 255, 255, 255 ) )
		labx, laby = SLabel:GetPos()
		table.insert( cleanupElements, SLabel )
		
		local BGGrid = ModelScroller:Add( "DGrid" )
		BGGrid:SetPos( bgsizew * 0.05, laby + 20 )
		BGGrid:SetSize( bgsizew * 0.8, buttonSize * rows )
		BGGrid:SetCols( 4 )
		BGGrid:SetColWide( bgsizew * 0.225 )
		gridx, gridy = BGGrid:GetPos()
		table.insert( cleanupElements, BGGrid )
		
		for i=1, LocalPlayer():SkinCount() do
			local BGButt = ModelScroller:Add( "DButton" )
			BGButt:SetText( i - 1 )
			BGButt:SetSize( bgsizew * 0.225, bgsizeh * 0.025 )
			BGGrid:AddItem( BGButt )
			--BGButt.bgparent = k - 1
			BGButt.DoClick = function( self )
				surface.PlaySound( "garrysmod/ui_click.wav" )
				net.Start( "update_store_freebodygroupr" )
					net.WriteInt( -5, 32 )
					net.WriteInt( self:GetValue(), 32)
				net.SendToServer()
				function YourModel:PostDrawModel( ent )
					ent:SetSkin( tonumber(BGButt:GetValue() ) )
				end
				--[[
				timer.Simple( 0.1, function()
					ModelLabel:SetText( "Current model: " .. LocalPlayer():GetModel() .. " with bodygroups " .. ConstructBGString() .. " and skin " .. LocalPlayer():GetSkin() )
					ModelLabel:SizeToContents()
				end )
				]]
			end
			function BGButt:Paint( w, h )
				if BGButt:IsHovered() then
					draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 96, 0, 255 ) )
					BGButt:SetTextColor(Color(255,255,255))
				else
					draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 193, 0, 255 ) )
					BGButt:SetTextColor(Color(0,0,0))
				end
			end
			table.insert( cleanupElements, BGButt )
		end
		--end skins
	end
	--######################################################################
	
	RefreshBodygroups()

	ClosetWindow.OnClose = function()
		if IsValid(BodyGroupWindow) then BodyGroupWindow:Close() end
	end
	BodyGroupWindow.OnClose = function()
		if IsValid(ClosetWindow) then ClosetWindow:Close() end
	end
	
end

concommand.Add( "bodygroupwardrobe", function()
	if GetConVar( "sv_st_freebodygroupr_remote" ):GetBool() then
		OpenFreeBodyGrouprMenu()
	else
		surface.PlaySound( "buttons/lightswitch2.wav" )
		notification.AddLegacy( "Remote access has been disabled on this server.  Please use a wardrobe.", NOTIFY_ERROR, 4 )
	end
end, nil, "Open the Bodygroup Wardrobe menu." )