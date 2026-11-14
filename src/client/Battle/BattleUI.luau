--!strict
-- Battle screen, layout A ("classic box") from design/Game UI Proposals.html:
--   enemy at the top (3D, from BattleArena), a dialogue box in the middle
--   (messages and option lists; the dodge box appears there in step 7),
--   the player's row with avatar headshot, name and HP, and command
--   buttons along the bottom.
-- Rules: text >= 18 px, buttons >= 44 px tall, bottom corners left free.
-- This module only draws. Input is handled by BattleMenu.

local Players = game:GetService("Players")

local BattleUI = {}

local ORANGE = Color3.fromRGB(255, 140, 0)
local YELLOW = Color3.fromRGB(255, 255, 0)
local RED = Color3.fromRGB(200, 0, 0)
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local FONT = Enum.Font.Arcade

export type ButtonStyle = "Command" | "Option"

type Ui = {
	gui: ScreenGui,
	box: Frame,
	message: TextLabel,
	options: Frame,
	hpFill: Frame,
	hpText: TextLabel,
	commands: { TextButton },
}

local ui: Ui? = nil

local function label(parent: Instance, text: string, size: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.Text = text
	l.TextSize = size
	l.TextColor3 = WHITE
	l.AutomaticSize = Enum.AutomaticSize.X
	l.Size = UDim2.fromOffset(0, 44)
	l.Parent = parent
	return l
end

local function makeCommandButton(parent: Instance, name: string, order: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.LayoutOrder = order
	b.Size = UDim2.fromOffset(170, 52)
	b.BackgroundColor3 = BLACK
	b.AutoButtonColor = false
	b.Selectable = false -- BattleMenu handles keyboard/gamepad selection
	b.Font = FONT
	b.Text = name
	b.TextSize = 26
	b.TextColor3 = ORANGE
	b:SetAttribute("Style", "Command")
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = ORANGE
	stroke.Thickness = 3
	stroke.Parent = b
	b.Parent = parent
	return b
end

local function build(): Ui
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "BattleUI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Dialogue box, anchored just above the player row so it never overlaps
	-- it, even on short phone screens.
	local box = Instance.new("Frame")
	box.Name = "DialogueBox"
	box.AnchorPoint = Vector2.new(0.5, 1)
	box.Position = UDim2.new(0.5, 0, 1, -152)
	box.Size = UDim2.new(0.9, 0, 0, 130)
	box.BackgroundColor3 = BLACK
	box.Parent = gui
	local boxLimit = Instance.new("UISizeConstraint")
	boxLimit.MaxSize = Vector2.new(640, 130)
	boxLimit.Parent = box
	local boxStroke = Instance.new("UIStroke")
	boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	boxStroke.Color = WHITE
	boxStroke.Thickness = 4
	boxStroke.Parent = box
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 14)
	padding.Parent = box

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.BackgroundTransparency = 1
	message.Size = UDim2.fromScale(1, 1)
	message.Font = FONT
	message.TextSize = 24
	message.TextColor3 = WHITE
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Top
	message.TextWrapped = true
	message.Parent = box

	-- Option list (ACT choices, targets) in two columns inside the box.
	local options = Instance.new("Frame")
	options.Name = "Options"
	options.BackgroundTransparency = 1
	options.Size = UDim2.fromScale(1, 1)
	options.Visible = false
	options.Parent = box
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -8, 0, 44)
	grid.CellPadding = UDim2.fromOffset(16, 6)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = options

	-- Player row: headshot, name, HP bar, HP numbers.
	local row = Instance.new("Frame")
	row.Name = "PlayerRow"
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.new(0.5, 0, 1, -92)
	row.Size = UDim2.fromOffset(0, 44)
	row.AutomaticSize = Enum.AutomaticSize.X
	row.BackgroundTransparency = 1
	row.Parent = gui
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	rowLayout.Padding = UDim.new(0, 12)
	rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
	rowLayout.Parent = row

	local headshot = Instance.new("ImageLabel")
	headshot.Name = "Headshot"
	headshot.LayoutOrder = 1
	headshot.Size = UDim2.fromOffset(44, 44)
	headshot.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	headshot.Parent = row
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok then
			headshot.Image = image
		end
	end)

	label(row, player.DisplayName, 22).LayoutOrder = 2
	label(row, "HP", 20).LayoutOrder = 3

	local hpBar = Instance.new("Frame")
	hpBar.Name = "HPBar"
	hpBar.LayoutOrder = 4
	hpBar.Size = UDim2.fromOffset(120, 22)
	hpBar.BackgroundColor3 = RED
	hpBar.BorderSizePixel = 0
	hpBar.Parent = row
	local hpFill = Instance.new("Frame")
	hpFill.Name = "Fill"
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = YELLOW
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBar

	local hpText = label(row, "", 22)
	hpText.LayoutOrder = 5

	-- Command buttons, centred so the bottom corners stay free.
	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "Commands"
	buttonRow.AnchorPoint = Vector2.new(0.5, 1)
	buttonRow.Position = UDim2.new(0.5, 0, 1, -24)
	buttonRow.Size = UDim2.fromOffset(0, 52)
	buttonRow.AutomaticSize = Enum.AutomaticSize.X
	buttonRow.BackgroundTransparency = 1
	buttonRow.Parent = gui
	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.Padding = UDim.new(0, 24)
	buttonLayout.SortOrder = Enum.SortOrder.LayoutOrder
	buttonLayout.Parent = buttonRow

	local commands = {
		makeCommandButton(buttonRow, "ATTACK", 1),
		makeCommandButton(buttonRow, "ACT", 2),
	}

	return {
		gui = gui,
		box = box,
		message = message,
		options = options,
		hpFill = hpFill,
		hpText = hpText,
		commands = commands,
	}
