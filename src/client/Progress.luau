--!strict
-- The player's gold, sword and items (bandages). Client-only like the
-- battle, and forgotten when you leave the game (saving comes in the
-- Systems phase).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Config)
local Supplies = require(ReplicatedStorage.Modules.Items.Supplies)
local Weapons = require(ReplicatedStorage.Modules.Items.Weapons)

local Progress = {}

local gold = 0
local weaponId = Config.StartWeapon
local items: { [string]: number } = {} -- supply Id -> how many you carry

-- Fires whenever gold, the sword or items change (the HUD listens to it).
local changedEvent = Instance.new("BindableEvent")
Progress.Changed = changedEvent.Event

function Progress.gold(): number
	return gold
end

function Progress.addGold(amount: number)
	gold += amount
	changedEvent:Fire()
end

function Progress.weapon(): Weapons.Weapon
	return Weapons[weaponId] or Weapons[Config.StartWeapon]
end

-- Buys sword `id` if you have enough gold. Returns true if it worked.
function Progress.buyWeapon(id: string): boolean
	local weapon = Weapons[id]
	if not weapon or gold < weapon.Price then
		return false
	end
	gold -= weapon.Price
	weaponId = id
	changedEvent:Fire()
	return true
end

-- The player's ATK in battle: base ATK plus the sword's Attack.
function Progress.attack(): number
	return Config.PlayerStats.ATK + Progress.weapon().Attack
end

function Progress.itemCount(id: string): number
	return items[id] or 0
end

-- A copy of all items, for a battle to use up.
function Progress.items(): { [string]: number }
	return table.clone(items)
end

-- After a battle: what's left of the items it used.
function Progress.setItems(newItems: { [string]: number })
	items = table.clone(newItems)
	changedEvent:Fire()
end

-- Buys one of supply `id` if you have the gold and room to carry it.
function Progress.buySupply(id: string): boolean
	local supply = Supplies[id]
	if not supply or gold < supply.Price or Progress.itemCount(id) >= Config.MaxItemCount then
		return false
	end
	gold -= supply.Price
	items[id] = Progress.itemCount(id) + 1
	changedEvent:Fire()
	return true
end

return Progress
