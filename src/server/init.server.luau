-- Server bootstrap for Brainrot Tide Keepers: starts every service and hands each joining player a plot.

local Players = game:GetService("Players")

local State = require(script.State)
local Remotes = require(script.Remotes)
local CarryService = require(script.CarryService)
local PlotService = require(script.PlotService)
local PurchaseService = require(script.PurchaseService)
local StealService = require(script.StealService)
local TideService = require(script.TideService)
local RebirthService = require(script.RebirthService)

PlotService.start()
PurchaseService.start()
StealService.start()
RebirthService.start()
TideService.start({
	onSurgeEnd = function()
		PurchaseService.restockAllPedestals()
		Remotes.notifyAll("The tide ebbs... a fresh catch washed up at the stall!", Color3.fromRGB(120, 230, 255))
	end,
})

local function onPlayerAdded(player: Player)
	State.addPlayer(player)
	local plot = PlotService.claimPlot(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		CarryService.restoreAfterRespawn(player)
	end)
	if plot then
		Remotes.notify(player, "Welcome, keeper! Plot " .. plot.index .. " on the high ground is yours.", Color3.fromRGB(120, 230, 255))
	end
end

-- Studio-only test hook: setting workspace attribute StudioGrantMoney from the command bar pays every player that much.
local function grantStudioTestMoney()
	local amount = workspace:GetAttribute("StudioGrantMoney")
	if typeof(amount) == "number" and amount > 0 then
		workspace:SetAttribute("StudioGrantMoney", nil)
		for _, player in Players:GetPlayers() do
			State.addMoney(player, amount)
		end
	end
end
if game:GetService("RunService"):IsStudio() then
	workspace:GetAttributeChangedSignal("StudioGrantMoney"):Connect(grantStudioTestMoney)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	PlotService.releasePlot(player)
	CarryService.release(player)
	State.removePlayer(player)
end)
