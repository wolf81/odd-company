--!strict
-- All enemies by Id. Rooms refer to enemies by these Ids.

local EnemyTypes = require(script.EnemyTypes)

local Enemies: { [string]: EnemyTypes.EnemyData } = {
	Noob = require(script.Noob),
}

return Enemies
