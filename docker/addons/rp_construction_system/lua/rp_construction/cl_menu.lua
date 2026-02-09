--[[-----------------------------------------------------------------------
    RP Construction System - Interface Utilisateur (Client)
    Menu principal moderne pour gérer les blueprints
---------------------------------------------------------------------------]]

ConstructionSystem.Menu = ConstructionSystem.Menu or {}

-- Rayon de sélection client (persiste entre sessions)
ConstructionSystem.ClientRadius = ConstructionSystem.ClientRadius or (ConstructionSystem.Config.SelectionRadiusDefault or 500)

---------------------------------------------------------------------------
-- COULEURS & STYLE
---------------------------------------------------------------------------

local Colors = {
    bg          = Color(18, 18, 22),
    bgLight     = Color(28, 28, 35),
    bgPanel     = Color(35, 35, 42),
    accent      = Color(59, 130, 246),    -- Bleu
    accentHover = Color(96, 165, 250),
    accentDark  = Color(37, 99, 235),
    success     = Color(34, 197, 94),
    danger      = Color(239, 68, 68),
    dangerHover = Color(248, 113, 113),
    warning     = Color(245, 158, 11),
    text        = Color(229, 231, 235),
    textDim     = Color(156, 163, 175),
    textMuted   = Color(107, 114, 128),
    border      = Color(55, 55, 65),
    white       = Color(255, 255, 255),
}

-- Fonts custom
surface.CreateFont("ConstructionTitle", {
    font = "Roboto", size = 22, weight = 700,
    antialias = true,
})
surface.CreateFont("ConstructionHeader", {
    font = "Roboto", size = 16, weight = 600,
    antialias = true,
})
surface.CreateFont("ConstructionBody", {
    font = "Roboto", size = 14, weight = 400,
    antialias = true,
})
surface.CreateFont("ConstructionSmall", {
    font = "Roboto", size = 12, weight = 400,
    antialias = true,
})
surface.CreateFont("ConstructionButton", {
    font = "Roboto", size = 14, weight = 600,
    antialias = true,
})

---------------------------------------------------------------------------
-- HELPERS UI
---------------------------------------------------------------------------

