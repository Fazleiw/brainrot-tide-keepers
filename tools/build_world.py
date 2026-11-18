#!/usr/bin/env python3
"""Writes default.project.json: the Rojo tree plus the static 3D harbour world of Brainrot Tide Keepers.

Layout: low market floor (top y=0, floods in a surge) with the Tide Stall in the middle; a north terrace
(top y=8) is the high ground holding 4 plots, each reached by its own ramp; the sea and docks lie south.
Rojo ignores Position, so every part is written with an explicit CFrame.
"""
import json, math, os, random

random.seed(7)
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def rgb(r, g, b):
    return [round(r / 255, 4), round(g / 255, 4), round(b / 255, 4)]


def cframe(pos, rx=0.0, ry=0.0, rz=0.0):
    """Rojo CFrame from a position and XYZ euler degrees, composed like CFrame.Angles (X then Y then Z)."""
    ax, ay, az = (math.radians(a) for a in (rx, ry, rz))
    cx, sx, cy, sy, cz, sz = math.cos(ax), math.sin(ax), math.cos(ay), math.sin(ay), math.cos(az), math.sin(az)
    X = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    Y = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    Z = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]
    mul = lambda a, b: [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    m = mul(mul(X, Y), Z)
    return {"CFrame": {"position": pos, "orientation": [[round(v, 6) for v in row] for row in m]}}


def part(size, pos, color, material="SmoothPlastic", cls="Part", rot=None, children=None, **props):
    p = {"Anchored": True, "Size": size, "Color": color, "Material": material,
         "TopSurface": "Smooth", "BottomSurface": "Smooth", "CFrame": cframe(pos, *(rot or (0, 0, 0)))}
    p.update(props)
    node = {"$className": cls, "$properties": p}
    if children:
        node.update(children)
    return node


def label(text, color, stroke=True):
    props = {"Text": text, "TextScaled": True, "Font": "FredokaOne", "TextColor3": color,
             "BackgroundTransparency": 1, "Size": {"UDim2": [[1, 0], [1, 0]]}}
    if stroke:
        props["TextStrokeTransparency"] = 0
        props["TextStrokeColor3"] = rgb(10, 20, 40)
    return {"$className": "TextLabel", "$properties": props}


def surface_text(text, color, pps=25, stroke=True, face="Back"):
    return {"$className": "SurfaceGui",
            "$properties": {"Face": face, "SizingMode": "PixelsPerStud", "PixelsPerStud": pps, "LightInfluence": 0},
            "Text": label(text, color, stroke)}


def light(color, rng=22, brightness=2.5):
    return {"$className": "PointLight", "$properties": {"Color": color, "Range": rng, "Brightness": brightness, "Shadows": False}}


def folder(cls="Folder"):
    return {"$className": cls}


world = {}

# ---------------------------------------------------------------- ground, walls and sea
ground = folder()
ground["MarketFloor"] = part([240, 2, 140], [0, -1, 15], rgb(92, 84, 78), "Cobblestone")
ground["HighGroundTerrace"] = part([240, 10, 40], [0, 3, -75], rgb(120, 104, 86), "Brick")
ground["TerraceEdge"] = part([240, 1, 2], [0, 8.5, -55.5], rgb(214, 190, 120), "Wood")
ground["SeaWall"] = part([240, 3, 3], [0, 0.5, 86], rgb(80, 86, 96), "Slate")
ground["Sea"] = part([900, 2, 600], [0, -3, 380], rgb(18, 60, 110), "Glass", Transparency=0.15, CanCollide=False)
ground["SeaBed"] = part([1200, 2, 1200], [0, -12, 0], rgb(30, 40, 50), "Sand")
ground["WestWall"] = part([3, 14, 180], [-121.5, 3, -5], rgb(70, 74, 84), "Slate")
ground["EastWall"] = part([3, 14, 180], [121.5, 3, -5], rgb(70, 74, 84), "Slate")
ground["NorthWall"] = part([246, 20, 3], [0, 8, -96.5], rgb(70, 74, 84), "Slate")
ground["SouthBarrier"] = part([240, 30, 1], [0, 15, 88], rgb(0, 0, 0), Transparency=1)
gauge = folder("Model")  # tide gauge post with painted level marks
gauge["Post"] = part([1.2, 12, 1.2], [34, 6, 30], rgb(240, 240, 240), "Wood")
for i, (y, c) in enumerate([(1.5, rgb(80, 200, 120)), (3.5, rgb(255, 200, 40)), (5.5, rgb(255, 60, 60))]):
    gauge[f"Mark{i}"] = part([1.4, 0.5, 1.4], [34, y, 30], c, "Neon")
ground["TideGauge"] = gauge
# The game's title on the back wall, above the gaps between the bases and high enough to clear the keepers' labels.
for side in (-1, 1):
    tx = side * 52
    ground[f"TitleBoard{side}"] = part([46, 9, 1], [tx, 52, -95.6], rgb(12, 16, 30), children={
        "Title": surface_text("BRAINROT TIDE KEEPERS", rgb(255, 225, 70), 20), "Glow": light(rgb(255, 220, 120), 30, 3)})
    ground[f"TitleFrame{side}"] = part([48, 11, 0.6], [tx, 52, -96.2], rgb(60, 220, 230), "Neon")
    for px in (-16, 16):
        ground[f"TitlePost{side}_{px}"] = part([1.2, 30, 1.2], [tx + px, 33, -96], rgb(60, 50, 40), "Wood")
world["Harbour"] = ground

# The water that rises in a surge: its top starts at y=-1.5 (under the floor); TideService tweens it up.
world["TideWater"] = part([236, 10, 200], [0, -6.5, 40], rgb(40, 140, 220), "Glass", Transparency=0.35,
                          CanCollide=False, CanQuery=False, CanTouch=False, CastShadow=False)

world["SpawnLocation"] = part([10, 1, 10], [0, 0.5, 50], rgb(90, 160, 170), "Marble", cls="SpawnLocation",
                              Neutral=True, Duration=0)

# ---------------------------------------------------------------- four plots on the terrace
PLOT_X = [-78, -26, 26, 78]
ACCENT = [rgb(60, 200, 210), rgb(255, 120, 90), rgb(170, 110, 255), rgb(140, 220, 70)]
plots = folder()
for i, x in enumerate(PLOT_X):
    acc = ACCENT[i]
    plot = folder("Model")
    plot["Base"] = part([44, 1, 34], [x, 8.5, -75], rgb(176, 150, 112), "WoodPlanks")
    plot["Trim"] = part([46, 0.8, 36], [x, 8.3, -75], acc, "Neon")
    slots = folder()
    k = 1
    for sz in (-84, -70):
        for sx in (-13, 0, 13):
            slots[f"Slot{k}"] = part([7, 0.6, 7], [x + sx, 9.3, sz], rgb(235, 225, 200), "Marble",
                                     children={"Ring": part([8, 0.3, 8], [x + sx, 9.1, sz], acc, "Neon")})
            k += 1
    plot["Slots"] = slots
    plot["LockPad"] = part([4, 1, 4], [x - 17, 9.5, -60], rgb(230, 60, 60), "Neon")
    plot["LockPost"] = part([1, 5, 1], [x - 17, 11, -62.5], rgb(60, 60, 70), "Metal")
    plot["Barrier"] = part([44, 9, 0.6], [x, 13.5, -57.6], rgb(255, 60, 80), "ForceField", Transparency=1, CanCollide=False)
    plot["SignPost"] = part([1.2, 16, 1.2], [x, 17, -93.2], rgb(60, 50, 40), "Wood")
    # Cream text on a near-black board inside an accent-coloured frame: readable from across the market.
    sign_gui = surface_text(f"EMPTY PLOT {i + 1}", rgb(255, 246, 225))
    sign_gui["OwnerLabel"] = sign_gui.pop("Text")
    plot["SignBoard"] = part([20, 4, 0.6], [x, 25, -92], rgb(16, 18, 26), children={"OwnerSign": sign_gui, "Glow": light(acc, 18, 2)})
    plot["SignFrame"] = part([21, 5, 0.4], [x, 25, -92.4], acc, "Neon")
    for fz in range(-90, -58, 8):
        plot[f"FenceL{fz}"] = part([0.8, 3, 0.8], [x - 22, 10.5, fz], rgb(90, 70, 50), "Wood")
        plot[f"FenceR{fz}"] = part([0.8, 3, 0.8], [x + 22, 10.5, fz], rgb(90, 70, 50), "Wood")
    plot["RailL"] = part([0.5, 0.5, 34], [x - 22, 11.6, -75], rgb(120, 95, 70), "Wood")
    plot["RailR"] = part([0.5, 0.5, 34], [x + 22, 11.6, -75], rgb(120, 95, 70), "Wood")
    run, rise = 20, 8  # ramp from the market (y=0, z=-35) up to the plot gate (y=8, z=-55)
    length, ang = math.hypot(run, rise), math.degrees(math.atan2(rise, run))
    plot["Ramp"] = part([14, 1, length + 1], [x, 3.6, -45], rgb(150, 120, 85), "WoodPlanks", rot=(ang, 0, 0))
    plot["RampRailL"] = part([0.6, 0.6, length], [x - 7, 6.2, -45], acc, "Neon", rot=(ang, 0, 0))
    plot["RampRailR"] = part([0.6, 0.6, length], [x + 7, 6.2, -45], acc, "Neon", rot=(ang, 0, 0))
    plots[f"Plot{i + 1}"] = plot
world["Plots"] = plots

# ---------------------------------------------------------------- the Tide Stall in the market centre
RARITY = [("Common", rgb(190, 200, 210)), ("Rare", rgb(70, 160, 255)), ("Epic", rgb(190, 90, 255)), ("Legendary", rgb(255, 190, 40))]
stall = folder("Model")
stall["Counter"] = part([62, 1, 14], [0, 0.5, 8], rgb(110, 80, 55), "WoodPlanks")
for cx in (-30, 30):
    for cz in (2, 14):
        stall[f"Pole{cx}_{cz}"] = part([1, 24, 1], [cx, 12, cz], rgb(80, 60, 40), "Wood")
for s in range(11):
    # Raised high enough that the keepers' labels and price tags float under it, not through it.
    stall[f"Awning{s}"] = part([62 / 11, 0.6, 16], [-31 + 62 / 22 + s * 62 / 11, 24.5, 8],
                               rgb(230, 60, 60) if s % 2 == 0 else rgb(245, 240, 230), "Fabric", rot=(-8, 0, 0))
pedestals = folder()
for j, (name, col) in enumerate(RARITY):
    px = -24 + j * 16  # 8-stud gaps between the 8-stud pedestals so their labels never touch
    pedestals[name] = part([3, 8, 8], [px, 2.5, 8], rgb(60, 64, 80), "Marble", rot=(0, 0, 90), Shape="Cylinder",
                           children={"Rim": part([0.6, 8.8, 8.8], [px, 4.3, 8], col, "Neon", rot=(0, 0, 90), Shape="Cylinder"),
                                     "Light": light(col, 16, 3)})
    stall[f"Tag{name}"] = part([8, 1.6, 0.4], [px, 1.2, 12.3], col, "Neon")  # the keeper's own label names the rarity
stall["Pedestals"] = pedestals
stall["BigSign"] = part([60, 10, 1], [0, 32, 4], rgb(20, 30, 60), children={
    "Front": surface_text("BRAINROT TIDE KEEPERS", rgb(255, 220, 80), 20), "Glow": light(rgb(255, 210, 120), 30, 3)})
stall["SignTrim"] = part([62, 11, 0.6], [0, 32, 3.6], rgb(60, 220, 230), "Neon")
stall["SubSign"] = part([30, 2.6, 0.4], [0, 25.8, 16.3], rgb(250, 240, 220), children={
    "Gui": surface_text("FRESH FROM THE TIDE - HOLD E TO BUY", rgb(30, 60, 120), 30, stroke=False)})
world["Stall"] = stall

# ---------------------------------------------------------------- decor: lanterns, crates, barrels, docks, boats, lighthouse
decor = folder()
lanterns = [(-60, 20), (-30, 40), (30, 40), (60, 20), (-95, -20), (95, -20), (-95, 60), (95, 60), (-45, -28), (45, -28), (0, 75), (-70, 78), (70, 78)]
for i, (lx, lz) in enumerate(lanterns):
    m = folder("Model")
    m["Pole"] = part([0.6, 11, 0.6], [lx, 5.5, lz], rgb(40, 40, 48), "Metal")
    m["Arm"] = part([3, 0.4, 0.4], [lx + 1.2, 10.8, lz], rgb(40, 40, 48), "Metal")
    m["Lamp"] = part([1.6, 1.8, 1.6], [lx + 2.4, 9.9, lz], rgb(255, 180, 80), "Neon", children={"Light": light(rgb(255, 170, 90), 28, 3)})
    decor[f"Lantern{i}"] = m
for i in range(26):
    cx = random.choice([-1, 1]) * random.uniform(40, 112)
    cz = random.uniform(-30, 80)
    s = random.choice([3, 4, 5])
    for h in range(random.randint(1, 3)):
        decor[f"Crate{i}_{h}"] = part([s, s, s], [cx + random.uniform(-0.4, 0.4), s / 2 + h * s, cz],
                                      random.choice([rgb(160, 120, 70), rgb(140, 100, 60), rgb(120, 90, 55)]), "WoodPlanks",
                                      rot=(0, random.uniform(-20, 20), 0))
for i in range(14):
    bx = random.choice([-1, 1]) * random.uniform(30, 110)
    bz = random.uniform(-30, 82)
    decor[f"Barrel{i}"] = part([4, 3, 3], [bx, 2, bz], random.choice([rgb(100, 70, 45), rgb(60, 110, 140), rgb(170, 60, 50)]),
                               "Wood", rot=(0, 0, 90), Shape="Cylinder")
decor["NetA"] = part([16, 6, 0.3], [-60, 5, 82], rgb(200, 190, 150), "Fabric", Transparency=0.4)
decor["NetB"] = part([16, 6, 0.3], [60, 5, 82], rgb(200, 190, 150), "Fabric", Transparency=0.4)
for i, dx in enumerate((-70, 0, 70)):
    decor[f"Dock{i}"] = part([10, 1, 50], [dx, 0.2, 112], rgb(130, 100, 70), "WoodPlanks")
    for pz in (92, 104, 116, 128):
        decor[f"PilingL{i}_{pz}"] = part([1.2, 6, 1.2], [dx - 5, -1.5, pz], rgb(80, 60, 40), "Wood")
        decor[f"PilingR{i}_{pz}"] = part([1.2, 6, 1.2], [dx + 5, -1.5, pz], rgb(80, 60, 40), "Wood")
for i, (bx, bz, yaw) in enumerate([(-38, 120, 20), (38, 125, -15), (105, 115, 70)]):
    boat = folder("Model")
    boat["Hull"] = part([8, 3, 18], [bx, -0.5, bz], rgb(150, 50, 40), "WoodPlanks", rot=(0, yaw, 0))
    boat["Deck"] = part([7, 0.4, 16], [bx, 1.1, bz], rgb(200, 170, 120), "WoodPlanks", rot=(0, yaw, 0))
    boat["Mast"] = part([0.8, 14, 0.8], [bx, 8, bz], rgb(90, 70, 50), "Wood")
    boat["Sail"] = part([0.3, 9, 8], [bx, 9.5, bz], rgb(240, 235, 220), "Fabric", rot=(0, yaw + 90, 0))
    decor[f"Boat{i}"] = boat
lighthouse = folder("Model")
lighthouse["Tower"] = part([30, 12, 12], [110, 23, -82], rgb(240, 240, 240), "Concrete", rot=(0, 0, 90), Shape="Cylinder")
for k, y in enumerate((14, 26)):
    lighthouse[f"Stripe{k}"] = part([4, 12.4, 12.4], [110, y, -82], rgb(220, 50, 50), "Concrete", rot=(0, 0, 90), Shape="Cylinder")
lighthouse["Lamp"] = part([5, 7, 7], [110, 40.5, -82], rgb(255, 240, 160), "Neon", rot=(0, 0, 90), Shape="Cylinder",
                          children={"Light": light(rgb(255, 240, 180), 60, 5)})
lighthouse["Cap"] = part([3, 9, 9], [110, 44.5, -82], rgb(40, 40, 50), "Metal", rot=(0, 0, 90), Shape="Cylinder")
decor["Lighthouse"] = lighthouse
decor["HighGroundSign"] = part([18, 3, 0.4], [0, 13, -56], rgb(30, 120, 60),
                               children={"Gui": surface_text("HIGH GROUND - SAFE FROM THE TIDE", rgb(255, 255, 255))})
world["Decor"] = decor

# ---------------------------------------------------------------- project
project = {
    "name": "brainrot-tide-keepers",
    "tree": {
        "$className": "DataModel",
        "ReplicatedStorage": {"Shared": {"$path": "src/shared"}},
        "ServerScriptService": {"Server": {"$path": "src/server"}},
        "StarterPlayer": {
            "$properties": {"CameraMaxZoomDistance": 120},
            "StarterPlayerScripts": {"Client": {"$path": "src/client"}},
        },
        "Workspace": dict({"$properties": {"FilteringEnabled": True}}, **world),
        "Lighting": {
            "$properties": {"Ambient": rgb(95, 90, 120), "OutdoorAmbient": rgb(145, 135, 175), "Brightness": 2.8,
                            "ClockTime": 17.4, "GeographicLatitude": 85, "GlobalShadows": True, "Technology": "Future", "EnvironmentDiffuseScale": 0.5},
            "Atmosphere": {"$className": "Atmosphere", "$properties": {"Density": 0.28, "Offset": 0.1, "Color": rgb(255, 170, 140),
                                                                     "Decay": rgb(90, 80, 140), "Glare": 0.4, "Haze": 1.6}},
            "Bloom": {"$className": "BloomEffect", "$properties": {"Intensity": 0.25, "Size": 24, "Threshold": 1.7}},
            "Grade": {"$className": "ColorCorrectionEffect", "$properties": {"Brightness": 0.05, "Saturation": 0.15, "Contrast": 0.08}},
        },
        "SoundService": {"$properties": {"RespectFilteringEnabled": True}},
    },
}
with open(os.path.join(ROOT, "default.project.json"), "w") as f:
    json.dump(project, f, indent=1)
print("wrote default.project.json")
