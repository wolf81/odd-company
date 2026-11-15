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

	-- Village (step 10–11): where the player starts, and talking to people.
	StartRoom = "Village",
	-- How close (studs) you must be to see the Talk / Open prompt.
	InteractDistance = 8,
	-- Attributes on each ProximityPrompt say what it's for.
	AllyPromptAttribute = "AllyId",
	ChestPromptAttribute = "ChestItem",

	-- At most this many allies in the team; to recruit another you send
	-- one back to the village.
	MaxTeamSize = 3,

	-- A recruited ally walks after you along your own path.
	AllyFollowGap = 4, -- studs behind you
	AllyWalkSpeed = 16, -- studs per second (same as the default player speed)
	-- If you jump further than this at once (respawn, lose a battle), the
	-- ally pops straight to you instead of walking.
	AllyTeleportDistance = 25,

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

	-- Attack timing bar (step 6). The cursor crosses the bar in this many
	-- seconds; press near the centre for more damage, too late = miss.
	AttackBarDuration = 1.6,
	AttackMinMultiplier = 0.4, -- pressed at the very edge
	AttackMaxMultiplier = 1.6, -- pressed in the centre
	AttackCriticalZone = 0.08, -- within this fraction of the centre = max damage

	-- Dodge phase (step 7): the heart in the box.
	AttackTextTime = 1.2, -- seconds the enemy's attack line shows first
	DodgeBoxMaxSize = 220, -- pixels; shrinks on short (phone) screens
	DodgeBoxMinSize = 140,
	HeartSpeed = 0.8, -- box widths per second
	HeartHitRadius = 6, -- pixels; smaller than the heart looks, to feel fair
	InvincibilityTime = 1.0, -- seconds after a hit when you can't be hit again
}

return Config
