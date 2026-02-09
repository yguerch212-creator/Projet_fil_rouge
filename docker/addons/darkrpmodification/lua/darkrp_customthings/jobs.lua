--[[-----------------------------------------------------------------------
    DarkRP Jobs - Projet Fil Rouge
---------------------------------------------------------------------------]]

TEAM_BUILDER = DarkRP.createJob("Constructeur", {
    color = Color(0, 100, 200, 255),
    model = "models/player/hostage/hostage_04.mdl",
    description = "Vous construisez des batiments pour les citoyens. Selectionnez vos props, sauvegardez des blueprints et posez des constructions fantomes.",
    weapons = {"weapon_construction"},
    command = "constructeur",
    max = 4,
    salary = 65,
    admin = 0,
    vote = false,
    hasLicense = false,
    candemote = true,
    category = "Civil",
})
