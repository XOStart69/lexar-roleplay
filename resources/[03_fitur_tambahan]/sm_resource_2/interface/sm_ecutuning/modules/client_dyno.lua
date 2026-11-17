local placedDynos = {}
local spawnedProps = {}
local ownState     = { owns = false, stored = false, mayUse = false }

local placing      = nil
local mounted      = false
local promptShown  = false
local pendingMount = nil

local startMount
local startSetup
local gotSync      = false
local lastSig      = nil

local scr = {
    dui = nil, txd = nil, tex = nil,
    rt = {}, replaced = false,
}

local function screenSendRaw(payload)
    if scr.dui then SendDuiMessage(scr.dui, json.encode(payload)) end
end

local function screenSend(payload)
    if scr.dui then SendDuiMessage(scr.dui, json.encode(payload)) end
end
local runState     = nil





local function dnotify(ntype, key, ...)
    if HRS_Notify then
        HRS_Notify(ntype, key, ...)
    else
        print(('^3[Debug Dyno]^7 %s: %s'):format(ntype, key))
    end
end

local function dnui(data)
    ECU_SendNUI(data)
end

local function loadModel(hash)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then return false end
    RequestModel(hash)
    local t = GetGameTimer() + 8000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > t then return false end
    end
    return true
end

local function originFixFor(model)
    for _, d in ipairs(ECUConfig.Dyno.Props) do
        if d.model == model and d.originFix then return d.originFix end
    end
    return vector3(0.0, 0.0, 0.0)
end

local function applyOriginFix(model, pos, yawDeg)
    local f = originFixFor(model)
    if f.x == 0.0 and f.y == 0.0 and f.z == 0.0 then return pos end
    local r = math.rad(yawDeg or 0.0)
    local cs, sn = math.cos(r), math.sin(r)
    return vector3(pos.x + (f.x * cs - f.y * sn),
                   pos.y + (f.x * sn + f.y * cs),
                   pos.z + f.z)
end

local function createProp(model, pos, rot, ghost)
    local hash = GetHashKey(model)
    if not loadModel(hash) then
        print(('^1[Debug EcuTuning]^7 dyno model "%s" failed to load (missing ytyp?)'):format(model))
        return nil
    end

    local wp = applyOriginFix(model, pos, rot.z)
    local obj
    if model == 'hrs_dyno' then
        obj = CreateObjectNoOffset(hash, wp.x, wp.y, wp.z, false, false, false)
    else
        obj = CreateObject(hash, wp.x, wp.y, wp.z, false, false, false)
    end
    SetModelAsNoLongerNeeded(hash)
    if not obj or obj == 0 or not DoesEntityExist(obj) then return nil end

    SetEntityRotation(obj, rot.x, rot.y, rot.z, 2, true)
    FreezeEntityPosition(obj, true)
    if ghost then
        SetEntityCollision(obj, false, false)
        SetEntityAlpha(obj, 190, false)
    else
        SetEntityCollision(obj, true, true)
        ResetEntityAlpha(obj)
    end
    if model == 'hrs_dyno' and HRS_DynoRollers then
        HRS_DynoRollers.spawn(obj, ghost)
    end
    return obj
end

local function destroySet(objs)
    for _, o in ipairs(objs or {}) do
        if HRS_DynoRollers then HRS_DynoRollers.remove(o) end
        if DoesEntityExist(o) then DeleteEntity(o) end
    end
end

local rebuildTries = 0

