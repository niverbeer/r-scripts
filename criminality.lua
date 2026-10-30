--!nocheck
-- fatality
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ACCENT = Color3.fromRGB(200, 55, 55)
local BG = Color3.fromRGB(15, 15, 18)
local BG2 = Color3.fromRGB(24, 24, 29)
local RAIL = Color3.fromRGB(11, 11, 14)
local TEXT = Color3.fromRGB(220, 220, 225)
local DIM = Color3.fromRGB(150, 150, 158)
local OFF = Color3.fromRGB(45, 45, 52)
local LINE = Color3.fromRGB(50, 50, 58)

local conns = {}
local function track(c)
    table.insert(conns, c)
    return c
end

local function clearConns()
    for _, c in ipairs(conns) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(conns)
end

local function inset()
    local a = GuiService:GetGuiInset()
    return a or Vector2.new(0, 36)
end

local function screenCenter()
    local cam = workspace.CurrentCamera
    local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
    local ins = inset()
    return Vector2.new(vp.X / 2 + ins.X / 2, vp.Y / 2 + ins.Y / 2)
end

----------------------------------------------------------------
-- CHAMS
----------------------------------------------------------------
local chamsActive = false
local chamsConns = {}

local function removeHighlight(plr)
    if not plr.Character then return end
    local hl = plr.Character:FindFirstChild("ESP_Highlight")
    if hl then hl:Destroy() end
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
            table.insert(chamsConns, plr.CharacterAdded:Connect(setupHighlight))
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            apply(plr)
        end

        table.insert(chamsConns, Players.PlayerAdded:Connect(apply))
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
                local top = camera:WorldToViewportPoint(root.Position + TOP_OFFSET)
                local bottom = camera:WorldToViewportPoint(root.Position - BOTTOM_OFFSET)

                if top.Z > 0 and bottom.Z > 0 then
                    show = true

                    local height = math.floor(math.abs(bottom.Y - top.Y))
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
                            entry.dist.Text = "[" .. roundedDistance .. " studs]"
                        end

                        local hp = math.clamp(
                            humanoid.Health / math.max(humanoid.MaxHealth, 1),
                            0,
                            1
                        )

                        local quantizedHp = math.floor(hp * 20)

                        if quantizedHp ~= entry.lastHp then
                            entry.lastHp = quantizedHp
                            entry.hpFill.Size = UDim2.new(1, 0, hp, 0)
                            entry.hpFill.BackgroundColor3 = HP_LOW:Lerp(HP_HIGH, hp)
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
            espState.entities[character] = createEntry(plr, humanoid, root)
        end)
    end

    if plr.Character then
        onCharacter(plr.Character)
    end

    table.insert(espState.conns, plr.CharacterAdded:Connect(onCharacter))
    table.insert(espState.conns, plr.CharacterRemoving:Connect(removeEntry))
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

        table.insert(espState.conns, RunService.RenderStepped:Connect(updateESP))
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
-- AIM
----------------------------------------------------------------
local Aim = {
    Enabled = false,
    FOV = 80,
    Smoothness = 4,
    Key = Enum.KeyCode.Q,
    WaitingForKey = false,
    Part = "Head",
    VisibleOnly = true,
    TeamCheck = true,
    Prediction = false,
    ProjectileSpeed = 500,
    LockTime = 0.2,
}

local aiming = false
local lockPart, lockAt = nil, 0
local aimKeyChanged

local aimGui = Instance.new("ScreenGui")
aimGui.Name = "FatalityAimFOV"
aimGui.ResetOnSpawn = false
aimGui.IgnoreGuiInset = true
aimGui.DisplayOrder = 997
aimGui.Parent = playerGui

local aimCircle = Instance.new("Frame")
aimCircle.AnchorPoint = Vector2.new(0.5, 0.5)
aimCircle.BackgroundTransparency = 1
aimCircle.Visible = false
aimCircle.Parent = aimGui

local aimCorner = Instance.new("UICorner")
aimCorner.CornerRadius = UDim.new(1, 0)
aimCorner.Parent = aimCircle

