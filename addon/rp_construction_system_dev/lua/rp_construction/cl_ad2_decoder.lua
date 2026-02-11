--[[-----------------------------------------------------------------------
    RP Construction System - Décodeur AdvDupe2 embarqué
    Décode les fichiers .txt AdvDupe2 sans dépendre de l'addon AD2
    Basé sur le codec AdvDupe2 (Apache 2.0 - wiremod/advdupe2)
---------------------------------------------------------------------------]]

ConstructionSystem.AD2Decoder = {}

local decompress = util.Decompress

---------------------------------------------------------------------------
-- BINARY DESERIALIZER (Version 4 & 5)
---------------------------------------------------------------------------

local buff      -- file handle
local tables    -- table references
local reference -- reference counter

-- Version 5 decoder (current AD2 format)
local dec5 = {}
for i = 1, 255 do dec5[i] = function() error("Unknown type " .. i) end end

local function read5()
    local tt = buff:ReadByte()
    if not tt then error("Expected value, got EOF!") end
    return dec5[tt]()
end

dec5[255] = function() -- table (dict)
    local t = {}
    reference = reference + 1
    tables[reference] = t
    for k in read5 do
        t[k] = read5()
    end
    return t
end

dec5[254] = function() -- array
    local t = {}
    reference = reference + 1
    tables[reference] = t
    local k = 1
    for v in read5 do
        t[k] = v
        k = k + 1
    end
    return t
end

dec5[253] = function() return true end
dec5[252] = function() return false end
dec5[251] = function() return buff:ReadDouble() end
dec5[250] = function() return Vector(buff:ReadDouble(), buff:ReadDouble(), buff:ReadDouble()) end
dec5[249] = function() return Angle(buff:ReadDouble(), buff:ReadDouble(), buff:ReadDouble()) end
dec5[248] = function() -- long string
    local slen = buff:ReadULong()
    local retv = buff:Read(slen)
    if not retv then retv = "" end
    return retv
end
dec5[247] = function() return tables[buff:ReadShort()] end -- table reference
dec5[246] = function() return end -- nil (end marker)
dec5[0]   = function() return "" end

for i = 1, 245 do
    dec5[i] = function() return buff:Read(i) end
end

-- Version 4 decoder (older AD2 format)
local dec4 = {}
for i = 1, 255 do dec4[i] = function() error("Unknown type " .. i) end end

local function read4()
    local tt = buff:ReadByte()
    if not tt then error("Expected value, got EOF!") end
    if tt == 0 then return nil end
    return dec4[tt]()
end

dec4[255] = function() -- table
    local t = {}
    local k
    reference = reference + 1
    local ref = reference
    repeat
        k = read4()
        if k ~= nil then t[k] = read4() end
    until (k == nil)
    tables[ref] = t
    return t
end

dec4[254] = function() -- array
    local t = {}
    local k = 0
    local v
    reference = reference + 1
    local ref = reference
    repeat
        k = k + 1
        v = read4()
        if v ~= nil then t[k] = v end
    until (v == nil)
    tables[ref] = t
    return t
end

dec4[253] = function() return true end
dec4[252] = function() return false end
dec4[251] = function() return buff:ReadDouble() end
dec4[250] = function() return Vector(buff:ReadDouble(), buff:ReadDouble(), buff:ReadDouble()) end
dec4[249] = function() return Angle(buff:ReadDouble(), buff:ReadDouble(), buff:ReadDouble()) end
dec4[248] = function() -- null-terminated string (v4)
    local start = buff:Tell()
    local slen = 0
    while buff:ReadByte() ~= 0 do slen = slen + 1 end
    buff:Seek(start)
    local retv = buff:Read(slen)
    if not retv then retv = "" end
    buff:ReadByte() -- skip null terminator
    return retv
end
dec4[247] = function()
    reference = reference + 1
    return tables[buff:ReadShort()]
end

for i = 1, 246 do
    dec4[i] = function() return buff:Read(i) end
end

---------------------------------------------------------------------------
-- DESERIALIZE
---------------------------------------------------------------------------

local function deserialize(str, readFunc)
    if not str then
        return nil, "Données décompressées vides"
    end

    tables = {}
    reference = 0

    -- Écrire dans un fichier temp puis relire (comme AD2 fait)
    buff = file.Open("construction_ad2_temp.txt", "wb", "DATA")
    if not buff then return nil, "Impossible de créer le fichier temporaire" end
    buff:Write(str)
    buff:Flush()
    buff:Close()

    buff = file.Open("construction_ad2_temp.txt", "rb", "DATA")
    if not buff then return nil, "Impossible de lire le fichier temporaire" end

    local success, tbl = pcall(readFunc)
    buff:Close()

    -- Nettoyer
    file.Delete("construction_ad2_temp.txt")

    if success then
        return tbl
    else
        return nil, tostring(tbl)
    end
end

---------------------------------------------------------------------------
-- PARSE INFO BLOCK
---------------------------------------------------------------------------

local function parseInfo(str)
    local last = str:find("\2")
    if not last then return nil, "Info block malformé" end

    local info = {}
    local ss = str:sub(1, last - 1)
    for k, v in ss:gmatch("(.-)\1(.-)\1") do
        info[k] = v
    end

    return info, str:sub(last + 2)
