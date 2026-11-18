-- The four bases on the high-ground terrace: who owns each, which keeper sits in each slot, placing keepers,
-- paying income every second, and rival harbour gangs that hold (and restock) the plots no player owns.

local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Brainrots = require(Shared.Brainrots)
local BrainrotModels = require(Shared.BrainrotModels)
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
local State = require(script.Parent.State)
local CarryService = require(script.Parent.CarryService)
local Remotes = require(script.Parent.Remotes)

local PlotService = {}

export type Slot = { part: BasePart, keeper: State.Keeper?, model: Model? }
export type Plot = {
	index: number,
	model: Model,
	owner: Player?,
	rivalName: string?,
	slots: { Slot },
	lockedUntil: number,
}

local plots: { Plot } = {}
local rng = Random.new()

PlotService.plots = plots

local function ownerName(plot: Plot): string
	if plot.owner then
		return plot.owner.DisplayName
	end
	return plot.rivalName or "Nobody"
end

local function refreshOwnerSign(plot: Plot)
	plot.model.SignBoard.OwnerSign.OwnerLabel.Text = string.upper(ownerName(plot)) .. "'S BASE"
	plot.model:SetAttribute("OwnerUserId", if plot.owner then plot.owner.UserId else 0)
	plot.model:SetAttribute("OwnerName", ownerName(plot))
end

-- Server-side distance check used by every prompt handler; the client is never trusted.
function PlotService.isWithinReach(player: Player, part: BasePart): boolean
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - part.Position).Magnitude <= Config.MAX_INTERACT_DISTANCE
end

function PlotService.isLocked(plot: Plot): boolean
	return os.clock() < plot.lockedUntil
end

-- Raises the red force-field barrier across the plot's gate; while it stands nobody can steal from it.
function PlotService.lockPlot(plot: Plot, seconds: number)
	local untilTime = os.clock() + seconds
	plot.lockedUntil = untilTime
	plot.model:SetAttribute("Locked", seconds > 0)
	plot.model:SetAttribute("LockedUntil", workspace:GetServerTimeNow() + seconds)
	plot.model.Barrier.Transparency = if seconds > 0 then 0.35 else 1
	task.delay(seconds, function()
		if plot.lockedUntil == untilTime then
			plot.lockedUntil = 0
			plot.model:SetAttribute("Locked", false)
			plot.model.Barrier.Transparency = 1
		end
	end)
end

function PlotService.plotOf(player: Player): Plot?
	for _, plot in plots do
		if plot.owner == player then
			return plot
		end
	end
	return nil
end

function PlotService.setSlot(plot: Plot, slotIndex: number, keeper: State.Keeper?)
	local slot = plot.slots[slotIndex]
	if slot.model then
		slot.model:Destroy()
		slot.model = nil
	end
	slot.keeper = keeper
	slot.part:SetAttribute("Occupied", keeper ~= nil)
	local steal = slot.part:FindFirstChild("StealPrompt")
	if steal then
		steal.ObjectText = if keeper then Brainrots.get(keeper.id).name else ""
	end
	if keeper then
		local model = BrainrotModels.build(keeper.id, keeper.mutated)
		BrainrotModels.standOn(model, slot.part, slotIndex)
		model.Parent = plot.model
		slot.model = model
	end
end

function PlotService.clearPlot(plot: Plot)
	for i in plot.slots do
		PlotService.setSlot(plot, i, nil)
	end
end

-- Owner, carrying a keeper, standing at an empty slot of their own plot.
function PlotService.placeKeeper(player: Player, plot: Plot, slotIndex: number)
	local slot = plot.slots[slotIndex]
	if plot.owner ~= player or slot.keeper or not CarryService.isCarrying(player) then
		return
	end
	if not PlotService.isWithinReach(player, slot.part) then
		return
	end
	local keeper = CarryService.release(player)
	if not keeper then
		return
	end
	PlotService.setSlot(plot, slotIndex, keeper)
	local entry = Brainrots.get(keeper.id)
	Remotes.notify(player, entry.name .. " is earning on your base!", Brainrots.rarityColor(entry.rarity))
	Remotes.burstAt(slot.part.Position + Vector3.new(0, 3, 0), Brainrots.rarityColor(entry.rarity))
