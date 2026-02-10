AddCSLuaFile()

SWEP.PrintName = "Outil de Construction"
SWEP.Author = "RP Construction System"
SWEP.Purpose = "Selectionner des props et gerer les blueprints"
SWEP.Instructions = "LMB: Select | RMB: Zone | Shift+RMB: Menu"
SWEP.Category = "Construction RP"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight = 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 1
SWEP.SlotPos = 5
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"
SWEP.UseHands = true
SWEP.HoldType = "slam"

-- Cacher le viewmodel de base (SLAM) et afficher le blueprint par-dessus
SWEP.ShowViewModel = false
SWEP.ShowWorldModel = false

-- Modèle custom à attacher sur le viewmodel (style SWEP Construction Kit)
SWEP.VElements = {
    ["blueprint"] = {
        type = "Model",
        model = "models/fortnitea31/weapons/misc/blueprint_pencil.mdl",
        bone = "ValveBiped.Anim_Attachment_RH",
        rel = "",
        pos = Vector(2, -1, -3),
        angle = Angle(0, 0, 0),
        size = Vector(1, 1, 1),
        color = Color(255, 255, 255, 255),
        surpresslightning = false,
        material = "",
        skin = 0,
        bodygroup = {}
    }
}

-- Modèle visible par les autres joueurs (worldmodel)
SWEP.WElements = {
    ["blueprint"] = {
        type = "Model",
        model = "models/fortnitea31/weapons/misc/blueprint_pencil.mdl",
        bone = "ValveBiped.Bip01_R_Hand",
        rel = "",
        pos = Vector(3, 2, -1),
        angle = Angle(-10, 0, 180),
        size = Vector(1, 1, 1),
        color = Color(255, 255, 255, 255),
        surpresslightning = false,
        material = "",
        skin = 0,
        bodygroup = {}
    }
}

---------------------------------------------------------------------------
-- SWEP Construction Kit rendering (by Clavus, public domain)
-- Adapted for our construction SWEP
---------------------------------------------------------------------------

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)

    if CLIENT then
        self.VElements = table.FullCopy(self.VElements)
        self.WElements = table.FullCopy(self.WElements)
        self.ViewModelBoneMods = self.ViewModelBoneMods or {}

        self:CreateModels(self.VElements)
        self:CreateModels(self.WElements)

        if IsValid(self.Owner) then
            local vm = self.Owner:GetViewModel()
            if IsValid(vm) then
                self:ResetBonePositions(vm)
                if self.ShowViewModel == false then
                    vm:SetColor(Color(255, 255, 255, 1))
                    vm:SetMaterial("Debug/hsv")
                end
            end
        end
    end
end

function SWEP:Deploy()
    if CLIENT and IsValid(self.Owner) then
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            if self.ShowViewModel == false then
                vm:SetColor(Color(255, 255, 255, 1))
                vm:SetMaterial("Debug/hsv")
            else
                vm:SetColor(Color(255, 255, 255, 255))
                vm:SetMaterial("")
            end
        end
    end
    return true
end

function SWEP:Holster()
    if CLIENT and IsValid(self.Owner) then
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            self:ResetBonePositions(vm)
            vm:SetColor(Color(255, 255, 255, 255))
            vm:SetMaterial("")
        end
    end
    return true
end

function SWEP:OnRemove()
    self:Holster()
end

-- LMB: Toggle sélection
function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.2)
    if CLIENT then return end

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    local tr = ply:GetEyeTrace()
    if not tr.Hit or not IsValid(tr.Entity) then return end
    if not ConstructionSystem.Config.AllowedClasses[tr.Entity:GetClass()] then return end

    ConstructionSystem.Selection.Toggle(ply, tr.Entity)
end

-- RMB: Zone select / Shift+RMB: Menu
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.5)

    local ply = self:GetOwner()
    if not IsValid(ply) then return end

    if ply:KeyDown(IN_SPEED) then
        if CLIENT then ConstructionSystem.Menu.Open() end
        return
    end

    if SERVER then return end

    local tr = ply:GetEyeTrace()
    if not tr.Hit then return end

    local radius = ConstructionSystem.ClientRadius or ConstructionSystem.Config.SelectionRadiusDefault or 500

    net.Start("Construction_SelectRadius")
    net.WriteVector(tr.HitPos)
    net.WriteUInt(math.Round(radius), 10)
    net.SendToServer()
end

-- Reload: Clear sélection
function SWEP:Reload()
    if CLIENT then return end
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    ConstructionSystem.Selection.Clear(ply)
end

---------------------------------------------------------------------------
-- CLIENT: Rendering (SCK-based)
---------------------------------------------------------------------------

