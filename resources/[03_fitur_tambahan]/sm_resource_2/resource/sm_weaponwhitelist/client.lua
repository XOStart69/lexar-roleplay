local weapons = localmodule 'data.weapons'
local hasAccess = localmodule 'modules.access'

local Wait = Wait

local CHECK_INTERVAL_MS = 1000
local DENIED = 'Kamu tidak bisa menggunakan senjata ini!'

---@type table<number, table>
local rulesByHash = {}
for name, rule in pairs(weapons) do
    rulesByHash[joaat(name)] = rule
end

---@param items string[]
---@return boolean
local function countItems(items)
    local counts = ox_inventory:Search('count', items)
    if type(counts) == 'number' then return counts > 0 end
    for _, count in pairs(counts) do
        if count > 0 then return true end
    end
    return false
end

local watchToken = 0

---@param weapon number
---@param rule table
---@param token number
local function watch(weapon, rule, token)
    while watchToken == token and cache.weapon == weapon do
        if not hasAccess(rule, QBPlayerData.job, countItems) then
            lib.notify({ title = 'Weapon System', description = DENIED, type = 'error', duration = 8000 })
            TriggerEvent('ox_inventory:disarm', true)
            return
        end
        Wait(CHECK_INTERVAL_MS)
    end
end

lib.onCache('weapon', function(weapon)
    watchToken = watchToken + 1
    local rule = weapon and rulesByHash[weapon]
    if not rule then return end

    local token = watchToken
    SetTimeout(500, function()
        watch(weapon, rule, token)
    end)
end)
