--[[
    RemoteEvents - クライアント/サーバー間通信イベント定義
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = {}

-- イベント名の定義
RemoteEvents.Names = {
    -- クライアント → サーバー
    THROW_BEAN = "ThrowBean",           -- 豆を投げる
    REQUEST_START = "RequestStart",     -- ゲーム開始リクエスト
    REQUEST_RESTART = "RequestRestart", -- リスタートリクエスト

    -- サーバー → クライアント
    GAME_STATE_CHANGED = "GameStateChanged", -- ゲーム状態変更
    SCORE_UPDATED = "ScoreUpdated",          -- スコア更新
    ONI_SPAWNED = "OniSpawned",              -- 鬼スポーン
    ONI_HIT = "OniHit",                      -- 鬼ヒット
    TIMER_UPDATE = "TimerUpdate",            -- タイマー更新
    GAME_RESULT = "GameResult",              -- ゲーム結果
}

-- RemoteEventsフォルダの取得または作成
function RemoteEvents:GetFolder()
    local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "RemoteEvents"
        folder.Parent = ReplicatedStorage
    end
    return folder
end

-- RemoteEventの取得または作成
function RemoteEvents:GetEvent(name)
    local folder = self:GetFolder()
    local event = folder:FindFirstChild(name)
    if not event then
        event = Instance.new("RemoteEvent")
        event.Name = name
        event.Parent = folder
    end
    return event
end

-- 全イベントの初期化（サーバー側で呼ぶ）
function RemoteEvents:InitializeAll()
    for _, name in pairs(self.Names) do
        self:GetEvent(name)
    end
end

return RemoteEvents
