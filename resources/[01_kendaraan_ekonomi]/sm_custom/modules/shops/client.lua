local config = require 'config.client'

---@class ShopsClient
local shops = {}

---@type table<string, boolean>
local access = {}
---@type CustomZone?
local current
---@type string | false
local prompt = false
---@type CPoint[]
local points = {}
---@type integer[]
local blips = {}
---@type fun(zone: CustomZone)
local opener
---@type fun(): boolean
local idle

---@param text string | false
local function show(text)
    if text == prompt then return end

    prompt = text

    if text then lib.showTextUI(text) else lib.hideTextUI() end
end

---@return CustomZone?
function shops.current()
    return current
end

---@param id string
---@return boolean
function shops.access(id)
    return access[id] == true
end

local function clear()
    for _, point in ipairs(points) do
        point:remove()
    end

    for _, handle in ipairs(blips) do
        RemoveBlip(handle)
    end

    table.wipe(points)
    table.wipe(blips)
    table.wipe(access)

    if current then
        current = nil
        show(false)
    end
end

---@param zone CustomZone
local function watch(zone)
    local point = lib.points.new({ coords = zone.coords, distance = config.zones.distance })

    function point:onEnter()
        lib.callback('sm_custom:server:access', false, function(allowed)
            access[zone.id] = allowed == true
        end, zone.id)
    end

    function point:onExit()
        access[zone.id] = nil

        if current == zone then
            current = nil
            show(false)
        end
    end

    function point:nearby()
        if not access[zone.id] then return end

        local inside = self.currentDistance <= zone.radius and cache.vehicle and cache.seat == -1 and idle()

        if not inside then
            if current == zone then
                current = nil
                show(false)
            end

            return
        end

        local claim = modules.receipt.pending(zone)

        current = zone
        show(claim and locale('receipt.register') or ('[E] %s'):format(zone.label))
        DisableControlAction(0, 86, true)

        if IsControlJustReleased(0, 38) then
            show(false)
            CreateThread(function()
                if claim then modules.receipt.register(claim, zone) else opener(zone) end
            end)
        end
    end

    points[#points + 1] = point
end

local function build()
    clear()

    for _, blip in ipairs(modules.zones.blips) do
        local handle = AddBlipForCoord(blip.coords.x, blip.coords.y, blip.coords.z)

        SetBlipSprite(handle, blip.sprite or 446)
        SetBlipColour(handle, blip.colour or 0)
        SetBlipScale(handle, blip.scale or 0.8)
        SetBlipAsShortRange(handle, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(blip.label)
        EndTextCommandSetBlipName(handle)

        blips[#blips + 1] = handle
    end

    for _, zone in ipairs(modules.zones.list) do
        watch(zone)
    end
end

---@param open fun(zone: CustomZone)
---@param ready fun(): boolean
function shops.start(open, ready)
    opener, idle = open, ready

    build()
    modules.zones.watch(build)
end

return shops
