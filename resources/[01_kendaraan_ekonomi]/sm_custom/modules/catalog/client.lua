local mods = lib.load('data.menu.mods')
local paints = lib.load('data.menu.paints')
local options = lib.load('data.menu.options')
local engines = lib.load('data.menu.engines')
local config = require 'config.client'

local SPECIAL <const> = 'Chameleon'

---@class CatalogClient
local catalog = {}

---@class CatalogOption
---@field label string
---@field patch table<string, any>
---@field price number

---@class CatalogColor
---@field key string
---@field patch table<string, any>
---@field price number

---@class CatalogNode
---@field id string
---@field label string
---@field view string
---@field children? CatalogNode[]
---@field options? CatalogOption[]
---@field color? CatalogColor
---@field fitment? { price: number, part: string }
---@field level? boolean

---@param text string?
---@param fallback string
---@return string
function catalog.label(text, fallback)
    return text and DoesTextLabelExist(text) and GetFilenameForAudioConversation(text) or fallback
end

---@param prices CustomPrices
---@param label string
---@param patch table<string, any>
---@return CatalogOption
local function option(prices, label, patch)
    return { label = label, patch = patch, price = modules.cart.sum(prices, patch) }
end

---@param prices CustomPrices
---@param key string
---@param colors { id: number, label: string }[]
---@return CatalogOption[]
local function palette(prices, key, colors)
    local list = {}

    for i = 1, #colors do
        list[i] = option(prices, colors[i].label, { [key] = colors[i].id })
    end

    return list
end

---@param prices CustomPrices
---@param id string
---@param key string
---@param view string
---@param special? boolean
---@return CatalogNode[]
local function shades(prices, id, key, view, special)
    local list = {}

    for _, group in ipairs(paints) do
        if special or group.label ~= SPECIAL then
            list[#list + 1] = {
                id = ('%s_%s'):format(id, group.label),
                label = group.label,
                view = view,
                options = palette(prices, key, group.colors),
            }
        end
    end

    return list
end

---@param prices CustomPrices
---@param id string
---@param label string
---@param key string
---@param patch? table<string, any>
---@param view? string
---@return CatalogNode
local function color(prices, id, label, key, patch, view)
    patch = patch or {}

    local full = table.clone(patch)

    full[key] = 0

    return {
        id = id,
        label = label,
        view = view or 'overview',
        color = {
            key = key,
            patch = patch,
            price = modules.cart.sum(prices, full),
        },
    }
end

---@param vehicle number
---@param prices CustomPrices
---@param mod { type: number, key: string, label: string, view: string, level?: boolean }
---@return CatalogNode?
local function slot(vehicle, prices, mod)
    local count = GetNumVehicleMods(vehicle, mod.type)
    if count < 1 then return end

    local list = { option(prices, locale('menu.stock'), { [mod.key] = -1 }) }

    for i = 0, count - 1 do
        local fallback = mod.level and locale('menu.level', i + 1) or ('%s %d'):format(mod.label, i + 1)
        list[i + 2] = option(prices, catalog.label(GetModTextLabel(vehicle, mod.type, i), fallback), { [mod.key] = i })
    end

    return { id = mod.key, label = mod.label, view = mod.view, options = list, level = mod.level }
end

