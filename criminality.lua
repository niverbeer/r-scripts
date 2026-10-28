local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
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

   local config = {}

   local old = playerGui:FindFirstChild("fatality")
   if old then old:Destroy() end

   -- ===== ROOT =====
   local gui = Instance.new("ScreenGui")
   gui.Name = "fatality"
   gui.ResetOnSpawn = false
   gui.DisplayOrder = 999
   gui.Parent = playerGui

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

   -- ===== MENU (header + tab list) =====
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

   -- ===== CONTENT WINDOW (separate, so it never gets clipped) =====
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
      content.Position = UDim2.new(
         0, menu.Position.X.Offset + MENU_W + 8,
         0, menu.Position.Y.Offset
      )
   end
   syncContent()

   -- ===== DRAGGING =====
   local dragging, dragStart, startPos = false, nil, nil
   header.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 then
         dragging = true
         dragStart = input.Position
         startPos = menu.Position
      end
   end)
   UIS.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1 then
         dragging = false
      end
   end)
   UIS.InputChanged:Connect(function(input)
      if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
         local d = input.Position - dragStart
         menu.Position = UDim2.new(0, startPos.X.Offset + d.X, 0, startPos.Y.Offset + d.Y)
         syncContent()
      end
   end)

   -- ===== EXPAND / COLLAPSE =====
   local expanded = false
   local function setExpanded(v)
      expanded = v
      TweenService:Create(menu, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {
         Size = UDim2.new(0, MENU_W, 0, v and FULL_H or HEADER_H)
      }):Play()
      TweenService:Create(plus, TweenInfo.new(0.25), { Rotation = v and 45 or 0 }):Play()
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
      row.BorderSizePixel = 0
      row.AutoButtonColor = false
      row.Text = "  " .. label
      row.TextColor3 = TEXT
      row.TextXAlignment = Enum.TextXAlignment.Left
      row.Font = Enum.Font.Gotham
      row.TextSize = 13
      row.Parent = page
      round(row, 5)

      local box = Instance.new("Frame")
      box.Size = UDim2.new(0, 14, 0, 14)
      box.Position = UDim2.new(1, -24, 0.5, -7)
      box.BackgroundColor3 = OFF
      box.BorderSizePixel = 0
      box.Parent = row
      round(box, 3)

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
      txt.Text = label .. ": " .. tostring(default)
      txt.TextColor3 = TEXT
      txt.TextXAlignment = Enum.TextXAlignment.Left
      txt.Font = Enum.Font.Gotham
      txt.TextSize = 12
      txt.Parent = holder

      local bar = Instance.new("TextButton")
      bar.Size = UDim2.new(1, 0, 0, 8)
      bar.Position = UDim2.new(0, 0, 0, 22)
      bar.BackgroundColor3 = BG2
      bar.BorderSizePixel = 0
      bar.AutoButtonColor = false
      bar.Text = ""
      bar.Parent = holder
      round(bar, 4)

      local fill = Instance.new("Frame")
      fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
      fill.BackgroundColor3 = ACCENT
      fill.BorderSizePixel = 0
      fill.Parent = bar
      round(fill, 4)

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
            update(i.Position.X)
         end
      end)
      UIS.InputEnded:Connect(function(i)
         if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
      end)
      UIS.InputChanged:Connect(function(i)
         if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i.Position.X)
         end
      end)
   end

   -- ===== TABS + PAGES =====
   local pages = {}
   for i, name in ipairs(TABS) do
      local btn = Instance.new("TextButton")
      btn.Size = UDim2.new(1, -8, 0, TAB_H)
      btn.BackgroundColor3 = BG2
      btn.BackgroundTransparency = 1
      btn.BorderSizePixel = 0
      btn.AutoButtonColor = false
      btn.Text = "     " .. name:lower()
      btn.TextColor3 = DIM
      btn.TextXAlignment = Enum.TextXAlignment.Left
      btn.Font = Enum.Font.Gotham
      btn.TextSize = 13
      btn.LayoutOrder = i
      btn.Parent = list
      round(btn, 5)

      local page = Instance.new("Frame")
      page.Size = UDim2.new(1, 0, 1, 0)
      page.BackgroundTransparency = 1
      page.Visible = false
      page.Parent = content
      pages[name] = page

      local title = Instance.new("TextLabel")
      title.Size = UDim2.new(1, -16, 0, 26)
      title.Position = UDim2.new(0, 8, 0, 4)
      title.BackgroundTransparency = 1
      title.Text = name:lower()
      title.TextColor3 = ACCENT
      title.TextXAlignment = Enum.TextXAlignment.Left
      title.Font = Enum.Font.GothamBold
      title.TextSize = 13
      title.Parent = page

      -- placeholder controls, rename or replace these
      addToggle(page, "Option 1", name .. "_opt1", 36)
      addToggle(page, "Option 2", name .. "_opt2", 68)
      addSlider(page, "Value", name .. "_value", 0, 100, 50, 106)

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
         for n, p in pairs(pages) do p.Visible = (n == name) end
      end)
   end

   -- ===== FREE THE CURSOR WHILE MENU IS OPEN =====
   local menuOpen = true
   RunService.RenderStepped:Connect(function()
      if menuOpen then
         UIS.MouseBehavior = Enum.MouseBehavior.Default
         UIS.MouseIconEnabled = true
      end
   end)

   -- ===== INSERT = SHOW/HIDE =====
   UIS.InputBegan:Connect(function(input, gpe)
      if gpe then return end
      if input.KeyCode == Enum.KeyCode.Insert then
         menuOpen = not menuOpen
         gui.Enabled = menuOpen
      end
   end)

   print("fatality loaded | parent:", gui.Parent:GetFullName())
end

local ok, err = pcall(build)
if not ok then
   warn("fatality error: " .. tostring(err))
end
