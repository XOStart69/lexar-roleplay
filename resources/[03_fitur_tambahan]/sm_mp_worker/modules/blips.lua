local blipUtils = {}

if lib.context ~= 'client' then return blipUtils end

---@class BlipConfig
---@field sprite? number default 1
---@field color? number default 0
---@field scale? number default 1.0
---@field display? number default 4
---@field name? string
---@field shortRange? boolean default true
---@field route? boolean default false
---@field routeColor? number default 0
---@field alpha? number

---@class BlipCoords: BlipConfig
---@field coords vector3 | { x: number, y: number, z: number }

---@class BlipEntity: BlipConfig
---@field entity number

local function setBlipConfig(blip, options)
    SetBlipSprite(blip, options.sprite or 1)
    SetBlipColour(blip, options.color or 0)
    SetBlipScale(blip, options.scale or 1.0)
    SetBlipDisplay(blip, options.display or 4)
    SetBlipAsShortRange(blip, options.shortRange ~= false)
    SetBlipAlpha(blip, options.alpha or 255)

    if options.name then
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(options.name)
        EndTextCommandSetBlipName(blip)
    end

    if options.route then
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, options.routeColor or 0)
    end
end

---@class BlipManager
---@overload fun(data: BlipCoords): number
---@field entity fun(data: BlipEntity): number
---@field radius fun(data: BlipRadius): number
blipUtils.create = setmetatable({}, {
    __call = function(_, data)
        local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z or 0.0)
        setBlipConfig(blip, data)
        return blip
    end
})

function blipUtils.create.entity(data)
    local blip = AddBlipForEntity(data.entity)
    setBlipConfig(blip, data)
    return blip
end

---@class BlipRadius
---@field coords vector3 | { x: number, y: number, z: number }
---@field radius number
---@field color? number default 0
---@field alpha? number

---@param data BlipRadius
---@return number blip
function blipUtils.create.radius(data)
    local blip = AddBlipForRadius(data.coords.x, data.coords.y, data.coords.z or 0.0, data.radius)
    SetBlipColour(blip, data.color or 0)
    if data.alpha then
        SetBlipAlpha(blip, data.alpha)
    end
    return blip
end

function blipUtils.setWaypoint(coords)
    if not coords then return end
    SetNewWaypoint(coords.x, coords.y)
end

function blipUtils.clearWaypoint()
    if IsWaypointActive() then
        SetWaypointOff()
    end
end

---@param blip? number
function blipUtils.remove(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end

---@param blips number[]|table<any, number>
function blipUtils.removeAll(blips)
    if type(blips) ~= 'table' then return end
    for k, blip in pairs(blips) do
        if type(blip) == 'number' and DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
        blips[k] = nil
    end
end

return blipUtils
