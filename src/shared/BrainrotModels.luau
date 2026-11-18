-- Builds each tide-keeper's 3D body out of primitive parts, plus its name / rarity / money-a-second label.
-- Every body faces -Z, stands on an invisible Root at y=0 and is welded together so it can be carried.

local Brainrots = require(script.Parent.Brainrots)
local Economy = require(script.Parent.Economy)

local BrainrotModels = {}

local V = Vector3.new
local C = CFrame.new
local A = CFrame.Angles
local rgb = Color3.fromRGB
local rad = math.rad
local BALL = Enum.PartType.Ball
local CYL = Enum.PartType.Cylinder
local NEON = Enum.Material.Neon
local GLASS = Enum.Material.Glass
local UPRIGHT = A(0, 0, rad(90)) -- stands a cylinder's X axis vertically

local function addPart(model: Model, size: Vector3, cf: CFrame, color: Color3, opts: { [string]: any }?)
	local o = opts or {}
	local p = Instance.new(o.class or "Part")
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = o.material or Enum.Material.SmoothPlastic
	if o.shape then
		p.Shape = o.shape
	end
	p.Transparency = o.transparency or 0
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function ball(m, d, x, y, z, color, opts)
	local o = opts or {}
	o.shape = BALL
	return addPart(m, V(d, d, d), C(x, y, z), color, o)
end

local function disc(m, d, h, x, y, z, color, opts)
	local o = opts or {}
	o.shape = CYL
	return addPart(m, V(h, d, d), C(x, y, z) * UPRIGHT, color, o)
end

local function eyes(m, y, z, spread, d, pupil)
	for _, s in { -1, 1 } do
		ball(m, d, s * spread, y, z, rgb(255, 255, 255))
		ball(m, d * 0.5, s * spread, y, z - d * 0.38, pupil or rgb(15, 15, 20))
	end
end

