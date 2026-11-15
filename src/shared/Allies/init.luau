--!strict
-- All allies by Id. Rooms refer to allies by these Ids.

local AllyTypes = require(script.AllyTypes)

local Allies: { [string]: AllyTypes.AllyData } = {
	Noob = require(script.Noob),
	Elliot = require(script.Elliot),
}

return Allies
