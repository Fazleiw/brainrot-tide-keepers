-- The Tide Stall: four pedestals, one per rarity, each showing a fresh keeper washed in by the tide.
-- Hold E at a pedestal to buy it (the server checks money and distance); 2% of buys come out Golden.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Brainrots = require(Shared.Brainrots)
local BrainrotModels = require(Shared.BrainrotModels)
local Economy = require(Shared.Economy)
local State = require(script.Parent.State)
local CarryService = require(script.Parent.CarryService)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)

local PurchaseService = {}

type Offer = { pedestal: BasePart, rarity: string, entryId: string?, display: Model?, prompt: ProximityPrompt }

local offers: { Offer } = {}
local rng = Random.new()

local function rollNewOffer(offer: Offer)
	if offer.display then
		offer.display:Destroy()
	end
	local entry = Brainrots.rollFromRarity(offer.rarity, rng)
	offer.entryId = entry.id
	local display = BrainrotModels.build(entry.id, false, entry.price)
	BrainrotModels.standOn(display, offer.pedestal)
	display.Parent = offer.pedestal
	offer.display = display
	offer.prompt.ActionText = "Buy " .. Economy.formatMoney(entry.price)
	offer.prompt.ObjectText = entry.name
end

function PurchaseService.buyKeeper(player: Player, offer: Offer)
	local entry = offer.entryId and Brainrots.get(offer.entryId)
	if not entry or not PlotService.isWithinReach(player, offer.pedestal) then
		return
	end
	if CarryService.isCarrying(player) then
		Remotes.notify(player, "Hands full - place your keeper first!", Color3.fromRGB(255, 180, 80))
		return
	end
	if not State.spendMoney(player, entry.price) then
		Remotes.notify(player, "Need " .. Economy.formatMoney(entry.price) .. " for " .. entry.name, Color3.fromRGB(255, 90, 90))
		return
	end
	local golden = Economy.rollGoldenMutation(rng)
	CarryService.pickUp(player, { id = entry.id, mutated = golden })
	if golden then
		Remotes.notify(player, "GOLDEN MUTATION! " .. entry.name .. " earns x2!", Brainrots.GOLD)
	else
		Remotes.notify(player, "Caught " .. entry.name .. "! Carry it to your base", Brainrots.rarityColor(entry.rarity))
	end
	Remotes.burstAt(offer.pedestal.Position + Vector3.new(0, 5, 0), if golden then Brainrots.GOLD else Brainrots.rarityColor(entry.rarity))
	rollNewOffer(offer)
end

-- A fresh catch on every pedestal; called each time a surge ebbs.
function PurchaseService.restockAllPedestals()
	for _, offer in offers do
		rollNewOffer(offer)
	end
end

function PurchaseService.start()
	for _, rarity in Brainrots.RarityOrder do
		local pedestal = workspace.Stall.Pedestals:FindFirstChild(rarity)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BuyPrompt"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.Parent = pedestal
		local offer: Offer = { pedestal = pedestal, rarity = rarity, entryId = nil, display = nil, prompt = prompt }
		prompt.Triggered:Connect(function(player)
			PurchaseService.buyKeeper(player, offer)
		end)
		table.insert(offers, offer)
		rollNewOffer(offer)
	end
end

return PurchaseService
