# Morrowind Door Randomizer #

## About ##

A Morrowind MWSE-Lua mod to randomize the destinations of cell-change doors. 

I discovered that tes3.setDestination() was a thing, so I wrote this. When
the game is started up, a list of all cells is built. Whenever an unlocked,
cell-change door is activated, its destination cell is randomized, according
to the below configuration values. A list of starting positions is built by
looking through each door in the chosen cell, then in each of those
destination cells, finding doors that return to the original picked cell, and
using its destination position/orientation values. The player's position in
the cell is chosen randomly from that list. If none are found, a default of
(0,0,0) is used for both values.

## Mod configuration menu ##

* Percent chance to randomize doors on activate
* Enable/Disable choosing of Wilderness cells
* Enable/Disable choosing of cells without a door to place the player at
    * With this enabled, if no starting positions are found in a cell, a new
    cell will be chosen.
* Choose only:
    * Interior cells
    * Exterior cells
    * Both
    * Match destination cell
* Ignore list for cells
* Ignore list for doors
* Debug logging, to see my cool recursive functions at work

## Interop Module ##

For modders, an interop module is included. Use it like so:

```Lua

local interop = require("celediel.DoorRandomizer.interop") -- the module

local chance = interop.getRandomizeChance() -- get global randomize chance
interop.setRandomizeChance(chance + 25) -- set global randomize chance

-- https://mwse.readthedocs.io/en/latest/lua/type/tes3door.html
local door -- a tes3door references

interop.randomizeDoor(door, 100) -- overrides randomize chance for this one door
interop.unRandomizeDoor(door) -- removes overrides
```

## Requirements ##
MWSE 2.1 nightly @ [github](https://github.com/MWSE/MWSE)

## Credits ##

* MWSE Team for MWSE with Lua support
* Morrowind Modding Discord as always, for essentially being the MWSE docs

## License ##

MIT License. See LICENSE file.
