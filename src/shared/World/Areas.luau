--!strict
-- Questions about a spot in the world: is it safe from random fights,
-- which village is it in, and which enemies can show up there?

local WorldTypes = require(script.Parent.WorldTypes)
local World = require(script.Parent)

local Areas = {}

function Areas.inRect(rect: WorldTypes.Rect, position: Vector3): boolean
	local half = rect.Size / 2
	return math.abs(position.X - rect.Center.X) <= half.X and math.abs(position.Z - rect.Center.Y) <= half.Y
end

-- The village at `position`, or nil out in the wild.
function Areas.villageAt(position: Vector3): WorldTypes.Village?
	for _, village in World.Villages do
		if Areas.inRect(village.Area, position) then
			return village
		end
	end
	return nil
end

function Areas.village(name: string): WorldTypes.Village?
	for _, village in World.Villages do
		if village.Name == name then
			return village
		end
	end
	return nil
end

-- Roads (including the bridge) and villages are safe: no random fights.
function Areas.isSafe(position: Vector3): boolean
	if Areas.villageAt(position) then
		return true
	end
	for _, road in World.Roads do
		if Areas.inRect(road, position) then
			return true
		end
	end
	return false
end

-- Which random fights can happen at `position`: the first zone it's in,
-- otherwise the default pool.
function Areas.encounterPool(position: Vector3): { WorldTypes.EncounterOption }
	for _, zone in World.Zones do
		if Areas.inRect(zone.Area, position) then
			return zone.Pool
		end
	end
	return World.DefaultPool
end

-- Picks one option from `pool`, weighted. Returns its list of enemy Ids.
function Areas.pickEncounter(pool: { WorldTypes.EncounterOption }, random: Random): { string }
	local total = 0
	for _, option in pool do
		total += option.Weight
	end
	local roll = random:NextNumber(0, total)
	for _, option in pool do
		roll -= option.Weight
		if roll <= 0 then
			return option.Enemies
		end
	end
	return pool[#pool].Enemies
end

return Areas
