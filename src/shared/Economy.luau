-- Money rules: what a keeper earns, the rebirth multiplier, mutation rolls and how money is written on screen.

local Config = require(script.Parent.Config)

local Economy = {}

function Economy.rebirthMultiplier(rebirths: number): number
	return Config.REBIRTH_MULTIPLIER_STEP ^ rebirths
end

function Economy.keeperRate(entry, mutated: boolean): number
	return entry.rate * (if mutated then Config.MUTATION_RATE_BONUS else 1)
end

function Economy.payoutPerSecond(entry, mutated: boolean, rebirths: number): number
	return math.floor(Economy.keeperRate(entry, mutated) * Economy.rebirthMultiplier(rebirths) + 0.5)
end

function Economy.canRebirth(money: number): boolean
	return money >= Config.REBIRTH_COST
end

function Economy.rollGoldenMutation(rng: Random): boolean
	return rng:NextNumber() < Config.MUTATION_CHANCE
end

function Economy.formatMoney(n: number): string
	n = math.floor(n)
	if n >= 1e6 then
		return string.format("$%.2fM", n / 1e6)
	elseif n >= 1e5 then
		return string.format("$%.1fK", n / 1e3)
	end
	local digits = tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return "$" .. digits
end

return Economy
