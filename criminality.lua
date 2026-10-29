--!nocheck
-- fatality v2
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer

local function build()
    local playerGui = player:WaitForChild("PlayerGui")

    local ACCENT = Color3.fromRGB(200, 55, 55)
    local BG = Color3.fromRGB(15, 15, 18)
    local BG2 = Color3.fromRGB(24, 24, 29)
    local RAIL = Color3.fromRGB(11, 11, 14)
    local TEXT = Color3.fromRGB(220, 220, 225)
    local DIM = Color3.fromRGB(150, 150, 158)
    local OFF = Color3.fromRGB(45, 45, 52)
    local LINE = Color3.fromRGB(50, 50, 58)

    local PANEL_W, PANEL_H, HEADER_H, RAIL_W = 430, 270, 36, 104
    local BODY_H = PANEL_H - HEADER_H
    local TABS = { "Legit", "Rage", "Visuals", "Misc" }

    local PRESETS = {
        Color3.fromRGB(200, 55, 55),
        Color3.fromRGB(70, 130, 230),
        Color3.fromRGB(80, 200, 120),
        Color3.fromRGB(170, 90, 230),
        Color3.fromRGB(240, 170, 50),
    }

    local config, accentRefs = {}, {}
    local accentIndex = 1

    for _, n in ipairs({ "fatality", "fatality_wm" }) do
        local old = playerGui:FindFirstChild(n)
        if old then old:Destroy() end
    end

    local function round(o, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = o
    end

    local function outline(o, col)
        local s = Instance.new("UIStroke")
        s.Color = col or LINE
        s.Thickness = 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = o
    end

    local function vp()
        local cam = workspace.CurrentCamera
        local v = cam and cam.ViewportSize or Vector2.new(0, 0)
        if v.X < 1 or v.Y < 1 then v = playerGui.AbsoluteSize end
        if v.X < 1 or v.Y < 1 then v = Vector2.new(1280, 720) end
        return v
    end

    local function insetY()
        local tl = GuiService:GetGuiInset()
        return tl and tl.Y or 36
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "fatality"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = playerGui

    -- ===== PANEL =====
    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
    panel.BackgroundColor3 = BG
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Active = true
    panel.Parent = gui
    round(panel, 8)
    outline(panel)

    local function place(x, y)
        local v = vp()
        local ins = insetY()
        local h = expanded and PANEL_H or HEADER_H
        panel.Position = UDim2.new(
            0, math.clamp(x, 8, math.max(8, v.X - PANEL_W - 8)),
            0, math.clamp(y, ins + 8, math.max(ins + 8, v.Y - h - 8))
        )
    end

    -- ===== HEADER =====
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundTransparency = 1
    header.Active = true
    header.Parent = panel

    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(0, 3, 0, HEADER_H - 12)
    accentLine.Position = UDim2.new(0, 0, 0, 6)
    accentLine.BackgroundColor3 = ACCENT
    accentLine.BorderSizePixel = 0
    accentLine.Parent = header
    round(accentLine, 2)
    table.insert(accentRefs, function() accentLine.BackgroundColor3 = ACCENT end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.fromOffset(14, 0)
    title.BackgroundTransparency = 1
    title.Text = "fatality"
    title.TextColor3 = TEXT
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.Parent = header

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.fromOffset(26, 22)
    minBtn.Position = UDim2.new(1, -34, 0, 7)
    minBtn.BackgroundColor3 = BG2
    minBtn.AutoButtonColor = false
    minBtn.Text = "-"
    minBtn.TextColor3 = TEXT
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    minBtn.ZIndex = 3
    minBtn.Parent = header
    round(minBtn, 4)

    local hr = Instance.new("Frame")
    hr.Size = UDim2.new(1, 0, 0, 1)
    hr.Position = UDim2.new(0, 0, 0, HEADER_H)
    hr.BackgroundColor3 = LINE
    hr.BorderSizePixel = 0
    hr.Parent = panel

    -- ===== BODY =====
    local body = Instance.new("Frame")
    body.Size = UDim2.new(1, 0, 0, BODY_H)
    body.Position = UDim2.new(0, 0, 0, HEADER_H + 1)
    body.BackgroundTransparency = 1
    body.Parent = panel

    local rail = Instance.new("Frame")
    rail.Size = UDim2.new(0, RAIL_W, 1, 0)
    rail.BackgroundColor3 = RAIL
    rail.BorderSizePixel = 0
    rail.Parent = body

    local railLayout = Instance.new("UIListLayout")
    railLayout.Padding = UDim.new(0, 1)
    railLayout.Parent = rail

    local railPad = Instance.new("UIPadding")
    railPad.PaddingTop = UDim.new(0, 8)
    railPad.Parent = rail

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -RAIL_W, 1, 0)
    content.Position = UDim2.fromOffset(RAIL_W, 0)
    content.BackgroundTransparency = 1
    content.Parent = body

    local contentPad = Instance.new("UIPadding")
    contentPad.PaddingTop = UDim.new(0, 10)
    contentPad.PaddingLeft = UDim.new(0, 10)
    contentPad.PaddingRight = UDim.new(0, 10)
    contentPad.PaddingBottom = UDim.new(0, 10)
    contentPad.Parent = content

    -- ===== CONTROLS =====
    local function addLabel(page, text, dim)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, dim and 15 or 18)
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
        d.BackgroundColor3 = LINE
        d.BorderSizePixel = 0
        d.Parent = page
    end

    local function addToggle(page, label, default, onChange)
        local state = default and true or false
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = BG2
        row.BorderSizePixel = 0
        row.Parent = page
        round(row, 5)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -54, 1, 0)
        lbl.Position = UDim2.fromOffset(10, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = TEXT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(32, 17)
        btn.Position = UDim2.new(1, -42, 0.5, -8)
        btn.BackgroundColor3 = state and ACCENT or OFF
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = row
        round(btn, 9)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(13, 13)
        knob.Position = UDim2.new(0, state and 17 or 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
        knob.Parent = btn
        round(knob, 7)

        local function paint()
            config[label] = state
            btn.BackgroundColor3 = state and ACCENT or OFF
            TweenService:Create(knob, TweenInfo.new(0.1), {
                Position = UDim2.new(0, state and 17 or 2, 0.5, -6),
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
        row.Size = UDim2.new(1, 0, 0, 42)
        row.BackgroundColor3 = BG2
        row.BorderSizePixel = 0
        row.Parent = page
        round(row, 5)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 0, 17)
        lbl.Position = UDim2.fromOffset(10, 4)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = TEXT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.Parent = row

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 40, 0, 17)
        val.Position = UDim2.new(1, -50, 0, 4)
        val.BackgroundTransparency = 1
        val.Text = tostring(value)
        val.TextColor3 = DIM
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Font = Enum.Font.GothamMedium
        val.TextSize = 11
        val.Parent = row

        local bar = Instance.new("TextButton")
        bar.Size = UDim2.new(1, -20, 0, 5)
        bar.Position = UDim2.fromOffset(10, 28)
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

        local function apply(a)
            value = math.floor(min + (max - min) * a + 0.5)
            fill.Size = UDim2.new(a, 0, 1, 0)
            val.Text = tostring(value)
            config[label] = value
            if onChange then task.spawn(onChange, value) end
        end

        local moveConn, upConn
        bar.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1
                and i.UserInputType ~= Enum.UserInputType.Touch then return end
            if moveConn then moveConn:Disconnect() end
            if upConn then upConn:Disconnect() end

            local function set(p)
                apply(math.clamp((p.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1))
            end
            set(i.Position)

            moveConn = UIS.InputChanged:Connect(function(m)
                if m.UserInputType == Enum.UserInputType.MouseMovement
                    or m.UserInputType == Enum.UserInputType.Touch then set(m.Position) end
            end)
            upConn = UIS.InputEnded:Connect(function(m)
                if m.UserInputType ~= Enum.UserInputType.MouseButton1
                    and m.UserInputType ~= Enum.UserInputType.Touch then return end
                if moveConn then moveConn:Disconnect() end
                if upConn then upConn:Disconnect() end
                moveConn, upConn = nil, nil
            end)
        end)

        config[label] = value
        return {
            Get = function() return value end,
            Set = function(v) apply(math.clamp((v - min) / (max - min), 0, 1)) end,
        }
    end

    local function addButton(page, label, onClick)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 26)
        b.BackgroundColor3 = BG2
        b.AutoButtonColor = false
        b.Text = label
        b.TextColor3 = TEXT
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.Parent = page
        round(b, 5)
        b.MouseEnter:Connect(function() b.BackgroundColor3 = OFF end)
        b.MouseLeave:Connect(function() b.BackgroundColor3 = BG2 end)
        b.MouseButton1Click:Connect(function() if onClick then task.spawn(onClick) end end)
        return b
    end

    -- ===== TABS =====
    local tabBtns, pages = {}, {}
    local current = 1

    local function selectTab(i)
        current = i
        for idx, b in ipairs(tabBtns) do
            b.TextColor3 = idx == i and TEXT or DIM
            b.BackgroundColor3 = idx == i and BG2 or RAIL
            pages[idx].Visible = idx == i
        end
    end

    for i, name in ipairs(TABS) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = RAIL
        b.AutoButtonColor = false
        b.Text = name
        b.TextColor3 = DIM
        b.TextXAlignment = Enum.TextXAlignment.Left
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.Parent = rail

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 14)
        pad.Parent = b

        b.MouseButton1Click:Connect(function() selectTab(i) end)
        tabBtns[i] = b

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = LINE
        page.ScrollingDirection = Enum.ScrollingDirection.Y
        page.ElasticBehavior = Enum.ElasticBehavior.Never
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = content

        local pl = Instance.new("UIListLayout")
        pl.Padding = UDim.new(0, 5)
        pl.Parent = page

        pages[i] = page
    end

    -- ===== CONTENT =====
    local function hum()
        local c = player.Character
        return c and c:FindFirstChildWhichIsA("Humanoid")
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
    end)

    addLabel(pages[4], "Character", false)
    addSlider(pages[4], "WalkSpeed", 16, 300, 16, function(v)
        local h = hum()
        if h then h.WalkSpeed = v end
    end)
    addSlider(pages[4], "JumpPower", 50, 500, 50, function(v)
        local h = hum()
        if h then h.JumpPower = v end
    end)
    addToggle(pages[4], "Infinite Jump", false, function(on)
        if jumpConn then jumpConn:Disconnect() jumpConn = nil end
        if on then
            jumpConn = UIS.JumpRequest:Connect(function()
                local h = hum()
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end)
    addDivider(pages[4])
    addLabel(pages[4], "Accent", false)

    local swRow = Instance.new("Frame")
    swRow.Size = UDim2.new(1, 0, 0, 24)
    swRow.BackgroundTransparency = 1
    swRow.Parent = pages[4]
    local swL = Instance.new("UIListLayout")
    swL.FillDirection = Enum.FillDirection.Horizontal
    swL.Padding = UDim.new(0, 6)
    swL.Parent = swRow

    local function applyAccent(c)
        ACCENT = c
        for _, f in ipairs(accentRefs) do pcall(f) end
    end

    for i, c in ipairs(PRESETS) do
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.fromOffset(24, 24)
        sw.BackgroundColor3 = c
        sw.Text = ""
        sw.AutoButtonColor = false
        sw.Parent = swRow
        round(sw, 12)
        sw.MouseButton1Click:Connect(function()
            accentIndex = i
            applyAccent(c)
        end)
    end

    addButton(pages[4], "Unload", function() gui:Destroy() end)

    -- ===== WATERMARK =====
    local wm = Instance.new("Frame")
    wm.Name = "fatality_wm"
    wm.Size = UDim2.fromOffset(160, 40)
    wm.Position = UDim2.new(0, 20, 1, -60)
    wm.BackgroundColor3 = BG
    wm.BackgroundTransparency = 0.2
    wm.BorderSizePixel = 0
    wm.Parent = gui
    round(wm, 6)
    outline(wm)

    local wmBar = Instance.new("Frame")
    wmBar.Size = UDim2.new(0, 3, 0, 24)
    wmBar.Position = UDim2.fromOffset(0, 8)
    wmBar.BackgroundColor3 = ACCENT
    wmBar.BorderSizePixel = 0
    wmBar.Parent = wm
    round(wmBar, 2)
    table.insert(accentRefs, function() wmBar.BackgroundColor3 = ACCENT end)

    local wmT = Instance.new("TextLabel")
    wmT.Size = UDim2.new(1, -16, 0, 16)
    wmT.Position = UDim2.fromOffset(12, 4)
    wmT.BackgroundTransparency = 1
    wmT.Text = "fatality"
    wmT.TextColor3 = TEXT
    wmT.TextXAlignment = Enum.TextXAlignment.Left
    wmT.Font = Enum.Font.GothamBold
    wmT.TextSize = 11
    wmT.Parent = wm

    local wmS = Instance.new("TextLabel")
    wmS.Size = UDim2.new(1, -16, 0, 13)
    wmS.Position = UDim2.fromOffset(12, 20)
    wmS.BackgroundTransparency = 1
    wmS.Text = "-- fps"
    wmS.TextColor3 = DIM
    wmS.TextXAlignment = Enum.TextXAlignment.Left
    wmS.Font = Enum.Font.Gotham
    wmS.TextSize = 10
    wmS.Parent = wm

    local fCount, fTime = 0, 0
    RunService.RenderStepped:Connect(function(dt)
        if not gui.Parent then return end
        fCount, fTime = fCount + 1, fTime + dt
        if fTime >= 0.5 then
            wmS.Text = string.format("%d fps", math.floor(fCount / fTime + 0.5))
            fCount, fTime = 0, 0
        end
    end)

    -- ===== DRAG =====
    local moveConn, upConn

    local function isPress(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end

    header.InputBegan:Connect(function(i)
        if not isPress(i) then return end
        if moveConn then moveConn:Disconnect() end
        if upConn then upConn:Disconnect() end

        local origin = i.Position
        local sx, sy = panel.Position.X.Offset, panel.Position.Y.Offset

        moveConn = UIS.InputChanged:Connect(function(m)
            if m.UserInputType == Enum.UserInputType.MouseMovement
                or m.UserInputType == Enum.UserInputType.Touch then
                place(sx + (m.Position.X - origin.X), sy + (m.Position.Y - origin.Y))
            end
        end)
        upConn = UIS.InputEnded:Connect(function(m)
            if not isPress(m) then return end
            if moveConn then moveConn:Disconnect() end
            if upConn then upConn:Disconnect() end
            moveConn, upConn = nil, nil
        end)
    end)

    -- ===== MINIMIZE =====
    local expanded = true

    local function setExpanded(v)
        expanded = v
        minBtn.Text = expanded and "-" or "+"
        body.Visible = expanded
        hr.Visible = expanded
        TweenService:Create(panel, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(PANEL_W, expanded and PANEL_H or HEADER_H),
        }):Play()
        place(panel.Position.X.Offset, panel.Position.Y.Offset)
    end

    minBtn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

    -- ===== KEYS =====
    UIS.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.K then
            gui.Enabled = not gui.Enabled
        elseif i.KeyCode == Enum.KeyCode.RightShift then
            place(60, 180)
        end
    end)

    -- ===== START =====
    place(60, 180)
    task.spawn(function()
        for _ = 1, 60 do
            local v = vp()
            if v.X > 1 and v.Y > 1 then
                place(60, 180)
                break
            end
            task.wait(0.1)
        end
    end)
    selectTab(1)
end

build()
