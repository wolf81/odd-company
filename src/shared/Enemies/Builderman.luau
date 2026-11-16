--!strict
-- Builderman: blocks the bridge (and, with a friend, the forest gate), and
-- shows up in random fights.
-- Placeholder look from body colours only: brown skin, orange work vest,
-- dark trousers. TODO: look up the catalog IDs for his hard hat and
-- construction outfit once and add them to Avatar (see PLAN.md roster).

local EnemyTypes = require(script.Parent.EnemyTypes)

local SKIN = Color3.fromRGB(124, 92, 70) -- "Brown"
local VEST = Color3.fromRGB(218, 133, 65) -- "Bright orange"
local TROUSERS = Color3.fromRGB(39, 70, 45) -- "Earth green"

local builderman: EnemyTypes.EnemyData = {
	Id = "Builderman",
	DisplayName = "Builderman",
	Description = "Built half of Roblox. Wants to build a wall right here.",
	FlavorText = {
		"* Builderman blocks the way!",
		"* Builderman is measuring the room.",
		"* Builderman taps his hard hat.",
		"* Smells like fresh bricks.",
	},
	AttackText = "* Builderman throws a pile of bricks at you!",
	-- Same block patterns the Noob had; Patterns.luau colours them as bricks.
	AttackPatterns = { "FallingBlocks", "SideBlocks", "BlockRows" },
	Acts = {
		{ Name = "Compliment", Message = "* You tell Builderman his walls are very straight.\n* Builderman stands a little taller." },
		{ Name = "Help", Message = "* You hand Builderman a brick.\n* He puts it in the wrong place on purpose. Rude." },
	},
	RigType = Enum.HumanoidRigType.R15,
	Avatar = {
		HeadColor = SKIN,
		LeftArmColor = SKIN,
		RightArmColor = SKIN,
		TorsoColor = VEST,
		LeftLegColor = TROUSERS,
		RightLegColor = TROUSERS,
	},
	IdleAnimationId = "rbxassetid://507766388", -- Roblox's standard R15 idle
	-- Still the tutorial fight, but a bit tougher than the Noob was
	-- (HP 20, ATK 4): takes ~5 normal hits, and 4 hits on you lose a fight.
	Stats = { HP = 30, ATK = 5, DEF = 0 },
	-- Tougher than Bacon girl, so he pays better.
	Reward = { GoldChance = 0.75, GoldMin = 4, GoldMax = 9 },
}

return builderman
