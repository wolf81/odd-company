--!strict
-- Server entry point. Builds the world (terrain, villages, scenery), puts
-- the fixed enemies and the allies in it, makes templates of every enemy
-- for random fights, and puts each player's own avatar in the start village.
-- Battles, talking, following and random fights run on the client; the
-- server only does world setup.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Allies = require(ReplicatedStorage.Modules.Allies)
local Config = require(ReplicatedStorage.Modules.Config)
local Enemies = require(ReplicatedStorage.Modules.Enemies)
local World = require(ReplicatedStorage.Modules.World)
local Areas = require(ReplicatedStorage.Modules.World.Areas)
local Ground = require(ReplicatedStorage.Modules.World.Ground)
local AllyBuilder = require(script.Parent.AllyBuilder)
local EnemyBuilder = require(script.Parent.EnemyBuilder)
local WorldBuilder = require(script.Parent.WorldBuilder)

local function makeFolder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local worldFolder = WorldBuilder.build(World)

-- Enemies standing at fixed spots (the bridge, the forest gate).
local enemiesFolder = makeFolder("Enemies", worldFolder)
for _, placement in World.FixedEnemies do
	local data = Enemies[placement.Id]
	if data then
		EnemyBuilder.spawn(data, Ground.at(placement.Position), enemiesFolder, placement.Group)
	else
		warn(`[Main] unknown enemy "{placement.Id}"`)
	end
end

-- Allies waiting in the villages.
local alliesFolder = makeFolder("Allies", worldFolder)
for _, village in World.Villages do
	for _, placement in village.Allies do
		local data = Allies[placement.Id]
		if data then
			AllyBuilder.spawn(data, Ground.at(placement.Position), alliesFolder)
		else
			warn(`[Main] {village.Name}: unknown ally "{placement.Id}"`)
		end
	end
end

-- One copy of every enemy in ReplicatedStorage, so the client can show
-- them in random fights.
EnemyBuilder.buildTemplates(Enemies, makeFolder(Config.EnemyTemplatesFolder, ReplicatedStorage))

local startVillage = Areas.village(World.StartVillage)
assert(startVillage, `[Main] start village "{World.StartVillage}" is not in World.Villages`)
local spawnPosition = startVillage.Spawn

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
	WorldBuilder.placeCharacter(character, spawnPosition)
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

print(`[{Config.GameName}] server running, built the world, start: {World.StartVillage}`)
