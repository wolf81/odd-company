--!strict
-- Shared type for enemy data, so every enemy file has the same shape.

export type Stats = {
	HP: number,
	ATK: number,
	DEF: number,
}

export type EnemyData = {
	Id: string,
	DisplayName: string,
	RigType: Enum.HumanoidRigType,
	-- Properties copied onto a HumanoidDescription to build the avatar:
	-- body colours (HeadColor, TorsoColor, ...), body part / clothing /
	-- accessory asset IDs, scales. Any HumanoidDescription property works.
	Description: { [string]: any },
	-- Animation that loops while the enemy stands in its room (optional).
	IdleAnimationId: string?,
	-- Used from step 8 (stats and damage). Placeholder numbers until then.
	Stats: Stats,
}

return {}
