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
	RigType = Enum.HumanoidRigType.R6,
	Description = {
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
