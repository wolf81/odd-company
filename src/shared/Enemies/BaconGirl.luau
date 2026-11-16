--!strict
-- Bacon girl: a wild enemy in random fights out in the world.
-- Placeholder look from body colours only: default-style skin, pink top,
-- dark blue trousers. TODO: look up the catalog ID of the bacon hair once
-- and add it to Avatar (HairAccessory), see PLAN.md roster.

local EnemyTypes = require(script.Parent.EnemyTypes)

local SKIN = Color3.fromRGB(234, 184, 146) -- "Light orange"
local TOP = Color3.fromRGB(255, 152, 220) -- "Carnation pink"
local TROUSERS = Color3.fromRGB(33, 84, 185) -- "Bright blue"

local baconGirl: EnemyTypes.EnemyData = {
	Id = "BaconGirl",
	DisplayName = "Bacon girl",
	Description = "Brand new account. Brand new hair. Very proud of both.",
	FlavorText = {
		"* Bacon girl flips her hair.",
		"* Bacon girl is asking everyone for free items.",
		"* Smells like breakfast.",
		"* Bacon girl practises her emotes.",
	},
	AttackText = "* Bacon girl throws sizzling bacon strips!",
	AttackPatterns = { "BaconZigzag", "BaconSweep" },
	Acts = {
		{ Name = "Compliment", Message = "* You tell Bacon girl her hair looks crispy.\n* She blushes. Or is that grease?" },
		{ Name = "Pancakes", Message = "* You offer Bacon girl pancakes.\n* She says bacon goes better with pancakes. Fair." },
	},
	RigType = Enum.HumanoidRigType.R15,
	Avatar = {
		HeadColor = SKIN,
		LeftArmColor = SKIN,
		RightArmColor = SKIN,
		TorsoColor = TOP,
		LeftLegColor = TROUSERS,
		RightLegColor = TROUSERS,
	},
	IdleAnimationId = "rbxassetid://507766388", -- Roblox's standard R15 idle
	-- A bit weaker than Builderman, since you meet her often.
	Stats = { HP = 22, ATK = 4, DEF = 0 },
	Reward = { GoldChance = 0.6, GoldMin = 1, GoldMax = 5 },
}

return baconGirl