---@param prices CustomPrices
---@param id string
---@param label string
---@param colorKey string
---@param typeKey string
---@return CatalogNode
local function paint(prices, id, label, colorKey, typeKey)
    local custom = {}

    for i, finish in ipairs(options.finishes) do
        local patch = { [typeKey] = finish.type }
        custom[i] = color(prices, ('%s_%d'):format(id, finish.type), finish.label, colorKey, patch)
    end

    local children = { { id = id .. '_custom', label = locale('menu.custom'), view = 'overview', children = custom } }

    for _, node in ipairs(shades(prices, id, colorKey, 'overview', true)) do
        children[#children + 1] = node
    end

    return { id = id, label = label, view = 'overview', children = children }
end

---@param vehicle number
---@param props VehicleProperties
---@param prices CustomPrices
---@return CatalogNode[]
local function wheels(vehicle, props, prices)
    local bike = GetVehicleClass(vehicle) == 8
    local types = {}

    for _, wheel in ipairs(options.wheelTypes) do
        if (wheel.type == 6) == bike then
            SetVehicleWheelType(vehicle, wheel.type)

            local stock = { wheels = props.wheels, modFrontWheels = -1, modBackWheels = bike and -1 or nil }
            local list = { option(prices, locale('menu.stock'), stock) }

            for i = 0, GetNumVehicleMods(vehicle, 23) - 1 do
                local text = catalog.label(GetModTextLabel(vehicle, 23, i), ('%s %d'):format(wheel.label, i + 1))
                local patch = { wheels = wheel.type, modFrontWheels = i, modBackWheels = bike and i or nil }
                list[i + 2] = option(prices, text, patch)
            end

            if #list > 1 then
                types[#types + 1] = {
                    id = 'wheels_' .. wheel.type,
                    label = wheel.label,
                    view = 'wheel',
                    options = list,
                }
            end
        end
    end

    SetVehicleWheelType(vehicle, props.wheels --[[@as number]])
    SetVehicleMod(vehicle, 23, props.modFrontWheels --[[@as number]], props.modCustomTiresF --[[@as boolean]])
    SetVehicleMod(vehicle, 24, props.modBackWheels --[[@as number]], props.modCustomTiresR --[[@as boolean]])

    local tires = {
        option(prices, locale('menu.stock'), { modCustomTiresF = false, modCustomTiresR = bike and false or nil }),
        option(prices, locale('menu.custom'), { modCustomTiresF = true, modCustomTiresR = bike and true or nil }),
    }
    local children = {}

    if #types > 0 then
        children[1] = { id = 'wheelTypes', label = locale('menu.wheel_type'), view = 'wheel', children = types }
    end

    children[#children + 1] = { id = 'tires', label = locale('menu.tires'), view = 'wheel', options = tires }
    children[#children + 1] = {
        id = 'wheelColor',
        label = locale('menu.wheel_color'),
        view = 'wheel',
        children = shades(prices, 'wheelColor', 'wheelColor', 'wheel', true),
    }
    children[#children + 1] = {
        id = 'smoke',
        label = locale('menu.tyre_smoke'),
        view = 'wheel',
        children = {
            {
                id = 'smokeState',
                label = locale('menu.status'),
                view = 'wheel',
                options = {
                    option(prices, locale('menu.off'), { modSmokeEnabled = false }),
                    option(prices, locale('menu.on'), { modSmokeEnabled = true }),
                },
            },
            color(prices, 'smokeColor', locale('menu.color'), 'tyreSmokeColor', { modSmokeEnabled = true }),
        },
    }

    if config.fitment.enable and GetVehicleNumberOfWheels(vehicle) > 0 then
        local price = modules.cart.price(prices, 'fitment', true)
        local settings = {}

        for i, entry in ipairs(options.fitment) do
            settings[i] = {
                id = 'fitment_' .. entry.part,
                label = entry.label,
                view = entry.view,
                fitment = { price = price, part = entry.part },
            }
        end

        children[#children + 1] = {
            id = 'fitment',
            label = locale('menu.fitment'),
            view = 'stance',
            children = {
                { id = 'fitment_setting', label = locale('menu.setting'), view = 'stance', children = settings },
                {
                    id = 'fitment_reset',
                    label = locale('menu.reset'),
                    view = 'stance',
                    fitment = { price = 0, part = 'reset' },
                },
                {
                    id = 'fitment_preset',
                    label = locale('menu.preset'),
                    view = 'overview',
                    fitment = { price = price, part = 'preset' },
                },
            },
        }
    end

    return children
end

---@param vehicle number
---@param prices CustomPrices
---@return CatalogNode?
local function engineSwap(vehicle, prices)
    local model = GetEntityModel(vehicle)
    local allowed

    for name, sounds in pairs(engines.models) do
        if joaat(name) == model then
            allowed = sounds
            break
        end
    end

    allowed = allowed or engines.classes[GetVehicleClass(vehicle)]
    if not allowed then return end

    local permitted = {}

    for _, sound in ipairs(allowed) do
        permitted[sound] = true
    end

    local list = { option(prices, locale('menu.stock'), { engineSound = false }) }

    for _, engine in ipairs(engines.list) do
        if permitted[engine.sound] then
            list[#list + 1] = option(prices, engine.label, { engineSound = engine.sound })
        end
    end

    return { id = 'engineSound', label = locale('menu.engine_swap'), view = 'engine', options = list }
end

---@param prices CustomPrices
---@return CatalogNode[]
local function lights(prices)
    local xenon = { option(prices, locale('menu.off'), { modXenon = false }) }

    for _, entry in ipairs(options.xenonColors) do
        xenon[#xenon + 1] = option(prices, entry.label, { modXenon = true, xenonColor = entry.id })
    end

    local neon = {}

    for i, layout in ipairs(options.neonLayouts) do
        neon[i] = option(prices, layout.label, { neonEnabled = layout.sides })
    end

    return {
        { id = 'xenon', label = locale('menu.xenon'), view = 'front', options = xenon },
        { id = 'neonLayout', label = locale('menu.neon'), view = 'neon', options = neon },
        color(prices, 'neonColor', locale('menu.neon_color'), 'neonColor', nil, 'neon'),
    }
end

---@param vehicle number
---@param prices CustomPrices
---@return CatalogNode[]
local function extra(vehicle, prices)
    local children = {
        {
            id = 'windowTint',
            label = locale('menu.window_tint'),
            view = 'left',
            options = palette(prices, 'windowTint', options.windowTints),
        },
        {
            id = 'plateIndex',
            label = locale('menu.plate'),
            view = 'plate',
            options = palette(prices, 'plateIndex', options.plates),
        },
    }

    local liveries = GetVehicleLiveryCount(vehicle)

    if liveries > 0 then
        local list = {}

        for i = 0, liveries - 1 do
            local text = catalog.label(GetLiveryName(vehicle, i), locale('menu.livery_n', i + 1))
            list[i + 1] = option(prices, text, { livery = i })
        end

        children[#children + 1] = { id = 'livery', label = locale('menu.livery'), view = 'left', options = list }
    end

    local roofs = GetVehicleRoofLiveryCount(vehicle)

    if roofs > 0 then
        local list = {}

        for i = 0, roofs - 1 do
            list[i + 1] = option(prices, locale('menu.roof_livery_n', i + 1), { modRoofLivery = i })
        end

        children[#children + 1] = {
            id = 'roofLivery',
            label = locale('menu.roof_livery'),
            view = 'top',
            options = list,
        }
    end

    for id = 1, 15 do
        if DoesExtraExist(vehicle, id) then
            local key = tostring(id)

            children[#children + 1] = {
                id = 'extra_' .. key,
                label = locale('menu.extra_n', id),
                view = 'overview',
                options = {
                    option(prices, locale('menu.on'), { extras = { [key] = 0 } }),
                    option(prices, locale('menu.off'), { extras = { [key] = 1 } }),
                },
            }
        end
    end

    return children
end

---@param nodes CatalogNode[]
---@param zone CustomZone
---@return CatalogNode[]
function catalog.filter(nodes, zone)
    if not zone.allow then return nodes end

    local result = {}

    for _, node in ipairs(nodes) do
        if modules.zones.shows(zone, node.id) then
            result[#result + 1] = node
        elseif node.children then
            local children = catalog.filter(node.children, zone)

            if #children > 0 then
                local copy = table.clone(node)

                copy.children = children
                result[#result + 1] = copy
            end
        end
    end

    return result
end

---@param prices CustomPrices
---@return CatalogNode
function catalog.service(prices)
    return {
        id = 'service',
        label = locale('menu.service'),
        view = 'overview',
        children = {
            {
                id = 'repair',
                label = locale('menu.repair'),
                view = 'engine',
                options = { option(prices, locale('menu.repair_vehicle'), { repair = true }) },
            },
            {
                id = 'clean',
                label = locale('menu.clean'),
                view = 'overview',
                options = { option(prices, locale('menu.clean_vehicle'), { clean = true }) },
            },
        },
    }
end

---@param vehicle number
---@param props VehicleProperties
---@param prices CustomPrices
---@param zone CustomZone
---@return CatalogNode[]
function catalog.build(vehicle, props, prices, zone)
    SetVehicleModKit(vehicle, 0)

    local menus = {
        performance = { id = 'performance', label = locale('menu.performance'), view = 'engine', children = {} },
        body = { id = 'body', label = locale('menu.body'), view = 'overview', children = {} },
        interior = { id = 'interior', label = locale('menu.interior'), view = 'interior', children = {} },
        extra = { id = 'extra', label = locale('menu.other'), view = 'overview', children = extra(vehicle, prices) },
    }

    for _, mod in ipairs(mods) do
        local node = slot(vehicle, prices, mod)

        if node then
            table.insert(menus[mod.menu].children, node)
        end
    end

    table.insert(menus.performance.children, {
        id = 'modTurbo',
        label = locale('menu.turbo'),
        view = 'engine',
        options = {
            option(prices, locale('menu.stock'), { modTurbo = false }),
            option(prices, locale('menu.turbo'), { modTurbo = true }),
        },
    })

    local swap = engineSwap(vehicle, prices)

    if swap then
        table.insert(menus.performance.children, swap)
    end

    if modules.nitrous.tank(vehicle) then
        table.insert(menus.performance.children, {
            id = 'nitrous',
            label = locale('menu.nitrous'),
            view = 'flame',
            children = {
                color(prices, 'nitrousFlame', locale('menu.flame_color'), 'nitrousFlame', nil, 'flame'),
                color(prices, 'nitrousPurge', locale('menu.purge_color'), 'nitrousPurge', nil, 'purge'),
            },
        })
    end

    table.insert(menus.interior.children, {
        id = 'interiorColor',
        label = locale('menu.interior_color'),
        view = 'seat',
        children = shades(prices, 'interiorColor', 'interiorColor', 'seat'),
    })

    table.insert(menus.interior.children, {
        id = 'dashboardColor',
        label = locale('menu.dashboard_color'),
        view = 'dashboard',
        children = shades(prices, 'dashboardColor', 'dashboardColor', 'dashboard'),
    })

    local result = {}

    for _, menu in ipairs({
        menus.performance,
        menus.body,
        { id = 'wheels', label = locale('menu.wheels'), view = 'wheel', children = wheels(vehicle, props, prices) },
        {
            id = 'paint',
            label = locale('menu.paint'),
            view = 'overview',
            children = {
                paint(prices, 'primary', locale('menu.primary'), 'color1', 'paintType1'),
                paint(prices, 'secondary', locale('menu.secondary'), 'color2', 'paintType2'),
                {
                    id = 'pearlescent',
                    label = locale('menu.pearlescent'),
                    view = 'overview',
                    children = shades(prices, 'pearlescent', 'pearlescentColor', 'overview', true),
                },
            },
        },
        { id = 'lights', label = locale('menu.lights'), view = 'front', children = lights(prices) },
        menus.interior,
        menus.extra,
    }) do
        if #menu.children > 0 then
            result[#result + 1] = menu
        end
    end

    local menu = catalog.filter(result, zone)

    if not zone.booth then menu[#menu + 1] = catalog.service(prices) end

    return menu
end

return catalog
