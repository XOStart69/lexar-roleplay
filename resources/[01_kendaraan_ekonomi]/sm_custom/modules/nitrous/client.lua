local config = require('config.client').nitrous

local ASSET <const> = 'rhd_nitrous_flame'
local FLAME <const> = 'rhd_veh_nitrous'
local STEAM <const> = 'ent_sht_steam'
local SHARE_DELAY <const> = 150

---@class NitrousClient
local nitrous = {}

---@class NitrousTank
---@field level number
---@field flame? integer[]
---@field purge? integer[]

---@alias NitrousEffect 'flame' | 'purge'

local exhausts = { 'exhaust' }

for i = 2, 16 do
    exhausts[i] = ('exhaust_%d'):format(i)
end

---@type table<string, NitrousTank>
local tanks = {}
---@type table<string, true>?
local fresh = {}
---@type table<number, table<NitrousEffect, integer[]>>
local effects = {}
---@type { vehicle: number, kind: NitrousEffect, handles: integer[] }?
local shown
---@type table<integer, { shop: string, handles: integer[] }>
local remote = {}
---@type { kind: NitrousEffect | false, colour: integer[] | false }
local queued = { kind = false, colour = false }
local shared, sharing = '', false
local boosting, purging, armed = false, 0, false

---@param vehicle number
---@return string
local function plateOf(vehicle)
    return (GetVehicleNumberPlateText(vehicle):match('^%s*(.-)%s*$'))
end

---@param vehicle number
---@return NitrousTank?
function nitrous.tank(vehicle)
    if not config.enable then return end
    if GetResourceState('rhd_nitrous') ~= 'started' then return tanks[plateOf(vehicle)] end

    local state = exports.rhd_nitrous:getNitrous(vehicle)
    if type(state) ~= 'table' or type(state.flame) ~= 'table' or type(state.purge) ~= 'table' then return end

    return { level = tonumber(state.level) or 0, flame = state.flame, purge = state.purge }
end

---@param plate string
---@param level number
local function gauge(plate, level)
    if cache.vehicle and plateOf(cache.vehicle) == plate then config.hud(level) end
end

---@param handles integer[]
---@param rgb integer[]?
---@param fallback integer[]
local function tint(handles, rgb, fallback)
    local colour = type(rgb) == 'table' and rgb[3] and rgb or fallback

    for _, handle in ipairs(handles) do
        SetParticleFxLoopedColour(handle, colour[1] / 255, colour[2] / 255, colour[3] / 255, false)
    end
end

---@param vehicle number
---@param kind NitrousEffect
---@param rgb integer[]?
---@return integer[]
local function start(vehicle, kind, rgb)
    local handles = {}

    if kind == 'flame' then
        lib.requestNamedPtfxAsset(ASSET)

        for _, name in ipairs(exhausts) do
            local bone = GetEntityBoneIndexByName(vehicle, name)

            if bone ~= -1 then
                UseParticleFxAsset(ASSET)
                handles[#handles + 1] = StartParticleFxLoopedOnEntityBone(
                    FLAME, vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, bone, config.flame.scale, false, false, false
                )
            end
        end
    else
        lib.requestNamedPtfxAsset('core')

        for side, name in ipairs({ 'wheel_lf', 'wheel_rf' }) do
            local bone = GetEntityBoneIndexByName(vehicle, name)

            if bone ~= -1 then
                local sign = side == 1 and -1.0 or 1.0
                local world = GetWorldPositionOfEntityBone(vehicle, bone)
                local offset = GetOffsetFromEntityGivenWorldCoords(vehicle, world.x, world.y, world.z)
                local x, y, z = offset.x + 0.1 * sign, offset.y + 0.5, offset.z + 0.05

                UseParticleFxAsset('core')
                handles[#handles + 1] = StartParticleFxLoopedOnEntity(
                    STEAM, vehicle, x, y, z, 30.0, 50.0 * sign, 0.5, config.purge.scale, false, false, false
                )
            end
        end
    end

    tint(handles, rgb, config[kind].colour)

    return handles
end

---@param handles integer[]?
local function stop(handles)
    for _, handle in ipairs(handles or {}) do
        StopParticleFxLooped(handle, false)
    end
end

---@param vehicle number
---@param kind NitrousEffect
---@param active boolean
local function toggle(vehicle, kind, active)
    local slot = effects[vehicle] or {}

    effects[vehicle] = slot
    stop(slot[kind])
    slot[kind] = nil

    if active then
        local tank = tanks[plateOf(vehicle)]

        slot[kind] = start(vehicle, kind, tank and tank[kind])
    elseif not next(slot) then
        effects[vehicle] = nil
    end
