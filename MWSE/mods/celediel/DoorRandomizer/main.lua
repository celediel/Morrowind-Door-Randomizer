-- pick a destination cell at random when activating a door
local common = require("celediel.DoorRandomizer.common")
local config = require("celediel.DoorRandomizer.config").getConfig()

local cells = {}

-- the door's original destination
local ogDestination

-- {{{ helper functions
local function log(...) if config.debug then mwse.log("[%s] %s", common.modName, string.format(...)) end end

local function isZero(spot)
    return spot.position.x == 0 and
           spot.position.y == 0 and
           spot.position.z == 0 and
           spot.orientation.x == 0 and
           spot.orientation.y == 0 and
           spot.orientation.z == 0
end

local function isTypeMatch(ogCell, chosenCell)
    return ((ogCell.isInterior and ogCell.behavesAsExterior) or not ogCell.isInterior) ==
           ((chosenCell.isInterior and chosenCell.behavesAsExterior) or not chosenCell.isInterior)
end
-- }}}

-- {{{ cell and position/orientation picking
local function pickSpot(cell)
    -- this will be the position/orientation destination of every door that puts the player into the above chosen cell
    local spots = {}
    local spot

    -- peek through doors in that cell to pick a position/orientation for the player
    for cellDoor in cell:iterateReferences(tes3.objectType.door) do
        if cellDoor.destination then -- only cell change doors
            -- loop through doors in THAT cell to find the door that led us there in the first place
            log("Looking through door %s in %s leading to %s",
                cellDoor.name or cellDoor.id, cell.id, cellDoor.destination.cell.id)
            for innerDoor in cellDoor.destination.cell:iterateReferences(tes3.objectType.door) do
                if innerDoor.destination and innerDoor.destination.cell.id == cell.id then
                    -- found the door, now add where that door puts a player to our table
                    log("Found a door in %s leading to %s with starting position:%s and orientation:%s",
                        cellDoor.destination.cell.id, innerDoor.destination.cell.id,
                        innerDoor.destination.marker.position, innerDoor.destination.marker.orientation)
                    -- comment this out and set config.needDoor = true to cause infinite recursion
                    table.insert(spots, {
                        position = innerDoor.destination.marker.position,
                        orientation = innerDoor.destination.marker.orientation
                    })
                end
            end
        end
    end

    if #spots > 0 then
        log("There %s %s spot%s in %s", #spots > 1 and "were" or "was", #spots, #spots > 1 and "s" or "", cell.id)
        spot = table.choice(spots)
    else
        -- if we don't find any then use 0,0,0, which can be really bad in some cells
        spot = {position = tes3vector3.new(0, 0, 0), orientation = tes3vector3.new(0, 0, 0)}
    end

    return spot
end

local function pickCell(ogDest)
    local picked = table.choice(cells)
    local cell = tes3.getCell({id = picked})

    if config.ignoredCells[cell.id] then
        log("%s is ignored cell, trying again...", cell.id)
        cell = pickCell(ogDest)
    end

    if not config.wildernessCells and not cell.name then
        log("%s is wilderness, trying again...", cell.id)
        cell = pickCell(ogDest)
    end

    if config.interiorExterior == common.cellTypes.exterior and cell.isInterior and not cell.behavesAsExterior then
        log("%s is interior, trying again...", cell.id)
        cell = pickCell(ogDest)
    elseif config.interiorExterior == common.cellTypes.interior and (not cell.isInterior or cell.behavesAsExterior) then
        log("%s is exterior, trying again...", cell.id)
        cell = pickCell(ogDest)
    elseif config.interiorExterior == common.cellTypes.match and not isTypeMatch(ogDest, cell) then
        log("%s and %s are not same cell type, trying again...", ogDest.id, cell.id)
        cell = pickCell(ogDest)
    end

    return cell
end

local function pickCellAndSpot(ogDest)
    local cell = pickCell(ogDest)
    log("Finally settled on %s, now picking position/orientation", cell.id)

    local spot = pickSpot(cell)

    if config.needDoor and isZero(spot) then
        log("No good door positions in %s, starting over!", cell.id)
        cell, spot = pickCellAndSpot(ogDest)
    end

    return cell, spot
end
-- }}}

-- {{{ event functions
local function onActivate(e)
    -- only do stuff on cell change doors
    if e.activator ~= tes3.player and e.target.objectType ~= tes3.objectType.door then return end

    local door = e.target

    if config.ignoredDoors[string.lower(door.id)] then
        log("Ignored door, not randomizing.")
        return
    end

    -- don't randomize locked doors, or: only randomize when a cell change event happens
    if door.destination and not tes3.getLocked({reference = door}) then
        local roll = math.random(0, 100)
        local rollStr = "Randomize Roll: %s "
        if config.randomizeChance < roll then
            log(rollStr .. "> %s, not randomizing", roll, config.randomizeChance)
            return
        end

        log(rollStr .. "< %s, randomizing!", roll, config.randomizeChance)

        log("Picking initial cell...")
        local cell, spot = pickCellAndSpot(door.destination.cell)

        log("Picked %s at (%s) facing (%s)", cell.id, spot.position, spot.orientation)

        -- store the original destination so that we can reset it later
        if not config.keepRandomized and not ogDestination then
            ogDestination = {
                door = door,
                cell = door.destination.cell,
                position = door.destination.marker.position,
                orientation = door.destination.marker.orientation
            }
        end

        -- set the door's destination to the picked cell and position/orientation
        tes3.setDestination({reference = door, cell = cell, position = spot.position, orientation = spot.orientation})
    end
end

local function onCellChanged(e)
    if not config.keepRandomized and ogDestination then
        log("Resetting door to original destination")

        -- it's later
        tes3.setDestination({
            reference = ogDestination.door,
            cell = ogDestination.cell,
            position = ogDestination.position,
            orientation = ogDestination.orientation
        })

        timer.delayOneFrame(function() ogDestination = nil end)
    end
end

local function onInitialized(e)
    for cell, _ in pairs(tes3.dataHandler.nonDynamicData.cells) do table.insert(cells, cell) end

    log("found %s cells", #cells)

    event.register("activate", onActivate)
    event.register("cellChanged", onCellChanged)
end
-- }}}

event.register("initialized", onInitialized)
event.register("modConfigReady", function() mwse.mcm.register(require("celediel.DoorRandomizer.mcm")) end)

-- vim:fdm=marker
