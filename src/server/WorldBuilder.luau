--!strict
-- Builds the world from src/shared/World at runtime:
--   Terrain: grass ground, dirt roads, a river and sea of water, rock
--            cliffs and the rocky ridge.
--   Parts:   the bridge, village fences, houses/trees/flowers
--            (decorations), chests, and invisible walls that keep the
--            player inside the map and out of the water.
-- Terrain is filled up to Y = 0, but its visible surface can sit a bit
-- higher, so everything is stood on the measured ground (Ground.luau).
-- North is -Z (top of the screen).

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local Ground = require(ReplicatedStorage.Modules.World.Ground)
local Placement = require(ReplicatedStorage.Modules.Placement)
local Props = require(ReplicatedStorage.Modules.World.Props)
local WorldTypes = require(ReplicatedStorage.Modules.World.WorldTypes)

local WorldBuilder = {}

local terrain = workspace.Terrain
local GROUND_DEPTH = 12 -- studs of terrain under the surface
local WALL_HEIGHT = 60 -- invisible walls: taller than anything can reach

local function makePart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- An invisible wall from (x1, z1) to (x2, z2) (a thin box along X or Z).
local function invisibleWall(x1: number, z1: number, x2: number, z2: number, parent: Instance)
	local size = Vector3.new(math.max(math.abs(x2 - x1), 1), WALL_HEIGHT, math.max(math.abs(z2 - z1), 1))
	local wall = makePart("InvisibleWall", size, CFrame.new((x1 + x2) / 2, WALL_HEIGHT / 2 - 2, (z1 + z2) / 2), Color3.new(), parent)
	wall.Transparency = 1
	wall.CanQuery = false
	wall.CastShadow = false
end

-- Fills a box of terrain: (x, z) centre and size on the ground, from
-- `bottom` up to `top` (Y).
local function fill(x: number, z: number, sizeX: number, sizeZ: number, bottom: number, top: number, material: Enum.Material)
	terrain:FillBlock(CFrame.new(x, (bottom + top) / 2, z), Vector3.new(sizeX, top - bottom, sizeZ), material)
end

-- Repaints the top layer of ground inside `rect` (e.g. grass -> dirt road).
local function paint(rect: WorldTypes.Rect, from: Enum.Material, to: Enum.Material)
	local half = rect.Size / 2
	local region = Region3.new(
		Vector3.new(rect.Center.X - half.X, -4, rect.Center.Y - half.Y),
		Vector3.new(rect.Center.X + half.X, 0, rect.Center.Y + half.Y)
	):ExpandToGrid(4)
	terrain:ReplaceMaterial(region, 4, from, to)
end

local function buildGround(world: WorldTypes.World)
	terrain:Clear()
	local extra = world.BorderThickness * 2 + 40
	fill(0, 0, world.Size.X + extra, world.Size.Y + extra, -GROUND_DEPTH, 0, Enum.Material.Grass)
end