end

local function getUi(): Ui
	if not ui then
		ui = build()
	end
	return ui :: Ui
end

-- Command buttons, in order: ATTACK, ACT.
function BattleUI.commandButtons(): { TextButton }
	return getUi().commands
end

-- Highlights a button yellow (selected) or back to its normal colour.
function BattleUI.setHighlight(button: TextButton, on: boolean)
	local isOption = button:GetAttribute("Style") == "Option"
	local normal = if isOption then WHITE else ORANGE
	local color = if on then YELLOW else normal
	button.TextColor3 = color
	local stroke = button:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = color
	end
	if isOption then
		local text = button:GetAttribute("Label")
		button.Text = if on then `♥ {text}` else `* {text}`
	end
end

-- Shows a message in the dialogue box (hides any option list).
function BattleUI.setMessage(text: string)
	local u = getUi()
	BattleUI.clearOptions()
	u.message.Text = text
	u.message.Visible = true
end

-- Replaces the message with a list of options and returns their buttons.
function BattleUI.showOptions(labels: { string }): { TextButton }
	local u = getUi()
	BattleUI.clearOptions()
	u.message.Visible = false
	local buttons = {}
	for i, text in labels do
		local b = Instance.new("TextButton")
		b.Name = `Option{i}`
		b.LayoutOrder = i
		b.BackgroundTransparency = 1
		b.AutoButtonColor = false
		b.Selectable = false
		b.Font = FONT
		b.TextSize = 24
		b.TextXAlignment = Enum.TextXAlignment.Left
		b:SetAttribute("Style", "Option")
		b:SetAttribute("Label", text)
		BattleUI.setHighlight(b, false)
		b.Parent = u.options
		table.insert(buttons, b)
	end
	u.options.Visible = true
	return buttons
end

function BattleUI.clearOptions()
	local u = getUi()
	for _, child in u.options:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	u.options.Visible = false
	u.message.Visible = true
end

function BattleUI.setPlayerHP(hp: number, maxHP: number)
	local u = getUi()
	u.hpFill.Size = UDim2.fromScale(math.clamp(hp / maxHP, 0, 1), 1)
	u.hpText.Text = `{hp} / {maxHP}`
end

function BattleUI.show()
	getUi().gui.Enabled = true
end

function BattleUI.hide()
	BattleUI.clearOptions()
	getUi().gui.Enabled = false
end

return BattleUI