local aimStroke = Instance.new("UIStroke")
aimStroke.Color = ACCENT
aimStroke.Thickness = 1.5
aimStroke.Transparency = 0.15
aimStroke.Parent = aimCircle

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function canSee(part)
    if not Aim.VisibleOnly then return true end
    local cam = workspace.CurrentCamera
    if not cam then return true end

    local filter = {}
    if player.Character then table.insert(filter, player.Character) end
    if part.Parent then table.insert(filter, part.Parent) end
    rayParams.FilterDescendantsInstances = filter

    local hit = workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, rayParams)
    return hit == nil
end

local function resolvePart(char)
    if Aim.Part == "Head" then
        local h = char:FindFirstChild("Head")
        if h then return h end
    elseif Aim.Part == "Chest" then
        local c = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if c then return c end
    elseif Aim.Part == "Legs" then
        local l = char:FindFirstChild("LeftLowerLeg")
            or char:FindFirstChild("Left Leg")
            or char:FindFirstChild("RightLowerLeg")
            or char:FindFirstChild("Right Leg")
        if l then return l end
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function pickTarget(center)
    local cam = workspace.CurrentCamera
    if not cam then return nil end

    local best, bestD = nil, Aim.FOV

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local part = char and resolvePart(char)

            local teamOK = true
            if Aim.TeamCheck and p.Team ~= nil and p.Team == player.Team then
                teamOK = false
            end

            if teamOK and hum and hum.Health > 0 and part then
                local sp, onScreen = cam:WorldToScreenPoint(part.Position)
                if onScreen and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d < bestD and canSee(part) then
                        best, bestD = part, d
                    end
                end
            end
        end
    end

    return best
end

local function aimStep(dt)
    local cam = workspace.CurrentCamera
    if not cam then return end

    local center = screenCenter()

    aimCircle.Position = UDim2.fromOffset(center.X, center.Y)
    aimCircle.Size = UDim2.fromOffset(Aim.FOV * 2, Aim.FOV * 2)
    aimCircle.Visible = Aim.Enabled and aiming
    aimStroke.Color = aiming and Color3.new(1, 1, 1) or ACCENT

    if not Aim.Enabled or not aiming then
        lockPart = nil
        return
    end

    local target = nil

    if lockPart and lockPart.Parent and os.clock() - lockAt < Aim.LockTime then
        local sp, onScreen = cam:WorldToScreenPoint(lockPart.Position)
        if onScreen and sp.Z > 0
            and (Vector2.new(sp.X, sp.Y) - center).Magnitude <= Aim.FOV then
            target = lockPart
        end
    end

    if not target then
        target = pickTarget(center)
        lockPart = target
        lockAt = os.clock()
    end

    if not target then return end

    local sp = cam:WorldToScreenPoint(target.Position)
    if (Vector2.new(sp.X, sp.Y) - center).Magnitude < 2 then return end

    local pos = target.Position
    if Aim.Prediction then
        local dist = (pos - cam.CFrame.Position).Magnitude
        pos = pos + target.AssemblyLinearVelocity * (dist / math.max(Aim.ProjectileSpeed, 1))
    end

    local desired = CFrame.lookAt(cam.CFrame.Position, pos + Vector3.new(0, 0.15, 0))
    local alpha = math.clamp(1 - math.exp(-Aim.Smoothness * dt), 0, 1)
    cam.CFrame = cam.CFrame:Lerp(desired, alpha)
end

track(UIS.InputBegan:Connect(function(input, processed)
    if Aim.WaitingForKey then
        if input.UserInputType == Enum.UserInputType.Keyboard
            and input.KeyCode ~= Enum.KeyCode.Unknown
            and input.KeyCode ~= Enum.KeyCode.Escape then
            Aim.Key = input.KeyCode
            Aim.WaitingForKey = false
            if aimKeyChanged then aimKeyChanged() end
        end
        return
    end
    if not processed and input.UserInputType == Enum.UserInputType.Keyboard
        and input.KeyCode == Aim.Key then
        aiming = true
    end
end))

track(UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Aim.Key then aiming = false end
end))

----------------------------------------------------------------
-- SILENT AIM FOV PREVIEW
----------------------------------------------------------------
local SA = { Enabled = false, FOV = 150, HitChance = 100, ShowFOV = true, Chest = false }

local saGui = Instance.new("ScreenGui")
saGui.Name = "FatalitySilentFOV"
saGui.ResetOnSpawn = false
saGui.IgnoreGuiInset = true
saGui.DisplayOrder = 996
saGui.Parent = playerGui

