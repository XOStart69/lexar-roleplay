local config = require 'casino.insidetrack.config'

---@class IT_ServerHorse
---@field nameKey string?
---@field oddsStr string?
---@field styleIndex integer?

local horseStyles <const> = {
    { 15553363, 5474797, 9858144, 4671302 },
    { 16724530, 3684408, 14807026, 16777215 },
    { 13560920, 15582764, 16770746, 7500402 },
    { 16558591, 5090807, 10446437, 7493977 },
    { 5090807, 16558591, 3815994, 9393493 },
    { 16269415, 16767010, 10329501, 16777215 },
}

local horseDisplayNames <const> = {
    'Durban Poison', 'Sweet Releaf', 'Robocall',
    'Banana Hammock', 'Salty And Woke', 'Wonder Boy',
}

local Horses = {}

---@return IT_Horse[]
function Horses.generate()
    local result = {}
    local usedNames = {}

    for i = 1, 6 do
        local idx
        repeat idx = math.random(0, 99) until not usedNames[idx]
        usedNames[idx] = true

        local nameKey = (idx < 10) and ('ITH_NAME_00' .. idx) or ('ITH_NAME_0' .. idx)
        local r = config.HorseOdds[i]
        local oddsStr = r and (r.min .. '/1') or '2/1'

        result[i] = {
            nameKey = nameKey,
            displayName = horseDisplayNames[i],
            styleIndex = i,
            style = horseStyles[i],
            oddsStr = oddsStr,
        }
    end

    return result
end

---@param serverHorses IT_ServerHorse[]|nil
---@return IT_Horse[]
function Horses.buildClient(serverHorses)
    local out = {}

    for i = 1, 6 do
        local sh = (serverHorses and serverHorses[i]) or {}
        local oddsRange = config.HorseOdds[i]
        local oddsStr = sh.oddsStr or (oddsRange and (oddsRange.min .. '/1') or '2/1')

        out[i] = {
            nameKey = sh.nameKey or ('ITH_NAME_00' .. i),
            oddsStr = oddsStr,
            style = horseStyles[sh.styleIndex or i],
        }
    end

    return out
end

return Horses
