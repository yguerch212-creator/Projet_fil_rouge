--[[-----------------------------------------------------------------------
    RP Construction System - Ghost Prop (Client)
    Rendu transparent + interaction E → net message
---------------------------------------------------------------------------]]

include("shared.lua")

function ENT:Initialize()
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
end

---------------------------------------------------------------------------
-- HELPER : vérifier si le joueur regarde ce ghost
---------------------------------------------------------------------------

local function IsLookingAtGhost(ply, ghost, maxDist)
    local eyePos = ply:EyePos()
    local toEnt = ghost:GetPos() - eyePos
    local dist = toEnt:Length()
    if dist > (maxDist or 300) then return false end

    local dir = toEnt:GetNormalized()
    local dot = ply:GetAimVector():Dot(dir)
    return dot > 0.9
end

--- Trouver le ghost le plus proche visé
local function FindBestGhost(ply)
    local best = nil
    local bestDist = 300

    for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
        if IsValid(ent) and IsLookingAtGhost(ply, ent, bestDist) then
            local dist = ply:EyePos():Distance(ent:GetPos())
            if dist < bestDist then
                bestDist = dist
                best = ent
            end
        end
    end

    return best
end

---------------------------------------------------------------------------
-- RENDU
---------------------------------------------------------------------------

function ENT:Draw()
    local ply = LocalPlayer()
    local isLooking = IsValid(ply) and IsLookingAtGhost(ply, self, 300)

    local pulse = math.abs(math.sin(CurTime() * 1.5 + self:EntIndex() * 0.5))

    if isLooking then
        self:SetColor(Color(80, 255, 120, 120 + pulse * 40))
    else
        self:SetColor(Color(100, 180, 255, 60 + pulse * 30))
    end

    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:DrawModel()
end

---------------------------------------------------------------------------
-- CLIENT : E sur ghost → net message au serveur
---------------------------------------------------------------------------

local lastUseSent = 0
local wasUseDown = false
local debugLog = {}

local function CL_Log(msg)
    local line = os.date("%H:%M:%S") .. " [CL] " .. msg
    table.insert(debugLog, line)
    if #debugLog > 100 then table.remove(debugLog, 1) end
    print("[Construction_CL] " .. msg)
end

-- Commande console pour voir les logs client
concommand.Add("construction_cllog", function()
    print("\n=== CONSTRUCTION CLIENT LOGS ===")
    for _, line in ipairs(debugLog) do
        print(line)
    end
    print("=== END (" .. #debugLog .. " entries) ===\n")
end)

-- Client Think : vérifie chaque frame si E est pressé en regardant un ghost
hook.Add("Think", "Construction_GhostUseClient", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local useDown = input.IsKeyDown(KEY_E)

    if useDown and not wasUseDown then
        wasUseDown = true

        CL_Log("E pressed!")

        if lastUseSent > CurTime() then
            CL_Log("  BLOCKED: cooldown (" .. string.format("%.1f", lastUseSent - CurTime()) .. "s left)")
            return
        end

        -- Vérifier caisse active
        local crate = ply:GetNWEntity("ActiveCrate")
        CL_Log("  Crate: " .. tostring(crate) .. " valid=" .. tostring(IsValid(crate)))
        if not IsValid(crate) then
            CL_Log("  STOP: no active crate")
            return
        end

        -- Vérifier ghost en vue
        local ghost = FindBestGhost(ply)
        CL_Log("  Ghost: " .. tostring(ghost) .. " valid=" .. tostring(IsValid(ghost)))
        if not IsValid(ghost) then
            CL_Log("  STOP: no ghost in sight")
            -- Log all ghosts and their distances/dots for debug
            local eyePos = ply:EyePos()
            local aimVec = ply:GetAimVector()
            for _, ent in ipairs(ents.FindByClass("construction_ghost")) do
                if IsValid(ent) then
                    local toEnt = (ent:GetPos() - eyePos)
                    local dist = toEnt:Length()
                    local dot = aimVec:Dot(toEnt:GetNormalized())
                    CL_Log("    ghost " .. tostring(ent) .. " dist=" .. math.floor(dist) .. " dot=" .. string.format("%.3f", dot))
                end
            end
            return
        end

        -- Envoyer au serveur
        lastUseSent = CurTime() + 0.3
        CL_Log("  >>> SENDING NET MESSAGE to server!")
        net.Start("Construction_MaterializeGhost")
        net.SendToServer()
    elseif not useDown then
        wasUseDown = false
    end
end)

---------------------------------------------------------------------------
-- HUD
---------------------------------------------------------------------------

hook.Add("HUDPaint", "Construction_GhostInfo", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local ghost = FindBestGhost(ply)
    if not IsValid(ghost) then return end

    local owner = ghost:GetNWString("ghost_blueprint_owner", "Inconnu")
    local model = string.match(ghost:GetModel() or "", "([^/]+)$") or "?"

    local x, y = ScrW() / 2, ScrH() / 2 + 40

    draw.SimpleTextOutlined("[FANTOME] " .. model, "DermaDefaultBold", x, y, Color(100, 180, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    draw.SimpleTextOutlined("Blueprint de: " .. owner, "DermaDefault", x, y + 18, Color(180, 180, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))

    local crate = ply:GetNWEntity("ActiveCrate")
    if IsValid(crate) then
        local mats = crate:GetNWInt("materials", 0)
        draw.SimpleTextOutlined("Caisse activee (" .. mats .. " mat.) - Appuyez E pour poser", "DermaDefault", x, y + 34, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    else
        draw.SimpleTextOutlined("Activez une caisse d'abord (E sur caisse)", "DermaDefault", x, y + 34, Color(255, 200, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
    end
end)
