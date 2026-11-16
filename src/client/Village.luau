--!strict
-- Talking, chests and shops in the villages. The server puts a Talk
-- prompt on each possible ally, an Open prompt on each chest and a Shop
-- prompt on each market stall; this module decides what happens when the
-- player uses one.
--
-- Recruiting: everyone who joins becomes part of your team.
--   Noob:   talk -> "Can I come?" -> Yes -> joins.
--   Elliot: wants the Pizza slice from the chest first. Give it to him,
--           then he asks to come along.
-- Shop: buy swords (add to your ATK) and bandages (heal in battle) with
-- gold from fights and loot chests.
-- Chests: the pizza chest gives an item; loot chests give random gold.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Allies = require(ReplicatedStorage.Modules.Allies)
local AllyTypes = require(ReplicatedStorage.Modules.Allies.AllyTypes)
local Config = require(ReplicatedStorage.Modules.Config)
local Supplies = require(ReplicatedStorage.Modules.Items.Supplies)
local Weapons = require(ReplicatedStorage.Modules.Items.Weapons)
local Battle = require(script.Parent.Battle)
local Dialogue = require(script.Parent.Dialogue)
local Party = require(script.Parent.Party)
local Progress = require(script.Parent.Progress)

local Village = {}

-- Simple quest flags, not an inventory: items the player is carrying, and
-- allies who already got the item they wanted.
local carrying: { [string]: boolean } = {}
local gotWhatTheyWanted: { [string]: boolean } = {}

-- Returns true if the ally is happy to join now (after any quest).
local function doQuest(ally: AllyTypes.AllyData): boolean
	local item = ally.Wants
	if not item or gotWhatTheyWanted[ally.Id] then
		return true
	end
	local lines = ally.Lines
	if not carrying[item] then
		Dialogue.say(lines.NeedItem or "* ...")
		return false
	end
	if not Dialogue.yesNo(lines.OfferItem or `* Give {ally.DisplayName} the {item}?`) then
		return false
	end
	carrying[item] = nil
	gotWhatTheyWanted[ally.Id] = true
	Dialogue.sayAll(lines.Thanks or {})
	return true
end

-- The team is full: pick an ally to send back to the village.
-- Returns false if the player cancelled.
local function makeRoom(): boolean
	local team = Party.allies()
	local names = {}
	for _, member in team do
		table.insert(names, member.DisplayName)
	end
	table.insert(names, "Cancel")
	local choice = Dialogue.ask(`* Your team is full ({#team} allies).\n* Who goes back to the village?`, names)
	local leaving = if choice then team[choice] else nil
	if not leaving then
		return false
	end
	Dialogue.say(leaving.Lines.Leave)
	Party.remove(leaving.Id)
	return true
end

local function talkTo(ally: AllyTypes.AllyData, prompt: ProximityPrompt)
	local lines = ally.Lines
	if Party.has(ally.Id) then
		return -- already in the team (their prompt is off anyway)
	end

	-- Greeting only the first time, until they've had what they wanted.
	if not gotWhatTheyWanted[ally.Id] then
		Dialogue.sayAll(lines.Greeting)
	end
	if not doQuest(ally) then
		return
	end

	if not Dialogue.yesNo(lines.Ask) then
		Dialogue.say(lines.Declined)
		return
	end
	if Party.isFull() and not makeRoom() then
		Dialogue.say(lines.Declined)
		return
	end
	local model = prompt:FindFirstAncestorWhichIsA("Model")
	if model then
		Dialogue.say(lines.Joined)
		Party.join(ally, model, prompt)
	end
end

-- Swings a chest lid open on its back (north) bottom edge, like a hinge,
-- over a third of a second.
local function swingOpen(lid: Model)
	local boxCFrame, size = lid:GetBoundingBox()
	local hinge = CFrame.new(boxCFrame.Position + Vector3.new(0, -size.Y / 2, -size.Z / 2))
	local closed = lid:GetPivot()
	local steps = 12
	for i = 1, steps do
		-- Rotating about X by a negative angle lifts the front (south) edge.
		local angle = math.rad(-105) * i / steps
		lid:PivotTo(hinge * CFrame.Angles(angle, 0, 0) * hinge:Inverse() * closed)
		task.wait(0.33 / steps)
	end
end

