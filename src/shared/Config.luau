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

	-- Fixed enemies (bridge, forest gate): how far (studs) around an enemy
	-- touching starts a battle.
	EncounterTriggerPadding = 1.5,
	-- Seconds before the same enemy can start a battle again.
	EncounterCooldown = 3,
	-- CollectionService tag on the invisible box around each enemy.
	EnemyTriggerTag = "EnemyTrigger",
	-- ReplicatedStorage folder with one copy of each enemy, for random fights.
	EnemyTemplatesFolder = "EnemyTemplates",

	-- Random fights (Pokémon-style) anywhere except roads and villages.
	-- Every RandomEncounterStep studs you walk there, there's a
	-- RandomEncounterChance chance of a fight (0.05 = 5%): on average a
	-- fight every ~80 studs (about 5 seconds of walking).
	RandomEncounterStep = 4,
	RandomEncounterChance = 0.05,
	-- After a fight, walk at least this far before the next one can start.
	RandomEncounterGrace = 40,

	-- Talking to people in villages.
	-- How close (studs) you must be to see the Talk / Open prompt.
	InteractDistance = 8,
	-- Attributes on each ProximityPrompt say what it's for.
	AllyPromptAttribute = "AllyId",
	ChestPromptAttribute = "ChestItem",
	ChestGoldAttribute = "ChestGold", -- true on loot chests (random gold)
	ShopPromptAttribute = "ShopItems", -- comma-separated weapon Ids

	-- At most this many allies in the team; to recruit another you send
	-- one back to the village.
	MaxTeamSize = 3,

	-- A recruited ally walks after you along your own path.
	AllyFollowGap = 4, -- studs behind you
	AllyWalkSpeed = 16, -- studs per second (same as the default player speed)
	-- If you jump further than this at once (respawn, lose a battle), the
	-- ally pops straight to you instead of walking.
	AllyTeleportDistance = 25,

	-- Battle scene: a dark arena built on the client, high above the world.
	BattleArenaPosition = Vector3.new(0, 500, 0),
	BattleCameraDistance = 16, -- studs in front of the enemy
	BattleCameraFieldOfView = 45,
	BattleFadeTime = 0.25, -- seconds for the fade to/from black
	-- After leaving a battle the player is pushed this far from the enemy,
	-- so they don't bump straight into it again.
	BattleExitPushback = 5,

	-- Player stats. Damage = max(1, ATK - DEF) x timing multiplier.
	-- ATK is low on purpose: buy a better sword in the shop (its Attack is
	-- added), or lean on your allies' special attacks.
	PlayerStats = { HP = 20, ATK = 4, DEF = 0 },
	-- The sword you start with (an Id in src/shared/Items/Weapons.luau).
	StartWeapon = "Stick",
	-- Most of one item (e.g. bandages) you can carry.
	MaxItemCount = 9,
	-- Loot chests out in the world give a random amount of gold in this range.
	LootChestGold = { Min = 5, Max = 15 },

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
	-- With two or more enemies attacking at once, each pattern runs at this
	-- speed (bullets slower and fewer), so the combined attack stays fair.
	MultiEnemyPatternSpeed = 0.75,
	-- Space (studs) between enemies standing side by side in the arena.
	BattleEnemySpacing = 2,
}

return Config
