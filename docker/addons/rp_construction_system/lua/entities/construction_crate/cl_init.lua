--[[-----------------------------------------------------------------------
    RP Construction System - Caisse de Matériaux (Client)
    Affichage 3D2D du nombre de matériaux restants
---------------------------------------------------------------------------]]

include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() + self:GetUp() * 45
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90)

    local materials = self:GetNWInt("materials", 0)
    local maxMaterials = self:GetNWInt("max_materials", 30)

    -- 3D2D au-dessus de la caisse
    cam.Start3D2D(pos, ang, 0.15)
        -- Background
        draw.RoundedBox(8, -150, -40, 300, 80, Color(30, 30, 30, 200))
        draw.RoundedBox(8, -150, -40, 300, 25, Color(0, 100, 200, 220))

        -- Titre
        draw.SimpleText("Caisse de Materiaux", "DermaLarge", 0, -32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Compteur
        local countColor = materials > 0 and Color(100, 255, 100) or Color(255, 50, 50)
        draw.SimpleText(materials .. " / " .. maxMaterials, "DermaLarge", 0, -2, countColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Instructions
        draw.SimpleText("Appuyez E pour activer", "DermaDefault", 0, 25, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    cam.End3D2D()

    -- Même chose de l'autre côté
    ang:RotateAroundAxis(ang:Up(), 180)
    cam.Start3D2D(pos, ang, 0.15)
        draw.RoundedBox(8, -150, -40, 300, 80, Color(30, 30, 30, 200))
        draw.RoundedBox(8, -150, -40, 300, 25, Color(0, 100, 200, 220))
        draw.SimpleText("Caisse de Materiaux", "DermaLarge", 0, -32, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        local countColor = materials > 0 and Color(100, 255, 100) or Color(255, 50, 50)
        draw.SimpleText(materials .. " / " .. maxMaterials, "DermaLarge", 0, -2, countColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText("Appuyez E pour activer", "DermaDefault", 0, 25, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    cam.End3D2D()
end
