--!strict
-- Pokémon-style random fights: while you walk anywhere that isn't a road
-- or a village, every few studs there's a small chance a battle starts.
-- Which enemies show up depends on where you are (World.Zones, e.g. the
-- forest is harder). Tuning numbers are in Config (RandomEncounter...).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Areas = require(ReplicatedStorage.Modules.World.Areas)
local Config = require(ReplicatedStorage.Modules.Config)
local Battle = require(script.Parent.Battle)
local Dialogue = require(script.Parent.Dialogue)

local RandomEncounters = {}

local random = Random.new()
local lastPosition: Vector3? = nil
local walked = 0 -- studs walked in the wild since the last dice roll
local grace = Config.RandomEncounterGrace -- studs to walk before fights can start

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function update()
	-- No fights while another fight or a conversation is going on, and a
	-- fresh grace distance after every battle.
	if Battle.isActive() or Dialogue.isOpen() then
		lastPosition = nil
		grace = Config.RandomEncounterGrace
		return
	end
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end

	local position = flat(root.Position)
	local moved = if lastPosition then (position - lastPosition).Magnitude else 0
	lastPosition = position
	if moved > 20 then
		return -- teleported (respawn, lost a battle): that isn't walking
	end
	if Areas.isSafe(root.Position) then
		walked = 0
		return
	end
	if grace > 0 then
		grace = math.max(0, grace - moved)
		return
	end

	walked += moved
	while walked >= Config.RandomEncounterStep do
		walked -= Config.RandomEncounterStep
		if random:NextNumber() < Config.RandomEncounterChance then
			walked = 0
			local enemies = Areas.pickEncounter(Areas.encounterPool(root.Position), random)
			task.spawn(Battle.startWild, enemies)
			return
		end
	end
end

function RandomEncounters.start()
	RunService.Heartbeat:Connect(update)
end

return RandomEncounters
