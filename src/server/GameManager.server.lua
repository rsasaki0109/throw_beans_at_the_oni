--[[
    GameManager - サーバーサイドゲーム管理
    ゲーム状態、鬼のスポーン、スコア管理を担当
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))
local ModelFactory = require(Shared:WaitForChild("ModelFactory"))

-- RemoteEventsを初期化
RemoteEvents:InitializeAll()

-- プレイヤーデータ管理
local PlayerData = {}

-- 鬼管理
local ActiveOnis = {}
local OniFolder = Instance.new("Folder")
OniFolder.Name = "Onis"
OniFolder.Parent = workspace

-- ゲームエリア作成
local function CreateGameArea()
    -- 床
    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(60, 1, 60)
    floor.Position = Vector3.new(0, -0.5, 0)
    floor.Color = Color3.fromRGB(100, 150, 100)
    floor.Material = Enum.Material.Grass
    floor.Anchored = true
    floor.CanCollide = true
    floor.Parent = workspace

    -- 背景壁
    local backWall = Instance.new("Part")
    backWall.Name = "BackWall"
    backWall.Size = Vector3.new(60, 20, 1)
    backWall.Position = Vector3.new(0, 10, 40)
    backWall.Color = Color3.fromRGB(139, 90, 43)
    backWall.Material = Enum.Material.Wood
    backWall.Anchored = true
    backWall.CanCollide = true
    backWall.Parent = workspace

    -- プレイヤー位置マーカー
    local spawnPoint = Instance.new("SpawnLocation")
    spawnPoint.Name = "SpawnLocation"
    spawnPoint.Size = Vector3.new(4, 1, 4)
    spawnPoint.Position = Vector3.new(0, 0.5, -10)
    spawnPoint.Color = Color3.fromRGB(80, 80, 80)
    spawnPoint.Material = Enum.Material.SmoothPlastic
    spawnPoint.Anchored = true
    spawnPoint.CanCollide = true
    spawnPoint.Enabled = true
    spawnPoint.Neutral = true
    spawnPoint.Parent = workspace
end

-- プレイヤーデータ初期化
local function InitPlayerData(player)
    PlayerData[player.UserId] = {
        score = 0,
        gameState = GameConfig.GAME_STATE.WAITING,
        lastThrowTime = 0,
    }
end

-- プレイヤーデータクリーンアップ
local function CleanupPlayerData(player)
    PlayerData[player.UserId] = nil
end

-- スコア更新
local function UpdateScore(player, amount)
    local data = PlayerData[player.UserId]
    if not data then return end

    data.score = data.score + amount

    local scoreEvent = RemoteEvents:GetEvent(RemoteEvents.Names.SCORE_UPDATED)
    scoreEvent:FireClient(player, data.score)
end

-- ゲーム状態変更
local function SetGameState(player, state)
    local data = PlayerData[player.UserId]
    if not data then return end

    data.gameState = state

    local stateEvent = RemoteEvents:GetEvent(RemoteEvents.Names.GAME_STATE_CHANGED)
    stateEvent:FireClient(player, state)
end

-- 鬼をスポーン
local function SpawnOni(player)
    local data = PlayerData[player.UserId]
    if not data or data.gameState ~= GameConfig.GAME_STATE.PLAYING then
        return nil
    end

    -- 最大数チェック
    local playerOnis = {}
    for _, oni in pairs(ActiveOnis) do
        if oni:GetAttribute("OwnerUserId") == player.UserId then
            table.insert(playerOnis, oni)
        end
    end

    if #playerOnis >= GameConfig.ONI.MAX_COUNT then
        return nil
    end

    -- 鬼の作成
    local oni = ModelFactory.CreateOni("NORMAL")

    -- スポーン位置計算（プレイヤーの前方）
    local character = player.Character
    if not character then return nil end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end

    local playerPos = humanoidRootPart.Position
    local randomX = (math.random() - 0.5) * 2 * GameConfig.ONI.SPAWN_WIDTH
    local spawnPos = Vector3.new(
        playerPos.X + randomX,
        GameConfig.ONI.SPAWN_HEIGHT,
        playerPos.Z + GameConfig.ONI.SPAWN_DISTANCE
    )

    ModelFactory.PositionOniParts(oni, spawnPos)

    -- 属性設定
    oni:SetAttribute("OwnerUserId", player.UserId)
    oni:SetAttribute("SpawnTime", tick())
    oni:SetAttribute("MoveDirection", math.random() > 0.5 and 1 or -1)

    oni.Parent = OniFolder
    table.insert(ActiveOnis, oni)

    -- クライアントに通知
    local spawnEvent = RemoteEvents:GetEvent(RemoteEvents.Names.ONI_SPAWNED)
    spawnEvent:FireClient(player, oni)

    return oni
