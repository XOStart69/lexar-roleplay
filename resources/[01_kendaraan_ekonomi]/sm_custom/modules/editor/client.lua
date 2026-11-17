local booth = lib.load('data.booth')

local REPLY_TIMEOUT <const> = 10000
local TELEPORT_TIMEOUT <const> = 5000
local EDGE <const> = 0.5
local AREA_HEIGHT <const> = 10.0
local BOUNDARY <const> = { 0, 255, 247, 200 }
local MENUS <const> = {
    { id = 'performance', label = locale('menu.performance'), children = {} },
    { id = 'body', label = locale('menu.body'), children = {} },
    {
        id = 'wheels',
        label = locale('menu.wheels'),
        children = {
            { id = 'wheelTypes', label = locale('menu.wheel_type') },
            { id = 'tires', label = locale('menu.tires') },
            { id = 'wheelColor', label = locale('menu.wheel_color') },
            { id = 'smoke', label = locale('menu.tyre_smoke') },
            { id = 'fitment', label = locale('menu.fitment') },
        },
    },
    {
        id = 'paint',
        label = locale('menu.paint'),
        children = {
            { id = 'primary', label = locale('menu.primary') },
            { id = 'secondary', label = locale('menu.secondary') },
            { id = 'pearlescent', label = locale('menu.pearlescent') },
        },
    },
    {
        id = 'lights',
        label = locale('menu.lights'),
        children = {
            { id = 'xenon', label = locale('menu.xenon') },
            { id = 'neonLayout', label = locale('menu.neon') },
            { id = 'neonColor', label = locale('menu.neon_color') },
        },
    },
    { id = 'interior', label = locale('menu.interior'), children = {} },
    {
        id = 'extra',
        label = locale('menu.other'),
        children = {
            { id = 'windowTint', label = locale('menu.window_tint') },
            { id = 'plateIndex', label = locale('menu.plate') },
            { id = 'livery', label = locale('menu.livery') },
            { id = 'roofLivery', label = locale('menu.roof_livery') },
            { id = 'extras', label = locale('menu.extra') },
        },
    },
}
local RACK <const> = { r = 255, g = 170, b = 0, a = 200 }
local TETHER <const> = { 255, 170, 0, 120 }
local SCREEN <const> = { r = 255, g = 255, b = 255, a = 200 }
local NOZZLE <const> = { r = 255, g = 60, b = 60, a = 200 }
local CARRIED <const> = {
    hei_prop_heist_box = 'editor.carry_box',
    prop_wheel_rim_01 = 'editor.carry_rim',
    xs_prop_arena_lights_tube_l_a = 'editor.carry_tube',
    p_num_plate_01 = 'editor.carry_plate',
    prop_cs_spray_can = 'editor.carry_can',
    imp_prop_impexp_exhaust_06 = 'editor.carry_exhaust',
    prop_car_bonnet_02 = 'editor.carry_hood',
}
local FITTED <const> = {
    front = 'editor.at_front',
    ['front-left'] = 'editor.at_front',
    ['front-right'] = 'editor.at_front',
    rear = 'editor.at_rear',
    left = 'editor.at_side',
    right = 'editor.at_side',
    door = 'editor.at_cabin',
    engine = 'editor.at_engine',
}
local RENAMED <const> = {
    wheelColor = 'editor.part_wheel_paint',
    interiorColor = 'editor.part_interior_paint',
    dashboardColor = 'editor.part_dashboard_paint',
}
local PLACE <const> = {
    point = { kind = 'point' },
    vehicle = { kind = 'vehicle', model = booth.preview },
    screen = { kind = 'object', model = booth.screen.model, gizmo = true },
    nozzle = { kind = 'object', model = booth.nozzle.model, tilt = true, gizmo = true, effect = booth.nozzle },
}

local sections = {}

for _, menu in ipairs(MENUS) do
    sections[menu.id] = menu.children
end

