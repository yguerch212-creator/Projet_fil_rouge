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
    -- simfphys WW2 (offsets calibrés pour le cargo bed)
    ["sim_fphy_codww2opel"]            = { pos = Vector(-80, 0, 35),  ang = Angle(0, 0, 0) },
    ["sim_fphy_codww2opel_ammo"]       = { pos = Vector(-80, 0, 35),  ang = Angle(0, 0, 0) },
    ["simfphys_cbww2_cckw6x6"]         = { pos = Vector(-100, 0, 40), ang = Angle(0, 0, 0) },
    ["simfphys_cbww2_cckw6x6_ammo"]    = { pos = Vector(-100, 0, 40), ang = Angle(0, 0, 0) },
}

-- Offset par défaut pour les véhicules non listés
ConstructionSystem.Vehicles.DefaultOffset = { pos = Vector(-70, 0, 10), ang = Angle(0, 0, 0) }

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

    -- Offset par défaut basé sur la taille du véhicule (dans le cargo, pas au-dessus)
    local mins, maxs = ent:GetModelBounds()
    if mins and maxs then
        return {
            pos = Vector(mins.x * 0.5, 0, 10),
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

    -- Vérifier le nombre de caisses attachées (max 2 grosses)
    vehicle.ConstructionCrates = vehicle.ConstructionCrates or {}

    -- Nettoyer les entrées invalides
    for i = #vehicle.ConstructionCrates, 1, -1 do
        if not IsValid(vehicle.ConstructionCrates[i]) then
            table.remove(vehicle.ConstructionCrates, i)
        end
    end

    local maxCrates = 2
    if #vehicle.ConstructionCrates >= maxCrates then
        return false, "Ce véhicule est plein (" .. maxCrates .. " caisses max)"
    end

    -- Vérifier que la caisse n'est pas déjà attachée
    if crate:GetNWBool("attached_to_vehicle", false) then
        return false, "Cette caisse est déjà attachée"
    end

    local offset = ConstructionSystem.Vehicles.GetCargoOffset(vehicle)
    if not offset then return false, "Impossible de calculer la position" end

    -- Décaler la 2ème caisse sur le côté
    local crateIndex = #vehicle.ConstructionCrates
    local finalPos = Vector(offset.pos.x, offset.pos.y, offset.pos.z)
    if crateIndex == 1 then
        finalPos.y = finalPos.y + 30 -- 2ème caisse décalée à droite
    elseif crateIndex == 0 then
        finalPos.y = finalPos.y - 15 -- 1ère caisse légèrement à gauche
    end

    -- Attacher
    crate:SetParent(vehicle)
    crate:SetLocalPos(finalPos)
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
    vehicle:SetNWInt("crate_count", crateIndex + 1)
    table.insert(vehicle.ConstructionCrates, crate)

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

    -- Calculer la position de déchargement (à côté du véhicule, pas à l'origine)
    local dropPos = crate:GetPos() -- Position actuelle (monde) avant détach
    local dropAng = Angle(0, 0, 0)

    if IsValid(vehicle) then
        -- Déposer sur le côté droit du véhicule, au sol
        local vRight = vehicle:GetRight()
        local vPos = vehicle:GetPos()
        dropPos = vPos + vRight * 120 + Vector(0, 0, 20)
        dropAng = vehicle:GetAngles()
        dropAng.p = 0
        dropAng.r = 0
    end

    -- Détacher
    crate:SetParent(nil)
    crate:SetPos(dropPos)
    crate:SetAngles(dropAng)
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
        vehicle.ConstructionCrates = vehicle.ConstructionCrates or {}
        for i, c in ipairs(vehicle.ConstructionCrates) do
            if c == crate then
                table.remove(vehicle.ConstructionCrates, i)
                break
            end
        end
        vehicle:SetNWInt("crate_count", #vehicle.ConstructionCrates)
        vehicle:SetNWBool("has_crate", #vehicle.ConstructionCrates > 0)
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

    for _, ent in pairs(ents.GetAll()) do
        if IsValid(ent) and (ent:GetClass() == "construction_crate" or ent:GetClass() == "construction_crate_small") then
            if not ent:GetNWBool("attached_to_vehicle", false) then
                local dist = ent:GetPos():Distance(ply:GetPos())
                if dist < closestDist then
                    closestDist = dist
                    closestCrate = ent
                end
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

    vehicle.ConstructionCrates = vehicle.ConstructionCrates or {}
    -- Nettoyer
    for i = #vehicle.ConstructionCrates, 1, -1 do
        if not IsValid(vehicle.ConstructionCrates[i]) then
            table.remove(vehicle.ConstructionCrates, i)
        end
    end

    if #vehicle.ConstructionCrates == 0 then
        ply:ChatPrint("[Construction] Ce véhicule n'a pas de caisse")
        return
    end

    -- Détacher la dernière caisse chargée
    local lastCrate = vehicle.ConstructionCrates[#vehicle.ConstructionCrates]
    local success, err = ConstructionSystem.Vehicles.DetachCrate(lastCrate)
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
    if ent.ConstructionCrates then
        for _, crate in ipairs(ent.ConstructionCrates) do
            if IsValid(crate) then
                ConstructionSystem.Vehicles.DetachCrate(crate)
            end
        end
    end
end)

print("[Construction] Module véhicules chargé (simfphys + LVS + Source)")
