--!strict
-- Elliot: a hungry pizza delivery guy in the village. Joins once you bring
-- him the Pizza slice from the chest. Placeholder look from body colours:
-- red shirt, black trousers. TODO: look up catalog IDs for a red cap and
-- delivery uniform once and add them to Avatar (see PLAN.md, Allies).

local AllyTypes = require(script.Parent.AllyTypes)

local SKIN = Color3.fromRGB(234, 184, 146) -- "Light orange"
local RED = Color3.fromRGB(196, 40, 28) -- "Bright red"
local BLACK = Color3.fromRGB(27, 42, 53) -- "Black"

local elliot: AllyTypes.AllyData = {
	Id = "Elliot",
	DisplayName = "Elliot",
	RigType = Enum.HumanoidRigType.R15,
	Avatar = {
		HeadColor = SKIN,
		LeftArmColor = RED,
		RightArmColor = RED,
		TorsoColor = RED,
		LeftLegColor = BLACK,
		RightLegColor = BLACK,
	},
	IdleAnimationId = "rbxassetid://507766388", -- Roblox's standard R15 idle
	WalkAnimationId = "rbxassetid://507777826", -- Roblox's standard R15 walk
	Wants = "Pizza slice",
	Lines = {
		Greeting = {
			"* Elliot: I'm sooo hungry...",
			"* Elliot: I delivered pizzas all day and didn't get to eat a single one.",
		},
		NeedItem = "* Elliot: If only someone had a slice of pizza...",
		OfferItem = "* Give Elliot the Pizza slice?",
		Thanks = {
			"* Elliot eats the pizza in one bite.",
			"* Elliot: You're a lifesaver!",
		},
		Ask = "* Elliot: Can I come with you? I know how to throw a pizza.",
		Joined = "* Elliot joined you!",
		Declined = "* Elliot: Okay... the offer stands!",
		Leave = "* Elliot: No problem. I'll go grab another slice.",
	},
	-- From the nephew: throws a hot pizza slice that hurts for 2 rounds,
	-- then needs 3 rounds to cool down.
	Ability = {
		Name = "Hot Pizza",
		Button = "PIZZA",
		Text = "* Elliot throws a hot pizza slice!",
		Damage = 8,
		MaxTargets = 1,
		Rounds = 2,
		Cooldown = 3,
	},
}

return elliot
