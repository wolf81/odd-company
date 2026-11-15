--!strict
-- Shared type for ally data, so every ally file has the same shape.

-- The ally's special move in battle (the third command button).
export type Ability = {
	Name: string, -- used in messages, e.g. "Shaken Cola"
	Button: string, -- command button text, e.g. "COLA"
	Text: string, -- shown when the ability is used
	-- Works like ATK: the enemy's DEF is subtracted (minimum 1 damage).
	Damage: number,
	-- 1 = you pick the target. More = hits that many enemies at once
	-- (the one you'd pick first, then the others).
	MaxTargets: number,
	-- How many rounds it hurts. 1 = once. 2 = once now, and again at the
	-- start of the enemy's turn next round (burning), and so on.
	Rounds: number,
	-- Rounds you have to wait after using it. 0 = usable every turn.
	Cooldown: number,
}

-- What the ally says in the village. Lines start with "* " like Undertale.
export type Lines = {
	Greeting: { string }, -- when you talk to them
	Ask: string, -- "Can I come with you?" (answered Yes / No)
	Joined: string,
	Declined: string, -- you said No
	Leave: string, -- sent back to the village because the team was full
	-- Only for allies that want something first (see Wants):
	NeedItem: string?, -- you don't have it yet
	OfferItem: string?, -- "Give it to them?" (Yes / No)
	Thanks: { string }?, -- after you gave it
}

export type AllyData = {
	Id: string,
	DisplayName: string,
	RigType: Enum.HumanoidRigType,
	-- Properties copied onto a HumanoidDescription, same as enemies.
	Avatar: { [string]: any },
	IdleAnimationId: string?,
	WalkAnimationId: string?, -- played while following the player
	-- Item (from a chest) the ally wants before they'll join, or nil.
	Wants: string?,
	Lines: Lines,
	Ability: Ability,
}

return {}
