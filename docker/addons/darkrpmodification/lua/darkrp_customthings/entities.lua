--[[-----------------------------------------------------------------------
    DarkRP Entities - Projet Fil Rouge
---------------------------------------------------------------------------]]

DarkRP.createEntity("Caisse de Materiaux", {
    ent = "construction_crate",
    model = "models/props_junk/wood_crate001a.mdl",
    price = 1,
    max = 2,  -- Synchronisé avec ConstructionSystem.Config.MaxCratesPerPlayer
    cmd = "buycrate",
    allowed = {TEAM_BUILDER},
    category = "Construction",
})
