--!strict
-- Layout for the village: where the game starts. Directly south of room 1,
-- with an open door north into it. The Noob and Elliot wait here; the chest
-- holds the Pizza slice Elliot wants. Placeholder geometry: plain Parts.

local RoomTypes = require(script.Parent.RoomTypes)

local WOOD = Color3.fromRGB(150, 110, 60)
local ROOF = Color3.fromRGB(140, 50, 40)
local HOUSE = Color3.fromRGB(205, 190, 150)

-- A house is two boxes: walls, and a slightly bigger roof on top.
local function house(name: string, x: number, z: number, width: number, depth: number): { RoomTypes.Decoration }
	return {
		{ Name = name, Offset = Vector3.new(x, 0, z), Size = Vector3.new(width, 4, depth), Color = HOUSE },
		{ Name = name .. "Roof", Offset = Vector3.new(x, 4, z), Size = Vector3.new(width + 1, 1, depth + 1), Color = ROOF },
	}
end

local decorations: { RoomTypes.Decoration } = {
	-- Dirt path from the spawn up to the door into room 1.
	{
		Name = "Path",
		Offset = Vector3.new(0, 0, 0),
		Size = Vector3.new(6, 0.05, 40),
		Color = Color3.fromRGB(170, 140, 95),
		CanCollide = false,
	},
}
for _, part in house("HouseWest", -22, -10, 12, 10) do
	table.insert(decorations, part)
end
for _, part in house("HouseEast", 22, -10, 12, 10) do
	table.insert(decorations, part)
end
for _, part in house("HouseSouthWest", -22, 11, 10, 8) do
	table.insert(decorations, part)
end

local room: RoomTypes.RoomLayout = {
	Name = "Village",
	-- Room 1's south wall ends at Z = -83; this room's north wall starts
	-- there, so the two door gaps line up.
	Center = Vector3.new(0, 0, -62),
	Size = Vector2.new(64, 40), -- width (X) by depth (Z) in studs
	WallHeight = 3, -- a low fence
	WallThickness = 1,
	FloorColor = Color3.fromRGB(88, 130, 70), -- grass
	WallColor = WOOD,
	DoorColor = WOOD,
	SpawnOffset = Vector3.new(0, 0, 14), -- near the south fence
	Doors = {
		-- Into room 1, always open. Same width as room 1's south door.
		{ Wall = "North", Width = 8, Open = true },
	},
	Enemies = {},
	Allies = {
		-- Either side of the path, so you pass both on the way north.
		{ Id = "Noob", Offset = Vector3.new(-8, 0, -4) },
		{ Id = "Elliot", Offset = Vector3.new(8, 0, -4) },
	},
	Chests = {
		-- Tucked in the south-east corner, away from Elliot.
		{ Item = "Pizza slice", Offset = Vector3.new(26, 0, 14) },
	},
	Decorations = decorations,
}

return room