end

---@param vehicle number
---@param kind NitrousEffect?
---@param props table
function nitrous.preview(vehicle, kind, props)
    if shown and (shown.kind ~= kind or shown.vehicle ~= vehicle) then
        stop(shown.handles)
        shown = nil
    end

    local rgb = kind and props[kind == 'flame' and 'nitrousFlame' or 'nitrousPurge']
    local colour = type(rgb) == 'table' and rgb or false
    local key = kind and ('%s:%s'):format(kind, colour and table.concat(colour, ',') or '') or ''

    if key ~= shared then
        shared = key
        queued = { kind = kind or false, colour = colour }

        if not sharing then
            sharing = true

            SetTimeout(SHARE_DELAY, function()
                sharing = false
                modules.net.emitLatentServer('sm_custom:server:nitrousPreview', queued.kind, queued.colour)
            end)
        end
    end

    if not kind or not DoesEntityExist(vehicle) then return end

    if shown then
        tint(shown.handles, rgb, config[kind].colour)
    else
        shown = { vehicle = vehicle, kind = kind, handles = start(vehicle, kind, rgb) }
    end
end

---@param props table
function nitrous.keep(props)
    if not shown or not DoesEntityExist(shown.vehicle) then return end

    for _, handle in ipairs(shown.handles) do
        if not DoesParticleFxLoopedExist(handle) then
            local rgb = props[shown.kind == 'flame' and 'nitrousFlame' or 'nitrousPurge']

            stop(shown.handles)
            shown.handles = start(shown.vehicle, shown.kind, rgb)

            return
        end
    end
end

---@param vehicle number
---@param seconds integer
---@return boolean exploded
local function overheat(vehicle, seconds)
    local limit = config.overheat
    if not limit or seconds < limit.warn then return false end

    if seconds >= limit.explode then
        lib.notify({ type = 'error', description = locale('nitrous.exploded') })
        NetworkExplodeVehicle(vehicle, true, true, true)
        return true
    end

    RequestAmbientAudioBank('DLC_sum20_Open_Wheel_Racing_Sounds', false)
    PlaySoundFromEntity(-1, 'tyre_health_warning', vehicle, 'DLC_sum20_Open_Wheel_Racing_Sounds', true, 0)

    if seconds >= limit.damage then
        if seconds == limit.damage then
            lib.notify({ type = 'error', description = locale('nitrous.overheat') })
        end

        SetVehicleEngineHealth(vehicle, GetVehicleEngineHealth(vehicle) - math.random(19, 25))
    end

    return false
end

local function boost()
    local vehicle = cache.vehicle
    local tank = vehicle and cache.seat == -1 and tanks[plateOf(vehicle)]
    if boosting or not vehicle or not tank or tank.level <= 0 then return end

    local netId = VehToNet(vehicle)
    local top = GetVehicleModelMaxSpeed(GetEntityModel(vehicle))
    local ceiling = config.maxSpeed / 3.6
    local level, began, second, report = tank.level, GetGameTimer(), 0, 0

    boosting = true
    TriggerServerEvent('sm_custom:server:nitrousFx', netId, 'flame', true)

    CreateThread(function()
        while boosting and level > 0 and cache.vehicle == vehicle and DoesEntityExist(vehicle) do
            local speed = GetEntitySpeed(vehicle)
            local now = GetGameTimer()

            if speed >= ceiling then
                SetVehicleBoostActive(vehicle, false)
                SetVehicleCheatPowerIncrease(vehicle, 1.0)
            else
                local power = speed < 1.0 and config.multiplier or config.multiplier * top / speed

                SetVehicleBoostActive(vehicle, true)
                SetVehicleCheatPowerIncrease(vehicle, math.min(power, config.multiplier * 3.0))
            end

            level = math.max(level - config.drain * GetFrameTime(), 0.0)

            if now >= report then
                report = now + 100
                config.hud(level)
            end

            if (now - began) // 1000 > second then
                second = (now - began) // 1000

                if overheat(vehicle, second) then break end
            end

            Wait(0)
        end

        boosting = false

        if DoesEntityExist(vehicle) then
            SetVehicleBoostActive(vehicle, false)
            SetVehicleCheatPowerIncrease(vehicle, 1.0)
        end

        config.hud(level)
        TriggerServerEvent('sm_custom:server:nitrousFx', netId, 'flame', false, level)
    end)
