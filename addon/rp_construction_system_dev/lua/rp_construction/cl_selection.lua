--[[-----------------------------------------------------------------------
    RP Construction System - Sélection Client (OPTIMISÉ)
    Rendu léger des props sélectionnés - pas de halo (trop lourd)
---------------------------------------------------------------------------]]

ConstructionSystem.Selection = ConstructionSystem.Selection or {}

local SelectedEntities = {}

net.Receive("Construction_SyncSelection", function()
    SelectedEntities = {}
    local count = net.ReadUInt(10)
    for i = 1, count do
        local id = net.ReadUInt(13)
        SelectedEntities[id] = true
    end
end)

function ConstructionSystem.Selection.IsSelected(ent)
    if not IsValid(ent) then return false end
    return SelectedEntities[ent:EntIndex()] == true
end

function ConstructionSystem.Selection.Count()
    local count = 0
    for id, _ in pairs(SelectedEntities) do
        if IsValid(Entity(id)) then
            count = count + 1
        end
    end
    return count
end

function ConstructionSystem.Selection.GetEntities()
    local list = {}
    for id, _ in pairs(SelectedEntities) do
        local ent = Entity(id)
        if IsValid(ent) then
            table.insert(list, ent)
        end
    end
    return list
end

-- Rendu : simple changement de couleur (PAS de halo, PAS de overlay)
-- Les props sélectionnés sont colorés en bleu clair
hook.Add("PreDrawOpaqueRenderables", "Construction_DrawSelection", function()
    for id, _ in pairs(SelectedEntities) do
        local ent = Entity(id)
        if IsValid(ent) then
            ent:SetColor(Color(100, 180, 255, 200))
        end
    end
end)

-- Restaurer la couleur quand désélectionné
hook.Add("Think", "Construction_RestoreColors", function()
    -- Exécuter rarement
    if not ConstructionSystem._nextColorCheck or ConstructionSystem._nextColorCheck < CurTime() then
        ConstructionSystem._nextColorCheck = CurTime() + 1

        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:GetClass() == "prop_physics" and not SelectedEntities[ent:EntIndex()] then
                local col = ent:GetColor()
                if col.r == 100 and col.g == 180 and col.b == 255 then
                    ent:SetColor(Color(255, 255, 255, 255))
                end
            end
        end
    end
end)

print("[Construction] Module cl_selection charge (optimise)")
