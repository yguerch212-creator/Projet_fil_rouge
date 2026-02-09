--[[-----------------------------------------------------------------------
    RP Construction System - Interface Utilisateur (Client)
    Menu principal Derma pour gérer les blueprints
---------------------------------------------------------------------------]]

ConstructionSystem.Menu = ConstructionSystem.Menu or {}

-- Cache des blueprints reçus du serveur
local cachedBlueprints = {}

---------------------------------------------------------------------------
-- RÉCEPTION DES DONNÉES
---------------------------------------------------------------------------

net.Receive("Construction_SendBlueprints", function()
    cachedBlueprints = {}
    local count = net.ReadUInt(8)

    for i = 1, count do
        table.insert(cachedBlueprints, {
            id = net.ReadUInt(32),
            name = net.ReadString(),
            description = net.ReadString(),
            prop_count = net.ReadUInt(10),
            constraint_count = net.ReadUInt(10),
            is_public = net.ReadBool(),
            created_at = net.ReadString(),
        })
    end

    -- Si le menu est ouvert, rafraîchir la liste
    if IsValid(ConstructionSystem.Menu.Frame) and ConstructionSystem.Menu.RefreshList then
        ConstructionSystem.Menu.RefreshList()
    end
end)

---------------------------------------------------------------------------
-- OUVERTURE DU MENU
---------------------------------------------------------------------------

net.Receive("Construction_OpenMenu", function()
    ConstructionSystem.Menu.Open()
end)

function ConstructionSystem.Menu.Open()
    -- Fermer si déjà ouvert
    if IsValid(ConstructionSystem.Menu.Frame) then
        ConstructionSystem.Menu.Frame:Remove()
    end

    -- Demander les blueprints au serveur
    net.Start("Construction_RequestBlueprints")
    net.SendToServer()

    -- Créer la fenêtre principale
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Systeme de Construction RP - v" .. ConstructionSystem.Config.Version)
    frame:SetSize(math.min(ScrW() * 0.6, 800), math.min(ScrH() * 0.7, 550))
    frame:Center()
    frame:MakePopup()
    frame:SetDraggable(true)
    frame:SetSizable(false)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Color(35, 35, 40, 245))
        draw.RoundedBox(8, 0, 0, w, 28, Color(0, 100, 200, 255))
        draw.SimpleText(self:GetTitle(), "DermaDefaultBold", w / 2, 14, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    ConstructionSystem.Menu.Frame = frame

    -- Onglets
    local tabs = vgui.Create("DPropertySheet", frame)
    tabs:Dock(FILL)
    tabs:DockMargin(5, 5, 5, 5)

    -- Onglet 1 : Mes Blueprints
    local myBPPanel = ConstructionSystem.Menu.CreateMyBlueprintsPanel(tabs)
    tabs:AddSheet("Mes Blueprints", myBPPanel, "icon16/brick.png")

    -- Onglet 2 : Sauvegarder
    local savePanel = ConstructionSystem.Menu.CreateSavePanel(tabs)
    tabs:AddSheet("Sauvegarder", savePanel, "icon16/disk.png")

    -- Onglet 3 : Infos
    local infoPanel = ConstructionSystem.Menu.CreateInfoPanel(tabs)
    tabs:AddSheet("Infos", infoPanel, "icon16/information.png")
end

---------------------------------------------------------------------------
-- ONGLET : MES BLUEPRINTS
---------------------------------------------------------------------------

function ConstructionSystem.Menu.CreateMyBlueprintsPanel(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:Dock(FILL)
    panel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 50, 200))
    end

    -- Liste des blueprints
    local list = vgui.Create("DListView", panel)
    list:Dock(FILL)
    list:DockMargin(5, 5, 5, 45)
    list:SetMultiSelect(false)
    list:AddColumn("ID"):SetFixedWidth(40)
    list:AddColumn("Nom"):SetFixedWidth(180)
    list:AddColumn("Props"):SetFixedWidth(50)
    list:AddColumn("Public"):SetFixedWidth(50)
    list:AddColumn("Date"):SetFixedWidth(120)
    list:AddColumn("Description")

    -- Fonction de rafraîchissement
    ConstructionSystem.Menu.RefreshList = function()
        list:Clear()
        for _, bp in ipairs(cachedBlueprints) do
            list:AddLine(
                bp.id,
                bp.name,
                bp.prop_count,
                bp.is_public and "Oui" or "Non",
                bp.created_at or "",
                bp.description or ""
            )
        end
    end

    -- Rafraîchir immédiatement avec le cache
    ConstructionSystem.Menu.RefreshList()

    -- Barre de boutons en bas
    local btnBar = vgui.Create("DPanel", panel)
    btnBar:Dock(BOTTOM)
    btnBar:SetTall(35)
    btnBar:DockMargin(5, 0, 5, 5)
    btnBar.Paint = function() end

    -- Bouton Charger
    local btnLoad = vgui.Create("DButton", btnBar)
    btnLoad:Dock(LEFT)
    btnLoad:SetWide(120)
    btnLoad:DockMargin(0, 0, 5, 0)
    btnLoad:SetText("Charger ($" .. ConstructionSystem.Config.LoadCost .. ")")
    btnLoad:SetTextColor(Color(255, 255, 255))
    btnLoad.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(0, 130, 50) or Color(0, 100, 40))
    end
    btnLoad.DoClick = function()
        local line = list:GetSelectedLine()
        if not line then
            Derma_Message("Selectionne un blueprint d'abord !", "Erreur", "OK")
            return
        end
        local id = tonumber(list:GetLine(line):GetValue(1))
        if id then
            net.Start("Construction_LoadBlueprint")
            net.WriteUInt(id, 32)
            net.SendToServer()
            if IsValid(ConstructionSystem.Menu.Frame) then
                ConstructionSystem.Menu.Frame:Remove()
            end
        end
    end

    -- Bouton Supprimer
    local btnDelete = vgui.Create("DButton", btnBar)
    btnDelete:Dock(LEFT)
    btnDelete:SetWide(100)
    btnDelete:DockMargin(0, 0, 5, 0)
    btnDelete:SetText("Supprimer")
    btnDelete:SetTextColor(Color(255, 255, 255))
    btnDelete.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(180, 30, 30) or Color(150, 20, 20))
    end
    btnDelete.DoClick = function()
        local line = list:GetSelectedLine()
        if not line then return end
        local id = tonumber(list:GetLine(line):GetValue(1))
        local name = list:GetLine(line):GetValue(2)
        if id then
            Derma_Query(
                "Supprimer le blueprint '" .. name .. "' ?",
                "Confirmation",
                "Oui", function()
                    net.Start("Construction_DeleteBlueprint")
                    net.WriteUInt(id, 32)
                    net.SendToServer()
                end,
                "Non", function() end
            )
        end
    end

    -- Bouton Rafraîchir
    local btnRefresh = vgui.Create("DButton", btnBar)
    btnRefresh:Dock(LEFT)
    btnRefresh:SetWide(90)
    btnRefresh:SetText("Rafraichir")
    btnRefresh:SetTextColor(Color(255, 255, 255))
    btnRefresh.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, self:IsHovered() and Color(60, 60, 70) or Color(50, 50, 60))
    end
    btnRefresh.DoClick = function()
        net.Start("Construction_RequestBlueprints")
        net.SendToServer()
    end

    return panel
