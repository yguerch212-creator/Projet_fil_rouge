--[[-----------------------------------------------------------------------
    RP Construction System - Système de Placement (Client)
    Preview holographique + panneau de contrôle style AdvDupe2
    
    Inspiré par Advanced Duplicator 2 (wiremod/advdupe2, Apache 2.0)
    Adapté pour le système de construction RP collaboratif.
---------------------------------------------------------------------------]]

ConstructionSystem.Placement = ConstructionSystem.Placement or {}

local PlacementActive = false
local PlacementData = nil
local PlacementCSEnts = {}
local PlacementBlueprintId = 0
local PlacementPanel = nil

-- Offsets & Options
local Offset = {
    height = 0,
    pitch = 0,
    yaw = 0,
    roll = 0,
}

local Options = {
    originalPos = false,         -- Coller à la position originale
    pasteConstraints = true,     -- Coller avec constraints
    pasteParenting = true,       -- Coller avec parenting
    unfreezeAll = false,         -- Tout dégeler après placement
    preserveFrozen = true,       -- Conserver l'état frozen
}

-- Info dupe
local DupeInfo = {
    file = "",
    creator = "",
    date = "",
    time = "",
    size = 0,
    description = "",
    constraints = 0,
}

-- Ghost rendering
local GhostPercentage = 50  -- 0-100
local GhostSpeed = 50       -- 0-100

---------------------------------------------------------------------------
-- COULEURS (réutilise celles du menu)
---------------------------------------------------------------------------

local Colors = {
    bg          = Color(18, 18, 22),
    bgLight     = Color(28, 28, 35),
    bgPanel     = Color(35, 35, 42),
    accent      = Color(59, 130, 246),
    accentHover = Color(96, 165, 250),
    success     = Color(34, 197, 94),
    danger      = Color(239, 68, 68),
    warning     = Color(245, 158, 11),
    text        = Color(229, 231, 235),
    textDim     = Color(156, 163, 175),
    textMuted   = Color(107, 114, 128),
    border      = Color(55, 55, 65),
    white       = Color(255, 255, 255),
}

---------------------------------------------------------------------------
-- RÉCEPTION DES DONNÉES DU SERVEUR
---------------------------------------------------------------------------