end

-- 鬼の移動処理
local function UpdateOniMovement(deltaTime)
    for i = #ActiveOnis, 1, -1 do
        local oni = ActiveOnis[i]
        if oni and oni.Parent then
            local torso = oni:FindFirstChild("Torso")
            if torso then
                local direction = oni:GetAttribute("MoveDirection") or 1
                local speed = GameConfig.ONI.MOVE_SPEED * (oni:GetAttribute("SpeedMultiplier") or 1)

                local currentPos = torso.Position
                local newX = currentPos.X + (direction * speed * deltaTime)

                -- 境界で反転
                if math.abs(newX) > GameConfig.ONI.SPAWN_WIDTH then
                    direction = -direction
                    oni:SetAttribute("MoveDirection", direction)
                    newX = currentPos.X + (direction * speed * deltaTime)
                end

                local newPos = Vector3.new(newX, currentPos.Y, currentPos.Z)
                ModelFactory.PositionOniParts(oni, newPos)
            end
        else
            table.remove(ActiveOnis, i)
        end
    end
end

-- 鬼ヒット処理
local function OnOniHit(player, oni)
    local data = PlayerData[player.UserId]
    if not data or data.gameState ~= GameConfig.GAME_STATE.PLAYING then
        return false
    end

    if not oni or not oni.Parent then
        return false
    end

    -- オーナーチェック
    if oni:GetAttribute("OwnerUserId") ~= player.UserId then
        return false
    end

    local score = oni:GetAttribute("Score") or GameConfig.SCORE.NORMAL_ONI
    local torso = oni:FindFirstChild("Torso")
    local hitPosition = torso and torso.Position or Vector3.new(0, 0, 0)

    -- スコア加算
    UpdateScore(player, score)

    -- ヒットイベント通知
    local hitEvent = RemoteEvents:GetEvent(RemoteEvents.Names.ONI_HIT)
    hitEvent:FireClient(player, score, hitPosition)

    -- 鬼を削除
    for i, activeOni in ipairs(ActiveOnis) do
        if activeOni == oni then
            table.remove(ActiveOnis, i)
            break
        end
    end

    -- ヒットエフェクト
    local effect = ModelFactory.CreateHitEffect(hitPosition, oni:FindFirstChild("Torso") and oni.Torso.Color)
    effect.Parent = workspace
    Debris:AddItem(effect, 0.5)

    oni:Destroy()

    return true
end

-- プレイヤーの鬼をすべて削除
local function ClearPlayerOnis(player)
    for i = #ActiveOnis, 1, -1 do
        local oni = ActiveOnis[i]
        if oni:GetAttribute("OwnerUserId") == player.UserId then
            oni:Destroy()
            table.remove(ActiveOnis, i)
        end
    end
end

-- ゲーム開始
local function StartGame(player)
    local data = PlayerData[player.UserId]
    if not data then return end

    -- 既にプレイ中なら無視
    if data.gameState == GameConfig.GAME_STATE.PLAYING or
       data.gameState == GameConfig.GAME_STATE.COUNTDOWN then
        return
    end

    -- スコアリセット
    data.score = 0
    UpdateScore(player, 0)

    -- カウントダウン開始
    SetGameState(player, GameConfig.GAME_STATE.COUNTDOWN)

    -- カウントダウン後にゲーム開始
    task.delay(GameConfig.COUNTDOWN_TIME, function()
        if not PlayerData[player.UserId] then return end

        SetGameState(player, GameConfig.GAME_STATE.PLAYING)

        -- 鬼スポーンループ
        local spawnConnection
        spawnConnection = RunService.Heartbeat:Connect(function()
            local currentData = PlayerData[player.UserId]
            if not currentData or currentData.gameState ~= GameConfig.GAME_STATE.PLAYING then
                if spawnConnection then
                    spawnConnection:Disconnect()
                end
                return
            end
        end)

        -- 定期的に鬼をスポーン
        task.spawn(function()
            while PlayerData[player.UserId] and
                  PlayerData[player.UserId].gameState == GameConfig.GAME_STATE.PLAYING do
                SpawnOni(player)
                task.wait(GameConfig.ONI.SPAWN_INTERVAL)
            end
        end)

        -- タイマー
        local startTime = tick()
        task.spawn(function()
            while PlayerData[player.UserId] and
                  PlayerData[player.UserId].gameState == GameConfig.GAME_STATE.PLAYING do
                local elapsed = tick() - startTime
                local remaining = GameConfig.PLAY_TIME - elapsed

                local timerEvent = RemoteEvents:GetEvent(RemoteEvents.Names.TIMER_UPDATE)
                timerEvent:FireClient(player, remaining)

                if remaining <= 0 then
                    EndGame(player)
                    break
                end

                task.wait(0.1)
            end
        end)
    end)
