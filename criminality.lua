--!nocheck
-- fatality v3 + Chams + Box ESP
-- Put this in a LocalScript: StarterPlayer > StarterPlayerScripts

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

----------------------------------------------------------------
-- CHAMS (Highlight on other players)
----------------------------------------------------------------
local chamsActive = false
local chamsConns = {}

local function removeHighlight(p)
	if p.Character then
		local hl = p.Character:FindFirstChild("ESP_Highlight")
		if hl then hl:Destroy() end
	end
end

local function setupHighlight(character)
	if not chamsActive then return end
	character:WaitForChild("HumanoidRootPart", 10)
	if not chamsActive then return end

	if not character:FindFirstChild("ESP_Highlight") then
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESP_Highlight"
		highlight.FillColor = Color3.fromRGB(200, 55, 55)
		highlight.FillTransparency = 0.5
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = character
	end
end

local function toggleChams(state)
	chamsActive = state

	if state then
		local function applyChams(p)
			if p == player then return end
			if p.Character then task.spawn(setupHighlight, p.Character) end
			table.insert(chamsConns, p.CharacterAdded:Connect(setupHighlight))
		end

		for _, p in ipairs(Players:GetPlayers()) do
			applyChams(p)
		end
		table.insert(chamsConns, Players.PlayerAdded:Connect(applyChams))
	else
		for _, conn in ipairs(chamsConns) do
			conn:Disconnect()
		end
		chamsConns = {}

		for _, p in ipairs(Players:GetPlayers()) do
			removeHighlight(p)
		end
	end
end

----------------------------------------------------------------
-- ESP (2D boxes for other players only, optimized)
----------------------------------------------------------------
local PLAYER_COL = Color3.fromRGB(200, 55, 55)
local HP_LOW = Color3.fromRGB(220, 60, 60)
local HP_HIGH = Color3.fromRGB(80, 220, 100)

local MAX_DIST = 1500        -- players farther than this get no box
local TEXT_INTERVAL = 0.15   -- how often distance/health are refreshed (seconds)
local TOP_OFFSET = Vector3.new(0, 2.7, 0)
local BOTTOM_OFFSET = Vector3.new(0, 3.1, 0)

local espState = {
	gui = nil,
	session = 0,
	entities = {}, -- [character] = entry
	conns = {},
}
local lastTextUpdate = 0

local function removeEntry(model)
	local e = espState.entities[model]
	if e then
		e.box:Destroy()
		espState.entities[model] = nil
	end
end

local function createEntry(plr, humanoid, root)
	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Visible = false
	box.Parent = espState.gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = PLAYER_COL
	stroke.Thickness = 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = box

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 60, 0, 14)
	nameLbl.Position = UDim2.new(0, -30, 0, -16)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = plr.Name
	nameLbl.TextColor3 = PLAYER_COL
	nameLbl.TextStrokeTransparency = 0
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 12
	nameLbl.Parent = box

	local distLbl = Instance.new("TextLabel")
	distLbl.Size = UDim2.new(1, 60, 0, 12)
	distLbl.Position = UDim2.new(0, -30, 1, 2)
	distLbl.BackgroundTransparency = 1
	distLbl.Text = ""
	distLbl.TextColor3 = Color3.fromRGB(235, 235, 240)
	distLbl.TextStrokeTransparency = 0
	distLbl.Font = Enum.Font.GothamMedium
	distLbl.TextSize = 11
	distLbl.Parent = box

	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(0, 3, 1, 0)
	hpBg.Position = UDim2.new(0, -6, 0, 0)
	hpBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	hpBg.BorderSizePixel = 0
	hpBg.Parent = box

	local hpFill = Instance.new("Frame")
	hpFill.AnchorPoint = Vector2.new(0, 1)
	hpFill.Position = UDim2.new(0, 0, 1, 0)
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = HP_HIGH
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg

	return {
		humanoid = humanoid,
		root = root,
		box = box,
		dist = distLbl,
		hpFill = hpFill,
		visible = false,
		lastDist = -1,
		lastHp = -1,
	}
end

local function updateESP()
	local cam = workspace.CurrentCamera
	if not cam then return end

	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local origin = myRoot and myRoot.Position or cam.CFrame.Position

	-- throttle the expensive part (text + health bar)
	local now = os.clock()
	local doText = (now - lastTextUpdate) >= TEXT_INTERVAL
	if doText then lastTextUpdate = now end

	for model, e in pairs(espState.entities) do
		local root = e.root

		if not model.Parent or not root.Parent then
			removeEntry(model)
		else
			local pos = root.Position
			local dist = (origin - pos).Magnitude
			local show = false

			if e.humanoid.Health > 0 and dist <= MAX_DIST then
				local top = cam:WorldToViewportPoint(pos + TOP_OFFSET)
				local bottom = cam:WorldToViewportPoint(pos - BOTTOM_OFFSET)

				if top.Z > 0 and bottom.Z > 0 then
					show = true
					local height = math.floor(math.abs(bottom.Y - top.Y))
					local width = math.floor(height * 0.55)
					local cx = (top.X + bottom.X) / 2

					e.box.Position = UDim2.fromOffset(math.floor(cx - width / 2), math.floor(top.Y))
					e.box.Size = UDim2.fromOffset(width, height)

					if doText then
						local d = math.floor(dist)
						if d ~= e.lastDist then
							e.lastDist = d
							e.dist.Text = "[" .. d .. " studs]"
						end

						local hp = math.clamp(e.humanoid.Health / math.max(e.humanoid.MaxHealth, 1), 0, 1)
						local q = math.floor(hp * 20)
						if q ~= e.lastHp then
							e.lastHp = q
							e.hpFill.Size = UDim2.new(1, 0, hp, 0)
							e.hpFill.BackgroundColor3 = HP_LOW:Lerp(HP_HIGH, hp)
						end
					end
				end
			end

			-- only touch Visible when it actually changes
			if show ~= e.visible then
				e.visible = show
				e.box.Visible = show
			end
		end
	end
