--!strict
-- The Noob: your childhood friend in the village. Joins straight away, no
-- quest. Classic blocky R6 look: yellow head and arms, blue torso, green legs.

local AllyTypes = require(script.Parent.AllyTypes)

local YELLOW = Color3.fromRGB(245, 205, 48) -- "Bright yellow"
local BLUE = Color3.fromRGB(13, 105, 172) -- "Bright blue"
local GREEN = Color3.fromRGB(164, 189, 71) -- "Br. yellowish green"

local noob: AllyTypes.AllyData = {
	Id = "Noob",
	DisplayName = "Noob",
	RigType = Enum.HumanoidRigType.R6,
	Avatar = {
		HeadColor = YELLOW,
		LeftArmColor = YELLOW,
		RightArmColor = YELLOW,
		TorsoColor = BLUE,
		LeftLegColor = GREEN,
		RightLegColor = GREEN,
	},
	IdleAnimationId = "rbxassetid://180435571", -- Roblox's standard R6 idle
	WalkAnimationId = "rbxassetid://180426354", -- Roblox's standard R6 walk
	Wants = nil,
	Lines = {
		Greeting = {
			"* Noob: Hey, it's me! Your old friend!",
			"* Noob: Remember when we got stuck on that obby for three days?",
		},
		Ask = "* Noob: Can I come with you?",
		Joined = "* Noob joined you!",
		Declined = "* Noob: Aw... I'll be right here if you change your mind.",
		Leave = "* Noob: Okay! I'll wait for you back in the village.",
	},
	-- From the nephew: shakes a cola that explodes and hits up to 2 enemies.
	-- No cooldown, so it hits softer than a good timing-bar attack.
	Ability = {
		Name = "Shaken Cola",
		Button = "COLA",
		Text = "* Noob shakes a cola really, really hard...\n* KABOOM!",
		Damage = 3,
		MaxTargets = 2,
		Rounds = 1,
		Cooldown = 0,
	},
}

return noob
