-- Client bootstrap: mounts the HUD, wires server events to effects, and shows each player only the
-- prompts that make sense for them (place on your own slots, steal from everyone else's).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local HUD = require(script.Parent.HUD)
local Effects = require(script.Parent.Effects)
local TideWarning = require(script.Parent.TideWarning)

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

local gui = HUD.mount(player:WaitForChild("PlayerGui"), function()
	Remotes.Rebirth:FireServer()
end)
TideWarning.start(gui)
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

-- A floating marker over the player's own base so they always know where to carry keepers.
local function markHomeBase(plotModel: Model)
	local old = workspace:FindFirstChild("YourBaseMarker")
	if old then
		old:Destroy()
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "YourBaseMarker"
	bb.Adornee = plotModel:WaitForChild("Base")
	bb.Size = UDim2.fromScale(16, 4)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 18, 0)
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(120, 255, 140)
	t.TextStrokeTransparency = 0
	t.Text = "YOUR BASE"
	t.Parent = bb
	bb.Parent = workspace
end

-- Enables only the prompts this player can use; the server re-checks every one anyway.
local homeIndex = 0
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
				steal.ActionText = if locked then "LOCKED" else "Steal"
			end
		end
		local lock = plotModel.LockPad:FindFirstChild("LockPrompt")
		if lock then
			lock.Enabled = mine
		end
	end
	local index = player:GetAttribute("PlotIndex") or 0
	if index ~= homeIndex and index > 0 then
		homeIndex = index
		markHomeBase(workspace.Plots["Plot" .. index])
	end
end

while true do
	refreshPrompts()
	task.wait(0.2)
end
