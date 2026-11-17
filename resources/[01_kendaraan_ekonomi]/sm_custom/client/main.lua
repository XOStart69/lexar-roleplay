local config = require 'config.client'

---@type table<string, NitrousEffect>
local EFFECT_VIEWS <const> = { flame = 'flame', purge = 'purge' }
local RADIO_CONTROLS <const> = { 249, 19 }
local HORN_CONTROL <const> = 86

---@class FitmentEdit
---@field values FitmentValues
---@field original FitmentValues
---@field defaults? FitmentValues
---@field ranges? FitmentRanges

---@class CustomProps : VehicleProperties
---@field nitrousFlame? integer[]
---@field nitrousPurge? integer[]
---@field engineSound? string | false

---@class CustomClientSession
---@field vehicle number
---@field props VehicleProperties
---@field prices CustomPrices
---@field fitment? FitmentEdit
---@field effect? NitrousEffect
---@field shown? table
---@field zone CustomZone
---@field shop CustomShop
---@field sound string | false
---@field label string

---@class CustomShop
---@field label string
---@field mechanic boolean
---@field billing boolean
---@field install boolean
---@field repair 'manual' | 'auto'
---@field timeout number
---@field self boolean

---@class CustomOpenPayload
---@field error? 'zone' | 'vehicle' | 'job' | 'owner' | 'busy'
---@field prices CustomPrices
---@field balance { cash: number, bank: number }
---@field owned boolean
---@field mine boolean
---@field shop CustomShop

---@type table<string, string>
local OPEN_ERRORS <const> = {
    zone = 'open.zone',
    vehicle = 'open.vehicle',
    job = 'open.job',
    owner = 'open.owner',
    busy = 'open.busy',
}

---@type CustomClientSession?
local session
---@type CustomOpenPayload?
local received
---@class CustomPurchaseResult
---@field ok boolean
---@field reason? string
---@field balance { cash: number, bank: number }
---@field install? boolean
---@field menu? CatalogNode[]
---@field receipt? string

---@type CustomPurchaseResult?
local purchased
---@type { list?: table[], values?: FitmentValues }?
local answered
---@type { active: boolean, focus?: integer, sent: { wheel: integer, x: number, y: number }[] }
local picker = { active = false, sent = {} }
---@type { engine: boolean, rev: boolean, burnout: boolean, lights: boolean, horn: boolean }
local controls = { engine = true, rev = false, burnout = false, lights = false, horn = false }
local pulse = 0

---@param vehicle number
---@param props VehicleProperties
local function setProps(vehicle, props)
    local primary, secondary = props.color1, props.color2
    local base = table.clone(props)

    if type(primary) == 'table' then base.color1 = nil end
    if type(secondary) == 'table' then base.color2 = nil end

    lib.setVehicleProperties(vehicle, base)

    if type(primary) ~= 'table' and type(secondary) ~= 'table' then return end

    local pearlescent, wheel = GetVehicleExtraColours(vehicle)

    if type(primary) == 'table' then
        SetVehicleModColor_1(vehicle, props.paintType1 or 1, 0, pearlescent)
        SetVehicleCustomPrimaryColour(vehicle, primary[1], primary[2], primary[3])
    end

    if type(secondary) == 'table' then
        SetVehicleModColor_2(vehicle, props.paintType2 or 1, 0)
        SetVehicleCustomSecondaryColour(vehicle, secondary[1], secondary[2], secondary[3])
    end

    SetVehicleExtraColours(vehicle, pearlescent, wheel)
end

---@param vehicle number
local function fix(vehicle)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)

    for index = 0, 7 do
        FixVehicleWindow(vehicle, index)
        SetVehicleTyreFixed(vehicle, index)
    end
end

---@param vehicle number
local function wash(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)
end

