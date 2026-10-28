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
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- try gethui(), fall back to PlayerGui if it fails
local ok = pcall(function() gui.Parent = gethui() end)
if not ok or not gui.Parent then
   gui.Parent = playerGui
end

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
         if input.UserInputState == Enum.UserInputState.End then
            dragging = false
         end
      end)
   end
end)

UserInputService.InputChanged:Connect(function(input)
   if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
      local delta = UserInputService:GetMouseLocation() - dragStart
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
   if not v then content.Visible = false end
end

plus.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

-- ===== CONTROLS =====
local function addToggle(page, label, key, y)
   config[key] = false
   local row = Instance.new("TextButton")
   row.Size = UDim2.new(1, -16, 0, 26)
   row.Position = UDim2.new(0, 8, 0, y)
   row.BackgroundColor3 = BG2
   row.Text = "  " .. label
   row.TextColor3 = TEXT
   row.TextXAlignment = Enum.TextXAlignment.Left
   row.Font = Enum.Font.Gotham
   row.TextSize = 13
   row.AutoButtonColor = false
   row.Parent = page
   Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

   local box = Instance.new("Frame")
   box.Size = UDim2.new(0, 14, 0, 14)
   box.Position = UDim2.new(1, -24, 0.5, -7)
   box.BackgroundColor3 = OFF
   box.BorderSizePixel = 0
   box.Parent = row
   Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

   row.MouseButton1Click:Connect(function()
      config[key] = not config[key]
      TweenService:Create(box, TweenInfo.new(0.15), {
         BackgroundColor3 = config[key] and ACCENT or OFF
      }):Play()
   end)
end

local function addSlider(page, label, key, min, max, default, y)
   config[key] = default
   local holder = Instance.new("Frame")
   holder.Size = UDim2.new(1, -16, 0, 34)
   holder.Position = UDim2.new(0, 8, 0, y)
   holder.BackgroundTransparency = 1
   holder.Parent = page

   local txt = Instance.new("TextLabel")
   txt.Size = UDim2.new(1, 0, 0, 16)
   txt.BackgroundTransparency = 1
   txt.Text = label .. ": " .. default
   txt.TextColor3 = TEXT
   txt.TextXAlignment = Enum.TextXAlignment.Left
   txt.Font = Enum.Font.Gotham
   txt.TextSize = 12
   txt.Parent = holder

   local bar = Instance.new("Frame")
   bar.Size = UDim2.new(1, 0, 0, 6)
   bar.Position = UDim2.new(0, 0, 0, 22)
   bar.BackgroundColor3 = BG2
   bar.BorderSizePixel = 0
   bar.Active = true
   bar.Parent = holder
   Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

   local fill = Instance.new("Frame")
   fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
   fill.BackgroundColor3 = ACCENT
   fill.BorderSizePixel = 0
   fill.Parent = bar
   Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

   local sliding = false
   local function update(x)
      local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
      local v = math.floor(min + (max - min) * a + 0.5)
      config[key] = v
      fill.Size = UDim2.new(a, 0, 1, 0)
      txt.Text = label .. ": " .. v
   end
   bar.InputBegan:Connect(function(i)
      if i.UserInputType == Enum.UserInputType.MouseButton1 then
         sliding = true
         update(UserInputService:GetMouseLocation().X)
      end
   end)
   UserInputService.InputEnded:Connect(function(i)
      if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
   end)
   UserInputService.InputChanged:Connect(function(i)
      if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
         update(UserInputService:GetMouseLocation().X)
      end
   end)
end

-- ===== TABS + PAGES =====
for i, name in ipairs(TABS) do
   local btn = Instance.new("TextButton")
   btn.Size = UDim2.new(1, -8, 0, TAB_H)
   btn.BackgroundColor3 = BG2
   btn.BackgroundTransparency = 1
   btn.Text = "     " .. name:lower()
   btn.TextColor3 = DIM
   btn.TextXAlignment = Enum.TextXAlignment.Left
   btn.Font = Enum.Font.Gotham
   btn.TextSize = 13
   btn.LayoutOrder = i
   btn.Parent = list
   Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

   local page = Instance.new("Frame")
   page.Size = UDim2.new(1, 0, 1, 0)
   page.BackgroundTransparency = 1
   page.Visible = false
   page.Parent = content
   contentPages[name] = page

   -- placeholder controls: rename the labels/keys and add your own
   addToggle(page, "Option 1", name .. "_opt1", 10)
   addToggle(page, "Option 2", name .. "_opt2", 42)
   addSlider(page, "Value", name .. "_value", 0, 100, 50, 80)

   btn.MouseEnter:Connect(function()
      btn.BackgroundTransparency = 0
      btn.TextColor3 = TEXT
   end)
   btn.MouseLeave:Connect(function()
      btn.BackgroundTransparency = 1
      btn.TextColor3 = DIM
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
      unlock.Modal = menuOpen
   end
end)

print("fatality loaded")
