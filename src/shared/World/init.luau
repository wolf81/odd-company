--!strict
-- The world: one big area to explore, built at runtime by
-- src/server/WorldBuilder.luau. Change numbers here to reshape it.
--
-- Map (north is the top of the screen, -Z):
--
--   +---------------- cliffs ----------------+
--   |  FOREST (pines)            |           |
--   |=========== rocky ridge === gap ========|  <- two Buildermans guard the gap
--   |                 |                      |
--   |  meadow         |------- side road --- HAMLET     sea
--   |                 |                      |   (beach)
--   |~~~~~~~~~~~~ river ~~~ bridge ~~~~~~~~~~|  <- Builderman blocks the bridge
--   |  meadow         |                      |
--   |            START VILLAGE               |
--   +------------- low cliffs ---------------+
--   (west edge: thick forest)
--
-- Random fights can start anywhere except on roads and in villages.

local Hamlet = require(script.Hamlet)
local Props = require(script.Props)
local StartVillage = require(script.StartVillage)
local WorldTypes = require(script.WorldTypes)

local SIZE = Vector2.new(320, 400) -- X from -160 to 160, Z from -200 to 200
local HALF = SIZE / 2

local RIVER = { Z = 0, Width = 24, BridgeX = 0, BridgeWidth = 8 }
local RIDGE = { Z = -140, Thickness = 12, Height = 12, GapX = 0, GapWidth = 12 }

local ROADS: { WorldTypes.Rect } = {
	-- Main road: start village's north gate -> bridge -> ridge gap -> forest.
	{ Center = Vector2.new(0, -33), Size = Vector2.new(8, 326) },
	-- Side road east to the hamlet.
	{ Center = Vector2.new(40, -60), Size = Vector2.new(72, 8) },
}

local VILLAGES: { WorldTypes.Village } = { StartVillage, Hamlet }

local FIXED_ENEMIES: { WorldTypes.FixedEnemy } = {
	-- Standing on the bridge: the only way north.
	{ Id = "Builderman", Position = Vector3.new(RIVER.BridgeX, 0, RIVER.Z) },
	-- Two of them side by side in the ridge gap: one battle against both.
	{ Id = "Builderman", Position = Vector3.new(RIDGE.GapX - 2.5, 0, RIDGE.Z), Group = "ForestGate" },
	{ Id = "Builderman", Position = Vector3.new(RIDGE.GapX + 2.5, 0, RIDGE.Z), Group = "ForestGate" },
}

-- Loot chests with gold, off the roads (so getting them can mean a
-- random fight). One in each corner of the meadows, one in the forest.
local LOOT_CHESTS: { WorldTypes.ChestLayout } = {
	{ Position = Vector3.new(-120, 0, 90) }, -- south-west meadow
	{ Position = Vector3.new(125, 0, 70) }, -- east, near the beach
	{ Position = Vector3.new(-100, 0, -90) }, -- north-west meadow, past the river
	{ Position = Vector3.new(70, 0, -180) }, -- deep in the forest
}

local FOREST: WorldTypes.Rect = {
	Center = Vector2.new(0, (-HALF.Y + RIDGE.Z - RIDGE.Thickness / 2) / 2),
	Size = Vector2.new(SIZE.X, HALF.Y + RIDGE.Z - RIDGE.Thickness / 2),
}

--------------------------------------------------------------------------
-- Scenery: trees, rocks and flowers scattered with a fixed seed, so the
-- world looks the same every time. Nothing is placed on roads, in
-- villages, in the river, on the ridge or next to the fixed enemies.

local function inRect(rect: WorldTypes.Rect, x: number, z: number, margin: number): boolean
	local half = rect.Size / 2 + Vector2.one * margin
	return math.abs(x - rect.Center.X) <= half.X and math.abs(z - rect.Center.Y) <= half.Y
end

local function keepClear(x: number, z: number): boolean
	for _, road in ROADS do
		if inRect(road, x, z, 4) then
			return true
		end
	end
	for _, village in VILLAGES do
		if inRect(village.Area, x, z, 5) then
			return true
		end
	end
	if math.abs(z - RIVER.Z) < RIVER.Width / 2 + 4 then
		return true
	end
	if math.abs(z - RIDGE.Z) < RIDGE.Thickness / 2 + 4 then
		return true
	end
	if x > HALF.X - 16 then
		return true -- the beach
	end
	for _, enemy in FIXED_ENEMIES do
		if (Vector2.new(x, z) - Vector2.new(enemy.Position.X, enemy.Position.Z)).Magnitude < 10 then
			return true
		end
	end
	for _, chest in LOOT_CHESTS do
		if (Vector2.new(x, z) - Vector2.new(chest.Position.X, chest.Position.Z)).Magnitude < 7 then
			return true
		end
	end
	return false
