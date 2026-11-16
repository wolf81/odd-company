--!strict
-- Shared types for the world layout (src/shared/World/). Positions are in
-- world studs; the ground's surface is at Y = 0. North is -Z (top of the
-- screen), south is +Z.

export type Side = "North" | "South" | "East" | "West"

-- An axis-aligned rectangle on the ground: Center and Size use (X, Z).
export type Rect = {
	Center: Vector2,
	Size: Vector2,
}

export type Shape = "Block" | "Ball" | "Cylinder"

-- A decoration Part: houses, roofs, trees, flowers, lamps, rocks.
-- Position is where the bottom centre goes (Position.Y lifts it, e.g. a
-- roof on top of a house).
export type Decoration = {
	Name: string,
	Position: Vector3,
	-- Width (X), height (Y), depth (Z). A Cylinder always stands upright:
	-- X is its diameter, Y its height.
	Size: Vector3,
	Color: Color3,
	Shape: Shape?, -- default "Block"
	Material: Enum.Material?, -- default SmoothPlastic
	Transparency: number?, -- default 0 (e.g. 0.2 for window glass)
	CanCollide: boolean?, -- default true; false for paths, flowers, leaves
}

export type AllyPlacement = {
	Id: string, -- key in ReplicatedStorage.Modules.Allies
	Position: Vector3,
}

-- A chest the player can open once. With an Item (e.g. "Pizza slice")
-- it gives that; without one it's a loot chest with a random amount of
-- gold (Config.LootChestGold).
export type ChestLayout = {
	Item: string?,
	Position: Vector3,
}

-- A market stall where you can buy things with gold. Position is the
-- middle of the stall, front (the counter) facing south.
export type ShopLayout = {
	Position: Vector3,
	-- What it sells: Ids from src/shared/Items/Weapons.luau (swords) or
	-- src/shared/Items/Supplies.luau (bandages).
	Items: { string },
}

-- An enemy standing at a fixed spot (e.g. blocking a bridge). Enemies with
-- the same Group fight together: touching one starts one battle against
-- all of them.
export type FixedEnemy = {
	Id: string, -- key in ReplicatedStorage.Modules.Enemies
	Position: Vector3,
	Group: string?,
}

-- A village: a safe area (no random fights) where you restart after
-- losing a battle.
export type Village = {
	Name: string,
	Area: Rect,
	Spawn: Vector3, -- where you start / restart
	Decorations: { Decoration },
	Allies: { AllyPlacement },
	Chests: { ChestLayout },
	Shops: { ShopLayout },
	-- A low wooden fence around the edge, with a gate gap in these sides.
	FenceGates: { string }?, -- "North", "South", "East" or "West"
}

-- One possible random fight: these enemies together, picked with this
-- weight (higher = more often).
export type EncounterOption = {
	Enemies: { string },
	Weight: number,
}

-- Random fights inside `Area` use this pool instead of the default one.
export type EncounterZone = {
	Name: string,
	Area: Rect,
	Pool: { EncounterOption },
}

-- What closes off each edge of the map. Invisible walls along every edge
-- make sure nobody gets out, whatever the border looks like.
--   Cliff:  a rock wall (Height studs tall)
--   Forest: a thick band of pine trees
--   Sea:    a sandy beach, then water
export type Border = { Kind: "Cliff" | "Forest" | "Sea", Height: number? }

export type World = {
	-- The walkable area, centred on (0, 0), inside the borders.
	Size: Vector2,
	BorderThickness: number, -- how far the cliffs / forest / sea reach outside
	Borders: { North: Border, South: Border, East: Border, West: Border },

	Roads: { Rect },
	-- A river running east-west across the whole world, with one bridge.
	River: { Z: number, Width: number, BridgeX: number, BridgeWidth: number },
	-- A rocky ridge running east-west with one gap (the forest gate).
	Ridge: { Z: number, Thickness: number, Height: number, GapX: number, GapWidth: number },

	Villages: { Village },
	StartVillage: string, -- Name of the village where the game starts
	FixedEnemies: { FixedEnemy },
	LootChests: { ChestLayout }, -- gold chests out in the wild
	Decorations: { Decoration }, -- trees, rocks, flowers out in the world

	-- Random fights happen anywhere except roads and villages.
	DefaultPool: { EncounterOption },
	Zones: { EncounterZone },
}

return {}
