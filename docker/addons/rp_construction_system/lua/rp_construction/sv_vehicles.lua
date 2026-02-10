--[[-----------------------------------------------------------------------
    RP Construction System - Module Véhicules
    Permet d'attacher/détacher une caisse de matériaux à un véhicule
    Compatible: simfphys, LVS, véhicules Source natifs
---------------------------------------------------------------------------]]

ConstructionSystem.Vehicles = ConstructionSystem.Vehicles or {}

-- Configuration des offsets de chargement par modèle de véhicule
-- Ajoutez vos véhicules ici : [entity_class] = { pos = Vector, ang = Angle }
-- pos est relatif au centre du véhicule (x=avant, y=gauche, z=haut)
ConstructionSystem.Vehicles.CargoOffsets = {
    -- simfphys WW2
    ["sim_fphy_codww2opel"]            = { pos = Vector(-80, 0, 40),  ang = Angle(0, 0, 0) },
    ["sim_fphy_codww2opel_ammo"]       = { pos = Vector(-80, 0, 40),  ang = Angle(0, 0, 0) },
    ["simfphys_cbww2_cckw6x6"]         = { pos = Vector(-100, 0, 50), ang = Angle(0, 0, 0) },
    ["simfphys_cbww2_cckw6x6_ammo"]    = { pos = Vector(-100, 0, 50), ang = Angle(0, 0, 0) },
}

-- Offset par défaut pour les véhicules non listés
ConstructionSystem.Vehicles.DefaultOffset = { pos = Vector(-70, 0, 45), ang = Angle(0, 0, 0) }

---------------------------------------------------------------------------
-- Détection du type de véhicule
---------------------------------------------------------------------------

function ConstructionSystem.Vehicles.IsSimfphys(ent)
    if not IsValid(ent) then return false end
    local class = ent:GetClass()
    return class == "gmod_sent_vehicle_fphysics_base" or
           string.StartWith(class, "sim_fphy") or
           string.StartWith(class, "simfphys_")
end

function ConstructionSystem.Vehicles.IsLVS(ent)
    if not IsValid(ent) then return false end
    local class = ent:GetClass()
    return string.StartWith(class, "lvs_")
end

function ConstructionSystem.Vehicles.IsSourceVehicle(ent)
    if not IsValid(ent) then return false end
    return ent:IsVehicle()
end

function ConstructionSystem.Vehicles.IsSupportedVehicle(ent)
    return ConstructionSystem.Vehicles.IsSimfphys(ent) or
           ConstructionSystem.Vehicles.IsLVS(ent) or
           ConstructionSystem.Vehicles.IsSourceVehicle(ent)
end

---------------------------------------------------------------------------
-- Obtenir l'offset cargo pour un véhicule
---------------------------------------------------------------------------

function ConstructionSystem.Vehicles.GetCargoOffset(ent)
    if not IsValid(ent) then return nil end

    local class = ent:GetClass()

    -- Chercher dans les offsets configurés
    if ConstructionSystem.Vehicles.CargoOffsets[class] then
        return ConstructionSystem.Vehicles.CargoOffsets[class]
    end

    -- Pour simfphys, chercher par le spawn name (dans la table de spawn)
    if ConstructionSystem.Vehicles.IsSimfphys(ent) then
        local spawnName = ent.VehicleData and ent.VehicleData.Name
        if spawnName and ConstructionSystem.Vehicles.CargoOffsets[spawnName] then
            return ConstructionSystem.Vehicles.CargoOffsets[spawnName]
        end
    end

    -- Offset par défaut basé sur la taille du véhicule
    local mins, maxs = ent:GetModelBounds()
    if mins and maxs then
        return {
            pos = Vector(mins.x * 0.6, 0, maxs.z + 5),
            ang = Angle(0, 0, 0)
        }
    end

    return ConstructionSystem.Vehicles.DefaultOffset
end

---------------------------------------------------------------------------
-- Attacher une caisse à un véhicule
---------------------------------------------------------------------------

