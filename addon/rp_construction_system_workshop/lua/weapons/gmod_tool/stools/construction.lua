--[[-----------------------------------------------------------------------
    RP Construction System - STool (Sandbox Tool)
    Intègre le système de construction dans le toolgun Sandbox
    Apparaît dans Q menu > Tools > Construction RP
---------------------------------------------------------------------------]]

TOOL.Category = "Construction RP"
TOOL.Name = "#tool.construction.name"

TOOL.Information = {
    {name = "left"},
    {name = "right"},
    {name = "reload"},
}

TOOL.ClientConVar = {
    ["radius"] = "500",
}

if CLIENT then
    language.Add("tool.construction.name", "Outil de Construction")
    language.Add("tool.construction.desc", "Selectionner des props, sauvegarder et charger des blueprints")
    language.Add("tool.construction.left", "Selectionner / Deselectionner un prop")
    language.Add("tool.construction.right", "Selection par zone (rayon) / Shift: Menu")
    language.Add("tool.construction.reload", "Vider la selection")
    language.Add("tool.construction.0", "LMB: Select | RMB: Zone | Shift+RMB: Menu | R: Clear")
end

-----------------------------------------------------------
-- LEFT CLICK: Toggle select prop
-----------------------------------------------------------
function TOOL:LeftClick(tr)
    if not tr.Hit or not IsValid(tr.Entity) then return false end
    if not ConstructionSystem.Config.AllowedClasses[tr.Entity:GetClass()] then return false end

    if CLIENT then return true end

    local ply = self:GetOwner()
    if not IsValid(ply) then return false end

    ConstructionSystem.Selection.Toggle(ply, tr.Entity)
    return true
end

-----------------------------------------------------------
-- RIGHT CLICK: Zone select / Shift = Menu
-----------------------------------------------------------
function TOOL:RightClick(tr)
    local ply = self:GetOwner()
    if not IsValid(ply) then return false end

    -- Shift+RMB = ouvrir le menu
    if ply:KeyDown(IN_SPEED) then
        if CLIENT then
            ConstructionSystem.Menu.Open()
        end
        return false
    end

    if not tr.Hit then return false end

    if CLIENT then
        local radius = self:GetClientNumber("radius", 500)
        net.Start("Construction_SelectRadius")
        net.WriteVector(tr.HitPos)
        net.WriteUInt(math.Clamp(math.Round(radius), 50, 1000), 10)
        net.SendToServer()
    end

    return true
end

-----------------------------------------------------------
-- RELOAD: Clear selection ou décharger caisse
-----------------------------------------------------------
function TOOL:Reload(tr)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not IsValid(ply) then return false end

    -- Chercher véhicule visé pour décharger
    local hitEnt = tr.Entity
    if IsValid(hitEnt) then
        local vehicle = nil
        local check = hitEnt
        for i = 1, 5 do
            if not IsValid(check) then break end
            if check:GetClass() == "gmod_sent_vehicle_fphysics_base" then
                vehicle = check
                break
            end
            check = check:GetParent()
        end

        if vehicle then
            for _, cls in ipairs({"construction_crate", "construction_crate_small"}) do
                for _, ent in ipairs(ents.FindByClass(cls)) do
                    if ent:GetNWBool("IsLoaded", false) and ent:GetParent() == vehicle then
                        ent:UnloadCrate()
                        ConstructionSystem.Compat.Notify(ply, 0, 4, "Caisse dechargee !")
                        return true
                    end
                end
            end
        end
    end

    -- Pas de véhicule → clear sélection
    ConstructionSystem.Selection.Clear(ply)
    ConstructionSystem.Compat.Notify(ply, 0, 3, "Selection videe")
    return true
end

-----------------------------------------------------------
-- TOOL PANEL (Q menu > Construction RP)
-----------------------------------------------------------
function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", {
        Description = "Systeme de construction RP - Selectionnez des props, sauvegardez des blueprints et construisez !",
    })

    panel:AddControl("Button", {
        Label = "Ouvrir le Menu Blueprints",
        Command = "construction_menu",
    })

    panel:AddControl("Button", {
        Label = "Vider la Selection",
        Command = "construction_clear",
    })

    panel:AddControl("Slider", {
        Label = "Rayon de selection (RMB)",
        Type = "Integer",
        Min = 50,
        Max = 1000,
        Command = "construction_radius",
    })

    panel:AddControl("Header", {
        Description = "\nRaccourcis:\nLMB: Selectionner un prop\nRMB: Selection par zone\nShift+RMB: Menu blueprints\nR: Vider la selection\nMolette: Rotation (placement)\nShift+Molette: Hauteur (placement)",
    })
end

-----------------------------------------------------------
-- HUD
-----------------------------------------------------------
function TOOL:DrawHUD()
    if not CLIENT then return end

    local count = ConstructionSystem.Selection and ConstructionSystem.Selection.Count() or 0
    local maxP = ConstructionSystem.Config.MaxPropsPerBlueprint

    local boxW, boxH = 240, 60
    local boxX = ScrW() - boxW - 20
    local boxY = ScrH() - boxH - 100

    draw.RoundedBox(6, boxX, boxY, boxW, boxH, Color(30, 30, 30, 180))
    draw.SimpleText("Construction", "DermaDefaultBold", boxX + boxW / 2, boxY + 8, Color(0, 150, 255), TEXT_ALIGN_CENTER)

    local col = count >= maxP and Color(255, 50, 50) or Color(200, 200, 200)
    draw.SimpleText("Props: " .. count .. "/" .. maxP, "DermaDefault", boxX + boxW / 2, boxY + 24, col, TEXT_ALIGN_CENTER)

    draw.SimpleText("LMB:Sel | RMB:Zone | Shift+RMB:Menu | R:Clear", "DermaDefault", boxX + boxW / 2, boxY + 40, Color(130, 130, 130), TEXT_ALIGN_CENTER)
end
