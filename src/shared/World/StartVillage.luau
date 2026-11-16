--!strict
-- The start village, in the south of the world. The Noob and Elliot wait
-- on the square; the chest holds the Pizza slice Elliot wants. The main
-- road leaves through the north gate.

local Props = require(script.Parent.Props)
local WorldTypes = require(script.Parent.WorldTypes)

local CENTER = Vector3.new(0, 0, 150)
local SIZE = Vector2.new(64, 40)

-- Offset from the village centre, so the layout is easy to move.
local function at(x: number, z: number): Vector3
	return CENTER + Vector3.new(x, 0, z)
end

local decorations: { WorldTypes.Decoration } = {}

-- Ground: path from the spawn to the gate, and a round square where the
-- two allies wait.
Props.paving(decorations, "Path", at(0, 0), Vector2.new(5, SIZE.Y), false)
Props.paving(decorations, "Square", at(0, -4), Vector2.new(16, 16), true)

-- Cottages
Props.house(decorations, "HouseWest", at(-22, -10), 12, 9, Color3.fromRGB(215, 195, 160), Color3.fromRGB(150, 60, 45), true)
Props.house(decorations, "HouseEast", at(22, -10), 12, 9, Color3.fromRGB(200, 205, 215), Color3.fromRGB(60, 90, 140), false)
Props.house(decorations, "HouseSouthWest", at(-22, 11), 10, 8, Color3.fromRGB(225, 185, 150), Color3.fromRGB(110, 70, 50), true)

-- Flower beds in front of the cottages
Props.flowerRow(decorations, at(-27, -4.5), 9, 1)
Props.flowerRow(decorations, at(17, -4.5), 9, 3)
Props.flowerRow(decorations, at(-26, 15.8), 7, 2)

-- Trees (never on the path or in the gate)
Props.tree(decorations, at(-29, 0), 5, 1)
Props.tree(decorations, at(29, 1), 5.5, 3)
Props.tree(decorations, at(-8, -16), 4.5, 2)
Props.tree(decorations, at(9, -16), 5, 1)
Props.tree(decorations, at(-12, 17), 4.5, 3)
Props.tree(decorations, at(14, 17), 5, 2)

Props.bush(decorations, at(-7, -18))
Props.bush(decorations, at(7, -18))
Props.stall(decorations, at(20, 6))

-- Lamp posts along the path, and a well beside the square
Props.lamp(decorations, at(-3.5, 9))
Props.lamp(decorations, at(3.5, 9))
Props.lamp(decorations, at(-3.5, -14))
Props.lamp(decorations, at(3.5, -14))
Props.well(decorations, at(-13, 4))

local village: WorldTypes.Village = {
	Name = "StartVillage",
	Area = { Center = Vector2.new(CENTER.X, CENTER.Z), Size = SIZE },
	Spawn = at(0, 14), -- near the south fence
	Decorations = decorations,
	Allies = {
		-- On the village square, either side of the path.
		{ Id = "Noob", Position = at(-5, -5) },
		{ Id = "Elliot", Position = at(5, -5) },
	},
	Chests = {
		-- Tucked in the south-east corner, away from Elliot.
		{ Item = "Pizza slice", Position = at(26, 14) },
	},
	Shops = {
		-- The market stall east of the square (its look is Props.stall above).
		{ Position = at(20, 6), Items = { "IronSword", "Bandage" } },
	},
	FenceGates = { "North" },
}

return village
