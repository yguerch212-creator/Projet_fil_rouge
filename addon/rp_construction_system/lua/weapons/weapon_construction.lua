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
    local hitEnt = tr.Entity

    -- Trouver le véhicule simfphys : l'entité visée OU son parent (sièges, etc.)
    local vehicle = nil
    if IsValid(hitEnt) then
        local check = hitEnt
        for i = 1, 5 do -- remonter max 5 niveaux de parents
            if not IsValid(check) then break end
            if check:GetClass() == "gmod_sent_vehicle_fphysics_base" then
                vehicle = check
                break
            end
            -- Vérifier aussi si c'est un véhicule Source lié à simfphys
            if check.IsSimfphyscar or check.simfphysdata then
                vehicle = check
                break
            end
            check = check:GetParent()
        end
    end

    -- Si on vise une caisse, chercher un véhicule à proximité
    local targetCrate = nil
    if not vehicle and IsValid(hitEnt) then
        local cls = hitEnt:GetClass()
        if cls == "construction_crate" or cls == "construction_crate_small" then
            targetCrate = hitEnt

            -- Caisse déjà chargée ? → décharger
            if targetCrate.LoadedVehicle then
                targetCrate:UnloadFromVehicle()
                DarkRP.notify(ply, 0, 4, "Caisse dechargee !")
                return
            end

            -- Chercher un véhicule simfphys proche de la caisse
            for _, ent in ipairs(ents.FindInSphere(hitEnt:GetPos(), 300)) do
                if ent:GetClass() == "gmod_sent_vehicle_fphysics_base" then
                    vehicle = ent
                    break
                end
            end
        end
    end

    if vehicle then
        local dist = ply:GetPos():Distance(vehicle:GetPos())
        if dist > 400 then
            DarkRP.notify(ply, 1, 3, "Trop loin du vehicule !")
            return
        end

        -- Vérifier si ce véhicule a déjà une caisse chargée → décharger
        for _, cls in ipairs({"construction_crate", "construction_crate_small"}) do
            for _, ent in ipairs(ents.FindByClass(cls)) do
                if ent.LoadedVehicle == vehicle then
                    ent:UnloadFromVehicle()
                    DarkRP.notify(ply, 0, 4, "Caisse dechargee du vehicule !")
                    return
                end
            end
        end

        -- Charger : si on visait une caisse précise, l'utiliser ; sinon chercher la plus proche
        if not targetCrate then
            local vPos = vehicle:GetPos()
            for _, ent in ipairs(ents.FindInSphere(vPos, 300)) do
                local cls = ent:GetClass()
                if (cls == "construction_crate" or cls == "construction_crate_small")
                   and not ent.LoadedVehicle then
                    targetCrate = ent
                    break
                end
            end
        end

        if targetCrate then
            targetCrate:LoadOntoVehicle(vehicle)
            DarkRP.notify(ply, 0, 4, "Caisse chargee ! (" .. targetCrate:GetRemainingMats() .. " materiaux)")
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
