--!nocheck
-- fatality v3 + ESP Integration
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer

-- Global ESP Control Variables
local _G = getgenv and getgenv() or _G
_G.ESP_Active = false
local connections = {}

-- Внутренняя функция для очистки конкретного игрока от ESP
local function removeHighlight(p)
    if p.Character then
        local hl = p.Character:FindFirstChild("ESP_Highlight")
        if hl then hl:Destroy() end
    end
end

-- Внутренняя функция применения ESP к персонажу
local function setupHighlight(character)
    if not _G.ESP_Active then return end
    character:WaitForChild("HumanoidRootPart", 10)
    
    if not character:FindFirstChild("ESP_Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.FillColor = Color3.fromRGB(200, 55, 55) -- Под цвет интерфейса (ACCENT)
        highlight.FillOpacity = 0.5
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineOpacity = 1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character
    end
end

-- Логика управления ESP (Вкл / Выкл)
local function toggleESP(state)
    _G.ESP_Active = state
    
    if state then
        -- Функция обработки игрока
        local function applyESP(p)
            if p == player then return end
            if p.Character then task.spawn(setupHighlight, p.Character) end
            local conn = p.CharacterAdded:Connect(setupHighlight)
            table.insert(connections, conn)
        end

        -- Включаем для текущих игроков
        for _, p in ipairs(Players:GetPlayers()) do
            applyESP(p)
        end

        -- Слушаем новых игроков
        local joinConn = Players.PlayerAdded:Connect(applyESP)
        table.insert(connections, joinConn)
    else
        -- Отключаем все слушатели событий
        for _, conn in ipairs(connections) do
            if conn then conn:Disconnect() end
        end
        connections = {}

        -- Удаляем визуальные эффекты со всех игроков в зоне видимости
        for _, p in ipairs(Players:GetPlayers()) do
            removeHighlight(p)
        end
    end
end

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

    local config, accentRefs = {}, {}
    local expanded = true

    for _, n in ipairs({ "fatality", "fatality_wm", "fatality_test" }) do
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

    local function screenBounds()
        local cam = workspace.CurrentCamera
        local v = cam and cam.ViewportSize
        if not v or v.X < 1 or v.Y < 1 then
            local ok, res = pcall(function() return GuiService:GetScreenResolution() end)
            if ok and res and res.X > 1 and res.Y > 1 then v = res end
        end
        return v
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "fatality"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 999
    gui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
    panel.Position = UDim2.fromScale(0.03, 0.12)
    panel.BackgroundColor3 = BG
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Active = true
    panel.Parent = gui
    round(panel, 8)
    outline(panel)

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
    accentLine.Parent = header
    round(accentLine, 2)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -110, 1, 0)
    title.Position = UDim2.fromOffset(28, 0)
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
    minBtn.Text = "-"
    minBtn.TextColor3 = TEXT
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    minBtn.Parent = header
    round(minBtn, 4)

    local hr = Instance.new("Frame")
    hr.Size = UDim2.new(1, 0, 0, 1)
    hr.Position = UDim2.new(0, 0, 0, HEADER_H)
    hr.BackgroundColor3 = LINE
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
    rail.Parent = body
    round(rail, 0)

    local railLayout = Instance.new("UIListLayout")
    railLayout.Padding = UDim.new(0, 1)
    railLayout.Parent = rail

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -RAIL_W, 1, 0)
    content.Position = UDim2.fromOffset(RAIL_W, 0)
    content.BackgroundTransparency = 1
    content.Parent = body

    -- Контейнеры для каждой вкладки
    local pages = {}
    for _, tabName in ipairs(TABS) do
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.ScrollBarThickness = 2
        page.Visible = (tabName == "Visuals") -- Делаем вкладку Visuals активной по умолчанию
        page.Parent = content
        
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.Parent = page

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
        pad.Parent = page

        pages[tabName] = page

        -- Создание кнопки вкладки в боковом меню (Rail)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 32)
        tabBtn.BackgroundColor3 = (tabName == "Visuals") and BG2 or Color3.fromRGB(0,0,0)
        tabBtn.BackgroundTransparency = (tabName == "Visuals") and 0 or 1
        tabBtn.Text = tabName
        tabBtn.TextColor3 = (tabName == "Visuals") and TEXT or DIM
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.TextSize = 12
        tabBtn.Parent = rail

        tabBtn.MouseButton1Click:Connect(function()
            for name, p in pairs(pages) do p.Visible = (name == tabName) end
            for _, b in ipairs(rail:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(0,0,0)
                    b.BackgroundTransparency = 1
                    b.TextColor3 = DIM
                end
            end
            tabBtn.BackgroundColor3 = BG2
            tabBtn.BackgroundTransparency = 0
            tabBtn.TextColor3 = TEXT
        end)
    end

    -- ===== CONTROLS BUILDER =====
    local function addToggle(page, label, default, onChange)
        local state = default and true or false
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundColor3 = BG2
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
        btn.Parent = row
        round(btn, 9)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(13, 13)
        knob.Position = UDim2.new(0, state and 17 or 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
        knob.Parent = btn
        round(knob, 7)

        local function paint(animate)
            local targetBg = state and ACCENT or OFF
            local targetKnobPos = state and UDim2.new(0, 17, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)

            if animate then
                TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = targetBg}):Play()
            TweenService:Create(knob, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetKnobPos}):Play()
else
btn.BackgroundColor3 = targetBg
knob.Position = targetKnobPos
end
end
btn.MouseButton1Click:Connect(function()
state = not state
config[label] = state
paint(true)
if onChange then task.spawn(onChange, state) end
end)
paint(false)
return row
end
-- ===== НАПОЛНЕНИЕ ВКЛАДКИ VISUALS =====
-- Добавляем наш интерактивный переключатель ESP во вкладку Visuals!
addToggle(pages["Visuals"], "Player ESP", false, function(enabled)
toggleESP(enabled)
end)
-- Перетаскивание интерфейса мышкой (Drag Logic)
local dragging, dragInput, dragStart, startPos
header.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
dragging = true
dragStart = input.Position
startPos = panel.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then dragging = false end
end)
end
end)
header.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
end)
UIS.InputChanged:Connect(function(input)
if input == dragInput and dragging then
local delta = input.Position - dragStart
panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
end)
-- Сворачивание/Разворачивание (Minimize Logic)
minBtn.MouseButton1Click:Connect(function()
expanded = not expanded
body.Visible = expanded
panel.Size = expanded and UDim2.fromOffset(PANEL_W, PANEL_H) or UDim2.fromOffset(PANEL_W, HEADER_H + 1)
minBtn.Text = expanded and "-" or "+"
end)
-- Переключатель видимости меню по кнопке Insert
UIS.InputBegan:Connect(function(input, gpe)
if not gpe and input.KeyCode == Enum.KeyCode.Insert then
gui.Enabled = not gui.Enabled
end
end)
end
-- Инициализация
task.spawn(build)
