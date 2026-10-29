--!nocheck
-- Fatality-style UI + ESP + Chams + Studio NPC Aim Test
-- LocalScript: StarterPlayer > StarterPlayerScripts

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

----------------------------------------------------------------
-- COLORS
----------------------------------------------------------------

local ACCENT = Color3.fromRGB(200, 55, 55)
local BG = Color3.fromRGB(15, 15, 18)
local BG2 = Color3.fromRGB(24, 24, 29)
local RAIL = Color3.fromRGB(11, 11, 14)
local TEXT = Color3.fromRGB(220, 220, 225)
local DIM = Color3.fromRGB(150, 150, 158)
local OFF = Color3.fromRGB(45, 45, 52)
local LINE = Color3.fromRGB(50, 50, 58)

----------------------------------------------------------------
-- CHAMS
----------------------------------------------------------------

local chamsActive = false
local chamsConns = {}

local function removeHighlight(plr)
    if not plr.Character then return end

    local hl = plr.Character:FindFirstChild("ESP_Highlight")
    if hl then
        hl:Destroy()
    end
end

local function setupHighlight(character)
    if not chamsActive then return end

    if not character:FindFirstChild("HumanoidRootPart") then
        character:WaitForChild("HumanoidRootPart", 10)
    end

    if not chamsActive or not character.Parent then return end

    if not character:FindFirstChild("ESP_Highlight") then
        local hl = Instance.new("Highlight")
        hl.Name = "ESP_Highlight"
        hl.FillColor = ACCENT
        hl.FillTransparency = 0.5
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = character
    end
end

local function toggleChams(state)
    chamsActive = state

    if state then
        local function apply(plr)
            if plr == player then return end

            if plr.Character then
                task.spawn(setupHighlight, plr.Character)
            end

            table.insert(
                chamsConns,
                plr.CharacterAdded:Connect(setupHighlight)
            )
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            apply(plr)
        end

        table.insert(
            chamsConns,
            Players.PlayerAdded:Connect(apply)
        )
    else
        for _, conn in ipairs(chamsConns) do
            conn:Disconnect()
        end

        table.clear(chamsConns)

        for _, plr in ipairs(Players:GetPlayers()) do
            removeHighlight(plr)
        end
    end
end

----------------------------------------------------------------
-- ESP BOXES
----------------------------------------------------------------

local PLAYER_COL = ACCENT
local HP_LOW = Color3.fromRGB(220, 60, 60)
local HP_HIGH = Color3.fromRGB(80, 220, 100)

local MAX_DIST = 1500
local TEXT_INTERVAL = 0.15
local TOP_OFFSET = Vector3.new(0, 2.7, 0)
local BOTTOM_OFFSET = Vector3.new(0, 3.1, 0)

local espState = {
    gui = nil,
    session = 0,
    entities = {},
    conns = {},
}

local lastTextUpdate = 0

local function removeEntry(model)
    local entry = espState.entities[model]

    if entry then
        entry.box:Destroy()
        espState.entities[model] = nil
    end
end

local function createEntry(plr, humanoid, root)
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = espState.gui

    local outline = Instance.new("UIStroke")
    outline.Color = PLAYER_COL
    outline.Thickness = 1.5
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outline.Parent = box

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 60, 0, 14)
    nameLabel.Position = UDim2.new(0, -30, 0, -16)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = plr.Name
    nameLabel.TextColor3 = PLAYER_COL
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.Parent = box

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 60, 0, 12)
    distanceLabel.Position = UDim2.new(0, -30, 1, 2)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = ""
    distanceLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
    distanceLabel.TextStrokeTransparency = 0
    distanceLabel.Font = Enum.Font.GothamMedium
    distanceLabel.TextSize = 11
    distanceLabel.Parent = box

    local hpBackground = Instance.new("Frame")
    hpBackground.Size = UDim2.new(0, 3, 1, 0)
    hpBackground.Position = UDim2.new(0, -6, 0, 0)
    hpBackground.BackgroundColor3 = Color3.new(0, 0, 0)
    hpBackground.BorderSizePixel = 0
    hpBackground.Parent = box

    local hpFill = Instance.new("Frame")
    hpFill.AnchorPoint = Vector2.new(0, 1)
    hpFill.Position = UDim2.new(0, 0, 1, 0)
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = HP_HIGH
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBackground

    return {
        humanoid = humanoid,
        root = root,
        box = box,
        dist = distanceLabel,
        hpFill = hpFill,
        visible = false,
        lastDist = -1,
        lastHp = -1,
    }
