--[[-----------------------------------------------------------------------
    RP Construction System - Ghost Prop (Client) - OPTIMISÉ
---------------------------------------------------------------------------]]

include("shared.lua")

function ENT:Initialize()
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SetColor(Color(100, 180, 255, 70))
end

function ENT:Draw()
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:DrawModel()
end

---------------------------------------------------------------------------
-- CLIENT : E sur ghost → net message au serveur
-- Throttled : check toutes les 50ms pas chaque frame
---------------------------------------------------------------------------

local lastUseSent = 0
local wasUseDown = false

hook.Add("Think", "Construction_GhostUseClient", function()
    local useDown = input.IsKeyDown(KEY_E)

    if useDown and not wasUseDown then
        wasUseDown = true
        if lastUseSent > CurTime() then return end

        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end

        local crate = ply:GetNWEntity("ActiveCrate")
        if not IsValid(crate) then return end

        -- Check rapide : y a-t-il un ghost proche ?
        local eyePos = ply:EyePos()
        local aimVec = ply:GetAimVector()
        local found = false

        for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
            if IsValid(ent) then
                local toEnt = (ent:GetPos() - eyePos)
                if toEnt:Length() < 300 then
                    if aimVec:Dot(toEnt:GetNormalized()) > 0.85 then
                        found = true
                        break
                    end
                end
            end
        end

        if found then
            lastUseSent = CurTime() + 0.3
            net.Start("Construction_MaterializeGhost")
            net.SendToServer()
        end
    elseif not useDown then
        wasUseDown = false
    end
end)

---------------------------------------------------------------------------
-- HUD (léger, pas de recherche lourde)
---------------------------------------------------------------------------

local cachedGhost = nil
local nextGhostCheck = 0

hook.Add("HUDPaint", "Construction_GhostInfo", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Refresh le ghost visé toutes les 200ms
    if nextGhostCheck < CurTime() then
        nextGhostCheck = CurTime() + 0.2
        cachedGhost = nil

        local eyePos = ply:EyePos()
        local aimVec = ply:GetAimVector()

        for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
            if IsValid(ent) then
                local toEnt = ent:GetPos() - eyePos
                if toEnt:Length() < 300 and aimVec:Dot(toEnt:GetNormalized()) > 0.9 then
                    cachedGhost = ent
                    break
                end
            end
        end
    end

    if not IsValid(cachedGhost) then return end

    local owner = cachedGhost:GetNWString("ghost_blueprint_owner", "")
    local model = string.match(cachedGhost:GetModel() or "", "([^/]+)$") or "?"

    local x, y = ScrW() / 2, ScrH() / 2 + 40

    draw.SimpleTextOutlined("[FANTOME] " .. model, "DermaDefaultBold", x, y, Color(100, 180, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))

    local crate = ply:GetNWEntity("ActiveCrate")
    if IsValid(crate) then
        local mats = crate:GetNWInt("materials", 0)
        draw.SimpleTextOutlined("Caisse activee (" .. mats .. ") - E pour poser", "DermaDefault", x, y + 18, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    else
        draw.SimpleTextOutlined("Activez une caisse (E sur caisse)", "DermaDefault", x, y + 18, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    end
end)
