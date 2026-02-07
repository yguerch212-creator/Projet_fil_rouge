--[[-----------------------------------------------------------------------
    Simfphys Vehicle Shop - Module DarkRP
    Permet l'achat de véhicules simfphys via chat commands
    Les véhicules simfphys ne sont pas des véhicules Valve,
    donc DarkRP.createVehicle() ne fonctionne pas avec eux.
---------------------------------------------------------------------------]]

-- Table des véhicules simfphys disponibles
local SimfphysVehicles = {
    ["tdmjeep"] = {
        name = "Jeep TDM",
        class = "sim_fphys_tdm_jeep",
        price = 1500,
        model = "models/tdmcars/jeep.mdl",
    },
    -- Ajouter d'autres véhicules ici au fur et à mesure
}

-- Cooldown par joueur
local buyCooldowns = {}

-- Fonction d'achat
local function BuySimfphysVehicle(ply, args)
    if not args or args == "" then
        DarkRP.notify(ply, 1, 4, "Usage: /buysimfphys <nom_vehicule>")

        local available = {}
        for id, v in pairs(SimfphysVehicles) do
            table.insert(available, id .. " - " .. v.name .. " ($" .. v.price .. ")")
        end
        ply:ChatPrint("Véhicules disponibles: " .. table.concat(available, ", "))
        return ""
    end

    -- Rate limit
    if buyCooldowns[ply] and buyCooldowns[ply] > CurTime() then
        DarkRP.notify(ply, 1, 4, "Attends avant d'acheter un autre véhicule !")
        return ""
    end

    local vehicleId = string.lower(string.Trim(args))
    local vehicle = SimfphysVehicles[vehicleId]

    if not vehicle then
        DarkRP.notify(ply, 1, 4, "Véhicule inconnu: " .. vehicleId)
        return ""
    end

    -- Vérifier l'argent
    if not ply:canAfford(vehicle.price) then
        DarkRP.notify(ply, 1, 4, "Tu n'as pas assez d'argent ! ($" .. vehicle.price .. " requis)")
        return ""
    end

    -- Vérifier que simfphys est disponible
    if not simfphys or not simfphys.SpawnVehicleSimple then
        DarkRP.notify(ply, 1, 4, "Le système simfphys n'est pas installé sur ce serveur.")
        return ""
    end

    -- Trouver la position de spawn devant le joueur
    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 200,
        filter = ply
    })

    local spawnPos = tr.HitPos + Vector(0, 0, 30)
    local spawnAng = Angle(0, ply:GetAngles().y + 90, 0)

    -- Spawner le véhicule
    local success, veh = pcall(function()
        return simfphys.SpawnVehicleSimple(vehicle.class, spawnPos, spawnAng)
    end)

    if not success or not IsValid(veh) then
        DarkRP.notify(ply, 1, 4, "Erreur lors du spawn du véhicule.")
        print("[SimfphysShop] Erreur spawn " .. vehicle.class .. ": " .. tostring(veh))
        return ""
    end

    -- Retirer l'argent
    ply:addMoney(-vehicle.price)

    -- Assigner la propriété
    if veh.CPPISetOwner then
        veh:CPPISetOwner(ply)
    end

    -- Undo
    undo.Create("Simfphys Vehicle")
        undo.AddEntity(veh)
        undo.SetPlayer(ply)
        undo.SetCustomUndoText("Undone " .. vehicle.name)
    undo.Finish()

    -- Cleanup quand le joueur part
    ply:AddCleanup("vehicles", veh)

    -- Cooldown 5 secondes
    buyCooldowns[ply] = CurTime() + 5

    DarkRP.notify(ply, 0, 4, vehicle.name .. " acheté pour $" .. vehicle.price .. " !")
    return ""
end

DarkRP.defineChatCommand("buysimfphys", BuySimfphysVehicle)
