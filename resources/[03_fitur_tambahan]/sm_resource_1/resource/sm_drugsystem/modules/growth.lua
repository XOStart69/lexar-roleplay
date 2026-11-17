local config = localmodule 'config.shared'

local STAGE_SHARES = { 20 / 160, 40 / 160, 50 / 160, 50 / 160 }

local Growth = {}

---@param lamp? boolean
---@return number
function Growth.rate(lamp)
    return 1 / (lamp and config.grow.lampSeconds or config.grow.seconds)
end

---@param from number
---@param since number
---@param lamp? boolean
---@param now number
---@return number
function Growth.progress(from, since, lamp, now)
    return math.min(1, from + (now - since) * Growth.rate(lamp))
end

---@param progress number
---@return integer stage
---@return number share
function Growth.stage(progress)
    if progress >= 1 then return 4, 1 end

    for i = 1, #STAGE_SHARES do
        local share = STAGE_SHARES[i]

        if progress < share then
            return i - 1, progress / share
        end

        progress -= share
    end

    return 3, 1
end

return Growth
