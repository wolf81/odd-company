--!strict
-- The battle state machine. Pure logic: it never touches UI or input.
-- Everything visible (menus, messages, the attack timing bar, the dodge
-- phase) is done through the `hooks` passed to BattleLogic.run, so this
-- module can move to the server later if the game becomes co-op.
--
-- States, in order:
--   PlayerTurn    -> the player picks an action (hooks.chooseAction)
--   ResolveAction -> the attack or act happens
--   CheckEnd      -> all enemies at 0 HP? -> Win
--   EnemyTurn     -> enemies attack (hooks.enemyTurn)
--   CheckEnd      -> player at 0 HP? -> Lose, otherwise back to PlayerTurn

local Damage = require(script.Parent.Damage)
local EnemyTypes = require(script.Parent.Parent.Enemies.EnemyTypes)

local BattleLogic = {}

export type State = "PlayerTurn" | "ResolveAction" | "EnemyTurn" | "CheckEnd" | "Win" | "Lose"
export type Result = "Win" | "Lose"

export type Fighter = {
	name: string,
	hp: number,
	maxHp: number,
	atk: number,
	def: number,
}

export type Enemy = Fighter & {
	id: string,
	data: EnemyTypes.EnemyData,
}

export type Battle = {
	state: State,
	turn: number,
	player: Fighter,
	enemies: { Enemy },
}

-- Attack: hit enemies[target]. Act: do enemies[target]'s act number `act`
-- (1 = Check, 2.. = the enemy's own Acts).
export type Action = { kind: "Attack", target: number } | { kind: "Act", target: number, act: number }

export type Hooks = {
	-- Wait for the player to choose. Only alive enemies may be targeted.
	chooseAction: (battle: Battle) -> Action,
	-- Play the attack; return the timing multiplier (0 = miss, 1 = normal).
	playerAttack: (battle: Battle, target: number) -> number,
	-- Show the hit on the enemy (damage 0 = miss). HP is already updated.
	enemyHit: (battle: Battle, target: number, damage: number) -> (),
	-- Play the enemies' turn; return the list of hits the player took,
	-- as enemy indices (one entry per hit).
	enemyTurn: (battle: Battle) -> { number },
	-- Show a message and wait until the player has read it.
	say: (battle: Battle, text: string) -> (),
	-- Called whenever HP or the state changes, to refresh the display.
	changed: (battle: Battle) -> (),
}

function BattleLogic.new(player: Fighter, enemyData: { EnemyTypes.EnemyData }): Battle
	local enemies: { Enemy } = {}
	for _, data in enemyData do
		table.insert(enemies, {
			id = data.Id,
			data = data,
			name = data.DisplayName,
			hp = data.Stats.HP,
			maxHp = data.Stats.HP,
			atk = data.Stats.ATK,
			def = data.Stats.DEF,
		})
	end
	return {
		state = "PlayerTurn",
		turn = 1,
		player = table.clone(player),
		enemies = enemies,
	}
end

function BattleLogic.isAlive(fighter: Fighter): boolean
	return fighter.hp > 0
end

function BattleLogic.aliveEnemies(battle: Battle): { number }
	local alive = {}
	for i, enemy in battle.enemies do
		if enemy.hp > 0 then
			table.insert(alive, i)
		end
	end
	return alive
end

-- Names of the ACT options for an enemy: "Check" first, then its own acts.
function BattleLogic.actNames(enemy: Enemy): { string }
	local names = { "Check" }
	for _, act in enemy.data.Acts do
		table.insert(names, act.Name)
	end
	return names
end

local function setState(battle: Battle, hooks: Hooks, state: State)
	battle.state = state
	hooks.changed(battle)
end

local function resolve(battle: Battle, hooks: Hooks, action: Action)
	local enemy = battle.enemies[action.target]
	if action.kind == "Attack" then
		local multiplier = hooks.playerAttack(battle, action.target)
		local damage = Damage.compute(battle.player.atk, enemy.def, multiplier)
		if damage <= 0 then
			hooks.enemyHit(battle, action.target, 0)
			hooks.say(battle, "* You missed!")
			return
		end
		enemy.hp = math.max(0, enemy.hp - damage)
		hooks.changed(battle)
		hooks.enemyHit(battle, action.target, damage)
		if enemy.hp <= 0 then
			hooks.say(battle, `* You hit {enemy.name} for {damage}!\n* {enemy.name} was defeated!`)
		else
			hooks.say(battle, `* You hit {enemy.name} for {damage}!\n* {enemy.name} HP: {enemy.hp} / {enemy.maxHp}`)
		end
	else
		if action.act == 1 then
			hooks.say(battle, `* {string.upper(enemy.name)} - ATK {enemy.atk} DEF {enemy.def}\n* {enemy.data.Description}`)
		else
			local act = enemy.data.Acts[action.act - 1]
			hooks.say(battle, if act then act.Message else "* Nothing happens.")
		end
	end
end

-- Runs the whole battle and returns "Win" or "Lose". Yields while hooks wait.
function BattleLogic.run(battle: Battle, hooks: Hooks): Result
	while true do
		setState(battle, hooks, "PlayerTurn")
		local action = hooks.chooseAction(battle)

		setState(battle, hooks, "ResolveAction")
		resolve(battle, hooks, action)

		setState(battle, hooks, "CheckEnd")
		if #BattleLogic.aliveEnemies(battle) == 0 then
			setState(battle, hooks, "Win")
			return "Win"
		end

		setState(battle, hooks, "EnemyTurn")
		local hits = hooks.enemyTurn(battle)
		local total = 0
		for _, enemyIndex in hits do
			local enemy = battle.enemies[enemyIndex]
			if enemy and enemy.hp > 0 then
				total += Damage.compute(enemy.atk, battle.player.def, 1)
			end
		end
		if total > 0 then
			battle.player.hp = math.max(0, battle.player.hp - total)
			hooks.changed(battle)
			hooks.say(battle, `* You took {total} damage.`)
		end

		setState(battle, hooks, "CheckEnd")
		if battle.player.hp <= 0 then
			setState(battle, hooks, "Lose")
			return "Lose"
		end
		battle.turn += 1
	end
end

return BattleLogic
