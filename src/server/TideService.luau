-- The tide surge: every 90 seconds a warning, then the water rises over the low market for 15 seconds.
-- Anyone caught below the high ground takes damage, and the tide washes away the keeper they carry.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Brainrots = require(Shared.Brainrots)
local Config = require(Shared.Config)
local Tide = require(Shared.Tide)
local CarryService = require(script.Parent.CarryService)
local Remotes = require(script.Parent.Remotes)

local TideService = {}

local BLUE = Color3.fromRGB(80, 170, 255)

local water: BasePart
local phase = Tide.Phase.Calm
local onSurgeEnd: (() -> ())?

local function waterTopY(): number
	return water.Position.Y + water.Size.Y / 2
end

local function tweenWaterTo(topY: number)
	local goal = CFrame.new(water.Position.X, topY - water.Size.Y / 2, water.Position.Z)
	local info = TweenInfo.new(Tide.RISE_SECONDS, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(water, info, { CFrame = goal }):Play()
end

local function setPhase(newPhase: string, seconds: number)
	phase = newPhase
	workspace:SetAttribute("TidePhase", newPhase)
	workspace:SetAttribute("TidePhaseEndsAt", workspace:GetServerTimeNow() + seconds)
end

-- Damages everyone standing in surge water and drowns the keeper they carry.
function TideService.floodLowGround(dt: number)
	local top = waterTopY()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local feetY = root.Position.Y - 3
			if Tide.isSubmerged(feetY, top, Config.HIGH_GROUND_Y) then
				humanoid:TakeDamage(Config.TIDE_DAMAGE_PER_SECOND * dt)
				local lost = CarryService.isCarrying(player) and CarryService.release(player)
				if lost then
					Remotes.notify(player, "The tide swallowed your " .. Brainrots.get(lost.id).name .. "!", BLUE)
				end
			end
		end
	end
end

-- Calm -> Warning -> Surge -> Calm forever. The end time lives in a workspace attribute so clients can count down.
local function runTideCycle()
	setPhase(Tide.Phase.Calm, Tide.CALM_SECONDS)
	while true do
		while workspace:GetServerTimeNow() < workspace:GetAttribute("TidePhaseEndsAt") do
			task.wait(0.2)
		end
		local nextPhase, seconds = Tide.nextPhase(phase)
		setPhase(nextPhase, seconds)
		if nextPhase == Tide.Phase.Surge then
			tweenWaterTo(Tide.SURGE_TOP_Y)
			Remotes.notifyAll("TIDE SURGE! Get to the high ground!", BLUE)
		elseif nextPhase == Tide.Phase.Calm then
			tweenWaterTo(Tide.LOW_TOP_Y)
			if onSurgeEnd then
				onSurgeEnd()
			end
		end
	end
end

function TideService.start(callbacks: { onSurgeEnd: () -> () })
	onSurgeEnd = callbacks.onSurgeEnd
	water = workspace.TideWater
	task.spawn(runTideCycle)
	task.spawn(function()
		while true do
			local dt = task.wait(0.25)
			if phase == Tide.Phase.Surge then
				TideService.floodLowGround(dt)
			end
		end
	end)
end

return TideService
