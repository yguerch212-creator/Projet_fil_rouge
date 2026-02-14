--[[-----------------------------------------------------------------------
    RP Construction System - Initialisation Client
    Compatible DarkRP + Sandbox
---------------------------------------------------------------------------]]

include("rp_construction/sh_config.lua")
include("rp_construction/cl_selection.lua")
include("rp_construction/cl_ad2_decoder.lua")
include("rp_construction/cl_blueprints.lua")
include("rp_construction/cl_menu.lua")
include("rp_construction/cl_placement.lua")
include("rp_construction/cl_vehicles.lua")

---------------------------------------------------------------------------
-- COMMANDES CONSOLE (fonctionnent sans SWEP)
---------------------------------------------------------------------------

-- Ouvrir le menu (déjà défini dans cl_menu.lua mais on s'assure)
if not concommand.GetTable()["construction_menu"] then
    concommand.Add("construction_menu", function()
        ConstructionSystem.Menu.Open()
    end)
end

-- Vider la sélection
concommand.Add("construction_clear", function()
    net.Start("Construction_SelectClear")
    net.SendToServer()
end)

-- Zone select à la position visée
concommand.Add("construction_zone", function(ply, cmd, args)
    local radius = tonumber(args[1]) or ConstructionSystem.ClientRadius or 500
    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end

    net.Start("Construction_SelectRadius")
    net.WriteVector(tr.HitPos)
    net.WriteUInt(math.Clamp(math.Round(radius), 50, 1000), 10)
    net.SendToServer()
end)

-- Select prop visé (toggle)
concommand.Add("construction_select", function(ply)
    local tr = ply:GetEyeTrace()
    if not tr.Hit or not IsValid(tr.Entity) then return end
    if not ConstructionSystem.Config.AllowedClasses[tr.Entity:GetClass()] then return end

    net.Start("Construction_SelectToggle")
    net.WriteUInt(tr.Entity:EntIndex(), 13)
    net.SendToServer()
end)

---------------------------------------------------------------------------
-- CONTEXT MENU (C) — Bouton Construction en haut
---------------------------------------------------------------------------

hook.Add("OnContextMenuOpen", "Construction_ContextBtn", function()
    if IsValid(ConstructionSystem._ctxBtn) then
        ConstructionSystem._ctxBtn:SetVisible(true)
        return
    end

    local btn = vgui.Create("DButton")
    btn:SetText("Construction System")
    btn:SetFont("DermaDefaultBold")
    btn:SetSize(200, 36)
    btn:SetPos(ScrW() / 2 - 100, 10)
    btn:SetTextColor(Color(255, 255, 255))
    btn.Paint = function(self, w, h)
        local bg = self:IsHovered() and Color(59, 130, 246) or Color(30, 30, 40, 220)
        draw.RoundedBox(8, 0, 0, w, h, bg)
        surface.SetDrawColor(59, 130, 246)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    btn.DoClick = function()
        ConstructionSystem.Menu.Open()
        gui.EnableScreenClicker(false)
    end

    ConstructionSystem._ctxBtn = btn
end)

hook.Add("OnContextMenuClose", "Construction_ContextBtn_Hide", function()
    if IsValid(ConstructionSystem._ctxBtn) then
        ConstructionSystem._ctxBtn:SetVisible(false)
    end
end)

print("[Construction] Client initialise - v" .. ConstructionSystem.Config.Version)
print("[Construction] Commandes: construction_menu | construction_select | construction_zone | construction_clear")
