--[[-----------------------------------------------------------------------
    RP Construction System - Ghost Prop (Client)
    Rendu transparent bleuté des props fantômes
---------------------------------------------------------------------------]]

include("shared.lua")

local GHOST_COLOR = Color(50, 150, 255, 80)       -- Bleu transparent
local GHOST_COLOR_HOVER = Color(50, 255, 100, 120) -- Vert quand visé

function ENT:Initialize()
    self.CreatedAt = CurTime()
end

function ENT:Draw()
    -- Pas de DrawModel classique, on dessine nous-mêmes en transparent
end

function ENT:DrawTranslucent()
    local ply = LocalPlayer()
    local isLooking = false

    -- Vérifier si le joueur regarde ce ghost
    if IsValid(ply) then
        local tr = ply:GetEyeTrace()
        if tr.Entity == self then
            isLooking = true
        end
    end

    -- Couleur selon si le joueur regarde ou non
    local col = isLooking and GHOST_COLOR_HOVER or GHOST_COLOR

    -- Effet de pulsation légère
    local pulse = math.sin(CurTime() * 2 + self:EntIndex()) * 10
    col = Color(col.r, col.g, col.b, col.a + pulse)

    render.SetColorMaterial()
    render.SetBlend(col.a / 255)
    self:SetColor(Color(col.r, col.g, col.b, 255))

    -- Material du ghost
    local mat = self:GetNWString("ghost_material", "")
    if mat ~= "" then
        self:SetMaterial(mat)
    else
        self:SetMaterial("models/wireframe")
    end

    self:DrawModel()

    render.SetBlend(1)

    -- Halo
    if isLooking then
        halo.Add({self}, Color(50, 255, 100), 3, 3, 1, true, false)
    else
        halo.Add({self}, Color(50, 150, 255), 1, 1, 1, true, false)
    end
end

--- HUD info quand le joueur regarde un ghost
hook.Add("HUDPaint", "Construction_GhostInfo", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    if not IsValid(tr.Entity) or tr.Entity:GetClass() ~= "construction_ghost" then return end

    local ghost = tr.Entity
    local owner = ghost:GetNWString("ghost_blueprint_owner", "Inconnu")
    local model = string.match(ghost:GetModel() or "", "([^/]+)$") or "?"

    local x, y = ScrW() / 2, ScrH() / 2 + 40

    draw.SimpleTextOutlined("[FANTOME] " .. model, "DermaDefaultBold", x, y, Color(50, 150, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    draw.SimpleTextOutlined("Blueprint de: " .. owner, "DermaDefault", x, y + 18, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    draw.SimpleTextOutlined("Utilisez une caisse de materiaux + E", "DermaDefault", x, y + 34, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
end)
