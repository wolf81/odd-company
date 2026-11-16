--!strict
-- Runs a battle on the client:
--   start:  freeze the player, fade to black, switch the camera to the dark
--           arena, show the battle UI
--   run:    BattleLogic (shared) drives the turns; the hooks below show
--           menus and messages
--   finish: win -> a fixed enemy disappears; lose -> back to the last
--           village you visited;
--           then fade back and give control back to the player

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BattleLogic = require(ReplicatedStorage.Modules.Battle.BattleLogic)
local Supplies = require(ReplicatedStorage.Modules.Items.Supplies)
local Config = require(ReplicatedStorage.Modules.Config)
local Damage = require(ReplicatedStorage.Modules.Battle.Damage)
local EnemyTypes = require(ReplicatedStorage.Modules.Enemies.EnemyTypes)
local Enemies = require(ReplicatedStorage.Modules.Enemies)
local EncounterTrigger = require(script.Parent.EncounterTrigger)
local Checkpoint = require(script.Parent.Checkpoint)
local Party = require(script.Parent.Party)
local Progress = require(script.Parent.Progress)
local PlayerControl = require(script.Parent.PlayerControl)
local TopDownCamera = require(script.Parent.TopDownCamera)
local BattleArena = require(script.BattleArena)
local BattleMenu = require(script.BattleMenu)
local BattleUI = require(script.BattleUI)
local DodgeBox = require(script.DodgeBox)
local Fade = require(script.Fade)
local Patterns = require(script.Patterns)

local CAMERA_BIND = "BattleCamera"

local Battle = {}

local active = false
local busy = false -- true while fading in or out
local battleThread: thread? = nil
local currentEnemyModels: { Model } = {} -- fixed enemies in this fight (none in random fights)

-- Hooks: how the shared battle logic shows things and asks for input.

local function pickTarget(battle: BattleLogic.Battle): number?
	local alive = BattleLogic.aliveEnemies(battle)
	if #alive == 1 then
		return alive[1]
	end
	local names = {}
	for _, i in alive do
		table.insert(names, battle.enemies[i].name)
	end
	local choice = BattleMenu.choose(BattleUI.showOptions(names), 2, true)
	return if choice then alive[choice] else nil
end

