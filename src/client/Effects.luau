-- Client-only feedback: floating "+$" over each earning keeper, particle bursts, spinning stall displays and sounds.

local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Economy = require(Shared.Economy)

local Effects = {}

local SOUNDS = {
	coin = "rbxasset://sounds/electronicpingshort.wav",
	splash = "rbxasset://sounds/impact_water.mp3",
	burst = "rbxasset://sounds/button.wav",
}

function Effects.playSound(name: string, volume: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = SOUNDS[name]
	sound.Volume = volume or 0.5
	SoundService:PlayLocalSound(sound)
	Debris:AddItem(sound, 3)
end

-- A big "+$14" that rises and fades in front of an earning keeper (depth-tested so it sits in the world).
function Effects.floatMoneyPop(slot: BasePart, amount: number, keeper: Model?)
	local height = if keeper and keeper.Parent then keeper:GetExtentsSize().Y else 4
	local start = Vector3.new(0, height * 0.55, 4)
	local bb = Instance.new("BillboardGui")
	bb.Name = "MoneyPop"
	bb.Adornee = slot
	bb.Size = UDim2.fromScale(6, 2)
	bb.StudsOffsetWorldSpace = start
	bb.LightInfluence = 0
	bb.MaxDistance = 140
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(120, 255, 120)
	t.TextStrokeTransparency = 0
	t.Text = "+" .. Economy.formatMoney(amount)
	t.Parent = bb
	bb.Parent = slot
	TweenService:Create(bb, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = start + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(0.4, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 1.1), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(bb, 1.6)
end

function Effects.burstAt(position: Vector3, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = position
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	emitter.Speed = NumberRange.new(10, 22)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Rate = 0
	emitter.Parent = anchor
	anchor.Parent = workspace
	emitter:Emit(60)
	Effects.playSound("burst", 0.4)
	Debris:AddItem(anchor, 2)
end

-- Slowly turns the keepers on display at the stall so every side of them shows (local only).
function Effects.spinStallDisplays()
	local pedestals = workspace:WaitForChild("Stall"):WaitForChild("Pedestals")
	RunService.RenderStepped:Connect(function(dt)
		for _, pedestal in pedestals:GetChildren() do
			local display = pedestal:FindFirstChildWhichIsA("Model")
			if display and display.PrimaryPart then
				display:PivotTo(display:GetPivot() * CFrame.Angles(0, dt * 0.6, 0))
			end
		end
	end)
end

return Effects
