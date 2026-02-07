--[[-----------------------------------------------------------------------
    DarkRP Vehicles - Projet Fil Rouge
    Véhicules disponibles à l'achat dans le F4 menu
    
    Note : Les véhicules simfphys ne sont PAS compatibles avec
    DarkRP.createVehicle() car ce ne sont pas des véhicules Valve.
    Ils nécessitent un système d'achat custom (voir sv_simfphys_shop.lua).
    
    Ici on ne met que les véhicules Valve (HL2) classiques.
---------------------------------------------------------------------------]]

DarkRP.createVehicle({
    name = "Jeep",
    model = "models/buggy.mdl",
    price = 600,
    allowed = {},
    label = "Jeep HL2",
    category = "Transport",
})

DarkRP.createVehicle({
    name = "Airboat",
    model = "models/airboat.mdl",
    price = 1200,
    allowed = {},
    label = "Airboat HL2",
    category = "Transport",
})

DarkRP.createVehicle({
    name = "Jalopy",
    model = "models/vehicle.mdl",
    price = 800,
    allowed = {},
    label = "Jalopy EP2",
    category = "Transport",
})
