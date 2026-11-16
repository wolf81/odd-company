--!strict
-- The enemy's turn: the player's heart dodges bullets inside a square box.
-- Bullets are plain UI Frames spawned by attack patterns (Patterns.luau).
--
-- Moving the heart:
--   keyboard: arrow keys / WASD
--   gamepad:  left stick / D-pad
--   touch:    put a finger down anywhere and drag; the heart moves in the
--             drag direction (a "floating" thumbstick)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Modules.Config)
local BattleUI = require(script.Parent.BattleUI)

local DodgeBox = {}

export type Bullet = {
	gui: Frame,
	pos: Vector2, -- centre, in pixels from the box's top-left corner
	vel: Vector2, -- pixels per second
	size: Vector2,
	owner: number, -- index of the enemy that fired it
	age: number, -- seconds since spawned
	update: ((bullet: Bullet, dt: number) -> ())?,
}

export type BulletSpec = {
	position: Vector2,
	velocity: Vector2,
	size: Vector2,
	color: Color3?,
	-- Optional custom movement, called every frame after the normal
	-- velocity step (e.g. to wobble). May change bullet.pos / bullet.vel.
	update: ((bullet: Bullet, dt: number) -> ())?,
}

-- What a pattern can do. Sizes are in pixels; use `size` (the box's width
-- and height) to scale everything so patterns work on any screen.
export type Api = {
	size: number,
	random: Random,
	running: () -> boolean,
	elapsed: () -> number,
	wait: (seconds: number) -> (),
	spawn: (spec: BulletSpec) -> (),
}

export type Pattern = {
	Duration: number, -- seconds the dodge phase lasts
	Run: (api: Api) -> (),
}

export type Job = {
	owner: number,
	pattern: Pattern,
	-- 1 = normal. Below 1 makes this pattern's bullets slower and fewer,
	-- so several enemies attacking at once stays fair.
	speed: number,
}

local MOVE_KEYS: { [Enum.KeyCode]: Vector2 } = {
	[Enum.KeyCode.Left] = Vector2.new(-1, 0),
	[Enum.KeyCode.A] = Vector2.new(-1, 0),
	[Enum.KeyCode.Right] = Vector2.new(1, 0),
	[Enum.KeyCode.D] = Vector2.new(1, 0),
	[Enum.KeyCode.Up] = Vector2.new(0, -1),
	[Enum.KeyCode.W] = Vector2.new(0, -1),
	[Enum.KeyCode.Down] = Vector2.new(0, 1),
	[Enum.KeyCode.S] = Vector2.new(0, 1),
}
local DPAD: { [Enum.KeyCode]: Vector2 } = {
	[Enum.KeyCode.DPadLeft] = Vector2.new(-1, 0),
	[Enum.KeyCode.DPadRight] = Vector2.new(1, 0),
	[Enum.KeyCode.DPadUp] = Vector2.new(0, -1),
	[Enum.KeyCode.DPadDown] = Vector2.new(0, 1),
}
local STICK_DEADZONE = 0.2
local activeCleanup: (() -> ())? = nil
local TOUCH_DRAG_FULL = 40 -- pixels of drag for full speed

-- Picks a box size that fits the screen: the space between the top of the
-- player row area and roughly the enemy's feet.
local function boxSize(): number
	local viewport = workspace.CurrentCamera.ViewportSize
	local available = viewport.Y - 152 - 110
	return math.floor(math.clamp(available, Config.DodgeBoxMinSize, Config.DodgeBoxMaxSize))
end

-- Distance check between the heart (a circle) and a bullet (a rectangle).
local function overlaps(heart: Vector2, radius: number, b: Bullet): boolean
	local dx = math.max(math.abs(heart.X - b.pos.X) - b.size.X / 2, 0)
	local dy = math.max(math.abs(heart.Y - b.pos.Y) - b.size.Y / 2, 0)
	return dx * dx + dy * dy < radius * radius
end

