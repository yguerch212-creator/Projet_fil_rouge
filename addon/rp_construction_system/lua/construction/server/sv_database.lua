-- Module base de données
require("mysqloo")

ConstructionDB = ConstructionDB or {}

function ConstructionDB:Initialize()
    local cfg = ConstructionSystem.Config.Database
    self.connection = mysqloo.connect(cfg.Host, cfg.Username, cfg.Password, cfg.Database, cfg.Port)
    
    self.connection.onConnected = function()
        ConstructionSystem:Log("Base de donnees connectee")
        self:CreateMissingTables()
    end
    
    self.connection.onConnectionFailed = function(db, err)
        ConstructionSystem:Log("Connexion BDD echouee: " .. err)
    end
    
    self.connection:connect()
end

function ConstructionDB:CreateMissingTables()
    local query = self.connection:query("SHOW TABLES")
    query.onSuccess = function(q, data)
        ConstructionSystem:Log("Tables trouvees: " .. #data)
    end
    query:start()
end

function ConstructionDB:Query(sql, callback)
    if not self.connection then
        ConstructionSystem:Log("Pas de connexion BDD")
        if callback then callback(false, "No connection") end
        return
    end
    
    local query = self.connection:query(sql)
    query.onSuccess = function(q, data)
        if callback then callback(true, data) end
    end
    query.onError = function(q, err)
        ConstructionSystem:Log("Query Error: " .. err)
        if callback then callback(false, err) end
    end
    query:start()
end

function ConstructionDB:Escape(str)
    if not self.connection then return str end
    return self.connection:escape(tostring(str))
end

hook.Add("Initialize", "ConstructionDB_Init", function()
    timer.Simple(2, function()
        ConstructionDB:Initialize()
    end)
end)
