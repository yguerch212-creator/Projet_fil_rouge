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
-- Les modèles custom sont inclus dans l'addon (models/weapons/v_fortnite_builder.mdl)
-- Ils s'affichent automatiquement quand l'addon est installé via Workshop
-- En dev (bind mount), fallback sur c_slam car le client ne reçoit pas les fichiers
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
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

-- Reload (R): Charger/décharger caisse sur véhicule OU clear sélection
function SWEP:Reload()
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if self.NextReload and self.NextReload > CurTime() then return end
    self.NextReload = CurTime() + 0.5

    local tr = ply:GetEyeTrace()

    -- Véhicule simfphys visé ?
    if IsValid(tr.Entity) and tr.Entity:GetClass() == "gmod_sent_vehicle_fphysics_base" then
        local vehicle = tr.Entity
        local dist = ply:GetPos():Distance(vehicle:GetPos())
        if dist > 300 then
            DarkRP.notify(ply, 1, 3, "Trop loin du vehicule !")
            return
        end

        -- Vérifier si ce véhicule a déjà une caisse chargée → décharger
        for _, ent in ipairs(ents.FindByClass("construction_crate")) do
            if ent.LoadedVehicle == vehicle then
                ent:UnloadFromVehicle()
                DarkRP.notify(ply, 0, 4, "Caisse dechargee du vehicule !")
                return
            end
        end
        for _, ent in ipairs(ents.FindByClass("construction_crate_small")) do
            if ent.LoadedVehicle == vehicle then
                ent:UnloadFromVehicle()
                DarkRP.notify(ply, 0, 4, "Caisse dechargee du vehicule !")
                return
            end
        end

        -- Pas de caisse chargée → chercher une caisse proche du véhicule pour charger
        local vPos = vehicle:GetPos()
        local nearCrate = nil
        local nearDist = 200 -- rayon de détection

        for _, ent in ipairs(ents.FindInSphere(vPos, nearDist)) do
            if (ent:GetClass() == "construction_crate" or ent:GetClass() == "construction_crate_small")
               and not ent.LoadedVehicle
               and not ent:GetNWBool("IsLoaded", false) then
                nearCrate = ent
                break
            end
        end

        if nearCrate then
            nearCrate:LoadOntoVehicle(vehicle)
            DarkRP.notify(ply, 0, 4, "Caisse chargee sur le vehicule ! (" .. nearCrate:GetRemainingMats() .. " materiaux)")
        else
            DarkRP.notify(ply, 1, 3, "Aucune caisse a proximite du vehicule !")
        end
        return
    end

    -- Pas de véhicule visé → clear sélection (comportement normal)
    ConstructionSystem.Selection.Clear(ply)
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