end

local function trackPlayer(p, session)
	if p == player then return end

	local function onCharacter(char)
		task.spawn(function()
			local hum = char:WaitForChild("Humanoid", 10)
			local root = char:WaitForChild("HumanoidRootPart", 10)
			if session ~= espState.session or not espState.gui then return end
			if not hum or not root or not char.Parent then return end
			removeEntry(char)
			espState.entities[char] = createEntry(p, hum, root)
		end)
	end

	if p.Character then onCharacter(p.Character) end
	table.insert(espState.conns, p.CharacterAdded:Connect(onCharacter))
	table.insert(espState.conns, p.CharacterRemoving:Connect(removeEntry))
end

local function esp(state)
	if state then
		if espState.gui then return end

		espState.session += 1
		local session = espState.session

		local gui = Instance.new("ScreenGui")
		gui.Name = "fatality_esp"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true -- matches WorldToViewportPoint coordinates
		gui.DisplayOrder = 998
		gui.Parent = player:WaitForChild("PlayerGui")
		espState.gui = gui

		-- track players directly (no workspace-wide scanning)
		for _, p in ipairs(Players:GetPlayers()) do
			trackPlayer(p, session)
		end
		table.insert(espState.conns, Players.PlayerAdded:Connect(function(p)
			trackPlayer(p, session)
		end))

		table.insert(espState.conns, RunService.RenderStepped:Connect(updateESP))
	else
		espState.session += 1
		for _, conn in ipairs(espState.conns) do
			conn:Disconnect()
		end
		espState.conns = {}
		espState.entities = {}
		if espState.gui then
			espState.gui:Destroy()
			espState.gui = nil
		end
	end
end

----------------------------------------------------------------
-- UI
----------------------------------------------------------------
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
	local TABS = { "Legit", "Rage", "Visuals", "Misc", "Credits" }

	local config = {}
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

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -RAIL_W, 1, 0)
	content.Position = UDim2.fromOffset(RAIL_W, 0)
	content.BackgroundTransparency = 1
	content.Parent = body

	-- ===== TAB PAGES =====
	local pages = {}
	for _, tabName in ipairs(TABS) do
		local page = Instance.new("ScrollingFrame")
		page.Size = UDim2.new(1, 0, 1, 0)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.ScrollBarThickness = 2
		page.Visible = (tabName == "Visuals")
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

		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(1, 0, 0, 32)
		tabBtn.BackgroundColor3 = BG2
		tabBtn.BackgroundTransparency = (tabName == "Visuals") and 0 or 1
		tabBtn.BorderSizePixel = 0
		tabBtn.Text = tabName
		tabBtn.TextColor3 = (tabName == "Visuals") and TEXT or DIM
		tabBtn.Font = Enum.Font.GothamMedium
		tabBtn.TextSize = 12
		tabBtn.Parent = rail

		tabBtn.MouseButton1Click:Connect(function()
			for name, p in pairs(pages) do
				p.Visible = (name == tabName)
			end
			for _, b in ipairs(rail:GetChildren()) do
				if b:IsA("TextButton") then
					b.BackgroundTransparency = 1
					b.TextColor3 = DIM
				end
			end
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

		local function paint(animate)
			local targetBg = state and ACCENT or OFF
			local targetKnobPos = UDim2.new(0, state and 17 or 2, 0.5, -6.5)

			if animate then
				local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				TweenService:Create(btn, info, { BackgroundColor3 = targetBg }):Play()
				TweenService:Create(knob, info, { Position = targetKnobPos }):Play()
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

	-- ===== VISUALS TAB =====
	addToggle(pages["Visuals"], "ESP (Boxes)", false, function(enabled)
		esp(enabled)
	end)

	addToggle(pages["Visuals"], "Chams", false, function(enabled)
		toggleChams(enabled)
	end)

	-- ===== CREDITS TAB =====
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

	-- ===== DRAGGING (mouse + touch) =====
	local dragging, dragInput, dragStart, startPos

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
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	-- ===== MINIMIZE =====
	minBtn.MouseButton1Click:Connect(function()
		expanded = not expanded
		body.Visible = expanded
		panel.Size = expanded and UDim2.fromOffset(PANEL_W, PANEL_H) or UDim2.fromOffset(PANEL_W, HEADER_H + 1)
		minBtn.Text = expanded and "-" or "+"
	end)

	-- ===== INSERT TO HIDE/SHOW =====
	UIS.InputBegan:Connect(function(input, gpe)
		if not gpe and input.KeyCode == Enum.KeyCode.Insert then
			gui.Enabled = not gui.Enabled
		end
	end)
end

task.spawn(build)
