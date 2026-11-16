--!strict
-- Finds where the ground really is. Terrain is made of 4-stud voxels and
-- its visible surface isn't exactly where it was filled to (in practice
-- it ends up a few studs higher), so instead of guessing we cast a ray
-- straight down and stand things on what it hits: the terrain, or a Part
-- tagged "Walkable" (the bridge deck). Water is ignored, so a spot in the
-- river finds the riverbed.
--
-- Freshly made terrain can't be hit by rays straight away: call
-- Ground.waitUntilReady() after building terrain, before placing things.
--
-- Layouts in src/shared/World use Y as "height above the ground"; use
-- Ground.at() to turn that into a real world position. Works on the
-- server and the client.

local CollectionService = game:GetService("CollectionService")

local Ground = {}

Ground.WalkableTag = "Walkable"

local RAY_START = 200 -- studs up; above every cliff
local RAY_LENGTH = 400

-- Used when a ray hits nothing (e.g. that part of the world isn't loaded
-- on this client yet): the last ground height we did find.
local lastHeight = 0

local function cast(x: number, z: number): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local hitThese: { Instance } = { workspace.Terrain }
	for _, part in CollectionService:GetTagged(Ground.WalkableTag) do
		table.insert(hitThese, part)
	end
	params.FilterDescendantsInstances = hitThese
	params.IgnoreWater = true
	return workspace:Raycast(Vector3.new(x, RAY_START, z), Vector3.new(0, -RAY_LENGTH, 0), params)
end

-- The height of the ground's surface at (x, z).
function Ground.height(x: number, z: number): number
	local hit = cast(x, z)
	if hit then
		lastHeight = hit.Position.Y
	end
	return lastHeight
end

-- `position` with its Y measured from the ground instead of from 0.
function Ground.at(position: Vector3): Vector3
	return Vector3.new(position.X, Ground.height(position.X, position.Z) + position.Y, position.Z)
end

-- Waits (up to `timeout` seconds) until a ray at (x, z) hits the ground.
-- Returns false if it never did.
function Ground.waitUntilReady(x: number, z: number, timeout: number): boolean
	local started = os.clock()
	while not cast(x, z) do
		if os.clock() - started > timeout then
			warn(`[Ground] no ground found at ({x}, {z}) after {timeout} s; placing things at Y = {lastHeight}`)
			return false
		end
		task.wait()
	end
	Ground.height(x, z) -- remember it as the fallback height
	return true
end

return Ground
