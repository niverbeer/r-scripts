local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "theops",
   LoadingTitle = "theops",
   LoadingSubtitle = "private build",
   ConfigurationSaving = { Enabled = false }
})

local function placeholder(name)
   return function(v) print(("[theops] %s -> %s"):format(name, tostring(v))) end
end

-- COMBAT
local Combat = Window:CreateTab("Combat", 4483362458)
Combat:CreateToggle({ Name = "Aimbot", CurrentValue = false, Callback = placeholder("aimbot") })
Combat:CreateSlider({ Name = "FOV", Range = {10, 360}, Increment = 5, CurrentValue = 90, Callback = placeholder("fov") })
Combat:CreateSlider({ Name = "Smoothness", Range = {0, 1}, Increment = 0.05, CurrentValue = 0.5, Callback = placeholder("smoothness") })
Combat:CreateToggle({ Name = "Hitbox Expander", CurrentValue = false, Callback = placeholder("hitbox") })

-- MOVEMENT
local Movement = Window:CreateTab("Movement", 4483362458)
Movement:CreateSlider({ Name = "Walk Speed", Range = {16, 500}, Increment = 1, CurrentValue = 16, Callback = placeholder("speed") })
Movement:CreateSlider({ Name = "Jump Power", Range = {50, 500}, Increment = 5, CurrentValue = 50, Callback = placeholder("jump") })
Movement:CreateToggle({ Name = "Noclip", CurrentValue = false, Callback = placeholder("noclip") })
Movement:CreateToggle({ Name = "Fly", CurrentValue = false, Callback = placeholder("fly") })

-- VISUALS
local Visuals = Window:CreateTab("Visuals", 4483362458)
Visuals:CreateToggle({ Name = "Player ESP", CurrentValue = false, Callback = placeholder("esp") })
Visuals:CreateToggle({ Name = "Chams", CurrentValue = false, Callback = placeholder("chams") })
Visuals:CreateToggle({ Name = "Off-screen Arrows", CurrentValue = false, Callback = placeholder("arrows") })

-- WEAPONS
local Weapons = Window:CreateTab("Weapons", 4483362458)
Weapons:CreateToggle({ Name = "No Recoil", CurrentValue = false, Callback = placeholder("recoil") })
Weapons:CreateToggle({ Name = "Fast Fire", CurrentValue = false, Callback = placeholder("fire") })
Weapons:CreateToggle({ Name = "Auto Reload", CurrentValue = false, Callback = placeholder("reload") })

-- MISC
local Misc = Window:CreateTab("Misc", 4483362458)
Misc:CreateToggle({ Name = "Anti-AFK", CurrentValue = false, Callback = placeholder("afk") })
Misc:CreateButton({ Name = "FPS Boost", Callback = function() print("[theops] fps boost") end })
