-- Warns the player about the tide: the HUD countdown, a flashing frame and banner during the warning,
-- and a blue underwater tint plus splash when the surge hits.

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Tide = require(Shared.Tide)
local HUD = require(script.Parent.HUD)
local Effects = require(script.Parent.Effects)

local TideWarning = {}

local CALM = Color3.fromRGB(110, 210, 255)
local WARN = Color3.fromRGB(255, 160, 40)
local SURGE = Color3.fromRGB(255, 70, 70)

function TideWarning.start(gui: ScreenGui)
	local frame = Instance.new("Frame")
	frame.Name = "TideVignette"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 18
	stroke.Color = WARN
	stroke.Transparency = 1
	stroke.Parent = frame

	local banner = Instance.new("TextLabel")
	banner.Name = "SurgeBanner"
	banner.BackgroundTransparency = 1
	banner.Size = UDim2.fromOffset(900, 70)
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.44)
	banner.Font = Enum.Font.FredokaOne
	banner.TextSize = 44
	banner.TextStrokeTransparency = 0
	banner.Visible = false
	banner.Parent = gui

	local tint = Instance.new("ColorCorrectionEffect")
	tint.Name = "SurgeTint"
	tint.Parent = Lighting

	local lastPhase = nil
	RunService.RenderStepped:Connect(function()
		local phase = workspace:GetAttribute("TidePhase") or Tide.Phase.Calm
		local endsAt = workspace:GetAttribute("TidePhaseEndsAt") or 0
		local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
		local flash = (math.sin(os.clock() * 10) + 1) / 2

		if phase == Tide.Phase.Calm then
			HUD.showTideClock("TIDE SURGE IN", left + Tide.WARNING_SECONDS, CALM)
			stroke.Transparency = 1
			banner.Visible = false
			tint.TintColor = Color3.new(1, 1, 1)
		elseif phase == Tide.Phase.Warning then
			HUD.showTideClock("SURGE INCOMING!", left, WARN)
			stroke.Color = WARN
			stroke.Transparency = 0.2 + flash * 0.6
			banner.Visible = true
			banner.TextColor3 = WARN
			banner.Text = "TIDE SURGE IN " .. left .. " - RUN TO HIGH GROUND!"
		else
			HUD.showTideClock("SURGE! STAY HIGH", left, SURGE)
			stroke.Color = SURGE
			stroke.Transparency = 0.3 + flash * 0.4
			banner.Visible = true
			banner.TextColor3 = Color3.fromRGB(120, 200, 255)
			banner.Text = "THE TIDE IS IN! LOW GROUND FLOODED"
			tint.TintColor = Color3.fromRGB(205, 225, 255)
		end
		if phase ~= lastPhase and phase == Tide.Phase.Surge then
			Effects.playSound("splash", 0.8)
		end
		lastPhase = phase
	end)
end

return TideWarning
