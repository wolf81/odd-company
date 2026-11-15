--!strict
-- Builds an avatar rig (enemy or ally) from a table of HumanoidDescription
-- properties and stands it on the floor. Used by EnemyBuilder and AllyBuilder.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Placement = require(ReplicatedStorage.Modules.Placement)

local AvatarBuilder = {}

local function buildDescription(id: string, avatar: { [string]: any }): HumanoidDescription
	local description = Instance.new("HumanoidDescription")
	for property, value in avatar do
		local ok, err = pcall(function()
			(description :: any)[property] = value
		end)
		if not ok then
			warn(`[AvatarBuilder] {id}: could not set {property}: {err}`)
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

-- Creates the avatar standing on `floorPosition`, facing south (toward the
-- camera), anchored so it never walks or falls by itself. Not parented yet.
function AvatarBuilder.build(id: string, avatar: { [string]: any }, rigType: Enum.HumanoidRigType, floorPosition: Vector3): Model
	local model = Players:CreateHumanoidModelFromDescription(buildDescription(id, avatar), rigType)
	model.Name = id

	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- no name/health bar
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	root.Anchored = true -- stands still; animations still play

	Placement.standOnFloor(model, floorPosition, Vector3.new(0, 0, 1))
	return model
end

-- Starts the looping idle animation. Call after the model is parented.
function AvatarBuilder.playIdle(model: Model, animationId: string?)
	if animationId then
		playIdle(model, animationId)
	end
end

return AvatarBuilder
