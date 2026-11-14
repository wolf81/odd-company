--!strict
-- The Noob: room 1's enemy and the weakest fight. Classic blocky R6 look
-- with yellow head and arms, blue torso, green legs.

local EnemyTypes = require(script.Parent.EnemyTypes)

local YELLOW = Color3.fromRGB(245, 205, 48) -- "Bright yellow"
local BLUE = Color3.fromRGB(13, 105, 172) -- "Bright blue"
local GREEN = Color3.fromRGB(164, 189, 71) -- "Br. yellowish green"

local noob: EnemyTypes.EnemyData = {
	Id = "Noob",
	DisplayName = "Noob",
	Description = "Joined today. Still figuring out the controls.",
	FlavorText = {
		"* Noob blocks the way!",
		"* Noob is trying to jump. Nothing happens.",
		"* Noob looks at you hopefully.",
		"* Smells like a brand new account.",
	},
	AttackText = "* Noob throws a wobbly block at you!",
	Acts = {
		{ Name = "Wave", Message = "* You wave at Noob.\n* Noob waves back... with the wrong arm." },
		{ Name = "Teach", Message = "* You show Noob how to walk properly.\n* Noob seems grateful." },
	},
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
	Stats = { HP = 20, ATK = 4, DEF = 0 },
}

return noob