end

---------------------------------------------------------------------------
-- ONGLET : SAUVEGARDER
---------------------------------------------------------------------------

function ConstructionSystem.Menu.CreateSavePanel(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:Dock(FILL)
    panel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 50, 200))
    end

    -- Infos sélection
    local selInfo = vgui.Create("DLabel", panel)
    selInfo:Dock(TOP)
    selInfo:DockMargin(10, 10, 10, 5)
    selInfo:SetTall(25)
    selInfo:SetFont("DermaDefaultBold")
    selInfo:SetTextColor(Color(0, 150, 255))

    local selCount = ConstructionSystem.Selection.Count()
    selInfo:SetText("Props selectionnes : " .. selCount .. " / " .. ConstructionSystem.Config.MaxPropsPerBlueprint)

    -- Nom
    local nameLabel = vgui.Create("DLabel", panel)
    nameLabel:Dock(TOP)
    nameLabel:DockMargin(10, 10, 10, 2)
    nameLabel:SetText("Nom du blueprint :")
    nameLabel:SetTextColor(Color(200, 200, 200))

    local nameEntry = vgui.Create("DTextEntry", panel)
    nameEntry:Dock(TOP)
    nameEntry:DockMargin(10, 0, 10, 5)
    nameEntry:SetTall(30)
    nameEntry:SetPlaceholderText("Ex: Maison simple, Garage, Tour...")

    -- Description
    local descLabel = vgui.Create("DLabel", panel)
    descLabel:Dock(TOP)
    descLabel:DockMargin(10, 5, 10, 2)
    descLabel:SetText("Description (optionnelle) :")
    descLabel:SetTextColor(Color(200, 200, 200))

    local descEntry = vgui.Create("DTextEntry", panel)
    descEntry:Dock(TOP)
    descEntry:DockMargin(10, 0, 10, 5)
    descEntry:SetTall(30)
    descEntry:SetPlaceholderText("Description de votre construction...")

    -- Coût
    local costLabel = vgui.Create("DLabel", panel)
    costLabel:Dock(TOP)
    costLabel:DockMargin(10, 10, 10, 5)
    costLabel:SetFont("DermaDefault")
    costLabel:SetTextColor(Color(100, 255, 100))
    costLabel:SetText("Cout : $" .. ConstructionSystem.Config.SaveCost)

    -- Bouton sauvegarder
    local btnSave = vgui.Create("DButton", panel)
    btnSave:Dock(TOP)
    btnSave:DockMargin(10, 10, 10, 5)
    btnSave:SetTall(40)
    btnSave:SetText("SAUVEGARDER LE BLUEPRINT")
    btnSave:SetTextColor(Color(255, 255, 255))
    btnSave:SetFont("DermaDefaultBold")
    btnSave.Paint = function(self, w, h)
        local color = self:IsHovered() and Color(0, 130, 220) or Color(0, 100, 200)
        if selCount == 0 then color = Color(80, 80, 80) end
        draw.RoundedBox(6, 0, 0, w, h, color)
    end
    btnSave.DoClick = function()
        local name = nameEntry:GetValue()
        if not name or string.Trim(name) == "" then
            Derma_Message("Entre un nom pour le blueprint !", "Erreur", "OK")
            return
        end

        if ConstructionSystem.Selection.Count() == 0 then
            Derma_Message("Selectionne des props d'abord avec le tool Blueprint Select !", "Erreur", "OK")
            return
        end

        net.Start("Construction_SaveBlueprint")
        net.WriteString(string.Trim(name))
        net.WriteString(string.Trim(descEntry:GetValue() or ""))
        net.SendToServer()

        if IsValid(ConstructionSystem.Menu.Frame) then
            ConstructionSystem.Menu.Frame:Remove()
        end
    end

    -- Timer pour rafraîchir le compteur
    timer.Create("Construction_UpdateSavePanel", 1, 0, function()
        if not IsValid(panel) then
            timer.Remove("Construction_UpdateSavePanel")
            return
        end
        selCount = ConstructionSystem.Selection.Count()
        if IsValid(selInfo) then
            selInfo:SetText("Props selectionnes : " .. selCount .. " / " .. ConstructionSystem.Config.MaxPropsPerBlueprint)
        end
    end)

    return panel
