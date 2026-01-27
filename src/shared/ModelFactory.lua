--[[
    ModelFactory - 鬼と豆のモデルを生成するファクトリー
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ModelFactory = {}

-- 豆モデルの作成
function ModelFactory.CreateBean()
    local bean = Instance.new("Part")
    bean.Name = "Bean"
    bean.Size = GameConfig.BEAN.SIZE
    bean.Color = GameConfig.BEAN.COLOR
    bean.Material = Enum.Material.SmoothPlastic
    bean.Shape = Enum.PartType.Ball
    bean.CanCollide = true
    bean.Anchored = false

    -- 物理設定
    bean.CustomPhysicalProperties = PhysicalProperties.new(
        0.5,  -- Density
        0.3,  -- Friction
        0.5,  -- Elasticity
        1,    -- FrictionWeight
        1     -- ElasticityWeight
    )

    -- 当たり判定用タグ
    bean:SetAttribute("IsBean", true)

    return bean
end

-- 鬼モデルの作成
function ModelFactory.CreateOni(oniType)
    oniType = oniType or "NORMAL"
    local config = GameConfig.ONI_TYPES[oniType]
    if not config then
        config = GameConfig.ONI_TYPES.NORMAL
    end

    local oniModel = Instance.new("Model")
    oniModel.Name = "Oni"

    -- 胴体
    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(GameConfig.ONI.SIZE.X, GameConfig.ONI.SIZE.Y * 0.5, GameConfig.ONI.SIZE.Z)
    torso.Color = config.color
    torso.Material = Enum.Material.SmoothPlastic
    torso.CanCollide = false
    torso.Anchored = true
    torso.Parent = oniModel

    -- 頭
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(GameConfig.ONI.SIZE.X * 0.8, GameConfig.ONI.SIZE.Y * 0.35, GameConfig.ONI.SIZE.Z * 0.9)
    head.Color = config.color
    head.Material = Enum.Material.SmoothPlastic
    head.Shape = Enum.PartType.Ball
    head.CanCollide = false
    head.Anchored = true
    head.Parent = oniModel

    -- 角（左）
    local hornLeft = Instance.new("Part")
    hornLeft.Name = "HornLeft"
    hornLeft.Size = Vector3.new(0.3, 1.5, 0.3)
    hornLeft.Color = Color3.fromRGB(245, 245, 220)
    hornLeft.Material = Enum.Material.SmoothPlastic
    hornLeft.CanCollide = false
    hornLeft.Anchored = true
    hornLeft.Parent = oniModel

    -- 角（右）
    local hornRight = Instance.new("Part")
    hornRight.Name = "HornRight"
    hornRight.Size = Vector3.new(0.3, 1.5, 0.3)
    hornRight.Color = Color3.fromRGB(245, 245, 220)
    hornRight.Material = Enum.Material.SmoothPlastic
    hornRight.CanCollide = false
    hornRight.Anchored = true
    hornRight.Parent = oniModel

    -- 目（左）
    local eyeLeft = Instance.new("Part")
    eyeLeft.Name = "EyeLeft"
    eyeLeft.Size = Vector3.new(0.5, 0.5, 0.2)
    eyeLeft.Color = Color3.fromRGB(255, 255, 255)
    eyeLeft.Material = Enum.Material.SmoothPlastic
    eyeLeft.Shape = Enum.PartType.Ball
    eyeLeft.CanCollide = false
    eyeLeft.Anchored = true
    eyeLeft.Parent = oniModel

    -- 目（右）
    local eyeRight = Instance.new("Part")
    eyeRight.Name = "EyeRight"
    eyeRight.Size = Vector3.new(0.5, 0.5, 0.2)
    eyeRight.Color = Color3.fromRGB(255, 255, 255)
    eyeRight.Material = Enum.Material.SmoothPlastic
    eyeRight.Shape = Enum.PartType.Ball
    eyeRight.CanCollide = false
    eyeRight.Anchored = true
    eyeRight.Parent = oniModel

    -- 瞳（左）
    local pupilLeft = Instance.new("Part")
    pupilLeft.Name = "PupilLeft"
    pupilLeft.Size = Vector3.new(0.25, 0.25, 0.15)
    pupilLeft.Color = Color3.fromRGB(20, 20, 20)
    pupilLeft.Material = Enum.Material.SmoothPlastic
    pupilLeft.Shape = Enum.PartType.Ball
    pupilLeft.CanCollide = false
    pupilLeft.Anchored = true
    pupilLeft.Parent = oniModel

    -- 瞳（右）
    local pupilRight = Instance.new("Part")
    pupilRight.Name = "PupilRight"
    pupilRight.Size = Vector3.new(0.25, 0.25, 0.15)
    pupilRight.Color = Color3.fromRGB(20, 20, 20)
    pupilRight.Material = Enum.Material.SmoothPlastic
    pupilRight.Shape = Enum.PartType.Ball
    pupilRight.CanCollide = false
    pupilRight.Anchored = true
    pupilRight.Parent = oniModel

    -- 口
    local mouth = Instance.new("Part")
    mouth.Name = "Mouth"
    mouth.Size = Vector3.new(1, 0.3, 0.2)
    mouth.Color = Color3.fromRGB(100, 20, 20)
    mouth.Material = Enum.Material.SmoothPlastic
    mouth.CanCollide = false
    mouth.Anchored = true
    mouth.Parent = oniModel

    -- 牙（左）
    local fangLeft = Instance.new("Part")
    fangLeft.Name = "FangLeft"
    fangLeft.Size = Vector3.new(0.2, 0.4, 0.15)
    fangLeft.Color = Color3.fromRGB(255, 255, 255)
    fangLeft.Material = Enum.Material.SmoothPlastic
    fangLeft.CanCollide = false
    fangLeft.Anchored = true
    fangLeft.Parent = oniModel

    -- 牙（右）
    local fangRight = Instance.new("Part")
    fangRight.Name = "FangRight"
    fangRight.Size = Vector3.new(0.2, 0.4, 0.15)
    fangRight.Color = Color3.fromRGB(255, 255, 255)
    fangRight.Material = Enum.Material.SmoothPlastic
    fangRight.CanCollide = false
    fangRight.Anchored = true
    fangRight.Parent = oniModel

    -- パーツの位置設定用関数
    oniModel.PrimaryPart = torso

    -- 属性設定
    oniModel:SetAttribute("OniType", oniType)
    oniModel:SetAttribute("Score", config.score)
    oniModel:SetAttribute("SpeedMultiplier", config.speed)

    return oniModel
end

-- 鬼の位置を更新（相対配置）
function ModelFactory.PositionOniParts(oniModel, basePosition)
    local torso = oniModel:FindFirstChild("Torso")
    local head = oniModel:FindFirstChild("Head")
    local hornLeft = oniModel:FindFirstChild("HornLeft")
    local hornRight = oniModel:FindFirstChild("HornRight")
    local eyeLeft = oniModel:FindFirstChild("EyeLeft")
    local eyeRight = oniModel:FindFirstChild("EyeRight")
    local pupilLeft = oniModel:FindFirstChild("PupilLeft")
    local pupilRight = oniModel:FindFirstChild("PupilRight")
    local mouth = oniModel:FindFirstChild("Mouth")
    local fangLeft = oniModel:FindFirstChild("FangLeft")
    local fangRight = oniModel:FindFirstChild("FangRight")

    if torso then
        torso.CFrame = CFrame.new(basePosition)
    end

    if head then
        head.CFrame = CFrame.new(basePosition + Vector3.new(0, 3.5, 0))
    end

    if hornLeft then
        hornLeft.CFrame = CFrame.new(basePosition + Vector3.new(-0.8, 5, 0)) * CFrame.Angles(0, 0, math.rad(-15))
    end

    if hornRight then
        hornRight.CFrame = CFrame.new(basePosition + Vector3.new(0.8, 5, 0)) * CFrame.Angles(0, 0, math.rad(15))
    end

    if eyeLeft then
        eyeLeft.CFrame = CFrame.new(basePosition + Vector3.new(-0.6, 3.8, -0.8))
    end

    if eyeRight then
        eyeRight.CFrame = CFrame.new(basePosition + Vector3.new(0.6, 3.8, -0.8))
    end

    if pupilLeft then
        pupilLeft.CFrame = CFrame.new(basePosition + Vector3.new(-0.6, 3.8, -0.95))
    end

    if pupilRight then
        pupilRight.CFrame = CFrame.new(basePosition + Vector3.new(0.6, 3.8, -0.95))
    end

    if mouth then
        mouth.CFrame = CFrame.new(basePosition + Vector3.new(0, 3, -0.85))
    end

    if fangLeft then
        fangLeft.CFrame = CFrame.new(basePosition + Vector3.new(-0.35, 2.7, -0.85))
    end

    if fangRight then
        fangRight.CFrame = CFrame.new(basePosition + Vector3.new(0.35, 2.7, -0.85))
    end
end

-- ヒットエフェクトの作成
function ModelFactory.CreateHitEffect(position, color)
    local effectPart = Instance.new("Part")
    effectPart.Name = "HitEffect"
    effectPart.Size = Vector3.new(0.5, 0.5, 0.5)
    effectPart.Position = position
    effectPart.Color = color or Color3.fromRGB(255, 255, 0)
    effectPart.Material = Enum.Material.Neon
    effectPart.Shape = Enum.PartType.Ball
    effectPart.CanCollide = false
    effectPart.Anchored = true
    effectPart.Transparency = 0

    return effectPart
end

return ModelFactory
