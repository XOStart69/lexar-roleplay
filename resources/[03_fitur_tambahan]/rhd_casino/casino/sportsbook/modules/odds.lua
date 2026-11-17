local Odds = {}

---@param value number
---@return number
local function round2(value)
    return math.floor(value * 100 + 0.5) / 100
end

Odds.round2 = round2

---Fair odds tanpa house edge.
---@param probability number persen 0-100
---@return number
function Odds.fair(probability)
    local p = tonumber(probability) or 0
    if p <= 0 then return 0 end
    return round2(100 / p)
end

---Fixed odds = 1 / (probabilitas * (1 + house edge)).
---@param probability number persen 0-100
---@param houseEdge number persen
---@return number
function Odds.fixed(probability, houseEdge)
    local p = (tonumber(probability) or 0) / 100
    local edge = (tonumber(houseEdge) or 0) / 100
    if p <= 0 then return 0 end
    return round2(1 / (p * (1 + edge)))
end

---@param stake number
---@param odds number
---@return integer
function Odds.potentialReturn(stake, odds)
    local value = (tonumber(stake) or 0) * (tonumber(odds) or 0)
    if value <= 0 then return 0 end
    return math.floor(value)
end

return Odds
