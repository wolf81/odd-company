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

	-- Enemies: how far (studs) around an enemy touching starts a battle.
	EncounterTriggerPadding = 1.5,
	-- Seconds before the same enemy can start a battle again.
	EncounterCooldown = 3,
	-- CollectionService tag on the invisible box around each enemy.
	EnemyTriggerTag = "EnemyTrigger",

	-- Battle scene: a dark arena built on the client, far from the rooms.
	BattleArenaPosition = Vector3.new(0, 500, 0),
	BattleCameraDistance = 16, -- studs in front of the enemy
	BattleCameraFieldOfView = 45,
	BattleFadeTime = 0.25, -- seconds for the fade to/from black
	-- After leaving a battle the player is pushed this far from the enemy,
	-- so they don't bump straight into it again.
	BattleExitPushback = 5,

	-- Player stats. Damage = max(1, ATK - DEF) x timing multiplier.
	PlayerStats = { HP = 20, ATK = 6, DEF = 0 },
}

return Config
