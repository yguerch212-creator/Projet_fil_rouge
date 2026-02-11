--[[-----------------------------------------------------------------------
    RP Construction System - Module Base de Données (Server)
    Gère la connexion MySQLOO et toutes les opérations CRUD
    Utilise des prepared statements pour prévenir les injections SQL
---------------------------------------------------------------------------]]

local cfg = ConstructionSystem.Config.DB
local db = nil

ConstructionSystem.DB = ConstructionSystem.DB or {}

---------------------------------------------------------------------------
-- CONNEXION
---------------------------------------------------------------------------

--- Initialise la connexion à MySQL via MySQLOO
function ConstructionSystem.DB.Connect()
    -- Vérifier que MySQLOO est installé
    if not pcall(require, "mysqloo") then
        ErrorNoHaltWithStack("[Construction] ERREUR: MySQLOO n'est pas installé !\n")
        ErrorNoHaltWithStack("[Construction] Placez gmsv_mysqloo_linux64.dll dans garrysmod/lua/bin/\n")
        return false
    end

    print("[Construction] MySQLOO v" .. (mysqloo.VERSION or "?") .. " chargé")

    db = mysqloo.connect(cfg.Host, cfg.User, cfg.Password, cfg.Database, cfg.Port)

    function db:onConnected()
        print("[Construction] ✅ MySQL connecté - " .. self:hostInfo())
        print("[Construction] Serveur MySQL v" .. self:serverVersion())

        -- Créer/vérifier les tables au démarrage
        ConstructionSystem.DB.InitTables()
    end

    function db:onConnectionFailed(err)
        ErrorNoHaltWithStack("[Construction] ❌ MySQL connexion échouée: " .. tostring(err) .. "\n")
        -- Retry après 30 secondes
        timer.Simple(30, function()
            print("[Construction] Tentative de reconnexion MySQL...")
            ConstructionSystem.DB.Connect()
        end)
    end

    db:connect()
    return true
end

--- Vérifie si la base de données est connectée
function ConstructionSystem.DB.IsConnected()
    return db and db:status() == mysqloo.DATABASE_CONNECTED
end

--- Retourne l'objet database (pour usage avancé)
function ConstructionSystem.DB.GetDB()
    return db
end

---------------------------------------------------------------------------
-- INITIALISATION DES TABLES
---------------------------------------------------------------------------

