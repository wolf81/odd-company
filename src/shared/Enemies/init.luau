--!strict
-- All enemies by Id. The world (fixed enemies, random-fight pools) refers to enemies by these Ids.

local EnemyTypes = require(script.EnemyTypes)

local Enemies: { [string]: EnemyTypes.EnemyData } = {
	Builderman = require(script.Builderman),
	BaconGirl = require(script.BaconGirl),
}

return Enemies
