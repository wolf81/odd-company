--!strict
-- Shared type for room layouts, so every room file has the same shape.
-- All Offsets are from the room centre, on the floor (+Z = south).

export type Wall = "North" | "South" | "East" | "West"

export type DoorLayout = {
	Wall: Wall,
	Width: number,
	-- true = just a gap you can walk through; otherwise a closed Door part.
	Open: boolean?,
}

export type EnemyPlacement = {
	Id: string, -- key in ReplicatedStorage.Modules.Enemies
	Offset: Vector3,
}

export type AllyPlacement = {
	Id: string, -- key in ReplicatedStorage.Modules.Allies
	Offset: Vector3,
}

-- A chest the player can open once to get an item (e.g. "Pizza slice").
export type ChestLayout = {
	Item: string,
	Offset: Vector3,
}

-- A plain coloured box: houses, roofs, paths, fences. Offset is where the
-- bottom centre goes (Offset.Y lifts it, e.g. a roof on top of a house).
export type Decoration = {
	Name: string,
	Offset: Vector3,
	Size: Vector3,
	Color: Color3,
	CanCollide: boolean?, -- default true; false for paths you walk over
}

export type RoomLayout = {
	Name: string,
	Center: Vector3,
	Size: Vector2,
	WallHeight: number,
	WallThickness: number,
	FloorColor: Color3,
	WallColor: Color3,
	DoorColor: Color3,
	SpawnOffset: Vector3,
	Doors: { DoorLayout },
	Enemies: { EnemyPlacement },
	Allies: { AllyPlacement }?,
	Chests: { ChestLayout }?,
	Decorations: { Decoration }?,
}

return {}
