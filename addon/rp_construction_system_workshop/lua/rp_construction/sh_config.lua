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
-- Grosse caisse (50 matériaux, transportable en camion)
ConstructionSystem.Config.CrateModel = "models/hts/ww2ns/props/dun/dun_wood_crate_03.mdl"
ConstructionSystem.Config.CrateMaxMaterials = 50
ConstructionSystem.Config.CratePrice = 1

-- Petite caisse (15 matériaux, spawn sur place)
ConstructionSystem.Config.SmallCrateModel = "models/props_supplies/german/r_crate_pak50mm_stacked.mdl"
ConstructionSystem.Config.SmallCrateMaxMaterials = 15
ConstructionSystem.Config.SmallCratePrice = 1

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

-- Jobs autorisés à spawner ET utiliser les caisses de matériaux
-- Table de TEAM_ IDs. nil = tout le monde peut utiliser les caisses
-- Ex: {TEAM_BUILDER, TEAM_ARCHITECT, TEAM_MAYOR}
ConstructionSystem.Config.CrateAllowedJobs = nil  -- Configuré après le chargement des jobs

---------------------------------------------------------------------------
-- NET MESSAGES
---------------------------------------------------------------------------
ConstructionSystem.NetMessages = {
    -- Menu
    "Construction_OpenMenu",
    -- Blueprints (client ↔ serveur)
    "Construction_SaveBlueprint",       -- Client → Serveur : demande sérialisation
    "Construction_SaveToClient",        -- Serveur → Client : données sérialisées pour stockage local
    "Construction_LoadBlueprint",       -- Client → Serveur : envoie blueprint local pour validation
    -- Sélection
    "Construction_SelectToggle",
    "Construction_SelectRadius",
    "Construction_SelectClear",
    "Construction_RequestSync",
    "Construction_SyncSelection",
    -- Placement
    "Construction_SendPreview",         -- Serveur → Client : preview après validation
    "Construction_ConfirmPlacement",    -- Client → Serveur : confirmer position
    "Construction_CancelPlacement",     -- Client → Serveur : annuler
    -- Ghosts
    "Construction_MaterializeGhost",    -- Client → Serveur : matérialiser un ghost
    -- Véhicules
    "Construction_AttachCrate",         -- Client → Serveur : charger une caisse
    "Construction_DetachCrate",         -- Client → Serveur : décharger une caisse
}