local function buildBorders(world: WorldTypes.World, parent: Instance)
	local half = world.Size / 2
	local t = world.BorderThickness
	local fullX = world.Size.X + 2 * t
	local fullZ = world.Size.Y + 2 * t

	-- Each side: where the band outside the map is, and how big.
	local sides: { [string]: { x: number, z: number, sizeX: number, sizeZ: number } } = {
		North = { x = 0, z = -half.Y - t / 2, sizeX = fullX, sizeZ = t },
		South = { x = 0, z = half.Y + t / 2, sizeX = fullX, sizeZ = t },
		East = { x = half.X + t / 2, z = 0, sizeX = t, sizeZ = world.Size.Y },
		West = { x = -half.X - t / 2, z = 0, sizeX = t, sizeZ = world.Size.Y },
	}

	local decorations: { WorldTypes.Decoration } = {}
	for name, border in world.Borders :: { [string]: WorldTypes.Border } do
		local band = sides[name]
		if border.Kind == "Cliff" then
			fill(band.x, band.z, band.sizeX, band.sizeZ, -GROUND_DEPTH, border.Height or 20, Enum.Material.Rock)
		elseif border.Kind == "Sea" then
			-- A sandy beach on the map's edge, then water outside it.
			local beachX = if name == "East" then half.X - 6 elseif name == "West" then -half.X + 6 else band.x
			local beachZ = if name == "South" then half.Y - 6 elseif name == "North" then -half.Y + 6 else band.z
			local alongX = name == "North" or name == "South"
			paint({ Center = Vector2.new(beachX, beachZ), Size = if alongX then Vector2.new(band.sizeX, 12) else Vector2.new(12, band.sizeZ) }, Enum.Material.Grass, Enum.Material.Sand)
			fill(band.x, band.z, band.sizeX, band.sizeZ, -GROUND_DEPTH, 0, Enum.Material.Water)
		elseif border.Kind == "Forest" then
			-- Three thick rows of pines just outside the edge.
			local random = Random.new(7)
			local alongX = name == "North" or name == "South"
			local length = if alongX then band.sizeX else band.sizeZ
			local outward = if name == "West" or name == "North" then -1 else 1
			for row = 0, 2 do
				for along = -length / 2, length / 2, 6 do
					local depth = (row * 6 + 2 + random:NextNumber(-1.5, 1.5)) * outward
					local wobble = random:NextNumber(-2, 2)
					local at = if alongX
						then Vector3.new(along + wobble, 0, (if name == "North" then -half.Y else half.Y) + depth)
						else Vector3.new((if name == "West" then -half.X else half.X) + depth, 0, along + wobble)
					-- No pines standing in the river or inside the ridge.
					local inRiver = math.abs(at.Z - world.River.Z) < world.River.Width / 2 + 2
					local inRidge = math.abs(at.Z - world.Ridge.Z) < world.Ridge.Thickness / 2 + 2
					if not inRiver and not inRidge then
						Props.pine(decorations, at, random:NextNumber(6, 9))
					end
				end
			end
			paint({ Center = Vector2.new(band.x, band.z), Size = Vector2.new(band.sizeX, band.sizeZ) }, Enum.Material.Grass, Enum.Material.LeafyGrass)
		end
	end
	WorldBuilder.buildDecorations(decorations, parent)

	-- Invisible walls on all four edges, whatever the border looks like.
	invisibleWall(-half.X, -half.Y, half.X, -half.Y, parent)
	invisibleWall(-half.X, half.Y, half.X, half.Y, parent)
	invisibleWall(-half.X, -half.Y, -half.X, half.Y, parent)
	invisibleWall(half.X, -half.Y, half.X, half.Y, parent)
end

-- The river: water across the whole map (it flows into the sea), a wooden
-- bridge, and invisible walls on both banks except at the bridge.
local function buildRiver(world: WorldTypes.World, parent: Instance)
	local river = world.River
	local fullX = world.Size.X + world.BorderThickness * 2
	fill(0, river.Z, fullX, river.Width, -8, 0, Enum.Material.Water)

	local bridgeLength = river.Width + 6
	-- Level with the ground on the bank, so you walk straight onto it.
	local bank = Ground.height(river.BridgeX, river.Z + bridgeLength / 2)
	local deck = makePart("BridgeDeck", Vector3.new(river.BridgeWidth, 0.6, bridgeLength), CFrame.new(river.BridgeX, bank + 0.3, river.Z), Props.Colors.Wood, parent)
	deck.Material = Enum.Material.WoodPlanks
	CollectionService:AddTag(deck, Ground.WalkableTag) -- things can stand on it
	for _, side in { -1, 1 } do
		local x = river.BridgeX + side * (river.BridgeWidth / 2 - 0.2)
		local rail = makePart("BridgeRail", Vector3.new(0.4, 0.4, bridgeLength), CFrame.new(x, bank + 2, river.Z), Props.Colors.DarkWood, parent)
		rail.Material = Enum.Material.Wood
		for z = -bridgeLength / 2, bridgeLength / 2, 5 do
			local post = makePart("BridgePost", Vector3.new(0.5, 2.2, 0.5), CFrame.new(x, bank + 1.1, river.Z + z), Props.Colors.DarkWood, parent)
			post.Material = Enum.Material.Wood
		end
		-- The rails are too low to stop anyone, so block the sides too.
		invisibleWall(x, river.Z - bridgeLength / 2, x, river.Z + bridgeLength / 2, parent)
	end

	local half = world.Size.X / 2
	local gapWest = river.BridgeX - river.BridgeWidth / 2
	local gapEast = river.BridgeX + river.BridgeWidth / 2
	for _, bank in { river.Z - river.Width / 2, river.Z + river.Width / 2 } do
		invisibleWall(-half, bank, gapWest, bank, parent)
		invisibleWall(gapEast, bank, half, bank, parent)
	end
