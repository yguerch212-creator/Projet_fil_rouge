--[[-----------------------------------------------------------------------
    DarkRP Entities - Projet Fil Rouge
    Entités achetables dans le F4 menu
---------------------------------------------------------------------------]]

DarkRP.createEntity("Caisse de Materiaux", {
    ent = "construction_crate",
    model = "models/hts/ww2ns/props/dun/dun_wood_crate_003.mdl",
    price = 1,
    max = 5,
    cmd = "buycrate",
    allowed = {TEAM_BUILDER},
    category = "Construction",
})
