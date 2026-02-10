--[[-----------------------------------------------------------------------
    RP Construction System - Caisse de Matériaux (Client)
    Affichage 3D2D du nombre de matériaux restants
---------------------------------------------------------------------------]]

include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    -- Calculer la hauteur du modèle pour placer l'UI au-dessus
    local obbMax = self:OBBMaxs()
    local height = obbMax and obbMax.z or 40
    local pos = self:GetPos() + self:GetUp() * (height + 20)

    -- Orienter vers le joueur local
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local ang = (ply:GetPos() - pos):Angle()
    ang = Angle(0, ang.y + 180, 0)

    local materials = self:GetNWInt("materials", 0)
    local maxMaterials = self:GetNWInt("max_materials", 30)

    -- 3D2D au-dessus de la caisse (face au joueur)
    cam.Start3D2D(pos, ang, 0.1)
        -- Background
        draw.RoundedBox(8, -180, -35, 360, 70, Color(30, 30, 30, 220))

        -- Barre de titre
        draw.RoundedBoxEx(8, -180, -35, 360, 25, Color(0, 100, 200, 220), true, true, false, false)
        draw.SimpleText("CAISSE DE MATERIAUX", "DermaLarge", 0, -28, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Compteur
        local countColor = materials > 0 and Color(100, 255, 100) or Color(255, 50, 50)
        draw.SimpleText(materials .. " / " .. maxMaterials, "DermaLarge", 0, -2, countColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Barre de progression
        local barW = 300
        local barH = 8
        local barX = -barW / 2
        local barY = 24
        draw.RoundedBox(4, barX, barY, barW, barH, Color(50, 50, 50, 200))
        if maxMaterials > 0 then
            local fill = math.Clamp(materials / maxMaterials, 0, 1) * barW
            local barColor = materials > 0 and Color(0, 180, 80, 220) or Color(180, 0, 0, 220)
            draw.RoundedBox(4, barX, barY, fill, barH, barColor)
        end
    cam.End3D2D()
end
