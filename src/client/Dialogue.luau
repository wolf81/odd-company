--!strict
-- Dialogue box for talking in rooms (village): a black box at the bottom
-- with white text, like the battle's dialogue box. Lines wait for a
-- confirm; questions show options (e.g. Yes / No) to pick from.
--
-- Input is the same as in battle (BattleMenu): mouse, touch, keyboard
-- (arrows/WASD, Z/Enter/Space/E to confirm, X/Backspace for "no") and
-- gamepad. While the box is open the player stands still and the
-- Talk/Open prompts are hidden.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local BattleMenu = require(script.Parent.Battle.BattleMenu)
local BattleUI = require(script.Parent.Battle.BattleUI)
local PlayerControl = require(script.Parent.PlayerControl)

local Dialogue = {}

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local FONT = Enum.Font.Arcade

type Ui = {
	gui: ScreenGui,
	message: TextLabel,
	options: Frame,
}

local ui: Ui? = nil
local open = false

local function build(): Ui
	local gui = Instance.new("ScreenGui")
	gui.Name = "Dialogue"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Centred at the bottom, at most 640 px wide.
	local box = Instance.new("Frame")
	box.Name = "Box"
	box.AnchorPoint = Vector2.new(0.5, 1)
	box.Position = UDim2.new(0.5, 0, 1, -24)
	box.Size = UDim2.new(0.9, 0, 0, 150)
	box.BackgroundColor3 = BLACK
	box.Parent = gui
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(640, 150)
	limit.Parent = box
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = WHITE
	stroke.Thickness = 4
	stroke.Parent = box
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)
	padding.PaddingTop = UDim.new(0, 14)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.Parent = box

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.BackgroundTransparency = 1
	message.Size = UDim2.new(1, 0, 1, -48)
	message.Font = FONT
	message.TextSize = 24
	message.TextColor3 = WHITE
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextYAlignment = Enum.TextYAlignment.Top
	message.TextWrapped = true
	message.Parent = box

	-- Answer buttons in a row along the bottom of the box.
	local options = Instance.new("Frame")
	options.Name = "Options"
	options.AnchorPoint = Vector2.new(0, 1)
	options.Position = UDim2.fromScale(0, 1)
	options.Size = UDim2.new(1, 0, 0, 44)
	options.BackgroundTransparency = 1
	options.Parent = box
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 16) -- room for 4 answers (3 allies + Cancel)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = options

	return { gui = gui, message = message, options = options }
end

local function getUi(): Ui
	if not ui then
		ui = build()
	end
	return ui :: Ui
end

local function clearOptions()
	for _, child in getUi().options:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
end

-- Option buttons look like the battle's ACT options ("* Yes" / "♥ Yes").
local function makeOption(text: string, order: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = text
	b.LayoutOrder = order
	b.Size = UDim2.fromOffset(120, 44)
	b.BackgroundTransparency = 1
	b.AutoButtonColor = false
	b.Selectable = false
	b.Font = FONT
	b.TextSize = 24
	b.TextXAlignment = Enum.TextXAlignment.Left
	b:SetAttribute("Style", "Option")
	b:SetAttribute("Label", text)
	BattleUI.setHighlight(b, false)
	b.Parent = getUi().options
	return b
end

function Dialogue.isOpen(): boolean
	return open
end

function Dialogue.open()
	open = true
	PlayerControl.freeze()
	ProximityPromptService.Enabled = false
	getUi().gui.Enabled = true
end

function Dialogue.close()
	clearOptions()
	getUi().gui.Enabled = false
	ProximityPromptService.Enabled = true
	PlayerControl.unfreeze()
	open = false
end

-- Shows one line and waits until the player confirms.
function Dialogue.say(text: string)
	clearOptions()
	getUi().message.Text = text
	BattleMenu.waitForConfirm()
end

function Dialogue.sayAll(lines: { string })
	for _, line in lines do
		Dialogue.say(line)
	end
end

-- Shows a question with answers to pick from. Returns the chosen index,
-- or nil if the player pressed back.
function Dialogue.ask(text: string, answers: { string }): number?
	clearOptions()
	getUi().message.Text = text
	local buttons = {}
	for i, answer in answers do
		table.insert(buttons, makeOption(answer, i))
	end
	local choice = BattleMenu.choose(buttons, #buttons, true)
	clearOptions()
	return choice
end

-- Yes / No question. Back counts as No.
function Dialogue.yesNo(text: string): boolean
	return Dialogue.ask(text, { "Yes", "No" }) == 1
end

return Dialogue