local saCircle = Instance.new("Frame")
saCircle.AnchorPoint = Vector2.new(0.5, 0.5)
saCircle.BackgroundTransparency = 1
saCircle.Visible = false
saCircle.Parent = saGui

local saCorner = Instance.new("UICorner")
saCorner.CornerRadius = UDim.new(1, 0)
saCorner.Parent = saCircle

local saStroke = Instance.new("UIStroke")
saStroke.Color = Color3.new(1, 1, 1)
saStroke.Thickness = 1.5
saStroke.Transparency = 0.2
saStroke.Parent = saCircle

track(RunService.RenderStepped:Connect(function()
    local center = screenCenter()
    saCircle.Position = UDim2.fromOffset(center.X, center.Y)
    saCircle.Size = UDim2.fromOffset(SA.FOV * 2, SA.FOV * 2)
    saCircle.Visible = SA.Enabled and SA.ShowFOV
end))

----------------------------------------------------------------
-- ANTI-AIM
----------------------------------------------------------------
local AA = { Enabled = false, Spin = 180, Dir = 1, Pitch = 0 }

local spinConn, spinHum, spinOrig

local function stopSpin()
    if spinConn then
        spinConn:Disconnect()
        spinConn = nil
    end
    if spinHum and spinHum.Parent then
        spinHum.AutoRotate = spinOrig
    end
    spinHum, spinOrig = nil, nil
end

local function startSpin()
    stopSpin()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    spinHum = hum
    spinOrig = hum.AutoRotate
    hum.AutoRotate = false

    local angle = math.rad(root.Orientation.Y)

    spinConn = RunService.RenderStepped:Connect(function(dt)
        if not AA.Enabled or not char.Parent or not root.Parent then
            stopSpin()
            return
        end
        angle += math.rad(AA.Spin) * AA.Dir * dt
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(math.rad(AA.Pitch), angle, 0)
    end)
end

local function refreshSpin()
    if AA.Enabled then startSpin() else stopSpin() end
end

