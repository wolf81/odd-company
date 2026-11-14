--!strict
-- Shared type for room layouts, so every room file has the same shape.

export type Wall = "North" | "South" | "East" | "West"

export type DoorLayout = {
	Wall: Wall,
	Width: number,
}

export type EnemyPlacement = {
	Id: string, -- key in ReplicatedStorage.Modules.Enemies
	Offset: Vector3, -- from the room centre, on the floor
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
}

return {}
