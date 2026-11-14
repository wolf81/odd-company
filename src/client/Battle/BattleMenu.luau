--!strict
-- Battle input: choosing from a set of buttons and confirming messages.
-- Works with mouse, touch, keyboard and gamepad:
--   move:    arrow keys / WASD / D-pad      (or hover with the mouse)
--   confirm: Z / Enter / Space / gamepad A  (or click / tap)
--   back:    X / Backspace / gamepad B

local UserInputService = game:GetService("UserInputService")

local BattleUI = require(script.Parent.BattleUI)

local BattleMenu = {}

local CONFIRM_KEYS = {
	[Enum.KeyCode.Z] = true,
	[Enum.KeyCode.Return] = true,
	[Enum.KeyCode.KeypadEnter] = true,
	[Enum.KeyCode.Space] = true,
	[Enum.KeyCode.ButtonA] = true,
}
local BACK_KEYS = {
	[Enum.KeyCode.X] = true,
	[Enum.KeyCode.Backspace] = true,
	[Enum.KeyCode.ButtonB] = true,
}
local MOVE_KEYS: { [Enum.KeyCode]: Vector2 } = {
	[Enum.KeyCode.Left] = Vector2.new(-1, 0),
	[Enum.KeyCode.A] = Vector2.new(-1, 0),
	[Enum.KeyCode.DPadLeft] = Vector2.new(-1, 0),
	[Enum.KeyCode.Right] = Vector2.new(1, 0),
	[Enum.KeyCode.D] = Vector2.new(1, 0),
	[Enum.KeyCode.DPadRight] = Vector2.new(1, 0),
	[Enum.KeyCode.Up] = Vector2.new(0, -1),
	[Enum.KeyCode.W] = Vector2.new(0, -1),
	[Enum.KeyCode.DPadUp] = Vector2.new(0, -1),
	[Enum.KeyCode.Down] = Vector2.new(0, 1),
	[Enum.KeyCode.S] = Vector2.new(0, 1),
	[Enum.KeyCode.DPadDown] = Vector2.new(0, 1),
}

-- Connections of whatever is currently waiting for input, so a battle that
-- ends early (e.g. respawn) can clean up with BattleMenu.cancel().
local active: { RBXScriptConnection } = {}
local wake: BindableEvent? = nil

local function cleanup()
	for _, c in active do
		c:Disconnect()
	end
	table.clear(active)
	wake = nil
end

function BattleMenu.cancel()
	local w = wake
	cleanup()
	if w then
		w:Fire(nil)
	end
end

-- Lets the player pick one of `buttons`, laid out in `columns` columns.
-- Returns the chosen index, or nil if they pressed back (only when
-- `allowBack` is true).
function BattleMenu.choose(buttons: { TextButton }, columns: number, allowBack: boolean): number?
	cleanup()
	local index = 1
	local event = Instance.new("BindableEvent")
	wake = event

	local function highlight()
		for i, b in buttons do
			BattleUI.setHighlight(b, i == index)
		end
	end
	highlight()

	for i, b in buttons do
		table.insert(active, b.MouseEnter:Connect(function()
			index = i
			highlight()
		end))
		table.insert(active, b.Activated:Connect(function()
			event:Fire(i)
		end))
	end

	table.insert(active, UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
			return -- e.g. typing in chat
		end
		local key = input.KeyCode
		local move = MOVE_KEYS[key]
		if move then
			local step = move.X + move.Y * columns
			local nextIndex = index + step
			if nextIndex >= 1 and nextIndex <= #buttons then
				index = nextIndex
				highlight()
			end
		elseif CONFIRM_KEYS[key] then
			event:Fire(index)
		elseif allowBack and BACK_KEYS[key] then
			event:Fire(nil)
		end
	end))

	local chosen = event.Event:Wait()
	cleanup()
	for _, b in buttons do
		BattleUI.setHighlight(b, false)
	end
	return chosen
end

-- Waits until the player confirms (key, click or tap anywhere).
function BattleMenu.waitForConfirm()
	cleanup()
	local event = Instance.new("BindableEvent")
	wake = event
	-- Ignore input for a moment so the press that triggered this message
	-- doesn't skip it straight away.
	local readyAt = os.clock() + 0.2
	table.insert(active, UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if os.clock() < readyAt then
			return
		end
		local isPointer = input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		if isPointer or (CONFIRM_KEYS[input.KeyCode] and not gameProcessed) then
			event:Fire()
		end
	end))
	event.Event:Wait()
	cleanup()
end

return BattleMenu
