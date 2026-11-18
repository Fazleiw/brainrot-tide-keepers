-- Tide surge timing and water levels. The server drives the cycle; the client reads it to count down.

local Tide = {}

Tide.CALM_SECONDS = 65
Tide.WARNING_SECONDS = 10
Tide.SURGE_SECONDS = 15
Tide.CYCLE_SECONDS = Tide.CALM_SECONDS + Tide.WARNING_SECONDS + Tide.SURGE_SECONDS -- 90

Tide.LOW_TOP_Y = -1.5 -- water surface when calm (just under the market floor at y=0)
Tide.SURGE_TOP_Y = 4.5 -- water surface at the height of a surge (high ground is y=8)
Tide.RISE_SECONDS = 3

Tide.Phase = { Calm = "Calm", Warning = "Warning", Surge = "Surge" }

function Tide.nextPhase(phase: string): (string, number)
	if phase == Tide.Phase.Calm then
		return Tide.Phase.Warning, Tide.WARNING_SECONDS
	elseif phase == Tide.Phase.Warning then
		return Tide.Phase.Surge, Tide.SURGE_SECONDS
	end
	return Tide.Phase.Calm, Tide.CALM_SECONDS
end

function Tide.isSubmerged(feetY: number, waterTopY: number, highGroundY: number): boolean
	return feetY < waterTopY and feetY < highGroundY
end

return Tide