local function close()
    if not session then return end

    local vehicle, props, edit = session.vehicle, session.props, session.fitment

    session = nil

    if controls.rev or controls.burnout then
        ClearPedTasks(cache.ped)
    end

    if DoesEntityExist(vehicle) then
        setProps(vehicle, props)
        modules.fitment.refresh(vehicle)

        modules.swap.release(vehicle)

        SetVehicleLights(vehicle, 0)
        SetVehicleEngineOn(vehicle, true, true, false)
        FreezeEntityPosition(vehicle, false)
    end

    if edit then
        modules.fitment.release(vehicle, edit.original)
    end

    modules.nitrous.preview(vehicle, nil, {})
    picker = { active = false, sent = {} }
    modules.camera.stop()
    config.hud.show()
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    TriggerServerEvent('sm_custom:server:close')
end

---@param markers { wheel: integer, x: number, y: number }[]
---@return boolean
local function moved(markers)
    local sent = picker.sent
    if #sent ~= #markers then return true end

    for i, marker in ipairs(markers) do
        local last = sent[i]
        local shift = math.max(math.abs(last.x - marker.x), math.abs(last.y - marker.y))

        if last.wheel ~= marker.wheel or shift > 0.0015 then
            return true
        end
    end

    return false
end

---@param force? boolean
local function syncWheels(force)
    local markers = picker.active and modules.camera.wheels() or {}

    if force or moved(markers) then
        picker.sent = markers
        SendNUIMessage({ action = 'wheels', data = { markers = markers, focus = picker.focus } })
    end
end

local function watch()
    local missing = 0

    while session do
        local vehicle = session.vehicle

        if not DoesEntityExist(vehicle) then
            print(locale('log.vehicle_gone'))
            return close()
        end

        missing = IsPedInVehicle(cache.ped, vehicle, false) and 0 or missing + 1

        if missing > 30 then
            print(locale('log.player_left'))
            return close()
        end

        if session.effect then
            modules.nitrous.keep(session.shown or session.props)
        end

        if (controls.rev or controls.burnout) and GetGameTimer() >= pulse then
            TaskVehicleTempAction(cache.ped, session.vehicle, controls.burnout and 30 or 31, 1500)
            pulse = GetGameTimer() + 1200
        end

        DisableAllControlActions(0)

        for i = 1, #RADIO_CONTROLS do
            EnableControlAction(0, RADIO_CONTROLS[i], true)
        end

        if controls.horn then
            EnableControlAction(0, HORN_CONTROL, true)
            SetControlNormal(0, HORN_CONTROL, 1.0)
        end

        HideHudAndRadarThisFrame()
        modules.camera.tick()

        if picker.active then
            syncWheels()
        end
        Wait(0)
    end
end

---@param zone CustomZone
local function open(zone)
    local vehicle = cache.vehicle
    if session or modules.install.active() or not vehicle or cache.seat ~= -1 then return end

    local netId = NetworkGetNetworkIdFromEntity(vehicle)

    received = nil
    TriggerServerEvent('sm_custom:server:open', netId, zone.id, GetVehicleClass(vehicle))

    local payload = modules.net.awaitPush(function() return received end, 5000) --[[@as CustomOpenPayload?]]

    if not payload or payload.error then
        local reason = payload and OPEN_ERRORS[payload.error]

        return lib.notify({ type = 'error', description = locale(reason or 'open.timeout') })
    end

    if cache.vehicle ~= vehicle then
        return TriggerServerEvent('sm_custom:server:close')
    end

    local props = lib.getVehicleProperties(vehicle) --[[@as CustomProps]]
    local model = GetDisplayNameFromVehicleModel(props.model --[[@as number]])
    local tank = modules.nitrous.tank(vehicle)

    if tank then
        props.nitrousFlame = tank.flame or config.nitrous.flame.colour
        props.nitrousPurge = tank.purge or config.nitrous.purge.colour
    end

    props.engineSound = modules.swap.current(vehicle)

    local catalog = modules.catalog
    local label = catalog.label(model, model)
    local menu = catalog.build(vehicle, props, payload.prices, zone)

    session = {
        vehicle = vehicle,
        props = props,
        prices = payload.prices,
        zone = zone,
        shop = payload.shop,
        sound = props.engineSound,
        label = label,
    }
    controls = { engine = true, rev = false, burnout = false, lights = false, horn = false }

    modules.net.emitLatentServer('sm_custom:server:original', props)
    FreezeEntityPosition(vehicle, true)
    SetVehicleEngineOn(vehicle, true, true, false)
    config.hud.hide()
    modules.camera.start(vehicle)

    SendNUIMessage({
        action = 'open',
        data = {
            name = label,
            class = modules.catalog.label(('VEH_CLASS_%d'):format(GetVehicleClass(vehicle)), ''),
            plate = props.plate,
            balance = payload.balance,
            props = props,
            menu = menu,
            controls = controls,
            shop = payload.shop,
        },
    })

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    CreateThread(watch)

    if not payload.owned then
        lib.notify({ type = 'info', description = locale('open.unowned') })
    elseif not payload.mine then
        lib.notify({ type = 'info', description = locale('open.customer') })
    end
