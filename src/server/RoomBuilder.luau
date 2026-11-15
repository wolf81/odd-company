--!strict
-- Builds a placeholder room (floor, four walls, doors, decorations, chests)
-- from a layout table. North is -Z (top of the screen), South is +Z (bottom).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local RoomTypes = require(ReplicatedStorage.Modules.Rooms.RoomTypes)
local Placement = require(ReplicatedStorage.Modules.Placement)

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
-- pieces around a centred gap, and a Door part fills the gap (unless the
-- door is open, then the gap stays empty so you can walk through).
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
	if not door.Open then
		makePart("Door" .. wall, wallSize(gap), mid, layout.DoorColor, model)
	end
end

-- Where a point `offset` from the room centre is, on top of the floor.
function RoomBuilder.floorPosition(layout: RoomTypes.RoomLayout, offset: Vector3): Vector3
	return layout.Center + Vector3.new(offset.X, FLOOR_THICKNESS + offset.Y, offset.Z)
end

local function buildDecorations(layout: RoomTypes.RoomLayout, model: Model)
	local decorations: { RoomTypes.Decoration } = layout.Decorations or {}
	for _, d in decorations do
		-- Offset is the bottom centre, so lift by half the height.
		local position = RoomBuilder.floorPosition(layout, d.Offset) + Vector3.new(0, d.Size.Y / 2, 0)
		local part = makePart(d.Name, d.Size, position, d.Color, model)
		part.CanCollide = d.CanCollide ~= false
	end
end

-- A chest is a brown box with a lid and an "Open" prompt. The client
-- (src/client/Village) gives the item and marks it opened.
local function buildChests(layout: RoomTypes.RoomLayout, model: Model)
	local chests: { RoomTypes.ChestLayout } = layout.Chests or {}
	for i, chest in chests do
		local floor = RoomBuilder.floorPosition(layout, chest.Offset)
		local box = makePart(`Chest{i}`, Vector3.new(3, 2, 2), floor + Vector3.new(0, 1, 0), Color3.fromRGB(120, 80, 40), model)
		local lid = makePart(`Chest{i}Lid`, Vector3.new(3.2, 0.5, 2.2), floor + Vector3.new(0, 2.25, 0), Color3.fromRGB(200, 160, 50), model)
		lid.Parent = box

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = "Chest"
		prompt.MaxActivationDistance = Config.InteractDistance
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute(Config.ChestPromptAttribute, chest.Item)
		prompt.Parent = box
	end
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

	buildWall(layout, "North", model)
	buildWall(layout, "South", model)
	buildWall(layout, "East", model)
	buildWall(layout, "West", model)
	buildDecorations(layout, model)
	buildChests(layout, model)

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
	-- The marker's centre is at floor height; lift 0.2 so the avatar
	-- drops onto the floor rather than starting inside it.
	Placement.standOnFloor(character, spawnMarker.Position, Vector3.new(0, 0, -1), 0.2)
end

return RoomBuilder
