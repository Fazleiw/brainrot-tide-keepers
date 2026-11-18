-- Theft and defence: hold E at someone else's occupied slot to steal the keeper, unless their base is locked.
-- Owners buy a timed lock at their plot's red Lock pad. Every check runs on the server.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Brainrots = require(Shared.Brainrots)
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
local State = require(script.Parent.State)
local CarryService = require(script.Parent.CarryService)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)

local StealService = {}

local RED = Color3.fromRGB(255, 80, 80)

function StealService.stealKeeper(thief: Player, plot: PlotService.Plot, slotIndex: number)
	local slot = plot.slots[slotIndex]
	local keeper = slot.keeper
	if not keeper or plot.owner == thief or not PlotService.isWithinReach(thief, slot.part) then
		return
	end
	if PlotService.isLocked(plot) then
		Remotes.notify(thief, "This base is LOCKED! Wait for the barrier to drop.", RED)
		return
	end
	if CarryService.isCarrying(thief) then
		Remotes.notify(thief, "Hands full!", RED)
		return
	end
	PlotService.setSlot(plot, slotIndex, nil)
	CarryService.pickUp(thief, keeper)
	local entry = Brainrots.get(keeper.id)
	Remotes.notify(thief, "STOLEN: " .. entry.name .. "! Run it home!", Brainrots.rarityColor(entry.rarity))
	Remotes.burstAt(slot.part.Position + Vector3.new(0, 3, 0), RED)
	if plot.owner then
		Remotes.notify(plot.owner, thief.DisplayName .. " stole your " .. entry.name .. "!", RED)
	end
end

function StealService.buyBaseLock(player: Player, plot: PlotService.Plot)
	if plot.owner ~= player or not PlotService.isWithinReach(player, plot.model.LockPad) then
		return
	end
	if PlotService.isLocked(plot) then
		Remotes.notify(player, "Your base is already locked.", Color3.fromRGB(255, 220, 120))
		return
	end
	if not State.spendMoney(player, Config.LOCK_PRICE) then
		Remotes.notify(player, "A lock costs " .. Economy.formatMoney(Config.LOCK_PRICE), RED)
		return
	end
	PlotService.lockPlot(plot, Config.LOCK_SECONDS)
	Remotes.notify(player, "Base locked for " .. Config.LOCK_SECONDS .. "s - thieves bounce off!", Color3.fromRGB(120, 220, 255))
end

function StealService.start()
	for _, plot in PlotService.plots do
		for k, slot in plot.slots do
			slot.part.StealPrompt.Triggered:Connect(function(player)
				StealService.stealKeeper(player, plot, k)
			end)
		end
		plot.model.LockPad.LockPrompt.Triggered:Connect(function(player)
			StealService.buyBaseLock(player, plot)
		end)
	end
end

return StealService