end

local function stockRivalKeepers(plot: Plot)
	for i, rarity in { "Common", "Rare", "Rare", "Epic" } do
		local entry = Brainrots.rollFromRarity(rarity, rng)
		PlotService.setSlot(plot, i, { id = entry.id, mutated = i == 4 })
	end
end

local function giveToRivalGang(plot: Plot)
	plot.owner = nil
	plot.rivalName = Config.RIVAL_NAMES[(plot.index - 1) % #Config.RIVAL_NAMES + 1]
	PlotService.lockPlot(plot, 0)
	PlotService.clearPlot(plot)
	stockRivalKeepers(plot)
	refreshOwnerSign(plot)
end

function PlotService.claimPlot(player: Player): Plot?
	for _, plot in plots do
		if not plot.owner then
			plot.owner = player
			plot.rivalName = nil
			PlotService.lockPlot(plot, 0)
			PlotService.clearPlot(plot)
			refreshOwnerSign(plot)
			State.setPlot(player, plot.index)
			return plot
		end
	end
	return nil
end

function PlotService.releasePlot(player: Player)
	local plot = PlotService.plotOf(player)
	if plot then
		giveToRivalGang(plot)
	end
end

-- Pays every player their keepers' rate once a second and tells their client which slots paid what.
local function payIncomeEverySecond()
	for _, player in Players:GetPlayers() do
		local s = State.get(player)
		local plot = PlotService.plotOf(player)
		if s and plot then
			local pops, income = {}, 0
			for _, slot in plot.slots do
				if slot.keeper then
					local amount = Economy.payoutPerSecond(Brainrots.get(slot.keeper.id), slot.keeper.mutated, s.rebirths)
					income += amount
					table.insert(pops, { slot.part, amount, slot.model })
				end
			end
			State.setIncome(player, income)
			if income > 0 then
				State.addMoney(player, income)
				Remotes.MoneyPop:FireClient(player, pops)
			end
		end
	end
end

-- Rival gangs restock robbed bases and sometimes lock up, so there is always something (risky) to steal.
local function restockRivalBases()
	for _, plot in plots do
		if not plot.owner and plot.rivalName then
			local empty = 0
			for _, slot in plot.slots do
				if not slot.keeper then
					empty += 1
				end
			end
			if empty > 3 then
				stockRivalKeepers(plot)
			end
			if rng:NextNumber() < 0.5 then
				PlotService.lockPlot(plot, 15)
			end
		end
	end
end

local function addPrompt(parent: Instance, name: string, action: string, hold: number): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = name
	prompt.ActionText = action
	prompt.HoldDuration = hold
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Style = Enum.ProximityPromptStyle.Custom -- drawn by the client's Prompts module
	prompt.Parent = parent
	return prompt
end

function PlotService.start()
	for i = 1, Config.PLOT_COUNT do
		local model = workspace.Plots:FindFirstChild("Plot" .. i)
		local plot: Plot = { index = i, model = model, owner = nil, rivalName = nil, slots = {}, lockedUntil = 0 }
		for k = 1, Config.SLOTS_PER_PLOT do
			local part = model.Slots:FindFirstChild("Slot" .. k)
			part:SetAttribute("PlotIndex", i)
			part:SetAttribute("SlotIndex", k)
			plot.slots[k] = { part = part, keeper = nil, model = nil }
			addPrompt(part, "PlacePrompt", "Place keeper", 0).Triggered:Connect(function(player)
				PlotService.placeKeeper(player, plot, k)
			end)
			addPrompt(part, "StealPrompt", "HOLD E TO STEAL", Config.STEAL_HOLD_SECONDS) -- wired by StealService
		end
		addPrompt(model.LockPad, "LockPrompt", "Lock base " .. Economy.formatMoney(Config.LOCK_PRICE), 0)
		plots[i] = plot
		giveToRivalGang(plot)
	end

	task.spawn(function()
		local sinceRestock = 0
		while true do
			task.wait(1)
			payIncomeEverySecond()
			sinceRestock += 1
			if sinceRestock >= Config.RIVAL_RESTOCK_SECONDS then
				sinceRestock = 0
				restockRivalBases()
			end
		end
	end)
end

return PlotService
