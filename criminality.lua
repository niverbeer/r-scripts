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
local MENU_W = 190
local HEADER_H = 38
local TAB_H = 32
local TABS = { "Legit", "Rage", "Visuals", "Misc" }

-- ===== ROOT =====
local gui = Instance.new("ScreenGui")
gui.Name = "fatality"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, MENU_W, 0, HEADER_H)  -- collapsed height
menu.Position = UDim2.new(0, 40, 0.35, 0)
menu.BackgroundColor3 = BG
menu.BorderSizePixel = 0
menu.ClipsDescendants = true
menu.Parent = gui
Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)
local menuStroke = Instance.new("UIStroke", menu)
menuStroke.Color = Color3.fromRGB(50, 50, 58)

-- ===== HEADER =====
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, HEADER_H)
header.BackgroundTransparency = 1
header.Text = "  fatality"
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
Instance.new("UICorner", accentLine).CornerRadius = UDim.new(0, 2)

-- ===== DRAG THE MENU (hold the title bar) =====
local dragging, dragStart, startPos

header.InputBegan:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
      dragging = true
      dragStart = input.Position
      startPos = menu.Position
      input.Changed:Connect(function()
         if input.UserInputState == Enum.UserInputState.End then
            dragging = false
         end
      end)
   end
end)

UserInputService.InputChanged:Connect(function(input)
   if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
      local delta = input.Position - dragStart
      menu.Position = UDim2.new(
         startPos.X.Scale, startPos.X.Offset + delta.X,
         startPos.Y.Scale, startPos.Y.Offset + delta.Y
      )
   end
end)

-- ===== + BUTTON =====
local plus = Instance.new("TextButton")
plus.Size = UDim2.new(0, HEADER_H, 0, HEADER_H)
plus.Position = UDim2.new(1, -HEADER_H, 0, 0)
plus.BackgroundTransparency = 1
plus.Text = "+"
plus.TextColor3 = TEXT
plus.Font = Enum.Font.GothamBold
plus.TextSize = 18
plus.Parent = menu

-- ===== TAB LIST =====
local list = Instance.new("Frame")
list.Size = UDim2.new(1, 0, 1, -HEADER_H)
list.Position = UDim2.new(0, 0, 0, HEADER_H)
list.BackgroundTransparency = 1
list.Parent = menu

local listLayout = Instance.new("UIListLayout", list)
listLayout.Padding = UDim.new(0, 2)

local expanded = false
local contentPages = {}

local function setExpanded(v)
   expanded = v
   local targetH = HEADER_H + (v and (#TABS * (TAB_H + 2)) or 0)
   TweenService:Create(menu, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
      Size = UDim2.new(0, MENU_W, 0, targetH)
   }):Play()
   TweenService:Create(plus, TweenInfo.new(0.25), {
      Rotation = v and 45 or 0
   }):Play()
end

plus.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

-- ===== CONTENT WINDOW (right side) =====
local content = Instance.new("Frame")
content.Size = UDim2.new(0, 230, 0, HEADER_H + #TABS * (TAB_H + 2))
content.Position = UDim2.new(0, MENU_W + 8, 0, 0)
content.BackgroundColor3 = BG
content.BorderSizePixel = 0
content.Visible = false
content.Parent = menu
Instance.new("UICorner", content).CornerRadius = UDim.new(0, 6)
local contentStroke = Instance.new("UIStroke", content)
contentStroke.Color = Color3.fromRGB(50, 50, 58)

-- ===== TABS =====
for i, name in ipairs(TABS) do
   local btn = Instance.new("TextButton")
   btn.Size = UDim2.new(1, -8, 0, TAB_H)
   btn.BackgroundColor3 = BG2
   btn.BackgroundTransparency = 1
   btn.Text = "     " .. name:lower()
   btn.TextColor3 = Color3.fromRGB(150, 150, 158)
   btn.TextXAlignment = Enum.TextXAlignment.Left
   btn.Font = Enum.Font.Gotham
   btn.TextSize = 13
   btn.LayoutOrder = i
   btn.Parent = list
   Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

   local page = Instance.new("TextLabel")
   page.Size = UDim2.new(1, 0, 1, 0)
   page.BackgroundTransparency = 1
   page.Text = name .. " page"
   page.TextColor3 = Color3.fromRGB(120, 120, 128)
   page.Font = Enum.Font.Gotham
   page.TextSize = 13
   page.Visible = false
   page.Parent = content
   contentPages[name] = page

   btn.MouseEnter:Connect(function()
      btn.BackgroundTransparency = 0
      btn.TextColor3 = TEXT
   end)
   btn.MouseLeave:Connect(function()
      btn.BackgroundTransparency = 1
      btn.TextColor3 = Color3.fromRGB(150, 150, 158)
   end)
   btn.MouseButton1Click:Connect(function()
      content.Visible = true
      for n, p in pairs(contentPages) do p.Visible = (n == name) end
   end)
end

-- ===== SHOW/HIDE WITH INSERT =====
local menuOpen = true
UserInputService.InputBegan:Connect(function(input, gpe)
   if gpe then return end
   if input.KeyCode == Enum.KeyCode.Insert then
      menuOpen = not menuOpen
      gui.Enabled = menuOpen
   end
end)
