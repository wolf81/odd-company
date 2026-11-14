--!strict
-- Builds a placeholder room (floor, four walls, doors) from a layout table.
-- North is -Z (top of the screen), South is +Z (bottom of the screen).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoomTypes = require(ReplicatedStorage.Modules.Rooms.RoomTypes)

local FLOOR_THICKNESS = 1

local RoomBuilder = {}

local function makePart(name: string, size: Vector3, position: Vector3, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Builds one wall. If a door sits in this wall, the wall is split into two
-- pieces around a centred gap, and a Door part fills the gap.
local function buildWall(layout: RoomTypes.RoomLayout, wall: RoomTypes.Wall, model: Model)
	local half = layout.Size / 2
	local t = layout.WallThickness
	local h = layout.WallHeight
	local floorTop = layout.Center.Y + FLOOR_THICKNESS
	local y = floorTop + h / 2

	-- Walls run along X (north/south) or along Z (east/west). North/south
	-- walls span the full width plus the corners.
	local alongX = wall == "North" or wall == "South"
	local length = if alongX then layout.Size.X + 2 * t else layout.Size.Y
	local mid: Vector3
	if wall == "North" then
		mid = layout.Center + Vector3.new(0, 0, -half.Y - t / 2)
	elseif wall == "South" then
		mid = layout.Center + Vector3.new(0, 0, half.Y + t / 2)
	elseif wall == "East" then
		mid = layout.Center + Vector3.new(half.X + t / 2, 0, 0)
	else
		mid = layout.Center + Vector3.new(-half.X - t / 2, 0, 0)
	end
	mid = Vector3.new(mid.X, y, mid.Z)

	local function wallSize(len: number): Vector3
		return if alongX then Vector3.new(len, h, t) else Vector3.new(t, h, len)
	end
	local function offsetAlong(d: number): Vector3
		return if alongX then Vector3.new(d, 0, 0) else Vector3.new(0, 0, d)
	end

	local door: RoomTypes.DoorLayout? = nil
	for _, d in layout.Doors do
		if d.Wall == wall then
			door = d
		end
	end

	if not door then
		makePart(wall .. "Wall", wallSize(length), mid, layout.WallColor, model)
		return
	end

	local gap = door.Width
	local sideLength = (length - gap) / 2
	local sideOffset = gap / 2 + sideLength / 2
	makePart(wall .. "WallA", wallSize(sideLength), mid - offsetAlong(sideOffset), layout.WallColor, model)
	makePart(wall .. "WallB", wallSize(sideLength), mid + offsetAlong(sideOffset), layout.WallColor, model)
	makePart("Door" .. wall, wallSize(gap), mid, layout.DoorColor, model)
end

-- Builds the room into `parent` and returns the model. A part named
-- "Spawn" (invisible, no collision) marks where the player starts.
function RoomBuilder.build(layout: RoomTypes.RoomLayout, parent: Instance): Model
	local existing = parent:FindFirstChild(layout.Name)
	if existing then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = layout.Name

	local floorSize = Vector3.new(layout.Size.X, FLOOR_THICKNESS, layout.Size.Y)
	local floor = makePart("Floor", floorSize, layout.Center + Vector3.new(0, FLOOR_THICKNESS / 2, 0), layout.FloorColor, model)
	model.PrimaryPart = floor

	for _, wall: RoomTypes.Wall in { "North", "South", "East", "West" } do
		buildWall(layout, wall, model)
	end

	local spawnPos = layout.Center + layout.SpawnOffset + Vector3.new(0, FLOOR_THICKNESS, 0)
	local spawnMarker = makePart("Spawn", Vector3.new(1, 1, 1), spawnPos, layout.FloorColor, model)
	spawnMarker.Transparency = 1
	spawnMarker.CanCollide = false
	spawnMarker.CanQuery = false
	spawnMarker.CanTouch = false

	model.Parent = parent
	return model
end

-- Places a character standing on the floor at the room's spawn point,
-- facing north. Works for any avatar size (R6 or R15).
function RoomBuilder.placeCharacter(room: Model, character: Model)
	local spawnMarker = room:FindFirstChild("Spawn") :: BasePart
	local height = character:GetExtentsSize().Y
	local floorY = spawnMarker.Position.Y
	local position = Vector3.new(spawnMarker.Position.X, floorY + height / 2 + 0.5, spawnMarker.Position.Z)
	character:PivotTo(CFrame.lookAt(position, position + Vector3.new(0, 0, -1)))
end

return RoomBuilder