end

---@return table<string, string>
local function interfaceLocales()
    local result = {}

    for key, text in pairs(lib.getLocales()) do
        local name = key:match('^ui%.(.+)$')

        if name then result[name] = text end
    end

    return result
end

RegisterNUICallback('locales', function(_, cb)
    cb(interfaceLocales())
end)

AddEventHandler('ox_lib:setLocale', function()
    SendNUIMessage({ action = 'locales', data = interfaceLocales() })
end)

SendNUIMessage({ action = 'locales', data = interfaceLocales() })

RegisterNetEvent('sm_custom:client:custom', function()
    if source == '' then return end

    open(modules.zones.admin)
end)

RegisterNetEvent('sm_custom:client:restore', function(netId, props)
    if source == '' or math.type(netId) ~= 'integer' or type(props) ~= 'table' then return end
    if not NetworkDoesEntityExistWithNetworkId(netId) then return end

    local vehicle = NetToVeh(netId)

    if vehicle ~= 0 and session?.vehicle ~= vehicle then setProps(vehicle, props) end
end)

RegisterNetEvent('sm_custom:client:session', function(payload)
    if source == '' then return end

    received = type(payload) == 'table' and payload or { error = 'vehicle' }
end)

RegisterNetEvent('sm_custom:client:purchased', function(result)
    if source == '' then return end

    purchased = result
end)

RegisterNetEvent('sm_custom:client:balance', function(balance)
    if source == '' or not session then return end

    SendNUIMessage({ action = 'balance', data = balance })
end)

RegisterNUICallback('preview', function(data, cb)
    if not session then return cb(0) end

    local shown = modules.cart.merge(modules.cart.merge(session.props, data.cart), data.preview or {})

    session.shown = shown
    setProps(session.vehicle, shown)
    modules.fitment.refresh(session.vehicle)
    modules.nitrous.preview(session.vehicle, session.effect, shown)

    if shown.engineSound ~= session.sound then
        session.sound = shown.engineSound
        modules.swap.hold(session.vehicle, session.sound)
    end

    cb(modules.cart.total(session.prices, session.props, data.cart))
end)

RegisterNUICallback('fitment', function(_, cb)
    if not session then return cb(false) end

    local vehicle = session.vehicle
    local defaults, ranges = modules.wheels.probe(vehicle)

    if not session or not defaults then return cb(false) end

    local edit = session.fitment

    if not edit then
        local values = modules.wheels.capture(vehicle)

        edit = { values = values, original = modules.wheels.copy(values) }
        session.fitment = edit
        modules.fitment.hold(vehicle, values)
    elseif edit.values.rim ~= modules.wheels.rim(vehicle) then
        modules.wheels.rebase(edit.values, modules.wheels.capture(vehicle))
    end

    edit.defaults, edit.ranges = defaults, ranges

    cb({
        values = edit.values,
        defaults = defaults,
        ranges = ranges,
        targets = modules.wheels.targets(vehicle),
        stored = modules.fitment.get(vehicle) ~= nil,
    })
end)

