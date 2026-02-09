--[[-----------------------------------------------------------------------
    RP Construction System - STOOL Sélection
    Outil du Tool Gun pour sélectionner des props
    
    LMB (Left Click)  : Sélectionner/Désélectionner un prop
    RMB (Right Click)  : Sélectionner tous les props dans un rayon
    Reload             : Vider la sélection
---------------------------------------------------------------------------]]

TOOL.Category = "Construction RP"
TOOL.Name = "#tool.construction_select.name"
TOOL.Command = nil
TOOL.ConfigName = ""

-- ConVars
TOOL.ClientConVar["radius"] = "300"

if CLIENT then
    language.Add("tool.construction_select.name", "Blueprint Select")
    language.Add("tool.construction_select.desc", "Selectionner des props pour creer un blueprint")
    language.Add("tool.construction_select.left", "Selectionner / Deselectionner un prop")
    language.Add("tool.construction_select.right", "Selectionner tous les props dans un rayon")
    language.Add("tool.construction_select.reload", "Vider la selection")
end

---------------------------------------------------------------------------
-- LEFT CLICK : Toggle sélection d'un prop
---------------------------------------------------------------------------
function TOOL:LeftClick(trace)
    if not trace.Hit or not IsValid(trace.Entity) then return false end
    if trace.Entity:GetClass() ~= "prop_physics" then return false end

    if CLIENT then return true end

    -- Server-side : toggle la sélection
    local ply = self:GetOwner()
    local ent = trace.Entity

    local ok, err = ConstructionSystem.Selection.Toggle(ply, ent)

    if not ok and err then
        DarkRP.notify(ply, 1, 3, err)
    elseif ok then
        local selected = ConstructionSystem.Selection.IsSelected(ply, ent)
        local count = ConstructionSystem.Selection.Count(ply)
        if selected then
            ply:ChatPrint("[Construction] Prop ajouté (" .. count .. " sélectionnés)")
        else
            ply:ChatPrint("[Construction] Prop retiré (" .. count .. " sélectionnés)")
        end
    end

    return true
end

---------------------------------------------------------------------------
-- RIGHT CLICK : Sélection par rayon
---------------------------------------------------------------------------
function TOOL:RightClick(trace)
    if not trace.Hit then return false end

    if CLIENT then return true end

    local ply = self:GetOwner()
    local radius = math.Clamp(self:GetClientNumber("radius", 300), 50, ConstructionSystem.Config.SelectionRadius)

    local added = ConstructionSystem.Selection.AddInRadius(ply, trace.HitPos, radius)
    local total = ConstructionSystem.Selection.Count(ply)

    DarkRP.notify(ply, 0, 4, added .. " prop(s) ajoutés (" .. total .. " total)")

    return true
end

---------------------------------------------------------------------------
-- RELOAD : Vider la sélection
---------------------------------------------------------------------------
function TOOL:Reload(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    local count = ConstructionSystem.Selection.Count(ply)

    ConstructionSystem.Selection.Clear(ply)

    if count > 0 then
        DarkRP.notify(ply, 0, 3, count .. " prop(s) désélectionnés")
    end

    return true
end

---------------------------------------------------------------------------
-- THINK : Mise à jour continue (utilisé pour le rendu)
---------------------------------------------------------------------------
function TOOL:Think()
end

---------------------------------------------------------------------------
-- PANEL : Options du tool dans le menu de droite
---------------------------------------------------------------------------
function TOOL.BuildCPanel(CPanel)
    CPanel:AddControl("Header", {
        Text = "Blueprint Select",
        Description = "Sélectionnez des props pour créer un blueprint.\nLMB: Select/Deselect | RMB: Zone | R: Clear"
    })

    CPanel:AddControl("Slider", {
        Label = "Rayon de sélection",
        Type = "Integer",
        Min = 50,
        Max = 500,
        Command = "construction_select_radius"
    })

    -- Bouton pour ouvrir le menu blueprints
    local btn = CPanel:AddControl("Button", {
        Label = "Ouvrir le menu Blueprints",
        Command = "construction_open_menu"
    })
end

-- ConCommand pour ouvrir le menu
if CLIENT then
    concommand.Add("construction_open_menu", function()
        net.Start("Construction_OpenMenu")
        net.SendToServer()
    end)
end
