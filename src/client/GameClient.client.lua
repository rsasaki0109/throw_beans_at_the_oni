--[[
    GameClient - クライアントサイドゲーム処理
    入力処理、カメラ制御、豆投擲を担当
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- 状態管理
local CurrentGameState = GameConfig.GAME_STATE.WAITING
local IsHolding = false
local LastThrowTime = 0

-- カメラ設定
local function SetupCamera()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    -- 一人称視点風のカメラ設定
    Camera.CameraType = Enum.CameraType.Scriptable

    local cameraPosition = humanoidRootPart.Position + Vector3.new(0, 2, -5)
    local lookAt = humanoidRootPart.Position + Vector3.new(0, 2, 30)

    Camera.CFrame = CFrame.lookAt(cameraPosition, lookAt)

    -- カメラを固定
    RunService.RenderStepped:Connect(function()
        if CurrentGameState == GameConfig.GAME_STATE.PLAYING or
           CurrentGameState == GameConfig.GAME_STATE.COUNTDOWN then
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local camPos = hrp.Position + Vector3.new(0, 3, -8)
                    local lookAtPos = hrp.Position + Vector3.new(0, 3, 30)
                    Camera.CFrame = CFrame.lookAt(camPos, lookAtPos)
                end
            end
        end
    end)
end

-- 照準位置の取得
local function GetAimPosition()
    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)

    -- 一定距離の平面と交差する点を計算
    local distance = GameConfig.ONI.SPAWN_DISTANCE
    local character = LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local targetZ = hrp.Position.Z + distance
            local t = (targetZ - ray.Origin.Z) / ray.Direction.Z
            if t > 0 then
                return ray.Origin + ray.Direction * t
            end
        end
    end

    return ray.Origin + ray.Direction * 50
end

-- 豆を投げる
local function ThrowBean()
    if CurrentGameState ~= GameConfig.GAME_STATE.PLAYING then
        return
    end

    -- 発射レート制限（クライアント側）
    local currentTime = tick()
    if currentTime - LastThrowTime < GameConfig.BEAN.FIRE_RATE then
        return
    end
    LastThrowTime = currentTime

    local character = LocalPlayer.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    -- 発射位置（プレイヤーの前方やや上）
    local origin = humanoidRootPart.Position + Vector3.new(0, 1.5, 2)

    -- 照準位置への方向
    local aimPosition = GetAimPosition()
    local direction = (aimPosition - origin).Unit

    -- サーバーに送信
    local throwEvent = RemoteEvents:GetEvent(RemoteEvents.Names.THROW_BEAN)
    throwEvent:FireServer(origin, direction)

    -- 投擲エフェクト（クライアント側の即時フィードバック）
    PlayThrowEffect(origin)
end

-- 投擲エフェクト
function PlayThrowEffect(position)
    -- 軽い画面シェイク
    local originalCFrame = Camera.CFrame
    task.spawn(function()
        for i = 1, 3 do
            local offset = Vector3.new(
                (math.random() - 0.5) * 0.05,
                (math.random() - 0.5) * 0.05,
                0
            )
            Camera.CFrame = originalCFrame * CFrame.new(offset)
            task.wait(0.02)
        end
        Camera.CFrame = originalCFrame
    end)
end

-- 入力処理（PC）
local function OnInputBegan(input, gameProcessed)
    if gameProcessed then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.KeyCode == Enum.KeyCode.Space then
        IsHolding = true
        ThrowBean()
    end
end

local function OnInputEnded(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.KeyCode == Enum.KeyCode.Space then
        IsHolding = false
    end
end

-- 入力処理（モバイル）
local function OnTouchBegan(touch, gameProcessed)
    if gameProcessed then return end
    IsHolding = true
    ThrowBean()
end

local function OnTouchEnded(touch, gameProcessed)
    IsHolding = false
end

-- 連射処理
local function UpdateContinuousFire()
    while true do
        if IsHolding and CurrentGameState == GameConfig.GAME_STATE.PLAYING then
            ThrowBean()
        end
        task.wait(GameConfig.BEAN.FIRE_RATE)
    end
end

-- ゲーム状態変更ハンドラ
local function OnGameStateChanged(state)
    CurrentGameState = state

    if state == GameConfig.GAME_STATE.PLAYING then
        -- マウスカーソルを中央にロック（PC）
        if not UserInputService.TouchEnabled then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    end
end

-- ヒットエフェクト
local function OnOniHit(score, position)
    -- サウンドエフェクト（実際の実装ではSoundを使用）
    -- 今回はビジュアルエフェクトのみ

    -- 星エフェクト
    for i = 1, GameConfig.EFFECTS.HIT_PARTICLE_COUNT do
        task.spawn(function()
            local star = Instance.new("Part")
            star.Name = "StarEffect"
            star.Size = Vector3.new(0.3, 0.3, 0.3)
            star.Position = position
            star.Color = Color3.fromRGB(255, 255, 0)
            star.Material = Enum.Material.Neon
            star.Shape = Enum.PartType.Ball
            star.CanCollide = false
            star.Anchored = false
            star.Parent = workspace

            -- ランダムな方向に飛ばす
            local randomVelocity = Vector3.new(
                (math.random() - 0.5) * 30,
                math.random() * 20 + 10,
                (math.random() - 0.5) * 30
            )
            star.AssemblyLinearVelocity = randomVelocity

            -- フェードアウト
            task.delay(0.3, function()
                local tween = TweenService:Create(
                    star,
                    TweenInfo.new(0.2),
                    {Transparency = 1}
                )
                tween:Play()
                tween.Completed:Connect(function()
                    star:Destroy()
                end)
            end)
        end)
    end

    -- 画面フラッシュ
    local flash = Instance.new("Frame")
    flash.Name = "HitFlash"
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
    flash.BackgroundTransparency = 0.7
    flash.BorderSizePixel = 0
    flash.ZIndex = 100
    flash.Parent = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("GameGui")

    local tween = TweenService:Create(
        flash,
        TweenInfo.new(0.1),
        {BackgroundTransparency = 1}
    )
    tween:Play()
    tween.Completed:Connect(function()
        flash:Destroy()
    end)

    -- モバイルバイブレーション
    if UserInputService.TouchEnabled then
        pcall(function()
            game:GetService("HapticService"):SetMotor(
                Enum.UserInputType.Gamepad1,
                Enum.VibrationMotor.Small,
                0.5
            )
            task.delay(0.1, function()
                game:GetService("HapticService"):SetMotor(
                    Enum.UserInputType.Gamepad1,
                    Enum.VibrationMotor.Small,
                    0
                )
            end)
        end)
    end
end

-- イベント接続
UserInputService.InputBegan:Connect(OnInputBegan)
UserInputService.InputEnded:Connect(OnInputEnded)
UserInputService.TouchStarted:Connect(OnTouchBegan)
UserInputService.TouchEnded:Connect(OnTouchEnded)

local stateEvent = RemoteEvents:GetEvent(RemoteEvents.Names.GAME_STATE_CHANGED)
stateEvent.OnClientEvent:Connect(OnGameStateChanged)

local hitEvent = RemoteEvents:GetEvent(RemoteEvents.Names.ONI_HIT)
hitEvent.OnClientEvent:Connect(OnOniHit)

-- キャラクター読み込み時にカメラ設定
LocalPlayer.CharacterAdded:Connect(SetupCamera)
if LocalPlayer.Character then
    SetupCamera()
end

-- 連射ループ開始
task.spawn(UpdateContinuousFire)

print("[GameClient] Client initialized")
