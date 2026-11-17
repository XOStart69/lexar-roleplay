local config = require 'config.client'
local data = lib.load('data.booth')

local SEND_EVERY <const> = 100
local BLEND_STEP <const> = 100
local RESEND <const> = 1000
local CLAIM_TIME <const> = 1500
local LIFT <const> = vec3(0.0, 0.0, 0.3)
local ORBIT_FRAME <const> = vec4(0.06, 0.06, 0.94, 0.86)
local LAYERS <const> = { 'color1', 'color2' }
local SHADE_CYCLE <const> = 3000
local MIST_LEVEL <const> = 230
local BODY_GAIN <const> = 1.6
local MATCH <const> = 0.05
local PLAIN_COLOUR <const> = 0

local OPEN_ERRORS <const> = {
    far = 'booth.far',
    taken = 'booth.taken',
    vehicle = 'booth.vehicle',
    occupied = 'booth.occupied',
    seat = 'booth.seat',
    busy = 'booth.busy',
    denied = 'booth.denied',
    invalid = 'booth.invalid',
    billing = 'booth.billing',
    spraying = 'booth.spraying',
    wait = 'booth.wait',
}

---@class BoothSurface
---@field center vector3
---@field normal vector3
---@field width number
---@field height number
---@field corners vector3[]

---@class BoothControl
---@field process boolean
---@field billing boolean
---@field prices table

---@class BoothSite
---@field booth CustomBooth
---@field token integer
---@field round integer
---@field inside boolean
---@field screen? integer
---@field nozzles integer[]
---@field fx integer[]
---@field view? table
---@field net? integer
---@field guarded? integer
---@field final? table
---@field shades? number[][]
---@field began? integer
---@field tone? number[]

local paints = {
    finishes = lib.load('data.menu.options').finishes,
    groups = lib.load('data.menu.paints'),
}

---@param hex string
---@return number[]
local function rgbOf(hex)
    local value = tonumber(hex, 16) or 0

    return { (value >> 16) & 255, (value >> 8) & 255, value & 255 }
end

---@param rgb number[]
---@return number[]
local function vivid(rgb)
    local peak, low = math.max(rgb[1], rgb[2], rgb[3]), math.min(rgb[1], rgb[2], rgb[3])
    local purity = peak > 0 and (peak - low) / peak or 0
    local scale = MIST_LEVEL / math.max(peak, 1) * purity
    local grey = MIST_LEVEL * (1 - purity)

    return { grey + rgb[1] * scale, grey + rgb[2] * scale, grey + rgb[3] * scale }
end

---@type table<integer, number[]>
local tones = {}
---@type table<integer, number[][]>
local shades = {}

for _, group in ipairs(paints.groups) do
    for _, entry in ipairs(group.colors) do
        if entry.ramp then
            local list, r, g, b = {}, 0, 0, 0

            for i, hex in ipairs(entry.ramp) do
                local rgb = rgbOf(hex)

                list[i] = vivid(rgb)
                r, g, b = r + rgb[1], g + rgb[2], b + rgb[3]
            end

            local gain = BODY_GAIN / #list

            tones[entry.id] = { math.min(r * gain, 255), math.min(g * gain, 255), math.min(b * gain, 255) }
            shades[entry.id] = list
        elseif entry.hex then
            tones[entry.id] = rgbOf(entry.hex)
        end
    end
end

---@class BoothClient
local booth = {}

---@type table<string, BoothSite>
local sites = {}
---@type BoothSite?
local focused
---@type BoothSite?
local shown
---@type BoothSite?
local prompted
---@type integer?
local cam
---@type Dui?
local dui
---@type { selection: table, cursor: table }?
local pending
---@type { selection: table, cursor: table }?
local latest
---@type BoothSurface?
local surface
---@type BoothControl?
local control
---@type integer?
local viewing
---@type { vehicle: integer, initial: table, paint?: table }?
local previewing
---@type BoothSite?
local docked
---@type string?
local hinted
local rendering = false
local opening = false
local switching = false
local claiming = false
local sent = 0