RegisterNUICallback('fitmentAdjust', function(data, cb)
    local edit = session and session.fitment
    if not session or not edit or not edit.ranges or type(data) ~= 'table' then return cb(false) end

    cb(modules.wheels.adjust(session.vehicle, edit.values, edit.ranges, data))
end)

RegisterNUICallback('fitmentApply', function(data, cb)
    local edit = session and session.fitment
    local values = type(data) == 'table' and data.values
    if not session or not edit or type(values) ~= 'table' then return cb(false) end
    if type(values.offset) ~= 'table' or type(values.rotation) ~= 'table' then return cb(false) end

    edit.values = modules.wheels.copy(values)
    modules.fitment.hold(session.vehicle, edit.values)
    modules.fitment.share(session.vehicle)
    cb(true)
end)

RegisterNUICallback('fitmentShare', function(_, cb)
    cb(1)

    if session and session.fitment then
        modules.fitment.share(session.vehicle)
    end
end)

RegisterNUICallback('presets', function(data, cb)
    local edit = session and session.fitment
    if not session or type(data) ~= 'table' then return cb(false) end

    local action = data.action
    if action == 'get' and not edit then return cb(false) end

    answered = nil
    TriggerServerEvent('sm_custom:server:presets', action, action == 'save' and {
        name = data.name,
        public = data.public == true,
    } or data.id)

    local reply = modules.net.awaitPush(function() return answered end, 5000)

    if reply and reply.values and edit and session and session.fitment == edit then
        local values = modules.wheels.copy(reply.values)

        if values.rim ~= modules.wheels.rim(session.vehicle) then
            reply.skipped = values.rim ~= nil
            modules.wheels.rebase(values, edit.values)
        end

        edit.values, reply.values = values, values
        modules.fitment.hold(session.vehicle, edit.values)
        modules.fitment.share(session.vehicle)
    end

    cb(reply or false)
end)

RegisterNetEvent('sm_custom:client:presets', function(reply)
    if source == '' then return end

    answered = type(reply) == 'table' and reply or {}
end)

RegisterNUICallback('wheelPick', function(data, cb)
    cb(1)

    local active = session ~= nil and type(data) == 'table' and data.active == true

    if not active and picker.focus then
        modules.camera.focusWheel(nil)
    end

    picker.active, picker.focus = active, active and picker.focus or nil
    syncWheels(true)
end)

RegisterNUICallback('wheelFocus', function(data, cb)
    cb(1)

    if not session or not picker.active or type(data) ~= 'table' then return end

    picker.focus = modules.camera.focusWheel(tonumber(data.wheel))
    syncWheels(true)
end)

RegisterNUICallback('view', function(data, cb)
    cb(1)
    picker.focus = nil
    modules.camera.focus(data.view)

    if session then
        session.effect = EFFECT_VIEWS[data.view]
        modules.nitrous.preview(session.vehicle, session.effect, session.shown or session.props)
    end
end)

RegisterNUICallback('orbit', function(data, cb)
    cb(1)
    modules.camera.orbit(data.x, data.y, data.zoom)
end)

RegisterNUICallback('camera', function(_, cb)
    cb(session ~= nil and modules.camera.toggle())
end)

RegisterNUICallback('frame', function(data, cb)
    cb(1)
    modules.camera.frame(data.left, data.top, data.right, data.bottom)
end)

