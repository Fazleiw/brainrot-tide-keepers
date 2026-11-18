-- Carrying: the keeper a player holds rides welded above their head until it is placed, stolen back or drowned.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local BrainrotModels = require(Shared.BrainrotModels)
local State = require(script.Parent.State)

local CarryService = {}

local carriedModels: { [Player]: Model } = {}

local function destroyCarriedModel(player: Player)
	if carriedModels[player] then
		carriedModels[player]:Destroy()
		carriedModels[player] = nil
	end
end

function CarryService.pickUp(player: Player, keeper: State.Keeper)
	destroyCarriedModel(player)
	State.setCarrying(player, keeper)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local model = BrainrotModels.build(keeper.id, keeper.mutated)
	model.Name = "Carried_" .. keeper.id
	model.PrimaryPart.KeeperLabel:Destroy() -- the HUD's carry bar names it; a second floating tag would only clutter
	model:ScaleTo(model:GetScale() * 0.7)
	model:PivotTo(head.CFrame * CFrame.new(0, 1, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = model.PrimaryPart
	weld.Parent = model.PrimaryPart
	model.Parent = character
	carriedModels[player] = model
end

-- Ends the carry and returns what was carried (nil if nothing).
function CarryService.release(player: Player): State.Keeper?
	local s = State.get(player)
	local keeper = s and s.carrying
	destroyCarriedModel(player)
	State.setCarrying(player, nil)
	return keeper
end

function CarryService.isCarrying(player: Player): boolean
	local s = State.get(player)
	return s ~= nil and s.carrying ~= nil
end

-- A respawn loses the carried model with the old character; rebuild it on the new one.
function CarryService.restoreAfterRespawn(player: Player)
	local s = State.get(player)
	if s and s.carrying then
		CarryService.pickUp(player, s.carrying)
	end
end

return CarryService
