--!strict
-- The exploring HUD (layout D, minimal): your gold, sword and bandages, in the
-- top-right corner (the top-left has Roblox's menu buttons, and the
-- bottom corners stay free for the mobile thumbstick).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Supplies = require(ReplicatedStorage.Modules.Items.Supplies)
local Progress = require(script.Parent.Progress)

local Hud = {}

local GOLD = Color3.fromRGB(255, 215, 80)

function Hud.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(1, 0)
	panel.Position = UDim2.new(1, -16, 0, 12)
	panel.Size = UDim2.fromOffset(0, 40)
	panel.AutomaticSize = Enum.AutomaticSize.X
	panel.BackgroundColor3 = Color3.new(0, 0, 0)
	panel.BackgroundTransparency = 0.35
	panel.Parent = gui
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(0, 1)
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Font = Enum.Font.Arcade
	text.TextSize = 22
	text.TextColor3 = GOLD
	text.Parent = panel

	local function refresh()
		local parts = { `{Progress.gold()} G`, Progress.weapon().Name }
		for id, supply in Supplies do
			local count = Progress.itemCount(id)
			if count > 0 then
				table.insert(parts, `{supply.Name} x{count}`)
			end
		end
		text.Text = table.concat(parts, "   ")
	end
	refresh()
	Progress.Changed:Connect(refresh)
end

return Hud
