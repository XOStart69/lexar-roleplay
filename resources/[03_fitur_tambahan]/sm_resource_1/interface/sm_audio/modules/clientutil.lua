local GetGameTimer = GetGameTimer
local StartShapeTestCapsule = StartShapeTestCapsule
local GetShapeTestResult = GetShapeTestResult
local IsEntityAVehicle = IsEntityAVehicle

local Util = {}

local notifyIcons = {
    error = 'ban',
    success = 'check',
}

local notifyColors = {
    error = '#C53030',
    success = '#019430',
}

local lastInteraction = 0

---@param message string
---@param kind? string
function Util.notify(message, kind)
    kind = kind or 'info'

    lib.notify({
        title = ('%s!'):format(kind:gsub('^%l', string.upper)),
        description = message,
        type = kind,
        icon = notifyIcons[kind],
        iconColor = notifyColors[kind],
    })
end

---@return boolean
function Util.interactionCheck()
    local now = GetGameTimer()

    if now - lastInteraction <= 2000 then
        Util.notify(locale('Please wait a little.'), 'info')
        return false
    end

    lastInteraction = now
    return true
end

---@param x number
---@param y number
---@param z number
---@param radius? number
---@return number|false
function Util.getNearestVehicle(x, y, z, radius)
    if not (x and y and z) then
        return false
    end

    local handle = StartShapeTestCapsule(x, y, z, x, y, z, radius or 2.0, 10, cache.ped, 7)
    local _, hit, _, _, entity = GetShapeTestResult(handle)

    if hit == 1 and entity and IsEntityAVehicle(entity) then
        return entity
    end

    return false
end

return Util
