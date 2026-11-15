--!strict
-- Server entry point. Builds the rooms (with their enemies and allies) and
-- puts each player's own avatar in the start room (the village).
-- Battles, talking and following run on the client; the server only does
-- world setup.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Allies = require(ReplicatedStorage.Modules.Allies)
local Config = require(ReplicatedStorage.Modules.Config)
local Enemies = require(ReplicatedStorage.Modules.Enemies)
local RoomTypes = require(ReplicatedStorage.Modules.Rooms.RoomTypes)
local AllyBuilder = require(script.Parent.AllyBuilder)
local EnemyBuilder = require(script.Parent.EnemyBuilder)
local RoomBuilder = require(script.Parent.RoomBuilder)

local ROOMS: { RoomTypes.RoomLayout } = {
	require(ReplicatedStorage.Modules.Rooms.Village),
	require(ReplicatedStorage.Modules.Rooms.Room1),
}

local function makeFolder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function buildRoom(layout: RoomTypes.RoomLayout, parent: Instance): Model
	local room = RoomBuilder.build(layout, parent)

	local enemiesFolder = makeFolder("Enemies", room)
	for _, placement in layout.Enemies do
		local data = Enemies[placement.Id]
		if data then
			EnemyBuilder.spawn(data, RoomBuilder.floorPosition(layout, placement.Offset), enemiesFolder)
		else
			warn(`[Main] {layout.Name}: unknown enemy "{placement.Id}"`)
		end
	end

	local alliesFolder = makeFolder("Allies", room)
	local allies: { RoomTypes.AllyPlacement } = layout.Allies or {}
	for _, placement in allies do
		local data = Allies[placement.Id]
		if data then
			AllyBuilder.spawn(data, RoomBuilder.floorPosition(layout, placement.Offset), alliesFolder)
		else
			warn(`[Main] {layout.Name}: unknown ally "{placement.Id}"`)
		end
	end
	return room
end

local roomsFolder = workspace:WaitForChild("Rooms")
local startRoom: Model? = nil
for _, layout in ROOMS do
	local room = buildRoom(layout, roomsFolder)
	if layout.Name == Config.StartRoom then
		startRoom = room
	end
end
assert(startRoom, `[Main] start room "{Config.StartRoom}" is not in ROOMS`)
local spawnRoom: Model = startRoom

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
	RoomBuilder.placeCharacter(spawnRoom, character)
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

print(`[{Config.GameName}] server running, built {#ROOMS} rooms, start: {spawnRoom.Name}`)