---@type fun(vehicle: number, props: table)
local apply = function() end
---@type fun(site: BoothSite, vehicle: integer, tone: number[])
local mist

---@param view table
---@return table
local function decorate(view)
    local result = table.clone(view)

    if view.model then
        local name = GetDisplayNameFromVehicleModel(view.model)

        result.vehicle = modules.catalog.label(name, name)
    end

    return result
end

---@param net any
---@return integer
local function vehicleOf(net)
    if type(net) ~= 'number' or not NetworkDoesEntityExistWithNetworkId(net) then return 0 end

    return NetToVeh(net)
end

---@param site BoothSite
---@param sync? boolean
local function project(site, sync)
    if not dui then return end

    sent = GetGameTimer()

    if not site.view then return dui:sendMessage({ standby = site.booth.label }) end

    local message = {
        view = decorate(site.view),
        paints = paints,
        control = focused == site and control or nil,
        sync = sync and (latest or { selection = site.view.selection, cursor = site.view.cursor }) or nil,
    }

    if viewing and focused == site then
        return SendNUIMessage({ action = 'boothScreen', data = message })
    end

    dui:sendMessage(message)
end

---@param a vector3
---@param b vector3
---@return vector3
local function cross(a, b)
    return vec3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
end

---@param entity integer
---@return BoothSurface
local function measure(entity)
    ---@type vector3[]
    local corners = {}

    for i, offset in ipairs(data.screen.surface) do
        corners[i] = GetOffsetFromEntityInWorldCoords(entity, offset.x, offset.y, offset.z)
    end

    local across, up = corners[2] - corners[1], corners[1] - corners[4]

    return {
        center = (corners[1] + corners[3]) / 2,
        normal = norm(cross(across, up)),
        width = #across,
        height = #up,
        corners = corners,
    }
end

---@param corners vector3[]
---@param x number
---@param y number
---@return number? u
---@return number? v
local function cursorUv(corners, x, y)
    local points = {}

    for i = 1, 4 do
        local visible, sx, sy = GetScreenCoordFromWorldCoord(corners[i].x, corners[i].y, corners[i].z)
        if not visible then return end

        points[i] = { x = sx, y = sy }
    end

    local p0, p1, p2, p3 = points[1], points[2], points[3], points[4]
    local u, v = 0.5, 0.5

    for _ = 1, 10 do
        local iu, iv = 1 - u, 1 - v
        local ex = x - (iu * iv * p0.x + u * iv * p1.x + u * v * p2.x + iu * v * p3.x)
        local ey = y - (iu * iv * p0.y + u * iv * p1.y + u * v * p2.y + iu * v * p3.y)

        if math.abs(ex) < 0.00001 and math.abs(ey) < 0.00001 then break end

        local dux = -iv * p0.x + iv * p1.x + v * p2.x - v * p3.x
        local duy = -iv * p0.y + iv * p1.y + v * p2.y - v * p3.y
        local dvx = -iu * p0.x - u * p1.x + u * p2.x + iu * p3.x
        local dvy = -iu * p0.y - u * p1.y + u * p2.y + iu * p3.y
        local det = dux * dvy - duy * dvx

        if math.abs(det) < 0.0000001 then break end

        u = u + (ex * dvy - ey * dvx) / det
        v = v + (dux * ey - duy * ex) / det
    end

    return u, v
end

---@return BoothSite?
local function closest()
    local coords, found, nearest = GetEntityCoords(cache.ped), nil, math.huge

    for _, site in pairs(sites) do
        local distance = site.screen and #(coords - site.booth.screen.xyz)

        if distance and distance < nearest then found, nearest = site, distance end
    end

    return found
end