track(player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if AA.Enabled then startSpin() end
end))

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
local function build()
    local PANEL_W, PANEL_H, HEADER_H, RAIL_W = 430, 270, 36, 104
    local BODY_H = PANEL_H - HEADER_H
    local TABS = { "Legit", "Rage", "Visuals", "Misc" }

    local config = {}
    local expanded = true
    local pages, tabBtns = {}, {}

    for _, n in ipairs({ "fatality", "fatality_wm" }) do
        local old = playerGui:FindFirstChild(n)
        if old then old:Destroy() end
    end

    local function round(o, r)
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = o
    end

    local function outline(o)
        local s = Instance.new("UIStroke")
        s.Color = LINE
        s.Thickness = 1
        s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        s.Parent = o
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

    local rl = Instance.new("UIListLayout")
    rl.Padding = UDim.new(0, 1)
    rl.Parent = rail

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -RAIL_W, 1, 0)
    content.Position = UDim2.fromOffset(RAIL_W, 0)
    content.BackgroundTransparency = 1
    content.Parent = body

    local function selectTab(name)
        for n, page in pairs(pages) do page.Visible = n == name end
        for n, btn in pairs(tabBtns) do
            btn.BackgroundTransparency = n == name and 0 or 1
            btn.TextColor3 = n == name and TEXT or DIM
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

        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 6)
        l.Parent = page

        local p = Instance.new("UIPadding")
        p.PaddingTop = UDim.new(0, 10)
        p.PaddingLeft = UDim.new(0, 10)
        p.PaddingRight = UDim.new(0, 10)
        p.PaddingBottom = UDim.new(0, 10)
        p.Parent = page

        pages[tabName] = page

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 32)
        b.BackgroundColor3 = BG2
        b.BackgroundTransparency = 1
        b.BorderSizePixel = 0
        b.Text = tabName
        b.TextColor3 = DIM
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.Parent = rail
        tabBtns[tabName] = b

        b.MouseButton1Click:Connect(function() selectTab(tabName) end)
    end

    selectTab("Legit")

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
        knob.Position = UDim2.new(0, state and 17 or 2, 0.5, -6.5)
        knob.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
        knob.BorderSizePixel = 0
        knob.Parent = btn
        round(knob, 7)

        local function paint(anim)
            local bg = state and ACCENT or OFF
            local pos = UDim2.new(0, state and 17 or 2, 0.5, -6.5)
            if anim then
                local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                TweenService:Create(btn, ti, { BackgroundColor3 = bg }):Play()
                TweenService:Create(knob, ti, { Position = pos }):Play()
            else
                btn.BackgroundColor3 = bg
                knob.Position = pos
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

    local function addAdjuster(page, label, getter, setter, minV, maxV, step)
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

        local val = Instance.new("TextLabel")
        val.Size = UDim2.fromOffset(42, 22)
        val.Position = UDim2.new(1, -83, 0.5, -11)
        val.BackgroundTransparency = 1
        val.TextColor3 = TEXT
        val.Font = Enum.Font.GothamBold
        val.TextSize = 12
        val.Parent = row

        local function makeBtn(off, glyph)
            local b = Instance.new("TextButton")
            b.Size = UDim2.fromOffset(22, 22)
            b.Position = UDim2.new(1, off, 0.5, -11)
            b.BackgroundColor3 = OFF
            b.BorderSizePixel = 0
            b.Text = glyph
            b.TextColor3 = TEXT
            b.Font = Enum.Font.GothamBold
            b.TextSize = 14
            b.Parent = row
            round(b, 4)
            return b
        end

        local minus = makeBtn(-108, "-")
        local plus = makeBtn(-27, "+")

        local function refresh() val.Text = tostring(getter()) end

        minus.MouseButton1Click:Connect(function()
            setter(math.clamp(getter() - step, minV, maxV))
            refresh()
        end)
        plus.MouseButton1Click:Connect(function()
            setter(math.clamp(getter() + step, minV, maxV))
            refresh()
        end)

        refresh()
        return row
    end

    local function addCycler(page, label, options, getter, setter)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 0, 30)
        b.BackgroundColor3 = BG2
        b.BorderSizePixel = 0
        b.TextColor3 = TEXT
        b.Font = Enum.Font.GothamMedium
        b.TextSize = 12
        b.Parent = page
        round(b, 5)

        local function refresh() b.Text = label .. ": " .. tostring(getter()) end

        b.MouseButton1Click:Connect(function()
            local cur = getter()
            local idx = 1
            for i, v in ipairs(options) do
                if v == cur then idx = i break end
            end
            setter(options[idx % #options + 1])
            refresh()
        end)

        refresh()
        return b
    end

    addToggle(pages["Legit"], "Aim Assist", false, function(on)
        Aim.Enabled = on
        if not on then aiming = false end
    end)

    addAdjuster(pages["Legit"], "FOV Radius",
        function() return Aim.FOV end,
        function(v) Aim.FOV = v end,
        20, 240, 10)

    addAdjuster(pages["Legit"], "Smoothness",
        function() return Aim.Smoothness end,
        function(v) Aim.Smoothness = v end,
        1, 40, 1)

    addCycler(pages["Legit"], "Target Part", { "Head", "Chest", "Legs" },
        function() return Aim.Part end,
        function(v) Aim.Part = v end)

    addToggle(pages["Legit"], "Visible Only", true, function(on)
        Aim.VisibleOnly = on
    end)

    addToggle(pages["Legit"], "Team Check", true, function(on)
        Aim.TeamCheck = on
    end)

    addToggle(pages["Legit"], "Prediction", false, function(on)
        Aim.Prediction = on
    end)

    addAdjuster(pages["Legit"], "Projectile Speed",
        function() return Aim.ProjectileSpeed end,
        function(v) Aim.ProjectileSpeed = v end,
        100, 2000, 100)

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(1, 0, 0, 30)
    keyBtn.BackgroundColor3 = BG2
    keyBtn.BorderSizePixel = 0
    keyBtn.TextColor3 = TEXT
    keyBtn.Font = Enum.Font.GothamMedium
    keyBtn.TextSize = 12
    keyBtn.Parent = pages["Legit"]
    round(keyBtn, 5)

    local function refreshKey()
        if Aim.WaitingForKey then
            keyBtn.Text = "Press a key..."
        else
            keyBtn.Text = "Aim Key: " .. Aim.Key.Name .. " (click to change)"
        end
    end

    aimKeyChanged = refreshKey

    keyBtn.MouseButton1Click:Connect(function()
        Aim.WaitingForKey = true
        refreshKey()
    end)

    refreshKey()

    addToggle(pages["Rage"], "Silent Aim Preview", false, function(on)
        SA.Enabled = on
    end)

    addAdjuster(pages["Rage"], "Silent FOV",
        function() return SA.FOV end,
        function(v) SA.FOV = v end,
        50, 500, 25)

    addAdjuster(pages["Rage"], "Hit Chance",
        function() return SA.HitChance end,
        function(v) SA.HitChance = v end,
        0, 100, 10)

    addToggle(pages["Rage"], "Show Silent FOV", true, function(on)
        SA.ShowFOV = on
    end)

    addToggle(pages["Rage"], "Silent Target Chest", false, function(on)
        SA.Chest = on
    end)

    addToggle(pages["Rage"], "Anti-Aim", false, function(on)
        AA.Enabled = on
        refreshSpin()
    end)

    addAdjuster(pages["Rage"], "Spin Speed",
        function() return AA.Spin end,
        function(v) AA.Spin = v; if AA.Enabled then startSpin() end end,
        30, 1650, 30)

    addToggle(pages["Rage"], "Reverse Yaw", false, function(on)
        AA.Dir = on and -1 or 1
    end)

    addAdjuster(pages["Rage"], "Pitch Offset",
        function() return AA.Pitch end,
        function(v) AA.Pitch = v end,
        -90, 90, 15)

    addToggle(pages["Visuals"], "ESP (Boxes)", false, function(on) esp(on) end)
    addToggle(pages["Visuals"], "Chams", false, function(on) toggleChams(on) end)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 48)
    info.BackgroundColor3 = BG2
    info.BorderSizePixel = 0
    info.Text = "Insert: hide / show UI\nDrag the header to move"
    info.TextColor3 = TEXT
    info.Font = Enum.Font.GothamMedium
    info.TextSize = 12
    info.TextWrapped = true
    info.Parent = pages["Misc"]
    round(info, 5)

    local unload = Instance.new("TextButton")
    unload.Size = UDim2.new(1, 0, 0, 30)
    unload.BackgroundColor3 = BG2
    unload.BorderSizePixel = 0
    unload.Text = "Unload"
    unload.TextColor3 = TEXT
    unload.Font = Enum.Font.GothamMedium
    unload.TextSize = 12
    unload.Parent = pages["Misc"]
    round(unload, 5)

    unload.MouseButton1Click:Connect(function()
        pcall(function()
            RunService:UnbindFromRenderStep("FatalityAimStep")
        end)
        stopSpin()
        clearConns()
        esp(false)
        toggleChams(false)
        gui:Destroy()
        aimGui:Destroy()
        saGui:Destroy()
    end)

    local dragConn, upConn
    local function press(i)
        return i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch
    end

    header.InputBegan:Connect(function(i)
        if not press(i) then return end
        if dragConn then dragConn:Disconnect() end
        if upConn then upConn:Disconnect() end

        local start = i.Position
        local origin = panel.AbsolutePosition

        dragConn = UIS.InputChanged:Connect(function(m)
            if m.UserInputType == Enum.UserInputType.MouseMovement
                or m.UserInputType == Enum.UserInputType.Touch then
                panel.Position = UDim2.fromOffset(
                    origin.X + (m.Position.X - start.X),
                    origin.Y + (m.Position.Y - start.Y)
                )
            end
        end)
        upConn = UIS.InputEnded:Connect(function(m)
            if not press(m) then return end
            if dragConn then dragConn:Disconnect() end
            if upConn then upConn:Disconnect() end
            dragConn, upConn = nil, nil
        end)
    end)

    minBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        body.Visible = expanded
        hr.Visible = expanded
        panel.Size = UDim2.fromOffset(PANEL_W, expanded and PANEL_H or HEADER_H)
        minBtn.Text = expanded and "-" or "+"
    end)

    track(UIS.InputBegan:Connect(function(i, processed)
        if not processed and i.KeyCode == Enum.KeyCode.Insert then
            gui.Enabled = not gui.Enabled
        end
    end))
end

build()
RunService:BindToRenderStep("FatalityAimStep", Enum.RenderPriority.Camera.Value + 1, aimStep)
