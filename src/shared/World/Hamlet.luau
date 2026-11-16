--!strict
-- A small second village past the river, at the end of a side road going
-- east. A safe place to rest: you restart here after losing a fight
-- once you've visited it. Room for new villagers later.

local Props = require(script.Parent.Props)
local WorldTypes = require(script.Parent.WorldTypes)

local CENTER = Vector3.new(96, 0, -60)
local SIZE = Vector2.new(40, 32)

local function at(x: number, z: number): Vector3
	return CENTER + Vector3.new(x, 0, z)
end

local decorations: { WorldTypes.Decoration } = {}

Props.paving(decorations, "Square", at(0, 2), Vector2.new(12, 12), true)
Props.paving(decorations, "Path", at(-14, 2), Vector2.new(12, 5), false) -- to the west gate

Props.house(decorations, "HamletHouseA", at(-10, -9), 10, 8, Color3.fromRGB(220, 210, 180), Color3.fromRGB(70, 110, 70), true)
Props.house(decorations, "HamletHouseB", at(10, -9), 10, 8, Color3.fromRGB(205, 175, 150), Color3.fromRGB(140, 60, 50), false)

Props.flowerRow(decorations, at(-14, -3.8), 7, 4)
Props.flowerRow(decorations, at(6, -3.8), 7, 1)
Props.tree(decorations, at(15, 11), 5, 2)
Props.tree(decorations, at(-15, 12), 4.5, 1)
Props.lamp(decorations, at(-4, 8))
Props.well(decorations, at(6, 9))

local village: WorldTypes.Village = {
	Name = "Hamlet",
	Area = { Center = Vector2.new(CENTER.X, CENTER.Z), Size = SIZE },
	Spawn = at(0, 4),
	Decorations = decorations,
	Allies = {},
	Chests = {},
	Shops = {},
	FenceGates = { "West" },
}

return village
