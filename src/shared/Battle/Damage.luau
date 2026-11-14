--!strict
-- The damage formula, in one place so it's easy to swap later.
-- damage = max(1, ATK - DEF) x multiplier, rounded.
-- `multiplier` comes from the attack timing (step 6); 0 means a miss.

local Damage = {}

function Damage.compute(atk: number, def: number, multiplier: number): number
	if multiplier <= 0 then
		return 0
	end
	return math.max(1, math.floor(math.max(1, atk - def) * multiplier + 0.5))
end

return Damage
