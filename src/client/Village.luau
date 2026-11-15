--!strict
-- Talking and chests in the village (step 11). The server puts a Talk
-- prompt on each possible ally and an Open prompt on each chest; this
-- module decides what happens when the player uses one.
--
-- Recruiting: everyone who joins becomes part of your team.
--   Noob:   talk -> "Can I come?" -> Yes -> joins.
--   Elliot: wants the Pizza slice from the chest first. Give it to him,
--           then he asks to come along.

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Allies = require(ReplicatedStorage.Modules.Allies)
local AllyTypes = require(ReplicatedStorage.Modules.Allies.AllyTypes)
local Config = require(ReplicatedStorage.Modules.Config)
local Battle = require(script.Parent.Battle)
local Dialogue = require(script.Parent.Dialogue)
local Party = require(script.Parent.Party)

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

local function openChest(item: string, prompt: ProximityPrompt)
	prompt.Enabled = false -- each chest opens once
	local box = prompt.Parent
	local lid = box and box:FindFirstChildWhichIsA("BasePart")
	if lid then
		-- "Open" the lid: tilt it back.
		lid.CFrame = lid.CFrame * CFrame.new(0, 0.6, 0.9) * CFrame.Angles(math.rad(-70), 0, 0)
	end
	carrying[item] = true
	Dialogue.say(`* You found a {item}!\n* It's still warm.`)
end

local function onPrompt(prompt: ProximityPrompt, player: Player)
	if player ~= Players.LocalPlayer or Dialogue.isOpen() or Battle.isActive() then
		return
	end
	local allyId = prompt:GetAttribute(Config.AllyPromptAttribute)
	local item = prompt:GetAttribute(Config.ChestPromptAttribute)

	Dialogue.open()
	if typeof(allyId) == "string" and Allies[allyId] then
		talkTo(Allies[allyId], prompt)
	elseif typeof(item) == "string" then
		openChest(item, prompt)
	end
	Dialogue.close()
end

function Village.start()
	ProximityPromptService.PromptTriggered:Connect(onPrompt)
end

return Village
