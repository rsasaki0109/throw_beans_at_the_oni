--[[
    GameGui - メインUIコンポーネント
    タイマー、スコア、照準、結果画面を管理
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local RemoteEvents = require(Shared:WaitForChild("RemoteEvents"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local GameGui = {}
GameGui.__index = GameGui

function GameGui.new()
    local self = setmetatable({}, GameGui)
    self:CreateUI()
    self:SetupEvents()
    return self
end

function GameGui:CreateUI()
    -- メインScreenGui
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "GameGui"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.screenGui.Parent = PlayerGui

    self:CreateTimer()
    self:CreateScore()
    self:CreateCrosshair()
    self:CreateCountdown()
    self:CreateResultScreen()
    self:CreateStartButton()
end

function GameGui:CreateTimer()
    local timerFrame = Instance.new("Frame")
    timerFrame.Name = "TimerFrame"
    timerFrame.Size = UDim2.new(0, 200, 0, 80)
    timerFrame.Position = UDim2.new(0.5, -100, 0, 20)
    timerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    timerFrame.BackgroundTransparency = 0.5
    timerFrame.BorderSizePixel = 0
    timerFrame.Parent = self.screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = timerFrame

    self.timerLabel = Instance.new("TextLabel")
    self.timerLabel.Name = "TimerLabel"
    self.timerLabel.Size = UDim2.new(1, 0, 1, 0)
    self.timerLabel.BackgroundTransparency = 1
    self.timerLabel.Text = "10"
    self.timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.timerLabel.TextScaled = true
    self.timerLabel.Font = Enum.Font.GothamBold
    self.timerLabel.Parent = timerFrame

    self.timerFrame = timerFrame
    timerFrame.Visible = false
end

function GameGui:CreateScore()
    local scoreFrame = Instance.new("Frame")
    scoreFrame.Name = "ScoreFrame"
    scoreFrame.Size = UDim2.new(0, 180, 0, 60)
    scoreFrame.Position = UDim2.new(1, -200, 0, 20)
    scoreFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    scoreFrame.BackgroundTransparency = 0.5
    scoreFrame.BorderSizePixel = 0
    scoreFrame.Parent = self.screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = scoreFrame

    local scoreTitle = Instance.new("TextLabel")
    scoreTitle.Name = "ScoreTitle"
    scoreTitle.Size = UDim2.new(1, 0, 0.4, 0)
    scoreTitle.BackgroundTransparency = 1
    scoreTitle.Text = "SCORE"
    scoreTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    scoreTitle.TextScaled = true
    scoreTitle.Font = Enum.Font.Gotham
    scoreTitle.Parent = scoreFrame

    self.scoreLabel = Instance.new("TextLabel")
    self.scoreLabel.Name = "ScoreLabel"
    self.scoreLabel.Size = UDim2.new(1, 0, 0.6, 0)
    self.scoreLabel.Position = UDim2.new(0, 0, 0.4, 0)
    self.scoreLabel.BackgroundTransparency = 1
    self.scoreLabel.Text = "0"
    self.scoreLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    self.scoreLabel.TextScaled = true
    self.scoreLabel.Font = Enum.Font.GothamBold
    self.scoreLabel.Parent = scoreFrame

    self.scoreFrame = scoreFrame
    scoreFrame.Visible = false
end

function GameGui:CreateCrosshair()
    local crosshair = Instance.new("Frame")
    crosshair.Name = "Crosshair"
    crosshair.Size = UDim2.new(0, GameConfig.UI.CROSSHAIR_SIZE, 0, GameConfig.UI.CROSSHAIR_SIZE)
    crosshair.Position = UDim2.new(0.5, -GameConfig.UI.CROSSHAIR_SIZE/2, 0.5, -GameConfig.UI.CROSSHAIR_SIZE/2)
    crosshair.BackgroundTransparency = 1
    crosshair.Parent = self.screenGui

    -- 横線
    local horizontal = Instance.new("Frame")
    horizontal.Size = UDim2.new(1, 0, 0, 2)
    horizontal.Position = UDim2.new(0, 0, 0.5, -1)
    horizontal.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    horizontal.BorderSizePixel = 0
    horizontal.Parent = crosshair

    -- 縦線
    local vertical = Instance.new("Frame")
    vertical.Size = UDim2.new(0, 2, 1, 0)
    vertical.Position = UDim2.new(0.5, -1, 0, 0)
    vertical.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    vertical.BorderSizePixel = 0
    vertical.Parent = crosshair

    -- 中心の点
    local center = Instance.new("Frame")
    center.Size = UDim2.new(0, 6, 0, 6)
    center.Position = UDim2.new(0.5, -3, 0.5, -3)
    center.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    center.BorderSizePixel = 0
    center.Parent = crosshair

    local centerCorner = Instance.new("UICorner")
    centerCorner.CornerRadius = UDim.new(1, 0)
    centerCorner.Parent = center

    self.crosshair = crosshair
    crosshair.Visible = false
end

function GameGui:CreateCountdown()
    self.countdownLabel = Instance.new("TextLabel")
    self.countdownLabel.Name = "CountdownLabel"
    self.countdownLabel.Size = UDim2.new(0, 300, 0, 200)
    self.countdownLabel.Position = UDim2.new(0.5, -150, 0.5, -100)
    self.countdownLabel.BackgroundTransparency = 1
    self.countdownLabel.Text = "3"
    self.countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.countdownLabel.TextScaled = true
    self.countdownLabel.Font = Enum.Font.GothamBlack
    self.countdownLabel.TextStrokeTransparency = 0.5
    self.countdownLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    self.countdownLabel.Visible = false
    self.countdownLabel.Parent = self.screenGui
end

function GameGui:CreateResultScreen()
    local resultFrame = Instance.new("Frame")
    resultFrame.Name = "ResultFrame"
    resultFrame.Size = UDim2.new(0, 400, 0, 350)
    resultFrame.Position = UDim2.new(0.5, -200, 0.5, -175)
    resultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    resultFrame.BackgroundTransparency = 0.1
    resultFrame.BorderSizePixel = 0
    resultFrame.Visible = false
    resultFrame.Parent = self.screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = resultFrame

    -- タイトル
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Position = UDim2.new(0, 0, 0, 20)
    title.BackgroundTransparency = 1
    title.Text = "TIME UP!"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.Parent = resultFrame

    -- スコアタイトル
    local scoreTitle = Instance.new("TextLabel")
    scoreTitle.Name = "ScoreTitle"
    scoreTitle.Size = UDim2.new(1, 0, 0, 30)
    scoreTitle.Position = UDim2.new(0, 0, 0, 90)
    scoreTitle.BackgroundTransparency = 1
    scoreTitle.Text = "YOUR SCORE"
    scoreTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    scoreTitle.TextScaled = true
    scoreTitle.Font = Enum.Font.Gotham
    scoreTitle.Parent = resultFrame

    -- スコア
    self.resultScoreLabel = Instance.new("TextLabel")
    self.resultScoreLabel.Name = "ResultScore"
    self.resultScoreLabel.Size = UDim2.new(1, 0, 0, 80)
    self.resultScoreLabel.Position = UDim2.new(0, 0, 0, 120)
    self.resultScoreLabel.BackgroundTransparency = 1
    self.resultScoreLabel.Text = "0"
    self.resultScoreLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
    self.resultScoreLabel.TextScaled = true
    self.resultScoreLabel.Font = Enum.Font.GothamBlack
    self.resultScoreLabel.Parent = resultFrame

    -- リトライボタン
    local retryButton = Instance.new("TextButton")
    retryButton.Name = "RetryButton"
    retryButton.Size = UDim2.new(0, 250, 0, 60)
    retryButton.Position = UDim2.new(0.5, -125, 0, 230)
    retryButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    retryButton.BorderSizePixel = 0
    retryButton.Text = "RETRY"
    retryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    retryButton.TextScaled = true
    retryButton.Font = Enum.Font.GothamBold
    retryButton.Parent = resultFrame

    local retryCorner = Instance.new("UICorner")
    retryCorner.CornerRadius = UDim.new(0, 10)
    retryCorner.Parent = retryButton

    retryButton.MouseButton1Click:Connect(function()
        self:RequestRestart()
    end)

    -- 自動リスタートラベル
    self.autoRestartLabel = Instance.new("TextLabel")
    self.autoRestartLabel.Name = "AutoRestartLabel"
    self.autoRestartLabel.Size = UDim2.new(1, 0, 0, 25)
    self.autoRestartLabel.Position = UDim2.new(0, 0, 0, 300)
    self.autoRestartLabel.BackgroundTransparency = 1
    self.autoRestartLabel.Text = "Auto restart in 3..."
    self.autoRestartLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    self.autoRestartLabel.TextScaled = true
    self.autoRestartLabel.Font = Enum.Font.Gotham
    self.autoRestartLabel.Parent = resultFrame

    self.resultFrame = resultFrame
    self.retryButton = retryButton
end

function GameGui:CreateStartButton()
    local startFrame = Instance.new("Frame")
    startFrame.Name = "StartFrame"
    startFrame.Size = UDim2.new(1, 0, 1, 0)
    startFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
    startFrame.BackgroundTransparency = 0.3
    startFrame.BorderSizePixel = 0
    startFrame.Parent = self.screenGui

    -- タイトル
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 100)
    title.Position = UDim2.new(0, 0, 0.2, 0)
    title.BackgroundTransparency = 1
    title.Text = "Oni Blaster"
    title.TextColor3 = Color3.fromRGB(255, 100, 100)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBlack
    title.Parent = startFrame

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 40)
    subtitle.Position = UDim2.new(0, 0, 0.2, 100)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Bean Throwing Battle"
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = startFrame

    -- スタートボタン
    local startButton = Instance.new("TextButton")
    startButton.Name = "StartButton"
    startButton.Size = UDim2.new(0, 300, 0, 80)
    startButton.Position = UDim2.new(0.5, -150, 0.6, 0)
    startButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    startButton.BorderSizePixel = 0
    startButton.Text = "START"
    startButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    startButton.TextScaled = true
    startButton.Font = Enum.Font.GothamBold
    startButton.Parent = startFrame

    local startCorner = Instance.new("UICorner")
    startCorner.CornerRadius = UDim.new(0, 15)
    startCorner.Parent = startButton

    startButton.MouseButton1Click:Connect(function()
        self:RequestStart()
    end)

    -- 説明
    local instructions = Instance.new("TextLabel")
    instructions.Name = "Instructions"
    instructions.Size = UDim2.new(0.8, 0, 0, 60)
    instructions.Position = UDim2.new(0.1, 0, 0.75, 0)
    instructions.BackgroundTransparency = 1
    instructions.Text = "Click/Tap to throw beans at the Oni!\nHit as many as you can in 10 seconds!"
    instructions.TextColor3 = Color3.fromRGB(180, 180, 180)
    instructions.TextScaled = true
    instructions.Font = Enum.Font.Gotham
    instructions.Parent = startFrame

    self.startFrame = startFrame
end

function GameGui:SetupEvents()
    local stateEvent = RemoteEvents:GetEvent(RemoteEvents.Names.GAME_STATE_CHANGED)
    local scoreEvent = RemoteEvents:GetEvent(RemoteEvents.Names.SCORE_UPDATED)
    local timerEvent = RemoteEvents:GetEvent(RemoteEvents.Names.TIMER_UPDATE)
    local resultEvent = RemoteEvents:GetEvent(RemoteEvents.Names.GAME_RESULT)
    local hitEvent = RemoteEvents:GetEvent(RemoteEvents.Names.ONI_HIT)

    stateEvent.OnClientEvent:Connect(function(state)
        self:OnGameStateChanged(state)
    end)

    scoreEvent.OnClientEvent:Connect(function(score)
        self:UpdateScore(score)
    end)

    timerEvent.OnClientEvent:Connect(function(time)
        self:UpdateTimer(time)
    end)

    resultEvent.OnClientEvent:Connect(function(finalScore, autoRestartTime)
        self:ShowResult(finalScore, autoRestartTime)
    end)

    hitEvent.OnClientEvent:Connect(function(score, position)
        self:ShowScorePopup(score, position)
    end)
end

function GameGui:OnGameStateChanged(state)
    if state == GameConfig.GAME_STATE.WAITING then
        self.startFrame.Visible = true
        self.timerFrame.Visible = false
        self.scoreFrame.Visible = false
        self.crosshair.Visible = false
        self.resultFrame.Visible = false
        self.countdownLabel.Visible = false
    elseif state == GameConfig.GAME_STATE.COUNTDOWN then
        self.startFrame.Visible = false
        self.resultFrame.Visible = false
        self.countdownLabel.Visible = true
        self:PlayCountdown()
    elseif state == GameConfig.GAME_STATE.PLAYING then
        self.countdownLabel.Visible = false
        self.timerFrame.Visible = true
        self.scoreFrame.Visible = true
        self.crosshair.Visible = true
    elseif state == GameConfig.GAME_STATE.RESULT then
        self.crosshair.Visible = false
    end
end

function GameGui:PlayCountdown()
    local counts = {"3", "2", "1", "GO!"}
    for i, text in ipairs(counts) do
        task.delay((i-1) * 0.5, function()
            if self.countdownLabel then
                self.countdownLabel.Text = text
                self.countdownLabel.TextColor3 = (text == "GO!")
                    and Color3.fromRGB(100, 255, 100)
                    or Color3.fromRGB(255, 255, 255)

                -- スケールアニメーション
                self.countdownLabel.TextScaled = false
                self.countdownLabel.TextSize = 150
                local tween = TweenService:Create(
                    self.countdownLabel,
                    TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    {TextSize = 200}
                )
                tween:Play()
            end
        end)
    end
end

function GameGui:UpdateScore(score)
    if self.scoreLabel then
        self.scoreLabel.Text = tostring(score)
    end
end

function GameGui:UpdateTimer(time)
    if self.timerLabel then
        self.timerLabel.Text = tostring(math.ceil(time))
        if time <= 3 then
            self.timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        else
            self.timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

function GameGui:ShowResult(finalScore, autoRestartTime)
    self.resultFrame.Visible = true
    self.resultScoreLabel.Text = tostring(finalScore)

    -- 自動リスタートカウントダウン
    for i = autoRestartTime, 1, -1 do
        task.delay(autoRestartTime - i, function()
            if self.autoRestartLabel then
                self.autoRestartLabel.Text = string.format("Auto restart in %d...", i)
            end
        end)
    end
end

function GameGui:ShowScorePopup(score, position)
    local camera = workspace.CurrentCamera
    if not camera then return end

    local screenPos, onScreen = camera:WorldToScreenPoint(position)
    if not onScreen then return end

    local popup = Instance.new("TextLabel")
    popup.Name = "ScorePopup"
    popup.Size = UDim2.new(0, 100, 0, 50)
    popup.Position = UDim2.new(0, screenPos.X - 50, 0, screenPos.Y - 25)
    popup.BackgroundTransparency = 1
    popup.Text = "+" .. tostring(score)
    popup.TextColor3 = Color3.fromRGB(255, 215, 0)
    popup.TextScaled = true
    popup.Font = Enum.Font.GothamBold
    popup.TextStrokeTransparency = 0.5
    popup.Parent = self.screenGui

    -- アニメーション
    local tween = TweenService:Create(
        popup,
        TweenInfo.new(GameConfig.EFFECTS.SCORE_POPUP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(0, screenPos.X - 50, 0, screenPos.Y - 75), TextTransparency = 1}
    )
    tween:Play()
    tween.Completed:Connect(function()
        popup:Destroy()
    end)
end

function GameGui:RequestStart()
    local event = RemoteEvents:GetEvent(RemoteEvents.Names.REQUEST_START)
    event:FireServer()
end

function GameGui:RequestRestart()
    local event = RemoteEvents:GetEvent(RemoteEvents.Names.REQUEST_RESTART)
    event:FireServer()
end

return GameGui
