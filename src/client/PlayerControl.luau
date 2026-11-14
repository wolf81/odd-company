--!strict
-- Freezes and unfreezes the local player's avatar (used during battles).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Placement = require(ReplicatedStorage.Modules.Placement)

local PlayerControl = {}

local function getControls(): any
	-- Roblox's built-in PlayerModule handles keyboard, gamepad and the
	-- mobile thumbstick. Disabling its controls also hides the thumbstick.
	local playerModule = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule") :: ModuleScript) :: any
	return playerModule:GetControls()
end

local function getRoot(): BasePart?
	local character = Players.LocalPlayer.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function PlayerControl.freeze()
	getControls():Disable()
	local root = getRoot()
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.Anchored = true
	end
end

function PlayerControl.unfreeze()
	local root = getRoot()
	if root then
		root.Anchored = false
	end
	getControls():Enable()
end

-- Puts the avatar standing on the floor at `floorPosition`, facing north.
function PlayerControl.moveTo(floorPosition: Vector3)
	local character = Players.LocalPlayer.Character
	if character then
		Placement.standOnFloor(character, floorPosition, Vector3.new(0, 0, -1), 0.2)
	end
end

-- Moves the avatar `distance` studs directly away from `fromPosition`
-- (flat, along the floor).
function PlayerControl.pushAwayFrom(fromPosition: Vector3, distance: number)
	local character = Players.LocalPlayer.Character
	local root = getRoot()
	if not character or not root then
		return
	end
	local away = root.Position - fromPosition
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 0.01 then
		away = Vector3.new(0, 0, 1) -- default: south, toward the camera
	end
	character:PivotTo(character:GetPivot() + away.Unit * distance)
end

return PlayerControl