local function glow(part: BasePart, color: Color3, range: number, brightness: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Parent = part
end

local Bodies = {}

-- Common ----------------------------------------------------------------------------------------------

function Bodies.Shrimpbishop(m)
	local pink, dark = rgb(255, 135, 120), rgb(225, 95, 85)
	ball(m, 2.2, 0, 1.1, 0.7, pink)
	ball(m, 2.4, 0, 2.3, 0, pink)
	ball(m, 2.0, 0, 3.4, -0.3, pink)
	addPart(m, V(1.8, 0.3, 1.4), C(0, 0.3, 1.9) * A(rad(-15), 0, 0), dark) -- tail fan
	for _, s in { -1, 1 } do
		addPart(m, V(0.15, 0.15, 2.6), C(s * 0.4, 4.4, -1.4) * A(rad(35), 0, 0), dark) -- feelers
	end
	eyes(m, 3.6, -1.15, 0.45, 0.6)
	addPart(m, V(1.5, 1.9, 1.5), C(0, 5.1, -0.3), rgb(250, 250, 245)) -- mitre
	addPart(m, V(0.35, 1.95, 1.55), C(0, 5.1, -0.3), rgb(240, 190, 40), { material = Enum.Material.Metal })
	addPart(m, V(1.1, 0.6, 1.1), C(0, 6.3, -0.3) * A(0, rad(45), 0), rgb(250, 250, 245))
	addPart(m, V(0.2, 5.5, 0.2), C(1.9, 2.75, -0.6), rgb(140, 100, 50)) -- crozier
	ball(m, 0.8, 1.9, 5.6, -0.6, rgb(240, 190, 40), { material = Enum.Material.Metal })
end

function Bodies.WetSockSteve(m)
	local sock = rgb(225, 232, 240)
	addPart(m, V(1.9, 3.6, 1.7), C(0, 2.6, 0), sock, { material = Enum.Material.Fabric })
	addPart(m, V(1.9, 1.4, 3.1), C(0, 0.7, -0.7), sock, { material = Enum.Material.Fabric }) -- the foot
	addPart(m, V(1.95, 0.35, 1.75), C(0, 4.0, 0), rgb(220, 50, 50))
	addPart(m, V(1.95, 0.35, 1.75), C(0, 3.4, 0), rgb(40, 90, 200))
	eyes(m, 2.9, -0.95, 0.45, 0.9)
	addPart(m, V(0.9, 0.2, 0.2), C(0, 2.1, -0.9), rgb(60, 30, 30)) -- worried mouth
	disc(m, 4.6, 0.15, 0, 0.08, 0, rgb(70, 140, 230), { material = GLASS, transparency = 0.35 }) -- his puddle
	for _, d in { { 0.7, 0.3, -2.2 }, { -0.8, 0.5, 1.1 }, { 1.0, 2.0, -0.9 }, { -1.0, 3.3, 0.2 } } do
		ball(m, 0.45, d[1], d[2], d[3], rgb(90, 170, 255), { material = GLASS, transparency = 0.25 }) -- drips
	end
end

function Bodies.PuddleProphet(m)
	disc(m, 5.2, 0.3, 0, 0.15, 0, rgb(70, 140, 220), { material = GLASS, transparency = 0.2 })
	addPart(m, V(1.7, 2.4, 1.3), C(0, 1.5, 0), rgb(110, 60, 170), { material = Enum.Material.Fabric }) -- robe
	ball(m, 1.5, 0, 3.3, 0, rgb(240, 200, 160))
	addPart(m, V(1.1, 1.1, 0.4), C(0, 2.75, -0.65), rgb(245, 245, 245)) -- beard
	eyes(m, 3.5, -0.6, 0.3, 0.35)
	for _, s in { -1, 1 } do
		addPart(m, V(0.4, 1.8, 0.4), C(s * 1.2, 3.0, -0.2) * A(0, 0, rad(-s * 25)), rgb(110, 60, 170)) -- raised arms
	end
	disc(m, 2.4, 0.15, 0, 4.4, 0, rgb(255, 225, 90), { material = NEON, transparency = 0.2 }) -- halo
end

-- Rare ------------------------------------------------------------------------------------------------

function Bodies.CrabMagistrate(m)
	local red = rgb(225, 65, 45)
	addPart(m, V(3.6, 1.5, 2.6), C(0, 1.6, 0), red)
	ball(m, 2.8, 0, 1.9, 0, red)
	for _, s in { -1, 1 } do
		addPart(m, V(1.3, 1.0, 1.5), C(s * 2.5, 2.3, -0.9), red) -- claws
		addPart(m, V(1.1, 0.4, 1.0), C(s * 2.5, 3.0, -1.2) * A(rad(20), 0, 0), red)
		for i = -1, 1 do
			addPart(m, V(1.4, 0.25, 0.25), C(s * 1.9, 0.6, i * 0.8) * A(0, 0, rad(s * 35)), rgb(190, 50, 35)) -- legs
		end
		addPart(m, V(0.2, 1.0, 0.2), C(s * 0.5, 3.1, -0.8), red)
		ball(m, 0.5, s * 0.5, 3.7, -0.8, rgb(20, 20, 20)) -- eye stalks
	end
	for _, w in { { -0.9, 3.2, 0.3 }, { 0, 3.5, 0.4 }, { 0.9, 3.2, 0.3 }, { -1.2, 2.6, 0.6 }, { 1.2, 2.6, 0.6 } } do
		ball(m, 1.0, w[1], w[2], w[3], rgb(245, 245, 245)) -- powdered wig
	end
	addPart(m, V(0.2, 0.2, 1.8), C(2.5, 3.4, -1.9), rgb(110, 70, 40)) -- gavel
	addPart(m, V(0.8, 0.6, 0.6), C(2.5, 3.4, -2.8), rgb(90, 55, 30))
end

function Bodies.BarnacleBard(m)
	local rock = rgb(130, 140, 140)
	ball(m, 3.2, 0, 1.7, 0, rock, { material = Enum.Material.Slate })
	for _, b in { { 1.2, 2.5, 0.6 }, { -1.3, 1.6, 0.7 }, { 0.6, 0.8, 1.3 }, { -0.5, 2.9, 0.8 }, { 1.4, 1.2, -0.3 }, { -1.1, 0.7, -0.6 } } do
		disc(m, 0.7, 0.5, b[1], b[2], b[3], rgb(225, 220, 205), { material = Enum.Material.Pebble }) -- barnacles
	end
	eyes(m, 2.2, -1.4, 0.5, 0.6)
	addPart(m, V(0.6, 0.4, 0.2), C(0, 1.5, -1.55), rgb(40, 20, 20)) -- singing mouth
	addPart(m, V(2.0, 0.5, 2.0), C(0, 3.35, 0), rgb(190, 40, 60), { material = Enum.Material.Fabric }) -- beret
	addPart(m, V(0.15, 2.2, 0.4), C(0.8, 4.2, 0.4) * A(0, 0, rad(-30)), rgb(255, 215, 60)) -- feather
	ball(m, 1.4, 1.4, 1.3, -1.3, rgb(160, 100, 50), { material = Enum.Material.Wood }) -- lute
	addPart(m, V(0.25, 0.25, 2.0), C(0.9, 1.9, -1.9) * A(rad(-35), rad(20), 0), rgb(90, 55, 30))
end

function Bodies.LampEel(m)
	local teal = rgb(40, 185, 170)
	for _, s in { { 1.2, 0.6, 1.8 }, { 1.3, 1.3, 1.0 }, { 1.4, 2.1, 0.4 }, { 1.4, 3.0, 0 }, { 1.3, 3.8, -0.3 } } do
		ball(m, s[1], 0, s[2], s[3], teal) -- coiled body
	end
	ball(m, 1.7, 0, 4.6, -0.6, teal)
	addPart(m, V(0.2, 1.2, 1.4), C(0, 3.0, 0.9), rgb(255, 120, 200)) -- fin
	eyes(m, 4.8, -1.3, 0.4, 0.55)
	addPart(m, V(0.12, 1.6, 0.12), C(0, 6.0, -1.1) * A(rad(-25), 0, 0), rgb(40, 40, 40))
	local bulb = ball(m, 0.9, 0, 6.8, -1.5, rgb(255, 245, 140), { material = NEON })
	glow(bulb, rgb(255, 240, 150), 12, 2)
end

-- Epic ------------------------------------------------------------------------------------------------

function Bodies.TidepoolTyrant(m)
	local green = rgb(85, 175, 80)
	disc(m, 5.4, 0.5, 0, 0.25, 0, rgb(120, 120, 125), { material = Enum.Material.Slate })
	disc(m, 4.6, 0.55, 0, 0.3, 0, rgb(60, 150, 220), { material = GLASS, transparency = 0.2 }) -- his tidepool
	addPart(m, V(2.0, 2.4, 2.8), C(0, 2.6, 0.4), green)
	addPart(m, V(1.9, 1.4, 2.4), C(0, 4.3, -0.9), green)
	addPart(m, V(1.7, 0.4, 1.8), C(0, 3.5, -1.3), rgb(70, 150, 70)) -- jaw
	for i = -2, 2 do
		addPart(m, V(0.2, 0.3, 0.2), C(i * 0.3, 3.8, -2.05), rgb(250, 250, 250)) -- teeth
	end
	eyes(m, 4.7, -2.05, 0.55, 0.45)
	for _, s in { -1, 1 } do
		addPart(m, V(0.3, 0.3, 0.8), C(s * 0.9, 3.0, -1.2), green) -- tiny arms
		addPart(m, V(0.8, 1.6, 1.0), C(s * 0.7, 0.9, 0.6), green)
	end
	addPart(m, V(1.0, 1.0, 2.6), C(0, 2.0, 2.5) * A(rad(20), 0, 0), green) -- tail
	addPart(m, V(1.3, 0.5, 1.3), C(0, 5.25, -0.9), rgb(255, 200, 40), { material = Enum.Material.Metal }) -- crown
	for _, s in { -0.45, 0, 0.45 } do
		addPart(m, V(0.25, 0.6, 0.25), C(s, 5.75, -0.9), rgb(255, 220, 60), { material = NEON })
	end
end

function Bodies.KelpColossus(m)
	local kelp = rgb(60, 135, 50)
	local grass = { material = Enum.Material.Grass }
	addPart(m, V(2.6, 4.2, 1.8), C(0, 2.6, 0), rgb(40, 95, 40), grass)
	for i, ang in { -24, -12, 0, 12, 24 } do
		local h = 6 + (i % 2) * 1.2
		addPart(m, V(0.7, h, 0.3), C(math.sin(rad(ang)) * 1.6, h / 2, 0.5) * A(0, 0, rad(-ang)), kelp, grass) -- fronds
	end
	for _, s in { -1, 1 } do
		ball(m, 0.6, s * 0.55, 4.0, -0.95, rgb(120, 255, 240), { material = NEON }) -- glowing eyes
		addPart(m, V(0.5, 3.4, 0.3), C(s * 2.1, 3.2, -0.2) * A(0, 0, rad(s * 40)), kelp, grass) -- arms
	end
	addPart(m, V(1.2, 0.3, 0.2), C(0, 3.0, -0.95), rgb(20, 40, 20))
	for _, b in { { 1.6, 5.5, -0.6 }, { -1.4, 6.6, -0.2 }, { 0.6, 7.6, 0.2 } } do
		ball(m, 0.5, b[1], b[2], b[3], rgb(180, 230, 255), { material = GLASS, transparency = 0.4 }) -- bubbles
	end
end

function Bodies.GullGoblin(m)
	ball(m, 2.7, 0, 1.9, 0, rgb(245, 245, 245))
	for _, s in { -1, 1 } do
		addPart(m, V(0.3, 1.1, 2.4), C(s * 1.45, 2.1, 0.2) * A(0, 0, rad(s * 20)), rgb(150, 155, 165)) -- wings
		addPart(m, V(0.25, 0.7, 1.3), C(s * 1.0, 3.9, -0.2) * A(0, 0, rad(-s * 55)), rgb(120, 180, 60)) -- goblin ears
		addPart(m, V(0.2, 0.8, 0.2), C(s * 0.5, 0.4, 0), rgb(255, 150, 40))
	end
	ball(m, 1.7, 0, 3.7, -0.3, rgb(120, 180, 60))
	addPart(m, V(0.5, 0.4, 1.1), C(0, 3.5, -1.3), rgb(255, 160, 40)) -- beak
	for _, s in { -1, 1 } do
		ball(m, 0.45, s * 0.4, 3.95, -1.0, rgb(255, 240, 60), { material = NEON })
	end
	addPart(m, V(0.9, 0.9, 0.6), C(1.3, 2.3, -1.4), rgb(220, 40, 40)) -- stolen chip carton
	for i = -1, 1 do
		addPart(m, V(0.18, 1.1, 0.18), C(1.3 + i * 0.25, 3.0, -1.4) * A(0, 0, rad(i * 10)), rgb(255, 215, 80))
	end
end

-- Legendary -------------------------------------------------------------------------------------------

function Bodies.DrownedNacho(m)
	addPart(m, V(0.7, 4.8, 4.8), C(0, 2.6, 0) * A(0, rad(90), 0), rgb(240, 180, 50), { class = "WedgePart" })
	addPart(m, V(0.7, 4.8, 4.8), C(0, 2.6, 0.2) * A(0, rad(-90), 0), rgb(225, 160, 40), { class = "WedgePart" })
	for _, d in { { -1.4, 3.6, 1.6 }, { 0.2, 4.4, 1.2 }, { 1.2, 2.2, 1.4 } } do
		addPart(m, V(0.5, d[3], 0.3), C(d[1], d[2], -0.5), rgb(255, 205, 40), { material = NEON }) -- cheese drips
	end
	eyes(m, 2.6, -0.6, 0.6, 0.85)
	addPart(m, V(0.9, 0.25, 0.2), C(0, 1.5, -0.55), rgb(80, 20, 20))
	addPart(m, V(2.0, 0.6, 0.3), C(0, 2.7, -0.95), rgb(40, 140, 220), { material = GLASS, transparency = 0.3 }) -- dive mask
	addPart(m, V(0.3, 2.6, 0.3), C(1.3, 4.1, -0.6), rgb(255, 120, 40)) -- snorkel
	for _, w in { { -1.8, 1.0 }, { 1.9, 0.8 }, { -0.6, 0.4 } } do
		addPart(m, V(0.3, 2.2, 0.2), C(w[1], w[2] + 0.8, 0.2) * A(0, 0, rad(w[1] * 10)), rgb(40, 120, 50), { material = Enum.Material.Grass })
	end
	for _, b in { { 0.8, 5.6 }, { -0.5, 6.4 }, { 0.3, 7.2 } } do
		ball(m, 0.5, b[1], b[2], -0.3, rgb(180, 230, 255), { material = GLASS, transparency = 0.35 })
	end
end

function Bodies.Moonanchor(m)
	local iron = rgb(70, 76, 92)
	local metal = { material = Enum.Material.Metal }
	local shank = addPart(m, V(0.8, 5.2, 0.8), C(0, 3.1, 0), iron, metal)
	addPart(m, V(3.6, 0.6, 0.6), C(0, 5.0, 0), iron, metal)
	for _, s in { -1, 1 } do
		addPart(m, V(2.6, 0.7, 0.7), C(s * 1.1, 0.9, 0) * A(0, 0, rad(s * 28)), iron, metal) -- flukes
		addPart(m, V(1.0, 1.0, 0.5), C(s * 2.3, 1.6, 0) * A(0, 0, rad(s * -20)), iron, metal)
	end
	ball(m, 3.0, 0, 7.4, 0, rgb(255, 245, 180), { material = NEON }) -- the moon
	ball(m, 2.7, 0.9, 7.7, -0.5, rgb(25, 30, 70)) -- shadow carving the crescent
	ball(m, 0.4, -0.9, 7.6, -1.35, rgb(20, 20, 30))
	addPart(m, V(0.6, 0.2, 0.2), C(-0.8, 6.9, -1.4), rgb(20, 20, 30))
	for i = 1, 4 do
		ball(m, 0.5, -1.5 - i * 0.3, 5.0 - i * 0.7, 0, rgb(150, 150, 160), metal) -- chain
	end
	glow(shank, rgb(255, 240, 180), 16, 2.5)
end

function Bodies.HighTideHooligan(m)
	addPart(m, V(2.8, 2.6, 2.2), C(0, 1.3, 0), rgb(30, 125, 225))
	addPart(m, V(2.8, 1.3, 2.4), C(0, 3.1, -0.4) * A(rad(-15), 0, 0), rgb(60, 160, 240))
	addPart(m, V(2.8, 0.9, 1.4), C(0, 3.7, -1.3) * A(rad(-45), 0, 0), rgb(110, 195, 250)) -- curling wave
	for i = -1, 1 do
		ball(m, 0.9, i * 1.0, 4.0, -1.7, rgb(245, 250, 255)) -- foam crest
	end
	for _, s in { -1, 1 } do
		addPart(m, V(0.9, 0.45, 0.2), C(s * 0.55, 2.6, -1.25), rgb(15, 15, 20)) -- shades
	end
	addPart(m, V(0.4, 0.15, 0.2), C(0, 2.7, -1.25), rgb(15, 15, 20))
	addPart(m, V(1.2, 0.25, 0.15), C(0, 1.9, -1.15), rgb(255, 255, 255)) -- grin
	addPart(m, V(1.7, 0.55, 1.7), C(0, 4.3, -0.2), rgb(220, 40, 40)) -- backwards cap
	addPart(m, V(1.3, 0.15, 0.9), C(0, 4.1, 0.9), rgb(220, 40, 40))
	addPart(m, V(1.2, 5.2, 0.3), C(2.1, 2.6, 0.4) * A(0, 0, rad(-8)), rgb(255, 140, 40)) -- surfboard
	addPart(m, V(0.3, 5.0, 0.32), C(2.1, 2.6, 0.4) * A(0, 0, rad(-8)), rgb(255, 255, 255))
end

-- Labels, mutation and assembly ---------------------------------------------------------------------

local function addNameRarityRateLabel(root: BasePart, entry, mutated: boolean, height: number, price: number?)
	local rarityColor = if mutated then Brainrots.GOLD else Brainrots.rarityColor(entry.rarity)
	local lines = {
		{ entry.name, 1.7, Color3.new(1, 1, 1) },
		{ (if mutated then "GOLDEN " else "") .. string.upper(entry.rarity), 1.25, rarityColor },
		{ Economy.formatMoney(Economy.keeperRate(entry, mutated)) .. "/s", 1.4, rgb(110, 255, 120) },
	}
	if price then
		table.insert(lines, { "BUY " .. Economy.formatMoney(price), 1.4, rgb(255, 230, 90) })
	end
	local totalStuds = 0
	for _, line in lines do
		totalStuds += line[2]
	end

	-- Sized in studs, not pixels, so far-away labels shrink instead of piling up on screen.
	local bb = Instance.new("BillboardGui")
	bb.Name = "KeeperLabel"
	bb.Size = UDim2.fromScale(13, totalStuds)
	bb.StudsOffsetWorldSpace = V(0, height + totalStuds / 2 + 0.4, 0)
	bb.MaxDistance = 110
	bb.LightInfluence = 0
	bb.Adornee = root
	bb.Parent = root

	local y = 0
	for i, line in lines do
		local t = Instance.new("TextLabel")
		t.Name = "Line" .. i
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, line[2] / totalStuds)
		t.Position = UDim2.fromScale(0, y / totalStuds)
		t.Font = Enum.Font.FredokaOne
		t.Text = line[1]
		t.TextScaled = true
		t.TextColor3 = line[3]
		t.TextStrokeTransparency = 0
		t.TextStrokeColor3 = rgb(10, 15, 30)
		t.Parent = bb
		y += line[2]
	end
