--[[-----------------------------------------------------------------------
    RP Construction System - Système de Placement (Client)
    Preview holographique + contrôles de placement style AdvDupe2
---------------------------------------------------------------------------]]

ConstructionSystem.Placement = ConstructionSystem.Placement or {}

local PlacementActive = false
local PlacementData = nil       -- {Entities = {}, OriginalCenter = Vector}
local PlacementCSEnts = {}      -- ClientsideModels pour la preview
local PlacementRotation = 0     -- Rotation Y en degrés
local PlacementHeight = 0       -- Offset hauteur
local PlacementOriginalPos = false  -- Coller à la position originale
local PlacementBlueprintId = 0
local PlacementOriginalCenter = Vector(0, 0, 0)

---------------------------------------------------------------------------
-- RÉCEPTION DES DONNÉES DU SERVEUR
---------------------------------------------------------------------------

net.Receive("Construction_SendPreview", function()
    local blueprintId = net.ReadUInt(32)
    local dataLen = net.ReadUInt(32)
    local jsonData = net.ReadData(dataLen)

    local decompressed = util.Decompress(jsonData)
    if not decompressed then
        chat.AddText(Color(255, 80, 80), "[Construction] Erreur: données corrompues")
        return
    end

    local data = util.JSONToTable(decompressed)
    if not data or not data.Entities then
        chat.AddText(Color(255, 80, 80), "[Construction] Erreur: blueprint invalide")
        return
    end

    ConstructionSystem.Placement.Start(blueprintId, data)
end)

---------------------------------------------------------------------------
-- DÉMARRAGE / ARRÊT DU PLACEMENT
---------------------------------------------------------------------------

