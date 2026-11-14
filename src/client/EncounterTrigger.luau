--!strict
-- Watches every enemy trigger box and calls back when the local player's
-- avatar touches one. Battle logic is client-only for the MVP, so this
-- runs on the client too.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)

local EncounterTrigger = {}

local enabled = true
local lastTriggered: { [string]: number } = {}

-- `onEncounter(enemyId, enemyModel)` is called once per touch, with a
-- cooldown per enemy so one bump doesn't start several battles.
function EncounterTrigger.start(onEncounter: (enemyId: string, enemyModel: Model) -> ())
	local function watch(trigger: Instance)
		if not trigger:IsA("BasePart") then
			return
		end
		trigger.Touched:Connect(function(hit: BasePart)
			local character = Players.LocalPlayer.Character
			if not enabled or not character or not hit:IsDescendantOf(character) then
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then
				return
			end

			local enemyId = trigger:GetAttribute("EnemyId")
			local enemyModel = trigger.Parent
			if typeof(enemyId) ~= "string" or not enemyModel or not enemyModel:IsA("Model") then
				return
			end

			local now = os.clock()
			if now - (lastTriggered[enemyId] or -math.huge) < Config.EncounterCooldown then
				return
			end
			lastTriggered[enemyId] = now
			onEncounter(enemyId, enemyModel)
		end)
	end

	for _, trigger in CollectionService:GetTagged(Config.EnemyTriggerTag) do
		watch(trigger)
	end
	CollectionService:GetInstanceAddedSignal(Config.EnemyTriggerTag):Connect(watch)
end

-- The battle (step 3) turns triggers off while a fight is running.
function EncounterTrigger.setEnabled(on: boolean)
	enabled = on
end

return EncounterTrigger
