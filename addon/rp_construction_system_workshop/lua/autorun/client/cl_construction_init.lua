--[[-----------------------------------------------------------------------
    RP Construction System - Initialisation Client
---------------------------------------------------------------------------]]

include("rp_construction/sh_config.lua")
include("rp_construction/cl_selection.lua")
include("rp_construction/cl_ad2_decoder.lua")
include("rp_construction/cl_blueprints.lua")
include("rp_construction/cl_menu.lua")
include("rp_construction/cl_placement.lua")
include("rp_construction/cl_vehicles.lua")

---------------------------------------------------------------------------
-- SPAWNMENU (Q) — Onglet Utilities > Construction RP
---------------------------------------------------------------------------

hook.Add("PopulateToolMenu", "Construction_ToolMenu", function()
    spawnmenu.AddToolMenuOption("Utilities", "Construction RP", "construction_open", "Menu Construction", "", "", function(panel)
        panel:ClearControls()
        panel:Help("RP Construction System v" .. ConstructionSystem.Config.Version)
        panel:Help("")

        panel:Button("Ouvrir le Menu Construction", "construction_menu")
        panel:Button("Vider la selection", "construction_clear")

        panel:Help("")
        panel:Help("=== Raccourcis (Outil de Construction) ===")
        panel:Help("LMB : Selectionner / Deselectionner un prop")
        panel:Help("RMB : Selection par zone (rayon)")
        panel:Help("Shift+RMB : Ouvrir le menu blueprints")
        panel:Help("R : Vider la selection / Decharger caisse")
        panel:Help("Molette : Rotation (placement)")
        panel:Help("Shift+Molette : Hauteur (placement)")
        panel:Help("")
        panel:Help("Console : construction_menu")
    end)
end)

---------------------------------------------------------------------------
-- CONTEXT MENU (C) — Bouton flottant en haut
---------------------------------------------------------------------------

hook.Add("ContextMenuCreated", "Construction_ContextMenu", function()
    -- Le context menu est recréé à chaque session, ce hook se déclenche une fois
end)

-- Ajouter un bouton au context menu quand il s'ouvre
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

---------------------------------------------------------------------------
-- COMMANDE CONSOLE : vider la sélection
---------------------------------------------------------------------------

concommand.Add("construction_clear", function()
    net.Start("Construction_SelectClear")
    net.SendToServer()
end)

print("[Construction] Client initialise - v" .. ConstructionSystem.Config.Version)