end

---------------------------------------------------------------------------
-- MAIN DECODE FUNCTION
---------------------------------------------------------------------------

--- Décode un fichier AdvDupe2 binaire
--- @param data string Les données brutes du fichier
--- @return table|nil dupeTable La table de données décodée
--- @return table|nil info Les métadonnées du dupe
--- @return string|nil error Message d'erreur si échec
function ConstructionSystem.AD2Decoder.Decode(data)
    if not data or #data < 6 then
        return nil, nil, "Fichier trop petit"
    end

    local sig = data:sub(1, 4)
    local rev = data:byte(5)

    if sig ~= "AD2F" then
        return nil, nil, "Pas un fichier AD2 (signature: " .. sig .. ")"
    end

    if rev < 1 or rev > 5 then
        return nil, nil, "Révision AD2 non supportée: " .. tostring(rev)
    end

    -- Parser le header (skip "AD2F" + rev + "\n" = 6 bytes)
    local afterHeader = data:sub(7)
    local info, bodyStr = parseInfo(afterHeader)
    if not info then
        return nil, nil, "Header AD2 malformé"
    end

    -- Décompresser le corps
    local decompressed = decompress(bodyStr)
    if not decompressed then
        return nil, nil, "Décompression échouée"
    end

    -- Désérialiser selon la version
    local readFunc = (rev >= 5) and read5 or read4
    local tbl, err = deserialize(decompressed, readFunc)
    if not tbl then
        return nil, nil, "Désérialisation échouée: " .. tostring(err)
    end

    return tbl, info, nil
end

---------------------------------------------------------------------------
-- CONVERT AD2 DUPE → CONSTRUCTION BLUEPRINT
---------------------------------------------------------------------------

--- Convertit un dupe AD2 décodé en format blueprint Construction System
--- Produit la MÊME structure que sv_blueprints.lua Serialize() :
--- blueprint.data.Entities[idx] = { Class, Model, Pos (relatif), Ang, Skin, Material, Frozen }
--- blueprint.data.OriginalCenter = Vector
function ConstructionSystem.AD2Decoder.ToBlueprint(dupeTable, info)
    if not dupeTable or not dupeTable.Entities then
        return nil, "Pas d'entités dans le dupe"
    end

    -- Récupérer HeadEnt.Pos = le point d'origine où le joueur visait lors du save
    -- C'est notre OriginalCenter (pour "Position originale")
    local originalCenter = Vector(0, 0, 0)
    if dupeTable.HeadEnt and dupeTable.HeadEnt.Pos then
        local hp = dupeTable.HeadEnt.Pos
        if type(hp) == "Vector" then
            originalCenter = Vector(hp)
        elseif type(hp) == "table" then
            originalCenter = Vector(tonumber(hp.x) or 0, tonumber(hp.y) or 0, tonumber(hp.z) or 0)
        end
    end

    local dataEntities = {}
    local propCount = 0

    -- Les positions dans AD2 sont DÉJÀ relatives à HeadEnt.Pos
    -- On les garde telles quelles (= offsets par rapport au centre)
    for idx, entData in pairs(dupeTable.Entities) do
        local converted = {}
        converted.Class = entData.Class or "prop_physics"
        converted.Model = entData.Model or ""

        -- Position depuis PhysicsObjects[0] — déjà relative dans AD2
        if entData.PhysicsObjects and entData.PhysicsObjects[0] then
            local phys = entData.PhysicsObjects[0]
            converted.Pos = phys.Pos or phys.LocalPos or Vector(0, 0, 0)
            converted.Ang = phys.Angle or phys.LocalAngle or Angle(0, 0, 0)
            if phys.Frozen ~= nil then converted.Frozen = phys.Frozen end
        else
            converted.Pos = entData.Pos or Vector(0, 0, 0)
            converted.Ang = entData.Angle or Angle(0, 0, 0)
        end

        -- Données visuelles
        if entData.Skin then converted.Skin = entData.Skin end
        if entData.Color then converted.Color = entData.Color end
        if entData.Material then converted.Material = entData.Material end

        propCount = propCount + 1
        dataEntities[propCount] = converted
    end

    if propCount == 0 then
        return nil, "Aucune entité trouvée"
    end

    print("[Construction] AD2 import: " .. propCount .. " props, OriginalCenter=" .. tostring(originalCenter))

    -- Structure identique à celle produite par sv_blueprints.Serialize()
    local blueprint = {
        name = (info and info.name) or "Import AD2",
        description = "Importé depuis AdvDupe2" .. ((info and info.date) and (" — " .. info.date) or ""),
        prop_count = propCount,
        created_at = os.date("%Y-%m-%d %H:%M"),
        imported_from = "advdupe2",
        version = ConstructionSystem.Config and ConstructionSystem.Config.Version or "2.0.0",
        data = {
            Entities = dataEntities,
            OriginalCenter = originalCenter,
        },
    }

    return blueprint
end

print("[Construction] Module cl_ad2_decoder chargé (décodeur AD2 embarqué)")
