-- Tunable numbers shared by server and client: one place to balance Brainrot Tide Keepers.

local Config = {}

Config.STARTING_MONEY = 100
Config.SLOTS_PER_PLOT = 6
Config.PLOT_COUNT = 4
Config.MAX_INTERACT_DISTANCE = 16 -- studs; the server ignores any prompt fired from farther away

Config.STEAL_HOLD_SECONDS = 2
Config.LOCK_PRICE = 150
Config.LOCK_SECONDS = 40

Config.REBIRTH_COST = 10000
Config.REBIRTH_MULTIPLIER_STEP = 1.5

Config.MUTATION_CHANCE = 0.02 -- per purchase: a Golden keeper earns double
Config.MUTATION_RATE_BONUS = 2

Config.TIDE_DAMAGE_PER_SECOND = 25
Config.HIGH_GROUND_Y = 7 -- feet above this height are safe from a surge

Config.RIVAL_NAMES = { "Barnacle Barry", "Gull Gang Gary", "Captain Soggy", "Mildew Marge" }
Config.RIVAL_RESTOCK_SECONDS = 35

return Config
