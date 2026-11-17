local mods = lib.load('data.menu.mods')

local INHERIT <const> = { 'label', 'radius', 'groups', 'menu', 'society', 'billing', 'install' }
local BOOTH_MENU <const> = { 'paint', 'wheelColor', 'interiorColor', 'dashboardColor' }
local ALIASES <const> = { paint = { 'color1', 'paintType1', 'color2', 'paintType2', 'pearlescentColor' } }
local NONE <const> = {}

---@class CustomRack
---@field coords vector3
---@field parts string[]

---@class CustomZoneRack
---@field coords vector3
---@field stock table<string, true>

---@class CustomZone
---@field id string
---@field key string
---@field label string
---@field coords vector3
---@field radius number
---@field groups? table<string, integer>
---@field menu? string[]
---@field allow? table<string, true>
---@field society? string
---@field billing boolean
---@field install boolean
---@field racks CustomZoneRack[]
---@field admin? boolean
---@field booth? string
---@field selfservice? boolean
---@field grades? table<integer, true>

---@class CustomZoneBlip
---@field sprite integer
---@field colour integer
---@field scale number
---@field coords? vector3
---@field label? string

---@class CustomBlip
---@field coords vector3
---@field sprite integer
---@field colour integer
---@field scale number
---@field label string

---@class CustomNozzle
---@field coords vector3
---@field rotation vector3

---@class CustomBooth
---@field id string
---@field key string
---@field label string
---@field groups? table<string, integer>
---@field society? string
---@field billing boolean
---@field mode 'screen' | 'menu'
---@field vehicle vector4
---@field screen? vector4
---@field nozzles CustomNozzle[]

---@class ZonesShared
local zones = {
    ALIASES = ALIASES,
    ---@type CustomZone[]
    list = {},
    ---@type CustomBlip[]
    blips = {},
    ---@type CustomBooth[]
    booths = {},
    ---@type table<string, table>
    data = {},
    ---@type CustomZone
    admin = {
        id = 'admin',
        key = 'admin',
        label = 'Admin',
        coords = vec3(0.0, 0.0, 0.0),
        radius = 0.0,
        billing = false,
        install = false,
        racks = {},
        admin = true,
    },
}

---@type table<string, CustomZone>
local byId = {}
---@type table<string, CustomBooth>
local byBooth = {}
---@type fun()[]
local watchers = {}
---@type table<string, string>
local aliasOf = {}

for alias, keys in pairs(ALIASES) do
    for _, key in ipairs(keys) do
        aliasOf[key] = alias
    end
end

local owners = {
    modTurbo = { 'modTurbo', 'performance' },
    engineSound = { 'engineSound', 'performance' },
    nitrousFlame = { 'nitrousFlame', 'nitrous', 'performance' },
    nitrousPurge = { 'nitrousPurge', 'nitrous', 'performance' },
    color1 = { 'primary', 'paint' },
    paintType1 = { 'primary', 'paint' },
    color2 = { 'secondary', 'paint' },
    paintType2 = { 'secondary', 'paint' },
    pearlescentColor = { 'pearlescent', 'paint' },
    wheels = { 'wheelTypes', 'wheels' },
    modFrontWheels = { 'wheelTypes', 'wheels' },
    modBackWheels = { 'wheelTypes', 'wheels' },
    modCustomTiresF = { 'tires', 'wheels' },
    modCustomTiresR = { 'tires', 'wheels' },
    wheelColor = { 'wheelColor', 'wheels' },
    modSmokeEnabled = { 'smokeState', 'smokeColor', 'smoke', 'wheels' },
    tyreSmokeColor = { 'smokeColor', 'smoke', 'wheels' },
    fitment = { 'fitment', 'wheels' },
    modXenon = { 'xenon', 'lights' },
    xenonColor = { 'xenon', 'lights' },
    neonEnabled = { 'neonLayout', 'lights' },
    neonColor = { 'neonColor', 'lights' },
    interiorColor = { 'interiorColor', 'interior' },
    dashboardColor = { 'dashboardColor', 'interior' },
    windowTint = { 'windowTint', 'extra' },
    plateIndex = { 'plateIndex', 'extra' },
    livery = { 'livery', 'extra' },
    modRoofLivery = { 'roofLivery', 'extra' },
    extras = { 'extras', 'extra' },
}

for _, mod in ipairs(mods) do
    owners[mod.key] = { mod.key, mod.menu }
end

---@param list string[]
---@return table<string, true>
local function set(list)
    local result = {}

    for _, id in ipairs(list) do
        result[id] = true
    end

    return result
