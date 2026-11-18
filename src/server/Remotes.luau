-- Creates the RemoteEvents between server and client. The only one a client may fire is Rebirth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local folder = Instance.new("Folder")
folder.Name = "Remotes"

local function newEvent(name: string): RemoteEvent
	local e = Instance.new("RemoteEvent")
	e.Name = name
	e.Parent = folder
	return e
end

Remotes.Notify = newEvent("Notify") -- server -> client: toast text, colour
Remotes.MoneyPop = newEvent("MoneyPop") -- server -> client: { {slot, amount, keeperModel} } each second
Remotes.Burst = newEvent("Burst") -- server -> all: sparkle burst at a position (buy, place, steal)
Remotes.Rebirth = newEvent("Rebirth") -- client -> server: ask to rebirth

folder.Parent = ReplicatedStorage

function Remotes.notify(player: Player, text: string, color: Color3?)
	Remotes.Notify:FireClient(player, text, color or Color3.new(1, 1, 1))
end

function Remotes.notifyAll(text: string, color: Color3?)
	Remotes.Notify:FireAllClients(text, color or Color3.new(1, 1, 1))
end

function Remotes.burstAt(position: Vector3, color: Color3)
	Remotes.Burst:FireAllClients(position, color)
end

return Remotes