end

local function purge()
    local vehicle = cache.vehicle
    local tank = vehicle and cache.seat == -1 and tanks[plateOf(vehicle)]
    if purging ~= 0 or not vehicle or not tank or tank.level <= 0 then return end

    purging = VehToNet(vehicle)
    TriggerServerEvent('sm_custom:server:nitrousFx', purging, 'purge', true)
end

local function unpurge()
    if purging == 0 then return end

    TriggerServerEvent('sm_custom:server:nitrousFx', purging, 'purge', false)
    purging = 0
end

local function arm()
    if armed then return end

    armed = true

    lib.addKeybind({
        name = 'sm_custom_nitrous',
        description = locale('nitrous.key_boost'),
        defaultKey = config.keys.boost,
        onPressed = boost,
        onReleased = function() boosting = false end,
    })

    lib.addKeybind({
        name = 'sm_custom_purge',
        description = locale('nitrous.key_purge'),
        defaultKey = config.keys.purge,
        onPressed = purge,
        onReleased = unpurge,
    })

    lib.onCache('vehicle', function(vehicle)
        boosting = false
        unpurge()

        local tank = vehicle and tanks[plateOf(vehicle)]

        config.hud(tank and tank.level or 0)
    end)
end

RegisterNetEvent('sm_custom:client:tanks', function(list)
    if source == '' or type(list) ~= 'table' then return end

    local skip = fresh or {}

    fresh = nil

    for plate, data in pairs(list) do
        if type(plate) == 'string' and type(data) == 'table' and not skip[plate] then
            tanks[plate] = data
        end
    end

    arm()

    local tank = cache.vehicle and tanks[plateOf(cache.vehicle)]

    if tank then config.hud(tank.level) end
end)

RegisterNetEvent('sm_custom:client:tank', function(plate, data)
    if source == '' or type(plate) ~= 'string' then return end

    if fresh then fresh[plate] = true end

    tanks[plate] = type(data) == 'table' and data or nil
    gauge(plate, tanks[plate] and tanks[plate].level or 0)
end)

RegisterNetEvent('sm_custom:client:nitrousFx', function(id, kind, active, plate, level)
    if source == '' or (kind ~= 'flame' and kind ~= 'purge') then return end

    local tank = type(plate) == 'string' and tanks[plate]

    if tank and type(level) == 'number' then
        tank.level = level
        gauge(plate, level)
    end

    if math.type(id) ~= 'integer' or not NetworkDoesEntityExistWithNetworkId(id) then return end

    local vehicle = NetToVeh(id)

    if vehicle ~= 0 then toggle(vehicle, kind, active == true) end
end)

RegisterNetEvent('sm_custom:client:nitrousPreview', function(id, shop, kind, colour)
    if source == '' or math.type(id) ~= 'integer' or type(shop) ~= 'string' then return end

    local entry = remote[id]

    remote[id] = nil

    if entry then stop(entry.handles) end
    if (kind ~= 'flame' and kind ~= 'purge') or not modules.areas.inside(shop) then return end
    if not NetworkDoesEntityExistWithNetworkId(id) then return end

    local vehicle = NetToVeh(id)
    if vehicle == 0 then return end

    local handles = start(vehicle, kind, type(colour) == 'table' and colour or nil)

    stop(remote[id] and remote[id].handles)
    remote[id] = { shop = shop, handles = handles }
end)

modules.areas.watch(function(key, inside)
    if inside then return end

    for id, entry in pairs(remote) do
        if entry.shop == key then
            stop(entry.handles)
            remote[id] = nil
        end
    end
end)

lib.callback.register('sm_custom:client:installNitrous', function()
    local vehicle = cache.vehicle

    if not vehicle then
        lib.notify({ type = 'error', description = locale('nitrous.need_vehicle') })
        return false
    end

    if config.classes[GetVehicleClass(vehicle)] then
        lib.notify({ type = 'error', description = locale('nitrous.blocked') })
        return false
    end

    if config.turbo and not IsToggleModOn(vehicle, 18) then
        lib.notify({ type = 'error', description = locale('nitrous.need_turbo') })
        return false
    end

    local done = lib.progressBar({
        duration = config.installTime,
        label = locale('nitrous.installing'),
        canCancel = true,
        disable = { move = true, car = true },
    })

    return done and cache.vehicle == vehicle and VehToNet(vehicle) or false
end)

if config.enable then TriggerServerEvent('sm_custom:server:tanks') end

return nitrous
