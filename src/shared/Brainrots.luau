-- The tide-keeper catalogue: twelve absurd harbour brainrots on a ladder of four rarities.
-- Each step up the ladder costs more and earns more money a second.

local Brainrots = {}

Brainrots.RarityOrder = { "Common", "Rare", "Epic", "Legendary" }

Brainrots.Rarities = {
	Common = { rank = 1, color = Color3.fromRGB(205, 215, 225), scale = 1.3 },
	Rare = { rank = 2, color = Color3.fromRGB(70, 165, 255), scale = 1.5 },
	Epic = { rank = 3, color = Color3.fromRGB(200, 100, 255), scale = 1.75 },
	Legendary = { rank = 4, color = Color3.fromRGB(255, 195, 40), scale = 2.1 },
}

Brainrots.GOLD = Color3.fromRGB(255, 215, 60)

Brainrots.Catalogue = {
	{ id = "Shrimpbishop", rarity = "Common", price = 40, rate = 2, quip = "Blesses every puddle. Charges a tithe." },
	{ id = "WetSockSteve", name = "Wet Sock Steve", rarity = "Common", price = 60, rate = 3, quip = "Has been damp since 2009." },
	{ id = "PuddleProphet", name = "Puddle Prophet", rarity = "Common", price = 90, rate = 5, quip = "Predicts rain. Is always right." },
	{ id = "CrabMagistrate", name = "Crab Magistrate", rarity = "Rare", price = 400, rate = 14, quip = "Order! Order in the tidepool!" },
	{ id = "BarnacleBard", name = "Barnacle Bard", rarity = "Rare", price = 550, rate = 18, quip = "Knows one song. It is about rocks." },
	{ id = "LampEel", name = "Lamp Eel", rarity = "Rare", price = 750, rate = 24, quip = "Bright idea, zero thoughts." },
	{ id = "TidepoolTyrant", name = "Tidepool Tyrant", rarity = "Epic", price = 2500, rate = 70, quip = "Rules a kingdom of four snails." },
	{ id = "KelpColossus", name = "Kelp Colossus", rarity = "Epic", price = 3400, rate = 95, quip = "Mostly salad. Entirely menace." },
	{ id = "GullGoblin", name = "Gull Goblin", rarity = "Epic", price = 4200, rate = 120, quip = "Steals chips. Steals hearts." },
	{ id = "DrownedNacho", name = "The Drowned Nacho", rarity = "Legendary", price = 9000, rate = 260, quip = "Extra cheese. Extra brine." },
	{ id = "Moonanchor", rarity = "Legendary", price = 12500, rate = 350, quip = "Pulls the tide. On purpose." },
	{ id = "HighTideHooligan", name = "High Tide Hooligan", rarity = "Legendary", price = 16000, rate = 480, quip = "Surfs your base. Rude." },
}

local byId = {}
for _, entry in Brainrots.Catalogue do
	entry.name = entry.name or entry.id
	byId[entry.id] = entry
end

function Brainrots.get(id: string)
	return byId[id]
end

function Brainrots.listByRarity(rarity: string)
	local list = {}
	for _, entry in Brainrots.Catalogue do
		if entry.rarity == rarity then
			table.insert(list, entry)
		end
	end
	return list
end

function Brainrots.rollFromRarity(rarity: string, rng: Random)
	local list = Brainrots.listByRarity(rarity)
	return list[rng:NextInteger(1, #list)]
end

function Brainrots.rarityColor(rarity: string): Color3
	return Brainrots.Rarities[rarity].color
end

return Brainrots
