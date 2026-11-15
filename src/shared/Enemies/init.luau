--!strict
-- All enemies by Id. Rooms refer to enemies by these Ids.

local EnemyTypes = require(script.EnemyTypes)

local Enemies: { [string]: EnemyTypes.EnemyData } = {
	Builderman = require(script.Builderman),
}

return Enemies
