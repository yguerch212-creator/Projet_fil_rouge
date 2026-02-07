-- Configuration RP Construction System
ConstructionSystem = ConstructionSystem or {}

ConstructionSystem.Config = {
    Version = "1.0.0",
    CommandName = "!construction",
    MaxBlueprints = 10,
    MaxPropsPerBlueprint = 50,
    MaxBlueprintNameLength = 64,
    AdminSteamIDs = { "STEAM_0:0:00000000" },
    Database = {
        Host = "mysql",
        Port = 3306,
        Database = "gmod_construction",
        Username = "gmod_user",
        Password = "GmodUserPass2025!"
    },
    MenuWidth = 800,
    MenuHeight = 600,
    PrimaryColor = Color(41, 128, 185),
    SecondaryColor = Color(52, 152, 219),
}

function ConstructionSystem:IsAdmin(ply)
    if not IsValid(ply) then return false end
    return table.HasValue(self.Config.AdminSteamIDs, ply:SteamID())
end

function ConstructionSystem:Log(msg)
    print("[Construction] " .. msg)
end