function ConstructionSystem.Placement.Start(blueprintId, data)
    -- Nettoyer un placement précédent
    ConstructionSystem.Placement.Stop()

    PlacementData = data
    PlacementBlueprintId = blueprintId
    PlacementRotation = 0
    PlacementHeight = 0
    PlacementOriginalPos = false
    PlacementActive = true

    -- Créer les CSEnts pour la preview
    for key, entData in pairs(data.Entities) do
        local csEnt = ClientsideModel(entData.Model or "models/error.mdl")
        if IsValid(csEnt) then
            csEnt:SetNoDraw(true)  -- On draw manuellement
            if entData.Skin and entData.Skin > 0 then
                csEnt:SetSkin(entData.Skin)
            end
            if entData.Material and entData.Material ~= "" then
                csEnt:SetMaterial(entData.Material)
            end
            table.insert(PlacementCSEnts, {
                ent = csEnt,
                offset = Vector(entData.Pos.x or 0, entData.Pos.y or 0, entData.Pos.z or 0),
                angles = Angle(entData.Ang.p or 0, entData.Ang.y or 0, entData.Ang.r or 0),
            })
        end
    end

    chat.AddText(Color(100, 200, 255), "[Construction] ", Color(255, 255, 255), "Mode placement activé - " .. #PlacementCSEnts .. " props")
    chat.AddText(Color(180, 180, 180), "  LMB: Confirmer | RMB/Échap: Annuler | Molette: Rotation | Shift+Molette: Hauteur")
end

function ConstructionSystem.Placement.Stop(confirmed)
    if PlacementActive and not confirmed then
        -- Notifier le serveur de l'annulation
        net.Start("Construction_CancelPlacement")
        net.SendToServer()
    end

    PlacementActive = false
    PlacementData = nil

    for _, csData in ipairs(PlacementCSEnts) do
        if IsValid(csData.ent) then
            csData.ent:Remove()
        end
    end
    PlacementCSEnts = {}
end

function ConstructionSystem.Placement.IsActive()
    return PlacementActive
end

---------------------------------------------------------------------------
-- CALCUL DE LA POSITION
---------------------------------------------------------------------------

local function GetPlacementPosition()
    local ply = LocalPlayer()
    if not IsValid(ply) then return Vector(0,0,0) end

    if PlacementOriginalPos and PlacementData then
        -- Position originale (centre du blueprint = 0,0,0 relatif)
        return PlacementOriginalCenter + Vector(0, 0, PlacementHeight)
    end

    -- Position au curseur
    local tr = ply:GetEyeTrace()
    return tr.HitPos + Vector(0, 0, 10 + PlacementHeight)
end

local function RotateVector(vec, angleDeg)
    local rad = math.rad(angleDeg)
    local cos, sin = math.cos(rad), math.sin(rad)
    return Vector(
        vec.x * cos - vec.y * sin,
        vec.x * sin + vec.y * cos,
        vec.z
    )
end

---------------------------------------------------------------------------
-- RENDU
---------------------------------------------------------------------------

hook.Add("PostDrawTranslucentRenderables", "Construction_PlacementRender", function()
    if not PlacementActive or #PlacementCSEnts == 0 then return end

    local basePos = GetPlacementPosition()
    local rotAngle = Angle(0, PlacementRotation, 0)

    for _, csData in ipairs(PlacementCSEnts) do
        if IsValid(csData.ent) then
            local rotatedOffset = RotateVector(csData.offset, PlacementRotation)
            local finalPos = basePos + rotatedOffset
            local finalAng = csData.angles + rotAngle

            csData.ent:SetPos(finalPos)
            csData.ent:SetAngles(finalAng)

            -- Rendu transparent bleu
            render.SetBlend(0.4)
            render.SetColorModulation(0.3, 0.6, 1.0)
            csData.ent:DrawModel()
            render.SetColorModulation(1, 1, 1)
            render.SetBlend(1)
        end
    end
end)

---------------------------------------------------------------------------
-- CONTRÔLES
---------------------------------------------------------------------------

-- Molette : rotation / hauteur
hook.Add("CreateMove", "Construction_PlacementScroll", function(cmd)
    if not PlacementActive then return end

    local scroll = cmd:GetMouseWheel()
    if scroll == 0 then return end

    if input.IsKeyDown(KEY_LSHIFT) then
        PlacementHeight = PlacementHeight + scroll * 10
    else
        PlacementRotation = (PlacementRotation + scroll * 15) % 360
    end

    -- Bloquer le scroll du weapon switch
    cmd:SetMouseWheel(0)
end)

-- LMB: Confirmer / RMB: Annuler
local lastClick = 0
hook.Add("Think", "Construction_PlacementInput", function()
    if not PlacementActive then return end
    if CurTime() - lastClick < 0.3 then return end

    -- LMB = confirmer
    if input.IsMouseDown(MOUSE_LEFT) then
        lastClick = CurTime()
        local basePos = GetPlacementPosition()

        net.Start("Construction_ConfirmPlacement")
        net.WriteUInt(PlacementBlueprintId, 32)
        net.WriteVector(basePos)
        net.WriteFloat(PlacementRotation)
        net.SendToServer()

        chat.AddText(Color(100, 255, 100), "[Construction] ", Color(255, 255, 255), "Placement confirmé !")
        ConstructionSystem.Placement.Stop(true)
        return
    end

    -- RMB = annuler
    if input.IsMouseDown(MOUSE_RIGHT) then
        lastClick = CurTime()
        chat.AddText(Color(255, 200, 100), "[Construction] ", Color(255, 255, 255), "Placement annulé")
        ConstructionSystem.Placement.Stop()
        return
    end
end)

-- Escape = annuler
hook.Add("PlayerBindPress", "Construction_PlacementEscape", function(ply, bind, pressed)
    if not PlacementActive then return end

    if pressed and (bind == "cancelselect" or bind == "+menu") then
        ConstructionSystem.Placement.Stop()
        chat.AddText(Color(255, 200, 100), "[Construction] ", Color(255, 255, 255), "Placement annulé")
        return true  -- Bloquer le bind
    end
end)

---------------------------------------------------------------------------
-- HUD PLACEMENT
---------------------------------------------------------------------------

hook.Add("HUDPaint", "Construction_PlacementHUD", function()
    if not PlacementActive then return end

    local w, h = 300, 140
    local x = ScrW() / 2 - w / 2
    local y = ScrH() - h - 80

    -- Background
    draw.RoundedBox(8, x, y, w, h, Color(20, 20, 25, 220))
    draw.RoundedBox(8, x, y, w, 30, Color(0, 100, 200, 240))

    -- Titre
    draw.SimpleText("MODE PLACEMENT", "DermaDefaultBold", x + w/2, y + 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Infos
    local infoY = y + 40
    draw.SimpleText("Rotation: " .. math.Round(PlacementRotation) .. "°", "DermaDefault", x + 15, infoY, Color(200, 200, 200))
    draw.SimpleText("Hauteur: " .. (PlacementHeight >= 0 and "+" or "") .. math.Round(PlacementHeight), "DermaDefault", x + 160, infoY, Color(200, 200, 200))

    infoY = infoY + 20
    draw.SimpleText("Props: " .. #PlacementCSEnts, "DermaDefault", x + 15, infoY, Color(100, 200, 255))

    -- Contrôles
    infoY = infoY + 25
    draw.SimpleText("Molette: Rotation", "DermaDefault", x + 15, infoY, Color(150, 150, 150))
    infoY = infoY + 16
    draw.SimpleText("Shift+Molette: Hauteur", "DermaDefault", x + 15, infoY, Color(150, 150, 150))
    infoY = infoY + 16
    draw.SimpleText("LMB: Confirmer  |  RMB/Échap: Annuler", "DermaDefault", x + 15, infoY, Color(100, 255, 100))
end)

---------------------------------------------------------------------------
-- BLOQUER LES ACTIONS PENDANT LE PLACEMENT
---------------------------------------------------------------------------

hook.Add("StartCommand", "Construction_PlacementBlock", function(ply, cmd)
    if not PlacementActive then return end
    if ply ~= LocalPlayer() then return end

    -- Bloquer le tir/use pendant le placement
    cmd:RemoveKey(IN_ATTACK)
    cmd:RemoveKey(IN_ATTACK2)
    cmd:RemoveKey(IN_USE)
end)

print("[Construction] Module cl_placement chargé")
