---@class AreasClient : AreasShared
local areas = {}

---@type table<string, CZone>
local polygons = {}
---@type table<string, true>
local present = {}
---@type fun(key: string, inside: boolean)[]
local listeners = {}

---@param key string
---@param inside boolean
local function report(key, inside)
    present[key] = inside or nil
    TriggerServerEvent('sm_custom:server:area', key, inside)

    for _, listener in ipairs(listeners) do
        listener(key, inside)
    end
end

local function build()
    for _, polygon in pairs(polygons) do
        polygon:remove()
    end

    table.wipe(polygons)
    table.wipe(present)

    for key, group in pairs(modules.zones.data) do
        local shape = group.area

        if type(shape) == 'table' and type(shape.points) == 'table' and #shape.points >= 3 then
            polygons[key] = lib.zones.poly({
                points = shape.points,
                thickness = shape.thickness,
                onEnter = function() report(key, true) end,
                onExit = function() report(key, false) end,
            })
        end
    end
end

---@param listener fun(key: string, inside: boolean)
function areas.watch(listener)
    listeners[#listeners + 1] = listener
end

---@param key string
---@return boolean
function areas.inside(key)
    return present[key] == true
end

build()
modules.zones.watch(build)

return areas
