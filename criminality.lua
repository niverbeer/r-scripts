local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer

local function build()
   local playerGui = player:WaitForChild("PlayerGui")

   -- ===== CONFIG =====
   local ACCENT = Color3.fromRGB(200, 55, 55)
   local BG = Color3.fromRGB(15, 15, 18)
   local BG2 = Color3.fromRGB(24, 24, 29)
   local TEXT = Color3.fromRGB(220, 220, 225)
   local DIM = Color3.fromRGB(150, 150, 158)
   local OFF = Color3.fromRGB(45, 45, 52)
   local STROKE = Color3.fromRGB(50, 50, 58)
   local MENU_W, HEADER_H, TAB_H = 190, 38, 32
   local CONTENT_W = 230
   local TABS = { "Legit", "Rage", "Visuals", "Misc" }
   local FULL_H = HEADER_H + #TABS * (TAB_H + 2)

   local ACCENT_PRESETS = {
      Color3.fromRGB(200, 55, 55),   -- red
      Color3.fromRGB(70, 130, 230),  -- blue
      Color3.fromRGB(80, 200, 120),  -- green
      Color3.fromRGB(170, 90, 230),  -- purple
      Color3.fromRGB(240, 170, 50),  -- orange
   }
   local accentIndex = 1

   local config = {}
   local accentRefs = {} -- functions that repaint accent-colored things

   for _, n in ipairs({ "fatality", "fatality_wm" }) do
      local old = playerGui:FindFirstChild(n)
      if old then old:Destroy() end
   end

   -- ===== ROOT =====
   local gui = Instance.new("ScreenGui")
   gui.Name = "fatality"
   gui.ResetOnSpawn = false
   gui.DisplayOrder = 999
   gui.Parent = playerGui

   local wmGui = Instance.new("ScreenGui")
   wmGui.Name = "fatality_wm"
   wmGui.ResetOnSpawn = false
   wmGui.DisplayOrder = 998
   wmGui.Parent = playerGui

   local function round(obj, r)
      local c = Instance.new("UICorner")
      c.CornerRadius = UDim.new(0, r)
      c.Parent = obj
   end
   local function stroke(obj)
      local s = Instance.new("UIStroke")
      s.Color = STROKE
      s.Parent = obj
   end

   -- ===== MENU =====
   local menu = Instance.new("Frame")
   menu.Name = "menu"
   menu.Size = UDim2.new(0, MENU_W, 0, HEADER_H)
   menu.Position = UDim2.new(0, 60, 0, 200)
   menu.BackgroundColor3 = BG
   menu.BorderSizePixel = 0
   menu.ClipsDescendants = true
   menu.Parent = gui
   round(menu, 6)
   stroke(menu)

   local header = Instance.new("TextButton")
   header.Size = UDim2.new(1, -HEADER_H, 0, HEADER_H)
   header.BackgroundTransparency = 1
   header.AutoButtonColor = false
   header.Text = "   fatality"
   header.TextColor3 = TEXT
   header.TextXAlignment = Enum.TextXAlignment.Left
   header.Font = Enum.Font.GothamBold
   header.TextSize = 14
   header.Parent = menu

   local accentLine = Instance.new("Frame")
   accentLine.Size = UDim2.new(0, 3, 0, HEADER_H - 14)
   accentLine.Position = UDim2.new(0, 0, 0, 7)
   accentLine.BackgroundColor3 = ACCENT
   accentLine.BorderSizePixel = 0
   accentLine.Parent = menu
   round(accentLine, 2)
   table.insert(accentRefs, function() accentLine.BackgroundColor3 = ACCENT end)

   local plus = Instance.new("TextButton")
   plus.Size = UDim2.new(0, HEADER_H, 0, HEADER_H)
   plus.Position = UDim2.new(1, -HEADER_H, 0, 0)
   plus.BackgroundTransparency = 1
   plus.AutoButtonColor = false
   plus.Text = "+"
   plus.TextColor3 = TEXT
   plus.Font = Enum.Font.GothamBold
   plus.TextSize = 20
   plus.Parent = menu

   local list = Instance.new("Frame")
   list.Size = UDim2.new(1, 0, 0, #TABS * (TAB_H + 2))
   list.Position = UDim2.new(0, 0, 0, HEADER_H)
   list.BackgroundTransparency = 1
   list.Parent = menu
   local layout = Instance.new("UIListLayout")
   layout.Padding = UDim.new(0, 2)
   layout.Parent = list

   -- ===== CONTENT WINDOW =====
   local content = Instance.new("Frame")
   content.Name = "content"
   content.Size = UDim2.new(0, CONTENT_W, 0, FULL_H)
   content.BackgroundColor3 = BG
   content.BorderSizePixel = 0
   content.Visible = false
   content.Parent = gui
   round(content, 6)
   stroke(content)

   local function syncContent()
      content.Position = UDim2.new(0, menu.Position.X.Offset + MENU_W + 8, 0, menu.Position.Y.Offset)
   end
   syncContent()

   -- ===== DRAGGING (listeners only exist while dragging) =====
   header.InputBegan:Connect(function(input)
      if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
      local dragStart = input.Position
