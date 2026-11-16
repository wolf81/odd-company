--!strict
-- Things you use up in battle (ITEM button), bought in shops.
-- Using one takes your turn. Add a new one here, then add its Id to a
-- shop to sell it.

export type Supply = {
	Id: string,
	Name: string, -- shown in the shop and in battle
	Heal: number, -- HP it gives back (never above your max HP)
	Price: number, -- gold
}

local Supplies: { [string]: Supply } = {
	Bandage = { Id = "Bandage", Name = "Bandage", Heal = 8, Price = 6 },
}

return Supplies
