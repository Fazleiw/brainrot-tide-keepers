-- Draws every proximity prompt in the HUD's style: a key badge, what the prompt is about, the action and a hold
-- bar that fills while E is held. The server marks its prompts Custom, so Roblox's default prompt never shows.

local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local Prompts = {}

local rgb = Color3.fromRGB
local FONT = Enum.Font.FredokaOne
local PANEL = rgb(14, 24, 44)
local ACCENT = rgb(70, 200, 230)

local function label(parent: Instance, str: string, size: number, color: Color3, pos: UDim2, dims: UDim2): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = FONT
	t.Text = str
	t.TextSize = size
	t.TextColor3 = color
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextStrokeTransparency = 0.3
	t.Position = pos
	t.Size = dims
	t.Parent = parent
	return t
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function buildPrompt(prompt: ProximityPrompt, holder: Instance): (BillboardGui, Frame, TextLabel)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Prompt"
	bb.Adornee = prompt.Parent
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(270, 74)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 4.5) -- in front of whatever stands on the slot or pedestal
	bb.LightInfluence = 0
	bb.Parent = holder

	local panel = Instance.new("Frame")
	panel.Size = UDim2.fromScale(1, 1)
	panel.BackgroundColor3 = PANEL
	panel.BackgroundTransparency = 0.05
	panel.Parent = bb
	corner(panel, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = ACCENT
	stroke.Thickness = 2.5
	stroke.Parent = panel

	local key = Instance.new("TextLabel")
	key.Size = UDim2.fromOffset(46, 46)
	key.Position = UDim2.fromOffset(10, 9)
	key.BackgroundColor3 = Color3.new(1, 1, 1)
	key.Font = FONT
	key.Text = prompt.KeyboardKeyCode.Name
	key.TextSize = 30
	key.TextColor3 = PANEL
	key.Parent = panel
	corner(key, 10)

	label(panel, prompt.ObjectText, 15, rgb(170, 230, 255), UDim2.fromOffset(66, 7), UDim2.new(1, -74, 0, 18))
	local action = label(panel, prompt.ActionText, 22, Color3.new(1, 1, 1), UDim2.fromOffset(66, 25), UDim2.new(1, -74, 0, 28))
	action.TextScaled = true

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -20, 0, 7)
	bar.Position = UDim2.new(0, 10, 1, -12)
	bar.BackgroundColor3 = rgb(40, 50, 80)
	bar.Visible = prompt.HoldDuration > 0
	bar.Parent = panel
	corner(bar, 4)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = rgb(255, 225, 80)
	fill.Parent = bar
	corner(fill, 4)
	return bb, fill, action
end

function Prompts.start(playerGui: PlayerGui)
	local holder = Instance.new("Folder") -- billboards render from PlayerGui itself, not from inside a ScreenGui
	holder.Name = "Prompts"
	holder.Parent = playerGui

	ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom then
			return
		end
		local bb, fill, action = buildPrompt(prompt, holder)
		local hold: Tween? = nil
		local function resetFill()
			if hold then
				hold:Cancel()
			end
			fill.Size = UDim2.fromScale(0, 1)
		end
		local connections = {
			prompt.PromptButtonHoldBegan:Connect(function()
				hold = TweenService:Create(fill, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
				hold:Play()
			end),
			prompt.PromptButtonHoldEnded:Connect(resetFill),
			prompt.Triggered:Connect(resetFill),
			prompt:GetPropertyChangedSignal("ActionText"):Connect(function()
				action.Text = prompt.ActionText
			end),
		}
		prompt.PromptHidden:Wait()
		for _, c in connections do
			c:Disconnect()
		end
		bb:Destroy()
	end)
end

return Prompts
