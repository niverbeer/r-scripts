--!nocheck
-- fatality UI framework
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer

local function build()
    local playerGui = (gethui and gethui()) or player:WaitForChild("PlayerGui")

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
    local GAP = 8

    local ACCENT_PRESETS = {
        Color3.fromRGB(200, 55, 55),
        Color3.fromRGB(70, 130, 230),
        Color3.fromRGB(80, 200, 120),
        Color3.fromRGB(170, 90, 230),
        Color3.fromRGB(240, 170, 50),
    }
    local accentIndex = 1
    local config = {}
    local accentRefs = {}

    for _, n in ipairs({ "fatality", "fatality_wm" }) do
        local old = playerGui:FindFirstChild(n)
        if old then old:Destroy() end
    end

    -- ===== HELPERS =====
    local function round(obj, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = obj
    end

    local function stroke(obj)
        local s = Instance.new("UIStroke")
        s.Color = STROKE
        s.Thickness = 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = obj
    end

    local function viewport()
        local cam = workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920, 1080)
    end

    -- ===== ROOT =====
    local gui = Instance.new("ScreenGui")
    gui.Name = "fatality"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = playerGui

    -- ===== MENU =====
    local menu = Instance.new("Frame")
    menu.Name = "menu"
    menu.Size = UDim2.new(0, MENU_W, 0, HEADER_H)
    menu.BackgroundColor3 = BG
    menu.BorderSizePixel = 0
    menu.ClipsDescendants = true
    menu.Active = true
    menu.Parent = gui
    round(menu, 8)
    stroke(menu)

    local header = Instance.new("TextButton")
    header.Size = UDim2.new(1, -HEADER_H, 0, HEADER_H)
    header.BackgroundTransparency = 1
    header.AutoButtonColor = false
    header.Text = "fatality"
    header.TextColor3 = TEXT
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Font = Enum.Font.GothamBold
    header.TextSize = 14
    header.Parent = menu

    local headerPad = Instance.new("UIPadding")
    headerPad.PaddingLeft = UDim.new(0, 12)
    headerPad.Parent = header

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
    content.Active = true
    content.Parent = gui
    round(content, 8)
    stroke(content)

    local contentPad = Instance.new("UIPadding")
    contentPad.PaddingTop = UDim.new(0, 10)
    contentPad.PaddingLeft = UDim.new(0, 10)
    contentPad.PaddingRight = UDim.new(0, 10)
    contentPad.PaddingBottom = UDim.new(0, 10)
    contentPad.Parent = content

    local function syncContent()
        local vp = viewport()
        local x, y = menu.Position.X.Offset, menu.Position.Y.Offset
        if x + MENU_W + GAP + CONTENT_W <= vp.X then
            content.Position = UDim2.new(0, x + MENU_W + GAP, 0, y)
        else
            content.Position = UDim2.new(0, x, 0, y + HEADER_H + 4)
        end
    end

    local function placeMenu(x, y)
        local vp = viewport()
        menu.Position = UDim2.new(
            0, math.clamp(x, 0, math.max(0, vp.X - MENU_W)),
            0, math.clamp(y, 0, math.max(0, vp.Y - FULL_H))
        )
        syncContent()
    end

    -- ===== CONTROLS =====
    local function addLabel(page, text, dim)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, dim and 16 or 20)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = dim and DIM or TEXT
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Font = dim and Enum.Font.Gotham or Enum.Font.GothamBold
        l.TextSize = dim and 11 or 12
        l.Parent = page
        return l
    end

    local function addDivider(page)
        local d = Instance.new("Frame")
        d.Size = UDim2.new(1, 0, 0, 1)
        d.BackgroundColor3 = STROKE
        d.BorderSizePixel = 0
        d.Parent = page
    end

    local function addToggle(page, label, default, onChange)
        local state = default and true or false
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = BG2
        row.BorderSizePixel = 0
        row.Parent = page
        round(row, 5)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -54, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = TEXT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(34, 18)
        btn.Position = UDim2.new(1, -44, 0.5, -9)
        btn.BackgroundColor3 = state and ACCENT or OFF
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = row
        round(btn, 9)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(14, 14)
        knob.Position = UDim2.new(0, state and 18 or 2, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
        knob.Parent = btn
        round(knob, 7)

        local function paint()
            config[label] = state
            btn.BackgroundColor3 = state and ACCENT or OFF
            TweenService:Create(knob, TweenInfo.new(0.12), {
                Position = UDim2.new(0, state and 18 or 2, 0.5, -7),
            }):Play()
            if onChange then task.spawn(onChange, state) end
        end

        table.insert(accentRefs, function()
            btn.BackgroundColor3 = state and ACCENT or OFF
        end)

        btn.MouseButton1Click:Connect(function()
            state = not state
            paint()
        end)

        config[label] = state
        return {
            Get = function() return state end,
            Set = function(v) state = v and true or false; paint() end,
        }
    end

    local function addSlider(page, label, min, max, default, onChange)
        local value = math.clamp(default, min, max)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundColor3 = BG2
        row.BorderSizePixel = 0
        row.Parent = page
        round(row, 5)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 0, 18)
        lbl.Position = UDim2.new(0, 10, 0, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = TEXT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.Parent = row

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 40, 0, 18)
        val.Position = UDim2.new(1, -50, 0, 4)
        val.BackgroundTransparency = 1
        val.Text = tostring(value)
        val.TextColor3 = DIM
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Font = Enum.Font.GothamMedium
        val.TextSize = 11
        val.Parent = row

        local bar = Instance.new("TextButton")
        bar.Size = UDim2.new(1, -20, 0, 6)
        bar.Position = UDim2.new(0, 10, 0, 30)
        bar.BackgroundColor3 = OFF
        bar.Text = ""
        bar.AutoButtonColor = false
        bar.Parent = row
        round(bar, 3)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = ACCENT
        fill.BorderSizePixel = 0
        fill.Parent = bar
        round(fill, 3)

        table.insert(accentRefs, function() fill.BackgroundColor3 = ACCENT end)

        local function apply(alpha)
            value = math.floor(min + (max - min) * alpha + 0.5)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            val.Text = tostring(value)
            config[label] = value
            if onChange then task.spawn(onChange, value) end
        end

        local dragConn, endConn
        local function begin(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
            if dragConn then dragConn:Disconnect() end
            if endConn then endConn:Disconnect() end

            local function set(pos)
                apply(math.clamp((pos.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1))
            end
            set(input.Position)

            dragConn = UIS.InputChanged:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseMovement
                    or m.UserInputType == Enum.UserInputType.Touch then
                    set(m.Position)
                end
            end)
            endConn = UIS.InputEnded:Connect(function(m)
                if m.UserInputType ~= Enum.UserInputType.MouseButton1
                    and m.UserInputType ~= Enum.UserInputType.Touch then return end
                if dragConn then dragConn:Disconnect() end
                if endConn then endConn:Disconnect() end
                dragConn, endConn = nil, nil
            end)
        end

        bar.InputBegan:Connect(begin)

        config[label] = value
        return {
            Get = function() return value end,
            Set = function(v)
                apply(math.clamp((v - min) / (max - min), 0, 1))
            end,
        }
    end

    local function addButton(page, label, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = BG2
        btn.AutoButtonColor = false
        btn.Text = label
        btn.TextColor3 = TEXT
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.Parent = page
        round(btn, 5)

        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = OFF end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = BG2 end)
        btn.MouseButton1Click:Connect(function()
            if onClick then task.spawn(onClick) end
        end)
        return btn
    end

    -- ===== TABS + PAGES =====
    local tabButtons, pages = {}, {}
    local activeTab = 1

    local function selectTab(i)
        activeTab = i
        for idx, b in ipairs(tabButtons) do
            b.paint(idx == i)
            pages[idx].Visible = (idx == i)
        end
    end

    for i, name in ipairs(TABS) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -12, 0, TAB_H)
        btn.Position = UDim2.new(0, 12, 0, 0)
        btn.BackgroundTransparency = 1
        btn.AutoButtonColor = false
        btn.Text = name
        btn.TextColor3 = DIM
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.Parent = list

        local ind = Instance.new("Frame")
        ind.Size = UDim2.new(0, 2, 0, TAB_H - 14)
        ind.Position = UDim2.new(0, -12, 0, 7)
        ind.BackgroundColor3 = ACCENT
        ind.BorderSizePixel = 0
        ind.Visible = false
        ind.Parent = btn
        round(ind, 1)

        table.insert(accentRefs, function() ind.BackgroundColor3 = ACCENT end)

        function btn.paint(active)
            btn.TextColor3 = active and TEXT or DIM
            ind.Visible = active
        end

        btn.MouseButton1Click:Connect(function() selectTab(i) end)
        tabButtons[i] = btn

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = STROKE
        page.ScrollingDirection = Enum.ScrollingDirection.Y
        page.ElasticBehavior = Enum.ElasticBehavior.Never
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = content

        local pl = Instance.new("UIListLayout")
        pl.Padding = UDim.new(0, 6)
        pl.Parent = page

        pages[i] = page
    end

    -- ===== PAGE CONTENT =====
    local function humanoid()
        local char = player.Character
        return char and char:FindFirstChildWhichIsA("Humanoid")
    end

    local jumpConn

    addLabel(pages[1], "Combat", false)
    addToggle(pages[1], "Aim Assist", false)
    addSlider(pages[1], "FOV", 20, 400, 120)
    addSlider(pages[1], "Smoothing", 1, 20, 6)
    addToggle(pages[1], "Silent Aim", false)
    addDivider(pages[1])
    addLabel(pages[1], "Trigger", false)
    addToggle(pages[1], "Trigger Bot", false)
    addSlider(pages[1], "Trigger Delay", 0, 300, 60)

    addLabel(pages[2], "Aimbot", false)
    addToggle(pages[2], "Enabled", false)
    addToggle(pages[2], "Visible Check", true)
    addSlider(pages[2], "Hitbox Scale", 1, 10, 2)
    addDivider(pages[2])
    addLabel(pages[2], "Target", false)
    addButton(pages[2], "Closest to Crosshair")
    addButton(pages[2], "Closest to Player")

    addLabel(pages[3], "ESP", false)
    addToggle(pages[3], "Boxes", false)
    addToggle(pages[3], "Names", false)
    addToggle(pages[3], "Health Bars", false)
    addSlider(pages[3], "Render Distance", 50, 2000, 500)
    addDivider(pages[3])
    addToggle(pages[3], "Fullbright", false, function(on)
        local lighting = game:GetService("Lighting")
        lighting.Brightness = on and 3 or 2
        lighting.ClockTime = on and 14 or lighting.ClockTime
    end)

    addLabel(pages[4], "Character", false)
    addSlider(pages[4], "WalkSpeed", 16, 300, 16, function(v)
        local h = humanoid()
        if h then h.WalkSpeed = v end
    end)
    addSlider(pages[4], "JumpPower", 50, 500, 50, function(v)
        local h = humanoid()
        if h then h.JumpPower = v end
    end)
    addToggle(pages[4], "Infinite Jump", false, function(on)
        if jumpConn then jumpConn:Disconnect() jumpConn = nil end
        if on then
            jumpConn = UIS.JumpRequest:Connect(function()
                local h = humanoid()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end)
    addDivider(pages[4], "Accent", false)
    addLabel(pages[4], "Accent", false)

    local swatchRow = Instance.new("Frame")
    swatchRow.Size = UDim2.new(1, 0, 0, 26)
    swatchRow.BackgroundTransparency = 1
    swatchRow.Parent = pages[4]
    local swatchLayout = Instance.new("UIListLayout")
    swatchLayout.FillDirection = Enum.FillDirection.Horizontal
    swatchLayout.Padding = UDim.new(0, 6)
    swatchLayout.Parent = swatchRow

    local function applyAccent(c)
        ACCENT = c
        for _, f in ipairs(accentRefs) do pcall(f) end
    end

    for i, c in ipairs(ACCENT_PRESETS) do
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.fromOffset(26, 26)
        sw.BackgroundColor3 = c
        sw.Text = ""
        sw.AutoButtonColor = false
        sw.Parent = swatchRow
        round(sw, 13)
        sw.MouseButton1Click:Connect(function()
            accentIndex = i
            applyAccent(c)
        end)
    end

    addButton(pages[4], "Unload", function()
        gui:Destroy()
    end)

    -- ===== WATERMARK =====
    local wm = Instance.new("Frame")
    wm.Name = "fatality_wm"
    wm.Size = UDim2.new(0, 168, 0, 42)
    wm.Position = UDim2.new(0, 20, 1, -62)
    wm.BackgroundColor3 = BG
    wm.BackgroundTransparency = 0.15
    wm.BorderSizePixel = 0
    wm.Parent = gui
    round(wm, 6)
    stroke(wm)

    local wmBar = Instance.new("Frame")
    wmBar.Size = UDim2.new(0, 3, 0, 26)
    wmBar.Position = UDim2.new(0, 0, 0, 8)
    wmBar.BackgroundColor3 = ACCENT
    wmBar.BorderSizePixel = 0
    wmBar.Parent = wm
    round(wmBar, 2)
    table.insert(accentRefs, function() wmBar.BackgroundColor3 = ACCENT end)

    local wmTitle = Instance.new("TextLabel")
    wmTitle.Size = UDim2.new(1, -16, 0, 18)
    wmTitle.Position = UDim2.new(0, 12, 0, 5)
    wmTitle.BackgroundTransparency = 1
    wmTitle.Text = "fatality"
    wmTitle.TextColor3 = TEXT
    wmTitle.TextXAlignment = Enum.TextXAlignment.Left
    wmTitle.Font = Enum.Font.GothamBold
    wmTitle.TextSize = 12
    wmTitle.Parent = wm

    local wmStats = Instance.new("TextLabel")
    wmStats.Size = UDim2.new(1, -16, 0, 14)
    wmStats.Position = UDim2.new(0, 12, 0, 22)
    wmStats.BackgroundTransparency = 1
    wmStats.Text = "-- fps  |  0s"
    wmStats.TextColor3 = DIM
    wmStats.TextXAlignment = Enum.TextXAlignment.Left
    wmStats.Font = Enum.Font.Gotham
    wmStats.TextSize = 10
    wmStats.Parent = wm

    local frames, elapsed, started = 0, 0, os.clock()
    RunService.RenderStepped:Connect(function(dt)
        if not gui.Parent then return end
        frames = frames + 1
        elapsed = elapsed + dt
        if elapsed >= 0.5 then
            wmStats.Text = ("%d fps  |  %ds"):format(
                math.floor(frames / elapsed + 0.5),
                math.floor(os.clock() - started)
            )
            frames, elapsed = 0, 0
        end
    end)

    -- ===== DRAGGING =====
    local dragConn, endConn

    local function isDragInput(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end

    header.InputBegan:Connect(function(input)
        if not isDragInput(input) then return end
        if dragConn then dragConn:Disconnect() end
        if endConn then endConn:Disconnect() end

        local dragStart = input.Position
        local startX = menu.Position.X.Offset
        local startY = menu.Position.Y.Offset

        local function move(pos)
            placeMenu(startX + (pos.X - dragStart.X), startY + (pos.Y - dragStart.Y))
        end

        dragConn = UIS.InputChanged:Connect(function(m)
            if m.UserInputType == Enum.UserInputType.MouseMovement
                or m.UserInputType == Enum.UserInputType.Touch then
                move(m.Position)
            end
        end)
        endConn = UIS.InputEnded:Connect(function(m)
            if not isDragInput(m) then return end
            if dragConn then dragConn:Disconnect() end
            if endConn then endConn:Disconnect() end
            dragConn, endConn = nil, nil
        end)
    end)

    -- ===== EXPAND =====
    local expanded = false

    local function setExpanded(v)
        expanded = v
        plus.Text = expanded and "−" or "+"
        content.Visible = expanded
        if expanded then syncContent() end
        TweenService:Create(menu, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, MENU_W, 0, expanded and FULL_H or HEADER_H),
        }):Play()
    end

    plus.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

    -- ===== START =====
    placeMenu(60, 200)
    selectTab(1)
end

build()
