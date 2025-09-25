include("shared.lua")

local function OpenSWBFrame()
    if IsValid(g_SWBFrame) then g_SWBFrame:Close() end

    local f = vgui.Create("DFrame")
    f:SetTitle("Strategic War Board — Prototype")
    f:SetSize(520, 360)
    f:Center()
    f:MakePopup()
    g_SWBFrame = f

    local info = vgui.Create("DLabel", f)
    info:SetText("Prototype: tableau interactif (v0.0.1)\n"+
                 "• Placez l'entité et E pour ouvrir.\n"..
                 "• Ici on mettra la carte, drapeaux, sections, etc.\n"..
                 "• Version seed pour pipeline GitLab (lint & checks).")
    info:SetPos(16, 40)
    info:SizeToContents()

    local btn = vgui.Create("DButton", f)
    btn:SetText("OK")
    btn:SetSize(80, 28)
    btn:SetPos(f:GetWide()-96, f:GetTall()-44)
    btn.DoClick = function() f:Close() end
end

net.Receive("swb_open_ui", OpenSWBFrame)
