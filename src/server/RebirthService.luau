-- Rebirth: at $10,000 a player trades their money and keepers for a permanent x1.5 income multiplier.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
local State = require(script.Parent.State)
local CarryService = require(script.Parent.CarryService)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)

local RebirthService = {}

local PINK = Color3.fromRGB(255, 120, 255)

function RebirthService.rebirth(player: Player)
	local s = State.get(player)
	if not s or not Economy.canRebirth(s.money) then
		Remotes.notify(player, "Rebirth needs " .. Economy.formatMoney(Config.REBIRTH_COST), Color3.fromRGB(255, 90, 90))
		return
	end
	CarryService.release(player)
	State.rebirth(player)
	local plot = PlotService.plotOf(player)
	if plot then
		PlotService.clearPlot(plot)
	end
	Remotes.notify(player, string.format("REBORN! Income x%.2f forever", Economy.rebirthMultiplier(s.rebirths)), PINK)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		Remotes.burstAt(root.Position, PINK)
	end
end

function RebirthService.start()
	Remotes.Rebirth.OnServerEvent:Connect(RebirthService.rebirth)
end

return RebirthService