net.Receive("Construction_SendPreview", function()
    local blueprintId = net.ReadUInt(32)
    local dataLen = net.ReadUInt(32)
    local compressed = net.ReadData(dataLen)

    local decompressed = util.Decompress(compressed)
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
-- DÉMARRAGE / ARRÊT
---------------------------------------------------------------------------

function ConstructionSystem.Placement.Start(blueprintId, data)
    ConstructionSystem.Placement.Stop(true)

    PlacementData = data
    PlacementBlueprintId = blueprintId
    PlacementActive = true

    -- Reset offsets
    Offset.height = 0
    Offset.pitch = 0
    Offset.yaw = 0
    Offset.roll = 0

    -- Récupérer la position originale si disponible
    if data.OriginalCenter then
        local oc = data.OriginalCenter
        if type(oc) == "Vector" then
            OriginalCenter = oc
        elseif type(oc) == "table" then
            OriginalCenter = Vector(
                tonumber(oc.x) or tonumber(oc["1"]) or 0,
                tonumber(oc.y) or tonumber(oc["2"]) or 0,
                tonumber(oc.z) or tonumber(oc["3"]) or 0
            )
        end
    else
        OriginalCenter = Vector(0, 0, 0)
    end

    -- Compter props et constraints
    local propCount = 0
    local constraintCount = 0
    for _, entData in pairs(data.Entities) do
        propCount = propCount + 1
    end

    DupeInfo.size = propCount
    DupeInfo.constraints = constraintCount

    -- Créer les CSEnts
    for key, entData in pairs(data.Entities) do
        local model = entData.Model or "models/error.mdl"
        local csEnt = ClientsideModel(model)
        if IsValid(csEnt) then
            csEnt:SetNoDraw(true)
            if entData.Skin and tonumber(entData.Skin) and tonumber(entData.Skin) > 0 then
                csEnt:SetSkin(tonumber(entData.Skin))
            end
            if entData.Material and entData.Material ~= "" then
                csEnt:SetMaterial(entData.Material)
            end

            -- Extraire position (table ou Vector)
            local pos = Vector(0, 0, 0)
            if entData.Pos then
                if type(entData.Pos) == "Vector" then
                    pos = entData.Pos
                elseif type(entData.Pos) == "table" then
                    pos = Vector(
                        tonumber(entData.Pos.x) or tonumber(entData.Pos["1"]) or 0,
                        tonumber(entData.Pos.y) or tonumber(entData.Pos["2"]) or 0,
                        tonumber(entData.Pos.z) or tonumber(entData.Pos["3"]) or 0
                    )
                end
            end

            local ang = Angle(0, 0, 0)
            if entData.Ang then
                if type(entData.Ang) == "Angle" then
                    ang = entData.Ang
                elseif type(entData.Ang) == "table" then
                    ang = Angle(
                        tonumber(entData.Ang.p) or tonumber(entData.Ang["1"]) or 0,
                        tonumber(entData.Ang.y) or tonumber(entData.Ang["2"]) or 0,
                        tonumber(entData.Ang.r) or tonumber(entData.Ang["3"]) or 0
                    )
                end
            end

            table.insert(PlacementCSEnts, {
                ent = csEnt,
                offset = pos,
                angles = ang,
            })
        end
    end

    -- Ouvrir le panneau de contrôle
    ConstructionSystem.Placement.OpenPanel()

    chat.AddText(Colors.accent, "[Construction] ", Colors.white, "Mode placement — " .. #PlacementCSEnts .. " props")
end

function ConstructionSystem.Placement.Stop(confirmed)
    if PlacementActive and not confirmed then
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

    -- Fermer le panneau
    if IsValid(PlacementPanel) then
        PlacementPanel:Remove()
        PlacementPanel = nil
    end
end

function ConstructionSystem.Placement.IsActive()
    return PlacementActive
end

---------------------------------------------------------------------------
-- CALCUL POSITION
---------------------------------------------------------------------------

local function RotateVector(vec, pitch, yaw, roll)
    local ang = Angle(pitch, yaw, roll)
    local rotated = Vector(vec)
    rotated:Rotate(ang)
    return rotated
end

local OriginalCenter = Vector(0, 0, 0)

local function GetPlacementPosition()
    local ply = LocalPlayer()
    if not IsValid(ply) then return Vector(0, 0, 0) end

    if Options.originalPos and OriginalCenter:Length() > 0 then
        return OriginalCenter + Vector(0, 0, Offset.height)
    end

    local tr = ply:GetEyeTrace()
    return tr.HitPos + Vector(0, 0, 10 + Offset.height)
end

---------------------------------------------------------------------------
-- RENDU PREVIEW
---------------------------------------------------------------------------

hook.Add("PostDrawTranslucentRenderables", "Construction_PlacementRender", function()
    if not PlacementActive or #PlacementCSEnts == 0 then return end

    local basePos = GetPlacementPosition()
    local alpha = GhostPercentage / 100

    for i, csData in ipairs(PlacementCSEnts) do
        if IsValid(csData.ent) then
            local rotatedOffset = RotateVector(csData.offset, Offset.pitch, Offset.yaw, Offset.roll)
            local finalPos = basePos + rotatedOffset

            local baseAng = csData.angles + Angle(Offset.pitch, Offset.yaw, Offset.roll)
            csData.ent:SetPos(finalPos)
            csData.ent:SetAngles(baseAng)

            -- Pulsation subtile
            local pulse = 0.8 + math.sin(CurTime() * (GhostSpeed / 25) + i * 0.3) * 0.15

            render.SetBlend(alpha * pulse)
            render.SetColorModulation(0.3, 0.6, 1.0)
            csData.ent:DrawModel()
            render.SetColorModulation(1, 1, 1)
            render.SetBlend(1)
        end
    end
end)

---------------------------------------------------------------------------
-- PANNEAU DE CONTRÔLE (style AdvDupe2)
---------------------------------------------------------------------------

function ConstructionSystem.Placement.OpenPanel()
    if IsValid(PlacementPanel) then PlacementPanel:Remove() end

    local panelW = 280
    local panelH = ScrH() * 0.85
    local panelX = ScrW() - panelW - 10
    local panelY = (ScrH() - panelH) / 2

    local frame = vgui.Create("DFrame")
    frame:SetPos(panelX, panelY)
    frame:SetSize(panelW, panelH)
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:SetSizable(false)
    frame:ShowCloseButton(false)
    frame:SetMouseInputEnabled(true)
    frame:SetKeyboardInputEnabled(false)

    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(18, 18, 22, 230))
        draw.RoundedBoxEx(8, 0, 0, w, 32, Colors.bgLight, true, true, false, false)
        surface.SetDrawColor(Colors.accent)
        surface.DrawRect(0, 32, w, 2)
        draw.SimpleText("Placement", "DermaDefaultBold", 12, 16, Colors.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    PlacementPanel = frame

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:SetPos(0, 36)
    scroll:SetSize(panelW, panelH - 36)

    -- Hint F3
    local hint = vgui.Create("DPanel", scroll)
    hint:Dock(TOP)
    hint:DockMargin(8, 6, 8, 2)
    hint:SetTall(28)
    hint.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(59, 130, 246, 40))
        draw.SimpleText("⌨ Appuyez sur F3 pour un meilleur usage", "DermaDefaultBold", w/2, h/2, Colors.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Helper: Section title
    local function SectionTitle(text)
        local lbl = vgui.Create("DPanel", scroll)
        lbl:Dock(TOP)
        lbl:DockMargin(8, 10, 8, 2)
        lbl:SetTall(20)
        lbl.Paint = function(self, w, h)
            draw.SimpleText(text, "DermaDefaultBold", 0, h/2, Colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    -- Helper: Checkbox
    local function AddCheckbox(text, default, onChange)
        local cb = vgui.Create("DCheckBoxLabel", scroll)
        cb:Dock(TOP)
        cb:DockMargin(12, 3, 8, 0)
        cb:SetText(text)
        cb:SetTextColor(Colors.textDim)
        cb:SetValue(default)
        cb.OnChange = function(self, val)
            if onChange then onChange(val) end
        end
        return cb
    end

    -- Helper: Slider
    local function AddSlider(text, min, max, default, decimals, onChange)
        local container = vgui.Create("DPanel", scroll)
        container:Dock(TOP)
        container:DockMargin(8, 2, 8, 0)
        container:SetTall(32)
        container.Paint = function() end

        local slider = vgui.Create("DNumSlider", container)
        slider:Dock(FILL)
        slider:SetText(text)
        slider:SetMin(min)
        slider:SetMax(max)
        slider:SetDecimals(decimals or 0)
        slider:SetValue(default)
        slider.Label:SetTextColor(Colors.textDim)
        slider.OnValueChanged = function(self, val)
            if onChange then onChange(math.Round(val, decimals or 0)) end
        end
        return slider
    end

    -- ===================== OPTIONS =====================
    SectionTitle("Options de collage")

    AddCheckbox("Position originale", Options.originalPos, function(v) Options.originalPos = v end)
    AddCheckbox("Coller avec constraints", Options.pasteConstraints, function(v) Options.pasteConstraints = v end)
    AddCheckbox("Coller avec parenting", Options.pasteParenting, function(v) Options.pasteParenting = v end)
    AddCheckbox("Dégeler tout après collage", Options.unfreezeAll, function(v) Options.unfreezeAll = v end)
    AddCheckbox("Conserver état frozen", Options.preserveFrozen, function(v) Options.preserveFrozen = v end)
    AddCheckbox("Props contraints hors zone", false, function() end)
    
    -- Copy only own props (forcé sur serveur)
    local ownCB = AddCheckbox("Copier ses props uniquement", true, function() end)
    ownCB:SetEnabled(false)
    ownCB:SetTooltip("Activé par défaut sur serveur (non modifiable)")

    AddCheckbox("Trier constraints par connexion", false, function() end)

    -- ===================== GHOST =====================
    SectionTitle("Fantôme")

    AddSlider("Opacité", 0, 100, GhostPercentage, 0, function(v) GhostPercentage = v end)
    AddSlider("Vitesse", 0, 100, GhostSpeed, 0, function(v) GhostSpeed = v end)

    -- ===================== OFFSETS =====================
    SectionTitle("Décalage")

    local heightSlider = AddSlider("Hauteur", -2500, 2500, 0, 0, function(v) Offset.height = v end)
    local pitchSlider = AddSlider("Pitch", -180, 180, 0, 1, function(v) Offset.pitch = v end)
    local yawSlider = AddSlider("Yaw", -180, 180, 0, 1, function(v) Offset.yaw = v end)
    local rollSlider = AddSlider("Roll", -180, 180, 0, 1, function(v) Offset.roll = v end)

    -- Reset button
    local btnReset = vgui.Create("DButton", scroll)
    btnReset:Dock(TOP)
    btnReset:DockMargin(8, 6, 8, 0)
    btnReset:SetTall(28)
    btnReset:SetText("")
    btnReset.Paint = function(self, w, h)
        local bg = self:IsHovered() and Colors.border or Colors.bgPanel
        draw.RoundedBox(4, 0, 0, w, h, bg)
        draw.SimpleText("↺ Reset Offsets", "DermaDefaultBold", w/2, h/2, Colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnReset.DoClick = function()
        Offset.height = 0; Offset.pitch = 0; Offset.yaw = 0; Offset.roll = 0
        if IsValid(heightSlider) then heightSlider:SetValue(0) end
        if IsValid(pitchSlider) then pitchSlider:SetValue(0) end
        if IsValid(yawSlider) then yawSlider:SetValue(0) end
        if IsValid(rollSlider) then rollSlider:SetValue(0) end
    end

    -- ===================== INFO DUPE =====================
    SectionTitle("Information")

    local function InfoLine(label, value)
        local p = vgui.Create("DPanel", scroll)
        p:Dock(TOP)
        p:DockMargin(12, 1, 8, 0)
        p:SetTall(16)
        p.Paint = function(self, w, h)
            draw.SimpleText(label, "DermaDefault", 0, h/2, Colors.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(tostring(value), "DermaDefault", w, h/2, Colors.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    InfoLine("Fichier", DupeInfo.file ~= "" and DupeInfo.file or "Local")
    InfoLine("Créateur", LocalPlayer():Nick())
    InfoLine("Date", os.date("%d/%m/%Y"))
    InfoLine("Heure", os.date("%H:%M"))
    InfoLine("Objets", DupeInfo.size)
    InfoLine("Constraints", DupeInfo.constraints)

    -- ===================== ACTIONS =====================
    SectionTitle("Actions")

    -- Confirmer
    local btnConfirm = vgui.Create("DButton", scroll)
    btnConfirm:Dock(TOP)
    btnConfirm:DockMargin(8, 6, 8, 0)
    btnConfirm:SetTall(34)
    btnConfirm:SetText("")
    btnConfirm.Paint = function(self, w, h)
        local bg = self:IsHovered() and Colors.success or Color(25, 160, 75)
        draw.RoundedBox(6, 0, 0, w, h, bg)
        draw.SimpleText("✓ Confirmer (LMB)", "DermaDefaultBold", w/2, h/2, Colors.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnConfirm.DoClick = function()
        ConstructionSystem.Placement.Confirm()
    end

    -- Annuler
    local btnCancel = vgui.Create("DButton", scroll)
    btnCancel:Dock(TOP)
    btnCancel:DockMargin(8, 4, 8, 8)
    btnCancel:SetTall(28)
    btnCancel:SetText("")
    btnCancel.Paint = function(self, w, h)
        local bg = self:IsHovered() and Colors.danger or Color(180, 50, 50)
        draw.RoundedBox(4, 0, 0, w, h, bg)
        draw.SimpleText("✕ Annuler (RMB / Échap)", "DermaDefault", w/2, h/2, Colors.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnCancel.DoClick = function()
        ConstructionSystem.Placement.Stop()
    end
end

---------------------------------------------------------------------------
-- CONFIRMER LE PLACEMENT
---------------------------------------------------------------------------

function ConstructionSystem.Placement.Confirm()
    if not PlacementActive then return end

    local basePos = GetPlacementPosition()

    net.Start("Construction_ConfirmPlacement")
    net.WriteUInt(PlacementBlueprintId, 32)
    net.WriteVector(basePos)
    net.WriteFloat(Offset.yaw)  -- Rotation principale
    net.SendToServer()

    chat.AddText(Colors.success, "[Construction] ", Colors.white, "Placement confirmé !")
    ConstructionSystem.Placement.Stop(true)
end

---------------------------------------------------------------------------
-- CONTRÔLES CLAVIER / SOURIS
---------------------------------------------------------------------------

-- Molette : yaw / hauteur
hook.Add("CreateMove", "Construction_PlacementScroll", function(cmd)
    if not PlacementActive then return end

    local scroll = cmd:GetMouseWheel()
    if scroll == 0 then return end

    if input.IsKeyDown(KEY_LSHIFT) then
        Offset.height = math.Clamp(Offset.height + scroll * 10, -2500, 2500)
    else
        Offset.yaw = math.NormalizeAngle(Offset.yaw + scroll * 15)
    end

    -- Mettre à jour les sliders si le panel est ouvert
    -- (les sliders se mettront à jour au prochain Paint)

    cmd:SetMouseWheel(0)
end)

-- Placement se fait uniquement via les boutons du panneau
-- Pas de LMB/RMB pour éviter les validations accidentelles

-- Escape
hook.Add("PlayerBindPress", "Construction_PlacementEscape", function(ply, bind, pressed)
    if not PlacementActive then return end
    if pressed and (bind == "cancelselect" or bind == "+menu") then
        ConstructionSystem.Placement.Stop()
        return true
    end
end)

---------------------------------------------------------------------------
-- HUD COMPACT (en bas au centre)
---------------------------------------------------------------------------

hook.Add("HUDPaint", "Construction_PlacementHUD", function()
    if not PlacementActive then return end

    local w, h = 320, 24
    local x = ScrW() / 2 - w / 2
    local y = ScrH() - 60

    draw.RoundedBox(4, x, y, w, h, Color(20, 20, 25, 200))

    local info = string.format("Yaw: %d° | Hauteur: %+d | Props: %d",
        math.Round(Offset.yaw), math.Round(Offset.height), #PlacementCSEnts)
    draw.SimpleText(info, "DermaDefault", x + w/2, y + h/2, Colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

-- Actions non bloquées pendant le placement (le joueur peut se déplacer librement)

print("[Construction] Module cl_placement chargé")