local function StyledButton(parent, text, color, hoverColor, textColor)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn.label = text
    btn.bgColor = color
    btn.hoverColor = hoverColor or Color(color.r + 30, color.g + 30, color.b + 30)
    btn.textColor = textColor or Colors.white
    btn.Paint = function(self, w, h)
        local c = self:IsHovered() and self.hoverColor or self.bgColor
        draw.RoundedBox(6, 0, 0, w, h, c)
        draw.SimpleText(self.label, "ConstructionButton", w/2, h/2, self.textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    return btn
end

---------------------------------------------------------------------------
-- OUVERTURE DU MENU
---------------------------------------------------------------------------

net.Receive("Construction_OpenMenu", function()
    ConstructionSystem.Menu.Open()
end)

function ConstructionSystem.Menu.Open()
    if IsValid(ConstructionSystem.Menu.Frame) then
        ConstructionSystem.Menu.Frame:Remove()
    end

    -- Ne pas ouvrir pendant le placement
    if ConstructionSystem.Placement and ConstructionSystem.Placement.IsActive() then
        chat.AddText(Colors.warning, "[Construction] ", Colors.text, "Terminez le placement avant d'ouvrir le menu")
        return
    end

    -- Frame principale
    local frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(math.min(ScrW() * 0.55, 750), math.min(ScrH() * 0.65, 520))
    frame:Center()
    frame:MakePopup()
    frame:SetDraggable(true)
    frame:SetSizable(false)
    frame:ShowCloseButton(false)

    frame.Paint = function(self, w, h)
        -- Ombre
        draw.RoundedBox(10, -2, -2, w+4, h+4, Color(0, 0, 0, 80))
        -- Background
        draw.RoundedBox(8, 0, 0, w, h, Colors.bg)
        -- Header
        draw.RoundedBoxEx(8, 0, 0, w, 48, Colors.bgLight, true, true, false, false)
        -- Ligne accent sous le header
        surface.SetDrawColor(Colors.accent)
        surface.DrawRect(0, 48, w, 2)
        -- Titre
        draw.SimpleText("Construction System", "ConstructionTitle", 20, 24, Colors.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("v" .. ConstructionSystem.Config.Version, "ConstructionSmall", w - 50, 24, Colors.textMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- Bouton close custom
    local btnClose = vgui.Create("DButton", frame)
    btnClose:SetPos(frame:GetWide() - 38, 8)
    btnClose:SetSize(30, 30)
    btnClose:SetText("")
    btnClose.Paint = function(self, w, h)
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Colors.danger)
        end
        draw.SimpleText("✕", "ConstructionHeader", w/2, h/2, Colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnClose.DoClick = function() frame:Remove() end

    ConstructionSystem.Menu.Frame = frame

    -- Container sous le header
    local container = vgui.Create("DPanel", frame)
    container:SetPos(0, 50)
    container:SetSize(frame:GetWide(), frame:GetTall() - 50)
    container.Paint = function() end

    -- Sidebar (navigation)
    local sidebar = vgui.Create("DPanel", container)
    sidebar:Dock(LEFT)
    sidebar:SetWide(160)
    sidebar:DockMargin(0, 0, 0, 0)
    sidebar.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Colors.bgLight)
        surface.SetDrawColor(Colors.border)
        surface.DrawRect(w-1, 0, 1, h)
    end

    -- Content area
    local content = vgui.Create("DPanel", container)
    content:Dock(FILL)
    content:DockMargin(0, 0, 0, 0)
    content.Paint = function() end

    -- Pages
    local pages = {}
    local activeTab = nil

    local function ShowPage(name)
        for k, p in pairs(pages) do
            p:SetVisible(k == name)
        end
        activeTab = name
        -- Refresh sidebar buttons
        if sidebar.RefreshButtons then sidebar:RefreshButtons() end
    end

    -- Créer les pages
    pages["blueprints"] = ConstructionSystem.Menu.CreateBlueprintsPage(content)
    pages["save"] = ConstructionSystem.Menu.CreateSavePage(content)
    pages["settings"] = ConstructionSystem.Menu.CreateSettingsPage(content)
    pages["help"] = ConstructionSystem.Menu.CreateHelpPage(content)

    for _, p in pairs(pages) do
        p:Dock(FILL)
        p:DockMargin(10, 10, 10, 10)
        p:SetVisible(false)
    end

    -- Sidebar buttons
    local tabs = {
        {name = "blueprints", label = "Blueprints", icon = "▦"},
        {name = "save", label = "Sauvegarder", icon = "💾"},
        {name = "settings", label = "Paramètres", icon = "⚙"},
        {name = "help", label = "Aide", icon = "?"},
    }

    local tabButtons = {}
    for i, tab in ipairs(tabs) do
        local btn = vgui.Create("DButton", sidebar)
        btn:Dock(TOP)
        btn:DockMargin(8, i == 1 and 10 or 2, 8, 0)
        btn:SetTall(36)
        btn:SetText("")
        btn.tabName = tab.name
        btn.Paint = function(self, w, h)
            local isActive = (activeTab == self.tabName)
            local bg = isActive and Colors.accent or (self:IsHovered() and Colors.bgPanel or Color(0,0,0,0))
            draw.RoundedBox(6, 0, 0, w, h, bg)
            local textCol = isActive and Colors.white or Colors.textDim
            draw.SimpleText(tab.icon .. "  " .. tab.label, "ConstructionButton", 14, h/2, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function() ShowPage(tab.name) end
        tabButtons[tab.name] = btn
    end

    sidebar.RefreshButtons = function() end  -- Les boutons se repaint automatiquement

    ShowPage("blueprints")
end

---------------------------------------------------------------------------
-- PAGE : BLUEPRINTS
---------------------------------------------------------------------------

function ConstructionSystem.Menu.CreateBlueprintsPage(parent)
    local page = vgui.Create("DPanel", parent)
    page.Paint = function() end

    -- Header
    local header = vgui.Create("DPanel", page)
    header:Dock(TOP)
    header:SetTall(30)
    header.bpCount = 0
    header.Paint = function(self, w, h)
        draw.SimpleText("Mes Blueprints", "ConstructionHeader", 0, h/2, Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText((self.bpCount or 0) .. " sauvegarde(s) locale(s)", "ConstructionSmall", w, h/2, Colors.textMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- Liste
    local listContainer = vgui.Create("DPanel", page)
    listContainer:Dock(FILL)
    listContainer:DockMargin(0, 8, 0, 8)
    listContainer.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Colors.bgLight)
    end

    local scroll = vgui.Create("DScrollPanel", listContainer)
    scroll:Dock(FILL)
    scroll:DockMargin(4, 4, 4, 4)

    local selectedBP = nil

    local function RefreshList()
        scroll:Clear()
        selectedBP = nil

        local localBlueprints = ConstructionSystem.LocalBlueprints.GetList()

        if #localBlueprints == 0 then
            local empty = vgui.Create("DPanel", scroll)
            empty:Dock(TOP)
            empty:SetTall(80)
            empty.Paint = function(self, w, h)
                draw.SimpleText("Aucun blueprint sauvegardé", "ConstructionBody", w/2, h/2 - 10, Colors.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Sélectionnez des props et sauvegardez !", "ConstructionSmall", w/2, h/2 + 10, Colors.textMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            if IsValid(header) then
                header.bpCount = 0
            end
            return
        end

        if IsValid(header) then
            header.bpCount = #localBlueprints
        end

        for _, bp in ipairs(localBlueprints) do
            local item = vgui.Create("DButton", scroll)
            item:Dock(TOP)
            item:DockMargin(2, 2, 2, 0)
            item:SetTall(50)
            item:SetText("")
            item.bp = bp

            item.Paint = function(self, w, h)
                local isSelected = (selectedBP and selectedBP.id == self.bp.id)
                local bg = isSelected and Color(Colors.accent.r, Colors.accent.g, Colors.accent.b, 40) or
                           (self:IsHovered() and Colors.bgPanel or Color(0,0,0,0))
                draw.RoundedBox(4, 0, 0, w, h, bg)

                -- Bord gauche si sélectionné
                if isSelected then
                    surface.SetDrawColor(Colors.accent)
                    surface.DrawRect(0, 4, 3, h-8)
                end

                -- Nom
                draw.SimpleText(self.bp.name, "ConstructionButton", 14, 14, Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                -- Infos
                local info = self.bp.prop_count .. " props"
                if self.bp.description and self.bp.description ~= "" then
                    info = info .. "  •  " .. self.bp.description
                end
                draw.SimpleText(info, "ConstructionSmall", 14, 32, Colors.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                -- Date
                draw.SimpleText(self.bp.created_at or "", "ConstructionSmall", w - 8, h/2, Colors.textMuted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            item.DoClick = function(self)
                selectedBP = self.bp
            end

            item.DoDoubleClick = function(self)
                selectedBP = self.bp
                ConstructionSystem.Menu.LoadBlueprint(self.bp.filename)
            end
        end
    end

    ConstructionSystem.Menu.RefreshList = RefreshList
    RefreshList()

    -- Boutons en bas
    local btnBar = vgui.Create("DPanel", page)
    btnBar:Dock(BOTTOM)
    btnBar:SetTall(38)
    btnBar.Paint = function() end

    local btnLoad = StyledButton(btnBar, "▶ Charger", Colors.accent, Colors.accentHover)
    btnLoad:Dock(LEFT)
    btnLoad:SetWide(130)
    btnLoad:DockMargin(0, 0, 6, 0)
    btnLoad.DoClick = function()
        if not selectedBP then
            chat.AddText(Colors.warning, "[Construction] Sélectionnez un blueprint")
            return
        end
        ConstructionSystem.Menu.LoadBlueprint(selectedBP.filename)
    end

    local btnDelete = StyledButton(btnBar, "✕ Supprimer", Colors.danger, Colors.dangerHover)
    btnDelete:Dock(LEFT)
    btnDelete:SetWide(120)
    btnDelete:DockMargin(0, 0, 6, 0)
    btnDelete.DoClick = function()
        if not selectedBP then return end
        Derma_Query(
            "Supprimer '" .. selectedBP.name .. "' ?",
            "Confirmation",
            "Supprimer", function()
                ConstructionSystem.LocalBlueprints.Delete(selectedBP.filename)
                selectedBP = nil
                RefreshList()
                chat.AddText(Colors.success, "[Construction] Blueprint supprimé")
            end,
            "Annuler", function() end
        )
    end

    local btnRefresh = StyledButton(btnBar, "↻ Actualiser", Colors.bgPanel, Colors.border)
    btnRefresh:Dock(LEFT)
    btnRefresh:SetWide(110)
    btnRefresh.DoClick = function()
        RefreshList()
    end

    return page
end

---------------------------------------------------------------------------
-- PAGE : SAUVEGARDER
---------------------------------------------------------------------------

function ConstructionSystem.Menu.CreateSavePage(parent)
    local page = vgui.Create("DPanel", parent)
    page.Paint = function() end

    -- Header
    local header = vgui.Create("DPanel", page)
    header:Dock(TOP)
    header:SetTall(30)
    header.Paint = function(self, w, h)
        draw.SimpleText("Sauvegarder un Blueprint", "ConstructionHeader", 0, h/2, Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Compteur de sélection
    local selPanel = vgui.Create("DPanel", page)
    selPanel:Dock(TOP)
    selPanel:SetTall(50)
    selPanel:DockMargin(0, 8, 0, 0)
    selPanel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Colors.bgLight)
        local count = ConstructionSystem.Selection.Count()
        local maxP = ConstructionSystem.Config.MaxPropsPerBlueprint
        local maxText = maxP > 0 and tostring(maxP) or "∞"
        local col = (maxP > 0 and count >= maxP) and Colors.danger or Colors.accent
        draw.SimpleText(count, "ConstructionTitle", 20, h/2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("/ " .. maxText .. " props sélectionnés", "ConstructionBody", 55, h/2, Colors.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Nom
    local nameLabel = vgui.Create("DLabel", page)
    nameLabel:Dock(TOP)
    nameLabel:DockMargin(0, 16, 0, 4)
    nameLabel:SetTall(16)
    nameLabel:SetFont("ConstructionBody")
    nameLabel:SetTextColor(Colors.textDim)
    nameLabel:SetText("Nom du blueprint")

    local nameEntry = vgui.Create("DTextEntry", page)
    nameEntry:Dock(TOP)
    nameEntry:SetTall(34)
    nameEntry:SetFont("ConstructionBody")
    nameEntry:SetPlaceholderText("Ex: Maison moderne, Garage, Base...")
    nameEntry.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Colors.bgLight)
        if self:HasFocus() then
            surface.SetDrawColor(Colors.accent)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        self:DrawTextEntryText(Colors.text, Colors.accent, Colors.text)
    end

    -- Description
    local descLabel = vgui.Create("DLabel", page)
    descLabel:Dock(TOP)
    descLabel:DockMargin(0, 12, 0, 4)
    descLabel:SetTall(16)
    descLabel:SetFont("ConstructionBody")
    descLabel:SetTextColor(Colors.textDim)
    descLabel:SetText("Description (optionnelle)")

    local descEntry = vgui.Create("DTextEntry", page)
    descEntry:Dock(TOP)
    descEntry:SetTall(34)
    descEntry:SetFont("ConstructionBody")
    descEntry:SetPlaceholderText("Courte description de la construction...")
    descEntry.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Colors.bgLight)
        if self:HasFocus() then
            surface.SetDrawColor(Colors.accent)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        self:DrawTextEntryText(Colors.text, Colors.accent, Colors.text)
    end

    -- Bouton save
    local btnSave = StyledButton(page, "💾  SAUVEGARDER", Colors.accent, Colors.accentHover)
    btnSave:Dock(TOP)
    btnSave:DockMargin(0, 20, 0, 0)
    btnSave:SetTall(42)
    btnSave.DoClick = function()
        local name = string.Trim(nameEntry:GetValue() or "")
        if name == "" then
            chat.AddText(Colors.danger, "[Construction] ", Colors.text, "Entrez un nom pour le blueprint")
            return
        end
        if ConstructionSystem.Selection.Count() == 0 then
            chat.AddText(Colors.danger, "[Construction] ", Colors.text, "Sélectionnez des props d'abord (LMB avec l'outil)")
            return
        end

        net.Start("Construction_SaveBlueprint")
        net.WriteString(name)
        net.WriteString(string.Trim(descEntry:GetValue() or ""))
        net.SendToServer()

        if IsValid(ConstructionSystem.Menu.Frame) then
            ConstructionSystem.Menu.Frame:Remove()
        end
    end

    return page
end

---------------------------------------------------------------------------
-- PAGE : PARAMÈTRES
---------------------------------------------------------------------------

function ConstructionSystem.Menu.CreateSettingsPage(parent)
    local page = vgui.Create("DPanel", parent)
    page.Paint = function() end

    local header = vgui.Create("DPanel", page)
    header:Dock(TOP)
    header:SetTall(30)
    header.Paint = function(self, w, h)
        draw.SimpleText("Paramètres", "ConstructionHeader", 0, h/2, Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Rayon de sélection
    local radiusPanel = vgui.Create("DPanel", page)
    radiusPanel:Dock(TOP)
    radiusPanel:SetTall(90)
    radiusPanel:DockMargin(0, 10, 0, 0)
    radiusPanel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Colors.bgLight)
        draw.SimpleText("Rayon de sélection (RMB)", "ConstructionButton", 14, 14, Colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(math.Round(ConstructionSystem.ClientRadius) .. " unités", "ConstructionBody", w - 14, 14, Colors.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    local minR = ConstructionSystem.Config.SelectionRadiusMin or 50
    local maxR = ConstructionSystem.Config.SelectionRadiusMax or 1000

    local slider = vgui.Create("DNumSlider", radiusPanel)
    slider:SetPos(10, 40)
    slider:SetSize(radiusPanel:GetWide() - 20, 40)
    slider:SetText("")
    slider:SetMin(minR)
    slider:SetMax(maxR)
    slider:SetDecimals(0)
    slider:SetValue(ConstructionSystem.ClientRadius)
    slider.OnValueChanged = function(self, val)
        ConstructionSystem.ClientRadius = math.Round(val)
    end

    -- Info
    local info = vgui.Create("DPanel", page)
    info:Dock(TOP)
    info:SetTall(50)
    info:DockMargin(0, 10, 0, 0)
    info.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Colors.bgLight)
        draw.SimpleText("ℹ Le rayon est appliqué immédiatement au prochain clic droit.", "ConstructionSmall", 14, h/2, Colors.textMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    return page
end

---------------------------------------------------------------------------
-- PAGE : AIDE
---------------------------------------------------------------------------

function ConstructionSystem.Menu.CreateHelpPage(parent)
    local page = vgui.Create("DPanel", parent)
    page.Paint = function() end

    local scroll = vgui.Create("DScrollPanel", page)
    scroll:Dock(FILL)

    local function Section(title)
        local lbl = vgui.Create("DLabel", scroll)
        lbl:Dock(TOP)
        lbl:DockMargin(0, 14, 0, 4)
        lbl:SetFont("ConstructionHeader")
        lbl:SetTextColor(Colors.accent)
        lbl:SetText(title)
    end

    local function Line(text, col)
        local lbl = vgui.Create("DLabel", scroll)
        lbl:Dock(TOP)
        lbl:DockMargin(8, 1, 0, 1)
        lbl:SetFont("ConstructionBody")
        lbl:SetTextColor(col or Colors.textDim)
        lbl:SetText(text)
        lbl:SetWrap(true)
        lbl:SetAutoStretchVertical(true)
    end

    Section("Sélection")
    Line("LMB  →  Sélectionner / Désélectionner un prop")
    Line("RMB  →  Sélectionner tous les props dans le rayon")
    Line("R (Reload)  →  Vider la sélection")
    Line("Shift+RMB  →  Ouvrir ce menu")

    Section("Blueprints")
    Line("1. Sélectionnez vos props avec l'outil")
    Line("2. Ouvrez le menu → onglet Sauvegarder")
    Line("3. Donnez un nom et sauvegardez")
    Line("4. Pour charger : onglet Blueprints → sélectionnez → Charger")

    Section("Placement")
    Line("Après avoir chargé un blueprint :")
    Line("Molette  →  Rotation")
    Line("Shift+Molette  →  Ajuster la hauteur")
    Line("LMB  →  Confirmer le placement")
    Line("RMB / Échap  →  Annuler")

    Section("Construction")
    Line("1. Le constructeur charge un blueprint (fantômes)")
    Line("2. Achetez une Caisse de Matériaux (F4 → Entities)")
    Line("3. Appuyez E sur la caisse pour l'activer")
    Line("4. Appuyez E sur les fantômes pour les matérialiser")
    Line("5. Tout le monde peut aider à construire !")

    Section("Limites")
    local maxP = ConstructionSystem.Config.MaxPropsPerBlueprint
    Line("Max props par blueprint : " .. (maxP > 0 and maxP or "Illimité"))
    Line("Sauvegardes : Illimité (stockage local)")
    Line("Max caisses par joueur : " .. (ConstructionSystem.Config.MaxCratesPerPlayer or 2))
    Line("Matériaux par caisse : " .. (ConstructionSystem.Config.CrateMaxMaterials or 30))

    return page
end

---------------------------------------------------------------------------
-- CHARGEMENT BLUEPRINT (local → serveur)
---------------------------------------------------------------------------

function ConstructionSystem.Menu.LoadBlueprint(filename)
    local blueprint = ConstructionSystem.LocalBlueprints.Load(filename)
    if not blueprint then
        chat.AddText(Colors.danger, "[Construction] Blueprint introuvable: " .. tostring(filename))
        return
    end

    -- Compresser et envoyer au serveur pour validation
    local json = util.TableToJSON(blueprint)
    local compressed = util.Compress(json)

    if not compressed then
        chat.AddText(Colors.danger, "[Construction] Erreur compression")
        return
    end

    net.Start("Construction_LoadBlueprint")
    net.WriteUInt(#compressed, 32)
    net.WriteData(compressed, #compressed)
    net.SendToServer()

    if IsValid(ConstructionSystem.Menu.Frame) then
        ConstructionSystem.Menu.Frame:Remove()
    end
end

---------------------------------------------------------------------------
-- CONCOMMAND
---------------------------------------------------------------------------

concommand.Add("construction_menu", function()
    ConstructionSystem.Menu.Open()
end)

print("[Construction] Module cl_menu chargé")
