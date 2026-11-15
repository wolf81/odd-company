--!strict
-- The battle state machine. Pure logic: it never touches UI or input.
-- Everything visible (menus, messages, the attack timing bar, the dodge
-- phase) is done through the `hooks` passed to BattleLogic.run, so this
-- module can move to the server later if the game becomes co-op.
--
-- States, in order:
--   PlayerTurn    -> the player picks an action (hooks.chooseAction)
--   ResolveAction -> the attack, act or ally ability happens
--   CheckEnd      -> all enemies at 0 HP? -> Win
--   EnemyTurn     -> burning enemies take damage first (ally ability),
--                    then enemies attack (hooks.enemyTurn)
--   CheckEnd      -> player at 0 HP? -> Lose, otherwise back to PlayerTurn

local AllyTypes = require(script.Parent.Parent.Allies.AllyTypes)
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

-- Damage that keeps hurting an enemy in later rounds (e.g. a hot pizza).
export type Burn = {
	damage: number,
	roundsLeft: number,
	fromTurn: number, -- the turn it was thrown; it burns in the turns after
}

export type Enemy = Fighter & {
	id: string,
	data: EnemyTypes.EnemyData,
	burn: Burn?,
}

-- An ally in the player's team, and the turn their ability is ready again.
export type Ally = {
	data: AllyTypes.AllyData,
	readyOnTurn: number,
}

export type Battle = {
	state: State,
	turn: number,
	player: Fighter,
	enemies: { Enemy },
	allies: { Ally }, -- the team (empty if you're on your own)
}

-- Attack: hit enemies[target]. Act: do enemies[target]'s act number `act`
-- (1 = Check, 2.. = the enemy's own Acts). Ability: allies[ally] uses their
-- ability, aimed at enemies[target] first.
export type Action =
	{ kind: "Attack", target: number }
	| { kind: "Act", target: number, act: number }
	| { kind: "Ability", target: number, ally: number }

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

function BattleLogic.new(player: Fighter, enemyData: { EnemyTypes.EnemyData }, allyData: { AllyTypes.AllyData }): Battle
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
			burn = nil,
		})
	end
	local allies: { Ally } = {}
	for _, data in allyData do
		table.insert(allies, { data = data, readyOnTurn = 1 })
	end
	return {
		state = "PlayerTurn",
		turn = 1,
		player = table.clone(player),
		enemies = enemies,
		allies = allies,
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

-- How many turns until allies[index]'s ability can be used again
-- (0 = ready now). math.huge if there's no such ally.
function BattleLogic.abilityWait(battle: Battle, index: number): number
	local ally = battle.allies[index]
	if not ally then
		return math.huge
	end
	return math.max(0, ally.readyOnTurn - battle.turn)
end

local function setState(battle: Battle, hooks: Hooks, state: State)
	battle.state = state
	hooks.changed(battle)
end

-- Takes `damage` HP from enemies[index] and shows the hit.
local function hitEnemy(battle: Battle, hooks: Hooks, index: number, damage: number)
	local enemy = battle.enemies[index]
	enemy.hp = math.max(0, enemy.hp - damage)
	hooks.changed(battle)
	hooks.enemyHit(battle, index, damage)
end

-- "Defeated!" or the HP left, for the message after a hit.
local function hpLine(enemy: Enemy): string
	if enemy.hp <= 0 then
		return `* {enemy.name} was defeated!`
	end
	return `* {enemy.name} HP: {enemy.hp} / {enemy.maxHp}`
end

-- The enemies an ability hits: the chosen one first, then other alive
-- enemies, up to `maxTargets`.
local function abilityTargets(battle: Battle, first: number, maxTargets: number): { number }
	local targets = { first }
	for _, i in BattleLogic.aliveEnemies(battle) do
		if #targets >= maxTargets then
			break
		end
		if i ~= first then
			table.insert(targets, i)
		end
	end
	return targets
end

local function useAbility(battle: Battle, hooks: Hooks, allyIndex: number, first: number)
	local ally = battle.allies[allyIndex]
	if not ally or BattleLogic.abilityWait(battle, allyIndex) > 0 then
		hooks.say(battle, "* Nothing happens.")
		return
	end
	local ability = ally.data.Ability
	-- Cooldown 3 used on turn 1 -> ready again on turn 5 (waits 3 turns).
	ally.readyOnTurn = battle.turn + ability.Cooldown + 1
	hooks.say(battle, ability.Text)

	for _, i in abilityTargets(battle, first, ability.MaxTargets) do
		local enemy = battle.enemies[i]
		local damage = Damage.compute(ability.Damage, enemy.def, 1)
		hitEnemy(battle, hooks, i, damage)
		if ability.Rounds > 1 and enemy.hp > 0 then
			enemy.burn = { damage = damage, roundsLeft = ability.Rounds - 1, fromTurn = battle.turn }
			hooks.say(battle, `* {enemy.name} took {damage} damage and is burning!\n{hpLine(enemy)}`)
		else
			hooks.say(battle, `* {enemy.name} took {damage} damage!\n{hpLine(enemy)}`)
		end
	end
end

-- At the start of the enemy turn, enemies hit by a burning ability in an
-- earlier round take its damage again.
local function applyBurns(battle: Battle, hooks: Hooks)
	for i, enemy in battle.enemies do
		local burn = enemy.burn
		if burn and enemy.hp > 0 and battle.turn > burn.fromTurn then
			hitEnemy(battle, hooks, i, burn.damage)
			hooks.say(battle, `* {enemy.name} is still burning! {burn.damage} damage.\n{hpLine(enemy)}`)
			burn.roundsLeft -= 1
			if burn.roundsLeft <= 0 then
				enemy.burn = nil
			end
		end
	end
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
		hitEnemy(battle, hooks, action.target, damage)
		hooks.say(battle, `* You hit {enemy.name} for {damage}!\n{hpLine(enemy)}`)
	elseif action.kind == "Ability" then
		useAbility(battle, hooks, action.ally, action.target)
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
		applyBurns(battle, hooks)
		if #BattleLogic.aliveEnemies(battle) == 0 then
			setState(battle, hooks, "Win")
			return "Win"
		end
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
