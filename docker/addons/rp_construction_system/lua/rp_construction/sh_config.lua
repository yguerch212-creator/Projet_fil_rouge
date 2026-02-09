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
ConstructionSystem.Config.MaxPropsPerBlueprint = 50
ConstructionSystem.Config.MaxBlueprintsPerPlayer = 20
ConstructionSystem.Config.MaxNameLength = 50
ConstructionSystem.Config.MaxDescLength = 200

---------------------------------------------------------------------------
-- COOLDOWNS (secondes)
---------------------------------------------------------------------------
ConstructionSystem.Config.SaveCooldown = 10
ConstructionSystem.Config.LoadCooldown = 15
ConstructionSystem.Config.SelectionRadius = 500

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
-- JOBS
---------------------------------------------------------------------------
-- Mettre les TEAM_ autorisés, nil = tout le monde
ConstructionSystem.Config.AllowedJobs = nil  -- Sera configuré quand TEAM_BUILDER existe

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
}
