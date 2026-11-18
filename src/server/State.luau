-- The single source of truth for every player's money, rebirths, income and carried keeper.
-- Other services change state only through these functions; each change is mirrored to player attributes for the HUD.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)

local State = {}

export type Keeper = { id: string, mutated: boolean }
export type PlayerState = { money: number, rebirths: number, income: number, carrying: Keeper?, plot: number? }

local states: { [Player]: PlayerState } = {}

local function mirrorToAttributes(player: Player)
	local s = states[player]
	if not s then
		return
	end
	player:SetAttribute("Money", s.money)
	player:SetAttribute("Rebirths", s.rebirths)
	player:SetAttribute("Multiplier", Economy.rebirthMultiplier(s.rebirths))
	player:SetAttribute("Income", s.income)
	player:SetAttribute("CarryingId", if s.carrying then s.carrying.id else "")
	player:SetAttribute("CarryingMutated", if s.carrying then s.carrying.mutated else false)
	player:SetAttribute("PlotIndex", s.plot or 0)
	local stats = player:FindFirstChild("leaderstats")
	if stats then
		stats.Money.Value = s.money
		stats.Rebirths.Value = s.rebirths
	end
end

function State.addPlayer(player: Player)
	states[player] = { money = Config.STARTING_MONEY, rebirths = 0, income = 0, carrying = nil, plot = nil }
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	for _, name in { "Money", "Rebirths" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = stats
	end
	stats.Parent = player
	mirrorToAttributes(player)
end

function State.removePlayer(player: Player)
	states[player] = nil
end

function State.get(player: Player): PlayerState?
	return states[player]
end

function State.addMoney(player: Player, amount: number)
	local s = states[player]
	if s then
		s.money += amount
		mirrorToAttributes(player)
	end
end

-- Takes money only if the player has enough; returns whether it did.
function State.spendMoney(player: Player, amount: number): boolean
	local s = states[player]
	if not s or s.money < amount then
		return false
	end
	s.money -= amount
	mirrorToAttributes(player)
	return true
end

function State.setCarrying(player: Player, keeper: Keeper?)
	local s = states[player]
	if s then
		s.carrying = keeper
		mirrorToAttributes(player)
	end
end

function State.setIncome(player: Player, income: number)
	local s = states[player]
	if s and s.income ~= income then
		s.income = income
		mirrorToAttributes(player)
	end
end

function State.setPlot(player: Player, plotIndex: number?)
	local s = states[player]
	if s then
		s.plot = plotIndex
		mirrorToAttributes(player)
	end
end

-- Resets money and adds a rebirth (a permanent x1.5 multiplier). The caller clears the plot.
function State.rebirth(player: Player): boolean
	local s = states[player]
	if not s or not Economy.canRebirth(s.money) then
		return false
	end
	s.money = Config.STARTING_MONEY
	s.rebirths += 1
	s.carrying = nil
	s.income = 0
	mirrorToAttributes(player)
	return true
end

return State