if CLIENT then

    -- ViewModelDrawn: draw VElements on top of hidden viewmodel
    SWEP.vRenderOrder = nil
    function SWEP:ViewModelDrawn()
        local vm = self.Owner:GetViewModel()
        if not IsValid(vm) then return end
        if not self.VElements then return end

        if not self.vRenderOrder then
            self.vRenderOrder = {}
            for k, v in pairs(self.VElements) do
                if v.type == "Model" then
                    table.insert(self.vRenderOrder, 1, k)
                elseif v.type == "Sprite" or v.type == "Quad" then
                    table.insert(self.vRenderOrder, k)
                end
            end
        end

        for _, name in ipairs(self.vRenderOrder) do
            local v = self.VElements[name]
            if not v then self.vRenderOrder = nil break end
            if v.hide then continue end

            local model = v.modelEnt
            if not v.bone then continue end

            local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)
            if not pos then continue end

            if v.type == "Model" and IsValid(model) then
                model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)
                model:SetAngles(ang)

                local matrix = Matrix()
                matrix:Scale(v.size)
                model:EnableMatrix("RenderMultiply", matrix)

                if v.material == "" then
                    model:SetMaterial("")
                elseif model:GetMaterial() ~= v.material then
                    model:SetMaterial(v.material)
                end

                if v.skin and v.skin ~= model:GetSkin() then
                    model:SetSkin(v.skin)
                end

                if v.surpresslightning then
                    render.SuppressEngineLighting(true)
                end
                render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
                render.SetBlend(v.color.a / 255)
                model:DrawModel()
                render.SetBlend(1)
                render.SetColorModulation(1, 1, 1)
                if v.surpresslightning then
                    render.SuppressEngineLighting(false)
                end
            end
        end
    end

    -- DrawWorldModel: draw WElements for other players
    SWEP.wRenderOrder = nil
    function SWEP:DrawWorldModel()
        if self.ShowWorldModel ~= false then
            self:DrawModel()
        end

        if not self.WElements then return end

        if not self.wRenderOrder then
            self.wRenderOrder = {}
            for k, v in pairs(self.WElements) do
                if v.type == "Model" then
                    table.insert(self.wRenderOrder, 1, k)
                elseif v.type == "Sprite" or v.type == "Quad" then
                    table.insert(self.wRenderOrder, k)
                end
            end
        end

        local bone_ent = IsValid(self.Owner) and self.Owner or self

        for _, name in pairs(self.wRenderOrder) do
            local v = self.WElements[name]
            if not v then self.wRenderOrder = nil break end
            if v.hide then continue end

            local pos, ang
            if v.bone then
                pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent)
            else
                pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand")
            end
            if not pos then continue end

            local model = v.modelEnt
            if v.type == "Model" and IsValid(model) then
                model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)
                model:SetAngles(ang)

                local matrix = Matrix()
                matrix:Scale(v.size)
                model:EnableMatrix("RenderMultiply", matrix)

                if v.material == "" then
                    model:SetMaterial("")
                elseif model:GetMaterial() ~= v.material then
                    model:SetMaterial(v.material)
                end

                if v.skin and v.skin ~= model:GetSkin() then
                    model:SetSkin(v.skin)
                end

                render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
                render.SetBlend(v.color.a / 255)
                model:DrawModel()
                render.SetBlend(1)
                render.SetColorModulation(1, 1, 1)
            end
        end
    end

    ---------------------------------------------------------------------------
    -- SCK Helper functions (CreateModels, GetBoneOrientation, ResetBonePositions)
    ---------------------------------------------------------------------------

    function SWEP:CreateModels(tab)
        if not tab then return end
        for name, v in pairs(tab) do
            if v.type == "Model" and v.model and v.model ~= "" and not IsValid(v.modelEnt) then
                local ent = ClientsideModel(v.model, RENDERGROUP_VIEWMODEL)
                if IsValid(ent) then
                    ent:SetPos(vector_origin)
                    ent:SetAngles(angle_zero)
                    ent:SetNoDraw(true)
                    v.modelEnt = ent
                end
            elseif v.type == "Sprite" and v.sprite and v.sprite ~= "" then
                v.spriteMaterial = Material(v.sprite)
            end
        end
    end

    function SWEP:GetBoneOrientation(basetab, v, ent, bone_override)
        local bone, pos, ang

        if v.rel and v.rel ~= "" then
            local parent = basetab[v.rel]
            if not parent then return end
            pos, ang = self:GetBoneOrientation(basetab, parent, ent)
            if not pos then return end
            pos = pos + ang:Forward() * parent.pos.x + ang:Right() * parent.pos.y + ang:Up() * parent.pos.z
            ang:RotateAroundAxis(ang:Up(), parent.angle.y)
            ang:RotateAroundAxis(ang:Right(), parent.angle.p)
            ang:RotateAroundAxis(ang:Forward(), parent.angle.r)
        else
            bone = ent:LookupBone(bone_override or v.bone)
            if not bone then return end
            pos, ang = Vector(0, 0, 0), Angle(0, 0, 0)
            local m = ent:GetBoneMatrix(bone)
            if m then
                pos, ang = m:GetTranslation(), m:GetAngles()
            end
        end

        return pos, ang
    end

    function SWEP:ResetBonePositions(vm)
        if not IsValid(vm) then return end
        for i = 0, vm:GetBoneCount() - 1 do
            vm:ManipulateBoneScale(i, Vector(1, 1, 1))
            vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
            vm:ManipulateBonePosition(i, Vector(0, 0, 0))
        end
    end

    ---------------------------------------------------------------------------
    -- HUD
    ---------------------------------------------------------------------------

    function SWEP:DrawHUD()
        local count = ConstructionSystem.Selection.Count()
        local maxP = ConstructionSystem.Config.MaxPropsPerBlueprint

        local boxW, boxH = 240, 60
        local boxX = ScrW() - boxW - 20
        local boxY = ScrH() - boxH - 100

        draw.RoundedBox(6, boxX, boxY, boxW, boxH, Color(30, 30, 30, 180))
        draw.SimpleText("Construction", "DermaDefaultBold", boxX + boxW / 2, boxY + 8, Color(0, 150, 255), TEXT_ALIGN_CENTER)

        local col = count >= maxP and Color(255, 50, 50) or Color(200, 200, 200)
        draw.SimpleText("Props: " .. count .. "/" .. maxP, "DermaDefault", boxX + boxW / 2, boxY + 24, col, TEXT_ALIGN_CENTER)

        draw.SimpleText("LMB:Sel | RMB:Zone | Shift+RMB:Menu", "DermaDefault", boxX + boxW / 2, boxY + 40, Color(130, 130, 130), TEXT_ALIGN_CENTER)
    end

end