for _, mod in ipairs(lib.load('data.menu.mods')) do
    local list = sections[mod.menu]

    list[#list + 1] = { id = mod.key, label = mod.label }
end

table.insert(sections.performance, { id = 'modTurbo', label = locale('menu.turbo') })
table.insert(sections.performance, { id = 'engineSound', label = locale('menu.engine_swap') })
table.insert(sections.performance, { id = 'nitrous', label = locale('menu.nitrous') })
table.insert(sections.interior, { id = 'interiorColor', label = locale('menu.interior_color') })
table.insert(sections.interior, { id = 'dashboardColor', label = locale('menu.dashboard_color') })

local PRICES <const> = {
    { id = 'performance', label = locale('menu.performance'), items = {} },
    { id = 'body', label = locale('menu.body'), items = {} },
    {
        id = 'wheels',
        label = locale('menu.wheels'),
        items = {
            { key = 'wheels', label = locale('menu.wheel_type') },
            { key = 'modFrontWheels', label = locale('menu.wheels'), kind = 'wheels' },
            { key = 'modBackWheels', label = locale('editor.rear_bike_wheels') },
            { key = 'modCustomTiresF', label = locale('editor.custom_tires') },
            { key = 'modCustomTiresR', label = locale('editor.custom_tires_rear') },
            { key = 'wheelColor', label = locale('menu.wheel_color') },
            { key = 'modSmokeEnabled', label = locale('menu.tyre_smoke') },
            { key = 'tyreSmokeColor', label = locale('editor.smoke_color') },
            { key = 'fitment', label = locale('menu.fitment') },
        },
    },
    {
        id = 'paint',
        label = locale('menu.paint'),
        items = {
            { key = 'color1', label = locale('menu.primary') },
            { key = 'paintType1', label = locale('editor.primary_type') },
            { key = 'color2', label = locale('menu.secondary') },
            { key = 'paintType2', label = locale('editor.secondary_type') },
            { key = 'pearlescentColor', label = locale('menu.pearlescent') },
        },
    },
    {
        id = 'lights',
        label = locale('menu.lights'),
        items = {
            { key = 'modXenon', label = locale('menu.xenon') },
            { key = 'xenonColor', label = locale('editor.xenon_color') },
            { key = 'neonEnabled', label = locale('menu.neon') },
            { key = 'neonColor', label = locale('menu.neon_color') },
        },
    },
    { id = 'interior', label = locale('menu.interior'), items = {} },
    {
        id = 'extra',
        label = locale('menu.other'),
        items = {
            { key = 'windowTint', label = locale('menu.window_tint') },
            { key = 'plateIndex', label = locale('menu.plate') },
            { key = 'livery', label = locale('menu.livery') },
            { key = 'modRoofLivery', label = locale('menu.roof_livery') },
            { key = 'extras', label = locale('editor.extras_each') },
        },
    },
    {
        id = 'general',
        label = locale('editor.general'),
        items = {
            { key = 'repair', label = locale('editor.full_repair') },
            { key = 'stock', label = locale('editor.stock_price') },
            { key = 'default', label = locale('editor.default_price') },
        },
    },
}

local rates = {}

for _, group in ipairs(PRICES) do
    rates[group.id] = group.items
end

for _, mod in ipairs(lib.load('data.menu.mods')) do
    local list = rates[mod.menu]

    list[#list + 1] = { key = mod.key, label = mod.label, kind = mod.level and 'levels' or nil }
end

table.insert(rates.performance, { key = 'modTurbo', label = locale('menu.turbo') })
table.insert(rates.performance, { key = 'engineSound', label = locale('menu.engine_swap'), kind = 'engines' })
table.insert(rates.performance, { key = 'nitrousFlame', label = locale('editor.nitrous_flame') })
table.insert(rates.performance, { key = 'nitrousPurge', label = locale('editor.nitrous_purge') })
table.insert(rates.interior, { key = 'interiorColor', label = locale('menu.interior_color') })
table.insert(rates.interior, { key = 'dashboardColor', label = locale('menu.dashboard_color') })

local engines = {}

for i, engine in ipairs(lib.load('data.menu.engines').list) do
    engines[i] = { id = engine.sound, label = engine.label }
end

local wheels = {}

for _, wheel in ipairs(lib.load('data.menu.options').wheelTypes) do
    local id = modules.cart.wheel(wheel.type)

    if id then wheels[#wheels + 1] = { id = id, label = wheel.label } end
end

---@param definition table
---@return string
local function carriedBy(definition)
    if definition.kind == 'engine' then return locale('editor.carry_engine') end

    local spec = definition.carry
    if not spec then return locale('editor.carry_none') end

    local model = spec.model or (spec[1] and spec[1].model)

    return locale(CARRIED[model] or 'editor.carry_panel')
end

---@param definition table
---@return string
local function fittedAt(definition)
    if definition.kind == 'engine' then return locale('editor.at_engine') end

    local list, seen = {}, {}
    local under = definition.work and definition.work.under

    for _, spot in ipairs(definition.spots or {}) do
        local side = spot.wheel and 'editor.at_wheels' or FITTED[spot.side] or 'editor.at_side'
        local id = under and 'editor.at_under' or side

        if not seen[id] then
            seen[id] = true
            list[#list + 1] = locale(id)
        end
    end

    return table.concat(list, ', ')
end

---@param definition table
---@param prefix? string
---@return string
local function describe(definition, prefix)
    local result = { prefix or carriedBy(definition) }
    local fitted = fittedAt(definition)

    if prefix then result[#result + 1] = carriedBy(definition) end
    if fitted ~= '' then result[#result + 1] = fitted end
    if definition.jack then result[#result + 1] = locale('editor.needs_jack') end

    return table.concat(result, ' · ')
end

---@param a table
---@param b table
---@return boolean
local function sooner(a, b)
    if a.id == 'default' then return b.id ~= 'default' end
    if b.id == 'default' then return false end

    return a.label < b.label
end

local parts = {}

do
    local install = lib.load('data.install')
    local folded, owner, buckets = {}, {}, {}
    local order, titles = { 'general' }, {}

    for alias, keys in pairs(modules.zones.ALIASES) do
        for _, key in ipairs(keys) do
            folded[key] = alias
        end
    end

    for _, group in ipairs(PRICES) do
        titles[group.id], buckets[group.id] = group.label, {}

        if group.id ~= 'general' then order[#order + 1] = group.id end

        for _, item in ipairs(group.items) do
            owner[item.key] = { group = group.id, label = item.label }
        end
    end

    buckets.general[#buckets.general + 1] = {
        id = 'default',
        label = locale('editor.part_default'),
        detail = locale('editor.part_default_detail'),
    }

    buckets.paint[#buckets.paint + 1] = {
        id = 'paint',
        label = locale('editor.part_paint'),
        detail = describe(install.parts.color1, locale('editor.part_paint_covers')),
    }

    for key, definition in pairs(install.parts) do
        if not folded[key] then
            local entry = owner[key]
            local bucket = entry and buckets[entry.group] or buckets.general

            bucket[#bucket + 1] = {
                id = key,
                label = RENAMED[key] and locale(RENAMED[key]) or entry and entry.label or key,
                detail = describe(definition),
            }
        end
    end

    for _, id in ipairs(order) do
        table.sort(buckets[id], sooner)

        for _, option in ipairs(buckets[id]) do
            option.group = titles[id]
            parts[#parts + 1] = option
        end
    end
end

local open = false
---@type table?
local preview
---@type vector3[][]?
local boundary
---@type { ok: boolean, error?: string, key?: string }?
local reply

local area = lib.marker.new({ type = 1, coords = vec3(0.0, 0.0, 0.0), color = { r = 0, g = 255, b = 247, a = 70 } })
local dot = lib.marker.new({ type = 28, coords = vec3(0.0, 0.0, 0.0), width = 0.12, height = 0.12 })
local car = lib.marker.new({
    type = 36,
    coords = vec3(0.0, 0.0, 0.0),
    width = 1.2,
    height = 1.2,
    color = { r = 0, g = 255, b = 247, a = 160 },
})

---@param coords vector3
---@param color { r: integer, g: integer, b: integer, a: integer }
local function pin(coords, color)
    dot.coords, dot.color = coords, color
    dot:draw()
end

---@param shop table
local function outline(shop)
    for _, point in ipairs(shop.points or {}) do
        local radius = point.radius or shop.radius or 3.0
        local origin = point.coords

        area.coords = origin - vec3(0.0, 0.0, 0.9)
        area.width, area.height = radius * 2.0, 0.4
        area:draw()

        for _, rack in ipairs(point.racks or {}) do
            local coords = rack.coords

            local r, g, b, a = table.unpack(TETHER)

            pin(coords, RACK)
            DrawLine(origin.x, origin.y, origin.z, coords.x, coords.y, coords.z, r, g, b, a)
        end
    end

    for _, rack in ipairs(shop.racks or {}) do
        pin(rack.coords, RACK)
    end

    for _, entry in ipairs(shop.booths or {}) do
        if entry.vehicle then
            car.coords = entry.vehicle.xyz + vec3(0.0, 0.0, 1.2)
            car.rotation = vec3(0.0, 0.0, entry.vehicle.w)
            car:draw()
        end

        if entry.screen then pin(entry.screen.xyz, SCREEN) end

        for _, nozzle in ipairs(entry.nozzles or {}) do
            pin(nozzle.coords, NOZZLE)
        end
    end
end

local function fence()
    for _, segment in ipairs(boundary or {}) do
        local a, b = segment[1], segment[2]

        DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, BOUNDARY[1], BOUNDARY[2], BOUNDARY[3], BOUNDARY[4])
    end
end

local function draw()
    while open do
        if preview then outline(preview) end
        if boundary and not modules.placer.active() then fence() end

        Wait(0)
    end
end

local function close()
    if not open then return end

    open, preview, boundary = false, nil, nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'editor', data = false })
end

RegisterNetEvent('sm_custom:client:editor', function(data)
    if source == '' or type(data) ~= 'table' or type(data.shops) ~= 'table' then return end

    if open then
        return SendNUIMessage({ action = 'editorShops', data = data })
    end

    open = true
    SendNUIMessage({
        action = 'editor',
        data = {
            shops = data.shops,
            prices = data.prices,
            vehicles = data.vehicles,
            grouping = data.grouping,
            menus = MENUS,
            parts = parts,
            catalog = { groups = PRICES, engines = engines, wheels = wheels },
        },
    })
    SetNuiFocus(true, true)
    CreateThread(draw)
end)

RegisterNUICallback('editorPrices', function(data, cb)
    local valid = open and type(data) == 'table' and (data.action == 'defaults' or data.action == 'spread')
    if not valid then return cb({ ok = false }) end

    local prices = { prices = data.prices, vehicles = data.vehicles, grouping = data.grouping }

    reply = nil
    modules.net.emitLatentServer('sm_custom:server:editorPrices', data.action, prices)
    cb(modules.net.awaitPush(function() return reply end, REPLY_TIMEOUT) or { ok = false, error = 'timeout' })
end)

RegisterNetEvent('sm_custom:client:editorSaved', function(result)
    if source == '' then return end

    reply = type(result) == 'table' and result or { ok = false }
end)

RegisterNUICallback('editorPlace', function(data, cb)
    local options = open and type(data) == 'table' and PLACE[data.kind]
    if not options or modules.placer.active() then return cb(false) end

    local rotation = modules.zones.decode(data.rotation)
    local origin = modules.zones.decode(data.coords)
    local current = data.kind == 'nozzle' and type(origin) == 'vector3' and modules.booth.nozzle(origin) or nil
    local shape = modules.zones.decode(data.area)
    local thickness = type(shape) == 'table' and tonumber(shape.thickness)
    if not thickness or type(shape.points) ~= 'table' or #shape.points < 3 then return cb(false) end

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'editorPlacing', data = true })

    local result = modules.placer.run({
        kind = options.kind,
        model = options.model,
        tilt = options.tilt,
        gizmo = options.gizmo,
        effect = options.effect,
        entity = current,
        rotation = type(rotation) == 'vector3' and rotation or nil,
        area = { points = shape.points, thickness = thickness },
    })

    SendNUIMessage({ action = 'editorPlacing', data = false })

    if open then SetNuiFocus(true, true) end

    cb(result and modules.zones.encode(result) or false)
end)

RegisterNUICallback('editorTeleport', function(data, cb)
    local coords = open and type(data) == 'table' and modules.zones.decode(data.coords)
    local shop = type(coords) == 'vector3' and modules.zones.data[data.key]
    local shape = type(shop) == 'table' and shop.area
    local inside = type(shape) == 'table' and type(shape.points) == 'table' and modules.areas.contains(shape, coords, EDGE)

    cb(inside == true)

    if not inside then return end

    local entity = cache.vehicle and cache.seat == -1 and cache.vehicle or cache.ped

    CreateThread(function()
        local timeout = GetGameTimer() + TELEPORT_TIMEOUT

        FreezeEntityPosition(entity, true)
        SetPedCoordsKeepVehicle(cache.ped, coords.x, coords.y, coords.z)

        while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < timeout do
            RequestCollisionAtCoord(coords.x, coords.y, coords.z)
            Wait(0)
        end

        FreezeEntityPosition(entity, false)
    end)
end)

RegisterNUICallback('editorArea', function(data, cb)
    if not open or type(data) ~= 'table' or modules.placer.active() then return cb(false) end

    local current = modules.zones.decode(data.area)
    local valid = type(current) == 'table' and type(current.points) == 'table'
    local points = valid and current.points or {}
    local thickness = valid and tonumber(current.thickness) or AREA_HEIGHT

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'editorPlacing', data = true })

    local result = modules.placer.polygon(points, thickness)

    SendNUIMessage({ action = 'editorPlacing', data = false })

    if open then SetNuiFocus(true, true) end

    cb(result and modules.zones.encode(result) or false)
end)

RegisterNUICallback('editorPreview', function(data, cb)
    cb(1)

    preview = open and type(data) == 'table' and modules.zones.decode(data.shop) or nil
    boundary = nil

    local zone = preview and preview.area

    if type(zone) == 'table' and type(zone.points) == 'table' and #zone.points >= 2 then
        boundary = modules.areas.prism(modules.areas.flatten(zone.points), tonumber(zone.thickness) or AREA_HEIGHT)
    end
end)

RegisterNUICallback('editorSave', function(data, cb)
    if not open or type(data) ~= 'table' or type(data.shop) ~= 'table' then return cb({ ok = false }) end

    reply = nil
    modules.net.emitLatentServer('sm_custom:server:editorSave', data.shop, data.previous)
    cb(modules.net.awaitPush(function() return reply end, REPLY_TIMEOUT) or { ok = false, error = 'timeout' })
end)

RegisterNUICallback('editorDelete', function(data, cb)
    if not open or type(data) ~= 'table' or type(data.key) ~= 'string' then return cb({ ok = false }) end

    reply = nil
    TriggerServerEvent('sm_custom:server:editorDelete', data.key)
    cb(modules.net.awaitPush(function() return reply end, REPLY_TIMEOUT) or { ok = false, error = 'timeout' })
end)

RegisterNUICallback('editorClose', function(_, cb)
    cb(1)
    close()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then close() end
end)
