include("shared.lua")

function ENT:Draw()
    self:DrawModel()
    if self:GetNWBool("IsLoaded", false) then return end

    local obbMax = self:OBBMaxs()
    local height = obbMax and obbMax.z or 20
    local pos = self:LocalToWorld(Vector(0, 0, height + 0.5))

    local ang = self:GetAngles()
    ang = Angle(0, ang.y - 90, 90)

    local materials = self:GetNWInt("materials", 0)
    local maxMaterials = self:GetNWInt("max_materials", 15)

    cam.Start3D2D(pos, ang, 0.06)
        draw.RoundedBox(8, -200, -60, 400, 120, Color(30, 30, 30, 220))
        draw.RoundedBoxEx(8, -200, -60, 400, 35, Color(180, 120, 0, 220), true, true, false, false)
        draw.SimpleText("PETITE CAISSE", "DermaLarge", 0, -55, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        local countColor = materials > 0 and Color(100, 255, 100) or Color(255, 50, 50)
        draw.SimpleText(materials .. " / " .. maxMaterials, "DermaLarge", 0, -15, countColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        local barW, barH = 340, 12
        local barX = -barW / 2
        draw.RoundedBox(4, barX, 20, barW, barH, Color(50, 50, 50, 200))
        if maxMaterials > 0 then
            local fill = math.Clamp(materials / maxMaterials, 0, 1) * barW
            local barColor = materials > 0 and Color(180, 140, 0, 220) or Color(180, 0, 0, 220)
            draw.RoundedBox(4, barX, 20, fill, barH, barColor)
        end

        draw.SimpleText("Appuyez [E] pres d'un ghost", "DermaDefault", 0, 40, Color(160, 160, 160), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    cam.End3D2D()
end
