local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== CONFIG (tweak these) =====
local ACCENT = Color3.fromRGB(200, 55, 55)   -- fatality red
local BG = Color3.fromRGB(15, 15, 18)
local BG2 = Color3.fromRGB(24, 24, 29)
local TEXT = Color3.fromRGB(220, 220, 225)
local DIM = Color3.fromRGB(150, 150, 158)
local OFF = Color3.fromRGB(45, 45, 52)
local STROKE = Color3.fromRGB(50, 50, 58)
local MENU_W = 190
local HEADER_H = 38
local TAB_H = 32
local TABS = { "Legit", "Rage", "Visuals", "Misc" }

local config = {}

-- ===== ROOT =====
local gui = Instance.new("ScreenGui")
gui.Name = "fatality"
gui.ResetOnSpawn = false
gui.Parent = (gethui and gethui()) or playerGui

local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, MENU_W, 0, HEADER_H)  -- collapsed height
menu.Position = UDim2.new(0, 40, 0.35, 0)
menu.BackgroundColor3 = BG
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.Parent = gui
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)
local menuStroke = Instance.new("UIStroke", menu)
menuStroke.Color = STROKE

-- Invisible modal button: frees the mouse cursor while the menu is open
local unlock = Instance.new("TextButton")
unlock.Size = UDim2.new(0, 0, 0, 0)
unlock.BackgroundTransparency = 1
unlock.Text = ""
unlock.Modal = true
unlock.Parent = gui

-- ===== HEADER =====
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundTransparency = 1
header.Text = "  fatality"
header.TextColor3 = TEXT
header.TextXAlignment = Enum.TextXAlignment.Left
header.Font = Enum.Font.GothamBold
header.TextSize = 14
header.Active = true  -- lets the label receive input (needed for dragging)
header.Parent = menu

local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(0, 3, 0, HEADER_H - 14)
accentLine.Position = UDim2.new(0, 0, 0, 7)
accentLine.BackgroundColor3 = ACCENT
accentLine.BorderSizePixel = 0
accentLine.Parent = menu
Instance.new("UICorner",
