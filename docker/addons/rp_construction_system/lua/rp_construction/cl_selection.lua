--[[-----------------------------------------------------------------------
    RP Construction System - Sélection Client
    Gère le rendu visuel (outline) des props sélectionnés
---------------------------------------------------------------------------]]

ConstructionSystem.Selection = ConstructionSystem.Selection or {}

-- Liste des entity index sélectionnés (synced depuis le serveur)
local SelectedEntities = {}

-- Couleurs
local COLOR_SELECTED = Color(0, 150, 255, 255)     -- Bleu
local COLOR_HOVER = Color(255, 200, 0, 255)         -- Jaune (prop sous le curseur)
local COLOR_CANT_SELECT = Color(255, 50, 50, 255)   -- Rouge (pas à toi)

---------------------------------------------------------------------------
-- SYNC DEPUIS LE SERVEUR
---------------------------------------------------------------------------

net.Receive("Construction_SyncSelection", function()
    SelectedEntities = {}

    local count = net.ReadUInt(10)
    for i = 1, count do
        local id = net.ReadUInt(13)
        SelectedEntities[id] = true
    end
end)

--- Vérifier si une entité est sélectionnée
function ConstructionSystem.Selection.IsSelected(ent)
    if not IsValid(ent) then return false end
    return SelectedEntities[ent:EntIndex()] == true
end

--- Nombre de props sélectionnés
function ConstructionSystem.Selection.Count()
    local count = 0
    for id, _ in pairs(SelectedEntities) do
        if IsValid(Entity(id)) then
            count = count + 1
        end
    end
    return count
end

--- Obtenir les entités sélectionnées
function ConstructionSystem.Selection.GetEntities()
    local ents_list = {}
    for id, _ in pairs(SelectedEntities) do
        local ent = Entity(id)
        if IsValid(ent) then
            table.insert(ents_list, ent)
        end
    end
    return ents_list
end

---------------------------------------------------------------------------
-- RENDU VISUEL
---------------------------------------------------------------------------

--- Dessiner un outline autour des props sélectionnés
hook.Add("PostDrawOpaqueRenderables", "Construction_DrawSelection", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Ne dessiner que si le joueur a le tool gun en main
    local wep = ply:GetActiveWeapon()
    local isToolgun = IsValid(wep) and wep:GetClass() == "gmod_tool"

    -- Dessiner les outlines des props sélectionnés
    for id, _ in pairs(SelectedEntities) do
        local ent = Entity(id)
        if IsValid(ent) then
            -- Outline bleu
            render.SetColorMaterial()
            render.SetBlend(0.3)
            ent:DrawModel()
            render.SetBlend(1)

            -- Halo
            local color = COLOR_SELECTED
            halo.Add({ent}, color, 2, 2, 1, true, false)
        end
    end
end)

--- HUD : afficher le nombre de props sélectionnés
hook.Add("HUDPaint", "Construction_SelectionHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Afficher seulement avec le tool gun
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return end

    local count = ConstructionSystem.Selection.Count()
    if count == 0 then return end

    local maxProps = ConstructionSystem.Config.MaxPropsPerBlueprint

    -- Box d'info en bas à droite
    local boxW, boxH = 220, 70
    local boxX = ScrW() - boxW - 20
    local boxY = ScrH() - boxH - 120

    -- Background
    draw.RoundedBox(8, boxX, boxY, boxW, boxH, Color(30, 30, 30, 200))

    -- Titre
    draw.SimpleText("Construction", "DermaDefaultBold", boxX + boxW / 2, boxY + 10, Color(0, 150, 255), TEXT_ALIGN_CENTER)

    -- Compteur
    local countColor = count >= maxProps and Color(255, 50, 50) or Color(200, 200, 200)
    draw.SimpleText("Props: " .. count .. " / " .. maxProps, "DermaDefault", boxX + boxW / 2, boxY + 30, countColor, TEXT_ALIGN_CENTER)

    -- Instructions
    draw.SimpleText("LMB: Select | RMB: Zone | R: Clear", "DermaDefault", boxX + boxW / 2, boxY + 50, Color(150, 150, 150), TEXT_ALIGN_CENTER)
end)

---------------------------------------------------------------------------
-- CROSSHAIR INFO
---------------------------------------------------------------------------

--- Afficher des infos sur le prop sous le curseur
hook.Add("HUDPaint", "Construction_CrosshairInfo", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return end

    -- Trace depuis les yeux du joueur
    local tr = ply:GetEyeTrace()
    if not tr.Hit or not IsValid(tr.Entity) then return end

    local ent = tr.Entity
    if ent:GetClass() ~= "prop_physics" then return end

    local selected = ConstructionSystem.Selection.IsSelected(ent)
    local model = ent:GetModel() or "unknown"
    -- Raccourcir le chemin du modèle
    model = string.match(model, "([^/]+)$") or model

    local text = selected and "[SELECTED] " .. model or model
    local color = selected and COLOR_SELECTED or COLOR_HOVER

    local x, y = ScrW() / 2, ScrH() / 2 + 30
    draw.SimpleTextOutlined(text, "DermaDefault", x, y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
end)

print("[Construction] Module cl_selection chargé")
