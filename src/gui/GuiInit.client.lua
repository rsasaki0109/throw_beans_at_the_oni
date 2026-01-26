--[[
    GuiInit - GUIの初期化
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

-- GameGuiモジュールを読み込み、初期化
local GameGuiModule = script.Parent:WaitForChild("GameGui")
local GameGui = require(GameGuiModule)

-- GUIインスタンス作成
local gui = GameGui.new()

print("[GuiInit] GUI initialized")
