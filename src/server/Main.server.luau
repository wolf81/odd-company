--!strict
-- Server entry point. Builds the room and puts each player's own avatar in it.
-- The MVP battle will run on the client; the server only does world setup.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local Room1 = require(ReplicatedStorage.Modules.Rooms.Room1)
local RoomBuilder = require(script.Parent.RoomBuilder)

local roomsFolder = workspace:WaitForChild("Rooms")
local room1 = RoomBuilder.build(Room1, roomsFolder)

local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	character:WaitForChild("HumanoidRootPart")

	if not Config.AllowJumping then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = 0
	end

	-- Wait one frame so the avatar's accessories are attached before we
	-- measure its height for placement.
	task.wait()
	RoomBuilder.placeCharacter(room1, character)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

print(`[{Config.GameName}] server running, built {room1.Name}`)