-- Opens a chest: gives its item, or random gold for a loot chest
-- (`item` nil).
local function openChest(item: string?, prompt: ProximityPrompt)
	prompt.Enabled = false -- each chest opens once
	local chest = prompt:FindFirstAncestorWhichIsA("Model")
	local lid = chest and chest:FindFirstChild("Lid")
	if lid and lid:IsA("Model") then
		swingOpen(lid)
	end
	if item then
		carrying[item] = true
		Dialogue.say(`* You found a {item}!\n* It's still warm.`)
	else
		local gold = math.random(Config.LootChestGold.Min, Config.LootChestGold.Max)
		Progress.addGold(gold)
		Dialogue.say(`* You found {gold} gold!`)
	end
end

-- What the shop says about buying sword `weapon`, and buys it if possible.
local function buyWeapon(weapon: Weapons.Weapon)
	local current = Progress.weapon()
	if current.Id == weapon.Id then
		Dialogue.say(`* You already have the {weapon.Name}.`)
	elseif current.Attack >= weapon.Attack then
		Dialogue.say(`* Your {current.Name} is already better than that.`)
	elseif Progress.gold() < weapon.Price then
		Dialogue.say(`* The {weapon.Name} costs {weapon.Price} gold.\n* You only have {Progress.gold()}. Win some fights!`)
	elseif Dialogue.yesNo(`* Buy the {weapon.Name} for {weapon.Price} gold?\n* (ATK +{weapon.Attack})`) then
		Progress.buyWeapon(weapon.Id)
		Dialogue.say(`* You bought the {weapon.Name}!\n* Your attacks hit harder now.`)
	end
end

-- Same for a supply (e.g. a Bandage): you can buy one at a time.
local function buySupply(supply: Supplies.Supply)
	local have = Progress.itemCount(supply.Id)
	if have >= Config.MaxItemCount then
		Dialogue.say(`* You can't carry more than {Config.MaxItemCount}.`)
	elseif Progress.gold() < supply.Price then
		Dialogue.say(`* A {supply.Name} costs {supply.Price} gold.\n* You only have {Progress.gold()}.`)
	elseif Dialogue.yesNo(`* Buy a {supply.Name} for {supply.Price} gold?\n* (heals {supply.Heal} HP in battle, you have {have})`) then
		Progress.buySupply(supply.Id)
		Dialogue.say(`* You bought a {supply.Name}! (you have {have + 1})\n* Use it in battle with ITEM.`)
	end
end

-- The shop: a list of what it sells (name and price) plus "Leave".
-- `itemList` is the comma-separated Ids from the village's Shops data;
-- each is a sword (Weapons) or a supply (Supplies).
local function openShop(itemList: string)
	Dialogue.say(`* Welcome to the shop!\n* You have {Progress.gold()} gold.`)
	local ids: { string } = {}
	local labels: { string } = {}
	for _, id in string.split(itemList, ",") do
		local thing = Weapons[id] or Supplies[id]
		if thing then
			table.insert(ids, id)
			table.insert(labels, `{thing.Name} {thing.Price}G`)
		end
	end
	table.insert(labels, "Leave")
	while true do
		local choice = Dialogue.ask("* What would you like?", labels)
		local id = if choice then ids[choice] else nil
		if not id then
			Dialogue.say("* Come back any time!")
			return
		end
		if Weapons[id] then
			buyWeapon(Weapons[id])
		else
			buySupply(Supplies[id])
		end
	end
end

local function onPrompt(prompt: ProximityPrompt, player: Player)
	if player ~= Players.LocalPlayer or Dialogue.isOpen() or Battle.isActive() then
		return
	end
	local allyId = prompt:GetAttribute(Config.AllyPromptAttribute)
	local item = prompt:GetAttribute(Config.ChestPromptAttribute)
	local shopItems = prompt:GetAttribute(Config.ShopPromptAttribute)
	local lootGold = prompt:GetAttribute(Config.ChestGoldAttribute)

	Dialogue.open()
	if typeof(allyId) == "string" and Allies[allyId] then
		talkTo(Allies[allyId], prompt)
	elseif typeof(item) == "string" then
		openChest(item, prompt)
	elseif lootGold == true then
		openChest(nil, prompt)
	elseif typeof(shopItems) == "string" then
		openShop(shopItems)
	end
	Dialogue.close()
end

function Village.start()
	ProximityPromptService.PromptTriggered:Connect(onPrompt)
end

return Village
