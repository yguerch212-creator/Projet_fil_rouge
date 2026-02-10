--[[-----------------------------------------------------------------------
    RP Construction System - Module Véhicules (Client)
    HUD indicateur + binds pour charger/décharger les caisses
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

-- HUD : affiche les instructions quand on regarde un véhicule
hook.Add("HUDPaint", "Construction_VehicleHUD", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Seulement si le joueur a le SWEP de construction
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_construction" then return end

    local vehicle = ConstructionSystem.Vehicles.GetLookedVehicle()
    if not IsValid(vehicle) then return end

    local hasCrate = vehicle:GetNWBool("has_crate", false) or
                     (vehicle.ConstructionCrate and IsValid(vehicle.ConstructionCrate))

    -- Chercher si une caisse est proche
    local nearCrate = false
    for _, ent in pairs(ents.FindByClass("construction_crate")) do
        if IsValid(ent) and not ent:GetNWBool("attached_to_vehicle", false) then
            if ent:GetPos():Distance(ply:GetPos()) < 200 then
                nearCrate = true
                break
            end
        end
    end

    -- Afficher les instructions
    local boxW, boxH = 320, 50
    local boxX = ScrW() / 2 - boxW / 2
    local boxY = ScrH() / 2 + 60

    draw.RoundedBox(6, boxX, boxY, boxW, boxH, Color(30, 30, 30, 200))

    if hasCrate then
        draw.SimpleText("Appuyez [R] pour décharger la caisse", "DermaDefaultBold",
            boxX + boxW / 2, boxY + boxH / 2, Color(255, 180, 50), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    elseif nearCrate then
        draw.SimpleText("Appuyez [R] pour charger la caisse", "DermaDefaultBold",
            boxX + boxW / 2, boxY + boxH / 2, Color(100, 255, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.SimpleText("Véhicule compatible", "DermaDefault",
            boxX + boxW / 2, boxY + boxH / 2, Color(150, 150, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end)

-- Bind : Reload (R) sur un véhicule = charger/décharger
hook.Add("PlayerBindPress", "Construction_VehicleBind", function(ply, bind, pressed)
    if not pressed then return end
    if not string.find(bind, "+reload") then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_construction" then return end

    local vehicle = ConstructionSystem.Vehicles.GetLookedVehicle()
    if not IsValid(vehicle) then return end

    -- Vérifier si le véhicule a une caisse
    local hasCrate = vehicle:GetNWBool("has_crate", false)

    if hasCrate then
        net.Start("Construction_DetachCrate")
        net.WriteEntity(vehicle)
        net.SendToServer()
    else
        net.Start("Construction_AttachCrate")
        net.WriteEntity(vehicle)
        net.SendToServer()
    end

    return true -- Bloquer le reload normal du SWEP
end)
