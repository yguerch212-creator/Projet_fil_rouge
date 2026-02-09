--[[-----------------------------------------------------------------------
    RP Construction System - Ghost Prop (Client)
    Rendu transparent bleuté
---------------------------------------------------------------------------]]

include("shared.lua")

function ENT:Initialize()
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
end

function ENT:Draw()
    local ply = LocalPlayer()
    local isLooking = false

    if IsValid(ply) then
        local tr = util.TraceLine({
            start = ply:EyePos(),
            endpos = ply:EyePos() + ply:GetAimVector() * 500,
            filter = ply,
            mask = MASK_ALL,
        })
        -- Le trace ne touche pas les SOLID_NONE, donc on check la distance
        local eyePos = ply:EyePos()
        local ghostPos = self:GetPos()
        local aimVec = ply:GetAimVector()

        -- Vérifier si le joueur vise à peu près vers ce ghost
        local toGhost = (ghostPos - eyePos):GetNormalized()
        local dot = aimVec:Dot(toGhost)
        local dist = eyePos:Distance(ghostPos)

        if dot > 0.98 and dist < 500 then
            isLooking = true
        end
    end

    -- Couleur
    local pulse = math.abs(math.sin(CurTime() * 1.5 + self:EntIndex() * 0.5))
    local alpha
    if isLooking then
        alpha = 120 + pulse * 40
        self:SetColor(Color(80, 255, 120, alpha))
    else
        alpha = 60 + pulse * 30
        self:SetColor(Color(100, 180, 255, alpha))
    end

    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:DrawModel()
end

--- HUD info quand le joueur regarde un ghost
hook.Add("HUDPaint", "Construction_GhostInfo", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Trouver le ghost le plus proche dans la direction du regard
    local eyePos = ply:EyePos()
    local aimVec = ply:GetAimVector()
    local bestGhost = nil
    local bestDot = 0.98

    for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
        if IsValid(ent) then
            local toEnt = (ent:GetPos() - eyePos):GetNormalized()
            local dot = aimVec:Dot(toEnt)
            local dist = eyePos:Distance(ent:GetPos())

            if dot > bestDot and dist < 500 then
                bestDot = dot
                bestGhost = ent
            end
        end
    end

    if not bestGhost then return end

    local owner = bestGhost:GetNWString("ghost_blueprint_owner", "Inconnu")
    local model = string.match(bestGhost:GetModel() or "", "([^/]+)$") or "?"

    local x, y = ScrW() / 2, ScrH() / 2 + 40

    draw.SimpleTextOutlined("[FANTOME] " .. model, "DermaDefaultBold", x, y, Color(100, 180, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    draw.SimpleTextOutlined("Blueprint de: " .. owner, "DermaDefault", x, y + 18, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))

    if ply.ActiveCrate then
        draw.SimpleTextOutlined("Appuyez E pour materialiser", "DermaDefault", x, y + 34, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    else
        draw.SimpleTextOutlined("Activez une caisse d'abord (E sur caisse)", "DermaDefault", x, y + 34, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    end
end)
