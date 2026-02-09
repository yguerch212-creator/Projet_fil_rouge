--[[-----------------------------------------------------------------------
    RP Construction System - Configuration partagée (Shared)
    Ce fichier est chargé côté serveur ET client.
---------------------------------------------------------------------------]]

ConstructionSystem = ConstructionSystem or {}
ConstructionSystem.Config = ConstructionSystem.Config or {}

-- Version
ConstructionSystem.Config.Version = "1.0.0"

-- Limites
ConstructionSystem.Config.MaxPropsPerBlueprint = 50      -- Nombre max de props par blueprint
ConstructionSystem.Config.MaxBlueprintsPerPlayer = 20    -- Nombre max de blueprints sauvegardés
ConstructionSystem.Config.MaxNameLength = 50             -- Longueur max du nom d'un blueprint
ConstructionSystem.Config.MaxDescLength = 200            -- Longueur max de la description

-- Coûts (DarkRP money)
ConstructionSystem.Config.SaveCost = 100                 -- Coût pour sauvegarder un blueprint
ConstructionSystem.Config.LoadCost = 50                  -- Coût pour charger un blueprint
ConstructionSystem.Config.ShareCost = 25                 -- Coût pour partager un blueprint

-- Cooldowns (en secondes)
ConstructionSystem.Config.SaveCooldown = 10              -- Cooldown entre deux sauvegardes
ConstructionSystem.Config.LoadCooldown = 15              -- Cooldown entre deux chargements
ConstructionSystem.Config.SelectionRadius = 500          -- Rayon max de sélection de props

-- Jobs autorisés (nil = tous les jobs peuvent utiliser)
ConstructionSystem.Config.AllowedJobs = nil              -- Mettre {TEAM_BUILDER} pour restreindre

-- Database
ConstructionSystem.Config.DB = {
    Host = "gmod-mysql",
    Port = 3306,
    User = "gmod_user",
    Password = "GmodUserPass2025!",
    Database = "gmod_construction",
}

-- Net messages
ConstructionSystem.NetMessages = {
    "Construction_OpenMenu",
    "Construction_RequestBlueprints",
    "Construction_SendBlueprints",
    "Construction_SaveBlueprint",
    "Construction_LoadBlueprint",
    "Construction_DeleteBlueprint",
    "Construction_ShareBlueprint",
    "Construction_Notification",
    -- Sélection
    "Construction_SelectToggle",
    "Construction_SelectRadius",
    "Construction_SelectClear",
    "Construction_RequestSync",
    "Construction_SyncSelection",
}