end

-- The rocky ridge across the map, with one gap for the road.
local function buildRidge(world: WorldTypes.World, parent: Instance)
	local ridge = world.Ridge
	local half = world.Size.X / 2 + world.BorderThickness
	local gapWest = ridge.GapX - ridge.GapWidth / 2
	local gapEast = ridge.GapX + ridge.GapWidth / 2
	fill((-half + gapWest) / 2, ridge.Z, gapWest + half, ridge.Thickness, -GROUND_DEPTH, ridge.Height, Enum.Material.Rock)
	fill((gapEast + half) / 2, ridge.Z, half - gapEast, ridge.Thickness, -GROUND_DEPTH, ridge.Height, Enum.Material.Rock)
	-- Terrain edges are steep, but make sure nobody climbs over.
	local north = ridge.Z - ridge.Thickness / 2
	local south = ridge.Z + ridge.Thickness / 2
	for _, z in { north, south } do
		invisibleWall(-half, z, gapWest, z, parent)
		invisibleWall(gapEast, z, half, z, parent)
	end
end

local function buildRoads(world: WorldTypes.World)
	for _, road in world.Roads do
		paint(road, Enum.Material.Grass, Enum.Material.Ground)
	end
end

-- A low wooden fence around the village, with an 8-stud gate gap in the
-- middle of each side listed in FenceGates.
local function buildFence(village: WorldTypes.Village, parent: Instance)
	local center, size = village.Area.Center, village.Area.Size
	local gates = village.FenceGates or {}
	local gateWidth = 8
	local wood = Props.Colors.Wood

	local function side(name: WorldTypes.Side, from: Vector3, to: Vector3)
		local length = (to - from).Magnitude
		local dir = (to - from).Unit
		local pieces: { { number } } = { { 0, length } }
		if table.find(gates, name) then
			pieces = { { 0, length / 2 - gateWidth / 2 }, { length / 2 + gateWidth / 2, length } }
		end
		for _, piece in pieces do
			local a, b = piece[1], piece[2]
			local mid = Ground.at(from + dir * (a + b) / 2)
			local rail = makePart("FenceRail", Vector3.new(0.3, 0.3, b - a), CFrame.lookAt(mid + Vector3.new(0, 1.1, 0), mid + Vector3.new(0, 1.1, 0) + dir), wood, parent)
			rail.Material = Enum.Material.Wood
			-- Invisible blocker the full fence height, so it's a real fence.
			local blocker = makePart("FenceBlock", Vector3.new(0.3, 3, b - a), CFrame.lookAt(mid + Vector3.new(0, 1.5, 0), mid + Vector3.new(0, 1.5, 0) + dir), wood, parent)
			blocker.Transparency = 1
			blocker.CanQuery = false
			for d = a, b, 3 do
				local p = Ground.at(from + dir * d)
				local post = makePart("FencePost", Vector3.new(0.4, 1.6, 0.4), CFrame.new(p + Vector3.new(0, 0.8, 0)), Props.Colors.DarkWood, parent)
				post.Material = Enum.Material.Wood
			end
		end
	end

	local x1, x2 = center.X - size.X / 2, center.X + size.X / 2
	local z1, z2 = center.Y - size.Y / 2, center.Y + size.Y / 2
	side("North", Vector3.new(x1, 0, z1), Vector3.new(x2, 0, z1))
	side("South", Vector3.new(x1, 0, z2), Vector3.new(x2, 0, z2))
	side("West", Vector3.new(x1, 0, z1), Vector3.new(x1, 0, z2))
	side("East", Vector3.new(x2, 0, z1), Vector3.new(x2, 0, z2))
