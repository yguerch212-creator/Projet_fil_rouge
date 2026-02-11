--[[-----------------------------------------------------------------------
    RP Construction System - Module Véhicules (Client)
    HUD indicateur + touche E pour charger/décharger les caisses
    Fonctionne sans SWEP — tout joueur peut charger/décharger
---------------------------------------------------------------------------]]

ConstructionSystem.Vehicles = ConstructionSystem.Vehicles or {}

-- Détection véhicule (même logique que serveur)
function ConstructionSystem.Vehicles.IsSupportedVehicle(ent)
    if not IsValid(ent) then return false end
    local class = ent:GetClass()
    return class == "gmod_sent_vehicle_fphysics_base" or
           string.StartWith(class, "sim_fphy") or
           string.StartWith(class, "simfphys_") or
           string.StartWith(class, "lvs_") or
           ent:IsVehicle()
end

-- Vérifier si le joueur regarde un véhicule compatible
function ConstructionSystem.Vehicles.GetLookedVehicle()
    local ply = LocalPlayer()
    if not IsValid(ply) then return nil end

    local tr = ply:GetEyeTrace()
    if not tr.Hit or not IsValid(tr.Entity) then return nil end
    if tr.HitPos:Distance(ply:GetPos()) > 300 then return nil end

    if ConstructionSystem.Vehicles.IsSupportedVehicle(tr.Entity) then
        return tr.Entity
    end

    return nil
end

-- Chercher une caisse proche (non attachée)
function ConstructionSystem.Vehicles.FindNearbyCrate()
    local ply = LocalPlayer()
    if not IsValid(ply) then return false end

    for _, ent in pairs(ents.GetAll()) do
        if IsValid(ent) and (ent:GetClass() == "construction_crate" or ent:GetClass() == "construction_crate_small") then
            if not ent:GetNWBool("attached_to_vehicle", false) and ent:GetPos():Distance(ply:GetPos()) < 200 then
                return true
            end
        end
    end
    return false
end

-- Cooldown anti-spam
local lastAction = 0

-- HUD : affiche les instructions quand on regarde un véhicule
hook.Add("HUDPaint", "Construction_VehicleHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if ply:InVehicle() then return end

    local vehicle = ConstructionSystem.Vehicles.GetLookedVehicle()
    if not IsValid(vehicle) then return end

    local hasCrate = vehicle:GetNWBool("has_crate", false)
    local nearCrate = ConstructionSystem.Vehicles.FindNearbyCrate()

    -- Rien à montrer si pas de caisse et pas de caisse proche
    if not hasCrate and not nearCrate then return end

    -- Afficher les instructions
    local boxW, boxH = 320, 50
    local boxX = ScrW() / 2 - boxW / 2
    local boxY = ScrH() / 2 + 60

    draw.RoundedBox(6, boxX, boxY, boxW, boxH, Color(30, 30, 30, 200))

    if hasCrate then
        draw.SimpleText("[R] Décharger la caisse", "DermaDefaultBold",
            boxX + boxW / 2, boxY + boxH / 2, Color(255, 180, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif nearCrate then
        draw.SimpleText("[R] Charger la caisse dans le véhicule", "DermaDefaultBold",
            boxX + boxW / 2, boxY + boxH / 2, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- Bind : touche E sur un véhicule (quand pas dans le véhicule) = charger/décharger
hook.Add("PlayerBindPress", "Construction_VehicleBind", function(ply, bind, pressed)
    if not pressed then return end
    if not string.find(bind, "+reload") then return end
    if ply:InVehicle() then return end

    -- Cooldown
    if CurTime() - lastAction < 1 then return end

    local vehicle = ConstructionSystem.Vehicles.GetLookedVehicle()
    if not IsValid(vehicle) then return end

    local hasCrate = vehicle:GetNWBool("has_crate", false)
    local nearCrate = ConstructionSystem.Vehicles.FindNearbyCrate()

    if not hasCrate and not nearCrate then return end

    lastAction = CurTime()

    if hasCrate then
        net.Start("Construction_DetachCrate")
        net.WriteEntity(vehicle)
        net.SendToServer()
    elseif nearCrate then
        net.Start("Construction_AttachCrate")
        net.WriteEntity(vehicle)
        net.SendToServer()
    end

    return true -- Bloquer le Use normal (sinon entre dans le véhicule)
end)