end

local function updateESP()
    local camera = workspace.CurrentCamera
    if not camera then return end

    local myChar = player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local origin = myRoot and myRoot.Position or camera.CFrame.Position

    local now = os.clock()
    local doText = now - lastTextUpdate >= TEXT_INTERVAL

    if doText then
        lastTextUpdate = now
    end

    for model, entry in pairs(espState.entities) do
        local root = entry.root
        local humanoid = entry.humanoid

        if not model.Parent or not root.Parent or not humanoid.Parent then
            removeEntry(model)
        else
            local distance = (origin - root.Position).Magnitude
            local show = false

            if humanoid.Health > 0 and distance <= MAX_DIST then
                local top = camera:WorldToViewportPoint(
                    root.Position + TOP_OFFSET
                )

                local bottom = camera:WorldToViewportPoint(
                    root.Position - BOTTOM_OFFSET
                )

                if top.Z > 0 and bottom.Z > 0 then
                    show = true

                    local height = math.floor(
                        math.abs(bottom.Y - top.Y)
                    )

                    local width = math.floor(height * 0.55)
                    local centerX = (top.X + bottom.X) / 2

                    entry.box.Position = UDim2.fromOffset(
                        math.floor(centerX - width / 2),
                        math.floor(top.Y)
                    )

                    entry.box.Size = UDim2.fromOffset(width, height)

                    if doText then
                        local roundedDistance = math.floor(distance)

                        if roundedDistance ~= entry.lastDist then
                            entry.lastDist = roundedDistance
                            entry.dist.Text =
                                "[" .. roundedDistance .. " studs]"
                        end

                        local hp = math.clamp(
                            humanoid.Health /
                                math.max(humanoid.MaxHealth, 1),
                            0,
                            1
                        )

                        local quantizedHp = math.floor(hp * 20)

                        if quantizedHp ~= entry.lastHp then
                            entry.lastHp = quantizedHp
                            entry.hpFill.Size = UDim2.new(1, 0, hp, 0)
                            entry.hpFill.BackgroundColor3 =
                                HP_LOW:Lerp(HP_HIGH, hp)
                        end
                    end
                end
            end

            if show ~= entry.visible then
                entry.visible = show
                entry.box.Visible = show
            end
        end
    end
end

local function trackPlayer(plr, session)
    if plr == player then return end

    local function onCharacter(character)
        task.spawn(function()
            local humanoid = character:WaitForChild("Humanoid", 10)
            local root = character:WaitForChild("HumanoidRootPart", 10)

            if session ~= espState.session or not espState.gui then
                return
            end

            if not humanoid or not root or not character.Parent then
                return
            end

            removeEntry(character)

            espState.entities[character] =
                createEntry(plr, humanoid, root)
        end)
    end

    if plr.Character then
        onCharacter(plr.Character)
    end

    table.insert(
        espState.conns,
        plr.CharacterAdded:Connect(onCharacter)
    )

    table.insert(
        espState.conns,
        plr.CharacterRemoving:Connect(removeEntry)
    )
end