local function render()
    if rendering then return end

    rendering = true

    CreateThread(function()
        local target, model = data.screen.target, joaat(data.screen.model)

        if not IsNamedRendertargetRegistered(target) then RegisterNamedRendertarget(target, false) end
        if not IsNamedRendertargetLinked(model) then LinkNamedRendertarget(model) end

        local id = GetNamedRendertargetRenderId(target)
        local screen = lib.dui:new({
            url = ('https://cfx-nui-%s/html/screen.html'):format(cache.resource),
            width = data.screen.width,
            height = data.screen.height,
        })

        dui = screen

        while true do
            local site = focused or closest()
            if not site then break end

            if site ~= shown or GetGameTimer() - sent > RESEND then
                shown = site
                project(site)
            end

            SetTextRenderId(id)
            SetScriptGfxDrawOrder(4)
            SetScriptGfxDrawBehindPausemenu(true)
            DrawSprite(screen.dictName, screen.txtName, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
            SetTextRenderId(GetDefaultScriptRendertargetRenderId())
            Wait(0)
        end

        screen:remove()
        ReleaseNamedRendertarget(target)
        dui, shown, rendering = nil, nil, false
    end)
end

---@param model string
---@param coords vector3
---@param rotation vector3
---@return integer
local function prop(model, coords, rotation)
    local hash = lib.requestModel(model)
    local entity = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, false, false, false)

    SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, false)
    FreezeEntityPosition(entity, true)
    SetModelAsNoLongerNeeded(hash)

    return entity
end

---@param site BoothSite
local function stop(site)
    for _, handle in ipairs(site.fx) do
        StopParticleFxLooped(handle, false)
    end

    table.wipe(site.fx)
end

---@param site BoothSite
local function clear(site)
    stop(site)

    if site.screen and DoesEntityExist(site.screen) then DeleteEntity(site.screen) end

    for _, entity in ipairs(site.nozzles) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end

    site.screen = nil
    table.wipe(site.nozzles)
end

---@param site BoothSite
local function furnish(site)
    local token, entry = site.token, site.booth
    local spot = entry.screen

    if spot then
        local made, screen = pcall(prop, data.screen.model, spot.xyz, vec3(0.0, 0.0, spot.w))

        if site.token ~= token then
            if made then DeleteEntity(screen) end
            return
        end

        if made then site.screen = screen end
    end

    for _, nozzle in ipairs(entry.nozzles) do
        local ok, entity = pcall(prop, data.nozzle.model, nozzle.coords, nozzle.rotation)

        if site.token ~= token then
            if ok then DeleteEntity(entity) end
            return
        end

        if ok then site.nozzles[#site.nozzles + 1] = entity end
    end

    if site.final then mist(site, vehicleOf(site.net), site.tone or data.primer.colour) end
    if site.screen then render() end
end

---@param area BoothSurface
---@param ease integer
local function look(area, ease)
    local view, center = data.screen.camera, area.center
    local spread = math.tan(math.rad(view.fov / 2))
    local fit = math.max(area.height / 2, area.width / 2 / GetAspectRatio(false)) / spread / view.fill
    local position = center + area.normal * fit

    cam = CreateCamWithParams(
        'DEFAULT_SCRIPTED_CAMERA',
        position.x,
        position.y,
        position.z,
        0.0,
        0.0,
        0.0,
        view.fov,
        true,
        2
    )
    PointCamAtCoord(cam, center.x, center.y, center.z)
    RenderScriptCams(true, ease > 0, ease, true, true)
end

---@param site BoothSite
---@param paint any
local function preview(site, paint)
    local view = site.view
    if not view or view.mode ~= 'screen' or view.status == 'spraying' or not view.initial then return end
    if type(paint) ~= 'table' then return end

    local vehicle = vehicleOf(view.net)
    if vehicle == 0 then return end

    previewing = previewing or { vehicle = vehicle, initial = view.initial }
    previewing.paint = paint
    apply(vehicle, paint)
end

---@param site BoothSite
local function claim(site)
    local vehicle = vehicleOf(site.view?.net)
    if claiming or vehicle == 0 or NetworkHasControlOfEntity(vehicle) then return end

    claiming = true

    local deadline = GetGameTimer() + CLAIM_TIME

    while focused == site and not NetworkHasControlOfEntity(vehicle) and GetGameTimer() < deadline do
        NetworkRequestControlOfEntity(vehicle)
        Wait(0)
    end

    claiming = false

    local last = previewing
    if focused ~= site or not last or not last.paint or not NetworkHasControlOfEntity(vehicle) then return end

    apply(vehicle, last.paint)
end

local function unpreview()
    local last = previewing
    if not last then return end

    previewing = nil

    if DoesEntityExist(last.vehicle) then apply(last.vehicle, last.initial) end
end

---@param site BoothSite
local function flush(site)
    if not pending then return end

    TriggerServerEvent('sm_custom:server:boothSelect', site.booth.id, pending.selection, pending.cursor)
    pending = nil
end

local function close()
    local site = focused
    if not site then return end

    focused, control, surface, latest = nil, nil, nil, nil
    flush(site)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'boothCapture', data = false })
    SendNUIMessage({ action = 'boothScreen', data = false })
    project(site)

    if viewing then
        viewing = nil
        modules.camera.stop()
    end

    if site.view?.status == 'spraying' then previewing = nil else unpreview() end

    if cam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(cam, false)
        cam = nil
    end

    config.hud.show()
    TriggerServerEvent('sm_custom:server:boothClose', site.booth.id)