local function flavorText(battle: BattleLogic.Battle): string
	local alive = BattleLogic.aliveEnemies(battle)
	local enemy = battle.enemies[alive[math.random(1, #alive)]]
	local lines = enemy.data.FlavorText
	return lines[math.random(1, #lines)]
end

-- Shows the team's names and the ALLY button (hidden with no team).
local function showTeam(battle: BattleLogic.Battle)
	local names = {}
	for _, ally in battle.allies do
		table.insert(names, ally.data.DisplayName)
	end
	BattleUI.setTeam(names)
end

-- Which ally acts. With one ally there's nothing to choose. The list shows
-- each ability and the turns left while it cools down ("Elliot: PIZZA 2").
local function pickAlly(battle: BattleLogic.Battle): number?
	if #battle.allies == 1 then
		return 1
	end
	local labels = {}
	for i, ally in battle.allies do
		local wait = BattleLogic.abilityWait(battle, i)
		local button = ally.data.Ability.Button
		table.insert(labels, if wait > 0 then `{ally.data.DisplayName}: {button} {wait}` else `{ally.data.DisplayName}: {button}`)
	end
	return BattleMenu.choose(BattleUI.showOptions(labels), 2, true)
end

local ATTACK, ACT, ITEM, ALLY = 1, 2, 3, 4 -- command button order

-- ITEM: pick a supply you carry ("Bandage x2"). nil = back, or you have
-- none (then a message says where to buy them).
local function chooseItem(battle: BattleLogic.Battle): BattleLogic.Action?
	local ids = {}
	local labels = {}
	for id, count in battle.items do
		local supply = Supplies[id]
		if supply and count > 0 then
			table.insert(ids, id)
			table.insert(labels, `{supply.Name} x{count}`)
		end
	end
	if #ids == 0 then
		BattleUI.setMessage("* You don't have any items.\n* The village shop sells bandages.")
		BattleUI.setContinueHint(true)
		BattleMenu.waitForConfirm()
		BattleUI.setContinueHint(false)
		return nil
	end
	local choice = BattleMenu.choose(BattleUI.showOptions(labels), 2, true)
	return if choice then { kind = "Item", item = ids[choice] } :: BattleLogic.Action else nil
end

-- An ally's ability: pick the ally, then a target if it hits one enemy;
-- abilities that hit several start with the first alive enemy.
-- nil = pressed back, or the ability isn't ready yet.
local function chooseAbility(battle: BattleLogic.Battle): BattleLogic.Action?
	local index = pickAlly(battle)
	local ally = if index then battle.allies[index] else nil
	if not index or not ally then
		return nil
	end
	local wait = BattleLogic.abilityWait(battle, index)
	if wait > 0 then
		local turns = if wait == 1 then "1 more turn" else `{wait} more turns`
		BattleUI.setMessage(`* {ally.data.DisplayName} needs {turns} before using {ally.data.Ability.Name} again.`)
		BattleUI.setContinueHint(true)
		BattleMenu.waitForConfirm()
		BattleUI.setContinueHint(false)
		return nil
	end
	local target = if ally.data.Ability.MaxTargets == 1 then pickTarget(battle) else BattleLogic.aliveEnemies(battle)[1]
	return if target then { kind = "Ability", target = target, ally = index } :: BattleLogic.Action else nil
end

local hooks: BattleLogic.Hooks = {
	chooseAction = function(battle)
		local flavor = flavorText(battle)
		while true do
			BattleUI.setMessage(flavor)
			showTeam(battle)
			local buttons = BattleUI.commandButtons()
			BattleUI.setCommandsEnabled(true)
			local command = BattleMenu.choose(buttons, #buttons, false)
			BattleUI.setCommandsEnabled(false)
			if command == ALLY then
				local action = chooseAbility(battle)
				if action then
					return action
				end
			elseif command == ITEM then
				local action = chooseItem(battle)
				if action then
					return action
				end
			else
				local target = pickTarget(battle)
				if target and command == ATTACK then
					return { kind = "Attack", target = target } :: BattleLogic.Action
				elseif target and command == ACT then
					local acts = BattleLogic.actNames(battle.enemies[target])
					local act = BattleMenu.choose(BattleUI.showOptions(acts), 2, true)
					if act then
						return { kind = "Act", target = target, act = act } :: BattleLogic.Action
					end
				end
			end
			-- Pressed back (or ability not ready): back to the command buttons.
		end
	end,

	-- Step 6: timing bar. The cursor slides left to right; press (key,
	-- click or tap) to strike. Centre = most damage, no press = miss.
	playerAttack = function(_battle, _target)
		local _, cursor = BattleUI.showAttackBar()
		local duration = Config.AttackBarDuration
		local startTime = os.clock()
		local function progress(): number
			return math.clamp((os.clock() - startTime) / duration, 0, 1)
		end
		local moving = RunService.RenderStepped:Connect(function()
			cursor.Position = UDim2.fromScale(progress(), 0.5)
		end)
		local pressed = BattleMenu.waitForConfirm(duration)
		moving:Disconnect()
		local p = progress()
		cursor.Position = UDim2.fromScale(p, 0.5)

		local multiplier = 0
		if pressed then
			local fromCentre = math.abs(p - 0.5) * 2 -- 0 = centre, 1 = edge
			if fromCentre <= Config.AttackCriticalZone then
				multiplier = Config.AttackMaxMultiplier
			else
				local minM, maxM = Config.AttackMinMultiplier, Config.AttackMaxMultiplier
				multiplier = minM + (maxM - minM) * (1 - fromCentre)
			end
			-- Blink the cursor to show where it stopped.
			for i = 1, 4 do
				cursor.BackgroundTransparency = if i % 2 == 1 then 0.8 else 0
				task.wait(0.08)
			end
		end
		return multiplier
	end,

	enemyHit = function(battle, target, damage)
		BattleArena.showHit(target, damage, battle.enemies[target].hp <= 0)
	end,

	-- Step 7: the dodge phase. Each alive enemy runs its next pattern;
	-- only hits that land count. HP drops live as you get hit.
	-- With several enemies, each starts at a different pattern (so two of
	-- the same enemy don't throw the same thing), and all run a bit slower.
	enemyTurn = function(battle)
		local lines = {}
		local jobs: { DodgeBox.Job } = {}
		local alive = BattleLogic.aliveEnemies(battle)
		local speed = if #alive > 1 then Config.MultiEnemyPatternSpeed else 1
		for position, i in alive do
			local data = battle.enemies[i].data
			if not table.find(lines, data.AttackText) then
				table.insert(lines, data.AttackText)
			end
			local names = data.AttackPatterns
			if #names > 0 then
				local pattern = Patterns[names[(battle.turn + position - 2) % #names + 1]]
				if pattern then
					table.insert(jobs, { owner = i, pattern = pattern, speed = speed })
				end
			end
		end
		BattleUI.setMessage(table.concat(lines, "\n"))
		task.wait(Config.AttackTextTime)
		if #jobs == 0 then
			return {}
		end

		local previewHp = battle.player.hp
		return DodgeBox.run(jobs, function(owner)
			local enemy = battle.enemies[owner]
			previewHp = math.max(0, previewHp - Damage.compute(enemy.atk, battle.player.def, 1))
			BattleUI.setPlayerHP(previewHp, battle.player.maxHp)
			return previewHp <= 0
		end)
	end,

	say = function(_battle, text)
		BattleUI.setMessage(text)
		BattleUI.setContinueHint(true)
		BattleMenu.waitForConfirm()
		BattleUI.setContinueHint(false)
	end,

	changed = function(battle)
		BattleUI.setPlayerHP(battle.player.hp, battle.player.maxHp)
	end,
}

-- Start / finish

-- Everyone who fights together with `enemyModel`: the enemies in the same
-- folder with the same EncounterGroup, or just this one if it has none.
-- Sorted west to east, so enemy 1 is on the left in the arena too.
local function encounterGroup(enemyModel: Model): { Model }
	local group = enemyModel:GetAttribute("EncounterGroup")
	local folder = enemyModel.Parent
	if group == nil or not folder then
		return { enemyModel }
	end
	local models = {}
	for _, other in folder:GetChildren() do
		if other:IsA("Model") and other:GetAttribute("EncounterGroup") == group then
			table.insert(models, other)
		end
	end
	table.sort(models, function(a, b)
		return a:GetPivot().Position.X < b:GetPivot().Position.X
	end)
	return models
end

local function finish(result: BattleLogic.Result?)
	if not active then
		return
	end
	busy = true
	BattleMenu.cancel()
	DodgeBox.cancel()

	Fade.toBlack()

	BattleUI.hide()
	BattleArena.hide()
	RunService:UnbindFromRenderStep(CAMERA_BIND)

	-- Only fixed enemies (bridge, forest gate) are in the world; random
	-- fights have nothing to remove.
	local fixed = currentEnemyModels
	if result == "Win" then
		-- Gone for this session (on this client). Saving comes later.
		for _, model in fixed do
			model:Destroy()
		end
	elseif result == "Lose" then
		-- Back to the last village you visited, with full HP next fight.
		PlayerControl.moveTo(Checkpoint.position())
	elseif fixed[1] then
		PlayerControl.pushAwayFrom(fixed[1]:GetPivot().Position, Config.BattleExitPushback)
	end
	currentEnemyModels = {}

	PlayerControl.unfreeze()
	TopDownCamera.start()
	print(`[{Config.GameName}] battle ended: {result or "cancelled"}`)
	Fade.fromBlack()

	active = false
	busy = false
	battleThread = nil
	-- Short grace period before enemies can start a new battle.
	task.delay(1, function()
		if not active then
			EncounterTrigger.setEnabled(true)
		end
	end)
end

function Battle.isActive(): boolean
	return active
end

-- "* A wild Bacon girl appears!" or "* Builderman and Bacon girl appear!"
local function wildIntro(battle: BattleLogic.Battle): string
	local names = {}
	for _, enemy in battle.enemies do
		table.insert(names, enemy.name)
	end
	if #names == 1 then
		return `* A wild {names[1]} appears!`
	end
	local last = table.remove(names) :: string
	return `* {table.concat(names, ", ")} and {last} appear!`
end

-- Runs one battle against `models` (shown in the arena, left to right).
-- `fixedModels` are the world's enemies to remove if you win (empty for
-- random fights).
local function runBattle(models: { Model }, fixedModels: { Model }, wild: boolean)
	local enemyList: { EnemyTypes.EnemyData } = {}
	local idleIds: { string? } = {}
	for i, model in models do
		local id = model:GetAttribute("EnemyId")
		local data = if typeof(id) == "string" then Enemies[id] else nil
		if not data then
			warn(`[Battle] unknown enemy "{id}"`)
			return
		end
		enemyList[i] = data
		idleIds[i] = data.IdleAnimationId
	end
	active = true
	busy = true
	currentEnemyModels = fixedModels
	EncounterTrigger.setEnabled(false)
	PlayerControl.freeze()

	Fade.toBlack()

	TopDownCamera.stop()
	local cameraCFrame = BattleArena.show(models, idleIds)
	RunService:BindToRenderStep(CAMERA_BIND, Enum.RenderPriority.Camera.Value + 1, function()
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = Config.BattleCameraFieldOfView
		camera.CFrame = cameraCFrame
	end)

	local stats = Config.PlayerStats
	local battle = BattleLogic.new({
		name = Players.LocalPlayer.DisplayName,
		hp = stats.HP,
		maxHp = stats.HP,
		atk = Progress.attack(), -- base ATK + your sword
		def = stats.DEF,
	}, enemyList, Party.allies(), Progress.items())

	BattleUI.setMessage("")
	BattleUI.setCommandsEnabled(false)
	BattleUI.setPlayerHP(battle.player.hp, battle.player.maxHp)
	showTeam(battle)
	BattleUI.show()
	print(`[{Config.GameName}] battle started: {#enemyList} enemies{if wild then " (random)" else ""}`)
	Fade.fromBlack()
	busy = false

	battleThread = coroutine.running()
	if wild then
		hooks.say(battle, wildIntro(battle))
	end
	local result: BattleLogic.Result = BattleLogic.run(battle, hooks)
	Progress.setItems(battle.items) -- bandages used in battle are gone
	local won = result == "Win"
	if won then
		local gold = BattleLogic.goldReward(battle, Random.new())
		Progress.addGold(gold)
		hooks.say(battle, if gold > 0 then `* YOU WON!\n* You found {gold} gold.` else "* YOU WON!\n* No gold this time.")
	else
		hooks.say(battle, "* You lost...\n* Stay determined! Try again.")
	end
	finish(if won then "Win" else "Lose")
end

-- Starts a battle against a fixed enemy in the world (and everyone in its
-- encounter group). Called when the player touches it.
-- (`_enemyId` comes from the trigger; each model carries its own EnemyId.)
function Battle.start(_enemyId: string, enemyModel: Model)
	if active or busy then
		return
	end
	local models = encounterGroup(enemyModel)
	runBattle(models, models, false)
end

-- Starts a random fight against these enemies (Ids), shown using the
-- templates the server put in ReplicatedStorage.
function Battle.startWild(enemyIds: { string })
	if active or busy then
		return
	end
	local templates = ReplicatedStorage:FindFirstChild(Config.EnemyTemplatesFolder)
	local models = {}
	for _, id in enemyIds do
		local template = templates and templates:FindFirstChild(id)
		if not template or not template:IsA("Model") then
			warn(`[Battle] no template for enemy "{id}"`)
			return
		end
		table.insert(models, template)
	end
	runBattle(models, {}, true)
end

-- If the player respawns mid-battle, stop the battle so the world works again.
Players.LocalPlayer.CharacterAdded:Connect(function()
	if active and not busy then
		local thread = battleThread
		if thread and thread ~= coroutine.running() then
			task.cancel(thread)
		end
		finish(nil)
	end
end)

return Battle
