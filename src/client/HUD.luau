-- The on-screen interface: money and income, the tide clock, what you carry, the rebirth button,
-- the keeper index and toasts. Big type so it still reads when a screenshot is scaled down.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local TweenService = game:GetService("TweenService")
local Brainrots = require(Shared.Brainrots)
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)

local HUD = {}

local rgb = Color3.fromRGB
local FONT = Enum.Font.FredokaOne
local PANEL = rgb(14, 24, 44)

local gui: ScreenGui
local refs: { [string]: any } = {}

local function roundAndOutline(parent: GuiObject, radius: number?): UIStroke
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 14)
	c.Parent = parent
	local s = Instance.new("UIStroke")
	s.Thickness = 3
	s.Color = rgb(70, 200, 230)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function panel(name: string, size: UDim2, pos: UDim2, anchor: Vector2): (Frame, UIStroke)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.AnchorPoint = anchor
	f.BackgroundColor3 = PANEL
	f.BackgroundTransparency = 0.15
	f.Parent = gui
	return f, roundAndOutline(f)
end

local function text(parent: Instance, name: string, str: string, size: number, color: Color3, pos: UDim2?, dims: UDim2?): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Font = FONT
	t.Text = str
	t.TextSize = size
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.2
	t.TextStrokeColor3 = rgb(5, 10, 20)
	t.Position = pos or UDim2.new()
	t.Size = dims or UDim2.fromScale(1, 1)
	t.Parent = parent
	return t
end

local function buildMoneyPanel()
	local f = panel("Money", UDim2.fromOffset(300, 86), UDim2.new(0.5, 0, 0, 10), Vector2.new(0.5, 0))
	refs.money = text(f, "Amount", "$0", 44, rgb(255, 225, 80), UDim2.fromOffset(0, 2), UDim2.new(1, 0, 0, 50))
	refs.income = text(f, "Income", "+$0/s", 24, rgb(110, 255, 120), UDim2.fromOffset(0, 50), UDim2.new(1, 0, 0, 30))
	refs.moneyScale = Instance.new("UIScale")
	refs.moneyScale.Parent = f
end

local function buildTideClock()
	local f, stroke = panel("Tide", UDim2.fromOffset(230, 80), UDim2.new(1, -14, 0, 10), Vector2.new(1, 0))
	refs.tideStroke = stroke
	refs.tideTitle = text(f, "Title", "TIDE SURGE IN", 19, rgb(150, 220, 255), UDim2.fromOffset(0, 4), UDim2.new(1, 0, 0, 24))
	refs.tideTime = text(f, "Time", "1:15", 40, Color3.new(1, 1, 1), UDim2.fromOffset(0, 28), UDim2.new(1, 0, 0, 46))
end

local function buildCarryBar()
	local f = panel("Carry", UDim2.fromOffset(600, 66), UDim2.new(0.5, 0, 1, -18), Vector2.new(0.5, 1))
	f.Visible = false
	refs.carry = f
	refs.carryName = text(f, "Name", "", 25, Color3.new(1, 1, 1), UDim2.fromOffset(0, 4), UDim2.new(1, 0, 0, 32))
	refs.carryHint = text(f, "Hint", "Carry it up the ramp to YOUR BASE - press E on a slot", 18, rgb(170, 230, 255), UDim2.fromOffset(0, 37), UDim2.new(1, 0, 0, 22))
end

local function buildRebirthPanel(onRebirth: () -> ())
	local f = panel("Rebirth", UDim2.fromOffset(230, 112), UDim2.new(1, -14, 0, 100), Vector2.new(1, 0))
	text(f, "Title", "REBIRTH", 25, rgb(255, 140, 255), UDim2.fromOffset(0, 2), UDim2.new(1, 0, 0, 30))
	refs.rebirthInfo = text(f, "Info", "", 16, Color3.new(1, 1, 1), UDim2.fromOffset(0, 32), UDim2.new(1, 0, 0, 20))
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.new(1, -24, 0, 12)
	bar.Position = UDim2.fromOffset(12, 57)
	bar.BackgroundColor3 = rgb(40, 40, 70)
	bar.Parent = f
	Instance.new("UICorner").Parent = bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = rgb(255, 120, 255)
	fill.Parent = bar
	Instance.new("UICorner").Parent = fill
	refs.rebirthFill = fill
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.new(1, -24, 0, 30)
	button.Position = UDim2.fromOffset(12, 75)
	button.Font = FONT
	button.TextSize = 18
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = rgb(80, 50, 100)
	button.Text = "needs " .. Economy.formatMoney(Config.REBIRTH_COST)
	button.Parent = f
	Instance.new("UICorner").Parent = button
	button.Activated:Connect(onRebirth)
	refs.rebirthButton = button
