--!strict
-- Shared type for enemy data, so every enemy file has the same shape.

export type Stats = {
	HP: number,
	ATK: number,
	DEF: number,
}

-- Something the player can do with ACT. "Check" is added automatically.
export type Act = {
	Name: string,
	Message: string, -- shown when chosen; use "\n" for a new line
}

export type EnemyData = {
	Id: string,
	DisplayName: string,
	-- One-line flavour text shown by ACT > Check.
	Description: string,
	-- Lines shown in the dialogue box at the start of each player turn
	-- (one picked at random).
	FlavorText: { string },
	-- What the enemy does on its turn until the dodge phase exists (step 7).
	AttackText: string,
	Acts: { Act },
	RigType: Enum.HumanoidRigType,
	-- Properties copied onto a HumanoidDescription to build the avatar
	-- (the field below is named Avatar to avoid confusion with Description):
	-- body colours (HeadColor, TorsoColor, ...), body part / clothing /
	-- accessory asset IDs, scales. Any HumanoidDescription property works.
	Avatar: { [string]: any },
	-- Animation that loops while the enemy stands in its room (optional).
	IdleAnimationId: string?,
	-- Used from step 8 (stats and damage). Placeholder numbers until then.
	Stats: Stats,
}

return {}
