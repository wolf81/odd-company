--!strict
-- Swords the player can use. Attack is added to the player's ATK, so a
-- better sword means more damage per hit. Shops sell them by Id (see the
-- Shops list of a village in src/shared/World/).
-- Add a new sword here, then add its Id to a shop to sell it.

export type Weapon = {
	Id: string,
	Name: string, -- shown in the shop and messages
	Attack: number, -- added to the player's ATK
	Price: number, -- gold
}

local Weapons: { [string]: Weapon } = {
	Stick = { Id = "Stick", Name = "Stick", Attack = 0, Price = 0 }, -- what you start with
	IronSword = { Id = "IronSword", Name = "Iron sword", Attack = 3, Price = 25 },
}

return Weapons