local function esp(state)
    if state then
        if espState.gui then return end

        espState.session += 1
        local session = espState.session

        local gui = Instance.new("ScreenGui")
        gui.Name = "fatality_esp"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.DisplayOrder = 998
        gui.Parent = playerGui

        espState.gui = gui

        for _, plr in ipairs(Players:GetPlayers()) do
            trackPlayer(plr, session)
        end

        table.insert(
            espState.conns,
            Players.PlayerAdded:Connect(function(plr)
                trackPlayer(plr, session)
            end)
        )

        table.insert(
            espState.conns,
            RunService.RenderStepped:Connect(updateESP)
        )
    else
        espState.session += 1

        for _, conn in ipairs(espState.conns) do
            conn:Disconnect()
        end

        table.clear(espState.conns)
        table.clear(espState.entities)

        if espState.gui then
            espState.gui:Destroy()
            espState.gui = nil
        end
    end
end

----------------------------------------------------------------
-- PLAYER AIM ASSIST
-- Intended for your own Roblox game's combat system.
-- Uses players who are valid targets in that game.
----------------------------------------------------------------

local AimTest = {
    Enabled = false,
    FOV = 80,
    Smoothness = 4,
    KeyCode = Enum.KeyCode.Q,
    WaitingForKey = false,
    TargetPart = "Head",
}

local aiming = false
local aimKeyChangedCallback

local aimGui = Instance.new("ScreenGui")
aimGui.Name = "AimTestFOV"
aimGui.ResetOnSpawn = false
aimGui.IgnoreGuiInset = true
aimGui.DisplayOrder = 997
aimGui.Parent = playerGui

local circle = Instance.new("Frame")
circle.Name = "FOVCircle"
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Position = UDim2.fromScale(0.5, 0.5)
circle.Size = UDim2.fromOffset(
    AimTest.FOV * 2,
    AimTest.FOV * 2
)
circle.BackgroundTransparency = 1
circle.Visible = false
circle.Parent = aimGui

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circle

local circleStroke = Instance.new("UIStroke")
circleStroke.Color = ACCENT
circleStroke.Thickness = 1.5
circleStroke.Transparency = 0.1
circleStroke.Parent = circle

local function getTargetPart(character)
    local part

    if AimTest.TargetPart == "Head" then
        part = character:FindFirstChild("Head")
    elseif AimTest.TargetPart == "Chest" then
        part = character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    elseif AimTest.TargetPart == "Legs" then
        part = character:FindFirstChild("LeftLowerLeg")
            or character:FindFirstChild("Left Leg")
            or character:FindFirstChild("RightLowerLeg")
            or character:FindFirstChild("Right Leg")
    end

    if part and part:IsA("BasePart") then
        return part
    end

    return character:FindFirstChild("HumanoidRootPart")
end

local function getAimTarget()
    local camera = workspace.CurrentCamera
    if not camera then
        return nil
    end

    local center = camera.ViewportSize / 2
    local bestDistance = AimTest.FOV
    local bestTarget = nil

    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer ~= player then
            local character = targetPlayer.Character
            local humanoid = character
                and character:FindFirstChildOfClass("Humanoid")
            local part = character and getTargetPart(character)

            if humanoid and humanoid.Health > 0 and part then
                local screenPos, onScreen =
                    camera:WorldToViewportPoint(part.Position)

                if onScreen and screenPos.Z > 0 then
                    local point = Vector2.new(
                        screenPos.X,
                        screenPos.Y
                    )

                    local distance = (point - center).Magnitude

                    if distance < bestDistance then
                        bestDistance = distance
                        bestTarget = part
                    end
                end
            end
        end
    end

    return bestTarget
end

UIS.InputBegan:Connect(function(input, processed)
    if AimTest.WaitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode ~= Enum.KeyCode.Unknown then

            AimTest.KeyCode = input.KeyCode
            AimTest.WaitingForKey = false

            if aimKeyChangedCallback then
                aimKeyChangedCallback()
            end
        end

        return
    end

    if not processed
        and input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == AimTest.KeyCode then

        aiming = true
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == AimTest.KeyCode then
        aiming = false
    end
end)