end

---@param result any
local function failed(result)
    local known = type(result) == 'table'
    local reason = known and OPEN_ERRORS[result.reason] or 'booth.timeout'

    lib.notify({ type = 'error', description = locale(reason, known and result.name or locale('booth.someone')) })
end

local function showScreen()
    if not viewing or not surface then return end

    viewing = nil
    look(surface, 0)
    modules.camera.stop(true)
    SendNUIMessage({ action = 'boothCapture', data = 'screen' })

    if focused then project(focused, true) end
end

local function showVehicle()
    local site = focused
    if not site or viewing or switching then return end

    local vehicle = vehicleOf(site.view?.net)

    if vehicle == 0 then
        return lib.notify({ type = 'error', description = locale('booth.unseen') })
    end

    switching = true

    local started = pcall(modules.camera.start, vehicle)

    switching = false

    if not started or focused ~= site then return modules.camera.stop() end

    modules.camera.frame(ORBIT_FRAME.x, ORBIT_FRAME.y, ORBIT_FRAME.z, ORBIT_FRAME.w)
    viewing = vehicle

    if cam then
        DestroyCam(cam, false)
        cam = nil
    end

    SendNUIMessage({ action = 'boothCapture', data = 'vehicle' })
    project(site, true)
end

---@param site BoothSite
local function open(site)
    if focused or opening or IsNuiFocused() then return end

    local entry = site.booth

    opening = true

    local result = lib.callback.await('sm_custom:server:boothOpen', false, entry.id)

    opening = false

    if type(result) ~= 'table' or not result.ok then return failed(result) end

    local screen = site.screen

    if focused or not site.inside or not screen or not DoesEntityExist(screen) then
        return TriggerServerEvent('sm_custom:server:boothClose', entry.id)
    end

    focused, pending, latest, site.view = site, nil, nil, result.view
    control = { process = result.process == true, billing = result.billing == true, prices = result.prices }
    surface = measure(screen)

    if result.view.changed then preview(site, result.view.selection) end

    CreateThread(function() claim(site) end)
    look(surface, 500)
    config.hud.hide()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'boothCapture', data = 'screen' })
    project(site)

    CreateThread(function()
        while focused == site do
            SetEntityLocallyInvisible(cache.ped)

            if viewing then
                if DoesEntityExist(viewing) then modules.camera.tick() else showScreen() end
            end

            Wait(0)
        end
    end)

    CreateThread(function()
        while focused == site do
            flush(site)
            Wait(SEND_EVERY)
        end
    end)
end

