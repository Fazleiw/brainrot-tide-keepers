-- Client bootstrap: mounts the HUD, wires server events to effects, and shows each player only the
-- prompts and tags that make sense for them (place on your own slots, steal from everyone else's).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local HUD = require(script.Parent.HUD)
local Effects = require(script.Parent.Effects)
local TideWarning = require(script.Parent.TideWarning)
local Prompts = require(script.Parent.Prompts)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local gui = HUD.mount(player:WaitForChild("PlayerGui"), function()
	Remotes.Rebirth:FireServer()
end)
TideWarning.start(gui)
Prompts.start(player.PlayerGui)
task.spawn(Effects.spinStallDisplays)

local function refreshStats()
	HUD.showMoney(player:GetAttribute("Money") or 0, player:GetAttribute("Income") or 0, player:GetAttribute("Multiplier") or 1, player:GetAttribute("Rebirths") or 0)
	HUD.showCarrying(player:GetAttribute("CarryingId") or "", player:GetAttribute("CarryingMutated") or false)
end
player.AttributeChanged:Connect(refreshStats)
refreshStats()

Remotes.Notify.OnClientEvent:Connect(HUD.toast)
Remotes.Burst.OnClientEvent:Connect(Effects.burstAt)
Remotes.MoneyPop.OnClientEvent:Connect(function(pops)
	for _, pop in pops do
		Effects.floatMoneyPop(pop[1], pop[2], pop[3])
	end
	Effects.playSound("coin", 0.15)
end)

-- Your own plot's sign reads YOUR BASE (locally); it is the one banner on that plot, everyone else sees your name.
local function labelOwnSign(plotModel: Model, mine: boolean)
	local label = plotModel.SignBoard.OwnerSign.OwnerLabel
	if mine then
		label.Text = "YOUR BASE"
		label.TextColor3 = Color3.fromRGB(130, 255, 150)
	else
		label.TextColor3 = Color3.fromRGB(255, 246, 225)
	end
end

-- Shows the "BUY $X" tag only on the stall pedestal the player is standing at (nearest, within 14 studs).
local PRICE_RANGE = 14
local function refreshPriceTags()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local nearest, best = nil, PRICE_RANGE
	for _, pedestal in workspace.Stall.Pedestals:GetChildren() do
		local d = if root then (root.Position - pedestal.Position).Magnitude else math.huge
		if d <= best then
			nearest, best = pedestal, d
		end
	end
	for _, pedestal in workspace.Stall.Pedestals:GetChildren() do
		local display = pedestal:FindFirstChildWhichIsA("Model")
		local tag = display and display.PrimaryPart and display.PrimaryPart:FindFirstChild("PriceTag")
		if tag then
			tag.Enabled = pedestal == nearest
		end
	end
end

-- Enables only the prompts this player can use; the server re-checks every one anyway.
local function refreshPrompts()
	local carrying = (player:GetAttribute("CarryingId") or "") ~= ""
	for _, plotModel in workspace.Plots:GetChildren() do
		local mine = plotModel:GetAttribute("OwnerUserId") == player.UserId
		local locked = plotModel:GetAttribute("Locked") == true
		for _, slot in plotModel.Slots:GetChildren() do
			local occupied = slot:GetAttribute("Occupied") == true
			local place = slot:FindFirstChild("PlacePrompt")
			local steal = slot:FindFirstChild("StealPrompt")
			if place and steal then
				place.Enabled = mine and carrying and not occupied
				steal.Enabled = not mine and occupied and not carrying
				steal.ActionText = if locked then "LOCKED" else "HOLD E TO STEAL"
			end
		end
		labelOwnSign(plotModel, mine)
		local lock = plotModel.LockPad:FindFirstChild("LockPrompt")
		if lock then
			lock.Enabled = mine
		end
	end
end

while true do
	refreshPrompts()
	refreshPriceTags()
	task.wait(0.2)
end
