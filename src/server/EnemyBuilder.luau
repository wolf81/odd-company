--!strict
-- Builds enemy avatars from their data (HumanoidDescription) and places
-- them in a room, each with an invisible trigger box that starts a battle.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local EnemyTypes = require(ReplicatedStorage.Modules.Enemies.EnemyTypes)
local Placement = require(ReplicatedStorage.Modules.Placement)

local EnemyBuilder = {}

local function buildDescription(data: EnemyTypes.EnemyData): HumanoidDescription
	local description = Instance.new("HumanoidDescription")
	for property, value in data.Avatar do
		local ok, err = pcall(function()
			(description :: any)[property] = value
		end)
		if not ok then
			warn(`[EnemyBuilder] {data.Id}: could not set {property}: {err}`)
		end
	end
	return description
end

local function playIdle(model: Model, animationId: string)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
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

-- Creates the enemy standing on `floorPosition`, facing south (toward the
-- camera), and parents it to `parent`. Returns the enemy model.
function EnemyBuilder.spawn(data: EnemyTypes.EnemyData, floorPosition: Vector3, parent: Instance): Model
	local model = Players:CreateHumanoidModelFromDescription(buildDescription(data), data.RigType)
	model.Name = data.Id
	model:SetAttribute("EnemyId", data.Id)

	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- no name/health bar
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	root.Anchored = true -- stands still; animations still play

	-- Feet on the floor, facing south (+Z, toward the camera).
	Placement.standOnFloor(model, floorPosition, Vector3.new(0, 0, 1))

	-- Invisible box a bit larger than the avatar. Touching it starts the
	-- battle, so even a big avatar triggers it before getting stuck.
	local boxCFrame, boxSize = model:GetBoundingBox()
	local trigger = Instance.new("Part")
	trigger.Name = "EncounterTrigger"
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.CanQuery = false
	trigger.Transparency = 1
	trigger.Size = boxSize + Vector3.new(2, 0, 2) * Config.EncounterTriggerPadding
	trigger.CFrame = boxCFrame
	trigger:SetAttribute("EnemyId", data.Id)
	CollectionService:AddTag(trigger, Config.EnemyTriggerTag)
	trigger.Parent = model

	model.Parent = parent

	if data.IdleAnimationId then
		playIdle(model, data.IdleAnimationId)
	end
	return model
end

return EnemyBuilder
