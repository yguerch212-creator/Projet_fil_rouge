--[[-----------------------------------------------------------------------
    DarkRP Entities - Projet Fil Rouge
---------------------------------------------------------------------------]]

DarkRP.createEntity("Grosse Caisse de Materiaux", {
    ent = "construction_crate",
    model = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl",
    price = 1,
    max = 2,
    cmd = "buycrate",
    allowed = {},  -- Tout le monde (configurable par le serveur)
    category = "Construction",
})

DarkRP.createEntity("Petite Caisse de Materiaux", {
    ent = "construction_crate_small",
    model = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl",
    price = 1,
    max = 4,
    cmd = "buysmallcrate",
    allowed = {},  -- Tout le monde (configurable par le serveur)
    category = "Construction",
})
