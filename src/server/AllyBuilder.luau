--!strict
-- Builds possible allies in the village from their data, each with a
-- "Talk" prompt (E key, gamepad button, or tap on touch screens).
-- What happens when you talk is handled on the client (src/client/Village).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AllyTypes = require(ReplicatedStorage.Modules.Allies.AllyTypes)
local Config = require(ReplicatedStorage.Modules.Config)
local AvatarBuilder = require(script.Parent.AvatarBuilder)

local AllyBuilder = {}

function AllyBuilder.spawn(data: AllyTypes.AllyData, floorPosition: Vector3, parent: Instance): Model
	local model = AvatarBuilder.build(data.Id, data.Avatar, data.RigType, floorPosition)
	model:SetAttribute("AllyId", data.Id)

	-- The player walks through allies instead of bumping into them, so a
	-- following ally never blocks a doorway.
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk"
	prompt.ObjectText = data.DisplayName
	prompt.MaxActivationDistance = Config.InteractDistance
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute(Config.AllyPromptAttribute, data.Id)
	prompt.Parent = model:FindFirstChild("HumanoidRootPart")

	model.Parent = parent
	AvatarBuilder.playIdle(model, data.IdleAnimationId)
	return model
end

return AllyBuilder
