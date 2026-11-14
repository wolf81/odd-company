--!strict
-- The dark arena where battles are shown. Built on the client only, so
-- each player sees their own battle. The camera looks at a copy of the
-- enemy standing on a black stage in front of a black wall.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Modules.Config)

local BattleArena = {}

local arena: Model? = nil
local currentEnemy: Model? = nil

local BLACK = Color3.new(0, 0, 0)

local function makePart(name: string, size: Vector3, cframe: CFrame, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = BLACK
	part.Material = Enum.Material.SmoothPlastic
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function getArena(): Model
	if arena and arena.Parent then
		return arena
	end
	local model = Instance.new("Model")
	model.Name = "BattleArena"
	local origin = Config.BattleArenaPosition
	-- Stage the enemy stands on; its top is at origin.Y.
	local floor = makePart("Floor", Vector3.new(120, 1, 120), CFrame.new(origin - Vector3.new(0, 0.5, 0)), model)
	model.PrimaryPart = floor
	-- Wall behind the enemy fills the background, so no sky is visible.
	makePart("BackWall", Vector3.new(160, 100, 1), CFrame.new(origin + Vector3.new(0, 40, -12)), model)
	model.Parent = workspace
	arena = model
	return model
end

local function playIdle(model: Model, animationId: string)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if ok and track then
		track.Looped = true
		track:Play()
	end
end

-- Puts a copy of `enemyModel` on the stage, facing the camera, and
-- returns the camera CFrame that frames it in the top half of the screen.
function BattleArena.show(enemyModel: Model, idleAnimationId: string?): CFrame
	BattleArena.hide()
	local stage = getArena()

	local copy = enemyModel:Clone()
	local trigger = copy:FindFirstChild("EncounterTrigger")
	if trigger then
		trigger:Destroy()
	end

	-- Stand on the stage at the origin, facing south (+Z) toward the camera.
	local origin = Config.BattleArenaPosition
	copy:PivotTo(CFrame.lookAt(origin, origin + Vector3.new(0, 0, 1)))
	local boxCFrame, boxSize = copy:GetBoundingBox()
	local bottomY = boxCFrame.Position.Y - boxSize.Y / 2
	copy:PivotTo(copy:GetPivot() + Vector3.new(0, origin.Y - bottomY, 0))
	copy.Parent = stage
	currentEnemy = copy

	if idleAnimationId then
		playIdle(copy, idleAnimationId)
	end

	-- Aim below the enemy's middle so the enemy sits in the top half of
	-- the screen, leaving room for the dialogue/dodge box and buttons.
	local _, size = copy:GetBoundingBox()
	local enemyMiddle = origin + Vector3.new(0, size.Y / 2, 0)
	local lookAt = enemyMiddle - Vector3.new(0, size.Y * 0.55, 0)
	local cameraPosition = enemyMiddle + Vector3.new(0, 0, Config.BattleCameraDistance)
	return CFrame.lookAt(cameraPosition, lookAt)
end

-- Shows a hit on the enemy: red flash, shake and a rising damage number
-- ("MISS" when damage is 0). If `defeated`, the enemy then fades away.
-- Waits until the effect is done.
function BattleArena.showHit(damage: number, defeated: boolean)
	local enemy = currentEnemy
	if not enemy then
		return
	end
	local _, size = enemy:GetBoundingBox()

	-- Damage number above the enemy's head.
	local billboard = Instance.new("BillboardGui")
	local adornee = enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")
	if adornee then
		billboard.Adornee = adornee
	end
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(160, 60)
	billboard.StudsOffset = Vector3.new(0, size.Y / 2, 0)
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.Arcade
	text.TextSize = 44
	text.Text = if damage > 0 then tostring(damage) else "MISS"
	text.TextColor3 = if damage > 0 then Color3.fromRGB(255, 40, 40) else Color3.fromRGB(190, 190, 190)
	text.TextStrokeTransparency = 0
	text.Parent = billboard
	billboard.Parent = enemy
	TweenService:Create(billboard, TweenInfo.new(0.7), { StudsOffset = billboard.StudsOffset + Vector3.new(0, 1.5, 0) }):Play()

	if damage > 0 then
		-- Red flash.
		local highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(255, 0, 0)
		highlight.FillTransparency = 0.3
		highlight.OutlineTransparency = 1
		highlight.Parent = enemy
		TweenService:Create(highlight, TweenInfo.new(0.5), { FillTransparency = 1 }):Play()

		-- Shake left and right.
		local home = enemy:GetPivot()
		for i = 1, 6 do
			local offset = (if i % 2 == 0 then 1 else -1) * 0.35 * (1 - i / 7)
			enemy:PivotTo(home * CFrame.new(offset, 0, 0))
			task.wait(0.05)
		end
		enemy:PivotTo(home)
		task.wait(0.4)
		highlight:Destroy()
	else
		task.wait(0.7)
	end
	billboard:Destroy()

	if defeated then
		local tweens = {}
		for _, d in enemy:GetDescendants() do
			if d:IsA("BasePart") and d.Transparency < 1 then
				table.insert(tweens, TweenService:Create(d, TweenInfo.new(0.8), { Transparency = 1 }))
			elseif d:IsA("Decal") then
				table.insert(tweens, TweenService:Create(d, TweenInfo.new(0.8), { Transparency = 1 }))
			end
		end
		for _, t in tweens do
			t:Play()
		end
		task.wait(0.8)
	end
end

function BattleArena.hide()
	if currentEnemy then
		currentEnemy:Destroy()
		currentEnemy = nil
	end
end

return BattleArena