---@param site BoothSite
local function leave(site)
    if not site.inside then return end

    site.inside, site.token = false, site.token + 1

    if focused == site then close() end

    if prompted == site then
        prompted = nil
        modules.interact.clear()
    end

    if docked == site then
        docked, hinted = nil, nil
        lib.hideTextUI()
    end

    clear(site)
    modules.interact.hold(site.booth.id, false)
end

---@param site BoothSite
local function prompt(site)
    if focused or not site.screen then return end

    local screen = site.booth.screen.xyz
    local distance = #(GetEntityCoords(cache.ped) - screen)

    if distance > data.reach or cache.vehicle then
        if prompted == site then
            prompted = nil
            modules.interact.clear()
        end

        return
    end

    prompted = site
    modules.interact.draw(screen + LIFT, 'paint', distance, locale('booth.choose'))

    if IsControlJustReleased(0, 38) then
        prompted = nil
        modules.interact.clear()
        CreateThread(function() open(site) end)
    end
end

---@param site BoothSite
---@param vehicle integer
---@param registered boolean
local function toggle(site, vehicle, registered)
    opening = true

    local result

    if registered then
        result = lib.callback.await('sm_custom:server:boothRelease', false, site.booth.id)
    else
        local props = lib.getVehicleProperties(vehicle) --[[@as VehicleProperties]]

        result = lib.callback.await('sm_custom:server:boothRegister', false, site.booth.id, {
            color1 = props.color1,
            paintType1 = props.paintType1,
            color2 = props.color2,
            paintType2 = props.paintType2,
            pearlescentColor = props.pearlescentColor,
        }, NetworkGetNetworkIdFromEntity(vehicle), GetVehicleClass(vehicle))
    end

    opening = false

    if type(result) ~= 'table' or not result.ok then return failed(result) end

    local text = locale(registered and 'booth.released' or 'booth.registered')

    lib.notify({ type = 'success', description = text })
end

---@param site BoothSite
---@param text string | false
local function hint(site, text)
    if text then
        if docked ~= site or hinted ~= text then lib.showTextUI(text) end

        docked, hinted = site, text
    elseif docked == site then
        docked, hinted = nil, nil
        lib.hideTextUI()
    end
end

---@param site BoothSite
local function dock(site)
    if site.booth.mode ~= 'screen' then return end

    local vehicle = cache.vehicle
    local driving = vehicle and cache.seat == -1 and not focused and NetworkGetEntityIsNetworked(vehicle)
    local parked = driving and #(GetEntityCoords(vehicle) - site.booth.vehicle.xyz) <= data.radius
    local registered = parked and vehicleOf(site.view?.net) or nil
    local release = registered ~= nil and registered == vehicle
    local text = (registered == 0 and locale('booth.register')) or (release and locale('booth.release')) or false

    hint(site, text)

    if not text then return end

    DisableControlAction(0, 86, true)

    if IsControlJustReleased(0, 38) and not opening then
        CreateThread(function() toggle(site, vehicle --[[@as integer]], release) end)
    end
end

---@param site BoothSite
local function guard(site)
    local net, now = site.view?.net, GetGameTimer()
    if not net or now < (site.guarded or 0) then return end

    site.guarded = now + 1000

    local vehicle = vehicleOf(net)

    if vehicle ~= 0 and NetworkHasControlOfEntity(vehicle) then FreezeEntityPosition(vehicle, true) end
end

---@param site BoothSite
local function tend(site)
    local token = site.token

    while site.inside and site.token == token do
        prompt(site)
        dock(site)
        guard(site)
        Wait(0)
    end
end

---@param site BoothSite
local function arrive(site)
    if site.inside then return end

    site.inside, site.token = true, site.token + 1
    modules.interact.hold(site.booth.id, true)
    CreateThread(function() furnish(site) end)
    CreateThread(function() tend(site) end)
end

---@param entry CustomBooth
---@return BoothSite
local function create(entry)
    ---@type BoothSite
    local site = { booth = entry, token = 0, round = 0, inside = false, nozzles = {}, fx = {} }

    if modules.areas.inside(entry.key) then arrive(site) end

    return site
end

