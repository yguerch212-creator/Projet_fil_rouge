--[[-----------------------------------------------------------------------
    RP Construction System - Configuration partagée (Shared)
    Ce fichier est chargé côté serveur ET client.
---------------------------------------------------------------------------]]

ConstructionSystem = ConstructionSystem or {}
ConstructionSystem.Config = ConstructionSystem.Config or {}

-- Version
ConstructionSystem.Config.Version = "2.0.0"

---------------------------------------------------------------------------
-- LIMITES
---------------------------------------------------------------------------
ConstructionSystem.Config.MaxPropsPerBlueprint = 150   -- Max props par blueprint (0 = illimité)
ConstructionSystem.Config.MaxBlueprintsPerPlayer = 0    -- Max blueprints par joueur (0 = illimité)
ConstructionSystem.Config.MaxCratesPerPlayer = 2        -- Max caisses simultanées par joueur (0 = illimité)
ConstructionSystem.Config.MaxNameLength = 50
ConstructionSystem.Config.MaxDescLength = 200

---------------------------------------------------------------------------
-- COOLDOWNS (secondes)
---------------------------------------------------------------------------
ConstructionSystem.Config.SaveCooldown = 10
ConstructionSystem.Config.LoadCooldown = 15

---------------------------------------------------------------------------
-- SÉLECTION
---------------------------------------------------------------------------
ConstructionSystem.Config.SelectionRadiusMin = 50       -- Rayon minimum
ConstructionSystem.Config.SelectionRadiusMax = 1000     -- Rayon maximum (max 1023 pour net)
ConstructionSystem.Config.SelectionRadiusDefault = 500  -- Rayon par défaut

---------------------------------------------------------------------------
-- CAISSE DE MATÉRIAUX
---------------------------------------------------------------------------
-- Modèle préféré (workshop Resistance & Liberation): "models/hts/ww2ns/props/dun/dun_wood_crate_003.mdl"
-- Fallback HL2 si le workshop n'est pas monté
ConstructionSystem.Config.CrateModel = "models/props_junk/wood_crate001a.mdl"
ConstructionSystem.Config.CrateModelPreferred = "models/hts/ww2ns/props/dun/dun_wood_crate_003.mdl"
ConstructionSystem.Config.CrateMaxMaterials = 30   -- Nombre de props matérialisables par caisse
ConstructionSystem.Config.CratePrice = 1            -- Prix F4

---------------------------------------------------------------------------
-- SÉCURITÉ : entités interdites dans les blueprints
---------------------------------------------------------------------------
ConstructionSystem.Config.BlacklistedEntities = {
    "prop_physics_multiplayer",
    "money_printer",
    "darkrp_money",
    "spawned_money",
    "spawned_shipment",
    "spawned_weapon",
    "drug_lab",
    "gun_lab",
    "microwave",
    "bitminers_",  -- pattern
}

-- Seuls les prop_physics sont autorisés
ConstructionSystem.Config.AllowedClasses = {
    ["prop_physics"] = true,
}

---------------------------------------------------------------------------
-- JOBS & SWEP
---------------------------------------------------------------------------
-- Liste des TEAM_ autorisés à utiliser le système (nil = tout le monde)
ConstructionSystem.Config.AllowedJobs = nil

-- Jobs qui reçoivent automatiquement le SWEP weapon_construction
-- Ajoutez vos jobs existants ici, ex: {TEAM_BUILDER, TEAM_ARCHITECT}
-- nil = personne ne reçoit le SWEP auto (les joueurs doivent le recevoir autrement)
ConstructionSystem.Config.SWEPJobs = nil  -- Configuré après le chargement des jobs (voir sv_construction_init.lua)

---------------------------------------------------------------------------
-- DATABASE
---------------------------------------------------------------------------
ConstructionSystem.Config.DB = {
    Host = "gmod-mysql",
    Port = 3306,
    User = "gmod_user",
    Password = "GmodUserPass2025!",
    Database = "gmod_construction",
}

---------------------------------------------------------------------------
-- NET MESSAGES
---------------------------------------------------------------------------
ConstructionSystem.NetMessages = {
    -- Menu / Blueprints
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
    -- Ghosts
    "Construction_SpawnGhosts",
    "Construction_RemoveGhosts",
    "Construction_MaterializeGhost",
    -- Placement
    "Construction_SendPreview",
    "Construction_ConfirmPlacement",
    "Construction_CancelPlacement",
}