end

local function applyGoldenMutation(model: Model, root: BasePart)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= root then
			p.Color = p.Color:Lerp(Brainrots.GOLD, 0.55)
			if p.Material == Enum.Material.SmoothPlastic then
				p.Material = Enum.Material.Foil
			end
		end
	end
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = Brainrots.GOLD
	sparkles.Parent = root
end

-- Builds a finished, welded keeper. Pass price to add a BUY line (stall display).
function BrainrotModels.build(id: string, mutated: boolean, price: number?): Model
	local entry = assert(Brainrots.get(id), "unknown brainrot " .. tostring(id))
	local model = Instance.new("Model")
	model.Name = entry.id
	local root = addPart(model, V(3, 0.2, 3), C(0, 0.1, 0), Color3.new(), { transparency = 1 })
	root.Name = "Root"
	model.PrimaryPart = root

	Bodies[entry.id](model)
	if mutated then
		applyGoldenMutation(model, root)
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = p
			weld.Parent = p
		end
	end
	model:ScaleTo(Brainrots.Rarities[entry.rarity].scale)
	model:SetAttribute("KeeperId", entry.id)
	model:SetAttribute("Mutated", mutated)
	addNameRarityRateLabel(root, entry, mutated, model:GetExtentsSize().Y, price)
	return model
end

-- Stands a keeper on the top face of a slot or pedestal, facing the market (+Z).
function BrainrotModels.standOn(model: Model, surface: BasePart)
	local halfHeight = if surface.Shape == Enum.PartType.Cylinder then surface.Size.X / 2 else surface.Size.Y / 2
	model.PrimaryPart.Anchored = true
	model:PivotTo(C(surface.Position + V(0, halfHeight, 0)) * A(0, math.pi, 0))
end

return BrainrotModels