end

---@param coords vector3
---@return string
local function spot(coords)
    return ('%.2f:%.2f:%.2f'):format(coords.x, coords.y, coords.z)
end

---@param ... CustomRack[]
---@return CustomZoneRack[]
local function stock(...)
    local list, byKey = {}, {}

    for i = 1, select('#', ...) do
        for _, rack in ipairs((select(i, ...))) do
            if type(rack.coords) == 'vector3' and type(rack.parts) == 'table' then
                local key = spot(rack.coords)
                local entry = byKey[key]

                if not entry then
                    entry = { coords = rack.coords, stock = {} }
                    byKey[key] = entry
                    list[#list + 1] = entry
                end

                for _, part in ipairs(rack.parts) do
                    entry.stock[part] = true

                    for _, key in ipairs(ALIASES[part] or NONE) do
                        entry.stock[key] = true
                    end
                end
            end
        end
    end

    return list
end

---@param blips CustomBlip[]
---@param blip CustomZoneBlip
---@param coords vector3
---@param label string
local function addBlip(blips, blip, coords, label)
    blips[#blips + 1] = {
        coords = coords,
        sprite = blip.sprite,
        colour = blip.colour,
        scale = blip.scale,
        label = blip.label or label,
    }
end

---@param key string
---@param group table
---@param list CustomZone[]
---@param blips CustomBlip[]
local function locations(key, group, list, blips)
    local blip = group.blip --[[@as CustomZoneBlip?]]
    local shared = zones.racks(group)

    for index, location in ipairs(group) do
        local zone = { id = ('%s:%d'):format(key, index), key = key, coords = location.coords } --[[@as table]]

        for _, field in ipairs(INHERIT) do
            local value = location[field]
            if value == nil then value = group[field] end

            zone[field] = value
        end

        zone.label = zone.label or key
        zone.radius = zone.radius or 3.0
        zone.racks = stock(zones.racks(location), shared)
        zone.allow = zone.menu and set(zone.menu)

        if zone.billing == nil then zone.billing = zone.groups ~= nil end
        if zone.install == nil then zone.install = zone.groups ~= nil and #zone.racks > 0 end

        zone.selfservice = location.selfservice == true
        zone.grades = type(location.grades) == 'table' and #location.grades > 0 and set(location.grades) or nil

        list[#list + 1] = zone
        byId[zone.id] = zone

        if blip and not blip.coords then
            addBlip(blips, blip, zone.coords, zone.label)
        end
    end

    if blip and blip.coords then
        addBlip(blips, blip, blip.coords, group.label or key)
    end
end

---@param booth CustomBooth
---@param group table
---@return CustomZone
local function counter(booth, group)
    return {
        id = booth.id,
        key = booth.key,
        label = booth.label,
        coords = booth.vehicle.xyz,
        radius = group.radius or 3.0,
        groups = booth.groups,
        menu = BOOTH_MENU,
        allow = set(BOOTH_MENU),
        society = booth.society,
        billing = booth.billing,
        install = false,
        racks = {},
        booth = booth.id,
    }
end

---@param key string
---@param group table
---@param booths CustomBooth[]
---@param list CustomZone[]
local function stations(key, group, booths, list)
    for index, booth in ipairs(group.booths or {}) do
        local mode = booth.mode == 'menu' and 'menu' or 'screen'
        local ready = type(booth.vehicle) == 'vector4' and (mode == 'menu' or type(booth.screen) == 'vector4')

        if ready then
            local entry = {
                id = ('%s:booth:%d'):format(key, index),
                key = key,
                label = booth.label or group.label or key,
                groups = group.groups,
                society = group.society,
                billing = group.billing == nil and group.groups ~= nil or group.billing == true,
                mode = mode,
                vehicle = booth.vehicle,
                screen = mode == 'screen' and booth.screen or nil,
                nozzles = booth.nozzles or {},
            }

            booths[#booths + 1] = entry
            byBooth[entry.id] = entry

            if mode == 'menu' then
                local zone = counter(entry, group)

                list[#list + 1] = zone
                byId[zone.id] = zone
            end
        end
    end
end

---@param data table<string, table>
function zones.load(data)
    local list, blips, booths = {}, {}, {}

    table.wipe(byId)
    table.wipe(byBooth)
    byId.admin = zones.admin

    for key, group in pairs(data) do
        locations(key, group, list, blips)
        stations(key, group, booths, list)
    end

    zones.data, zones.list, zones.blips, zones.booths = data, list, blips, booths

    for _, watcher in ipairs(watchers) do
        watcher()
    end
end

---@param watcher fun()
function zones.watch(watcher)
    watchers[#watchers + 1] = watcher
end

---@param value any
---@return any
function zones.encode(value)
    local kind = type(value)

    if kind == 'vector3' then return { x = value.x, y = value.y, z = value.z } end
    if kind == 'vector4' then return { x = value.x, y = value.y, z = value.z, w = value.w } end
    if kind ~= 'table' then return value end

    local result = {}

    for key, item in pairs(value) do
        result[key] = zones.encode(item)
    end

    return result
end

---@param value any
---@return any
function zones.decode(value)
    if type(value) ~= 'table' then return value end

    local x, y, z, w = value.x, value.y, value.z, value.w

    if type(x) == 'number' and type(y) == 'number' and type(z) == 'number' then
        return type(w) == 'number' and vec4(x, y, z, w) or vec3(x, y, z)
    end

    local result = {}

    for key, item in pairs(value) do
        result[key] = zones.decode(item)
    end

    return result
end

---@param id any
---@return CustomZone?
function zones.get(id)
    return type(id) == 'string' and byId[id] or nil
end

---@param id any
---@return CustomBooth?
function zones.booth(id)
    return type(id) == 'string' and byBooth[id] or nil
end

---@param zone CustomZone
---@param coords vector3
---@param slack? number
---@return boolean
function zones.inside(zone, coords, slack)
    local offset = coords - zone.coords

    return #offset.xy <= zone.radius + (slack or 0.0) and math.abs(offset.z) <= 4.0
end

---@param zone CustomZone | CustomBooth
---@param job? CachedJob
---@param duty? boolean
---@return boolean
function zones.member(zone, job, duty)
    local groups = zone.groups
    if not groups then return true end
    if not job then return false end

    local grade = groups[job.name]
    if type(grade) ~= 'number' or (duty and not job.onduty) then return false end

    local allowed = zone.grades
    if allowed and not allowed[job.grade] then return false end

    return job.grade >= grade
end

---@param zone CustomZone
---@param patch table
---@return boolean
function zones.permits(zone, patch)
    local allow = zone.allow
    if not allow then return true end

    for key in pairs(patch) do
        local ids = owners[key]
        local found = key == 'repair' or key == 'clean'

        for i = 1, ids and #ids or 0 do
            if allow[ids[i]] then
                found = true
                break
            end
        end

        if not found then return false end
    end

    return true
end

---@param source table
---@return CustomRack[]
function zones.racks(source)
    if type(source.racks) == 'table' then return source.racks end

    local parts = source.parts
    if type(parts) ~= 'table' then return {} end

    local list = {}

    if parts[1] then
        for i, coords in ipairs(parts) do
            list[i] = { coords = coords, parts = { 'default' } }
        end

        return list
    end

    local names, byKey = {}, {}

    for name in pairs(parts) do
        names[#names + 1] = name
    end

    table.sort(names)

    for _, name in ipairs(names) do
        for _, coords in ipairs(parts[name]) do
            local key = spot(coords)
            local rack = byKey[key]

            if not rack then
                rack = { coords = coords, parts = {} }
                byKey[key] = rack
                list[#list + 1] = rack
            end

            rack.parts[#rack.parts + 1] = name
        end
    end

    for _, rack in ipairs(list) do
        rack.parts = zones.collapse(rack.parts)
    end

    return list
end

---@param parts string[]
---@return string[]
function zones.collapse(parts)
    local result, seen = {}, {}

    for _, part in ipairs(parts) do
        local id = aliasOf[part] or part

        if not seen[id] then
            seen[id] = true
            result[#result + 1] = id
        end
    end

    return result
end

---@param zone CustomZone
---@param keys string[]
---@return vector3[]
function zones.pickups(zone, keys)
    local exact, fallback, all = {}, {}, {}

    for _, rack in ipairs(zone.racks) do
        all[#all + 1] = rack.coords

        if rack.stock.default then fallback[#fallback + 1] = rack.coords end

        for i = 1, #keys do
            if rack.stock[keys[i]] then
                exact[#exact + 1] = rack.coords
                break
            end
        end
    end

    if #exact > 0 then return exact end
    if #fallback > 0 then return fallback end

    return all
end

---@param zone CustomZone
---@param id string
---@return boolean
function zones.shows(zone, id)
    local allow = zone.allow

    return not allow or allow[id] == true or (allow.extras == true and id:find('^extra_%d') ~= nil)
end

zones.load(lib.load(GetConvarBool('sm_custom:devmode', false) and 'data.zones_dev' or 'data.zones') or {})

return zones
