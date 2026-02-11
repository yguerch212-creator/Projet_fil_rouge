--[[-----------------------------------------------------------------------
    RP Construction System - Logging persistant
    Écrit les logs dans un fichier pour debug à distance
---------------------------------------------------------------------------]]

ConstructionSystem.Log = ConstructionSystem.Log or {}

local LOG_DIR = "construction_logs"
local LOG_FILE = LOG_DIR .. "/server.log"

-- Créer le dossier
if not file.IsDir(LOG_DIR, "DATA") then
    file.CreateDir(LOG_DIR)
end

--- Écrire une ligne de log
function ConstructionSystem.Log.Write(level, msg)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local line = string.format("[%s] [%s] %s\n", timestamp, level, msg)

    -- Console
    print("[Construction][" .. level .. "] " .. msg)

    -- Fichier persistant (garrysmod/data/construction_logs/server.log)
    file.Append(LOG_FILE, line)
end

function ConstructionSystem.Log.Info(msg)
    ConstructionSystem.Log.Write("INFO", msg)
end

function ConstructionSystem.Log.Error(msg)
    ConstructionSystem.Log.Write("ERROR", msg)
end

function ConstructionSystem.Log.Debug(msg)
    ConstructionSystem.Log.Write("DEBUG", msg)
end

--- Commande RCON pour lire les logs
concommand.Add("construction_readlog", function(ply, cmd, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local lines = tonumber(args[1]) or 50
    local content = file.Read(LOG_FILE, "DATA")

    if not content or content == "" then
        print("[Construction] Aucun log")
        return
    end

    -- Dernières N lignes
    local allLines = string.Explode("\n", content)
    local startIdx = math.max(1, #allLines - lines)

    print("\n=== CONSTRUCTION LOGS (last " .. lines .. ") ===")
    for i = startIdx, #allLines do
        if allLines[i] and allLines[i] ~= "" then
            print(allLines[i])
        end
    end
    print("=== END ===\n")
end)

--- Commande pour vider les logs
concommand.Add("construction_clearlog", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    file.Write(LOG_FILE, "")
    print("[Construction] Logs vidés")
end)

print("[Construction] Module sv_logging charge")
ConstructionSystem.Log.Info("Logging initialise - fichier: data/" .. LOG_FILE)
