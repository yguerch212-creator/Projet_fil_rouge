--[[-----------------------------------------------------------------------
    RP Construction System - Stockage Blueprints (Client)
    Sauvegarde/chargement local dans data/construction_blueprints/
    Supporte les sous-dossiers et l'import AdvDupe2 (.txt)
---------------------------------------------------------------------------]]

ConstructionSystem.LocalBlueprints = ConstructionSystem.LocalBlueprints or {}

local SAVE_DIR = "construction_blueprints"

---------------------------------------------------------------------------
-- FILESYSTEM
---------------------------------------------------------------------------

--- Crée le dossier (+ sous-dossier) si nécessaire
local function EnsureDir(subdir)
    local path = SAVE_DIR
    if subdir and subdir ~= "" then
        path = SAVE_DIR .. "/" .. subdir
    end
    if not file.IsDir(path, "DATA") then
        file.CreateDir(path)
    end
    return path
end

--- Nom de fichier/dossier sécurisé
local function SafeName(name)
    local safe = string.gsub(name, "[^%w%s_%-]", "")
    safe = string.Trim(safe)
    if safe == "" then safe = "blueprint" end
    return safe
end

--- Construit le chemin complet à partir d'un sous-dossier relatif
local function FullPath(subdir)
    if not subdir or subdir == "" then return SAVE_DIR end
    return SAVE_DIR .. "/" .. subdir
end

--- Génère un nom unique dans un dossier
local function UniqueFileName(name, subdir)
    local base = SafeName(name)
    local dir = FullPath(subdir)
    local path = dir .. "/" .. base .. ".dat"
    if not file.Exists(path, "DATA") then return base end

    local i = 1
    while file.Exists(dir .. "/" .. base .. "_" .. i .. ".dat", "DATA") do
        i = i + 1
    end
    return base .. "_" .. i
end

---------------------------------------------------------------------------
-- DIRECTORIES
---------------------------------------------------------------------------

--- Créer un sous-dossier
function ConstructionSystem.LocalBlueprints.CreateFolder(name, parentDir)
    local safeName = SafeName(name)
    local parent = FullPath(parentDir)
    local fullPath = parent .. "/" .. safeName

    if file.IsDir(fullPath, "DATA") then
        return false, "Le dossier existe déjà"
    end

    file.CreateDir(fullPath)
    return true, safeName
end

