--[[
    GameConfig - ゲーム設定モジュール
    鬼退治！豆まきバトル (Oni Blaster)
]]

local GameConfig = {}

-- ゲーム時間設定
GameConfig.COUNTDOWN_TIME = 2        -- カウントダウン時間（秒）
GameConfig.PLAY_TIME = 10            -- プレイ時間（秒）
GameConfig.RESULT_TIME = 3           -- 結果表示時間（秒）
GameConfig.AUTO_RESTART_TIME = 3     -- 自動リスタート時間（秒）

-- スコア設定
GameConfig.SCORE = {
    NORMAL_ONI = 10,    -- 通常鬼（青）
    FAST_ONI = 30,      -- 高速鬼（赤）※v2
    GOLD_ONI = 100,     -- 金鬼 ※v2
}

-- 豆設定
GameConfig.BEAN = {
    FIRE_RATE = 0.15,           -- 発射間隔（秒）
    SPEED = 100,                -- 初速
    GRAVITY = 196.2,            -- 重力
    SIZE = Vector3.new(0.3, 0.25, 0.3),  -- 豆のサイズ
    COLOR = Color3.fromRGB(210, 180, 140), -- 薄茶色
    LIFETIME = 3,               -- 豆の生存時間（秒）
}

-- 鬼設定
GameConfig.ONI = {
    SPAWN_INTERVAL = 1.5,       -- 鬼のスポーン間隔（秒）
    MAX_COUNT = 5,              -- 同時出現最大数
    MOVE_SPEED = 5,             -- 移動速度
    SIZE = Vector3.new(4, 6, 2), -- 鬼のサイズ
    SPAWN_DISTANCE = 30,        -- プレイヤーからの距離
    SPAWN_HEIGHT = 3,           -- スポーン高さ
    SPAWN_WIDTH = 20,           -- 左右のスポーン範囲
    HIT_KNOCKBACK = 10,         -- ヒット時のノックバック
}

-- 鬼の種類
GameConfig.ONI_TYPES = {
    NORMAL = {
        name = "Normal",
        color = Color3.fromRGB(70, 130, 180),  -- 青
        score = GameConfig.SCORE.NORMAL_ONI,
        speed = 1.0,
        spawnRate = 1.0,  -- MVP: 通常鬼のみ
    },
}

-- ゲーム状態
GameConfig.GAME_STATE = {
    WAITING = "Waiting",
    COUNTDOWN = "Countdown",
    PLAYING = "Playing",
    RESULT = "Result",
}

-- UI設定
GameConfig.UI = {
    TIMER_FONT_SIZE = 72,
    SCORE_FONT_SIZE = 48,
    CROSSHAIR_SIZE = 40,
}

-- エフェクト設定
GameConfig.EFFECTS = {
    HIT_PARTICLE_COUNT = 10,
    SCORE_POPUP_DURATION = 0.5,
}

return GameConfig
