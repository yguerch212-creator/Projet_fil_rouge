--[[-----------------------------------------------------------------------
    Catégories DarkRP - Projet Fil Rouge
    Chaque job/entité/véhicule doit appartenir à une catégorie existante.
---------------------------------------------------------------------------]]

-- Catégorie pour les jobs civils
DarkRP.createCategory{
    name = "Civil",
    categorises = "jobs",
    startExpanded = true,
    color = Color(0, 107, 0, 255),
    canSee = function(ply) return true end,
    sortOrder = 100,
}

-- Catégorie pour les entités de construction
DarkRP.createCategory{
    name = "Construction",
    categorises = "entities",
    startExpanded = true,
    color = Color(0, 100, 200, 255),
    canSee = function(ply) return true end,
    sortOrder = 50,
}

-- Catégorie pour les véhicules
DarkRP.createCategory{
    name = "Transport",
    categorises = "vehicles",
    startExpanded = true,
    color = Color(200, 100, 0, 255),
    canSee = function(ply) return true end,
    sortOrder = 100,
}
