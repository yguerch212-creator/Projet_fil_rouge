--[[-----------------------------------------------------------------------
    RP Construction System - SWEP Constructeur
    Arme donnée au job Constructeur pour sélectionner et gérer les blueprints
    
    LMB : Sélectionner / Désélectionner un prop
    RMB : Sélectionner tous les props dans un rayon
    Reload : Vider la sélection
    E (Use key) : Ouvrir le menu blueprints
---------------------------------------------------------------------------]]

AddCSLuaFile()

SWEP.PrintName = "Outil de Construction"
SWEP.Author = "RP Construction System"
SWEP.Purpose = "Sélectionner des props et gérer les blueprints"
SWEP.Instructions = "LMB: Select | RMB: Zone | R: Clear | Use: Menu"
SWEP.Category = "Construction RP"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/v_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true

SWEP.HoldType = "revolver"

---------------------------------------------------------------------------
-- SHARED
---------------------------------------------------------------------------

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Deploy()
    return true
end

function SWEP:Holster()
    return true
end

---------------------------------------------------------------------------
-- PRIMARY : Toggle sélection d'un prop
---------------------------------------------------------------------------

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.2)

    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    if not tr.Hit or not IsValid(tr.Entity) then return end

    local ent = tr.Entity
    if not ConstructionSystem.Config.AllowedClasses[ent:GetClass()] then
        DarkRP.notify(ply, 1, 3, "Ce type d'objet ne peut pas etre selectionne")
        return
    end

    local ok, err = ConstructionSystem.Selection.Toggle(ply, ent)
    if not ok and err then
        DarkRP.notify(ply, 1, 3, err)
    elseif ok then
        local selected = ConstructionSystem.Selection.IsSelected(ply, ent)
        local count = ConstructionSystem.Selection.Count(ply)
        ply:ChatPrint("[Construction] " .. (selected and "Prop ajoute" or "Prop retire") .. " (" .. count .. " selectionnes)")
    end

    -- Effet visuel
    local effectdata = EffectData()
    effectdata:SetOrigin(tr.HitPos)
    effectdata:SetNormal(tr.HitNormal)
    util.Effect("selection_indicator", effectdata)
end

---------------------------------------------------------------------------
-- SECONDARY : Sélection par rayon
---------------------------------------------------------------------------

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 1)

    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end

    local radius = ConstructionSystem.Config.SelectionRadius
    local added = ConstructionSystem.Selection.AddInRadius(ply, tr.HitPos, radius)
    local total = ConstructionSystem.Selection.Count(ply)

    DarkRP.notify(ply, 0, 4, added .. " prop(s) ajoutes (" .. total .. " total)")
end

---------------------------------------------------------------------------
-- RELOAD : Vider la sélection
---------------------------------------------------------------------------

function SWEP:Reload()
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local count = ConstructionSystem.Selection.Count(ply)
    ConstructionSystem.Selection.Clear(ply)

    if count > 0 then
        DarkRP.notify(ply, 0, 3, count .. " prop(s) deselectionnes")
    end
end

---------------------------------------------------------------------------
-- CLIENT : HUD et rendu
---------------------------------------------------------------------------

if CLIENT then

    function SWEP:DrawHUD()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local count = ConstructionSystem.Selection.Count()
        local maxProps = ConstructionSystem.Config.MaxPropsPerBlueprint

        -- Box d'info en bas à droite
        local boxW, boxH = 250, 90
        local boxX = ScrW() - boxW - 20
        local boxY = ScrH() - boxH - 100

        draw.RoundedBox(8, boxX, boxY, boxW, boxH, Color(30, 30, 30, 200))
        draw.RoundedBox(8, boxX, boxY, boxW, 28, Color(0, 100, 200, 220))

        draw.SimpleText("Outil de Construction", "DermaDefaultBold", boxX + boxW / 2, boxY + 14, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local countColor = count >= maxProps and Color(255, 50, 50) or Color(200, 200, 200)
        draw.SimpleText("Props: " .. count .. " / " .. maxProps, "DermaDefault", boxX + boxW / 2, boxY + 38, countColor, TEXT_ALIGN_CENTER)

        draw.SimpleText("LMB: Select | RMB: Zone | R: Clear", "DermaDefault", boxX + boxW / 2, boxY + 55, Color(150, 150, 150), TEXT_ALIGN_CENTER)
        draw.SimpleText("Tapez  construction_menu  pour le menu", "DermaDefault", boxX + boxW / 2, boxY + 72, Color(100, 180, 255), TEXT_ALIGN_CENTER)

        -- Crosshair info
        local tr = ply:GetEyeTrace()
        if tr.Hit and IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_physics" then
            local ent = tr.Entity
            local selected = ConstructionSystem.Selection.IsSelected(ent)
            local model = string.match(ent:GetModel() or "unknown", "([^/]+)$") or "unknown"

            local text = selected and "[SELECTIONNE] " .. model or model
            local color = selected and Color(0, 150, 255) or Color(255, 200, 0)

            draw.SimpleTextOutlined(text, "DermaDefault", ScrW() / 2, ScrH() / 2 + 30, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, Color(0, 0, 0))
        end
    end
end
