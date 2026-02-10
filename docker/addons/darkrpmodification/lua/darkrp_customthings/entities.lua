--[[-----------------------------------------------------------------------
    DarkRP Entities - Projet Fil Rouge
---------------------------------------------------------------------------]]

DarkRP.createEntity("Grosse Caisse de Materiaux", {
    ent = "construction_crate",
    model = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl",
    price = 1,
    max = 2,
    cmd = "buycrate",
    allowed = {TEAM_BUILDER},  -- Restreint aux Constructeurs (ajouter d'autres TEAM_ si besoin)
    category = "Construction",
})

DarkRP.createEntity("Petite Caisse de Materiaux", {
    ent = "construction_crate_small",
    model = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl",
    price = 1,
    max = 4,
    cmd = "buysmallcrate",
    allowed = {TEAM_BUILDER},  -- Restreint aux Constructeurs (ajouter d'autres TEAM_ si besoin)
    category = "Construction",
})