local function build()
    for _, site in pairs(sites) do
        leave(site)
    end

    table.wipe(sites)

    for _, entry in ipairs(modules.zones.booths) do
        sites[entry.id] = create(entry)
    end
end

---@param a any
---@param b any
---@return boolean
local function same(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end

    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

---@param colour any
---@return number[]
local function toneOf(colour)
    if type(colour) == 'table' then return colour end

    return tones[colour] or data.primer.colour
end

---@param colour any
---@return number[][]
local function shadesOf(colour)
    return type(colour) == 'number' and shades[colour] or { toneOf(colour) }
end

---@param vehicle integer
---@param primary boolean
---@return number[]
local function current(vehicle, primary)
    if primary and GetIsVehiclePrimaryColourCustom(vehicle) then return { GetVehicleCustomPrimaryColour(vehicle) } end

    if not primary and GetIsVehicleSecondaryColourCustom(vehicle) then
        return { GetVehicleCustomSecondaryColour(vehicle) }
    end

    local first, second = GetVehicleColours(vehicle)

    return toneOf(primary and first or second)
end

---@param a number[]
---@param b number[]
---@param t number
---@return number[]
local function lerp(a, b, t)
    return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end

---@param list number[][]
---@param time integer
---@return number[]
local function shadeAt(list, time)
    if #list < 2 then return list[1] end

    local position = time % SHADE_CYCLE / SHADE_CYCLE * #list
    local index = math.floor(position)

    return lerp(list[index + 1], list[(index + 1) % #list + 1], position - index)
end

---@param handle integer
---@param tone number[]
local function tint(handle, tone)
    SetParticleFxLoopedColour(handle, tone[1] / 255, tone[2] / 255, tone[3] / 255, false)
end

---@param site BoothSite
---@param tone number[]
local function colorize(site, tone)
    site.tone = tone

    for _, handle in ipairs(site.fx) do
        tint(handle, tone)
    end
end

---@param vehicle integer
---@return integer?
local function puff(vehicle)
    local fx = data.smoke

    if vehicle == 0 or not pcall(lib.requestNamedPtfxAsset, fx.asset) then return end

    UseParticleFxAsset(fx.asset)

    local offset, rotation = fx.offset, fx.rotation
    local handle = StartParticleFxLoopedOnEntity(
        fx.effect,
        vehicle,
        offset.x,
        offset.y,
        offset.z,
        rotation.x,
        rotation.y,
        rotation.z,
        fx.scale,
        false,
        false,
        false
    )

    SetParticleFxLoopedAlpha(handle, fx.alpha)

    return handle
end

---@param site BoothSite
---@param vehicle integer
---@param tone number[]
function mist(site, vehicle, tone)
    local nozzle = data.nozzle
    local offset, rotation = nozzle.offset, nozzle.rotation

    lib.requestNamedPtfxAsset(nozzle.asset)

    for _, entity in ipairs(site.nozzles) do
        UseParticleFxAsset(nozzle.asset)

        local handle = StartParticleFxLoopedOnEntity(
            nozzle.effect,
            entity,
            offset.x,
            offset.y,
            offset.z,
            rotation.x,
            rotation.y,
            rotation.z,
            nozzle.scale,
            false,
            false,
            false
        )

        SetParticleFxLoopedAlpha(handle, nozzle.alpha)
        site.fx[#site.fx + 1] = handle
    end

    local cloud = puff(vehicle)

    if cloud then site.fx[#site.fx + 1] = cloud end

    colorize(site, tone)
end

---@param vehicle integer
---@param primary boolean
---@param colour number[]
local function coat(vehicle, primary, colour)
    local r, g, b = math.floor(colour[1] + 0.5), math.floor(colour[2] + 0.5), math.floor(colour[3] + 0.5)

    if primary then
        SetVehicleCustomPrimaryColour(vehicle, r, g, b)
    else
        SetVehicleCustomSecondaryColour(vehicle, r, g, b)
    end
end

---@param vehicle integer
---@param channels { primary: boolean }[]
local function unramp(vehicle, channels)
    local first, second = GetVehicleColours(vehicle)
    local primary, secondary = first, second

    for _, channel in ipairs(channels) do
        if channel.primary and shades[first] then primary = PLAIN_COLOUR end
        if not channel.primary and shades[second] then secondary = PLAIN_COLOUR end
    end

    if primary ~= first or secondary ~= second then SetVehicleColours(vehicle, primary, secondary) end
end

---@param site BoothSite
---@param payload { net: integer, paint: table, initial?: table, time: integer, began?: integer, elapsed?: number }
---@param round integer
local function blend(site, payload, round)
    local vehicle = vehicleOf(payload.net)
    if vehicle == 0 then return end

    local final, initial, primer = payload.paint, payload.initial, data.primer
    local channels = {}

    if initial then apply(vehicle, initial) end

    for index, key in ipairs(LAYERS) do
        if final[key] ~= nil and not (initial and same(final[key], initial[key])) then
            local primary = index == 1

            channels[#channels + 1] = {
                key = key,
                primary = primary,
                from = current(vehicle, primary),
                to = toneOf(final[key]),
            }
        end
    end

    local list = shadesOf(final[channels[1] and channels[1].key or 'pearlescentColor'])
    local elapsed = math.min(math.max(tonumber(payload.elapsed) or 0, 0), payload.time)
    local began, split, coated = GetGameTimer() - elapsed, primer.share, false

    site.shades = list
    unramp(vehicle, channels)

    while site.round == round and DoesEntityExist(vehicle) do
        local now = GetGameTimer()
        local t = math.min((now - began) / payload.time, 1.0)
        local second = t >= split

        if second and not coated then
            coated = true
            apply(vehicle, final)
            unramp(vehicle, channels)
            colorize(site, list[1])
        end

        if second and #list > 1 then colorize(site, shadeAt(list, now)) end

        for _, channel in ipairs(channels) do
            local colour = second
                and lerp(primer.colour, channel.to, (t - split) / (1.0 - split))
                or lerp(channel.from, primer.colour, t / split)

            coat(vehicle, channel.primary, colour)
        end

        if t >= 1.0 then return apply(vehicle, final) end

        Wait(BLEND_STEP)
    end
end

---@param vehicle integer
---@param list? number[][]
local function smoke(vehicle, list)
    local handle = puff(vehicle)
    if not handle then return end

    local began, time = GetGameTimer(), data.smoke.time

    repeat
        if list then tint(handle, shadeAt(list, GetGameTimer())) end

        Wait(list and #list > 1 and BLEND_STEP or time)
    until GetGameTimer() - began >= time

    StopParticleFxLooped(handle, false)
end

RegisterNetEvent('sm_custom:client:booth', function(view)
    if source == '' or type(view) ~= 'table' then return end

    local site = sites[view.id]
    if not site then return end

    local before = site.view?.net

    site.view = view

    if before and before ~= view.net then
        local vehicle = vehicleOf(before)

        if vehicle ~= 0 and NetworkHasControlOfEntity(vehicle) then FreezeEntityPosition(vehicle, false) end
    end

    if site == shown then project(site) end
end)

RegisterNetEvent('sm_custom:client:boothSpray', function(id, payload)
    if source == '' then return end

    local site = sites[id]
    if not site then return end

    local fresh = type(payload) == 'table'

    if fresh and site.final and site.began == payload.began then return end

    site.round += 1
    stop(site)

    if not fresh then
        local vehicle, final, list = vehicleOf(site.net), site.final, site.shades

        site.net, site.final, site.shades, site.began, site.tone = nil, nil, nil, nil, nil

        if vehicle ~= 0 and final then apply(vehicle, final) end

        CreateThread(function() smoke(vehicle, list) end)
        return
    end

    local round = site.round

    site.net, site.final, site.shades, site.began = payload.net, payload.paint, nil, payload.began

    CreateThread(function()
        if pcall(mist, site, vehicleOf(payload.net), data.primer.colour) and site.round ~= round then stop(site) end

        blend(site, payload, round)
    end)
end)

---@param net any
---@return boolean
local function spraying(net)
    for _, site in pairs(sites) do
        if site.final and site.net == net then return true end
    end

    return false
end

RegisterNetEvent('sm_custom:client:boothPaint', function(net, paint, preview)
    if source == '' or type(paint) ~= 'table' then return end
    if preview == true and spraying(net) then return end

    local vehicle = vehicleOf(net)

    if vehicle ~= 0 then apply(vehicle, paint) end
end)

RegisterNUICallback('boothSelect', function(body, cb)
    cb(1)

    if not focused or type(body) ~= 'table' then return end

    local site = focused

    pending = { selection = body.selection, cursor = body.cursor }
    latest = pending
    preview(site, body.selection)
    CreateThread(function() claim(site) end)
end)

RegisterNUICallback('boothMouse', function(body, cb)
    cb(1)

    local area, screen = surface, dui
    if not focused or not area or not screen or type(body) ~= 'table' then return end

    local u, v = cursorUv(area.corners, tonumber(body.x) or -1, tonumber(body.y) or -1)
    if not u or not v then return end

    local inside = u >= 0 and u <= 1 and v >= 0 and v <= 1

    if body.type == 'down' and not inside then return end

    local button = body.button == 2 and 'right' or 'left'

    screen:sendMouseMove(
        math.floor(math.min(math.max(u, 0), 1) * data.screen.width + 0.5),
        math.floor(math.min(math.max(v, 0), 1) * data.screen.height + 0.5)
    )

    if body.type == 'down' then
        screen:sendMouseDown(button)
    elseif body.type == 'up' then
        screen:sendMouseUp(button)
    elseif body.type == 'wheel' then
        screen:sendMouseWheel(0.0, -(tonumber(body.delta) or 0))
    end
end)

RegisterNUICallback('boothCustomers', function(_, cb)
    if not focused then return cb({}) end

    cb(lib.callback.await('sm_custom:server:boothCustomers', false, focused.booth.id) or {})
end)

RegisterNUICallback('boothProcess', function(body, cb)
    local site = focused
    if not site or type(body) ~= 'table' then return cb({ ok = false, reason = 'invalid' }) end

    pending = nil

    local result = lib.callback.await(
        'sm_custom:server:boothProcess',
        false,
        site.booth.id,
        body.method,
        tonumber(body.customer),
        body.selection,
        body.cursor
    )

    cb(result or { ok = false, reason = 'timeout' })

    if type(result) == 'table' and result.ok and focused == site then close() end
end)

RegisterNUICallback('boothPreview', function(body, cb)
    cb(1)

    if focused and type(body) == 'table' then preview(focused, body.selection) end
end)

RegisterNUICallback('boothClose', function(_, cb)
    cb(1)
    close()
end)

RegisterNUICallback('boothVehicle', function(_, cb)
    cb(1)
    showVehicle()
end)

RegisterNUICallback('boothScreen', function(_, cb)
    cb(1)
    showScreen()
end)

modules.areas.watch(function(key, inside)
    for _, site in pairs(sites) do
        if site.booth.key == key then
            if inside then
                arrive(site)
            else
                leave(site)
                site.round += 1
                site.view, site.net, site.final, site.shades, site.began, site.tone = nil, nil, nil, nil, nil, nil

                if site == shown then project(site) end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    close()

    for _, site in pairs(sites) do
        clear(site)
    end
end)

---@param coords vector3
---@return integer?
function booth.nozzle(coords)
    for _, site in pairs(sites) do
        for _, entity in ipairs(site.nozzles) do
            if DoesEntityExist(entity) and #(GetEntityCoords(entity) - coords) <= MATCH then return entity end
        end
    end
end

---@param setter fun(vehicle: number, props: table)
function booth.start(setter)
    apply = setter

    build()
    modules.zones.watch(build)
end

return booth