-- Runs the dodge phase for all `jobs` at once (one per attacking enemy).
-- `onHit(owner)` is called for every hit; return true from it to end the
-- phase early (e.g. the player is out of HP).
-- Returns the hits as a list of enemy indices.
function DodgeBox.run(jobs: { Job }, onHit: (owner: number) -> boolean): { number }
	local size = boxSize()
	local box = BattleUI.showDodgeBox(size)

	local heart = Instance.new("TextLabel")
	heart.Name = "Heart"
	heart.AnchorPoint = Vector2.new(0.5, 0.5)
	heart.Size = UDim2.fromOffset(24, 24)
	heart.BackgroundTransparency = 1
	heart.Font = Enum.Font.SourceSansBold
	heart.Text = "♥"
	heart.TextSize = 28
	heart.TextColor3 = Color3.fromRGB(255, 0, 0)
	heart.ZIndex = 2
	heart.Parent = box

	local heartPos = Vector2.new(size / 2, size / 2)
	local radius = Config.HeartHitRadius
	local speed = Config.HeartSpeed * size
	local bullets: { Bullet } = {}
	local hits: { number } = {}
	local running = true
	local startTime = os.clock()
	local invincibleUntil = 0

	local duration = 0
	for _, job in jobs do
		duration = math.max(duration, job.pattern.Duration)
	end

	-- Input state
	local stick = Vector2.zero
	local touchOrigin: Vector2? = nil
	local touchDir = Vector2.zero
	local connections: { RBXScriptConnection } = {}

	table.insert(connections, UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			local v = Vector2.new(input.Position.X, -input.Position.Y)
			stick = if v.Magnitude > STICK_DEADZONE then v else Vector2.zero
		elseif input.UserInputType == Enum.UserInputType.Touch and touchOrigin then
			local drag = Vector2.new(input.Position.X, input.Position.Y) - touchOrigin
			touchDir = drag / TOUCH_DRAG_FULL
			if touchDir.Magnitude > 1 then
				touchDir = touchDir.Unit
			end
		end
	end))
	table.insert(connections, UserInputService.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			touchOrigin = Vector2.new(input.Position.X, input.Position.Y)
			touchDir = Vector2.zero
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			touchOrigin = nil
			touchDir = Vector2.zero
		end
	end))

	local function inputDirection(): Vector2
		local dir = Vector2.zero
		if not UserInputService:GetFocusedTextBox() then
			for key, v in MOVE_KEYS do
				if UserInputService:IsKeyDown(key) then
					dir += v
				end
			end
		end
		for key, v in DPAD do
			if UserInputService:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, key) then
				dir += v
			end
		end
		dir += stick + touchDir
		if dir.Magnitude > 1 then
			dir = dir.Unit
		end
		return dir
	end

	local done = Instance.new("BindableEvent")
	local function cleanup()
		running = false
		for _, c in connections do
			c:Disconnect()
		end
		table.clear(connections)
		BattleUI.hideDodgeBox()
		if activeCleanup == cleanup then
			activeCleanup = nil
		end
	end
	activeCleanup = cleanup
	local function finish()
		if running then
			cleanup()
			done:Fire()
		end
	end

	-- Start each enemy's pattern in its own thread.
	for _, job in jobs do
		local random = Random.new()
		local api: Api = {
			size = size,
			random = random,
			running = function()
				return running
			end,
			elapsed = function()
				return os.clock() - startTime
			end,
			wait = function(seconds: number)
				task.wait(seconds / job.speed)
			end,
			spawn = function(spec: BulletSpec)
				if not running then
					return
				end
				local gui = Instance.new("Frame")
				gui.AnchorPoint = Vector2.new(0.5, 0.5)
				gui.Size = UDim2.fromOffset(spec.size.X, spec.size.Y)
				gui.Position = UDim2.fromOffset(spec.position.X, spec.position.Y)
				gui.BackgroundColor3 = spec.color or Color3.new(1, 1, 1)
				gui.BorderSizePixel = 0
				gui.Parent = box
				table.insert(bullets, {
					gui = gui,
					pos = spec.position,
					vel = spec.velocity * job.speed,
					size = spec.size,
					owner = job.owner,
					age = 0,
					update = spec.update,
				})
			end,
		}
		task.spawn(job.pattern.Run, api)
	end

	table.insert(connections, RunService.RenderStepped:Connect(function(dt: number)
		if not running then
			return
		end
		local now = os.clock()

		-- Heart
		heartPos += inputDirection() * speed * dt
		heartPos = Vector2.new(math.clamp(heartPos.X, radius + 4, size - radius - 4), math.clamp(heartPos.Y, radius + 4, size - radius - 4))
		heart.Position = UDim2.fromOffset(heartPos.X, heartPos.Y)
		local invincible = now < invincibleUntil
		-- Blink while invincible.
		heart.TextTransparency = if invincible and math.floor(now * 12) % 2 == 0 then 0.7 else 0

		-- Bullets
		local margin = 60
		for i = #bullets, 1, -1 do
			local b = bullets[i]
			b.age += dt
			b.pos += b.vel * dt
			if b.update then
				b.update(b, dt)
			end
			b.gui.Position = UDim2.fromOffset(b.pos.X, b.pos.Y)

			local outside = b.pos.X < -margin or b.pos.X > size + margin or b.pos.Y < -margin or b.pos.Y > size + margin
			if outside then
				b.gui:Destroy()
				table.remove(bullets, i)
			elseif not invincible and overlaps(heartPos, radius, b) then
				invincible = true
				invincibleUntil = now + Config.InvincibilityTime
				table.insert(hits, b.owner)
				if onHit(b.owner) then
					finish()
					return
				end
			end
		end

		if now - startTime >= duration then
			finish()
		end
	end))

	done.Event:Wait()
	return hits
end

-- Stops a running dodge phase immediately (e.g. the battle was cancelled).
function DodgeBox.cancel()
	if activeCleanup then
		activeCleanup()
	end
end

return DodgeBox