end

local decorations: { WorldTypes.Decoration } = {}
local random = Random.new(2026)

-- Tries `count` random spots in the area from (x1, z1) to (x2, z2) and
-- calls `place` for each spot that's clear.
local function scatter(count: number, x1: number, x2: number, z1: number, z2: number, place: (at: Vector3) -> ())
	for _ = 1, count do
		local x = random:NextNumber(x1, x2)
		local z = random:NextNumber(z1, z2)
		if not keepClear(x, z) then
			place(Vector3.new(x, 0, z))
		end
	end
end

local meadowNorth = RIDGE.Z + RIDGE.Thickness / 2
local inside = 4 -- keep scenery this far from the map edges

-- Meadows: round trees in loose groves, boulders and flower patches.
scatter(90, -HALF.X + inside, HALF.X - inside, meadowNorth, HALF.Y - inside, function(p)
	Props.tree(decorations, p, random:NextNumber(4.5, 6.5), random:NextInteger(1, 3))
end)
scatter(30, -HALF.X + inside, HALF.X - inside, meadowNorth, HALF.Y - inside, function(p)
	Props.rock(decorations, p, random:NextNumber(1.5, 3.5))
end)
scatter(25, -HALF.X + inside, HALF.X - inside, meadowNorth, HALF.Y - inside, function(p)
	Props.flowerRow(decorations, p, random:NextInteger(3, 6), random:NextInteger(1, 5))
end)
scatter(25, -HALF.X + inside, HALF.X - inside, meadowNorth, HALF.Y - inside, function(p)
	Props.bush(decorations, p)
end)

-- The forest north of the ridge: lots of pines.
scatter(140, -HALF.X + inside, HALF.X - inside, -HALF.Y + inside, RIDGE.Z - RIDGE.Thickness / 2, function(p)
	Props.pine(decorations, p, random:NextNumber(5, 8))
end)

-- Along the river banks: a few bushes and rocks for a nicer shoreline.
for x = -HALF.X + 10, HALF.X - 20, 18 do
	if math.abs(x - RIVER.BridgeX) > 12 then
		Props.bush(decorations, Vector3.new(x + random:NextNumber(-3, 3), 0, RIVER.Z - RIVER.Width / 2 - 2))
		Props.rock(decorations, Vector3.new(x + random:NextNumber(4, 9), 0, RIVER.Z + RIVER.Width / 2 + 2), random:NextNumber(1.2, 2.2))
	end
end

--------------------------------------------------------------------------

local world: WorldTypes.World = {
	Size = SIZE,
	BorderThickness = 40,
	Borders = {
		North = { Kind = "Cliff", Height = 28 },
		-- Low, so the camera (which looks from the south) never loses the player.
		South = { Kind = "Cliff", Height = 6 },
		East = { Kind = "Sea" },
		West = { Kind = "Forest" },
	},

	Roads = ROADS,
	River = RIVER,
	Ridge = RIDGE,

	Villages = VILLAGES,
	StartVillage = StartVillage.Name,
	FixedEnemies = FIXED_ENEMIES,
	LootChests = LOOT_CHESTS,
	Decorations = decorations,

	-- Out in the meadows: mostly one enemy at a time.
	DefaultPool = {
		{ Enemies = { "Builderman" }, Weight = 3 },
		{ Enemies = { "BaconGirl" }, Weight = 3 },
		{ Enemies = { "Builderman", "BaconGirl" }, Weight = 1 },
	},
	Zones = {
		-- The forest is harder: pairs are common.
		{
			Name = "Forest",
			Area = FOREST,
			Pool = {
				{ Enemies = { "BaconGirl" }, Weight = 1 },
				{ Enemies = { "Builderman", "BaconGirl" }, Weight = 2 },
				{ Enemies = { "BaconGirl", "BaconGirl" }, Weight = 2 },
			},
		},
	},
}

return world
