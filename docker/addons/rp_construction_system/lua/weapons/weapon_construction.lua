AddCSLuaFile()

SWEP.PrintName = "Outil de Construction"
SWEP.Author = "RP Construction System"
SWEP.Purpose = "Selectionner des props et gerer les blueprints"
SWEP.Instructions = "LMB: Select | RMB: Zone | Shift+RMB: Menu"
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

-- Viewmodel Fortnite Builder (plan d'architecte)
-- Modèle fourni par l'addon Workshop (ID 3664157203)
SWEP.ViewModel = "models/weapons/v_fortnite_builder.mdl"
SWEP.WorldModel = "models/weapons/w_fortnite_builder.mdl"
SWEP.UseHands = true
SWEP.HoldType = "slam"

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:Deploy() return true end
function SWEP:Holster() return true end

-- LMB: Toggle sélection
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.2)
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    if not tr.Hit or not IsValid(tr.Entity) then return end
    if not ConstructionSystem.Config.AllowedClasses[tr.Entity:GetClass()] then return end

    ConstructionSystem.Selection.Toggle(ply, tr.Entity)
end

-- RMB: Zone select / Shift+RMB: Menu
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.5)

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if ply:KeyDown(IN_SPEED) then
        if CLIENT then ConstructionSystem.Menu.Open() end
        return
    end

    if SERVER then return end

    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end

    local radius = ConstructionSystem.ClientRadius or ConstructionSystem.Config.SelectionRadiusDefault or 500

    net.Start("Construction_SelectRadius")
    net.WriteVector(tr.HitPos)
    net.WriteUInt(math.Round(radius), 10)
    net.SendToServer()
end

-- Reload (R): clear sélection OU décharger caisse du véhicule
-- Le CHARGEMENT se fait automatiquement (physgun parent → Think détecte)
function SWEP:Reload()
    if SERVER then return end

    if self.NextReload and self.NextReload > CurTime() then return end
    self.NextReload = CurTime() + 0.5

    net.Start("Construction_VehicleReload")
    net.SendToServer()
end

-- HUD
if CLIENT then
    function SWEP:DrawHUD()
        local count = ConstructionSystem.Selection.Count()
        local maxP = ConstructionSystem.Config.MaxPropsPerBlueprint

        local boxW, boxH = 240, 60
        local boxX = ScrW() - boxW - 20
        local boxY = ScrH() - boxH - 100

        draw.RoundedBox(6, boxX, boxY, boxW, boxH, Color(30, 30, 30, 180))
        draw.SimpleText("Construction", "DermaDefaultBold", boxX + boxW / 2, boxY + 8, Color(0, 150, 255), TEXT_ALIGN_CENTER)

        local col = count >= maxP and Color(255, 50, 50) or Color(200, 200, 200)
        draw.SimpleText("Props: " .. count .. "/" .. maxP, "DermaDefault", boxX + boxW / 2, boxY + 24, col, TEXT_ALIGN_CENTER)

        draw.SimpleText("LMB:Sel | RMB:Zone | R:Vehicule/Clear", "DermaDefault", boxX + boxW / 2, boxY + 40, Color(130, 130, 130), TEXT_ALIGN_CENTER)
    end
end

-- Net receiver serveur pour le Reload (R) : décharger OU clear sélection
if SERVER then
    util.AddNetworkString("Construction_VehicleReload")

    net.Receive("Construction_VehicleReload", function(len, ply)
        if not IsValid(ply) then return end
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "weapon_construction" then return end

        local tr = ply:GetEyeTrace()
        local hitEnt = tr.Entity

        -- Trouver véhicule simfphys (entité visée ou son parent)
        local vehicle = nil
        if IsValid(hitEnt) then
            local check = hitEnt
            for i = 1, 5 do
                if not IsValid(check) then break end
                if check:GetClass() == "gmod_sent_vehicle_fphysics_base" then
                    vehicle = check
                    break
                end
                check = check:GetParent()
            end
        end

        -- Véhicule trouvé → chercher une caisse chargée dessus → décharger
        if vehicle then
            for _, cls in ipairs({"construction_crate", "construction_crate_small"}) do
                for _, ent in ipairs(ents.FindByClass(cls)) do
                    if ent:GetNWBool("IsLoaded", false) and ent:GetParent() == vehicle then
                        ent:UnloadCrate()
                        ConstructionSystem.Compat.Notify(ply, 0, 4, "Caisse dechargee !")
                        return
                    end
                end
            end
            ConstructionSystem.Compat.Notify(ply, 1, 3, "Pas de caisse chargee sur ce vehicule !")
            return
        end

        -- Pas de véhicule → clear sélection
        ConstructionSystem.Selection.Clear(ply)
    end)
end