end

local function buildKeeperIndex()
	local rowHeight = 18
	local f = panel("Index", UDim2.fromOffset(212, 38 + #Brainrots.Catalogue * rowHeight), UDim2.new(0, 12, 1, -12), Vector2.new(0, 1))
	text(f, "Title", "KEEPER INDEX", 19, rgb(255, 225, 80), UDim2.fromOffset(0, 5), UDim2.new(1, 0, 0, 24))
	for i, entry in Brainrots.Catalogue do
		local row = text(f, entry.id, "", 15, Brainrots.rarityColor(entry.rarity), UDim2.fromOffset(10, 32 + (i - 1) * rowHeight), UDim2.new(1, -20, 0, rowHeight))
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.Text = entry.name .. "  " .. Economy.formatMoney(entry.rate) .. "/s"
	end
end

local function buildToastStack()
	local holder = Instance.new("Frame")
	holder.Name = "Toasts"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(720, 150)
	holder.Position = UDim2.new(0.5, 0, 1, -96)
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Padding = UDim.new(0, 6)
	layout.Parent = holder
	refs.toasts = holder
end

function HUD.mount(playerGui: PlayerGui, onRebirth: () -> ()): ScreenGui
	gui = Instance.new("ScreenGui")
	gui.Name = "TideKeepersHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui
	buildMoneyPanel()
	buildTideClock()
	buildCarryBar()
	buildRebirthPanel(onRebirth)
	buildKeeperIndex()
	buildToastStack()
	return gui
end

local lastMoney = 0
function HUD.showMoney(money: number, income: number, multiplier: number, rebirths: number)
	refs.money.Text = Economy.formatMoney(money)
	local mult = if multiplier > 1 then string.format("   x%.2f", multiplier) else ""
	refs.income.Text = "+" .. Economy.formatMoney(income) .. "/s" .. mult
	if money > lastMoney then
		refs.moneyScale.Scale = 1.08
		TweenService:Create(refs.moneyScale, TweenInfo.new(0.25), { Scale = 1 }):Play()
	end
	lastMoney = money
	refs.rebirthFill.Size = UDim2.fromScale(math.clamp(money / Config.REBIRTH_COST, 0, 1), 1)
	refs.rebirthInfo.Text = string.format("Rebirths: %d   next x%.2f", rebirths, Economy.rebirthMultiplier(rebirths + 1))
	local ready = Economy.canRebirth(money)
	refs.rebirthButton.Text = if ready then "REBIRTH NOW!" else "needs " .. Economy.formatMoney(Config.REBIRTH_COST)
	refs.rebirthButton.BackgroundColor3 = if ready then rgb(230, 70, 230) else rgb(80, 50, 100)
end

function HUD.showCarrying(id: string, mutated: boolean)
	local entry = if id ~= "" then Brainrots.get(id) else nil
	refs.carry.Visible = entry ~= nil
	if entry then
		local tag = (if mutated then "GOLDEN " else "") .. string.upper(entry.rarity)
		refs.carryName.Text = "CARRYING: " .. entry.name .. "  (" .. tag .. ", " .. Economy.formatMoney(Economy.keeperRate(entry, mutated)) .. "/s)"
		refs.carryName.TextColor3 = if mutated then Brainrots.GOLD else Brainrots.rarityColor(entry.rarity)
	end
end

function HUD.showTideClock(title: string, seconds: number, color: Color3)
	refs.tideTitle.Text = title
	refs.tideTime.Text = string.format("%d:%02d", seconds // 60, seconds % 60)
	refs.tideStroke.Color = color
	refs.tideTitle.TextColor3 = color
end

function HUD.toast(message: string, color: Color3)
	local t = text(refs.toasts, "Toast", message, 26, color, nil, UDim2.fromOffset(720, 32))
	task.delay(3, function()
		local fade = TweenService:Create(t, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 })
		fade:Play()
		fade.Completed:Wait()
		t:Destroy()
	end)
	local shown = refs.toasts:GetChildren()
	if #shown > 5 then
		for _, child in shown do
			if child:IsA("TextLabel") then
				child:Destroy()
				break
			end
		end
	end
end

return HUD
