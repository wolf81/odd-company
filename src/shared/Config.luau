--!strict
-- Shared settings and tuning numbers. Kept in one place so they're easy
-- to change during playtests.

local Config = {
	GameName = "odd-company",

	-- Top-down camera: where the camera sits relative to the player.
	-- Y = height above, Z = how far "south" (toward the screen bottom).
	-- More Z gives a more tilted view; less Z looks straight down.
	CameraOffset = Vector3.new(0, 36, 14),
	CameraFieldOfView = 60,

	-- Zoom (scroll wheel, or pinch on touch screens). The offset above is
	-- multiplied by the zoom: 0.5 = twice as close, 1.5 = further away.
	CameraZoomMin = 0.4,
	CameraZoomMax = 1.6,
	CameraZoomStep = 0.1, -- per scroll-wheel notch
	CameraZoomSmoothing = 12, -- higher = snappier, lower = smoother

	-- Undertale-style movement: walking only, no jumping.
	AllowJumping = false,
}

return Config