end

local function buildDecoration(d: WorldTypes.Decoration, parent: Instance)
	-- Position is the bottom centre (Y = height above the ground), so
	-- stand it on the ground and lift by half its height.
	local position = Ground.at(d.Position) + Vector3.new(0, d.Size.Y / 2, 0)
	local part = makePart(d.Name, d.Size, CFrame.new(position), d.Color, parent)
	part.Material = d.Material or Enum.Material.SmoothPlastic
	part.Transparency = d.Transparency or 0
	part.CanCollide = d.CanCollide ~= false
	part.CastShadow = part.CanCollide -- small things (flowers, glass) don't need shadows

	if d.Shape == "Ball" then
		part.Shape = Enum.PartType.Ball
	elseif d.Shape == "Cylinder" then
		-- Roblox cylinders lie along X; turn it upright so its length
		-- (Size.X) becomes the height.
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(d.Size.Y, d.Size.X, d.Size.X)
		part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	end
end

function WorldBuilder.buildDecorations(decorations: { WorldTypes.Decoration }, parent: Instance)
	for _, d in decorations do
		buildDecoration(d, parent)
	end
end

-- A wooden treasure chest, front (with the lock) facing south toward the
-- camera: plank body on a dark base, metal bands, a gold lock, and a
-- stepped lid (like the cottage roofs) in its own "Lid" model so the
-- client can swing it open on its back edge. The "Open" prompt is on the
-- body; the client (src/client/Village) gives the item.
local CHEST_WOOD = Color3.fromRGB(150, 95, 50)
local CHEST_DARK = Color3.fromRGB(85, 55, 30)
local CHEST_METAL = Color3.fromRGB(60, 60, 65)
local CHEST_GOLD = Color3.fromRGB(230, 180, 60)

local function buildChest(chest: WorldTypes.ChestLayout, parent: Instance)
	local model = Instance.new("Model")
	model.Name = "Chest"
	local at = Ground.at(chest.Position)
	local width, height, depth = 3, 1.6, 2

	local function piece(name: string, size: Vector3, centre: Vector3, color: Color3, material: Enum.Material, into: Instance): Part
		local part = makePart(name, size, CFrame.new(at + centre), color, into)
		part.Material = material
		return part
	end

	piece("Base", Vector3.new(width + 0.2, 0.2, depth + 0.2), Vector3.new(0, 0.1, 0), CHEST_DARK, Enum.Material.Wood, model)
	local body = piece("Body", Vector3.new(width, height - 0.2, depth), Vector3.new(0, 0.2 + (height - 0.2) / 2, 0), CHEST_WOOD, Enum.Material.WoodPlanks, model)
	-- Glows warm inside; you only see it once the lid is open.
	piece("Inside", Vector3.new(width - 0.4, 0.05, depth - 0.4), Vector3.new(0, height + 0.01, 0), Color3.fromRGB(255, 210, 120), Enum.Material.Neon, model)
	for _, side in { -1, 1 } do
		piece("Band", Vector3.new(0.25, height - 0.15, depth + 0.06), Vector3.new(side * 1, 0.2 + (height - 0.15) / 2, 0), CHEST_METAL, Enum.Material.Metal, model)
	end
	piece("Lock", Vector3.new(0.5, 0.6, 0.12), Vector3.new(0, height - 0.25, depth / 2 + 0.06), CHEST_GOLD, Enum.Material.Metal, model)

	-- The lid: three stepped layers plus its own metal bands.
	local lid = Instance.new("Model")
	lid.Name = "Lid"
	local y = height
	for i, layer in { Vector3.new(width + 0.1, 0.35, depth + 0.1), Vector3.new(width, 0.25, depth * 0.75), Vector3.new(width - 0.1, 0.18, depth * 0.45) } do
		piece(`Lid{i}`, layer, Vector3.new(0, y + layer.Y / 2, 0), CHEST_WOOD, Enum.Material.WoodPlanks, lid)
		y += layer.Y
	end
	for _, side in { -1, 1 } do
		piece("LidBand", Vector3.new(0.27, 0.37, depth + 0.14), Vector3.new(side * 1, height + 0.18, 0), CHEST_METAL, Enum.Material.Metal, lid)
	end
	piece("LidLock", Vector3.new(0.4, 0.3, 0.12), Vector3.new(0, height + 0.1, depth / 2 + 0.11), CHEST_GOLD, Enum.Material.Metal, lid)
	lid.Parent = model

	model.Parent = parent

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Open"
	prompt.ObjectText = "Chest"
	prompt.MaxActivationDistance = Config.InteractDistance
	prompt.RequiresLineOfSight = false
	if chest.Item then
		prompt:SetAttribute(Config.ChestPromptAttribute, chest.Item)
	else
		prompt:SetAttribute(Config.ChestGoldAttribute, true)
	end
	prompt.Parent = body
