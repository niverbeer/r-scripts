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
-- ESP (2D boxes for every Humanoid: players + NPCs)
----------------------------------------------------------------
local PLAYER_COL = Color3.fromRGB(200, 55, 55)
local NPC_COL = Color3.fromRGB(255, 170, 50)

local espState = {
	gui = nil,
	entities = {}, -- [model] = { humanoid, box, name, dist, hpFill, isPlayer }
	conns = {},
}

local function removeEntry(model)
	local e = espState.entities[model]
	if e then
		e.box:Destroy()
		espState.entities[model] = nil
	end
end

local function createEntry(model, humanoid)
	local plr = Players:GetPlayerFromCharacter(model)
	local col = plr and PLAYER_COL or NPC_COL

	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Visible = false
	box.Parent = espState.gui

	local stroke = Instance.new("UIStroke")
	stroke.Color = col
	stroke.Thickness = 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = box

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 60, 0, 14)
	nameLbl.Position = UDim2.new(0, -30, 0, -16)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = plr and plr.Name or model.Name
	nameLbl.TextColor3 = col
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
	hpFill.BackgroundColor3 = Color3.fromRGB(80, 220, 100)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg

	return { humanoid = humanoid, box = box, name = nameLbl, dist = distLbl, hpFill = hpFill }
end

local function trackModel(model)
	if espState.entities[model] then return end
	if not model:IsA("Model") or model == player.Character then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	espState.entities[model] = createEntry(model, hum)
end

local function updateESP()
	local cam = workspace.CurrentCamera
	if not cam then return end

	local myChar = player.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

	for model, e in pairs(espState.entities) do
		if not model:IsDescendantOf(workspace) then
			removeEntry(model)
		elseif model == myChar or e.humanoid.Health <= 0 then
			e.box.Visible = false
		else
			local cf, size = model:GetBoundingBox()
			local center = cam:WorldToViewportPoint(cf.Position)

			if center.Z <= 0 then
				e.box.Visible = false
			else
				local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
				local any = false
				local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2

				for _, sx in ipairs({ -1, 1 }) do
					for _, sy in ipairs({ -1, 1 }) do
						for _, sz in ipairs({ -1, 1 }) do
							local v = cam:WorldToViewportPoint((cf * CFrame.new(sx * hx, sy * hy, sz * hz)).Position)
							if v.Z > 0 then
								any = true
								minX = math.min(minX, v.X)
								minY = math.min(minY, v.Y)
								maxX = math.max(maxX, v.X)
								maxY = math.max(maxY, v.Y)
							end
						end
					end
				end

				if any then
					e.box.Position = UDim2.fromOffset(minX, minY)
					e.box.Size = UDim2.fromOffset(maxX - minX, maxY - minY)
					e.box.Visible = true

					local hp = math.clamp(e.humanoid.Health / math.max(e.humanoid.MaxHealth, 1), 0, 1)
					e.hpFill.Size = UDim2.new(1, 0, hp, 0)
					e.hpFill.BackgroundColor3 = Color3.fromRGB(220, 60, 60):Lerp(Color3.fromRGB(80, 220, 100), hp)

					if myRoot then
						e.dist.Text = "[" .. math.floor((myRoot.Position - cf.Position).Magnitude) .. " studs]"
					else
						e.dist.Text = ""
					end
				else
					e.box.Visible = false
				end
			end
		end
	end
end

local function esp(state)
	if state then
		if espState.gui then return end

		local gui = Instance.new("ScreenGui")
		gui.Name = "fatality_esp"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true -- matches WorldToViewportPoint coordinates
		gui.DisplayOrder = 998
		gui.Parent = player:WaitForChild("PlayerGui")
		espState.gui = gui

		-- every Humanoid already in the world (players + NPCs)
		for _, inst in ipairs(workspace:GetDescendants()) do
			if inst:IsA("Humanoid") and inst.Parent then
				trackModel(inst.Parent)
			end
		end

		-- anything that spawns later
		table.insert(espState.conns, workspace.DescendantAdded:Connect(function(inst)
			if inst:IsA("Humanoid") then
				task.defer(function()
					if inst.Parent then trackModel(inst.Parent) end
				end)
			end
		end))

		table.insert(espState.conns, RunService.RenderStepped:Connect(updateESP))
	else
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
	local TABS = { "Legit", "Rage", "Visuals", "Misc" }

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