--- Supprimer un dossier (doit être vide)
function ConstructionSystem.LocalBlueprints.DeleteFolder(folderPath)
    local full = FullPath(folderPath)
    if not file.IsDir(full, "DATA") then return false, "Dossier introuvable" end

    local files, dirs = file.Find(full .. "/*", "DATA")
    if (#files > 0 or #dirs > 0) then
        return false, "Le dossier n'est pas vide"
    end

    -- GMod ne supporte pas file.DeleteDir, on ne peut pas supprimer les dossiers vides
    -- On laisse le dossier vide, l'utilisateur devra le supprimer manuellement
    return false, "Suppression de dossier non supportée par GMod (supprimez manuellement dans garrysmod/data/)"
end

--- Lister les dossiers dans un chemin
function ConstructionSystem.LocalBlueprints.GetFolders(subdir)
    EnsureDir(subdir)
    local dir = FullPath(subdir)
    local _, dirs = file.Find(dir .. "/*", "DATA")
    return dirs or {}
end

---------------------------------------------------------------------------
-- ADVDUPE2 IMPORT
---------------------------------------------------------------------------

--- Tente de lire un fichier AdvDupe2 (.txt) et le convertit en notre format
local function ReadAdvDupe2File(filepath)
    -- Vérifier que AdvDupe2 est chargé
    if not AdvDupe2 or not AdvDupe2.Decode then
        return nil, "AdvDupe2 non disponible"
    end

    -- Lire le fichier binaire
    local f = file.Open(filepath, "rb", "DATA")
    if not f then return nil, "Impossible d'ouvrir le fichier" end
    local data = f:Read(f:Size())
    f:Close()

    if not data or #data < 5 then return nil, "Fichier trop petit" end

    -- Vérifier la signature AD2F
    local sig = data:sub(1, 4)
    if sig ~= "AD2F" then
        -- Peut-être un fichier AD1 (legacy)
        if sig ~= "[Inf" then
            return nil, "Pas un fichier AdvDupe2 valide"
        end
    end

    -- Décoder
    local success, dupeTable, info = AdvDupe2.Decode(data)
    if not success then
        return nil, "Erreur décodage: " .. tostring(dupeTable)
    end

    -- Convertir le format AD2 vers notre format
    local entities = {}
    local propCount = 0

    if dupeTable.Entities then
        for idx, entData in pairs(dupeTable.Entities) do
            local converted = {}
            converted.Class = entData.Class or "prop_physics"
            converted.Model = entData.Model or ""

            -- Position depuis PhysicsObjects[0]
            if entData.PhysicsObjects and entData.PhysicsObjects[0] then
                local phys = entData.PhysicsObjects[0]
                converted.Pos = phys.Pos or phys.LocalPos or Vector(0, 0, 0)
                converted.Angles = phys.Angle or phys.LocalAngle or Angle(0, 0, 0)
                -- Données physiques optionnelles
                if phys.Frozen ~= nil then converted.Frozen = phys.Frozen end
            else
                converted.Pos = entData.Pos or Vector(0, 0, 0)
                converted.Angles = entData.Angle or Angle(0, 0, 0)
            end

            -- Copier les données supplémentaires utiles
            if entData.Skin then converted.Skin = entData.Skin end
            if entData.Color then converted.Color = entData.Color end
            if entData.Material then converted.Material = entData.Material end
            if entData.BodyG then converted.BodyG = entData.BodyG end

            propCount = propCount + 1
            table.insert(entities, converted)
        end
    end

    -- Construire le blueprint dans notre format
    local blueprint = {
        entities = entities,
        name = (info and info.name) or "Import AD2",
        description = "Importé depuis AdvDupe2",
        prop_count = propCount,
        created_at = os.date("%Y-%m-%d %H:%M"),
        imported_from = "advdupe2",
        version = ConstructionSystem.Config.Version or "2.0.0",
    }

    return blueprint
end

---------------------------------------------------------------------------
-- SAVE / LOAD / DELETE / LIST
---------------------------------------------------------------------------

--- Sauvegarder un blueprint reçu du serveur
function ConstructionSystem.LocalBlueprints.Save(name, compressedData, propCount, subdir)
    EnsureDir(subdir)

    local fname = UniqueFileName(name, subdir)
    local dir = FullPath(subdir)
    local path = dir .. "/" .. fname .. ".dat"

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
    if subdir and subdir ~= "" then
        blueprint.folder = subdir
    end

    -- Sauvegarder
    local saveJson = util.TableToJSON(blueprint, true)
    file.Write(path, saveJson)

    return true, fname
end

--- Charger un blueprint par chemin relatif (sans extension)
function ConstructionSystem.LocalBlueprints.Load(filename, subdir)
    local dir = FullPath(subdir)

    -- 1. Essayer .dat (notre format natif)
    local datPath = dir .. "/" .. filename .. ".dat"
    if file.Exists(datPath, "DATA") then
        local content = file.Read(datPath, "DATA")
        if not content then return nil, "Erreur lecture" end
        local blueprint = util.JSONToTable(content)
        if not blueprint then return nil, "Fichier corrompu" end
        return blueprint
    end

    -- 2. Essayer .txt (AdvDupe2)
    local txtPath = dir .. "/" .. filename .. ".txt"
    if file.Exists(txtPath, "DATA") then
        local blueprint, err = ReadAdvDupe2File(txtPath)
        if not blueprint then return nil, "Erreur import AD2: " .. tostring(err) end
        blueprint.filename = filename
        return blueprint
    end

    return nil, "Fichier introuvable"
end

--- Supprimer un blueprint
function ConstructionSystem.LocalBlueprints.Delete(filename, subdir)
    local dir = FullPath(subdir)

    -- Essayer .dat puis .txt
    local datPath = dir .. "/" .. filename .. ".dat"
    if file.Exists(datPath, "DATA") then
        file.Delete(datPath)
        return true
    end

    local txtPath = dir .. "/" .. filename .. ".txt"
    if file.Exists(txtPath, "DATA") then
        file.Delete(txtPath)
        return true
    end

    return false
end

--- Lister tous les blueprints dans un dossier (supporte .dat et .txt)
function ConstructionSystem.LocalBlueprints.GetList(subdir)
    EnsureDir(subdir)
    local dir = FullPath(subdir)

    local list = {}

    -- 1. Fichiers .dat (notre format)
    local datFiles = file.Find(dir .. "/*.dat", "DATA")
    for _, fname in ipairs(datFiles or {}) do
        local path = dir .. "/" .. fname
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
                    format = "dat",
                    folder = subdir or "",
                })
            end
        end
    end

    -- 2. Fichiers .txt (AdvDupe2) — on lit juste les métadonnées sans décoder tout
    local txtFiles = file.Find(dir .. "/*.txt", "DATA")
    for _, fname in ipairs(txtFiles or {}) do
        local path = dir .. "/" .. fname
        local f = file.Open(path, "rb", "DATA")
        if f then
            local header = f:Read(math.min(f:Size(), 2048))
            f:Close()

            -- Vérifier que c'est bien un fichier AD2
            if header and (#header >= 5) and (header:sub(1, 4) == "AD2F" or header:sub(1, 4) == "[Inf") then
                -- Extraire les infos du header AD2
                local info = {}
                local infoBlock = header:match("^......\n(.-)\2")
                if infoBlock then
                    for k, v in infoBlock:gmatch("(.-)%z(.-)%z") do
                        -- Le séparateur dans AD2 est \1 pas \0
                    end
                    -- Extraire avec le bon séparateur (\1)
                    for k, v in infoBlock:gmatch("(.-)\1(.-)\1") do
                        info[k] = v
                    end
                end

                table.insert(list, {
                    filename = string.StripExtension(fname),
                    name = info.name or string.StripExtension(fname),
                    description = "AdvDupe2" .. (info.date and (" — " .. info.date) or ""),
                    prop_count = tonumber(info.size) and 0 or 0,  -- On ne peut pas connaître le nb de props sans décoder
                    created_at = info.date or "",
                    version = "AD2",
                    format = "txt",
                    folder = subdir or "",
                })
            end
        end
    end

    -- Trier par date (récent en premier), .dat avant .txt à date égale
    table.sort(list, function(a, b)
        if (a.created_at or "") == (b.created_at or "") then
            return a.format == "dat"
        end
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

    -- Sauvegarder dans le dossier courant du menu (si ouvert), sinon racine
    local currentDir = ConstructionSystem.Menu and ConstructionSystem.Menu.CurrentDir or ""

    local ok, fname = ConstructionSystem.LocalBlueprints.Save(name, compressed, propCount, currentDir)
    if ok then
        local folderInfo = (currentDir ~= "") and (" dans " .. currentDir) or ""
        chat.AddText(
            Color(100, 255, 100), "[Construction] ",
            Color(255, 255, 255), "Blueprint '",
            Color(100, 200, 255), name,
            Color(255, 255, 255), "' sauvegardé localement (",
            Color(100, 200, 255), tostring(propCount) .. " props",
            Color(255, 255, 255), ")" .. folderInfo
        )
        -- Rafraîchir le menu si ouvert
        if IsValid(ConstructionSystem.Menu.Frame) and ConstructionSystem.Menu.RefreshList then
            ConstructionSystem.Menu.RefreshList()
        end
    else
        chat.AddText(Color(255, 80, 80), "[Construction] Erreur sauvegarde: " .. tostring(fname))
    end
end)

print("[Construction] Module cl_blueprints chargé (dossiers + import AD2)")
