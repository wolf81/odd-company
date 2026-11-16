--!strict
-- Building blocks for decorating the world: each function adds the Parts
-- for one thing (a cottage, a tree, a lamp...) to a list of decorations.
-- Positions are world positions of the thing's bottom centre.
-- Still plain Parts until the nephew's art arrives, but with materials
-- and shapes so places feel real.

local WorldTypes = require(script.Parent.WorldTypes)

type Decoration = WorldTypes.Decoration
type List = { Decoration }

local Props = {}

Props.Colors = {
	Cobble = Color3.fromRGB(165, 150, 130),
	Wood = Color3.fromRGB(124, 86, 52),
	DarkWood = Color3.fromRGB(80, 55, 35),
	Stone = Color3.fromRGB(140, 140, 135),
	Glass = Color3.fromRGB(170, 215, 240),
	Leaves = { Color3.fromRGB(70, 125, 55), Color3.fromRGB(85, 145, 60), Color3.fromRGB(60, 110, 50) },
	Flowers = {
		Color3.fromRGB(235, 80, 80), -- red
		Color3.fromRGB(250, 210, 70), -- yellow
		Color3.fromRGB(240, 140, 200), -- pink
		Color3.fromRGB(245, 245, 245), -- white
		Color3.fromRGB(150, 120, 230), -- purple
	},
}
local C = Props.Colors

-- A cottage with its front door facing south (toward the camera): walls,
-- a door, two windows, a stepped roof and maybe a chimney.
function Props.house(list: List, name: string, at: Vector3, width: number, depth: number, wallColor: Color3, roofColor: Color3, chimney: boolean)
	local wallHeight = 4
	table.insert(list, { Name = name, Position = at, Size = Vector3.new(width, wallHeight, depth), Color = wallColor, Material = Enum.Material.Brick })

	-- Door and windows sit just in front of the south wall.
	local front = at.Z + depth / 2 + 0.1
	table.insert(list, { Name = name .. "Door", Position = Vector3.new(at.X, at.Y, front), Size = Vector3.new(2, 3, 0.2), Color = C.DarkWood, Material = Enum.Material.WoodPlanks })
	for _, side in { -1, 1 } do
		local x = at.X + side * width * 0.28
		table.insert(list, { Name = name .. "Window", Position = Vector3.new(x, at.Y + 1.5, front), Size = Vector3.new(1.8, 1.5, 0.2), Color = C.Glass, Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false })
		table.insert(list, { Name = name .. "Sill", Position = Vector3.new(x, at.Y + 1.3, front + 0.15), Size = Vector3.new(2.2, 0.2, 0.4), Color = C.Wood, Material = Enum.Material.Wood, CanCollide = false })
	end

	-- Stepped roof: three layers, each narrower front-to-back, like a
	-- pixel-art gable. Overhangs the walls a little.
	for layer = 0, 2 do
		table.insert(list, {
			Name = name .. "Roof",
			Position = at + Vector3.new(0, wallHeight + layer * 0.7, 0),
			Size = Vector3.new(width + 1.5, 0.7, (depth + 1.5) * (1 - layer * 0.33)),
			Color = roofColor,
			Material = Enum.Material.Slate,
		})
	end

	if chimney then
		table.insert(list, { Name = name .. "Chimney", Position = at + Vector3.new(width * 0.3, wallHeight, -depth * 0.15), Size = Vector3.new(1.2, 3.2, 1.2), Color = C.Stone, Material = Enum.Material.Brick })
	end
end

