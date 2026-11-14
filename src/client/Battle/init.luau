--!strict
-- Runs a battle on the client:
--   start:  freeze the player, fade to black, switch the camera to the dark
--           arena, show the battle UI
--   run:    BattleLogic (shared) drives the turns; the hooks below show
--           menus and messages
--   finish: win -> the enemy disappears; lose -> back to the room's spawn;
--           then fade back and give control back to the player

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BattleLogic = require(ReplicatedStorage.Modules.Battle.BattleLogic)
local Config = require(ReplicatedStorage.Modules.Config)
local Damage = require(ReplicatedStorage.Modules.Battle.Damage)
local EnemyTypes = require(ReplicatedStorage.Modules.Enemies.EnemyTypes)
local Enemies = require(ReplicatedStorage.Modules.Enemies)
local EncounterTrigger = require(script.Parent.EncounterTrigger)
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
local currentEnemyModel: Model? = nil

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

local hooks: BattleLogic.Hooks = {
	chooseAction = function(battle)
		local flavor = flavorText(battle)
		while true do
			BattleUI.setMessage(flavor)
			local command = BattleMenu.choose(BattleUI.commandButtons(), 2, false)
			local target = pickTarget(battle)
			if target then
				if command == 1 then
					return { kind = "Attack", target = target } :: BattleLogic.Action
				end
				local acts = BattleLogic.actNames(battle.enemies[target])
				local act = BattleMenu.choose(BattleUI.showOptions(acts), 2, true)
				if act then
					return { kind = "Act", target = target, act = act } :: BattleLogic.Action
				end
			end
			-- Pressed back: return to the command buttons.
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
		BattleArena.showHit(damage, battle.enemies[target].hp <= 0)
	end,

	-- Step 7: the dodge phase. Each alive enemy runs its next pattern;
	-- only hits that land count. HP drops live as you get hit.
	enemyTurn = function(battle)
		local lines = {}
		local jobs: { DodgeBox.Job } = {}
		for _, i in BattleLogic.aliveEnemies(battle) do
			local data = battle.enemies[i].data
			table.insert(lines, data.AttackText)
			local names = data.AttackPatterns
			if #names > 0 then
				local pattern = Patterns[names[(battle.turn - 1) % #names + 1]]
				if pattern then
					table.insert(jobs, { owner = i, pattern = pattern })
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
		BattleMenu.waitForConfirm()
	end,

	changed = function(battle)
		BattleUI.setPlayerHP(battle.player.hp, battle.player.maxHp)
	end,
}

-- Start / finish

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

	local enemyModel = currentEnemyModel
	if result == "Win" and enemyModel then
		-- Gone for this session (on this client). Step 12 makes it permanent.
		enemyModel:Destroy()
	elseif result == "Lose" and enemyModel then
		local room = enemyModel:FindFirstAncestorWhichIsA("Model")
		local spawnMarker = room and room:FindFirstChild("Spawn")
		if spawnMarker and spawnMarker:IsA("BasePart") then
			PlayerControl.moveTo(spawnMarker.Position)
		end
	elseif enemyModel then
		PlayerControl.pushAwayFrom(enemyModel:GetPivot().Position, Config.BattleExitPushback)
	end
	currentEnemyModel = nil

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

function Battle.start(enemyId: string, enemyModel: Model)
	if active or busy then
		return
	end
	local data = Enemies[enemyId]
	if not data then
		warn(`[Battle] unknown enemy "{enemyId}"`)
		return
	end
	active = true
	busy = true
	currentEnemyModel = enemyModel
	EncounterTrigger.setEnabled(false)
	PlayerControl.freeze()

	Fade.toBlack()

	TopDownCamera.stop()
	local cameraCFrame = BattleArena.show(enemyModel, data.IdleAnimationId)
	RunService:BindToRenderStep(CAMERA_BIND, Enum.RenderPriority.Camera.Value + 1, function()
		local camera = workspace.CurrentCamera
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = Config.BattleCameraFieldOfView
		camera.CFrame = cameraCFrame
	end)

	-- Rooms 1 and 2 have one enemy; room 3 will pass two (step 11).
	local enemyList: { EnemyTypes.EnemyData } = { data }
	local stats = Config.PlayerStats
	local battle = BattleLogic.new({
		name = Players.LocalPlayer.DisplayName,
		hp = stats.HP,
		maxHp = stats.HP,
		atk = stats.ATK,
		def = stats.DEF,
	}, enemyList)

	BattleUI.setMessage("")
	BattleUI.setPlayerHP(battle.player.hp, battle.player.maxHp)
	BattleUI.show()
	print(`[{Config.GameName}] battle started: {data.DisplayName}`)
	Fade.fromBlack()
	busy = false

	battleThread = coroutine.running()
	local result: BattleLogic.Result = BattleLogic.run(battle, hooks)
	local won = result == "Win"
	if won then
		hooks.say(battle, "* YOU WON!\n* You earned 0 EXP and 0 gold.")
	else
		hooks.say(battle, "* You lost...\n* Stay determined! Try again.")
	end
	finish(if won then "Win" else "Lose")
end

-- If the player respawns mid-battle, stop the battle so the room works again.
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