function ConstructionSystem.Vehicles.AttachCrate(crate, vehicle)
    if not IsValid(crate) or not IsValid(vehicle) then return false, "Entité invalide" end

    -- Vérifier que c'est un véhicule supporté
    if not ConstructionSystem.Vehicles.IsSupportedVehicle(vehicle) then
        return false, "Ce véhicule n'est pas supporté"
    end

    -- Vérifier qu'il n'y a pas déjà une caisse attachée
    if vehicle.ConstructionCrate and IsValid(vehicle.ConstructionCrate) then
        return false, "Ce véhicule a déjà une caisse"
    end

    -- Vérifier que la caisse n'est pas déjà attachée
    if crate:GetNWBool("attached_to_vehicle", false) then
        return false, "Cette caisse est déjà attachée"
    end

    local offset = ConstructionSystem.Vehicles.GetCargoOffset(vehicle)
    if not offset then return false, "Impossible de calculer la position" end

    -- Attacher
    crate:SetParent(vehicle)
    crate:SetLocalPos(offset.pos)
    crate:SetLocalAngles(offset.ang)

    -- Désactiver la physique de la caisse
    local phys = crate:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end

    -- Marquer l'attachement
    crate:SetNWBool("attached_to_vehicle", true)
    crate:SetNWEntity("parent_vehicle", vehicle)
    vehicle:SetNWBool("has_crate", true)
    vehicle.ConstructionCrate = crate

    -- Stocker le propriétaire d'origine
    crate._OriginalOwner = crate:GetNWEntity("owner")

    print("[Construction] Caisse attachée au véhicule " .. vehicle:GetClass())
    return true
end

---------------------------------------------------------------------------
-- Détacher une caisse d'un véhicule
---------------------------------------------------------------------------

function ConstructionSystem.Vehicles.DetachCrate(crate)
    if not IsValid(crate) then return false end
    if not crate:GetNWBool("attached_to_vehicle", false) then return false, "Pas attachée" end

    local vehicle = crate:GetNWEntity("parent_vehicle")

    -- Détacher
    crate:SetParent(nil)
    crate:SetNWBool("attached_to_vehicle", false)
    crate:SetNWEntity("parent_vehicle", NULL)

    -- Réactiver la physique
    local phys = crate:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(true)
        phys:Wake()
    end

    -- Nettoyer le véhicule
    if IsValid(vehicle) then
        vehicle:SetNWBool("has_crate", false)
        vehicle.ConstructionCrate = nil
    end

    print("[Construction] Caisse détachée du véhicule")
    return true
end

---------------------------------------------------------------------------
-- Net receivers : charger/décharger une caisse
---------------------------------------------------------------------------

-- Net messages enregistrés dans sv_construction_init.lua via ConstructionSystem.NetMessages

-- Joueur regarde un véhicule et appuie sur une touche pour charger sa caisse
net.Receive("Construction_AttachCrate", function(len, ply)
    if not IsValid(ply) then return end

    local vehicle = net.ReadEntity()
    if not IsValid(vehicle) then
        ply:ChatPrint("[Construction] Véhicule invalide")
        return
    end

    -- Trouver la caisse la plus proche du joueur
    local closestCrate = nil
    local closestDist = 200 -- rayon max

    for _, ent in pairs(ents.FindByClass("construction_crate")) do
        if IsValid(ent) and not ent:GetNWBool("attached_to_vehicle", false) then
            local dist = ent:GetPos():Distance(ply:GetPos())
            if dist < closestDist then
                closestDist = dist
                closestCrate = ent
            end
        end
    end

    if not closestCrate then
        ply:ChatPrint("[Construction] Aucune caisse à proximité")
        return
    end

    local success, err = ConstructionSystem.Vehicles.AttachCrate(closestCrate, vehicle)
    if success then
        ply:ChatPrint("[Construction] Caisse chargée dans le véhicule !")
    else
        ply:ChatPrint("[Construction] " .. (err or "Erreur"))
    end
end)

net.Receive("Construction_DetachCrate", function(len, ply)
    if not IsValid(ply) then return end

    local vehicle = net.ReadEntity()
    if not IsValid(vehicle) then return end

    if not vehicle.ConstructionCrate or not IsValid(vehicle.ConstructionCrate) then
        ply:ChatPrint("[Construction] Ce véhicule n'a pas de caisse")
        return
    end

    local success, err = ConstructionSystem.Vehicles.DetachCrate(vehicle.ConstructionCrate)
    if success then
        ply:ChatPrint("[Construction] Caisse déchargée !")
    else
        ply:ChatPrint("[Construction] " .. (err or "Erreur"))
    end
end)

---------------------------------------------------------------------------
-- Nettoyage : si le véhicule est supprimé, détacher la caisse
---------------------------------------------------------------------------

hook.Add("EntityRemoved", "Construction_VehicleRemoved", function(ent)
    if ent.ConstructionCrate and IsValid(ent.ConstructionCrate) then
        ConstructionSystem.Vehicles.DetachCrate(ent.ConstructionCrate)
    end
end)

print("[Construction] Module véhicules chargé (simfphys + LVS + Source)")