end

-- ゲーム終了
function EndGame(player)
    local data = PlayerData[player.UserId]
    if not data then return end

    SetGameState(player, GameConfig.GAME_STATE.RESULT)

    -- 鬼をクリア
    ClearPlayerOnis(player)

    -- 結果送信
    local resultEvent = RemoteEvents:GetEvent(RemoteEvents.Names.GAME_RESULT)
    resultEvent:FireClient(player, data.score, GameConfig.AUTO_RESTART_TIME)

    -- 自動リスタート
    task.delay(GameConfig.AUTO_RESTART_TIME, function()
        local currentData = PlayerData[player.UserId]
        if currentData and currentData.gameState == GameConfig.GAME_STATE.RESULT then
            StartGame(player)
        end
    end)
end

-- 豆投擲処理
local function OnThrowBean(player, origin, direction)
    local data = PlayerData[player.UserId]
    if not data or data.gameState ~= GameConfig.GAME_STATE.PLAYING then
        return
    end

    -- 発射レート制限
    local currentTime = tick()
    if currentTime - data.lastThrowTime < GameConfig.BEAN.FIRE_RATE then
        return
    end
    data.lastThrowTime = currentTime

    -- 豆を作成
    local bean = ModelFactory.CreateBean()
    bean.Position = origin
    bean.Parent = workspace

    -- 速度を設定
    local velocity = direction.Unit * GameConfig.BEAN.SPEED
    bean.AssemblyLinearVelocity = velocity

    -- ライフタイム設定
    Debris:AddItem(bean, GameConfig.BEAN.LIFETIME)

    -- 衝突検知
    bean.Touched:Connect(function(hit)
        if not bean.Parent then return end

        -- 鬼との衝突チェック
        local oniModel = hit.Parent
        if oniModel and oniModel:GetAttribute("OniType") then
            if OnOniHit(player, oniModel) then
                bean:Destroy()
            end
        end
    end)
end

-- イベント接続
local startEvent = RemoteEvents:GetEvent(RemoteEvents.Names.REQUEST_START)
startEvent.OnServerEvent:Connect(function(player)
    StartGame(player)
end)

local restartEvent = RemoteEvents:GetEvent(RemoteEvents.Names.REQUEST_RESTART)
restartEvent.OnServerEvent:Connect(function(player)
    StartGame(player)
end)

local throwEvent = RemoteEvents:GetEvent(RemoteEvents.Names.THROW_BEAN)
throwEvent.OnServerEvent:Connect(function(player, origin, direction)
    OnThrowBean(player, origin, direction)
end)

-- プレイヤー接続処理
Players.PlayerAdded:Connect(function(player)
    InitPlayerData(player)
    SetGameState(player, GameConfig.GAME_STATE.WAITING)
end)

Players.PlayerRemoving:Connect(function(player)
    ClearPlayerOnis(player)
    CleanupPlayerData(player)
end)

-- 既存プレイヤーの処理
for _, player in pairs(Players:GetPlayers()) do
    InitPlayerData(player)
    SetGameState(player, GameConfig.GAME_STATE.WAITING)
end

-- 鬼の移動更新
RunService.Heartbeat:Connect(function(deltaTime)
    UpdateOniMovement(deltaTime)
end)

-- ゲームエリア作成
CreateGameArea()

print("[GameManager] Server initialized")