function ConstructionSystem.DB.InitTables()
    if not ConstructionSystem.DB.IsConnected() then return end

    -- Table des blueprints
    local q1 = db:query([[
        CREATE TABLE IF NOT EXISTS blueprints (
            id INT AUTO_INCREMENT PRIMARY KEY,
            owner_steamid VARCHAR(32) NOT NULL,
            owner_name VARCHAR(64) NOT NULL,
            name VARCHAR(50) NOT NULL,
            description VARCHAR(200) DEFAULT '',
            data LONGTEXT NOT NULL,
            prop_count INT DEFAULT 0,
            constraint_count INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            is_public TINYINT(1) DEFAULT 0,
            INDEX idx_owner (owner_steamid),
            INDEX idx_public (is_public)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    q1.onSuccess = function() print("[Construction] Table 'blueprints' OK") end
    q1.onError = function(_, err) ErrorNoHaltWithStack("[Construction] Erreur table blueprints: " .. err .. "\n") end
    q1:start()

    -- Table des permissions de partage
    local q2 = db:query([[
        CREATE TABLE IF NOT EXISTS blueprint_permissions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            blueprint_id INT NOT NULL,
            target_steamid VARCHAR(32) NOT NULL,
            permission_level ENUM('view', 'use', 'edit') DEFAULT 'use',
            granted_by VARCHAR(32) NOT NULL,
            granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (blueprint_id) REFERENCES blueprints(id) ON DELETE CASCADE,
            UNIQUE KEY uk_bp_target (blueprint_id, target_steamid),
            INDEX idx_target (target_steamid)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    q2.onSuccess = function() print("[Construction] Table 'blueprint_permissions' OK") end
    q2.onError = function(_, err) ErrorNoHaltWithStack("[Construction] Erreur table permissions: " .. err .. "\n") end
    q2:start()

    -- Table des logs
    local q3 = db:query([[
        CREATE TABLE IF NOT EXISTS blueprint_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            steamid VARCHAR(32) NOT NULL,
            player_name VARCHAR(64) NOT NULL,
            action ENUM('save', 'load', 'delete', 'share', 'unshare', 'update') NOT NULL,
            blueprint_id INT DEFAULT NULL,
            blueprint_name VARCHAR(50) DEFAULT '',
            details TEXT DEFAULT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_steamid (steamid),
            INDEX idx_action (action),
            INDEX idx_date (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
    q3.onSuccess = function() print("[Construction] Table 'blueprint_logs' OK") end
    q3.onError = function(_, err) ErrorNoHaltWithStack("[Construction] Erreur table logs: " .. err .. "\n") end
    q3:start()
end

---------------------------------------------------------------------------
-- HELPERS
---------------------------------------------------------------------------

--- Exécute une query simple avec callbacks
local function RunQuery(sql, onSuccess, onError)
    if not ConstructionSystem.DB.IsConnected() then
        if onError then onError("Database not connected") end
        return
    end

    local q = db:query(sql)
    q.onSuccess = function(self, data) if onSuccess then onSuccess(data) end end
    q.onError = function(self, err)
        ErrorNoHaltWithStack("[Construction] SQL Error: " .. err .. "\n")
        if onError then onError(err) end
    end
    q:start()
end

--- Exécute une prepared query (anti-injection SQL)
local function PreparedQuery(sql, params, onSuccess, onError)
    if not ConstructionSystem.DB.IsConnected() then
        if onError then onError("Database not connected") end
        return
    end

    local q = db:prepare(sql)

    for i, param in ipairs(params) do
        local t = type(param)
        if t == "string" then
            q:setString(i, param)
        elseif t == "number" then
            if math.floor(param) == param then
                q:setNumber(i, param)
            else
                q:setNumber(i, param)
            end
        elseif t == "boolean" then
            q:setBoolean(i, param)
        elseif param == nil then
            q:setNull(i)
        end
    end

    q.onSuccess = function(self, data) if onSuccess then onSuccess(data) end end
    q.onError = function(self, err)
        ErrorNoHaltWithStack("[Construction] Prepared SQL Error: " .. err .. "\nQuery: " .. sql .. "\n")
        if onError then onError(err) end
    end
    q:start()
    return q
end

---------------------------------------------------------------------------
-- LOGGING
---------------------------------------------------------------------------

--- Enregistre une action dans les logs
function ConstructionSystem.DB.Log(ply, action, blueprintId, blueprintName, details)
    local steamid = IsValid(ply) and ply:SteamID() or "CONSOLE"
    local name = IsValid(ply) and ply:Nick() or "Console"

    PreparedQuery(
        "INSERT INTO blueprint_logs (steamid, player_name, action, blueprint_id, blueprint_name, details) VALUES (?, ?, ?, ?, ?, ?)",
        {steamid, name, action, blueprintId, blueprintName or "", details or ""}
    )
end

---------------------------------------------------------------------------
-- CRUD BLUEPRINTS
---------------------------------------------------------------------------

--- Sauvegarder un nouveau blueprint
-- @param ply Player - Le joueur qui sauvegarde
-- @param name string - Nom du blueprint
-- @param description string - Description
-- @param data string - Données sérialisées (JSON compressé en base64)
-- @param propCount number - Nombre de props
-- @param constraintCount number - Nombre de constraints
-- @param callback function(success, blueprintId, error)
function ConstructionSystem.DB.SaveBlueprint(ply, name, description, data, propCount, constraintCount, callback)
    if not IsValid(ply) then
        if callback then callback(false, nil, "Invalid player") end
        return
    end

    PreparedQuery(
        "INSERT INTO blueprints (owner_steamid, owner_name, name, description, data, prop_count, constraint_count) VALUES (?, ?, ?, ?, ?, ?, ?)",
        {ply:SteamID(), ply:Nick(), name, description or "", data, propCount or 0, constraintCount or 0},
        function(resultData)
            local insertId = db:lastInsert()
            ConstructionSystem.DB.Log(ply, "save", insertId, name, "Props: " .. (propCount or 0))
            if callback then callback(true, insertId, nil) end
            print("[Construction] Blueprint '" .. name .. "' sauvegardé par " .. ply:Nick() .. " (ID: " .. insertId .. ")")
        end,
        function(err)
            if callback then callback(false, nil, err) end
        end
    )
end

--- Récupérer tous les blueprints d'un joueur
-- @param ply Player
-- @param callback function(blueprints) - Liste des blueprints
function ConstructionSystem.DB.GetPlayerBlueprints(ply, callback)
    if not IsValid(ply) then return end

    PreparedQuery(
        "SELECT id, name, description, prop_count, constraint_count, is_public, created_at, updated_at FROM blueprints WHERE owner_steamid = ? ORDER BY updated_at DESC",
        {ply:SteamID()},
        function(data)
            if callback then callback(data or {}) end
        end,
        function(err)
            if callback then callback({}) end
        end
    )
end

--- Récupérer les données complètes d'un blueprint (pour le charger)
-- @param blueprintId number
-- @param ply Player - Le joueur qui charge (pour vérif permissions)
-- @param callback function(blueprint, error)
function ConstructionSystem.DB.LoadBlueprint(blueprintId, ply, callback)
    if not IsValid(ply) then return end

    -- Récupérer le blueprint si le joueur en est propriétaire OU s'il a une permission OU s'il est public
    PreparedQuery(
        [[SELECT b.* FROM blueprints b
          WHERE b.id = ? AND (
              b.owner_steamid = ?
              OR b.is_public = 1
              OR EXISTS (SELECT 1 FROM blueprint_permissions bp WHERE bp.blueprint_id = b.id AND bp.target_steamid = ?)
          )]],
        {blueprintId, ply:SteamID(), ply:SteamID()},
        function(data)
            if data and #data > 0 then
                ConstructionSystem.DB.Log(ply, "load", blueprintId, data[1].name)
                if callback then callback(data[1], nil) end
            else
                if callback then callback(nil, "Blueprint introuvable ou accès refusé") end
            end
        end,
        function(err)
            if callback then callback(nil, err) end
        end
    )
end

--- Supprimer un blueprint (propriétaire uniquement)
-- @param blueprintId number
-- @param ply Player
-- @param callback function(success, error)
function ConstructionSystem.DB.DeleteBlueprint(blueprintId, ply, callback)
    if not IsValid(ply) then return end

    PreparedQuery(
        "DELETE FROM blueprints WHERE id = ? AND owner_steamid = ?",
        {blueprintId, ply:SteamID()},
        function(data)
            local affected = db:affectedRows()
            if affected > 0 then
                ConstructionSystem.DB.Log(ply, "delete", blueprintId, "")
                if callback then callback(true, nil) end
                print("[Construction] Blueprint #" .. blueprintId .. " supprimé par " .. ply:Nick())
            else
                if callback then callback(false, "Blueprint introuvable ou non propriétaire") end
            end
        end,
        function(err)
            if callback then callback(false, err) end
        end
    )
end

--- Mettre à jour un blueprint existant
-- @param blueprintId number
-- @param ply Player
-- @param data string - Nouvelles données sérialisées
-- @param propCount number
-- @param constraintCount number
-- @param callback function(success, error)
function ConstructionSystem.DB.UpdateBlueprint(blueprintId, ply, data, propCount, constraintCount, callback)
    if not IsValid(ply) then return end

    PreparedQuery(
        "UPDATE blueprints SET data = ?, prop_count = ?, constraint_count = ? WHERE id = ? AND owner_steamid = ?",
        {data, propCount or 0, constraintCount or 0, blueprintId, ply:SteamID()},
        function()
            local affected = db:affectedRows()
            if affected > 0 then
                ConstructionSystem.DB.Log(ply, "update", blueprintId, "")
                if callback then callback(true, nil) end
            else
                if callback then callback(false, "Blueprint introuvable ou non propriétaire") end
            end
        end,
        function(err)
            if callback then callback(false, err) end
        end
    )
end

---------------------------------------------------------------------------
-- PERMISSIONS / PARTAGE
---------------------------------------------------------------------------

--- Partager un blueprint avec un autre joueur
-- @param blueprintId number
-- @param ownerPly Player - Le propriétaire
-- @param targetSteamId string - SteamID de la cible
-- @param permLevel string - "view", "use", ou "edit"
-- @param callback function(success, error)
function ConstructionSystem.DB.ShareBlueprint(blueprintId, ownerPly, targetSteamId, permLevel, callback)
    if not IsValid(ownerPly) then return end

    permLevel = permLevel or "use"
    if permLevel ~= "view" and permLevel ~= "use" and permLevel ~= "edit" then
        if callback then callback(false, "Niveau de permission invalide") end
        return
    end

    -- Vérifier que le joueur est bien propriétaire
    PreparedQuery(
        "SELECT id FROM blueprints WHERE id = ? AND owner_steamid = ?",
        {blueprintId, ownerPly:SteamID()},
        function(data)
            if not data or #data == 0 then
                if callback then callback(false, "Tu n'es pas propriétaire de ce blueprint") end
                return
            end

            -- Ajouter ou mettre à jour la permission
            PreparedQuery(
                "INSERT INTO blueprint_permissions (blueprint_id, target_steamid, permission_level, granted_by) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE permission_level = ?",
                {blueprintId, targetSteamId, permLevel, ownerPly:SteamID(), permLevel},
                function()
                    ConstructionSystem.DB.Log(ownerPly, "share", blueprintId, "", "Partagé avec " .. targetSteamId .. " (" .. permLevel .. ")")
                    if callback then callback(true, nil) end
                end,
                function(err)
                    if callback then callback(false, err) end
                end
            )
        end,
        function(err)
            if callback then callback(false, err) end
        end
    )
end

--- Retirer le partage d'un blueprint
function ConstructionSystem.DB.UnshareBlueprint(blueprintId, ownerPly, targetSteamId, callback)
    if not IsValid(ownerPly) then return end

    PreparedQuery(
        "DELETE FROM blueprint_permissions WHERE blueprint_id = ? AND target_steamid = ? AND granted_by = ?",
        {blueprintId, targetSteamId, ownerPly:SteamID()},
        function()
            ConstructionSystem.DB.Log(ownerPly, "unshare", blueprintId, "", "Retiré pour " .. targetSteamId)
            if callback then callback(true, nil) end
        end,
        function(err)
            if callback then callback(false, err) end
        end
    )
end

--- Récupérer les blueprints partagés avec un joueur
function ConstructionSystem.DB.GetSharedBlueprints(ply, callback)
    if not IsValid(ply) then return end

    PreparedQuery(
        [[SELECT b.id, b.name, b.description, b.owner_name, b.prop_count, b.constraint_count, b.created_at, bp.permission_level
          FROM blueprints b
          INNER JOIN blueprint_permissions bp ON b.id = bp.blueprint_id
          WHERE bp.target_steamid = ?
          ORDER BY b.updated_at DESC]],
        {ply:SteamID()},
        function(data)
            if callback then callback(data or {}) end
        end,
        function(err)
            if callback then callback({}) end
        end
    )
end

--- Récupérer les blueprints publics
function ConstructionSystem.DB.GetPublicBlueprints(callback)
    RunQuery(
        "SELECT id, name, description, owner_name, prop_count, constraint_count, created_at FROM blueprints WHERE is_public = 1 ORDER BY created_at DESC LIMIT 50",
        function(data)
            if callback then callback(data or {}) end
        end,
        function(err)
            if callback then callback({}) end
        end
    )
end

--- Rendre un blueprint public/privé
function ConstructionSystem.DB.SetPublic(blueprintId, ply, isPublic, callback)
    if not IsValid(ply) then return end

    PreparedQuery(
        "UPDATE blueprints SET is_public = ? WHERE id = ? AND owner_steamid = ?",
        {isPublic and 1 or 0, blueprintId, ply:SteamID()},
        function()
            if callback then callback(true) end
        end,
        function(err)
            if callback then callback(false) end
        end
    )
end

---------------------------------------------------------------------------
-- STATISTIQUES
---------------------------------------------------------------------------

--- Compter les blueprints d'un joueur
function ConstructionSystem.DB.CountPlayerBlueprints(ply, callback)
    if not IsValid(ply) then return end

    PreparedQuery(
        "SELECT COUNT(*) as count FROM blueprints WHERE owner_steamid = ?",
        {ply:SteamID()},
        function(data)
            if callback then callback(data and data[1] and tonumber(data[1].count) or 0) end
        end,
        function()
            if callback then callback(0) end
        end
    )
end

print("[Construction] Module sv_database chargé")