RegisterNUICallback('control', function(data, cb)
    local name = data.name
    if not session or controls[name] == nil then return cb(controls) end

    local vehicle = session.vehicle
    local acting = controls.rev or controls.burnout

    controls[name] = not controls[name]

    if controls[name] and (name == 'rev' or name == 'burnout') then
        controls[name == 'rev' and 'burnout' or 'rev'] = false
        controls.engine = true
    elseif name == 'engine' and not controls.engine then
        controls.rev, controls.burnout = false, false
    end

    if acting and not (controls.rev or controls.burnout) then
        ClearPedTasks(cache.ped)
    end

    SetVehicleEngineOn(vehicle, controls.engine, true, true)
    SetVehicleLights(vehicle, controls.lights and 2 or 0)
    FreezeEntityPosition(vehicle, not controls.burnout)

    pulse = 0
    cb(controls)
end)

RegisterNUICallback('customers', function(_, cb)
    if not session or not session.shop.billing then return cb({}) end

    cb(lib.callback.await('sm_custom:server:customers', false) or {})
end)

---@param vehicle number
local function assemble(vehicle)
    close()

    if not DoesEntityExist(vehicle) then return end

    FreezeEntityPosition(vehicle, true)

    if IsPedInVehicle(cache.ped, vehicle, false) then
        TaskLeaveVehicle(cache.ped, vehicle, 0)
    end
end

RegisterNUICallback('discount', function(data, cb)
    if not session or type(data) ~= 'table' then return cb({ ok = false, reason = 'invalid' }) end

    local code = type(data.code) == 'string' and data.code or false

    cb(lib.callback.await('sm_custom:server:discount', false, code) or { ok = false, reason = 'timeout' })
end)

RegisterNUICallback('purchase', function(data, cb)
    if not session or type(data) ~= 'table' or type(data.cart) ~= 'table' then return cb({ ok = false }) end

    local billed = data.method == 'bill'

    purchased = nil
    modules.net.emitLatentServer('sm_custom:server:purchase', data.cart, data.method, {
        customer = billed and tonumber(data.customer) or nil,
        items = type(data.items) == 'table' and data.items or nil,
        vehicle = session.label,
    })

    local timeout = billed and (session.shop.timeout + 10) * 1000 or 10000
    local result = modules.net.awaitPush(function() return purchased end, timeout) --[[@as CustomPurchaseResult?]]

    if result and result.ok and result.receipt then
        cb(result)
        close()

        return lib.notify({ type = 'success', description = locale('receipt.issued', result.receipt) })
    end

    if result and result.ok and session then
        if result.install then
            cb(result)

            return assemble(session.vehicle)
        end

        local edit, bought = session.fitment, data.cart.fitment

        session.props = modules.cart.merge(session.props, data.cart)

        if edit and bought ~= nil then
            edit.original = modules.wheels.copy(bought or edit.defaults or edit.original)
        end

        if data.cart.repair then
            fix(session.vehicle)
            session.props = modules.cart.repair(session.props)
        end

        if data.cart.clean then
            wash(session.vehicle)
            session.props = modules.cart.clean(session.props)
        end
    end

    if result and not result.ok then
        lib.print.warn(('purchase failed: %s, method %s, cart %s'):format(result.reason, data.method, json.encode(data.cart)))
    end

    cb(result or { ok = false, reason = 'timeout' })
end)

RegisterNUICallback('close', function(_, cb)
    cb(1)
    close()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then close() end
end)

modules.install.start(function(vehicle, props)
    local patch = table.clone(props)

    if patch.repair then
        patch.repair = nil
        fix(vehicle)
    end

    if patch.clean then
        patch.clean = nil
        wash(vehicle)
    end

    if patch.modFrontWheels ~= nil and patch.modCustomTiresF == nil then
        patch.modCustomTiresF = GetVehicleModVariation(vehicle, 23)
    end

    if patch.modBackWheels ~= nil and patch.modCustomTiresR == nil then
        patch.modCustomTiresR = GetVehicleModVariation(vehicle, 24)
    end

    setProps(vehicle, patch)
    modules.fitment.refresh(vehicle)
end)

modules.booth.start(setProps)

modules.shops.start(open, function() return session == nil and not modules.install.active() end)
modules.billing.start(function() return session ~= nil end)
