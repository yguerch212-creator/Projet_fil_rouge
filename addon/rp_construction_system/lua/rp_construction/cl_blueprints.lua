--[[-----------------------------------------------------------------------
    RP Construction System - Stockage Blueprints (Client)
    Sauvegarde/chargement local dans data/construction_blueprints/
---------------------------------------------------------------------------]]

ConstructionSystem.LocalBlueprints = ConstructionSystem.LocalBlueprints or {}

local SAVE_DIR = "construction_blueprints"

---------------------------------------------------------------------------
-- FILESYSTEM
---------------------------------------------------------------------------

--- Crée le dossier si nécessaire
local function EnsureDir()
    if not file.IsDir(SAVE_DIR, "DATA") then
        file.CreateDir(SAVE_DIR)
    end
end

--- Nom de fichier sécurisé
local function SafeFileName(name)
    local safe = string.gsub(name, "[^%w%s_%-]", "")
    safe = string.Trim(safe)
    if safe == "" then safe = "blueprint" end
    return safe
end

--- Génère un nom unique
local function UniqueFileName(name)
    local base = SafeFileName(name)
    local path = SAVE_DIR .. "/" .. base .. ".dat"
    if not file.Exists(path, "DATA") then return base end

    local i = 1
    while file.Exists(SAVE_DIR .. "/" .. base .. "_" .. i .. ".dat", "DATA") do
        i = i + 1
    end
    return base .. "_" .. i
end

---------------------------------------------------------------------------
-- SAVE / LOAD / DELETE / LIST
---------------------------------------------------------------------------

--- Sauvegarder un blueprint reçu du serveur
function ConstructionSystem.LocalBlueprints.Save(name, compressedData, propCount)
    EnsureDir()

    local fname = UniqueFileName(name)
    local path = SAVE_DIR .. "/" .. fname .. ".dat"

    -- Décompresser pour ajouter les métadonnées
    local json = util.Decompress(compressedData)
    if not json then return false, "Erreur décompression" end

    local blueprint = util.JSONToTable(json)
    if not blueprint then return false, "Erreur parsing" end

    -- Ajouter métadonnées
    blueprint.name = name
    blueprint.prop_count = propCount
    blueprint.created_at = os.date("%Y-%m-%d %H:%M")
    blueprint.filename = fname

    -- Sauvegarder
    local saveJson = util.TableToJSON(blueprint, true)
    file.Write(path, saveJson)

    return true, fname
end

--- Charger un blueprint par nom de fichier
function ConstructionSystem.LocalBlueprints.Load(filename)
    local path = SAVE_DIR .. "/" .. filename .. ".dat"
    if not file.Exists(path, "DATA") then return nil, "Fichier introuvable" end

    local content = file.Read(path, "DATA")
    if not content then return nil, "Erreur lecture" end

    local blueprint = util.JSONToTable(content)
    if not blueprint then return nil, "Fichier corrompu" end

    return blueprint
end

--- Supprimer un blueprint
function ConstructionSystem.LocalBlueprints.Delete(filename)
    local path = SAVE_DIR .. "/" .. filename .. ".dat"
    if file.Exists(path, "DATA") then
        file.Delete(path)
        return true
    end
    return false
end

--- Lister tous les blueprints locaux
function ConstructionSystem.LocalBlueprints.GetList()
    EnsureDir()

    local files = file.Find(SAVE_DIR .. "/*.dat", "DATA")
    local list = {}

    for _, fname in ipairs(files or {}) do
        local path = SAVE_DIR .. "/" .. fname
        local content = file.Read(path, "DATA")
        if content then
            local bp = util.JSONToTable(content)
            if bp then
                table.insert(list, {
                    filename = string.StripExtension(fname),
                    name = bp.name or string.StripExtension(fname),
                    description = bp.description or "",
                    prop_count = bp.prop_count or 0,
                    created_at = bp.created_at or "",
                    version = bp.version or "?",
                })
            end
        end
    end

    -- Trier par date (récent en premier)
    table.sort(list, function(a, b)
        return (a.created_at or "") > (b.created_at or "")
    end)

    return list
end

---------------------------------------------------------------------------
-- NET: Réception des données sérialisées du serveur
---------------------------------------------------------------------------

net.Receive("Construction_SaveToClient", function()
    local name = net.ReadString()
    local propCount = net.ReadUInt(10)
    local dataLen = net.ReadUInt(32)
    local compressed = net.ReadData(dataLen)

    local ok, fname = ConstructionSystem.LocalBlueprints.Save(name, compressed, propCount)
    if ok then
        chat.AddText(
            Color(100, 255, 100), "[Construction] ",
            Color(255, 255, 255), "Blueprint '",
            Color(100, 200, 255), name,
            Color(255, 255, 255), "' sauvegardé localement (",
            Color(100, 200, 255), tostring(propCount) .. " props",
            Color(255, 255, 255), ")"
        )
        -- Rafraîchir le menu si ouvert
        if IsValid(ConstructionSystem.Menu.Frame) and ConstructionSystem.Menu.RefreshList then
            ConstructionSystem.Menu.RefreshList()
        end
    else
        chat.AddText(Color(255, 80, 80), "[Construction] Erreur sauvegarde: " .. tostring(fname))
    end
end)

print("[Construction] Module cl_blueprints chargé")
