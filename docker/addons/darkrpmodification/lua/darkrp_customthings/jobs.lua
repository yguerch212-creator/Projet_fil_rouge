--[[-----------------------------------------------------------------------
    DarkRP Custom Jobs - Projet Fil Rouge
    Jobs personnalisés pour le serveur RP Construction
---------------------------------------------------------------------------]]

-- Job Constructeur (lié à notre addon principal)
TEAM_BUILDER = DarkRP.createJob("Constructeur", {
    color = Color(0, 128, 255, 255),
    model = {"models/player/eli.mdl"},
    description = [[Tu es un constructeur professionnel.
    Utilise le système de blueprints pour créer et sauvegarder des structures.
    Tu peux vendre tes services aux autres joueurs.]],
    weapons = {"weapon_physgun", "gmod_tool"},
    command = "builder",
    max = 5,
    salary = 65,
    admin = 0,
    vote = false,
    hasLicense = false,
    category = "Civil",
})