end

-- The shop's sign ("SHOP", on the front of the awning) and its "Shop"
-- prompt on the counter. The stall itself is Props.stall (decorations).
-- The client (src/client/Village) runs the shop.
local function buildShop(shop: WorldTypes.ShopLayout, parent: Instance)
	local at = Ground.at(shop.Position)

	local sign = makePart("ShopSign", Vector3.new(3.2, 1.1, 0.2), CFrame.new(at + Vector3.new(0, 5, 2.2)), Props.Colors.DarkWood, parent)
	sign.Material = Enum.Material.Wood
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back -- +Z: the side facing south, toward the camera
	surface.CanvasSize = Vector2.new(320, 110)
	surface.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Arcade
	label.Text = "SHOP"
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 215, 80)
	label.Parent = surface

	-- Invisible box on the counter that carries the prompt.
	local counter = makePart("ShopCounter", Vector3.new(6, 1.6, 1.4), CFrame.new(at + Vector3.new(0, 0.8, 1)), Color3.new(), parent)
	counter.Transparency = 1
	counter.CanCollide = false
	counter.CanQuery = false

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Market stall"
	prompt.MaxActivationDistance = Config.InteractDistance
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute(Config.ShopPromptAttribute, table.concat(shop.Items, ","))
	prompt.Parent = counter
end

local function setLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.25
		atmosphere.Haze = 1
		atmosphere.Color = Color3.fromRGB(200, 215, 230)
		atmosphere.Parent = Lighting
	end
end

-- Builds everything into a "World" folder in Workspace and returns it.
-- Enemies and allies are added by Main.server.
function WorldBuilder.build(world: WorldTypes.World): Folder
	local existing = workspace:FindFirstChild("World")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "World"
	folder.Parent = workspace

	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	scenery.Parent = folder

	setLighting()
	buildGround(world)
	buildRoads(world)
	-- New terrain can't be hit by rays straight away; wait until it can,
	-- so Ground puts everything on the real surface (not buried in it).
	local probe = world.Villages[1].Area.Center
	Ground.waitUntilReady(probe.X, probe.Y, 10)
	buildBorders(world, scenery)
	buildRiver(world, scenery)
	buildRidge(world, scenery)
	for _, village in world.Villages do
		local villageFolder = Instance.new("Folder")
		villageFolder.Name = village.Name
		villageFolder.Parent = folder
		paint(village.Area, Enum.Material.Grass, Enum.Material.LeafyGrass)
		buildFence(village, villageFolder)
		WorldBuilder.buildDecorations(village.Decorations, villageFolder)
		for _, chest in village.Chests do
			buildChest(chest, villageFolder)
		end
		for _, shop in village.Shops do
			buildShop(shop, villageFolder)
		end
	end
	WorldBuilder.buildDecorations(world.Decorations, scenery)
	for _, chest in world.LootChests do
		buildChest(chest, scenery)
	end
	return folder
end

-- Places a character standing at `position` (on the ground there),
-- facing north. Works for any avatar size (R6 or R15).
function WorldBuilder.placeCharacter(character: Model, position: Vector3)
	-- Lift 0.2 so the avatar drops onto the ground rather than starting in it.
	Placement.standOnFloor(character, Ground.at(position), Vector3.new(0, 0, -1), 0.2)
end

return WorldBuilder
