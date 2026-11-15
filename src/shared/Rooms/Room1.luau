--!strict
-- Layout for room 1 (Builderman's room). Placeholder geometry: plain Parts
-- built by RoomBuilder. Change numbers here to reshape the room.

local RoomTypes = require(script.Parent.RoomTypes)

local room: RoomTypes.RoomLayout = {
	Name = "Room1",
	-- Floor centre; floor top sits at Center.Y + 1. Kept away from the
	-- Baseplate template's SpawnLocation at the origin.
	Center = Vector3.new(0, 0, -100),
	Size = Vector2.new(48, 32), -- width (X) by depth (Z) in studs
	WallHeight = 4, -- low enough that the top-down camera sees over it
	WallThickness = 1,
	FloorColor = Color3.fromRGB(72, 62, 96),
	WallColor = Color3.fromRGB(38, 33, 54),
	DoorColor = Color3.fromRGB(150, 110, 60),
	SpawnOffset = Vector3.new(0, 0, 10), -- from the centre; +Z is toward the screen bottom
	Doors = {
		-- Leads to room 2 later (step 13). Closed for now.
		-- 8 studs wide so even the biggest avatars fit.
		{ Wall = "North", Width = 8 },
		-- Back to the village, always open.
		{ Wall = "South", Width = 8, Open = true },
	},
	Enemies = {
		-- In the north half, between the player's spawn and the door.
		{ Id = "Builderman", Offset = Vector3.new(0, 0, -6) },
	},
}

return room