RunService.RenderStepped:Connect(function(dt)
    circle.Visible = AimTest.Enabled
    circle.Size = UDim2.fromOffset(
        AimTest.FOV * 2,
        AimTest.FOV * 2
    )

    if not AimTest.Enabled or not aiming then
        return
    end

    local camera = workspace.CurrentCamera
    local target = getAimTarget()

    if camera and target then
       local aimPosition = target.Position + Vector3.new(0, 0.15, 0)

local desired = CFrame.lookAt(
    camera.CFrame.Position,
    aimPosition
)
        local alpha = 1 - math.exp(
            -AimTest.Smoothness * dt
        )

        camera.CFrame = camera.CFrame:Lerp(
            desired,
            math.clamp(alpha, 0, 1)
        )
    end
end)

----------------------------------------------------------------
-- UI
----------------------------------------------------------------

local function build()
    local PANEL_W = 430
    local PANEL_H = 270
    local HEADER_H = 36
    local RAIL_W = 104
    local BODY_H = PANEL_H - HEADER_H

    local TABS = {
        "Legit",
        "Rage",
        "Visuals",
        "Misc",
        "Credits",
    }

    local config = {}
    local expanded = true

    for _, name in ipairs({
        "fatality",
        "fatality_wm",
        "fatality_test",
    }) do
        local old = playerGui:FindFirstChild(name)

        if old then
            old:Destroy()
        end
    end

    local function round(object, radius)
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, radius)
        corner.Parent = object
    end

    local function outline(object, color)
        local stroke = Instance.new("UIStroke")
        stroke.Color = color or LINE
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = object
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

    ------------------------------------------------------------
    -- HEADER
    ------------------------------------------------------------

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
    minBtn.BorderSizePixel = 0
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
    hr.BorderSizePixel = 0
    hr.Parent = panel

    ------------------------------------------------------------
    -- BODY
    ------------------------------------------------------------

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

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -RAIL_W, 1, 0)
    content.Position = UDim2.fromOffset(RAIL_W, 0)
    content.BackgroundTransparency = 1
    content.Parent = body

    ------------------------------------------------------------
    -- TABS
    ------------------------------------------------------------

    local pages = {}
    local tabButtons = {}

    local function selectTab(selected)
        for name, page in pairs(pages) do
            page.Visible = name == selected
        end

        for name, button in pairs(tabButtons) do
            button.BackgroundTransparency =
                name == selected and 0 or 1

            button.TextColor3 =
                name == selected and TEXT or DIM
        end
    end

    for _, tabName in ipairs(TABS) do
        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.ScrollBarThickness = 2
        page.Visible = false
        page.Parent = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.Parent = page

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 10)
        padding.PaddingLeft = UDim.new(0, 10)
        padding.PaddingRight = UDim.new(0, 10)
        padding.PaddingBottom = UDim.new(0, 10)
        padding.Parent = page

        pages[tabName] = page

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 32)
        button.BackgroundColor3 = BG2
        button.BackgroundTransparency = 1
        button.BorderSizePixel = 0
        button.Text = tabName
        button.TextColor3 = DIM
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 12
        button.Parent = rail

        tabButtons[tabName] = button

        button.MouseButton1Click:Connect(function()
            selectTab(tabName)
        end)
    end

    selectTab("Legit")

    ------------------------------------------------------------
    -- TOGGLE BUILDER
    ------------------------------------------------------------

    local function addToggle(page, label, default, onChange)
        local state = default == true

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
        btn.Position = UDim2.new(1, -42, 0.5, -8.5)
        btn.BackgroundColor3 = state and ACCENT or OFF
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.Parent = row

        round(btn, 9)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(13, 13)
        knob.Position = UDim2.new(
            0,
            state and 17 or 2,
            0.5,
            -6.5
        )
        knob.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
        knob.BorderSizePixel = 0
        knob.Parent = btn

        round(knob, 7)

        local function paint(animate)
            local targetBg = state and ACCENT or OFF

            local targetPosition = UDim2.new(
                0,
                state and 17 or 2,
                0.5,
                -6.5
            )

            if animate then
                local info = TweenInfo.new(
                    0.15,
                    Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out
                )

                TweenService:Create(
                    btn,
                    info,
                    { BackgroundColor3 = targetBg }
                ):Play()

                TweenService:Create(
                    knob,
                    info,
                    { Position = targetPosition }
                ):Play()
            else
                btn.BackgroundColor3 = targetBg
                knob.Position = targetPosition
            end
        end

        btn.MouseButton1Click:Connect(function()
            state = not state
            config[label] = state

            paint(true)

            if onChange then
                task.spawn(onChange, state)
            end
        end)

        paint(false)

        return row
    end

    ------------------------------------------------------------
    -- ADJUSTER BUILDER
    ------------------------------------------------------------

    local function addAdjuster(
        page,
        label,
        getter,
        setter,
        minValue,
        maxValue,
        step
    )
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = BG2
        row.BorderSizePixel = 0
        row.Parent = page

        round(row, 5)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -130, 1, 0)
        lbl.Position = UDim2.fromOffset(9, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = TEXT
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 12
        lbl.Parent = row

        local value = Instance.new("TextLabel")
        value.Size = UDim2.fromOffset(42, 22)
        value.Position = UDim2.new(1, -83, 0.5, -11)
        value.BackgroundTransparency = 1
        value.TextColor3 = TEXT
        value.Font = Enum.Font.GothamBold
        value.TextSize = 12
        value.Parent = row

        local minus = Instance.new("TextButton")
        minus.Size = UDim2.fromOffset(22, 22)
        minus.Position = UDim2.new(1, -108, 0.5, -11)
        minus.BackgroundColor3 = OFF
        minus.BorderSizePixel = 0
        minus.Text = "-"
        minus.TextColor3 = TEXT
        minus.Font = Enum.Font.GothamBold
        minus.TextSize = 14
        minus.Parent = row

        round(minus, 4)

        local plus = Instance.new("TextButton")
        plus.Size = UDim2.fromOffset(22, 22)
        plus.Position = UDim2.new(1, -27, 0.5, -11)
        plus.BackgroundColor3 = OFF
        plus.BorderSizePixel = 0
        plus.Text = "+"
        plus.TextColor3 = TEXT
        plus.Font = Enum.Font.GothamBold
        plus.TextSize = 14
        plus.Parent = row

        round(plus, 4)

        local function refresh()
            value.Text = tostring(getter())
        end

        minus.MouseButton1Click:Connect(function()
            setter(math.clamp(
                getter() - step,
                minValue,
                maxValue
            ))

            refresh()
        end)

        plus.MouseButton1Click:Connect(function()
            setter(math.clamp(
                getter() + step,
                minValue,
                maxValue
            ))

            refresh()
        end)

        refresh()

        return row
    end

    ------------------------------------------------------------
    -- LEGIT TAB: NPC AIM TEST
    ------------------------------------------------------------

    addToggle(
        pages["Legit"],
        "Aim Assist",
        false,
        function(enabled)
            AimTest.Enabled = enabled
        end
    )

    addAdjuster(
        pages["Legit"],
        "FOV Radius",
        function()
            return AimTest.FOV
        end,
        function(value)
            AimTest.FOV = value
        end,
        20,
        240,
        10
    )

    addAdjuster(
        pages["Legit"],
        "Smoothness",
        function()
            return AimTest.Smoothness
        end,
        function(value)
            AimTest.Smoothness = value
        end,
        1,
        40,
        1
    )

    local partButton = Instance.new("TextButton")
    partButton.Size = UDim2.new(1, 0, 0, 30)
    partButton.BackgroundColor3 = BG2
    partButton.BorderSizePixel = 0
    partButton.TextColor3 = TEXT
    partButton.Font = Enum.Font.GothamMedium
    partButton.TextSize = 12
    partButton.Parent = pages["Legit"]

    round(partButton, 5)

    local targetParts = { "Head", "Chest", "Legs" }
    local partIndex = 1

    local function refreshPart()
        partButton.Text =
            "Target Part: " .. AimTest.TargetPart .. " (click to change)"
    end

    partButton.MouseButton1Click:Connect(function()
        partIndex = partIndex % #targetParts + 1
        AimTest.TargetPart = targetParts[partIndex]
        refreshPart()
    end)

    refreshPart()

    local keyButton = Instance.new("TextButton")
    keyButton.Size = UDim2.new(1, 0, 0, 30)
    keyButton.BackgroundColor3 = BG2
    keyButton.BorderSizePixel = 0
    keyButton.TextColor3 = TEXT
    keyButton.Font = Enum.Font.GothamMedium
    keyButton.TextSize = 12
    keyButton.Parent = pages["Legit"]

    round(keyButton, 5)

    local function refreshAimKey()
        if AimTest.WaitingForKey then
            keyButton.Text = "Press a keyboard key..."
        else
            keyButton.Text =
                "Aim Key: " .. AimTest.KeyCode.Name .. " (click to change)"
        end
    end

    aimKeyChangedCallback = refreshAimKey

    keyButton.MouseButton1Click:Connect(function()
        AimTest.WaitingForKey = true
        refreshAimKey()
    end)

    refreshAimKey()

    ------------------------------------------------------------
    -- VISUALS TAB
    ------------------------------------------------------------

    addToggle(
        pages["Visuals"],
        "ESP (Boxes)",
        false,
        function(enabled)
            esp(enabled)
        end
    )

    addToggle(
        pages["Visuals"],
        "Chams",
        false,
        function(enabled)
            toggleChams(enabled)
        end
    )

    ------------------------------------------------------------
    -- MISC TAB
    ------------------------------------------------------------

    local miscLabel = Instance.new("TextLabel")
    miscLabel.Size = UDim2.new(1, 0, 0, 48)
    miscLabel.BackgroundColor3 = BG2
    miscLabel.BorderSizePixel = 0
    miscLabel.Text =
        "Insert: Hide / Show UI\nDrag the header to move the window"
    miscLabel.TextColor3 = TEXT
    miscLabel.Font = Enum.Font.GothamMedium
    miscLabel.TextSize = 12
    miscLabel.TextWrapped = true
    miscLabel.Parent = pages["Misc"]

    round(miscLabel, 5)

    ------------------------------------------------------------
    -- CREDITS TAB
    ------------------------------------------------------------

    local creditsLabel = Instance.new("TextLabel")
    creditsLabel.Size = UDim2.new(1, 0, 0, 40)
    creditsLabel.BackgroundColor3 = BG2
    creditsLabel.BorderSizePixel = 0
    creditsLabel.Text = "created by niverbeer/AKA/Nicolae"
    creditsLabel.TextColor3 = TEXT
    creditsLabel.Font = Enum.Font.GothamMedium
    creditsLabel.TextSize = 13
    creditsLabel.TextWrapped = true
    creditsLabel.Parent = pages["Credits"]

    round(creditsLabel, 5)

    ------------------------------------------------------------
    -- DRAGGING: MOUSE + TOUCH
    ------------------------------------------------------------

    local dragging = false
    local dragInput
    local dragStart
    local startPos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true
            dragStart = input.Position
            startPos = panel.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart

            panel.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    ------------------------------------------------------------
    -- MINIMIZE
    ------------------------------------------------------------

    minBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        body.Visible = expanded

        panel.Size = expanded
            and UDim2.fromOffset(PANEL_W, PANEL_H)
            or UDim2.fromOffset(PANEL_W, HEADER_H + 1)

        minBtn.Text = expanded and "-" or "+"
    end)

    ------------------------------------------------------------
    -- INSERT: HIDE / SHOW
    ------------------------------------------------------------

    UIS.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.Insert then
            gui.Enabled = not gui.Enabled
        end
    end)
end

task.spawn(build)
