local common = require("celediel.DoorRandomizer.common")

local defaultConfig = {
    randomizeChance = 50,
    interiorExterior = common.cellTypes.both,
    wildernessCells = true,
    needDoor = true,
    debug = false,
    ignoredCells = {},
}

local currentConfig

local this = {}

function this.getConfig()
    currentConfig = currentConfig or mwse.loadConfig(common.configPath, defaultConfig)
    return currentConfig
end

return this
