--!strict
-- Enemy attack patterns for the dodge phase, by name. Enemies list the
-- names they use in their data file (AttackPatterns).
--
-- A pattern spawns bullets over time with api.spawn and api.wait.
-- Positions are pixels inside the box (0,0 = top-left, api.size = width
-- and height). Scale speeds and positions by api.size so patterns work on
-- any screen. Always stop when api.running() becomes false.

local DodgeBox = require(script.Parent.DodgeBox)

-- Builderman's bricks.
local BRICK_COLORS = {
	Color3.fromRGB(196, 40, 28), -- brick red
	Color3.fromRGB(218, 133, 65), -- orange
	Color3.fromRGB(163, 162, 165), -- concrete grey
}

local Patterns: { [string]: DodgeBox.Pattern } = {}

-- Builderman 1: bricks fall from the top, wobbling left and right.
Patterns.FallingBlocks = {
	Duration = 5,
	Run = function(api)
		local s = api.size
		local blockSize = math.floor(s * 0.08)
		while api.running() and api.elapsed() < 4.2 do
			local baseX = api.random:NextNumber(0.1, 0.9) * s
			local phase = api.random:NextNumber(0, math.pi * 2)
			api.spawn({
				position = Vector2.new(baseX, -blockSize),
				velocity = Vector2.new(0, s * 0.45),
				size = Vector2.new(blockSize, blockSize),
				color = BRICK_COLORS[api.random:NextInteger(1, #BRICK_COLORS)],
				update = function(b, _dt)
					b.pos = Vector2.new(baseX + math.sin(b.age * 4 + phase) * s * 0.06, b.pos.Y)
				end,
			})
			api.wait(0.4)
		end
	end,
}

-- Builderman 2: bricks slide in from the left and right sides.
Patterns.SideBlocks = {
	Duration = 5,
	Run = function(api)
		local s = api.size
		local blockSize = math.floor(s * 0.08)
		while api.running() and api.elapsed() < 4.2 do
			local fromLeft = api.random:NextNumber() < 0.5
			local y = api.random:NextNumber(0.1, 0.9) * s
			local x = if fromLeft then -blockSize else s + blockSize
			local vx = (if fromLeft then 1 else -1) * s * 0.55
			api.spawn({
				position = Vector2.new(x, y),
				velocity = Vector2.new(vx, 0),
				size = Vector2.new(blockSize, blockSize),
				color = BRICK_COLORS[api.random:NextInteger(1, #BRICK_COLORS)],
			})
			api.wait(0.5)
		end
	end,
}

-- Builderman 3: rows of bricks (a wall) fall with one gap to slip through.
Patterns.BlockRows = {
	Duration = 5.5,
	Run = function(api)
		local s = api.size
		local blockSize = math.floor(s * 0.08)
		local gapWidth = s * 0.28
		for row = 1, 3 do
			if not api.running() then
				return
			end
			local gapCentre = api.random:NextNumber(0.2, 0.8) * s
			local color = BRICK_COLORS[(row - 1) % #BRICK_COLORS + 1]
			local x = blockSize / 2
			while x < s do
				if math.abs(x - gapCentre) > gapWidth / 2 then
					api.spawn({
						position = Vector2.new(x, -blockSize),
						velocity = Vector2.new(0, s * 0.35),
						size = Vector2.new(blockSize, blockSize),
						color = color,
					})
				end
				x += blockSize + 2
			end
			api.wait(1.3)
		end
	end,
}

return Patterns