local function rebuildWorld()
    for _, set in pairs(spawnedProps) do destroySet(set) end
    spawnedProps = {}

    local expected, created = 0, 0
    for _, d in ipairs(placedDynos) do
        local objs = {}
        for _, pr in ipairs(d.props or {}) do
            expected = expected + 1
            local o = createProp(pr.model,
                vector3(pr.x, pr.y, pr.z),
                vector3(pr.rx or 0.0, pr.ry or 0.0, pr.rz or 0.0), false)
            if o then
                objs[#objs + 1] = o
                created = created + 1
            end
        end
        spawnedProps[d.owner] = objs
    end

    if expected > 0 and created < expected then
        rebuildTries = rebuildTries + 1
        if rebuildTries <= 6 then
            print(('^3[Debug Dyno]^7 only %d of %d props created, retry in 4s (%d/6)')
                :format(created, expected, rebuildTries))
            SetTimeout(4000, function()
                if #placedDynos > 0 then rebuildWorld() end
            end)
            lastSig = nil
        else
            print(('^1[Debug Dyno]^7 props could not be created (%d/%d).')
                :format(created, expected))
            print('^1[Debug Dyno]^7 check that hrs_dyno.ytyp is streamed')
        end
    elseif expected > 0 then
        rebuildTries = 0
        print(('^2[Debug Dyno]^7 %d prop(s) built'):format(created))
    end
end

local function nearestDyno(coords)
    local best, bestProp, bestD = nil, nil, ECUConfig.Dyno.MountDistance + 3.0
    for _, d in ipairs(placedDynos) do
        for _, pr in ipairs(d.props or {}) do
            if pr.isdyno == 1 or pr.isdyno == true then
                local dist = #(coords - vector3(pr.x, pr.y, pr.z))
                if dist < bestD then best, bestProp, bestD = d, pr, dist end
            end
        end
    end
    return best, bestProp, bestD
end

local dynoBlips = {}

local function clearBlips()
    for _, b in ipairs(dynoBlips) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    dynoBlips = {}
end

local function rebuildBlips()
    clearBlips()
    local cfg = ECUConfig.Dyno.Blip
    if not cfg or not cfg.enabled then return end

    for _, d in ipairs(placedDynos) do
        local isStatic = tostring(d.owner or ''):find('^static') ~= nil
        if isStatic or not cfg.staticOnly then
            for _, pr in ipairs(d.props or {}) do
                if pr.isdyno == 1 or pr.isdyno == true then
                    local b = AddBlipForCoord(pr.x, pr.y, pr.z)
                    SetBlipSprite(b, cfg.sprite or 446)
                    SetBlipColour(b, cfg.color or 3)
                    SetBlipScale(b, cfg.scale or 0.75)
                    SetBlipAsShortRange(b, true)
                    BeginTextCommandSetBlipName('STRING')
                    AddTextComponentString(cfg.label or 'Dyno')
                    EndTextCommandSetBlipName(b)
                    dynoBlips[#dynoBlips + 1] = b
                end
            end
        end
    end
end

local function listSignature(list)
    local parts = {}
    for _, d in ipairs(list or {}) do
        for _, pr in ipairs(d.props or {}) do
            parts[#parts + 1] = ('%s|%s|%.2f|%.2f|%.2f|%.2f|%.2f|%.2f')
                :format(tostring(d.owner), tostring(pr.model),
                        pr.x or 0, pr.y or 0, pr.z or 0,
                        pr.rx or 0, pr.ry or 0, pr.rz or 0)
        end
    end
    table.sort(parts)
    return table.concat(parts, ';')
end

RegisterNetEvent('sm_ecutuning:dyno:sync', function(list)
    gotSync = true
    placedDynos = list or {}

    local sig = listSignature(placedDynos)
    if sig == lastSig then return end
    lastSig = sig

    rebuildTries = 0
    rebuildWorld()
    rebuildBlips()
end)

RegisterNetEvent('sm_ecutuning:dyno:ownState', function(s)
    ownState = s or ownState
    dnui({ type = 'dynoOwnState', state = ownState })
    rebuildBlips()
end)

RegisterNetEvent('sm_ecutuning:dyno:useGranted', function()
    if pendingMount and not mounted then
        local d = pendingMount
        pendingMount = nil
        startMount(d)
    end
end)

RegisterNetEvent('sm_ecutuning:dyno:notify', function(ntype, key, ...)
    if ntype == 'error' then pendingMount = nil end
    dnotify(ntype, key, ...)
end)

local curPlate = ''

local function plateOf(veh)
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        local p = GetVehicleNumberPlateText(veh)
        if p then
            p = p:gsub('%s+', '')
            if p ~= '' then return p end
        end
    end
    return nil
end

local function refreshPlate(veh)
    local p = plateOf(veh or GetVehiclePedIsIn(PlayerPedId(), false))
    if p then curPlate = p end
    return curPlate
end

RegisterNetEvent('sm_ecutuning:openGranted', function(plate)
    curPlate = plate or ''
    TriggerTokenEvent('sm_ecutuning:dyno:lastRun', curPlate)
    TriggerTokenEvent('sm_ecutuning:dyno:request')
end)

local refCurve, refPs, refNm, showRef = nil, 0, 0, false

local lastLocal = nil

RegisterNetEvent('sm_ecutuning:dyno:lastRunResult', function(row)
    if not row and lastLocal and lastLocal.plate ~= ''
       and lastLocal.plate == curPlate then
        row = {
            ps    = lastLocal.ps,    nm    = lastLocal.nm,
            psrpm = lastLocal.psRpm, nmrpm = lastLocal.nmRpm,
            model = lastLocal.model, curve = lastLocal.curve,
        }
        dnui({ type = 'dynoLastRun', has = true,
               ps = row.ps, nm = row.nm,
               psRpm = row.psrpm, nmRpm = row.nmrpm,
               model = row.model, boost = lastLocal.boost,
               curve = row.curve, base = lastLocal.base,
               hasCurve = row.curve ~= nil })
        refCurve, refPs, refNm = row.curve, row.ps, row.nm
        return
    end

    refCurve = row and row.curve or nil
    refPs    = row and row.ps or 0
    refNm    = row and row.nm or 0
    dnui({ type = 'dynoLastRun', has = row ~= nil, ps = refPs, nm = refNm,
           psRpm = row and row.psrpm or nil,
           nmRpm = row and row.nmrpm or nil,
           model = row and row.model or nil,
           curve = refCurve,
           hasCurve = refCurve ~= nil })
end)

RegisterCommand('hrs_dyno_compare', function()
    if not mounted then return end
    if not refCurve then
        dnotify('warn', 'dyno_no_ref')
        return
    end
    showRef = not showRef
    dnui({ type = 'dynoRef', show = showRef, curve = showRef and refCurve or nil,
           ps = refPs, nm = refNm })
    dnotify('info', showRef and 'dyno_ref_on' or 'dyno_ref_off')
end, false)

RegisterKeyMapping('hrs_dyno_compare', 'Dyno: show previous run', 'keyboard', 'J')

local remoteDynos = {}

local function resolveRemote(netId, d)
    local ent = d.ent
    if ent and ent ~= 0 and DoesEntityExist(ent) then return ent end

    local now = GetGameTimer()
    if (now - (d.lastLookup or 0)) < 1000 then return nil end
    d.lastLookup = now

    if NetworkDoesNetworkIdExist(netId) then
        local veh = NetworkGetEntityFromNetworkId(netId)
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            d.ent, d.missSince = veh, nil
            return veh
        end
    end

    d.ent = nil
    d.missSince = d.missSince or now
    if (now - d.missSince) > 10000 then remoteDynos[netId] = nil end
    return nil
end

local function releaseAllRemote()
    for netId, d in pairs(remoteDynos) do
        local veh = d.ent
        if (not veh or not DoesEntityExist(veh)) and NetworkDoesNetworkIdExist(netId) then
            veh = NetworkGetEntityFromNetworkId(netId)
        end
        do
            if veh and veh ~= 0 and DoesEntityExist(veh) then
                SetEntityCollision(veh, true, true)
                if SetEntityHasGravity then SetEntityHasGravity(veh, true) end
                if SetVehicleGravity   then SetVehicleGravity(veh, true)   end
            end
        end
    end
    remoteDynos = {}
end

RegisterNetEvent('sm_ecutuning:dyno:remoteState', function(src, netId, active, wheels)
    if src == GetPlayerServerId(PlayerId()) then return end

    if active then
        remoteDynos[netId] = { wheels = wheels or { 0, 1, 4, 5 }, rpm = 0.0 }

        CreateThread(function()
            local tries  = 0
            local misses = 0

            while tries < 40 and misses < 3 and remoteDynos[netId] do
                local d   = remoteDynos[netId]
                local veh = d and d.ent
                if (not veh or not DoesEntityExist(veh)) and NetworkDoesNetworkIdExist(netId) then
                    veh = NetworkGetEntityFromNetworkId(netId)
                end

                if veh and veh ~= 0 and DoesEntityExist(veh) then
                    misses = 0
                    if d then d.ent = veh end

                    if DisableVehicleWorldCollision then
                        DisableVehicleWorldCollision(veh)
                    end
                    return
                else
                    misses = misses + 1
                end

                tries = tries + 1
                Wait(250)
            end
        end)
    else
        local stopped = remoteDynos[netId]
        if stopped and HRS_DynoRollers then HRS_DynoRollers.stop(stopped.ent) end
        if NetworkDoesNetworkIdExist(netId) then
            local veh = NetworkGetEntityFromNetworkId(netId)
            if veh and veh ~= 0 and DoesEntityExist(veh) then
                SetEntityCollision(veh, true, true)
                if SetEntityHasGravity then SetEntityHasGravity(veh, true) end
                if SetVehicleGravity   then SetVehicleGravity(veh, true)   end
            end
        end
        remoteDynos[netId] = nil
        if scr.dui then screenSend({ type = 'idle' }) end
    end
end)

local function onRemoteData(netId, rpm, payload)
    local d = remoteDynos[netId]
    if not d and payload and type(payload.rollerWheels) == 'table' then
        d = { wheels = payload.rollerWheels, rpm = 0.0 }
        remoteDynos[netId] = d
    end
    if d then
        d.rpm = rpm
        d.frontSurfaceSpeed = payload and payload.rollerFront or nil
        d.rearSurfaceSpeed = payload and payload.rollerRear or nil
        d.lastRollerPacket = GetGameTimer()
    end

    if payload and scr.dui then screenSend(payload) end
end

AddStateBagChangeHandler('hrsDynoLive', nil, function(bagName, _, value)
    if type(value) ~= 'table' then return end
    local netId = tonumber(bagName:match('entity:(%d+)'))
    if not netId or not NetworkDoesNetworkIdExist(netId) then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) == PlayerPedId() then return end
    local rpm = tonumber(value.r) or 0.0
    if rpm < 0.0 then rpm = 0.0 elseif rpm > 1.2 then rpm = 1.2 end
    onRemoteData(netId, rpm, type(value.p) == 'table' and value.p or nil)
end)

CreateThread(function()
    while true do
        local any = next(remoteDynos) ~= nil
        Wait(any and 0 or 700)

        if any then
            local minRpm = ECUConfig.Dyno.WheelMinRpm or 0.25
            local factor = ECUConfig.Dyno.WheelSpeedFactor or 44.1

            for netId, d in pairs(remoteDynos) do
                local veh = resolveRemote(netId, d)
                if veh then
                    SetVehicleCurrentRpm(veh, d.rpm)

                    if SetVehicleWheelRotationSpeed then
                        local wspd = (d.rpm > minRpm) and -factor * d.rpm or 0.0
                        for _, i in ipairs(d.wheels or { 0, 1, 4, 5 }) do
                            SetVehicleWheelRotationSpeed(veh, i, wspd)
                        end
                    end
                    if HRS_DynoRollers then
                        local fresh = GetGameTimer() - (d.lastRollerPacket or 0) < 1500
                        local front, rear = 0.0, 0.0
                        if fresh and d.rpm > minRpm then
                            front, rear = HRS_DynoRollers.speed(veh, d.wheels, -factor * d.rpm)
                            if d.frontSurfaceSpeed ~= nil then
                                front, rear = d.frontSurfaceSpeed, d.rearSurfaceSpeed or 0.0
                            end
                        end
                        HRS_DynoRollers.drive(veh, front, rear)
                    end
                end
            end
        end
    end
end)


local function requestSyncUntilAnswered(tries)
    tries = tries or 0
    if gotSync or tries >= 12 then return end
    TriggerTokenEvent('sm_ecutuning:dyno:request')
    Citizen.SetTimeout(2500, function() requestSyncUntilAnswered(tries + 1) end)
end

AddEventHandler('onClientResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(1500)
    requestSyncUntilAnswered()
end)

AddEventHandler('playerSpawned', function()
    releaseAllRemote()
    gotSync = false
    requestSyncUntilAnswered()
end)

AddEventHandler('onClientResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    releaseAllRemote()
    clearBlips()
    for _, set in pairs(spawnedProps) do destroySet(set) end
    if placing then
        if placing.ghost and DoesEntityExist(placing.ghost) then DeleteEntity(placing.ghost) end
        destroySet(placing.solid)
    end
end)

local TXD_NAME, TEX_NAME = 'hrs_dyno_scr_txd', 'hrs_dyno_scr_tex'

local function scrCfg()
    return ECUConfig.Dyno.Screen or {}
end

local function screenEnabled()
    return scrCfg().enabled == true
end

local function screenModel()
    return scrCfg().model or 'hrs_dyno'
end

local function screenTargets()
    local c = scrCfg()
    if type(c.targets) == 'table' and #c.targets > 0 then
        local out = {}
        for _, t in ipairs(c.targets) do
            out[#out + 1] = {
                model   = t.model or screenModel(),
                mode    = t.mode or c.mode or 'texture',
                texture = t.texture,
                target  = t.target or 'hrs_dyno_screen',
            }
        end
        return out
    end
    return { {
        model   = screenModel(),
        mode    = c.mode or 'texture',
        texture = c.texture or 'image_0',
        target  = c.target or 'hrs_dyno_screen',
    } }
end

local function startScreen()
    if scr.dui or not screenEnabled() then return end

    local res = GetCurrentResourceName()
    scr.dui = CreateDui('nui://' .. res .. '/interface/sm_ecutuning/web/build/screen.html', 1280, 720)
    if not scr.dui then
        print('^1[Debug Dyno]^7 screen DUI could not be created.')
        return
    end

    scr.txd = CreateRuntimeTxd(TXD_NAME)
    scr.tex = CreateRuntimeTextureFromDuiHandle(scr.txd, TEX_NAME, GetDuiHandle(scr.dui))

    local L = scrCfg().layout or {}
    screenSendRaw({
        type = 'layout',
        flipX = L.flipX, flipY = L.flipY,
        zoom  = L.zoom, offX = L.offX, offY = L.offY, bg = L.bg,
    })

    scr.rt = {}
    for _, t in ipairs(screenTargets()) do
        if t.mode == 'rendertarget' then
            local hash = GetHashKey(t.model)
            if not IsNamedRendertargetRegistered(t.target) then
                RegisterNamedRendertarget(t.target, false)
            end
            if not IsNamedRendertargetLinked(hash) then
                LinkNamedRendertarget(hash)
            end
            if IsNamedRendertargetRegistered(t.target) then
                scr.rt[#scr.rt + 1] = {
                    name = t.target,
                    id   = GetNamedRendertargetRenderId(t.target),
                }
            else
                print(('^1[Debug Dyno]^7 render target "%s" could not be created.'):format(t.target))
            end
        elseif t.texture then
            AddReplaceTexture(t.model, t.texture, TXD_NAME, TEX_NAME)
            scr.replaced = true
        end
    end
end

local function stopScreen()
    if scr.replaced then
        for _, t in ipairs(screenTargets()) do
            if t.mode ~= 'rendertarget' and t.texture then
                RemoveReplaceTexture(t.model, t.texture)
            end
        end
        scr.replaced = false
    end
    for _, r in ipairs(scr.rt or {}) do
        if IsNamedRendertargetRegistered(r.name) then
            ReleaseNamedRendertarget(r.name)
        end
    end
    scr.rt = {}
    if scr.dui then
        DestroyDui(scr.dui)
        scr.dui, scr.txd, scr.tex = nil, nil, nil
    end
end

local function nearestScreen(coords)
    local maxD = scrCfg().distance or 40.0
    local want = {}
    for _, t in ipairs(screenTargets()) do want[t.model] = true end

    for _, d in ipairs(placedDynos) do
        for _, pr in ipairs(d.props or {}) do
            if want[pr.model] and #(coords - vector3(pr.x, pr.y, pr.z)) < maxD then
                return true
            end
        end
    end
    return false
end

CreateThread(function()
    while true do
        local sleep = 900

        if screenEnabled() and #placedDynos > 0 then
            local near = nearestScreen(GetEntityCoords(PlayerPedId()))
            if near and not scr.dui then
                startScreen()
                screenSend({ type = 'idle' })
            elseif not near and scr.dui then
                stopScreen()
            end
        elseif scr.dui then
            stopScreen()
        end

        if scr.dui and scr.rt and #scr.rt > 0 then
            sleep = 0
            for _, r in ipairs(scr.rt) do
                SetTextRenderId(r.id)
                Set_2dLayer(4)
                SetScriptGfxDrawBehindPausemenu(true)
                DrawSprite(TXD_NAME, TEX_NAME, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
                SetTextRenderId(GetDefaultScriptRendertargetRenderId())
                SetScriptGfxDrawBehindPausemenu(false)
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onClientResourceStop', function(res)
    if res == GetCurrentResourceName() then stopScreen() end
end)

local AXES = {
    { name = 'X', dir = vector3(1.0, 0.0, 0.0), r = 235, g =  70, b =  70 },
    { name = 'Y', dir = vector3(0.0, 1.0, 0.0), r =  90, g = 220, b = 110 },
    { name = 'Z', dir = vector3(0.0, 0.0, 1.0), r =  80, g = 160, b = 255 },
}

local GIZMO_SCALE = 0.16
local GIZMO_MIN   = 0.8
local GIZMO_MAX   = 5.0
local HIT_RADIUS  = 0.055

local function drawThickAxis(o, tip, ax, thick)
    local up = (math.abs(ax.dir.z) > 0.9) and vector3(1.0, 0.0, 0.0) or vector3(0.0, 0.0, 1.0)
    local p1 = vector3(ax.dir.y * up.z - ax.dir.z * up.y,
                       ax.dir.z * up.x - ax.dir.x * up.z,
                       ax.dir.x * up.y - ax.dir.y * up.x)
    local l1 = math.sqrt(p1.x * p1.x + p1.y * p1.y + p1.z * p1.z)
    if l1 < 0.0001 then l1 = 1.0 end
    p1 = vector3(p1.x / l1, p1.y / l1, p1.z / l1)
    local p2 = vector3(ax.dir.y * p1.z - ax.dir.z * p1.y,
                       ax.dir.z * p1.x - ax.dir.x * p1.z,
                       ax.dir.x * p1.y - ax.dir.y * p1.x)

    for i = -1, 1 do
        for j = -1, 1 do
            local ox = (p1.x * i + p2.x * j) * thick
            local oy = (p1.y * i + p2.y * j) * thick
            local oz = (p1.z * i + p2.z * j) * thick
            DrawLine(o.x + ox, o.y + oy, o.z + oz,
                     tip.x + ox, tip.y + oy, tip.z + oz,
                     ax.r, ax.g, ax.b, 255)
        end
    end
end

local function screenOf(p)
    local ok, sx, sy = GetScreenCoordFromWorldCoord(p.x, p.y, p.z)
    if not ok then return nil end
    return { x = sx, y = sy }
end

local function axisLabel(txt, sx, sy, active)
    SetTextFont(4) SetTextScale(0.34, 0.34)
    if active then SetTextColour(255, 255, 255, 255) else SetTextColour(210, 210, 210, 160) end
    SetTextOutline() SetTextCentre(true)
    SetTextEntry('STRING') AddTextComponentString(txt)
    DrawText(sx, sy - 0.014)
end

---@param list table[]
local function copyStaticSnippet(list)
    local lines = { '        {' }
    for i = 1, #list do
        local p = list[i]
        lines[#lines + 1] = ('            { model = %q, x = %.4f, y = %.4f, z = %.4f, h = %.4f%s },'):format(
            p.model, p.x, p.y, p.z, p.rz or 0.0, p.isdyno == 1 and ', isDyno = true' or '')
    end
    lines[#lines + 1] = '        },'
    lib.setClipboard(table.concat(lines, '\n'))
    lib.notify({ type = 'success', title = 'Dyno Static', description = 'Config disalin ke clipboard. Tempel ke ECUConfig.Dyno.Static.list.' })
end

local function startPlacing(editMode, staticMode)
    if placing then return end
    if not staticMode then
        if not ownState.owns then dnotify('error', 'dyno_not_owned') return end
        if not editMode and not ownState.stored then
            dnotify('error', 'dyno_already_placed') return
        end
        if editMode and ownState.stored then
            dnotify('error', 'dyno_not_placed') return
        end
    end

    local range = ECUConfig.Dyno.EditRange or 15.0
    if editMode and not staticMode and range > 0 then
        local me   = GetEntityCoords(PlayerPedId())
        local nah  = false
        local weit = nil

        for _, d in ipairs(placedDynos) do
            if d.owner == ownState.owner then
                for _, pr in ipairs(d.props or {}) do
                    local dist = #(me - vector3(pr.x, pr.y, pr.z))
                    if not weit or dist < weit then weit = dist end
                    if dist <= range then nah = true break end
                end
            end
            if nah then break end
        end

        if not nah then
            dnotify('warn', 'dyno_edit_far', math.floor(weit or 0))
            return
        end
    end

    local defs = ECUConfig.Dyno.Props
    local ped  = PlayerPedId()
    local pc   = GetEntityCoords(ped)
    local fwd  = GetEntityForwardVector(ped)

    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, pc.x - fwd.x * 6.0, pc.y - fwd.y * 6.0, pc.z + 4.0)
    SetCamRot(cam, -20.0, 0.0, GetEntityHeading(ped), 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 400, true, true)

    local preset = nil
    if editMode and not staticMode then
        for _, d in ipairs(placedDynos) do
            if d.owner == ownState.owner then preset = d.props break end
        end
    end

    placing = {
        edit   = editMode == true,
        static = staticMode == true,
        preset = preset,
        idx    = 1,
        result = {},
        solid  = {},
        ghost  = nil,
        pos    = vector3(pc.x + fwd.x * 4.0, pc.y + fwd.y * 4.0, pc.z - 0.95),
        rot    = vector3(0.0, 0.0, GetEntityHeading(ped)),
        mode   = 'move',
        drag   = nil,
        cam    = cam,
        camRot = vector3(-20.0, 0.0, GetEntityHeading(ped)),
    }

    if preset and preset[1] then
        local q = preset[1]
        SetCamCoord(cam, q.x - fwd.x * 6.0, q.y - fwd.y * 6.0, q.z + 4.0)
    end

    dnui({ type = 'dynoPlace', show = true, idx = 1, total = #defs,
           model = defs[1].model, mode = 'move' })

    CreateThread(function()
        while placing do
            Wait(0)
            local def = defs[placing.idx]
            if not def then break end

            local pl = placing
            FreezeEntityPosition(PlayerPedId(), true)

            if pl.preset and pl.preset[pl.idx] and not pl.loaded then
                local q = pl.preset[pl.idx]
                pl.pos = vector3(q.x, q.y, q.z)
                pl.rot = vector3(q.rx or 0.0, q.ry or 0.0, q.rz or 0.0)
                pl.loaded = true
                if pl.ghost and DoesEntityExist(pl.ghost) then
                    DeleteEntity(pl.ghost)
                    pl.ghost = nil
                end
            end

            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)

            local look = IsDisabledControlPressed(0, 25)
            if look then
                local mx = GetDisabledControlNormal(0, 1) * 8.0
                local my = GetDisabledControlNormal(0, 2) * 8.0
                pl.camRot = vector3(
                    math.max(-89.0, math.min(89.0, pl.camRot.x - my)),
                    0.0,
                    (pl.camRot.z - mx) % 360.0)
                SetCamRot(pl.cam, pl.camRot.x, 0.0, pl.camRot.z, 2)
            else
                SetMouseCursorActiveThisFrame()
            end

            local spd = (ECUConfig.Dyno.CamSpeed or 0.35)
            if IsDisabledControlPressed(0, 21) then spd = spd * 3.0 end
            local cr  = pl.camRot
            local rz, rx = math.rad(cr.z), math.rad(cr.x)
            local cosX = math.abs(math.cos(rx))
            local f = vector3(-math.sin(rz) * cosX, math.cos(rz) * cosX, math.sin(rx))
            local rgt = vector3(math.cos(rz), math.sin(rz), 0.0)
            local cp = GetCamCoord(pl.cam)
            local mv = vector3(0.0, 0.0, 0.0)
            if IsDisabledControlPressed(0, 32) then mv = mv + f end
            if IsDisabledControlPressed(0, 33) then mv = mv - f end
            if IsDisabledControlPressed(0, 34) then mv = mv - rgt end
            if IsDisabledControlPressed(0, 35) then mv = mv + rgt end
            if IsDisabledControlPressed(0, 22) then mv = mv + vector3(0.0, 0.0, 1.0) end
            if IsDisabledControlPressed(0, 36) then mv = mv - vector3(0.0, 0.0, 1.0) end
            if #mv > 0.0 then
                SetCamCoord(pl.cam, cp.x + mv.x * spd, cp.y + mv.y * spd, cp.z + mv.z * spd)
            end

            local cur = { x = GetDisabledControlNormal(0, 239), y = GetDisabledControlNormal(0, 240) }
            local origin = pl.pos
            local oScr = screenOf(origin)
            local hover = nil

            local camPos = GetCamCoord(pl.cam)
            local camDist = #(camPos - origin)
            local glen = math.max(GIZMO_MIN, math.min(GIZMO_MAX, camDist * GIZMO_SCALE))
            local thick = glen * 0.022
            local ball  = glen * 0.13
            pl.glen = glen

            for i, ax in ipairs(AXES) do
                local tip = vector3(origin.x + ax.dir.x * glen,
                                    origin.y + ax.dir.y * glen,
                                    origin.z + ax.dir.z * glen)
                drawThickAxis(origin, tip, ax, thick)

                local tScr = screenOf(tip)
                local isHover = false
                if oScr and tScr and not look then
                    local dx, dy = cur.x - tScr.x, cur.y - tScr.y
                    local dist = math.sqrt(dx * dx + dy * dy)
                    if dist < HIT_RADIUS and (not hover or dist < hover.dist) then
                        hover = { i = i, dist = dist, tScr = tScr, oScr = oScr }
                    end
                end
                isHover = (hover and hover.i == i) or false

                local rad = isHover and (ball * 1.45) or ball
                DrawMarker(28, tip.x, tip.y, tip.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                           rad, rad, rad, ax.r, ax.g, ax.b,
                           isHover and 255 or 190, false, false, 2, false, nil, nil, false)

                if tScr then axisLabel(ax.name, tScr.x, tScr.y, isHover) end
            end

            DrawMarker(28, origin.x, origin.y, origin.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                       ball * 0.55, ball * 0.55, ball * 0.55, 255, 255, 255, 150,
                       false, false, 2, false, nil, nil, false)

            if pl.drag then
                if IsDisabledControlPressed(0, 24) then
                    local ax = AXES[pl.drag.axis]
                    local dx = cur.x - pl.drag.startCursor.x
                    local dy = cur.y - pl.drag.startCursor.y
                    local amount = (dx * pl.drag.sdx + dy * pl.drag.sdy)
                    if pl.mode == 'move' then
                        local w = amount * pl.drag.worldPerScreen
                        pl.pos = vector3(pl.drag.startPos.x + ax.dir.x * w,
                                         pl.drag.startPos.y + ax.dir.y * w,
                                         pl.drag.startPos.z + ax.dir.z * w)
                    else
                        local deg = amount * 400.0
                        local r = pl.drag.startRot
                        if pl.drag.axis == 1 then
                            pl.rot = vector3(math.max(-89.0, math.min(89.0, r.x + deg)), r.y, r.z)
                        elseif pl.drag.axis == 2 then
                            pl.rot = vector3(r.x, math.max(-89.0, math.min(89.0, r.y + deg)), r.z)
                        else
                            pl.rot = vector3(r.x, r.y, (r.z + deg) % 360.0)
                        end
                    end
                else
                    pl.drag = nil
                end
            elseif hover and IsDisabledControlJustPressed(0, 24) then
                local sdx = hover.tScr.x - hover.oScr.x
                local sdy = hover.tScr.y - hover.oScr.y
                local slen = math.sqrt(sdx * sdx + sdy * sdy)
                if slen > 0.0005 then
                    pl.drag = {
                        axis = hover.i,
                        startCursor = { x = cur.x, y = cur.y },
                        startPos = pl.pos, startRot = pl.rot,
                        sdx = sdx / slen, sdy = sdy / slen,
                        worldPerScreen = (pl.glen or 1.4) / slen,
                    }
                end
            end

            if IsDisabledControlJustPressed(0, 37) then
                pl.mode = (pl.mode == 'move') and 'rotate' or 'move'
                pl.drag = nil
                dnui({ type = 'dynoPlace', show = true, idx = pl.idx, total = #defs,
                       model = def.model, mode = pl.mode })
            end

            if pl.mode == 'rotate' then
                local step = IsDisabledControlPressed(0, 21) and 0.4 or 1.8
                if IsDisabledControlPressed(0, 44) then
                    pl.rot = vector3(pl.rot.x, pl.rot.y, (pl.rot.z - step) % 360.0)
                end
                if IsDisabledControlPressed(0, 38) then
                    pl.rot = vector3(pl.rot.x, pl.rot.y, (pl.rot.z + step) % 360.0)
                end
            end

            if not pl.ghost or not DoesEntityExist(pl.ghost) then
                pl.ghost = createProp(def.model, pl.pos, pl.rot, true)
            else
                local wp = applyOriginFix(def.model, pl.pos, pl.rot.z)
                SetEntityCoordsNoOffset(pl.ghost, wp.x, wp.y, wp.z, false, false, false)
                SetEntityRotation(pl.ghost, pl.rot.x, pl.rot.y, pl.rot.z, 2, true)
            end

            if IsDisabledControlJustPressed(0, 191) then
                pl.result[#pl.result + 1] = {
                    model = def.model,
                    x = pl.pos.x, y = pl.pos.y, z = pl.pos.z,
                    rx = pl.rot.x, ry = pl.rot.y, rz = pl.rot.z,
                    isdyno = def.isDyno and 1 or 0,
                }
                if pl.ghost and DoesEntityExist(pl.ghost) then
                    ResetEntityAlpha(pl.ghost)
                    SetEntityCollision(pl.ghost, true, true)
                    pl.solid[#pl.solid + 1] = pl.ghost
                end
                pl.ghost = nil
                pl.idx = pl.idx + 1

                if pl.idx > #defs then
                    local out, solid, camx = pl.result, pl.solid, pl.cam
                    placing = nil
                    RenderScriptCams(false, false, 400, true, true)
                    DestroyCam(camx, false)
                    FreezeEntityPosition(PlayerPedId(), false)
                    dnui({ type = 'dynoPlace', show = false })
                    destroySet(solid)
                    if pl.static then
                        copyStaticSnippet(out)
                        return
                    end
                    TriggerTokenEvent('sm_ecutuning:dyno:place', out, pl.edit)
                    return
                end

                pl.loaded = false
                if not (pl.preset and pl.preset[pl.idx]) then
                    pl.pos = vector3(pl.pos.x + 3.0, pl.pos.y, pl.pos.z)
                    pl.rot = vector3(0.0, 0.0, pl.rot.z)
                end
                pl.drag = nil
                dnui({ type = 'dynoPlace', show = true, idx = pl.idx, total = #defs,
                       model = defs[pl.idx].model, mode = pl.mode })

            elseif IsDisabledControlJustPressed(0, 194) then
                if pl.ghost and DoesEntityExist(pl.ghost) then DeleteEntity(pl.ghost) end
                destroySet(pl.solid)
                RenderScriptCams(false, false, 400, true, true)
                DestroyCam(pl.cam, false)
                FreezeEntityPosition(PlayerPedId(), false)
                placing = nil
                dnui({ type = 'dynoPlace', show = false })
                dnotify('info', 'dyno_place_cancel')
                return
            end
        end
    end)
end

local powerByHash = nil

local function buildPowerIndex()
    powerByHash = {}
    local n = 0
    for name, v in pairs(ECUConfig.Dyno.VehiclePower or {}) do
        powerByHash[GetHashKey(name)] = { name = name, ps = v.ps, nm = v.nm }
        n = n + 1
    end
    print(('^2[Debug Dyno]^7 %d vehicles loaded from ECUConfig.Dyno.VehiclePower'):format(n))
end

local warnedModels = {}

local solveRedline

function HRS_DynoRedline(vehicle)
    local ps, nm = HRS_DynoBasePower(vehicle)
    if not ps or not nm or nm <= 0 then return nil end
    local ok, v = pcall(solveRedline, ps, nm, ECUConfig.Dyno.ChartRpmMin or 1000)
    if not ok or not v then return nil end
    return math.floor(v / 100 + 0.5) * 100
end

function HRS_DynoBasePower(vehicle)
    if not powerByHash then buildPowerIndex() end
    local e = powerByHash[GetEntityModel(vehicle)]
    if e then return e.ps, e.nm, true end
    return ECUConfig.Dyno.Fallback.ps, ECUConfig.Dyno.Fallback.nm, false
end

local function basePowerOf(vehicle)
    if not powerByHash then buildPowerIndex() end

    local hash = GetEntityModel(vehicle)
    local e = powerByHash[hash]
    if e then
        return e.ps or ECUConfig.Dyno.Fallback.ps, e.nm or ECUConfig.Dyno.Fallback.nm, e.name, true
    end

    if not warnedModels[hash] then
        warnedModels[hash] = true
        local disp = GetDisplayNameFromVehicleModel(hash) or '?'
        print(('^3[Debug Dyno]^7 vehicle not in ECUConfig.Dyno.VehiclePower.')
            )
        print(('^3[Debug Dyno]^7   model hash: %d   display name: "%s"'):format(hash, disp))
        print( '^3[Debug Dyno]^7   add the spawn name, format:')
        print( '^3[Debug Dyno]^7   [\'spawnname\'] = { ps = 300, nm = 400 },')
    end
    return ECUConfig.Dyno.Fallback.ps, ECUConfig.Dyno.Fallback.nm,
           ('#' .. tostring(hash)), false
end

local function displayBoostOf(key)
    local h = HRSPerf.Hardware[key]
    if h then return h.reserve or 0 end
    if key == 'ecustage1' then return HRSPerf.Stages[1].basis end
    if key == 'ecustage2' then return HRSPerf.Stages[2].basis end
    if key == 'ecustage3' then return HRSPerf.Stages[3].basis end
    return 0
end

function HRS_DynoBoost()
    local pkg = HRS_PerfPackage and HRS_PerfPackage() or nil
    if pkg and pkg.gain then return pkg.gain end
    local parts = HRS_GetParts and HRS_GetParts() or {}
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    local ps, nm = 300, 400
    if veh ~= 0 and HRS_DynoBasePower then ps, nm = HRS_DynoBasePower(veh) end
    local p = HRSPerf.compute({ ps = ps, nm = nm, engine = 'turbo' }, parts, nil)
    return p.gain
end

function HRS_DynoPartList()
    local list = {}
    local parts = HRS_GetParts and HRS_GetParts() or nil
    if type(parts) == 'table' then
        for _, key in ipairs(parts) do
            local def = ECUConfig.Parts[key]
            local b   = displayBoostOf(key)
            if def and b > 0 then
                list[#list + 1] = { label = def.label, boost = b }
            end
        end
    end
    return list
end

local function partsBoostPercent()
    return HRS_DynoBoost()
end

local function unusedPartsBoost()
    if HRS_GetBoost then
        local b = HRS_GetBoost()
        if type(b) == 'number' then return b end
    end
    local total = 0
    local parts = HRS_GetParts and HRS_GetParts() or nil
    if type(parts) == 'table' then
        for _, key in ipairs(parts) do
            local def = ECUConfig.Parts[key]
            if def and def.boost then total = total + def.boost end
        end
    end
    return total
end

local TQ_RISE, TQ_PEAK, TQ_DROP = 0.30, 0.50, 0.28
local TQ_NORM = nil

local function torqueRaw(x)
    local rise = 1.0 - math.exp(-x / TQ_RISE)
    local over = math.max(0.0, (x - TQ_PEAK) / (1.0 - TQ_PEAK))
    return rise * (1.0 - TQ_DROP * over * over)
end

local function tempFactor(tempC)
    local H = ECUConfig.Dyno.Heat
    if not H or not H.enabled then return 1.0 end

    local lo, hi = H.windowMin or 90, H.windowMax or 115
    if tempC >= lo and tempC <= hi then return 1.0 end

    local TH   = ECUConfig.TurboHeat or {}
    local pMin = (H.penaltyMin or 5) / 100.0
    local pMax = (H.penaltyMax or 10) / 100.0

    local t
    if tempC < lo then
        local amb = TH.ambient or 30
        t = math.min(1.0, math.max(0.0, (lo - tempC) / math.max(1.0, lo - amb)))
    else
        local blow = TH.blowAt or 140
        t = math.min(1.0, math.max(0.0, (tempC - hi) / math.max(1.0, blow - hi)))
    end

    return 1.0 - (pMin + t * (pMax - pMin))
end

local function torqueFactor(rpm)
    local pkg = HRS_PerfPackage and HRS_PerfPackage() or nil
    if pkg and pkg.curve and pkg.curve.shaped then
        local x = math.max(0.0, math.min(1.0, rpm))
        if pkg.curve.rev and x > pkg.curve.rev then return 0.02 end
        return math.max(0.02, HRSPerf.torqueShapeForChart(pkg.curve, x))
    end
    if not TQ_NORM then
        TQ_NORM = 0.0
        for i = 0, 1000 do
            local v = torqueRaw(i / 1000)
            if v > TQ_NORM then TQ_NORM = v end
        end
    end
    local x = math.max(0.0, math.min(1.0, rpm))
    return math.max(0.02, torqueRaw(x) / TQ_NORM)
end

function solveRedline(ps, nm, idleRpm)
    if nm <= 0 or ps <= 0 then return 8000.0 end
    local target = 7023.5 * ps / nm
    local lo, hi = idleRpm + 500.0, 30000.0
    for _ = 1, 40 do
        local mid = (lo + hi) * 0.5
        local best = 0.0
        for i = 0, 100 do
            local x = i / 100
            local v = torqueFactor(x) * (idleRpm + (mid - idleRpm) * x)
            if v > best then best = v end
        end
        if best < target then lo = mid else hi = mid end
    end
    return (lo + hi) * 0.5
end

local function drivenWheels(vehicle)
    local bias = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveBiasFront') or 0.0
    local list = {}

    local wheelCount = GetVehicleNumberOfWheels(vehicle)
    for i = 0, wheelCount - 1 do
        local powered
        if bias <= 0.05 then
            powered = (i >= 2)
        elseif bias >= 0.95 then
            powered = (i <= 1)
        else
            powered = true
        end
        if powered then list[#list + 1] = i end
    end

    local name = (bias <= 0.05 and 'Heck') or (bias >= 0.95 and 'Front') or 'Allrad'
    return list, name
end

local function gearRatioOf(maxgear, gear)
    local set = ECUConfig.Dyno.GearRatios[maxgear] or ECUConfig.Dyno.GearRatios[6]
    local r = set[math.max(1, math.min(gear, #set))] or 1.0
    return r * (1.0 / 0.9)
end

local function gearMaxSpeed(maxFlatVel, ratio)
    return ((maxFlatVel * 1.32) / 3.6) / ratio
end

local function gearInertia(baseInertia, maxgear, ratio, onGas)
    local base = (baseInertia / math.max(maxgear, 1))
    local v = (base - (base / ratio)) + 0.04
    if onGas then v = v * (ECUConfig.Dyno.RevSpeed or 1.0) end
    return v
end

local function stopMount(silent)
    if not mounted then return end
    mounted = false
    if HRS_SetDynoMode then HRS_SetDynoMode(false) end

    local st0 = runState
    if st0 and HRS_DynoRollers then HRS_DynoRollers.stop(st0.veh) end
    if st0 and st0.veh and DoesEntityExist(st0.veh) then
        if Entity(st0.veh).state.hrsDynoLive then Entity(st0.veh).state:set('hrsDynoLive', nil, true) end
        local nid = NetworkGetNetworkIdFromEntity(st0.veh)
        if nid and nid ~= 0 then
            TriggerTokenEvent('sm_ecutuning:dyno:remoteState', nid, false)
        end
    end

    local st  = runState
    local veh = (st and st.veh) or GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 and DoesEntityExist(veh) then
        if st then
            if st.baseInertia then
                SetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveInertia', st.baseInertia)
            end
            if st.driveForce then
                SetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce', st.driveForce)
            end
            if st.maxFlatVel then
                SetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveMaxFlatVel', st.maxFlatVel)
            end
        end
        if SetVehiclePetrolTankHealth then SetVehiclePetrolTankHealth(veh, 1000.0) end

        SetVehicleHandbrake(veh, false)
        SetEntityCollision(veh, true, true)
        if SetEntityHasGravity then SetEntityHasGravity(veh, true) end
        if SetVehicleGravity   then SetVehicleGravity(veh, true)   end
        FreezeEntityPosition(veh, false)
        if SetVehicleOnGroundProperly then SetVehicleOnGroundProperly(veh) end
        SetVehicleEngineOn(veh, true, true, false)
    end
    runState = nil
    HRS_DynoHeatActive = false
    showRef = false
    dnui({ type = 'dynoRef', show = false })
    dnui({ type = 'dynoPrompt', show = false })
    dnui({ type = 'dynoRun', show = false })
    screenSend({ type = 'idle' })
    if not silent then dnotify('info', 'dyno_left') end
end

local function mountConfigured(dyno)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return end
    if GetPedInVehicleSeat(veh, -1) ~= ped then
        dnotify('error', 'dyno_need_driver') return
    end

    local c, h = GetEntityCoords(veh), GetEntityHeading(veh)
    local snap = ECUConfig.Dyno.MountSnap

    if snap and snap.enabled and dyno then
        for _, pr in ipairs(dyno.props or {}) do
            if pr.isdyno == 1 or pr.isdyno == true then
                local off = snap.offset or vector3(0.0, 0.0, 0.0)
                local r   = math.rad(pr.rz or 0.0)
                local cs, sn = math.cos(r), math.sin(r)
                c = vector3(pr.x + (off.x * cs - off.y * sn),
                            pr.y + (off.x * sn + off.y * cs),
                            pr.z + off.z)
                h = ((pr.rz or 0.0) + (snap.heading or 0.0)) % 360.0
                break
            end
        end
    end

    local lift = ECUConfig.Dyno.LiftHeight or 0.01

    if snap and snap.enabled then
        local mn = GetModelDimensions(GetEntityModel(veh))
        lift = lift + ((mn and math.abs(mn.z)) or 0.0)
    end

    SetEntityCoordsNoOffset(veh, c.x, c.y, c.z + lift, false, false, false)
    SetEntityHeading(veh, h)

    SetVehicleUndriveable(veh, false)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleHandbrake(veh, false)

    if DisableVehicleWorldCollision then
        DisableVehicleWorldCollision(veh)
    else
        SetEntityCollision(veh, false, true)
    end
    FreezeEntityPosition(veh, true)

    if SetEntityHasGravity then SetEntityHasGravity(veh, false) end
    if SetVehicleGravity   then SetVehicleGravity(veh, false)   end

    SetVehicleHandbrake(veh, true)

    local gearsOfCar = (GetVehicleHandlingInt
        and GetVehicleHandlingInt(veh, 'CHandlingData', 'nInitialDriveGears'))
        or ECUConfig.Dyno.GearCount or 6

    local hMaxFlatVel = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveMaxFlatVel') or 40.0
    local hDriveForce = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce') or 0.3
    local hInertia    = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveInertia') or 1.0

    if SetVehicleCheatPowerIncrease then SetVehicleCheatPowerIncrease(veh, 1.0) end
    if ModifyVehicleTopSpeed        then ModifyVehicleTopSpeed(veh, 1.0)        end

    local wheels, driveName = drivenWheels(veh)
    local basePs, baseNm, model, known = basePowerOf(veh)
    local boost   = partsBoostPercent()
    local mult    = 1.0 + boost / 100.0
    local finalPs = math.floor(basePs * mult)
    local finalNm = math.floor(baseNm * mult)

    mounted = true
    refreshPlate(veh)

    if not NetworkGetEntityIsNetworked(veh) then NetworkRegisterEntityAsNetworked(veh) end
    local nid = NetworkGetNetworkIdFromEntity(veh)
    if nid and nid ~= 0 then
        TriggerTokenEvent('sm_ecutuning:dyno:remoteState', nid, true, wheels)
    end
    runState = {
        veh = veh, model = model,
        anchor = vector3(c.x, c.y, c.z + lift), heading = h,
        basePs = basePs, baseNm = baseNm, boost = boost,
        finalPs = finalPs, finalNm = finalNm, known = known,
        rpm = 0.0, gear = 0, phase = 'idle',
        heat = math.max(
            (ECUConfig.Dyno.Heat and ECUConfig.Dyno.Heat.idleTemp) or 60,
            (type(HRS_GetTurboHeat) == 'function' and HRS_GetTurboHeat() or 0)
        ),
        origEngineHealth = GetVehicleEngineHealth(veh),
        popBlocked = false,
        buckets = {},
        engineMode = ECUConfig.Dyno.EngineMode or 'native',
        rot = GetEntityRotation(veh, 2),
        topSpeed = (GetVehicleEstimatedMaxSpeed and GetVehicleEstimatedMaxSpeed(veh)) or 60.0,
        gearMax = gearsOfCar,
        maxFlatVel = hMaxFlatVel, driveForce = hDriveForce, baseInertia = hInertia,
        idleRpm = ECUConfig.Dyno.ChartRpmMin or 1000,
        rpmIdle = math.max(0.05, math.min(0.5, GetVehicleCurrentRpm(veh) or 0.2)),
        redline = solveRedline(finalPs, finalNm, ECUConfig.Dyno.ChartRpmMin or 1000),
        gasSince = 0, warned = false,
        wheels = wheels, drive = driveName,
        peakPs = 0, peakNm = 0, samples = {},
    }

    dnui({ type = 'dynoRun', show = true, model = model, boost = boost,
           base = basePs, baseNm = baseNm, known = known, drive = driveName,
           measureGear = math.max(1, math.min(ECUConfig.Dyno.MeasureGear or 3, gearsOfCar)) })
    dnotify('info', 'dyno_mounted')
end

local function requestUseOrMount(dyno)
    pendingMount = dyno
    TriggerTokenEvent('sm_ecutuning:dyno:requestUse', dyno.owner)
end

---@return boolean
local function canUseDyno()
    local mode = ECUConfig.Dyno.UseAccess
    if mode == nil or mode == 'all' then return true end

    local job = QBPlayerData.job
    local name = job and job.name
    if not name then return false end
    if ECUConfig.Dyno.UseJobs and ECUConfig.Dyno.UseJobs[name] then return true end

    local mech = ECUConfig.MechanicJobs
    for i = 1, #mech do
        if mech[i] == name then return true end
    end
    return false
end

startMount = mountConfigured

startSetup = function(dyno)
    if HRS_DynoRollers and (ECUConfig.Dyno.Rollers or {}).enabled ~= false then
        if HRS_DynoRollers.isSettingUp() then return end
        local ped=PlayerPedId()
        local veh=GetVehiclePedIsIn(ped,false)
        if veh==0 or GetPedInVehicleSeat(veh,-1) ~= ped then
            dnotify('error','dyno_need_driver');return
        end
        if not HRS_DynoRollers.beginSetup(veh,function() requestUseOrMount(dyno) end) then
            dnotify('error','dyno_rollers_loading')
        end
    else
        requestUseOrMount(dyno)
    end
end

local function finishRun(s)
    s.phase = 'done'
    local ps2, nm2 = math.floor(s.peakPs + 0.5), math.floor(s.peakNm + 0.5)

    local rMin = s.idleRpm or 1000
    local rMax = s.redline or 8000
    local pAt, nAt, bestP, bestN = rMin, rMin, -1, -1
    for _, sm in ipairs(s.samples) do
        if sm.p > bestP then bestP, pAt = sm.p, (sm.a or rMin) end
        if sm.n > bestN then bestN, nAt = sm.n, (sm.a or rMin) end
    end

    dnui({
        type = 'dynoResult', ps = ps2, nm = nm2, model = s.model, boost = s.boost,
        drive = s.drive, gears = s.gearMax,
        psRpm = math.floor(pAt), nmRpm = math.floor(nAt),
        curve = s.samples, rpmMin = rMin, rpmMax = rMax,
    })
    local menuCurve = {}
    for _, sm in ipairs(s.samples or {}) do
        menuCurve[#menuCurve + 1] = {
            r = math.floor((sm.r or 0) * 1000) / 1000,
            p = math.floor(sm.p or 0),
            n = math.floor(sm.n or 0),
        }
    end

    dnui({ type = 'dynoLastRun', has = true, ps = ps2, nm = nm2,
           psRpm = math.floor(pAt), nmRpm = math.floor(nAt),
           model = s.model, boost = s.boost,
           curve = menuCurve, base = s.basePs })
    local slim = {}
    for _, sm in ipairs(s.samples or {}) do
        slim[#slim + 1] = {
            r = math.floor((sm.r or 0) * 1000) / 1000,
            p = math.floor(sm.p or 0),
            n = math.floor(sm.n or 0),
        }
    end
    local savePlate = plateOf(s.veh) or curPlate
    if savePlate ~= '' then curPlate = savePlate end
    lastLocal = {
        plate = savePlate, ps = ps2, nm = nm2,
        psRpm = math.floor(pAt), nmRpm = math.floor(nAt),
        model = s.model, boost = s.boost,
        base  = s.basePs, curve = menuCurve,
    }
    local partList = (type(HRS_DynoPartList) == 'function') and HRS_DynoPartList() or nil

    TriggerTokenEvent('sm_ecutuning:dyno:saveResult', s.model, ps2, nm2, savePlate, slim,
        math.floor(pAt), math.floor(nAt), partList)
    dnotify('success', 'dyno_done')

    interface.focus(true, true)
end

interface.callback('dynoResultClose', function(_, cb)
    interface.focus(false, false)
    cb('ok')
end)

local function tickRun(dt)
    local s = runState
    if not s or not DoesEntityExist(s.veh) then stopMount(true) return end
    local veh = s.veh

    local gas = IsControlPressed(0, 71)

    if s.rot then
        SetEntityRotation(veh, s.rot.x, s.rot.y, s.rot.z, 2, true)
    end

    if s.engineMode == 'native' then
        s.rpm = GetVehicleCurrentRpm(veh) or 0.0

        if gas then
            if s.gasSince == 0 then s.gasSince = GetGameTimer() end
            if not s.warned and s.rpm < 0.30 and (GetGameTimer() - s.gasSince) > 2500 then
                s.warned = true
                print('^3[Debug Dyno]^7 rpm does not rise under full throttle.')
                print("^3[Debug Dyno]^7 falling back to ECUConfig.Dyno.EngineMode = 'simulated'.")
            end
        else
            s.gasSince = 0
        end
    else
        local up = (s.phase == 'measuring')
            and (1.0 / math.max(1.0, ECUConfig.Dyno.SweepTime or 6.0))
            or  ((ECUConfig.Dyno.RevUpRate or 0.32) / math.max(s.gear * 0.45, 1.0))
        local down = (ECUConfig.Dyno.RevDownRate or 0.45)
        if gas then
            s.rpm = math.min(1.0, s.rpm + up * dt)
        else
            s.rpm = math.max(0.0, s.rpm - down * dt)
        end
        SetVehicleCurrentRpm(veh, s.rpm)
    end

    local gmax  = math.max(s.gearMax or 6, 1)
    local ratio = gearRatioOf(gmax, math.max(s.gear or 1, 1))

    local neutralBoost = ((s.gear or 0) == 0)
        and (ECUConfig.Dyno.NeutralRevSpeed or 2.5) or 1.0
    s.gearMaxSpd = gearMaxSpeed(s.maxFlatVel or 40.0, ratio)
    s.flatSpeed  = (s.maxFlatVel or 40.0) / ratio

    local onGas = GetControlNormal(0, 71) > 0.05
    SetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveInertia',
        gearInertia(s.baseInertia or 1.0, gmax, ratio, onGas) * neutralBoost)

    local angularSpeed = 0.0
    if (s.gear or 0) > 0 and s.rpm > (ECUConfig.Dyno.WheelMinRpm or 0.25) then
        angularSpeed = -(ECUConfig.Dyno.WheelSpeedFactor or 44.1) * s.rpm
    end
    local rollerFront, rollerRear = 0.0, 0.0
    if HRS_DynoRollers then
        rollerFront, rollerRear = HRS_DynoRollers.speed(veh, s.wheels, angularSpeed)
        HRS_DynoRollers.drive(veh, rollerFront, rollerRear)
    end
    local netNow = GetGameTimer()
    if netNow - (s.lastNet or 0) > (ECUConfig.Dyno.NetRate or 120) then
        s.lastNet = netNow
        local nid = NetworkGetNetworkIdFromEntity(veh)
        if nid and nid ~= 0 then
            local payload = s.lastPayload or {}
            payload.rollerFront, payload.rollerRear = rollerFront, rollerRear
            payload.rollerWheels = s.wheels
            Entity(veh).state:set('hrsDynoLive', { r = ((s.gear or 0) > 0) and s.rpm or 0.0, p = payload }, true)
        end
    end

    if SetVehicleWheelRotationSpeed then
        local wspd = angularSpeed
        for _, i in ipairs(s.wheels) do
            SetVehicleWheelRotationSpeed(veh, i, wspd)
        end
    end

    do
        local blocked = GetControlNormal(0, 71) > 0.05
        if blocked ~= s.popBlocked then
            s.popBlocked = blocked
            if HRS_SetDynoMode then HRS_SetDynoMode(blocked) end
        end
    end

    local idle     = s.rpmIdle or 0.2
    local x        = math.max(0.0, math.min(1.0, (s.rpm - idle) / math.max(0.05, 1.0 - idle)))
    local throttle = GetControlNormal(0, 71)

    local H  = ECUConfig.Dyno.Heat
    local TH = ECUConfig.TurboHeat or {}
    if H and H.enabled then
        local oper = TH.operating or 90
        local load = throttle * math.max(s.rpm, 0.1)
        if load > 0.05 then
            s.heat = math.min(TH.blowAt or 140, s.heat + (H.upRate or 2.6) * load * dt)
        else
            s.heat = math.max(oper, s.heat - (H.coolRate or 3.2) * dt)
        end

        if TH.linkDyno and type(HRS_SetTurboHeat) == 'function' then
            HRS_DynoHeatActive = (s.phase == 'measuring')
            HRS_SetTurboHeat(s.heat)
        end

        if s.heat >= (TH.critAt or 130) then
            local hp = GetVehicleEngineHealth(veh) or 1000.0
            local nw = math.max(H.minHealth or 120.0, hp - (H.damageRate or 55.0) * dt)
            SetVehicleEngineHealth(veh, nw)

            if not s.heatWarned then
                s.heatWarned = true
                dnotify('error', 'dyno_overheat')
            end
        elseif s.heat < (TH.greenMax or 115) then
            s.heatWarned = false
        end
    end

    local rpmAbs   = (s.idleRpm or 1000) + ((s.redline or 8000) - (s.idleRpm or 1000)) * x

    local engaged = (s.gear or 0) > 0 and 1.0 or 0.0
    local nm = s.finalNm * torqueFactor(x) * throttle * engaged * tempFactor(s.heat)
    local ps = nm * rpmAbs / 7023.5
    s.curPs, s.curNm = ps, nm

    local now = GetGameTimer()

    if s.phase == 'done' then
        local endRpm = ECUConfig.Dyno.RunEndRpm or 2000
        local idleA  = s.idleRpm or 1000
        local redA   = s.redline or 8000
        local endX   = (endRpm - idleA) / math.max(1.0, redA - idleA)
        local endNorm = idle + (1.0 - idle) * math.max(0.0, math.min(1.0, endX))
        if s.rpm <= endNorm then
            s.phase   = 'idle'
            s.buckets = {}
            s.samples = {}
        end
    end

    if s.phase == 'measuring' then
        local nBuckets = ECUConfig.Dyno.ChartBuckets or 24
        if throttle > 0.1 and now - (s.lastSample or 0) > 30 then
            s.lastSample = now
            local idx = math.max(1, math.min(nBuckets, math.floor(x * (nBuckets - 1)) + 1))
            s.buckets[idx] = { r = (idx - 1) / (nBuckets - 1), p = ps, n = nm, a = rpmAbs }
        end

        if ps > s.peakPs then s.peakPs = ps end
        if nm > s.peakNm then s.peakNm = nm end

        if s.rpm > (s.rpmPeak or 0) + 0.005 then
            s.rpmPeak   = s.rpm
            s.rpmRoseAt = now
        elseif s.rpmRoseAt and (now - s.rpmRoseAt) > 4000 and #(s.samples or {}) > 3 then
            finishRun(s)
        end

        local curve = {}
        for i = 1, nBuckets do
            if s.buckets[i] then curve[#curve + 1] = s.buckets[i] end
        end
        s.samples = curve

        if s.rpm >= 0.98 then finishRun(s) end

    elseif s.phase ~= 'done' then
        s.buckets = {}
        s.samples = {}
    end

    local kmh = ((s.gear or 0) > 0)
        and (((s.flatSpeed or 40.0) * 1.2 / 0.9) * s.rpm) or 0.0

    if netNow - (s.lastScr or 0) > 90 then
        s.lastScr = netNow
        local payload = {
            type = 'live', model = s.model, drive = s.drive, phase = s.phase,
            gear = ((s.gear or 0) > 0) and s.gear or 'N',
            ps = math.floor((s.curPs or 0) + 0.5),
            nm = math.floor((s.curNm or 0) + 0.5),
            kmh = math.floor(kmh + 0.5),
            heat     = math.floor((s.heat or 0) + 0.5),
            heatLo   = (ECUConfig.TurboHeat and ECUConfig.TurboHeat.ambient) or 30,
            heatWarn = (ECUConfig.TurboHeat and ECUConfig.TurboHeat.greenMax) or 115,
            heatMax  = (ECUConfig.TurboHeat and ECUConfig.TurboHeat.blowAt) or 140,
            heatWin  = { ECUConfig.Dyno.Heat.windowMin or 90, ECUConfig.Dyno.Heat.windowMax or 115 },
            heatOk   = (s.heat >= (ECUConfig.Dyno.Heat.windowMin or 90)
                        and s.heat <= (ECUConfig.Dyno.Heat.windowMax or 115)),
            curve = s.samples,
            scalePs = math.ceil((s.finalPs or 300) / 50) * 50,
            scaleNm = math.ceil((s.finalNm or 400) / 50) * 50,
            rpmMin = s.idleRpm, rpmMax = s.redline,
            window = ECUConfig.Dyno.LiveWindow or 8000,
            brand  = ECUConfig.Dyno.Screen and ECUConfig.Dyno.Screen.brand or nil,
            ref    = showRef and refCurve or nil,
        }
        if scr.dui then screenSend(payload) end
        s.lastPayload = payload
    end

    dnui({
        type = 'dynoLive', rpm = s.rpm, phase = s.phase,
        gear = ((s.gear or 0) > 0) and s.gear or 'N',
        gearMax = s.gearMax, kmh = math.floor(kmh + 0.5),
        heat     = math.floor((s.heat or 0) + 0.5),
        heatLo   = (ECUConfig.TurboHeat and ECUConfig.TurboHeat.ambient) or 30,
        heatWarn = (ECUConfig.TurboHeat and ECUConfig.TurboHeat.greenMax) or 115,
        heatMax  = (ECUConfig.TurboHeat and ECUConfig.TurboHeat.blowAt) or 140,
        heatWin  = { ECUConfig.Dyno.Heat.windowMin or 90, ECUConfig.Dyno.Heat.windowMax or 115 },
        heatOk   = (s.heat >= (ECUConfig.Dyno.Heat.windowMin or 90)
                    and s.heat <= (ECUConfig.Dyno.Heat.windowMax or 115)),
        rpmMin = s.idleRpm, rpmMax = s.redline,
        scalePs = math.ceil((s.finalPs or 300) / 50) * 50,
        scaleNm = math.ceil((s.finalNm or 400) / 50) * 50,
        window  = ECUConfig.Dyno.LiveWindow or 8000,
        ps = math.floor((s.curPs or 0) + 0.5),
        nm = math.floor((s.curNm or 0) + 0.5),
        curve = s.samples,
    })
end

CreateThread(function()
    local last = GetGameTimer()
    while true do
        local ped = PlayerPedId()
        local sleep = 500
        local wantPrompt = false

        if HRS_DynoRollers and HRS_DynoRollers.isSettingUp() then
            sleep = 0
            last = GetGameTimer()
        elseif mounted then
            sleep = 0
            local now = GetGameTimer()
            local dt  = math.min((now - last) / 1000.0, 0.1)
            last = now

            tickRun(dt)
            local K = ECUConfig.Dyno.Keys

            if IsControlJustPressed(0, K.mount) or IsControlJustPressed(0, K.stop) then
                stopMount(false)
            end

            if runState and runState.veh and DoesEntityExist(runState.veh) then
                local rs   = runState
                local gmax = math.max(rs.gearMax or 6, 1)
                local ng   = nil
                if IsControlJustPressed(0, K.gearUp) and rs.gear < gmax then
                    ng = rs.gear + 1
                elseif IsControlJustPressed(0, K.gearDown) and rs.gear > 1 then
                    ng = rs.gear - 1
                end
                if ng then
                    local wheelSpd   = (rs.gearMaxSpd or 1.0) * rs.rpm
                    local nextRatio  = gearRatioOf(gmax, ng)
                    local nextMaxSpd = gearMaxSpeed(rs.maxFlatVel or 40.0, nextRatio)
                    local newRpm     = (nextMaxSpd > 0.01) and (wheelSpd / nextMaxSpd) or 0.2

                    rs.gear = ng
                    SetVehicleHandlingFloat(rs.veh, 'CHandlingData', 'fDriveInertia',
                        gearInertia(rs.baseInertia or 1.0, gmax, nextRatio,
                                    GetControlNormal(0, 71) > 0.05))
                    SetVehicleCurrentRpm(rs.veh, math.max(0.05, math.min(1.0, newRpm)))
                end
            end

            if runState and runState.phase ~= 'measuring' then
                if IsControlJustPressed(0, K.gearUp) and (runState.gear or 0) == 0 then
                    runState.gear = 1
                elseif IsControlJustPressed(0, K.gearDown) and (runState.gear or 0) == 1 then
                    runState.gear = 0
                    runState.rpm  = math.min(runState.rpm, 0.5)
                end
            end

            if IsControlJustPressed(0, ECUConfig.Dyno.Keys.run) and runState then
                if runState.phase == 'idle' or runState.phase == 'done' then
                    do
                        local rsx = runState

                        if rsx.veh and DoesEntityExist(rsx.veh) then
                            SetVehicleUndriveable(rsx.veh, false)
                            if not GetIsVehicleEngineRunning(rsx.veh) then
                                SetVehicleEngineOn(rsx.veh, true, true, false)
                            end
                        end

                        local bPs, bNm, mdl, kn = basePowerOf(rsx.veh)
                        local bst  = partsBoostPercent()
                        local mlt  = 1.0 + bst / 100.0
                        rsx.basePs, rsx.baseNm  = bPs, bNm
                        rsx.model,  rsx.known   = mdl, kn
                        rsx.boost               = bst
                        rsx.finalPs             = math.floor(bPs * mlt)
                        rsx.finalNm             = math.floor(bNm * mlt)
                        rsx.redline             = solveRedline(rsx.finalPs, rsx.finalNm,
                                                    ECUConfig.Dyno.ChartRpmMin or 1000)

                        local TH   = ECUConfig.TurboHeat or {}
                        local capT = TH.greenMax or 115
                        if (rsx.heat or 0) > capT then rsx.heat = capT end
                        rsx.heatWarned = false
                    end

                    runState.phase   = 'measuring'
                    runState.samples = {}
                    runState.peakPs, runState.peakNm = 0, 0
                    runState.rpmPeak    = 0.0
                    runState.rpmRoseAt  = GetGameTimer()
                    local rs   = runState
                    local v    = rs.veh
                    local gmax = math.max(rs.gearMax or 6, 1)
                    local mg   = math.max(1, math.min(ECUConfig.Dyno.MeasureGear or 3, gmax))
                    rs.gear    = mg
                    rs.rpm     = 0.0
                    rs.samples = {}
                    rs.buckets = {}
                    local ratio = gearRatioOf(gmax, mg)
                    SetVehicleHandlingFloat(v, 'CHandlingData', 'fDriveInertia',
                        gearInertia(rs.baseInertia or 1.0, gmax, ratio, false))
                    rs.measureGear = mg
                    if SetVehicleCurrentRpm then SetVehicleCurrentRpm(v, 0.0) end
                    dnotify('info', 'dyno_run_start')
                elseif runState.phase == 'measuring' then
                    runState.phase   = 'idle'
                    runState.samples = {}
                    runState.peakPs, runState.peakNm = 0, 0
                    dnui({ type = 'dynoLive', rpm = runState.rpm, gear = runState.gear,
                           phase = 'idle', ps = 0, nm = 0, curve = {} })
                    dnotify('warn', 'dyno_run_abort')
                end
            end
            if not IsPedInAnyVehicle(ped, false) then stopMount(true) end

        elseif IsPedInAnyVehicle(ped, false) and #placedDynos > 0 and canUseDyno() then
            local veh = GetVehiclePedIsIn(ped, false)
            local d = nearestDyno(GetEntityCoords(veh))
            if d then
                wantPrompt = true
                sleep = 0
                last = GetGameTimer()
                if not promptShown then
                    promptShown = true
                    dnui({ type = 'dynoPrompt', show = true })
                end
                if IsControlJustPressed(0, ECUConfig.Dyno.Keys.mount) then
                    startSetup(d)
                end
            end
        end

        if promptShown and not wantPrompt then
            promptShown = false
            dnui({ type = 'dynoPrompt', show = false })
        end
        Wait(sleep)
    end
end)


interface.callback('dynoBuy', function(_, cb)
    TriggerTokenEvent('sm_ecutuning:dyno:buy'); cb('ok')
end)

interface.callback('dynoPlace', function(_, cb)
    cb('ok')
    SetTimeout(150, function() startPlacing(false) end)
end)

interface.callback('dynoEdit', function(_, cb)
    cb('ok')
    SetTimeout(150, function() startPlacing(true) end)
end)

RegisterCommand('dynostatic', function()
    if placing then return end
    if not lib.callback.await('sm_ecutuning:dyno:canStatic', false) then
        lib.notify({ type = 'error', description = 'Khusus admin.' })
        return
    end

    startPlacing(false, true)
end, false)

interface.callback('dynoStore', function(_, cb)
    TriggerTokenEvent('sm_ecutuning:dyno:store'); cb('ok')
end)


interface.callback('dynoState', function(_, cb)
    TriggerTokenEvent('sm_ecutuning:dyno:request'); cb('ok')
end)

---@return boolean
function HRS_DynoBusy() return placing ~= nil or mounted end

function HRS_DynoForceStop()
    if mounted then stopMount(true) end
end