-- A round tree: trunk plus a big leafy ball and a smaller one on top.
-- Leaves don't collide, so only the thin trunk is in the way.
function Props.tree(list: List, at: Vector3, size: number, shade: number)
	local leaves = C.Leaves[(shade - 1) % #C.Leaves + 1]
	table.insert(list, { Name = "TreeTrunk", Position = at, Size = Vector3.new(1.2, 3, 1.2), Color = C.Wood, Shape = "Cylinder", Material = Enum.Material.Wood })
	table.insert(list, { Name = "TreeLeaves", Position = at + Vector3.new(0, 2.4, 0), Size = Vector3.one * size, Color = leaves, Shape = "Ball", Material = Enum.Material.Grass, CanCollide = false })
	table.insert(list, { Name = "TreeLeaves", Position = at + Vector3.new(size * 0.25, 2.4 + size * 0.55, -size * 0.1), Size = Vector3.one * size * 0.6, Color = leaves, Shape = "Ball", Material = Enum.Material.Grass, CanCollide = false })
end

-- A tall pine for the forest: trunk and three stacked cones (balls
-- getting smaller), darker green.
function Props.pine(list: List, at: Vector3, size: number)
	local green = Color3.fromRGB(45, 95, 55)
	table.insert(list, { Name = "PineTrunk", Position = at, Size = Vector3.new(1, 3, 1), Color = C.DarkWood, Shape = "Cylinder", Material = Enum.Material.Wood })
	for i = 0, 2 do
		local s = size * (1 - i * 0.28)
		table.insert(list, { Name = "PineLeaves", Position = at + Vector3.new(0, 2 + i * size * 0.45, 0), Size = Vector3.new(s, s * 0.8, s), Color = green, Shape = "Ball", Material = Enum.Material.Grass, CanCollide = false })
	end
end

-- A low green bush (you can walk through it).
function Props.bush(list: List, at: Vector3)
	table.insert(list, { Name = "Bush", Position = at, Size = Vector3.new(2.4, 1.8, 2.4), Color = C.Leaves[2], Shape = "Ball", Material = Enum.Material.Grass, CanCollide = false })
end

-- A grey boulder.
function Props.rock(list: List, at: Vector3, size: number)
	table.insert(list, { Name = "Rock", Position = at, Size = Vector3.new(size * 1.3, size, size), Color = Color3.fromRGB(120, 120, 115), Shape = "Ball", Material = Enum.Material.Slate })
end

-- A row of small flowers going east from `at`, `count` long. Colours
-- repeat in a fixed order, so the world looks the same every time.
function Props.flowerRow(list: List, at: Vector3, count: number, firstColor: number)
	for i = 0, count - 1 do
		local color = C.Flowers[(firstColor + i - 1) % #C.Flowers + 1]
		table.insert(list, { Name = "Flower", Position = at + Vector3.new(i * 1.2, 0.1, (i % 2) * 0.5), Size = Vector3.one * 0.7, Color = color, Shape = "Ball", CanCollide = false })
	end
end

-- A lamp post: dark pole with a glowing lamp on top.
function Props.lamp(list: List, at: Vector3)
	table.insert(list, { Name = "LampPost", Position = at, Size = Vector3.new(0.4, 5, 0.4), Color = Color3.fromRGB(40, 40, 45), Shape = "Cylinder", Material = Enum.Material.Metal })
	table.insert(list, { Name = "Lamp", Position = at + Vector3.new(0, 5, 0), Size = Vector3.new(0.9, 0.9, 0.9), Color = Color3.fromRGB(255, 220, 140), Material = Enum.Material.Neon, CanCollide = false })
end

-- A stone well with water, two posts and a little roof.
function Props.well(list: List, at: Vector3)
	table.insert(list, { Name = "Well", Position = at, Size = Vector3.new(3.4, 1.6, 3.4), Color = C.Stone, Shape = "Cylinder", Material = Enum.Material.Cobblestone })
	table.insert(list, { Name = "WellWater", Position = at + Vector3.new(0, 1.6, 0), Size = Vector3.new(2.6, 0.05, 2.6), Color = Color3.fromRGB(60, 120, 190), Shape = "Cylinder", Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false })
	for _, side in { -1, 1 } do
		table.insert(list, { Name = "WellPost", Position = at + Vector3.new(side * 1.4, 1.6, 0), Size = Vector3.new(0.3, 2.4, 0.3), Color = C.Wood, Material = Enum.Material.Wood })
	end
	table.insert(list, { Name = "WellRoof", Position = at + Vector3.new(0, 4, 0), Size = Vector3.new(3.8, 0.4, 2.4), Color = Color3.fromRGB(150, 70, 50), Material = Enum.Material.Slate })
end

-- A market stall facing south: counter, back wall with two swords on
-- display, corner posts and a red-and-white striped awning. The "SHOP"
-- sign and the prompt are added by WorldBuilder (they aren't plain Parts).
function Props.stall(list: List, at: Vector3)
	local width = 6
	table.insert(list, { Name = "StallCounter", Position = at + Vector3.new(0, 0, 1), Size = Vector3.new(width, 1.4, 1.4), Color = C.Wood, Material = Enum.Material.WoodPlanks })
	table.insert(list, { Name = "StallCounterTop", Position = at + Vector3.new(0, 1.4, 1), Size = Vector3.new(width + 0.4, 0.2, 1.8), Color = C.DarkWood, Material = Enum.Material.Wood })
	table.insert(list, { Name = "StallBack", Position = at + Vector3.new(0, 0, -1.3), Size = Vector3.new(width, 3.2, 0.4), Color = C.Wood, Material = Enum.Material.WoodPlanks })
	for _, x in { -width / 2, width / 2 } do
		for _, z in { 1.7, -1.3 } do
			table.insert(list, { Name = "StallPost", Position = at + Vector3.new(x, 0, z), Size = Vector3.new(0.4, 4.2, 0.4), Color = C.DarkWood, Material = Enum.Material.Wood })
		end
	end
	-- Striped awning: alternating red and white strips.
	local strips = 6
	local stripWidth = (width + 0.8) / strips
	for i = 0, strips - 1 do
		local x = -(width + 0.8) / 2 + stripWidth * (i + 0.5)
		table.insert(list, {
			Name = "StallAwning",
			Position = at + Vector3.new(x, 4.2, 0.2),
			Size = Vector3.new(stripWidth, 0.25, 3.8),
			Color = if i % 2 == 0 then Color3.fromRGB(200, 50, 45) else Color3.fromRGB(245, 240, 230),
			Material = Enum.Material.Fabric,
		})
	end
	-- Two swords hanging on the back wall.
	for _, x in { -1.2, 1.2 } do
		table.insert(list, { Name = "DisplayBlade", Position = at + Vector3.new(x, 1.6, -1.0), Size = Vector3.new(0.25, 1.4, 0.1), Color = Color3.fromRGB(200, 205, 215), Material = Enum.Material.Metal, CanCollide = false })
		table.insert(list, { Name = "DisplayGuard", Position = at + Vector3.new(x, 1.5, -0.98), Size = Vector3.new(0.8, 0.15, 0.15), Color = Color3.fromRGB(230, 180, 60), Material = Enum.Material.Metal, CanCollide = false })
		table.insert(list, { Name = "DisplayHandle", Position = at + Vector3.new(x, 1.0, -1.0), Size = Vector3.new(0.18, 0.5, 0.18), Color = C.DarkWood, Material = Enum.Material.Wood, CanCollide = false })
	end
end

-- A flat cobblestone patch on the ground (village squares, paths).
function Props.paving(list: List, name: string, at: Vector3, size: Vector2, round: boolean)
	table.insert(list, {
		Name = name,
		Position = at + Vector3.new(0, 0.02, 0),
		Size = Vector3.new(size.X, 0.05, size.Y),
		Color = C.Cobble,
		Shape = if round then "Cylinder" else "Block",
		Material = Enum.Material.Cobblestone,
		CanCollide = false,
	})
end

return Props
