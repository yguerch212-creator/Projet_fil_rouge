--[[-----------------------------------------------------------------------
    RP Construction System - Caisse de Matériaux (Client)
    Affichage 3D2D du nombre de matériaux restants
---------------------------------------------------------------------------]]

include("shared.lua")

function ENT:Draw()
    -- Invisible quand chargée sur un véhicule
    if self:GetNWBool("IsLoaded", false) then return end

    self:DrawModel()

    -- Position: sur le dessus de la caisse, collé
    local obbMax = self:OBBMaxs()
    local height = obbMax and obbMax.z or 40
    local pos = self:LocalToWorld(Vector(0, 0, height + 0.5))

    -- Angle: horizontal, fixe sur la caisse (suit la rotation de la caisse)
    local ang = self:GetAngles()
    ang = Angle(0, ang.y - 90, 90)

    local materials = self:GetNWInt("materials", 0)
    local maxMaterials = self:GetNWInt("max_materials", 30)

    cam.Start3D2D(pos, ang, 0.08)
        -- Background
        draw.RoundedBox(8, -200, -60, 400, 120, Color(30, 30, 30, 220))

        -- Barre de titre
        draw.RoundedBoxEx(8, -200, -60, 400, 35, Color(0, 100, 200, 220), true, true, false, false)
        draw.SimpleText("CAISSE DE MATERIAUX", "DermaLarge", 0, -55, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Compteur
        local countColor = materials > 0 and Color(100, 255, 100) or Color(255, 50, 50)
        draw.SimpleText(materials .. " / " .. maxMaterials, "DermaLarge", 0, -15, countColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Barre de progression
        local barW = 340
        local barH = 12
        local barX = -barW / 2
        local barY = 20
        draw.RoundedBox(4, barX, barY, barW, barH, Color(50, 50, 50, 200))
        if maxMaterials > 0 then
            local fill = math.Clamp(materials / maxMaterials, 0, 1) * barW
            local barColor = materials > 0 and Color(0, 180, 80, 220) or Color(180, 0, 0, 220)
            draw.RoundedBox(4, barX, barY, fill, barH, barColor)
        end

        -- Instructions
        draw.SimpleText("Appuyez [E] pres d'un ghost", "DermaDefault", 0, 40, Color(160, 160, 160), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    cam.End3D2D()
end