end

---------------------------------------------------------------------------
-- ONGLET : INFOS
---------------------------------------------------------------------------

function ConstructionSystem.Menu.CreateInfoPanel(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:Dock(FILL)
    panel.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(45, 45, 50, 200))
    end

    local scroll = vgui.Create("DScrollPanel", panel)
    scroll:Dock(FILL)
    scroll:DockMargin(10, 10, 10, 10)

    local function AddInfoLine(text, color)
        local label = vgui.Create("DLabel", scroll)
        label:Dock(TOP)
        label:DockMargin(0, 2, 0, 2)
        label:SetText(text)
        label:SetTextColor(color or Color(200, 200, 200))
        label:SetWrap(true)
        label:SetAutoStretchVertical(true)
    end

    AddInfoLine("=== SYSTEME DE CONSTRUCTION RP ===", Color(0, 150, 255))
    AddInfoLine("")
    AddInfoLine("UTILISATION :", Color(255, 200, 0))
    AddInfoLine("1. Equipe le Tool Gun (Q menu)")
    AddInfoLine("2. Selectionne l'outil 'Blueprint Select' dans Construction RP")
    AddInfoLine("3. Clic gauche sur des props pour les selectionner (halo bleu)")
    AddInfoLine("4. Clic droit pour selectionner tous les props dans un rayon")
    AddInfoLine("5. Ouvre ce menu et va dans 'Sauvegarder'")
    AddInfoLine("6. Donne un nom et sauvegarde !")
    AddInfoLine("")
    AddInfoLine("RACCOURCIS :", Color(255, 200, 0))
    AddInfoLine("LMB : Selectionner / Deselectionner un prop")
    AddInfoLine("RMB : Selectionner par zone (rayon)")
    AddInfoLine("R (Reload) : Vider la selection")
    AddInfoLine("")
    AddInfoLine("LIMITES :", Color(255, 200, 0))
    AddInfoLine("Max props par blueprint : " .. ConstructionSystem.Config.MaxPropsPerBlueprint)
    AddInfoLine("Max blueprints sauvegardes : " .. ConstructionSystem.Config.MaxBlueprintsPerPlayer)
    AddInfoLine("")
    AddInfoLine("COUTS :", Color(100, 255, 100))
    AddInfoLine("Sauvegarder : $" .. ConstructionSystem.Config.SaveCost)
    AddInfoLine("Charger : $" .. ConstructionSystem.Config.LoadCost)

    return panel
end

---------------------------------------------------------------------------
-- CONCOMMAND POUR OUVRIR LE MENU
---------------------------------------------------------------------------

concommand.Add("construction_menu", function()
    ConstructionSystem.Menu.Open()
end)

print("[Construction] Module cl_menu chargé")
