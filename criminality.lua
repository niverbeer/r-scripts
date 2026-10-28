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

-- remove any old copy from a previous execute
local old = playerGui:FindFirstChild("fatality")
if old then old:Destroy() end

-- ===== ROOT =====
local gui = Instance.new("ScreenGui")
gui.Name = "fatality"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui  -- plain PlayerGui, no gethui()

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
header.Active = true
header.Parent = menu

local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(0, 3, 0, HEADER_H - 14)
accentLine.Position = UDim2.new(0, 0, 0, 7)
accentLine.BackgroundColor3 = ACCENT
accentLine.BorderSizePixel = 0
accentLine.Parent = menu
Instance.new("UICorner", accentLine).CornerRadius = UDim.new(0, 2)

-- ===== CONTENT WINDOW (right side, parented to gui so it isn't clipped) =====
local content = Instance.new("Frame")
content.Size = UDim2.new(0, 230, 0, HEADER_H + #TABS * (TAB_H + 2))
content.BackgroundColor3 = BG
content.BorderSizePixel = 0
content.Visible = false
content.Parent = gui
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 6)
local contentStroke = Instance.new("UIStroke", content)
contentStroke.Color = STROKE

local function syncContent()
   content.Position = UDim2.new(
      menu.Position.X.Scale, menu.Position.X.Offset + MENU_W + 8,
      menu.Position.Y.Scale, menu.Position.Y.Offset
   )
end
menu:GetPropertyChangedSignal("Position"):Connect(syncContent)
syncContent()

-- ===== DRAG THE MENU (hold the title bar) =====
local dragging, dragStart, startPos

header.InputBegan:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
      dragging = true
      dragStart = UserInputService:GetMouseLocation()
      startPos = menu.Position
      input.Changed:Connect(function()
