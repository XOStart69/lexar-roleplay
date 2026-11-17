local function cleanPlate(p)
    if not p then return nil end
    return (p:gsub('%s+', ''):upper())
end

local popsEnabled = true
local lastNitroAsset = nil
local bootCleanup

local setSmoke
local bootPlate   = ''
local bootVehicle = nil
local isInVehicle = false
local ecuOpen     = false
local shopOpen    = false

local function defaultSettings()
    return {
    rpmMin        = ECUConfig.ECU.rpmMin,
    rpmMax        = ECUConfig.ECU.rpmMax,
    popDuration   = ECUConfig.ECU.popDuration,
    popsStage     = ECUConfig.ECU.popsStage,
    standPops     = ECUConfig.ECU.standPops,
    schaltPop     = ECUConfig.ECU.schaltPop,
    megaFlameMode = ECUConfig.ECU.megaFlameMode,
    explosionKnall = false,
    engineVol      = 0,
    addonPop       = false,
    addonRpmMin    = 35,
    addonRpmMax    = 95,
    flamePacks    = ECUConfig.DefaultFlamePacks or { 'standard' },
    nitroColor    = ECUConfig.DefaultNitroColor or 'ncolor1',
    nitroRGB      = (ECUConfig.NitroCustomColor and ECUConfig.NitroCustomColor.default) or { r = 1.0, g = 0.45, b = 0.08 },
    pops2Enabled  = false,
    rpm2Min       = 30,
    rpm2Max       = 50,
    pop2Duration  = 200,
    pops2Stage    = 2,
    pops3Enabled  = false,
    rpm3Min       = 55,
    rpm3Max       = 75,
    pop3Duration  = 200,
    pops3Stage    = 2,
    flammenwerfer = {
        enabled     = ECUConfig.ECU.flammenwerfer.enabled,
        rpmMin      = ECUConfig.ECU.flammenwerfer.rpmMin,
        rpmMax      = ECUConfig.ECU.flammenwerfer.rpmMax,
        duration    = ECUConfig.ECU.flammenwerfer.duration,
        standFlamme = ECUConfig.ECU.flammenwerfer.standFlamme,
        knall       = ECUConfig.ECU.flammenwerfer.knall or false,
        gluehen     = ECUConfig.ECU.flammenwerfer.gluehen or false,
        random      = ECUConfig.ECU.flammenwerfer.random or false,
        randomPreset = ECUConfig.ECU.flammenwerfer.randomPreset or 'aggressiv',
    },
    flammenwerfer2 = {
        enabled  = false,
        rpmMin   = 40,
        rpmMax   = 55,
        duration = 300,
    },
    flammenwerfer3 = {
        enabled  = false,
        rpmMin   = 60,
        rpmMax   = 75,
        duration = 300,
    },
    turboSound = {
        enabled   = ECUConfig.TurboSound.enabled,
        pick      = ECUConfig.TurboSound.pick,
        dumpValve = ECUConfig.TurboSound.dumpValve,
        volume    = math.floor((ECUConfig.TurboSound.volume or 0.3) * 100 + 0.5),
    },
    diesel = {
        enabled    = ECUConfig.Diesel.enabled,
        standSmoke = ECUConfig.Diesel.standSmoke,
        sound      = ECUConfig.Diesel.sound,
        color      = ECUConfig.Diesel.color,
        hardcut    = (ECUConfig.Diesel.hardcut and ECUConfig.Diesel.hardcut.enabled) or false,
        hardcutMs  = (ECUConfig.Diesel.hardcut and ECUConfig.Diesel.hardcut.interval) or 130,
    },
    exhaustMode = 'pops',
    map = nil,
    addonPopPick = nil,
    exhaustSounds = {},
    exhaustVol    = nil,
    shiftVol      = nil,
    shiftSounds   = {},
    drift = {
        angle      = ECUConfig.Drift.angle,
        grip       = ECUConfig.Drift.grip,
        power      = ECUConfig.Drift.power,
        aggression = ECUConfig.Drift.aggression,
        vmax       = ECUConfig.Drift.vmax,
    },
    antilag = {
        rpmLock   = ECUConfig.AntiLag.rpmLock,
        targetPsi = ECUConfig.AntiLag.targetPsi,
    },
}
end

local ecuSettings = defaultSettings()

ecuMaps   = {}
activeMap = 1

local currentParts
local turboHeat

local function hasMapSwitch(liste)
    for _, p in ipairs(liste or currentParts or {}) do
        if p == 'mapswitch' then return true end
    end
    return false
end
HRS_HasMapSwitch = hasMapSwitch

function HRS_MyEngineVol()
    return ecuSettings and ecuSettings.engineVol or 0
end

local function copyTable(t)
    if type(t) ~= 'table' then return t end
    local o = {}
    for k, v in pairs(t) do o[k] = copyTable(v) end
    return o
end

local currentPlate  = nil
local applyPerformance
local spawnFlame
currentParts        = {}
local vehBricked    = false
local pendingOpen   = false
local installing    = false

local driftActive   = false
local driftOrig     = nil
local driftVehicle  = 0

local antilagArmed    = false
local antilagBuilding = false
local antilagPsi      = 0.0

local setFWNitro
local fwNitroActive = false
local antilagReady    = false
local antilagVehicle  = 0
local antilagCruise   = -1.0
local antilagArmedAt  = 0
local antilagLastSpd  = -1.0
local antilagLastBody = -1.0
local antilagLaunched = false
local antilagRpmCur   = 0.0

local UI = {
    frame = interface.init(false),
    mounted = false,
    usedAt = 0,
    busy = false,
    noMount = { forceHide = true, closeECU = true, closeShop = true, forceClose = true, ecuBootStop = true, installEnd = true, setLang = true, hudConfig = true, hudDump = true, addonPopInit = true, dieselSoundInit = true, perfPackage = true, partsUpdate = true, driftState = true, antilagState = true, engineDown = true, ecuBroken = true, dynoOwnState = true, idle = true },
    notifyType = { ok = 'success', success = 'success', err = 'error', error = 'error', warn = 'warning', info = 'inform' },
    status = { veh = 0, pops = false, flame = false, label = 'POP & BANG', at = 0 },
    infoShown = false,
    scanAnim = { dict = 'amb@world_human_clipboard@male@idle_a', clip = 'idle_c', flag = 49 },
    scanProp = { model = 'p_amb_clipboard_01', bone = 36029, pos = vec3(0.16, 0.08, 0.1), rot = vec3(-130.0, -50.0, 0.0) },
}

---@param text any
---@return string
function UI.plain(text)
    if type(text) ~= 'string' then return text ~= nil and tostring(text) or '' end
    return (text:gsub('<[^>]+>', ''))
end

---@param ntype string
---@param title string
---@param msg string
function UI.notify(ntype, title, msg)
    lib.notify({ title = UI.plain(title), description = UI.plain(msg), type = UI.notifyType[ntype] or 'inform', duration = 5000 })
end

---@param label string
---@param duration number
---@param scan boolean
function UI.progress(label, duration, scan)
    if UI.busy then return end
    UI.busy = true
    CreateThread(function()
        local opts = { duration = math.max(500, tonumber(duration) or 5000), label = label, useWhileDead = false, canCancel = false, disable = { combat = true, car = not scan, move = scan } }
        if scan and not cache.vehicle then
            opts.anim = UI.scanAnim
            opts.prop = UI.scanProp
        end
        lib.progressBar(opts)
        UI.busy = false
    end)
end

function UI.sendJob()
    local job = UI.job
    if not job or not UI.mounted then return end

    local left = job.endsAt - GetGameTimer()
    if left <= 0 then return end

    UI.usedAt = GetGameTimer()
    interface.send({ type = 'installStart', kind = job.kind, key = job.key, label = job.label, duration = job.duration, remaining = left })
end

function UI.detachJob()
    if not UI.job then return end

    CreateThread(function()
        for _ = 1, 30 do
            if not UI.busy then break end
            Wait(0)
        end

        local job = UI.job
        if not job or ecuOpen then return end

        local left = job.endsAt - GetGameTimer()
        if left < 500 then return end

        UI.progress(ECU_LS(job.kind) .. ': ' .. job.label, left, false)
    end)
end

function UI.attachJob()
    if not UI.job then return end
    if UI.busy and lib.progressActive() then lib.cancelProgress() end
    UI.sendJob()
end

---@param data table
function UI.install(data)
    local kind = data.style == 'upload' and 'pb_upload' or data.removing and 'pb_remove' or data.isECU and 'pb_flash' or 'pb_install'
    local dur = math.max(500, tonumber(data.duration) or 5000)
    UI.job = { kind = kind, key = data.key, label = UI.plain(data.label or ''), duration = dur, endsAt = GetGameTimer() + dur }

    if ecuOpen and UI.mounted then
        UI.sendJob()
        return
    end

    UI.progress(ECU_LS(kind) .. ': ' .. UI.job.label, dur, false)
end

---@param data table
function UI.installEnd(data)
    UI.job = nil
    if data.failed and UI.busy and lib.progressActive() then lib.cancelProgress() end
    if not ecuOpen or not UI.mounted then return end

    UI.usedAt = GetGameTimer()
    interface.send({ type = 'installEnd', failed = data.failed == true })
end

---@param data table
function UI.update(data)
    local st = UI.status
    if data.inVehicle == nil and data.pops == nil then return end
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then st.veh = veh end
    if data.pops ~= nil then st.pops = data.pops == true end
    if data.flameActive ~= nil or data.megaFlameMode ~= nil then st.flame = data.flameActive == true or (tonumber(data.megaFlameMode) or 0) > 0 end
    if data.hudLabel then st.label = data.hudLabel end
    st.at = GetGameTimer()
end

---@param show boolean
function UI.dynoPrompt(show)
    if show and not UI.infoShown then
        UI.infoShown = true
        local t = ECU_L('dyno_prompt_info')
        exports.rhd_infoui:show({ id = 'sm_ecutuning:dyno', title = t[1], icon = 'fa-solid fa-gauge-high', description = t[2] })
    elseif not show and UI.infoShown then
        UI.infoShown = false
        exports.rhd_infoui:remove('sm_ecutuning:dyno')
    end
end

UI.intercept = {
    notify = function(d) UI.notify(d.ntype, d.title, d.msg) end,
    installStart = UI.install,
    installEnd = UI.installEnd,
    searchScan = function(d) UI.progress(ECU_LS('pb_scan') .. ': ' .. UI.plain(d.label or ''), d.duration, true) end,
    turboHeat = function() end,
    update = UI.update,
    forceHide = function() end,
    dynoPrompt = function(d) UI.dynoPrompt(d.show == true) end,
}

local function sendNUI(data)
    local hook = UI.intercept[data.type]
    if hook then return hook(data) end
    if not UI.frame then return end
    if not UI.mounted then
        if UI.noMount[data.type] or data.show == false then return end
        UI.mounted = true
        interface.show()
    end
    UI.usedAt = GetGameTimer()
    interface.send(data)
end
ECU_SendNUI = sendNUI
ECU_UI = UI

---@return boolean
function ECU_FrameMounted() return UI.mounted end

---@return number
function ECU_FrameUsedAt() return UI.usedAt end

function ECU_UnmountFrame()
    if not UI.mounted then return end
    UI.mounted = false
    interface.focus(false, false)
    interface.hide()
end

local function notifyLocal(ntype, key, ...)
    local t = ECU_L(key)
    local title = t[1]
    local msg = t[2]
    local args = {...}
    if #args > 0 then
        if title == '%s' then
            title = args[1]
        else
            msg = string.format(msg, table.unpack(args))
        end
    end
    sendNUI({ type = 'notify', ntype = ntype, title = title, msg = msg })
end

local function playSound(name, set)
    PlaySoundFrontend(-1, name, set, true)
end
local flashSoundId = nil
local function startFlashSound()
    if flashSoundId then return end
    flashSoundId = GetSoundId()
    PlaySoundFrontend(flashSoundId, 'Trip_Skip_Countdown', 'HUD_MINI_GAME_SOUNDSET', true)
end
local function stopFlashSound()
    if flashSoundId then
        StopSound(flashSoundId)
        ReleaseSoundId(flashSoundId)
        flashSoundId = nil
    end
end

local function hasPartLocal(p)
    for _, x in ipairs(currentParts) do if x == p then return true end end
    return false
end

local function hasAnyStageLocal()
    return hasPartLocal('ecustage1') or hasPartLocal('ecustage2') or hasPartLocal('ecustage3')
end
local function hasStage2OrHigher()
    return hasPartLocal('ecustage2') or hasPartLocal('ecustage3')
end

local function featureUnlocked(feat)
    if not ECUConfig.RequirePartsForFeatures then return true end
    if feat == 'popbang'           then return hasAnyStageLocal() end
    if feat == 'popbang_aggressiv' then return hasPartLocal('downpipe') and hasStage2OrHigher() end
    if feat == 'schaltpop'         then return hasPartLocal('getriebeflash') end
    if feat == 'megaflamme'        then return hasPartLocal('endschalldaempfer') end
    if feat == 'flammenwerfer'     then return hasPartLocal('downpipe') and hasPartLocal('straightpipe') and hasPartLocal('ecustage3') end
    if feat == 'drift'             then return hasPartLocal('driftflash') end
    if feat == 'antilag'           then return hasPartLocal('antilagflash') end
    if feat == 'exhaustvalve'      then return hasPartLocal('exhaustvalve') end
    if feat == 'turbosound'        then return hasPartLocal('turbo') end
    if feat == 'turboheat'         then return hasPartLocal('turbo') end
    return true
end

---@return table<string, boolean>
function UI.features()
    return {
        popbang           = featureUnlocked('popbang'),
        popbang_aggressiv = featureUnlocked('popbang_aggressiv'),
        schaltpop         = featureUnlocked('schaltpop'),
        megaflamme        = featureUnlocked('megaflamme'),
        flammenwerfer     = featureUnlocked('flammenwerfer'),
        drift             = featureUnlocked('drift'),
        antilag           = featureUnlocked('antilag'),
        turbosound        = featureUnlocked('turbosound'),
        exhaustvalve      = featureUnlocked('exhaustvalve'),
    }
end

local DRIFT_MODS = {
    { 'fDriveInertia',             0.31  },
    { 'fSteeringLock',            22.0   },
    { 'fTractionCurveMax',        -1.1   },
    { 'fTractionCurveMin',        -0.4   },
    { 'fTractionCurveLateral',     2.5   },
    { 'fLowSpeedTractionLossMult', -0.57 },
}
local DRIFT_FIELDS = {
    'fDriveInertia', 'fSteeringLock', 'fTractionCurveMax',
    'fTractionCurveMin', 'fTractionCurveLateral', 'fLowSpeedTractionLossMult',
}

local function isDriftClassAllowed(vehicle)
    local class = GetVehicleClass(vehicle)
    for _, c in ipairs(ECUConfig.DriftClassWhitelist) do
        if c == class then return true end
    end
    return false
end

local function saveDriftOriginals(vehicle)
    if driftOrig then return end

    driftOrig = {}
    for _, f in ipairs(DRIFT_FIELDS) do
        driftOrig[f] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', f)
    end
end

local function applyDriftMods(vehicle, modifier)
    for _, mod in ipairs(DRIFT_MODS) do
        local field, value = mod[1], mod[2]
        local cur = GetVehicleHandlingFloat(vehicle, 'CHandlingData', field)
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', field, cur + value * modifier)
    end
end

local function restoreDriftOriginals(vehicle)
    if driftOrig then
        for _, f in ipairs(DRIFT_FIELDS) do
            if driftOrig[f] then
                SetVehicleHandlingFloat(vehicle, 'CHandlingData', f, driftOrig[f])
            end
        end
        driftOrig = nil
    end
    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetEntityMaxSpeed(vehicle, GetVehicleEstimatedMaxSpeed(vehicle))
    end
    applyPerformance(vehicle)
end

local function setDrift(vehicle, on)
    if (not ECUConfig.EnableDrift or ECUConfig.ModifyHandling == false) and on then return end
    if on and ecuVehicleBlocked(vehicle) then return end
    if on then
        saveDriftOriginals(vehicle)
        applyDriftMods(vehicle, 1)
        driftActive = true
        driftVehicle = vehicle
        notifyLocal('ok', 'drift_on')
    else
        driftActive = false
        local v = driftVehicle ~= 0 and driftVehicle or vehicle
        driftVehicle = 0
        restoreDriftOriginals(v)
        notifyLocal('warn', 'drift_off')
    end
    if ecuOpen then sendNUI({ type = 'driftState', active = driftActive }) end
end

local function toggleDrift()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then return end
    if ECUConfig.RequirePartsForFeatures and not featureUnlocked('drift') then
        notifyLocal('warn', 'drift_need_flash')
        return
    end
    if not isDriftClassAllowed(vehicle) then
        notifyLocal('warn', 'drift_wrong_class')
        return
    end
    setDrift(vehicle, not driftActive)
end

local function antilagMaxPsi()
    return ecuSettings.antilag.targetPsi
end

local function armAntiLag(vehicle, on)
    if on then
        antilagArmed    = true
        antilagVehicle  = vehicle
        antilagPsi      = 0.0
        antilagReady    = false
        antilagBuilding = false
        antilagCruise   = -1.0
        antilagLaunched = false
        antilagRpmCur   = 0.0
        antilagArmedAt  = GetGameTimer()
        antilagLastSpd  = GetEntitySpeed(vehicle)
        antilagLastBody = GetVehicleBodyHealth(vehicle)
        local spd = GetEntitySpeed(vehicle)
        if spd > 2.0 then
            antilagCruise = spd
        end
        notifyLocal('ok', 'antilag_armed')
    else
        antilagArmed    = false
        antilagBuilding = false
        antilagReady    = false
        antilagPsi      = 0.0
        antilagVehicle  = 0
        antilagCruise   = -1.0
        antilagLastSpd  = -1.0
        antilagLastBody = -1.0
        antilagLaunched = false
        antilagRpmCur   = 0.0
        if vehicle ~= 0 and DoesEntityExist(vehicle) then
            SetVehicleTurboPressure(vehicle, 0.0)
            local cv = vehicle
            CreateThread(function()
                for i = 1, 8 do
                    Wait(0)
                    if not DoesEntityExist(cv) then break end
                    if not antilagArmed then
                        local g = IsControlPressed(0, 71)
                        SetVehicleCurrentRpm(cv, g and 0.5 or 0.2)
                    else
                        break
                    end
                end
            end)
        end
        sendNUI({ type = 'antilagHud', show = false })
        notifyLocal('warn', 'antilag_off')
    end
    if ecuOpen then sendNUI({ type = 'antilagState', armed = antilagArmed }) end
end

local function toggleAntiLag()
    if not ECUConfig.EnableAntiLag or ECUConfig.ModifyHandling == false then return end
    if vehBlacklisted then notifyLocal('err', 'veh_blocked') return end
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then return end
    if ECUConfig.RequirePartsForFeatures and not featureUnlocked('antilag') then
        notifyLocal('warn', 'antilag_need_flash')
        return
    end
    armAntiLag(vehicle, not antilagArmed)
end

local function antilagLaunch(vehicle, psi)
    local push = psi * ECUConfig.AntiLagPushPerPsi
    local vel = GetEntityVelocity(vehicle)
    local fwd = GetEntityForwardVector(vehicle)
    local curSpeed = GetEntitySpeed(vehicle)

    local kmh = curSpeed * 3.6
    local grenze = ECUConfig.AntiLagLaunchUpTo or 120
    local boostKick = 0.0
    if kmh < grenze then
        boostKick = curSpeed * (ECUConfig.AntiLagLaunchBoost or 0.25)
    end
    local speedAdd = psi * ECUConfig.AntiLagSpeedPerPsi + boostKick

    local maxKmh = ECUConfig.AntiLagMaxSpeed or 0
    if maxKmh <= 0 then
        maxKmh = (GetVehicleEstimatedMaxSpeed(vehicle) or 0) * 3.6
        if maxKmh <= 0 then maxKmh = 300 end
    end
    local maxMs = maxKmh / 3.6
    if curSpeed + speedAdd > maxMs then
        speedAdd = math.max(0.0, maxMs - curSpeed)
    end
    SetEntityVelocity(vehicle,
        vel.x + fwd.x * speedAdd,
        vel.y + fwd.y * speedAdd,
        vel.z)
    ApplyForceToEntity(vehicle, 1,
        fwd.x * push, fwd.y * push, 0.0,
        0.0, 0.0, 0.0, 0, true, true, true, false, true)
end

local function getBaseHP(vehicle)
    if HRS_DynoBasePower then
        local ps = HRS_DynoBasePower(vehicle)
        if ps and ps > 0 then return ps end
    end

    local model = GetEntityModel(vehicle)
    local name = string.lower(GetDisplayNameFromVehicleModel(model))
    if ECUConfig.DynoOverride[name] then return ECUConfig.DynoOverride[name] end
    local force = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveForce')
    local hp = math.floor(force * ECUConfig.DynoForceFactor)
    if hp < 60 then hp = 60 end
    return hp
end

local function getTotalBoost()
    local total = 0
    for _, p in ipairs(currentParts) do
        local def = ECUConfig.Parts[p]
        if def and def.boost then total = total + def.boost end
    end
    return total
end

local perfBaseline = {}
local perfApplied  = {}
local perfCurrent  = nil

local PERF_FIELDS = {
    driveForce = 'fInitialDriveForce',
    vmax       = 'fInitialDriveMaxFlatVel',
    inertia    = 'fDriveInertia',
    clutchUp   = 'fClutchChangeRateScaleUpShift',
    clutchDown = 'fClutchChangeRateScaleDownShift',
}

local function perfReadBaseline(vehicle)
    local netId = VehToNet(vehicle)
    if netId == 0 then return nil end
    local model = GetEntityModel(vehicle)
    local cached = perfBaseline[netId]
    if cached and cached.model == model then return cached end

    local b = { model = model }
    for k, f in pairs(PERF_FIELDS) do
        b[k] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', f)
    end
    perfBaseline[netId] = b
    return b
end

local PERF_SKIP_CLASS = { [13] = true, [14] = true, [15] = true, [16] = true, [21] = true }

local function perfVehicleOk(vehicle)
    if PERF_SKIP_CLASS[GetVehicleClass(vehicle)] then return false end
    local v = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fInitialDriveMaxFlatVel')
    if not v or v <= 1.0 then return false end
    return true
end

local function perfApply(vehicle, pkg, force)
    if ECUConfig.ModifyHandling == false then return end
    if ecuVehicleBlocked(vehicle) then return end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if not perfVehicleOk(vehicle) then return end
    if driftActive and vehicle == driftVehicle then return end

    if not pkg or not pkg.mult then return end

    local b = perfReadBaseline(vehicle)
    if not b then return end

    local m = pkg.mult
    local C = HRSPerf.Clamp
    local set = function(k, mul)
        local v = b[k] * (mul or 1.0)
        if k == 'driveForce' then v = math.min(v, C.driveForceAbs) end
        if k == 'clutchUp' or k == 'clutchDown' then v = math.min(v, C.clutchAbs) end
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', PERF_FIELDS[k], v)
    end
    local netId = VehToNet(vehicle)
    if not force and netId ~= 0 and perfApplied[netId] == (pkg.v or 0) then return end

    set('driveForce', m.driveForce)
    set('vmax',       m.vmax)
    set('inertia',    m.inertia)
    set('clutchUp',   m.clutch)
    set('clutchDown', m.clutch)

    if ModifyVehicleTopSpeed then ModifyVehicleTopSpeed(vehicle, 1.0) end
    if SetVehicleCheatPowerIncrease then SetVehicleCheatPowerIncrease(vehicle, 1.0) end

    if netId ~= 0 then perfApplied[netId] = pkg.v or 0 end
end

applyPerformance = function(vehicle)
    if vehicle == 0 then return end
    perfApply(vehicle, perfCurrent, true)
end

RegisterNetEvent('sm_ecutuning:perf:package', function(plate, pkg)
    if plate ~= currentPlate then return end
    perfCurrent = pkg
    local v0 = GetVehiclePedIsIn(PlayerPedId(), false)
    if v0 ~= 0 then
        local n0 = VehToNet(v0)
        if n0 ~= 0 then perfApplied[n0] = nil end
    end
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then perfApply(veh, pkg) end
    sendNUI({ type = 'perfPackage', pkg = pkg })
end)

AddStateBagChangeHandler('hrs_perf', nil, function(bagName, key, value)
    local veh = GetEntityFromStateBagName(bagName)
    if not veh or veh == 0 then return end
    local tries = 0
    while not DoesEntityExist(veh) and tries < 20 do Wait(50) tries = tries + 1 end
    if not DoesEntityExist(veh) then return end
    perfApply(veh, value)
    if GetVehiclePedIsIn(PlayerPedId(), false) == veh and value then
        perfCurrent = value
    end
end)

vehBlacklisted = false

function ecuVehicleBlocked(vehicle)
    if not vehicle or vehicle == 0 then return false end
    local model = GetEntityArchetypeName and GetEntityArchetypeName(vehicle) or nil
    return HRSVehicleBlocked(model, GetVehicleClass(vehicle))
end

function faultCodeFor(plate)
    local liste = ECUConfig.TurboHeat and ECUConfig.TurboHeat.faultCodes
    if not liste or #liste == 0 then return nil end
    local sum = 0
    for i = 1, #plate do sum = sum + string.byte(plate, i) * i end
    local e = liste[(sum % #liste) + 1]
    return { code = e.code, text = (ECUConfig.Language == 'id') and (e.id or e.en) or e.en }
end

local function perfLocalPackage(vehicle)
    if type(HRSPerf) ~= 'table' or type(HRSPerf.compute) ~= 'function' then return nil end
    if not currentParts or #currentParts == 0 then return nil end

    local plate = cleanPlate(GetVehicleNumberPlateText(vehicle) or '')
    if plate == '' or plate ~= currentPlate then return nil end
    local ps, nm = 300, 400
    if HRS_DynoBasePower then
        local a, b = HRS_DynoBasePower(vehicle)
        if a then ps, nm = a, b end
    end
    local pkg = HRSPerf.compute({ ps = ps, nm = nm, engine = 'turbo' },
        currentParts, ecuSettings.map)
    pkg.v = -1
    return pkg
end

local function perfRequest(vehicle)
    local plate = cleanPlate(GetVehicleNumberPlateText(vehicle) or '')
    if plate == '' then return end
    local netId = VehToNet(vehicle)
    local model = GetEntityArchetypeName and GetEntityArchetypeName(vehicle) or nil
    TriggerTokenEvent('sm_ecutuning:perf:request', plate, model, netId)
    local bag = netId ~= 0 and Entity(vehicle).state.hrs_perf or nil
    if bag then
        perfCurrent = bag
        perfApply(vehicle, bag)
    else
        local vor = perfLocalPackage(vehicle)
        if vor then
            perfCurrent = vor
            perfApply(vehicle, vor)
        end
    end
end

CreateThread(function()
    while true do
        Wait(2000)
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            local netId = NetworkGetEntityIsNetworked(veh) and VehToNet(veh) or 0
            if netId ~= 0 then
                local bag = Entity(veh).state.hrs_perf
                if bag and perfApplied[netId] ~= (bag.v or 0) then
                    perfApply(veh, bag)
                end
            end
        end
    end
end)

function HRS_PerfPackage() return perfCurrent end

CreateThread(function()
    local lastCut = 0
    while true do
        local sleep = 300
        local cfgH = ECUConfig.Diesel and ECUConfig.Diesel.hardcut

        if cfgH and ecuSettings.diesel and ecuSettings.diesel.hardcut
           and ecuSettings.exhaustMode == 'diesel'
           and not vehBlacklisted then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                sleep = 0
                local rpm = GetVehicleCurrentRpm(veh)
                if rpm >= (cfgH.rpm or 0.92) and IsControlPressed(0, 71) then
                    local now = GetGameTimer()
                    local takt = ecuSettings.diesel.hardcutMs or cfgH.interval or 130
                    if now - lastCut >= takt then
                        lastCut = now
                        if spawnFlame then spawnFlame(veh, rpm) end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and perfCurrent and perfCurrent.curve then
            local c = perfCurrent.curve
            if c.shaped then
                sleep = 0
                local ok, err = pcall(function()
                    local rpm  = GetVehicleCurrentRpm(veh)
                    local gear = GetVehicleCurrentGear(veh)
                    local f = HRSPerf.torqueAt(c, rpm, gear)
                    if ECUConfig.ModifyHandling ~= false then
                        SetVehicleEngineTorqueMultiplier(veh, f)
                    end
                    if c.rev and c.rev < 1.0 and rpm >= c.rev then
                        DisableControlAction(0, 71, true)
                    end
                end)
                if not ok then
                    print(('^1[Debug PERF]^7 torque shaping: %s'):format(tostring(err)))
                    sleep = 1000
                end
            end
        end
        Wait(sleep)
    end
end)

local function buildDynoData(vehicle)
    local base = getBaseHP(vehicle)

    local boost = HRS_DynoBoost and HRS_DynoBoost() or getTotalBoost()
    local parts = HRS_DynoPartList and HRS_DynoPartList() or nil

    if not parts then
        parts = {}
        for _, p in ipairs(currentParts) do
            local def = ECUConfig.Parts[p]
            if def and def.boost and def.boost > 0 then
                parts[#parts+1] = { label = def.label, boost = def.boost }
            end
        end
    end

    local total = math.floor(base * (1.0 + boost/100.0))
    local maxB = 0
    for _, key in ipairs(ECUConfig.ShopOrder or {}) do
        if HRSPartDisabled(key) then goto continue end
        local ov = ECUConfig.Dyno and ECUConfig.Dyno.StageBoost and ECUConfig.Dyno.StageBoost[key]
        local def = ECUConfig.Parts[key]
        maxB = maxB + (ov or (def and def.boost) or 0)
        ::continue::
    end
    if maxB < 1 then maxB = 30 end

    return { base = base, boost = boost, total = total, parts = parts, maxBoost = maxB }
end

local function buildPartsData()
    local list = {}
    for _, key in ipairs(ECUConfig.ShopOrder) do
        if HRSPartDisabled(key) then goto continue end
        local def = ECUConfig.Parts[key]
        if def then
            list[#list+1] = {
                key = key, label = def.label, boost = def.boost or 0,
                category = def.category, installed = hasPartLocal(key),
                unlocks = def.unlocks, requires = def.requires,
                requiresAny = def.requiresAny, replaces = def.replaces,
            }
        end
        ::continue::
    end
    local features = {
        { key='popbang',           label='Pop & Bang (Normal + Sport)', unlocked=featureUnlocked('popbang'),           req='ECU Stage 1' },
        { key='popbang_aggressiv', label='Pop & Bang Aggressive',         unlocked=featureUnlocked('popbang_aggressiv'), req='Downpipe + ECU Stage 2' },
        { key='schaltpop',         label='Shift-Pop',                   unlocked=featureUnlocked('schaltpop'),          req='Gearbox Flash' },
        { key='megaflamme',        label='Mega Flames',                 unlocked=featureUnlocked('megaflamme'),         req='Muffler' },
        { key='flammenwerfer',     label='Flamethrower',                unlocked=featureUnlocked('flammenwerfer'),      req='Downpipe + Straight Pipe + Stage 3' },
        { key='drift',             label='Drift Mode',                  unlocked=featureUnlocked('drift'),              req='Differential Flash' },
        { key='antilag',           label='Anti-Lag / Launch Control',    unlocked=featureUnlocked('antilag'),            req='Anti-Lag Flash' },
    }
    return { parts = list, features = features }
end

local function getVehicleLabel(vehicle)
    if vehicle == 0 then return 'No vehicle', '' end
    local model = GetEntityModel(vehicle)
    local lbl = GetLabelText(GetDisplayNameFromVehicleModel(model))
    if not lbl or lbl == 'NULL' or lbl == '' then
        lbl = GetDisplayNameFromVehicleModel(model)
    end
    local plate = GetVehicleNumberPlateText(vehicle)
    if plate then plate = cleanPlate(plate) end
    return lbl or 'Vehicle', plate or ''
end

popHeatActive = false
popHeatUntil  = 0
blownPlates   = {}
turboBlown    = false

local hudShowUntil = 0

local hasOBD = true
local hudHiddenSent = false

Citizen.CreateThread(function()
    if not ECUConfig.HudNeedsOBD or not ECUConfig.RequireOBD then
        hasOBD = true
        return
    end
    local obdItem = ECUConfig.OBDItem
    local wasIn = false
    local nextCheck = 0
    while true do
        local inside = cache.vehicle ~= false and cache.vehicle ~= nil
        local now = GetGameTimer()
        if inside and (not wasIn or now >= nextCheck) then
            hasOBD = (ox_inventory:Search('count', obdItem) or 0) > 0
            nextCheck = now + 10000
        end
        wasIn = inside
        Citizen.Wait(1000)
    end
end)

local function updateUI()
    local flameActive = ecuSettings.megaFlameMode > 0 or ecuSettings.flammenwerfer.enabled
    local dieselMode = (ecuSettings.exhaustMode == 'diesel')
    local popsActive = popsEnabled
    if ecuSettings.exhaustMode == 'off' then
        popsActive = false
    elseif dieselMode then
        if ECUConfig.Diesel.requiresTurbo and not featureUnlocked('turbosound') then
            popsActive = false
        end
    elseif ECUConfig.RequirePartsForFeatures and not featureUnlocked('popbang') then
        popsActive = false
    end

    local mode = ECUConfig.HudMode or 'always'
    if ECUConfig.HudNeedsOBD and ECUConfig.RequireOBD and not hasOBD then
        if not hudHiddenSent then
            hudHiddenSent = true
            sendNUI({ type = 'update', inVehicle = false })
        end
        return
    end
    hudHiddenSent = false

    local hudVisible
    if mode == 'off' then
        hudVisible = false
    elseif mode == 'toggle' then
        hudVisible = isInVehicle and (GetGameTimer() < hudShowUntil)
    else
        hudVisible = isInVehicle
    end

    sendNUI({
        type          = 'update',
        pops          = popsActive,
        hudLabel      = dieselMode and 'DIESEL' or 'POP & BANG',
        megaFlameMode = ecuSettings.megaFlameMode,
        flameActive   = flameActive,
        inVehicle     = hudVisible,
    })
end

local function flashHud()
    if (ECUConfig.HudMode or 'always') ~= 'toggle' then return end
    hudShowUntil = GetGameTimer() + (ECUConfig.HudToggleDuration or 5000)
    updateUI()
    Citizen.CreateThread(function()
        Citizen.Wait((ECUConfig.HudToggleDuration or 5000) + 50)
        updateUI()
    end)
end

local function closeECUMenu()
    if bootCleanup then bootCleanup() end
    if bootVehicle and bootVehicle ~= 0 and DoesEntityExist(bootVehicle) then
        SetVehicleDoorShut(bootVehicle, 4, false)
        bootVehicle = nil
    end

    ecuOpen = false
    interface.focus(false, false)
    sendNUI({ type = 'closeECU' })
    UI.detachJob()
end

local settingsToTable

local function snapshotProfile()
    local t = settingsToTable()
    t.maps, t.activeMap = nil, nil
    return copyTable(t)
end

function syncActiveSlot()
    if hasMapSwitch(menuParts) or hasMapSwitch() then
        ecuMaps[activeMap] = snapshotProfile()
    end
end

settingsToTable = function()
    return {
        rpmMin = ecuSettings.rpmMin, rpmMax = ecuSettings.rpmMax,
        popDuration = ecuSettings.popDuration, popsStage = ecuSettings.popsStage,
        standPops = ecuSettings.standPops, schaltPop = ecuSettings.schaltPop,
        megaFlameMode = ecuSettings.megaFlameMode,
        explosionKnall = ecuSettings.explosionKnall,
        engineVol      = ecuSettings.engineVol or 0,
        addonPop       = ecuSettings.addonPop,
        addonRpmMin    = ecuSettings.addonRpmMin,
        addonRpmMax    = ecuSettings.addonRpmMax,
        flamePacks = ecuSettings.flamePacks,
        nitroColor = ecuSettings.nitroColor,
        nitroRGB   = ecuSettings.nitroRGB,
        map = ecuSettings.map,
        maps = ecuMaps,
        activeMap = activeMap,
        addonPopPick = ecuSettings.addonPopPick,
        exhaustSounds = ecuSettings.exhaustSounds,
        exhaustVol    = ecuSettings.exhaustVol,
        shiftVol      = ecuSettings.shiftVol,
        shiftSounds   = ecuSettings.shiftSounds,
        exhaustMode = ecuSettings.exhaustMode,
        diesel     = ecuSettings.diesel,
        turboSound = ecuSettings.turboSound,
        pops2Enabled = ecuSettings.pops2Enabled,
        rpm2Min = ecuSettings.rpm2Min, rpm2Max = ecuSettings.rpm2Max,
        pop2Duration = ecuSettings.pop2Duration, pops2Stage = ecuSettings.pops2Stage,
        pops3Enabled = ecuSettings.pops3Enabled,
        rpm3Min = ecuSettings.rpm3Min, rpm3Max = ecuSettings.rpm3Max,
        pop3Duration = ecuSettings.pop3Duration, pops3Stage = ecuSettings.pops3Stage,
        fwEnabled = ecuSettings.flammenwerfer.enabled,
        fwRpmMin = ecuSettings.flammenwerfer.rpmMin,
        fwRpmMax = ecuSettings.flammenwerfer.rpmMax,
        fwDuration = ecuSettings.flammenwerfer.duration,
        fwStandFlamme = ecuSettings.flammenwerfer.standFlamme,
        fwKnall = ecuSettings.flammenwerfer.knall,
        fwGluehen = ecuSettings.flammenwerfer.gluehen,
        fwRandom = ecuSettings.flammenwerfer.random,
        fwRandomPreset = ecuSettings.flammenwerfer.randomPreset,
        sealed = ecuSealed or nil,
        fw2Enabled = ecuSettings.flammenwerfer2.enabled,
        fw2RpmMin = ecuSettings.flammenwerfer2.rpmMin,
        fw2RpmMax = ecuSettings.flammenwerfer2.rpmMax,
        fw2Duration = ecuSettings.flammenwerfer2.duration,
        fw3Enabled = ecuSettings.flammenwerfer3.enabled,
        fw3RpmMin = ecuSettings.flammenwerfer3.rpmMin,
        fw3RpmMax = ecuSettings.flammenwerfer3.rpmMax,
        fw3Duration = ecuSettings.flammenwerfer3.duration,
        driftAngle = ecuSettings.drift.angle,
        driftGrip = ecuSettings.drift.grip,
        driftPower = ecuSettings.drift.power,
        driftAggr = ecuSettings.drift.aggression,
        driftVmax = ecuSettings.drift.vmax,
        antilagRpm = ecuSettings.antilag.rpmLock,
        antilagPsi = ecuSettings.antilag.targetPsi,
    }
end

local function applySettingsTable(t)
    ecuSealed = (type(t) == 'table' and type(t.sealed) == 'table') and t.sealed or nil
    if type(t.maps) == 'table' then ecuMaps = t.maps end
    if t.activeMap then
        activeMap = tonumber(t.activeMap) or 1
        if activeMap < 1 or activeMap > 3 then activeMap = 1 end
    end
    if not t then return end
    ecuSettings.rpmMin        = tonumber(t.rpmMin)      or ecuSettings.rpmMin
    ecuSettings.rpmMax        = tonumber(t.rpmMax)      or ecuSettings.rpmMax
    ecuSettings.popDuration   = tonumber(t.popDuration) or ecuSettings.popDuration
    ecuSettings.popsStage     = tonumber(t.popsStage)   or ecuSettings.popsStage
    ecuSettings.megaFlameMode = tonumber(t.megaFlameMode) or 0
    ecuSettings.explosionKnall = t.explosionKnall == true

    if type(t.turboSound) == 'table' then
        local ts = ecuSettings.turboSound
        ts.enabled   = t.turboSound.enabled   == true
        ts.dumpValve = t.turboSound.dumpValve == true
        ts.volume    = tonumber(t.turboSound.volume) or ts.volume
        if t.turboSound.pick then
            for _, s in ipairs(ECUConfig.TurboSounds or {}) do
                if s.key == t.turboSound.pick then ts.pick = s.key break end
            end
        end
    end

    if type(t.diesel) == 'table' then
        local d = ecuSettings.diesel
        d.enabled    = t.diesel.enabled == true
        d.hardcut    = t.diesel.hardcut == true
        if tonumber(t.diesel.hardcutMs) then d.hardcutMs = tonumber(t.diesel.hardcutMs) end
        d.standSmoke = t.diesel.standSmoke == true
        d.sound      = t.diesel.sound == true
        if t.diesel.color and ECUConfig.SmokeColors[t.diesel.color] then
            d.color = t.diesel.color
        end
    end
    ecuSettings.diesel.enabled = (ecuSettings.exhaustMode == 'diesel')

    if t.addonPopPick then ecuSettings.addonPopPick = t.addonPopPick end
    if type(t.map) == 'table' then ecuSettings.map = t.map end
    if type(t.exhaustSounds) == 'table' then
        local sauber = {}
        for _, key in ipairs(t.exhaustSounds) do
            for _, s in ipairs(ECUConfig.ExhaustSounds or {}) do
                if s.key == key then sauber[#sauber + 1] = key break end
            end
        end
        ecuSettings.exhaustSounds = sauber
    end
    if tonumber(t.exhaustVol) then ecuSettings.exhaustVol = tonumber(t.exhaustVol) end
    ecuSettings.engineVol = math.max(0, math.floor(tonumber(t.engineVol) or 0))
    if tonumber(t.shiftVol)   then ecuSettings.shiftVol   = tonumber(t.shiftVol)   end
    if type(t.shiftSounds)   == 'table' then ecuSettings.shiftSounds   = t.shiftSounds end

    if t.exhaustMode == 'pops' or t.exhaustMode == 'diesel' or t.exhaustMode == 'off' then
        ecuSettings.exhaustMode = t.exhaustMode
    elseif type(t.diesel) == 'table' and t.diesel.enabled == true then
        ecuSettings.exhaustMode = 'diesel'
    elseif t.popsMaster == false then
        ecuSettings.exhaustMode = 'off'
    else
        ecuSettings.exhaustMode = 'pops'
    end
    ecuSettings.addonPop       = t.addonPop == true
    ecuSettings.addonRpmMin    = tonumber(t.addonRpmMin) or ecuSettings.addonRpmMin
    ecuSettings.addonRpmMax    = tonumber(t.addonRpmMax) or ecuSettings.addonRpmMax
    ecuSettings.standPops     = t.standPops == true
    ecuSettings.schaltPop     = t.schaltPop == true
    if type(t.flamePacks) == 'table' then ecuSettings.flamePacks = t.flamePacks end
    if t.nitroColor ~= nil then
        local _, k = nitroColorEntry(t.nitroColor)
        ecuSettings.nitroColor = k or ecuSettings.nitroColor
    end
    if type(t.nitroRGB) == 'table' then ecuSettings.nitroRGB = nitroRGBClean(t.nitroRGB) end
    ecuSettings.pops2Enabled  = t.pops2Enabled == true
    ecuSettings.rpm2Min       = tonumber(t.rpm2Min) or ecuSettings.rpm2Min
    ecuSettings.rpm2Max       = tonumber(t.rpm2Max) or ecuSettings.rpm2Max
    ecuSettings.pop2Duration  = tonumber(t.pop2Duration) or ecuSettings.pop2Duration
    ecuSettings.pops2Stage    = tonumber(t.pops2Stage) or ecuSettings.pops2Stage
    ecuSettings.pops3Enabled  = t.pops3Enabled == true
    ecuSettings.rpm3Min       = tonumber(t.rpm3Min) or ecuSettings.rpm3Min
    ecuSettings.rpm3Max       = tonumber(t.rpm3Max) or ecuSettings.rpm3Max
    ecuSettings.pop3Duration  = tonumber(t.pop3Duration) or ecuSettings.pop3Duration
    ecuSettings.pops3Stage    = tonumber(t.pops3Stage) or ecuSettings.pops3Stage
    ecuSettings.flammenwerfer.enabled     = t.fwEnabled == true
    ecuSettings.flammenwerfer.standFlamme = t.fwStandFlamme == true
    ecuSettings.flammenwerfer.knall       = t.fwKnall == true
    ecuSettings.flammenwerfer.gluehen     = t.fwGluehen == true
    ecuSettings.flammenwerfer.random      = t.fwRandom == true
    if t.fwRandomPreset and (ECUConfig.FlameRandomPresets or {})[t.fwRandomPreset] then
        ecuSettings.flammenwerfer.randomPreset = t.fwRandomPreset
    end
    ecuSettings.flammenwerfer.rpmMin      = tonumber(t.fwRpmMin) or ecuSettings.flammenwerfer.rpmMin
    ecuSettings.flammenwerfer.rpmMax      = tonumber(t.fwRpmMax) or ecuSettings.flammenwerfer.rpmMax
    ecuSettings.flammenwerfer.duration    = tonumber(t.fwDuration) or ecuSettings.flammenwerfer.duration
    ecuSettings.flammenwerfer2.enabled  = t.fw2Enabled == true
    ecuSettings.flammenwerfer2.rpmMin   = tonumber(t.fw2RpmMin) or ecuSettings.flammenwerfer2.rpmMin
    ecuSettings.flammenwerfer2.rpmMax   = tonumber(t.fw2RpmMax) or ecuSettings.flammenwerfer2.rpmMax
    ecuSettings.flammenwerfer2.duration = tonumber(t.fw2Duration) or ecuSettings.flammenwerfer2.duration
    ecuSettings.flammenwerfer3.enabled  = t.fw3Enabled == true
    ecuSettings.flammenwerfer3.rpmMin   = tonumber(t.fw3RpmMin) or ecuSettings.flammenwerfer3.rpmMin
    ecuSettings.flammenwerfer3.rpmMax   = tonumber(t.fw3RpmMax) or ecuSettings.flammenwerfer3.rpmMax
    ecuSettings.flammenwerfer3.duration = tonumber(t.fw3Duration) or ecuSettings.flammenwerfer3.duration
    ecuSettings.drift.angle      = tonumber(t.driftAngle) or ecuSettings.drift.angle
    ecuSettings.drift.grip       = tonumber(t.driftGrip)  or ecuSettings.drift.grip
    ecuSettings.drift.power      = tonumber(t.driftPower) or ecuSettings.drift.power
    ecuSettings.drift.aggression = tonumber(t.driftAggr)  or ecuSettings.drift.aggression
    ecuSettings.drift.vmax       = tonumber(t.driftVmax)  or ecuSettings.drift.vmax
    ecuSettings.antilag.rpmLock   = tonumber(t.antilagRpm) or ecuSettings.antilag.rpmLock
    ecuSettings.antilag.targetPsi = tonumber(t.antilagPsi) or ecuSettings.antilag.targetPsi
    updateUI()
end

local function loadSettingsForPlate(plate)
    if not plate then return end
    TriggerTokenEvent('sm_ecutuning:loadSettings', plate)
end

RegisterNetEvent('sm_ecutuning:receiveSettings', function(plate, settingsJson)
    if plate ~= currentPlate then return end
    if settingsJson then
        local ok, decoded = pcall(json.decode, settingsJson)
        if ok and decoded then applySettingsTable(decoded) end
    else
        ecuSettings = defaultSettings()
        ecuMaps, activeMap = {}, 1
        ecuSealed = nil
    end
    updateUI()
end)

RegisterNetEvent('sm_ecutuning:syncVehicle', function(plate, settingsJson)
    if plate == currentPlate and settingsJson then
        local ok, decoded = pcall(json.decode, settingsJson)
        if ok and decoded then applySettingsTable(decoded) end
    end
end)

local function getMyPlate()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then return nil, 0 end
    local plate = GetVehicleNumberPlateText(veh)
    if plate then plate = cleanPlate(plate) end
    return plate, veh
end

function revalidateFeatures(veh)
    if not ECUConfig.RequirePartsForFeatures then return end

    popsEnabled = featureUnlocked('popbang')

    if ecuSettings.megaFlameMode > 0 and not featureUnlocked('megaflamme') then
        ecuSettings.megaFlameMode = 0
    end

    if ecuSettings.flammenwerfer and ecuSettings.flammenwerfer.enabled and not featureUnlocked('flammenwerfer') then
        ecuSettings.flammenwerfer.enabled = false
        if ecuSettings.flammenwerfer2 then ecuSettings.flammenwerfer2.enabled = false end
        if ecuSettings.flammenwerfer3 then ecuSettings.flammenwerfer3.enabled = false end
        if veh and veh ~= 0 and fwNitroActive then setFWNitro(veh, false) end
    end

    if ecuSettings.schaltPop and not featureUnlocked('schaltpop') then
        ecuSettings.schaltPop = false
    end

    if driftActive and not featureUnlocked('drift') then
        if veh and veh ~= 0 then setDrift(veh, false) end
        driftActive = false
    end

    if antilagArmed and not featureUnlocked('antilag') then
        armAntiLag(veh or antilagVehicle or 0, false)
    end
end

RegisterNetEvent('sm_ecutuning:receiveParts', function(plate, parts, bricked)
    if plate == currentPlate then
        local v = GetVehiclePedIsIn(PlayerPedId(), false)
        if v ~= 0 then Citizen.SetTimeout(200, function() perfRequest(v) end) end
    end
    if parts and (plate == currentPlate or (menuPlate and plate == menuPlate)) then
        menuParts = parts
    end

    if plate ~= currentPlate then return end
    currentParts = parts or {}
    vehBricked   = bricked or false
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)

    revalidateFeatures(veh)

    if veh ~= 0 then
        perfRequest(veh)
        applyPerformance(veh)
        Citizen.SetTimeout(1500, function()
            local v = GetVehiclePedIsIn(PlayerPedId(), false)
            if v ~= 0 then
                local n = VehToNet(v)
                if n ~= 0 then perfApplied[n] = nil end
                applyPerformance(v)
            end
        end)
    end
    updateUI()
    if ecuOpen then
        sendNUI({ type = 'partsUpdate', parts = buildPartsData(), dyno = buildDynoData(veh),
                  mapSwitch = hasMapSwitch(parts), features = UI.features(),
                  bricked = vehBricked })
    end
end)

RegisterNetEvent('sm_ecutuning:notify', function(ntype, title, msg)
    sendNUI({ type = 'notify', ntype = ntype, title = title, msg = msg })
    if ntype == 'ok' then
        playSound('CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET')
    elseif ntype == 'err' then
        playSound('ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
    elseif ntype == 'warn' then
        playSound('ATTENTION_LOST', 'HUD_AWARDS')
    end
end)

menuParts = {}
menuPlate = nil

function sendMenuState(veh, vlabel, vplate, parts, bricked)
    parts   = parts or menuParts or currentParts or {}
    menuParts = parts
    menuPlate = vplate or currentPlate

    local flamePackList = {}
    for _, key in ipairs(ECUConfig.FlamePackOrder or {}) do
        if ECUConfig.FlamePacks[key] then
            flamePackList[#flamePackList+1] = { key = key, label = ECUConfig.FlamePacks[key].label }
        end
    end

    local nitroColorList = {}
    for _, key in ipairs(ECUConfig.NitroColorOrder or {}) do
        if ECUConfig.NitroColors[key] then
            nitroColorList[#nitroColorList+1] = { key = key, label = ECUConfig.NitroColors[key].label }
        end
    end
    if nitroCustomEntry() then
        nitroColorList[#nitroColorList+1] = { key = 'custom', label = 'Custom colour', custom = true }
    end
    bricked = bricked or vehBricked or false
    sendNUI({
        type        = 'openECU',
        lang        = ECUConfig.Language,
        ecu         = settingsToTable(),
        flamePacks  = flamePackList,
        nitroColors = nitroColorList,
        fwPresets   = (function()
            local l = {}
            for _, k in ipairs(ECUConfig.FlameRandomPresetOrder or {}) do
                local p = (ECUConfig.FlameRandomPresets or {})[k]
                if p then l[#l+1] = { key = k, label = p.label or k } end
            end
            return l
        end)(),
        shiftSoundList = ECUConfig.ShiftSounds or {},
        shiftSoundPick = ecuSettings.shiftSounds or {},
        exhaustSoundList = ECUConfig.ExhaustSounds or {},
        exhaustSoundPick = ecuSettings.exhaustSounds or {},
        exhaustVol  = ecuSettings.exhaustVol or math.floor((ECUConfig.ExhaustSoundVolume or 0.7) * 100),
        shiftVol    = ecuSettings.shiftVol   or math.floor((ECUConfig.ShiftSoundVolume   or 0.7) * 100),
        addonPops   = ECUConfig.AddonPops or {},
        addonPick   = ecuSettings.addonPopPick,
        smokeColors = (function()
            local out = {}
            for _, key in ipairs(ECUConfig.SmokeColorOrder or {}) do
                local c = ECUConfig.SmokeColors[key]
                if c then
                    out[#out + 1] = {
                        key   = key,
                        label = c.label or key,
                        css   = c.r and string.format('rgb(%d,%d,%d)',
                                math.floor(c.r * 255), math.floor(c.g * 255),
                                math.floor(c.b * 255)) or nil,
                    }
                end
            end
            return out
        end)(),
        turboSounds = ECUConfig.TurboSounds,
        dumpFile    = ECUConfig.TurboSound.dumpFile,
        pops        = popsEnabled,
        exhaustMode = ecuSettings.exhaustMode,
        popsStages  = ECUConfig.PopsStages,
        mapSwitch   = hasMapSwitch(parts),
        mapLocked    = menuPerms and menuPerms.mapLocked == true,
        stage3Locked = menuPerms and menuPerms.stage3Locked == true,
        msLocked     = menuPerms and menuPerms.msLocked == true,
        isAdmin      = menuPerms and menuPerms.isAdmin == true,
        engineVol    = ecuSettings.engineVol or 0,
        engVolOn     = (ECUConfig.EngineVolume or {}).enabled ~= false,
        engVolStages = (ECUConfig.EngineVolume or {}).stages or { 50, 100, 200 },
        engVolMax    = (ECUConfig.EngineVolume or {}).adminMax or 4400,
        engVolLevels = ECUConfig.EngineVolumeLevels,
        engVolClosed = (ECUConfig.EngineVolume or {}).closed or -30,
        engVolKey    = (ECUConfig.EngineVolume or {}).key or 'G',
        hearOthers   = HRS_HearOthers(),
        sealed       = ecuSealed,
        mapSwitchPrice = (ECUConfig.Parts.mapswitch and ECUConfig.Parts.mapswitch.price) or 0,
        valvePrice     = (ECUConfig.Parts.exhaustvalve and ECUConfig.Parts.exhaustvalve.price) or 0,
        mapSwitchKey   = ECUConfig.MapSwitchKey or 'F5',
        enableDrift   = ECUConfig.EnableDrift ~= false and ECUConfig.ModifyHandling ~= false,
        enableAntiLag = ECUConfig.EnableAntiLag ~= false and ECUConfig.ModifyHandling ~= false,
        hideSettings  = UI.fromSpot == true,
        version       = '4.1.0',
        activeMap   = activeMap,
        engineDown  = (currentPlate and blownPlates[currentPlate]) and true or false,
        faultCode   = currentPlate and faultCodeFor(currentPlate) or nil,
        repairPrice = (ECUConfig.TurboHeat and ECUConfig.TurboHeat.repairPrice) or 0,
        perf        = perfCurrent,
        hasDyno     = (ECUConfig.Dyno ~= nil),
        perfBase    = (function()
            local bp = HRS_DynoBasePower and { HRS_DynoBasePower(veh) } or nil
            return { ps = bp and bp[1] or 300, nm = bp and bp[2] or 400, engine = 'turbo' }
        end)(),
        perfMap     = ecuSettings.map or HRSPerf.defaultMap(),
        perfRedline = (HRS_DynoRedline and HRS_DynoRedline(veh)) or ECUConfig.DefaultRedline or 7800,
        perfStage   = HRSPerf.stageOf(currentParts),
        vehLabel    = vlabel,
        vehPlate    = vplate,
        parts       = buildPartsData(),
        dyno        = buildDynoData(veh),
        features    = UI.features(),
        driftActive = driftActive,
        antilagArmed = antilagArmed,
        valveOpen = (function() local v = GetVehiclePedIsIn(PlayerPedId(), false) return v == 0 or Entity(v).state.hrsValve ~= 1 end)(),
        bricked     = vehBricked,
    })
end

menuPerms = {}

RegisterNetEvent('sm_ecutuning:openGranted', function(plate, parts, bricked, perms)
    menuPerms = perms or {}
    if not isInVehicle and plate and plate ~= '' and plate ~= currentPlate then
        currentPlate = plate
        loadSettingsForPlate(plate)
    end
    if plate == currentPlate then
        currentParts = parts or {}
        vehBricked   = bricked or false
    end
    if not pendingOpen then return end
    pendingOpen = false

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 and bootVehicle and bootVehicle ~= 0 and DoesEntityExist(bootVehicle) then
        veh = bootVehicle
    end
    local vlabel, vplate = getVehicleLabel(veh)

    ecuOpen = true
    interface.focus(true, true)
    playSound('Highlight_Move', 'DLC_HEIST_PLANNING_BOARD_SOUNDS')
    sendMenuState(veh, vlabel, vplate, parts, bricked)
    UI.attachJob()
end)

RegisterNetEvent('sm_ecutuning:tryOpenFromOBD', function()
    local plate, veh = getMyPlate()
    if veh == 0 then
        notifyLocal('warn', 'need_vehicle', ECU_LS('t_ecutune'))
        return
    end
    pendingOpen = true
    (function()
        local v = GetVehiclePedIsIn(PlayerPedId(), false)
        if v == 0 then v = bootVehicle or 0 end
        if v ~= 0 and ecuVehicleBlocked(v) then
            notifyLocal('err', 'veh_blocked')
            return
        end
        TriggerTokenEvent('sm_ecutuning:requestOpen', plate,
            (v ~= 0 and GetEntityArchetypeName) and GetEntityArchetypeName(v) or nil,
            v ~= 0 and GetVehicleClass(v) or nil, v ~= 0 and VehToNet(v) or 0)
    end)()
end)

RegisterNetEvent('sm_ecutuning:tryInstallFromItem', function(partKey)
    local plate, veh = getMyPlate()
    if veh == 0 then
        notifyLocal('warn', 'need_vehicle', ECU_LS('t_install'))
        return
    end
    TriggerTokenEvent('sm_ecutuning:installPart', plate, partKey)
end)

RegisterNetEvent('sm_ecutuning:startInstall', function(plate, partKey, failed, serverDur)
    if installing then return end
    installing = true
    local def = ECUConfig.Parts[partKey]
    if not def then installing = false return end

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    local isECU = def.isECU == true
    local dur = tonumber(serverDur) or def.installTime or 20000

    if veh ~= 0 and not isECU then
        SetVehicleDoorOpen(veh, 4, false, false)
    end

    if veh ~= 0 then
        SetVehicleEngineOn(veh, false, true, true)
        SetVehicleUndriveable(veh, true)
    end

    if not ecuOpen then interface.focus(false, false) end
    sendNUI({
        type = 'installStart',
        key = partKey,
        style = (ECUConfig.Parts[partKey] and ECUConfig.Parts[partKey].noItem) and 'upload' or nil,
        isECU = isECU,
        label = def.label,
        duration = dur,
        standalone = not ecuOpen,
    })
    startFlashSound()

    local steps = 50
    local stepWait = dur / steps
    CreateThread(function()
        for i = 1, steps do
            Citizen.Wait(stepWait)
            if not installing then
                stopFlashSound()
                if veh ~= 0 and DoesEntityExist(veh) then
                    if not isECU then SetVehicleDoorShut(veh, 4, false) end
                    SetVehicleUndriveable(veh, false)
                    SetVehicleEngineOn(veh, true, true, false)
                end
                return
            end
            if veh ~= 0 then SetVehicleEngineOn(veh, false, true, true) end
        end
        stopFlashSound()
        if veh ~= 0 and not isECU then
            SetVehicleDoorShut(veh, 4, false)
        end
        if veh ~= 0 and DoesEntityExist(veh) then
            local stayDead = failed and isECU and ECUConfig.BrickEngineOnFail
            if not stayDead then
                SetVehicleUndriveable(veh, false)
                SetVehicleEngineOn(veh, true, true, false)
            end
        end
        if failed then
            playSound('Hack_Failed', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS')
        else
            playSound('Hack_Success', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS')
        end
        sendNUI({ type = 'installEnd', failed = failed })
        installing = false
        TriggerTokenEvent('sm_ecutuning:finishInstall', plate, partKey, failed)
    end)
end)

RegisterNetEvent('sm_ecutuning:engineBricked', function(plate)
    if plate ~= currentPlate then return end
    vehBricked = true
end)

RegisterNetEvent('sm_ecutuning:startRemove', function(plate, partKey, serverDur)
    if installing then return end
    installing = true
    local def = ECUConfig.Parts[partKey]
    if not def then installing = false return end

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    local isECU = def.isECU == true
    local dur = tonumber(serverDur) or ECUConfig.RemoveTime or 8000

    if veh ~= 0 and not isECU then
        SetVehicleDoorOpen(veh, 4, false, false)
    end
    if veh ~= 0 then
        SetVehicleEngineOn(veh, false, true, true)
        SetVehicleUndriveable(veh, true)
    end

    if not ecuOpen then interface.focus(false, false) end
    sendNUI({
        type = 'installStart',
        key = partKey,
        style = (ECUConfig.Parts[partKey] and ECUConfig.Parts[partKey].noItem) and 'upload' or nil,
        isECU = isECU,
        label = def.label,
        duration = dur,
        standalone = not ecuOpen,
        removing = true,
    })
    startFlashSound()

    local steps = 50
    local stepWait = dur / steps
    CreateThread(function()
        for i = 1, steps do
            Citizen.Wait(stepWait)
            if not installing then
                stopFlashSound()
                if veh ~= 0 and DoesEntityExist(veh) then
                    if not isECU then SetVehicleDoorShut(veh, 4, false) end
                    SetVehicleUndriveable(veh, false)
                    SetVehicleEngineOn(veh, true, true, false)
                end
                return
            end
            if veh ~= 0 then SetVehicleEngineOn(veh, false, true, true) end
        end
        stopFlashSound()
        if veh ~= 0 and not isECU then
            SetVehicleDoorShut(veh, 4, false)
        end
        if veh ~= 0 then
            SetVehicleUndriveable(veh, false)
            SetVehicleEngineOn(veh, true, true, false)
        end
        playSound('Hack_Success', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS')
        sendNUI({ type = 'installEnd', failed = false })
        installing = false
        TriggerTokenEvent('sm_ecutuning:finishRemove', plate, partKey)
    end)
end)

RegisterNetEvent('sm_ecutuning:engineDamage', function(plate)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh == 0 then return end
    SetVehicleEngineHealth(veh, 150.0)
    SetVehiclePetrolTankHealth(veh, 350.0)
    SetVehicleEngineOn(veh, false, true, true)
end)

RegisterNetEvent('sm_ecutuning:engineRepaired', function(plate)
    plate = tostring(plate or '')
    blownPlates[plate] = nil
    turboBlown = false
    HRS_SetTurboHeat((ECUConfig.TurboHeat and ECUConfig.TurboHeat.heatAfterBlow) or 105)

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleUndriveable(veh, false)
        SetVehicleEngineOn(veh, true, true, false)
    end
    if ecuOpen then sendNUI({ type = 'engineDown', down = false }) end
    notifyLocal('ok', 'engine_repaired')
end)

RegisterNetEvent('sm_ecutuning:engineFixed', function(plate)
    if plate ~= currentPlate then return end
    vehBricked = false

    if blownPlates[plate] then
        blownPlates[plate] = nil
        turboBlown = false
        HRS_SetTurboHeat((ECUConfig.TurboHeat and ECUConfig.TurboHeat.heatAfterBlow) or 105)
    end
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh ~= 0 then
        SetVehicleEngineHealth(veh, 1000.0)
        SetVehicleUndriveable(veh, false)
        SetVehicleEngineOn(veh, true, true, false)
        SetVehicleFixed(veh)
    end
    if ecuOpen then sendNUI({ type = 'ecuBroken', broken = false }) end
end)

RegisterNetEvent('sm_ecutuning:tryRepairFromItem', function()
    local plate, veh = getMyPlate()
    if veh == 0 then
        notifyLocal('warn', 'need_vehicle', ECU_LS('t_repair'))
        return
    end
    TriggerTokenEvent('sm_ecutuning:repairECU', plate)
end)

interface.callback('uiClick', function(_, cb)
    playSound('NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
    cb('ok')
end)

interface.callback('uiToggle', function(data, cb)
    local on = data and data.on
    playSound(on and 'TOGGLE_ON' or 'TOGGLE_OFF', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
    cb('ok')
end)

RegisterNetEvent('sm_ecutuning:mapSwitchInstall', function(dauer, label)
    sendNUI({ type = 'installStart', style = 'upload', isECU = true,
              label = label or 'MAP SWITCH', duration = dauer or 8000 })
end)

RegisterNetEvent('sm_ecutuning:mapSwitchDone', function()
    sendNUI({ type = 'installEnd', failed = false })
end)

interface.callback('buyExhaustValve', function(_, cb)
    cb('ok')
    local plate = menuPlate or currentPlate
    if not plate or plate == '' then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then plate = cleanPlate(GetVehicleNumberPlateText(veh)) end
    end
    TriggerTokenEvent('sm_ecutuning:buyExhaustValve', plate or '')
end)

interface.callback('buyMapSwitch', function(_, cb)
    cb('ok')
    local plate = menuPlate or currentPlate
    if not plate or plate == '' then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 then plate = cleanPlate(GetVehicleNumberPlateText(veh)) end
    end
    TriggerTokenEvent('sm_ecutuning:buyMapSwitch', plate or '')
end)

interface.callback('closeECU', function(_, cb)
    bootCleanup()
    if bootVehicle and bootVehicle ~= 0 and DoesEntityExist(bootVehicle) then
        SetVehicleDoorShut(bootVehicle, 4, false)
    end
    bootVehicle = nil
    playSound('Cancel', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
    closeECUMenu()
    cb('ok')
end)

interface.callback('repairECU', function(_, cb)
    if currentPlate then
        TriggerTokenEvent('sm_ecutuning:repairECU', currentPlate)
    end
    cb('ok')
end)

local VALID_LANGS = { en = true }

interface.callback('hudSave', function(data, cb)
    cb('ok')
    if type(data) ~= 'table' then return end

    TriggerTokenEvent('sm_ecutuning:hudSave', data)

    local ok, enc = pcall(json.encode, data)
    if ok and enc and #enc < 4000 then
        SetResourceKvp('hrs_ecutuning_hud', enc)
        if ECUConfig.HudDebug then
            print(('^5[Debug HUD]^7 saved (%d chars): %s'):format(#enc, enc))
        end
    elseif ECUConfig.HudDebug then
        print(('^1[Debug HUD]^7 save failed, ok=%s len=%s')
            :format(tostring(ok), enc and #enc or 'nil'))
    end
end)

local function hudConfigLesen()
    local raw = GetResourceKvpString('hrs_ecutuning_hud')
    if not raw then return {} end
    local ok, dec = pcall(json.decode, raw)
    if ok and type(dec) == 'table' then return dec end
    return {}
end

local function hudConfigSenden()
    local cfg = hudConfigLesen()
    if ECUConfig.HudDebug then
        local ok, enc = pcall(json.encode, cfg)
        print(('^5[Debug HUD]^7 read local: %s'):format(ok and enc or 'none'))
    end
    sendNUI({ type = 'hudConfig', cfg = cfg })
end

RegisterNetEvent('sm_ecutuning:hudLoaded', function(cfg)
    if ECUConfig.HudDebug then
        local ok, enc = pcall(json.encode, cfg)
        print(('^5[Debug HUD]^7 from server: %s'):format(ok and enc or tostring(cfg)))
    end
    if type(cfg) ~= 'table' then return end

    local leer = true
    for _ in pairs(cfg) do leer = false break end
    if leer then return end

    local ok, enc = pcall(json.encode, cfg)
    if ok and enc then SetResourceKvp('hrs_ecutuning_hud', enc) end
    sendNUI({ type = 'hudConfig', cfg = cfg })
end)

interface.callback('hudRequest', function(_, cb)
    cb('ok')
    hudConfigSenden()
end)

Citizen.CreateThread(function()
    Citizen.Wait(3000)
    TriggerTokenEvent('sm_ecutuning:hudLoad')
end)

interface.callback('repairEngine', function(_, cb)
    cb('ok')
    if not currentPlate then return end
    TriggerTokenEvent('sm_ecutuning:repairEngine', currentPlate)
end)

interface.callback('perfReset', function(_, cb)
    cb('ok')
    ecuSettings.map = HRSPerf.defaultMap()
    local v = GetVehiclePedIsIn(PlayerPedId(), false)
    if v ~= 0 and currentPlate then
        TriggerTokenEvent('sm_ecutuning:perf:reset', currentPlate,
            GetEntityArchetypeName and GetEntityArchetypeName(v) or nil, VehToNet(v))
    end
    notifyLocal('ok', 'map_reset')
end)

local function applyLang(l, refreshUi)
    if type(l) ~= 'string' or not VALID_LANGS[l] or l == ECUConfig.Language then return end
    ECUConfig.Language = l
    SetResourceKvp('hrs_ecutuning_lang', l)
    TriggerTokenEvent('sm_ecutuning:setLang', l)

    if refreshUi then
        if ecuOpen then
            local veh = GetVehiclePedIsIn(PlayerPedId(), false)
            if veh == 0 and bootVehicle then veh = bootVehicle end
            local vlabel, vplate = getVehicleLabel(veh)
            sendMenuState(veh, vlabel, vplate)
        end
        sendNUI({ type = 'setLang', lang = l })
        if HRS_RefreshBlips then HRS_RefreshBlips() end
    end
end

local function playerPickedLanguage(l)
    if not l or not VALID_LANGS[l] then return end
    applyLang(l, true)
end

interface.callback('setLang', function(data, cb)
    playerPickedLanguage(data and data.lang)
    cb('ok')
end)

local function sendLangToNui()
    sendNUI({ type = 'setLang', lang = ECUConfig.Language })
end

interface.callback('nuiReady', function(_, cb)
    cb('ok')
    sendLangToNui()
    hudConfigSenden()
    ECU_PreloadSounds()
end)

Citizen.CreateThread(function()
    local saved = GetResourceKvpString('hrs_ecutuning_lang')
    if saved and VALID_LANGS[saved] then
        ECUConfig.Language = saved
    end
    Citizen.Wait(3000)
    TriggerTokenEvent('sm_ecutuning:setLang', ECUConfig.Language)
end)

function applyMenuSettings(data)
    ecuSettings.rpmMin      = tonumber(data.rpmMin)      or ecuSettings.rpmMin
    ecuSettings.rpmMax      = tonumber(data.rpmMax)      or ecuSettings.rpmMax
    ecuSettings.popDuration = tonumber(data.popDuration) or ecuSettings.popDuration
    ecuSettings.popsStage   = tonumber(data.popsStage)   or 2
    ecuSettings.standPops     = data.standPops == true or data.standPops == 'true'
    ecuSettings.schaltPop     = data.schaltPop == true or data.schaltPop == 'true'
    ecuSettings.megaFlameMode = tonumber(data.megaFlameMode) or 0
    ecuSettings.explosionKnall = data.explosionKnall == true or data.explosionKnall == 'true'

    do
        local wantPops   = (data.popsOn == true or data.popsOn == 'true')
        local wantDiesel = (data.dieselEnabled == true or data.dieselEnabled == 'true')

        if wantPops and ECUConfig.RequirePartsForFeatures and not featureUnlocked('popbang') then
            wantPops = false
        end
        if wantDiesel and ECUConfig.Diesel.requiresTurbo and not featureUnlocked('turbosound') then
            wantDiesel = false
        end

        local mode = 'off'
        if wantDiesel then mode = 'diesel'
        elseif wantPops then mode = 'pops' end

        if mode ~= ecuSettings.exhaustMode then
            ecuSettings.exhaustMode = mode
            popsEnabled = true
            local veh = GetVehiclePedIsIn(PlayerPedId(), false)
            if veh ~= 0 and setSmoke then setSmoke(veh, false) end
        end
        ecuSettings.diesel.enabled = (mode == 'diesel')
        updateUI()
        flashHud()
    end

    local ts = ecuSettings.turboSound
    ts.enabled   = data.turboEnabled == true or data.turboEnabled == 'true'
    ts.dumpValve = data.turboDump    == true or data.turboDump    == 'true'
    ts.volume    = tonumber(data.turboVolume) or ts.volume
    if data.turboPick then
        for _, s in ipairs(ECUConfig.TurboSounds or {}) do
            if s.key == data.turboPick then ts.pick = s.key break end
        end
    end

    local dz = ecuSettings.diesel
    dz.standSmoke = data.dieselStand   == true or data.dieselStand   == 'true'
    dz.sound      = data.dieselSound   == true or data.dieselSound   == 'true'
    dz.hardcut    = data.dieselHardcut == true or data.dieselHardcut == 'true'
    do
        local hc = ECUConfig.Diesel.hardcut or {}
        local ms = tonumber(data.dieselHardcutMs)
        if ms then
            dz.hardcutMs = math.max(hc.minInterval or 100,
                                math.min(hc.maxInterval or 300, math.floor(ms)))
        end
    end
    if data.dieselColor and ECUConfig.SmokeColors[data.dieselColor] then
        dz.color = data.dieselColor
    end
    ecuSettings.addonPop       = data.addonPop == true or data.addonPop == 'true'
    if tonumber(data.engineVol) then
        local ev = HRS_EngVolSnap(data.engineVol)
        ecuSettings.engineVol = math.max(0, math.min((ECUConfig.EngineVolume or {}).adminMax or 4400, ev))
    end
    if tonumber(data.exhaustVol) then
        ecuSettings.exhaustVol = math.max(5, math.min(100, math.floor(tonumber(data.exhaustVol))))
    end
    if tonumber(data.shiftVol) then
        ecuSettings.shiftVol = math.max(5, math.min(100, math.floor(tonumber(data.shiftVol))))
    end

    if type(data.exhaustSounds) == 'table' then
        local sauber = {}
        for _, key in ipairs(data.exhaustSounds) do
            for _, s in ipairs(ECUConfig.ExhaustSounds or {}) do
                if s.key == key then sauber[#sauber + 1] = key break end
            end
        end
        ecuSettings.exhaustSounds = sauber
    end

    if type(data.shiftSounds) == 'table' then
        local sauber = {}
        for _, key in ipairs(data.shiftSounds) do
            for _, s in ipairs(ECUConfig.ShiftSounds or {}) do
                if s.key == key then sauber[#sauber + 1] = key break end
            end
        end
        ecuSettings.shiftSounds = sauber
    end

    if type(data.map) == 'table' then
        ecuSettings.map = HRSPerf.sanitizeMap(data.map, HRSPerf.stageOf(currentParts))
    end

    if data.addonPopPick then
        for _, s in ipairs(ECUConfig.AddonPops or {}) do
            if s.key == data.addonPopPick then
                ecuSettings.addonPopPick = data.addonPopPick
                break
            end
        end
    end
    ecuSettings.addonRpmMin    = tonumber(data.addonRpmMin) or ecuSettings.addonRpmMin
    ecuSettings.addonRpmMax    = tonumber(data.addonRpmMax) or ecuSettings.addonRpmMax
    if type(data.flamePacks) == 'table' then ecuSettings.flamePacks = data.flamePacks end
    if data.nitroColor ~= nil then
        local changed = (ecuSettings.nitroColor ~= data.nitroColor)
        if type(data.nitroRGB) == 'table' then
            local n = nitroRGBClean(data.nitroRGB)
            local o = ecuSettings.nitroRGB or {}
            if data.nitroColor == 'custom'
                and (o.r ~= n.r or o.g ~= n.g or o.b ~= n.b) then
                changed = true
            end
            ecuSettings.nitroRGB = n
        end
        ecuSettings.nitroColor = data.nitroColor
        if changed then
            for _, c in pairs(ECUConfig.NitroColors) do
                if c.asset then
                    local n = 0
                    while HasNamedPtfxAssetLoaded(c.asset) and n < 15 do
                        RemoveNamedPtfxAsset(c.asset)
                        n = n + 1
                        Citizen.Wait(0)
                    end
                end
            end
            local n = 0
            while HasNamedPtfxAssetLoaded('veh_xs_vehicle_mods') and n < 15 do
                RemoveNamedPtfxAsset('veh_xs_vehicle_mods')
                n = n + 1
                Citizen.Wait(0)
            end
            lastNitroAsset = nil
            local veh = GetVehiclePedIsIn(PlayerPedId(), false)
            if veh ~= 0 and fwNitroActive then
                setFWNitro(veh, false)
                setFWNitro(veh, true)
            end
        end
    end
    ecuSettings.pops2Enabled  = data.pops2Enabled == true or data.pops2Enabled == 'true'
    ecuSettings.rpm2Min       = tonumber(data.rpm2Min) or ecuSettings.rpm2Min
    ecuSettings.rpm2Max       = tonumber(data.rpm2Max) or ecuSettings.rpm2Max
    ecuSettings.pop2Duration  = tonumber(data.pop2Duration) or ecuSettings.pop2Duration
    ecuSettings.pops2Stage    = tonumber(data.pops2Stage) or 2
    ecuSettings.pops3Enabled  = data.pops3Enabled == true or data.pops3Enabled == 'true'
    ecuSettings.rpm3Min       = tonumber(data.rpm3Min) or ecuSettings.rpm3Min
    ecuSettings.rpm3Max       = tonumber(data.rpm3Max) or ecuSettings.rpm3Max
    ecuSettings.pop3Duration  = tonumber(data.pop3Duration) or ecuSettings.pop3Duration
    ecuSettings.pops3Stage    = tonumber(data.pops3Stage) or 2
    ecuSettings.flammenwerfer.enabled     = data.fwEnabled     == true or data.fwEnabled     == 'true'
    ecuSettings.flammenwerfer.standFlamme = data.fwStandFlamme == true or data.fwStandFlamme == 'true'
    ecuSettings.flammenwerfer.knall       = data.fwKnall == true or data.fwKnall == 'true'
    ecuSettings.flammenwerfer.gluehen     = data.fwGluehen == true or data.fwGluehen == 'true'
    ecuSettings.flammenwerfer.random      = data.fwRandom == true or data.fwRandom == 'true'
    if data.fwRandomPreset and (ECUConfig.FlameRandomPresets or {})[data.fwRandomPreset] then
        ecuSettings.flammenwerfer.randomPreset = data.fwRandomPreset
    end
    ecuSettings.flammenwerfer.rpmMin      = tonumber(data.fwRpmMin)   or ecuSettings.flammenwerfer.rpmMin
    ecuSettings.flammenwerfer.rpmMax      = tonumber(data.fwRpmMax)   or ecuSettings.flammenwerfer.rpmMax
    ecuSettings.flammenwerfer.duration    = tonumber(data.fwDuration) or ecuSettings.flammenwerfer.duration
    ecuSettings.flammenwerfer2.enabled  = data.fw2Enabled == true or data.fw2Enabled == 'true'
    ecuSettings.flammenwerfer2.rpmMin   = tonumber(data.fw2RpmMin) or ecuSettings.flammenwerfer2.rpmMin
    ecuSettings.flammenwerfer2.rpmMax   = tonumber(data.fw2RpmMax) or ecuSettings.flammenwerfer2.rpmMax
    ecuSettings.flammenwerfer2.duration = tonumber(data.fw2Duration) or ecuSettings.flammenwerfer2.duration
    ecuSettings.flammenwerfer3.enabled  = data.fw3Enabled == true or data.fw3Enabled == 'true'
    ecuSettings.flammenwerfer3.rpmMin   = tonumber(data.fw3RpmMin) or ecuSettings.flammenwerfer3.rpmMin
    ecuSettings.flammenwerfer3.rpmMax   = tonumber(data.fw3RpmMax) or ecuSettings.flammenwerfer3.rpmMax
    ecuSettings.flammenwerfer3.duration = tonumber(data.fw3Duration) or ecuSettings.flammenwerfer3.duration
    ecuSettings.drift.angle      = tonumber(data.driftAngle) or ecuSettings.drift.angle
    ecuSettings.drift.grip       = tonumber(data.driftGrip)  or ecuSettings.drift.grip
    ecuSettings.drift.power      = tonumber(data.driftPower) or ecuSettings.drift.power
    ecuSettings.drift.aggression = tonumber(data.driftAggr)  or ecuSettings.drift.aggression
    ecuSettings.drift.vmax       = tonumber(data.driftVmax)  or ecuSettings.drift.vmax
    ecuSettings.antilag.rpmLock   = tonumber(data.antilagRpm) or ecuSettings.antilag.rpmLock
    ecuSettings.antilag.targetPsi = tonumber(data.antilagPsi) or ecuSettings.antilag.targetPsi
end

interface.callback('saveECU', function(data, cb)
    cb('ok')
    applyMenuSettings(data)

    if currentPlate then
        TriggerTokenEvent('sm_ecutuning:menuFlash', currentPlate)
    end
end)

RegisterNetEvent('sm_ecutuning:startMenuFlash', function(plate, failed, serverDur)
    if installing then return end
    installing = true

    local veh = GetVehiclePedIsIn(PlayerPedId(), false)

    if veh ~= 0 then
        SetVehicleEngineOn(veh, false, true, true)
        SetVehicleUndriveable(veh, true)
    end

    local fdur = tonumber(serverDur) or ECUConfig.MenuFlashTime or 15000

    sendNUI({ type = 'installStart', isECU = true, label = 'ECU FLASH', duration = fdur, standalone = true })
    startFlashSound()

    CreateThread(function()
        local steps = 50
        for i = 1, steps do
            Citizen.Wait(fdur / steps)
            if veh ~= 0 then SetVehicleEngineOn(veh, false, true, true) end
        end
        stopFlashSound()
        if failed then
            playSound('Hack_Failed', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS')
        else
            playSound('Hack_Success', 'DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS')
        end

        if veh ~= 0 and DoesEntityExist(veh) then
            local stayDead = failed and ECUConfig.BrickEngineOnFail
            if not stayDead then
                SetVehicleUndriveable(veh, false)
                SetVehicleEngineOn(veh, true, true, false)
            end
        end
        sendNUI({ type = 'installEnd', failed = failed })
        installing = false
        local fv = GetVehiclePedIsIn(PlayerPedId(), false)
        syncActiveSlot()
        TriggerTokenEvent('sm_ecutuning:finishMenuFlash', currentPlate, json.encode(settingsToTable()), failed,
            (fv ~= 0 and GetEntityArchetypeName) and GetEntityArchetypeName(fv) or nil,
            fv ~= 0 and VehToNet(fv) or nil)
    end)
end)

interface.callback('installPart', function(data, cb)
    local plate = getMyPlate()
    if plate and data.key then
        TriggerTokenEvent('sm_ecutuning:installPart', plate, data.key)
    end
    cb('ok')
end)

interface.callback('removePart', function(data, cb)
    local plate = getMyPlate()
    if plate and data.key then
        TriggerTokenEvent('sm_ecutuning:removePart', plate, data.key)
    end
    cb('ok')
end)

interface.callback('closeShop', function(_, cb)
    shopOpen = false
    interface.focus(false, false)
    sendNUI({ type = 'closeShop' })
    cb('ok')
end)

interface.callback('buyCart', function(data, cb)
    cb('ok')
    if type(data.items) ~= 'table' then return end
    TriggerTokenEvent('sm_ecutuning:buyCart', data.items)
end)

RegisterNetEvent('sm_ecutuning:cartResult', function(ok, money)
    if ok then playSound('PURCHASE', 'HUD_LIQUOR_STORE_SOUNDSET') end
    if not shopOpen then return end
    sendNUI({ type = 'cartResult', ok = ok == true, money = money })
end)

RegisterNetEvent('sm_ecutuning:openShop', function(money, society)
    shopOpen = true
    interface.focus(true, true)
    playSound('Highlight_Move', 'DLC_HEIST_PLANNING_BOARD_SOUNDS')
    local items = {}
    for _, key in ipairs(ECUConfig.ShopOrder) do
        if HRSPartDisabled(key) then goto continue end
        local def = ECUConfig.Parts[key]
        if def then
            items[#items+1] = {
                key = key, label = def.label, category = def.category,
                boost = def.boost or 0, price = def.price,
                unlocks = def.unlocks, requires = def.requires,
            }
        end
        ::continue::
    end
    local tools = ECUConfig.Tools
    for i = 1, #tools do
        local t = tools[i]
        items[#items+1] = { key = t.item, label = t.label, category = 'tool', boost = 0, price = t.price, isTool = true }
    end
    sendNUI({ type = 'openShop', lang = ECUConfig.Language, money = money, items = items,
              society = society })
end)

local function forceCloseAll(reason)
    local wasOpen = ecuOpen
    shopOpen = false
    ecuOpen  = false
    interface.focus(false, false)
    sendNUI({ type = 'closeShop' })
    sendNUI({ type = 'closeECU' })
    sendNUI({ type = 'forceClose' })
    if wasOpen then UI.detachJob() end
    if bootCleanup then bootCleanup() end
    if reason then
        print(('^5[Debug EcuTuning]^7 menu force closed (%s)'):format(reason))
    end
end





AddEventHandler('sm_ecutuning:client:forceClose', function()
    forceCloseAll(nil)
    if HRS_DynoForceStop then HRS_DynoForceStop() end
    ECU_UnmountFrame()
end)

AddEventHandler('playerSpawned', function() forceCloseAll(nil) end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function() forceCloseAll(nil) end)
RegisterNetEvent('sm_ecutuning:forceClose',     function() forceCloseAll('Server') end)

CreateThread(function()
    while true do
        Wait(500)

        if shopOpen then
            local ped = PlayerPedId()

            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
                forceCloseAll('state changed')
                goto continue
            end

            local pc   = GetEntityCoords(ped)
            local near = false
            for _, loc in ipairs(ECUConfig.ShopLocations or {}) do
                if #(pc - vector3(loc.x, loc.y, loc.z)) < 12.0 then
                    near = true break
                end
            end
            if not near and #(ECUConfig.ShopLocations or {}) > 0 then
                forceCloseAll('too far')
                goto continue
            end
        end

        if (shopOpen or ecuOpen)
            and (IsControlJustReleased(0, 200) or IsControlJustReleased(0, 202)) then
            forceCloseAll('Escape')
        end

        ::continue::
    end
end)

local exhaustOffsetOverride = nil
local ZERO_OFF = { x = 0.0, y = 0.0, z = 0.0 }

local function vehModelName(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
    local name = GetEntityArchetypeName and GetEntityArchetypeName(vehicle) or nil
    if name and name ~= '' then return string.lower(name) end
    return nil
end

local function pickBoneEntry(entry, boneName)
    if type(entry) ~= 'table' then return nil end
    if type(entry.x) == 'number' or type(entry.y) == 'number' or type(entry.z) == 'number' then
        return entry
    end
    return entry[boneName]
end

local function exhaustOffsetFor(vehicle, boneName)
    if exhaustOffsetOverride then
        local e = exhaustOffsetOverride[boneName] or exhaustOffsetOverride['*']
        if e then return e end
    end

    local byModel = ECUConfig.ExhaustOffsetByModel
    if byModel and vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        local entry = nil
        local name  = vehModelName(vehicle)
        if name then entry = byModel[name] end
        if not entry then
            local hash = GetEntityModel(vehicle)
            for key, e in pairs(byModel) do
                if GetHashKey(key) == hash then entry = e break end
            end
        end
        local hit = pickBoneEntry(entry, boneName)
        if hit then return hit end
    end

    local byBone = ECUConfig.ExhaustOffsetByBone
    if byBone and byBone[boneName] then return byBone[boneName] end

    return ECUConfig.ExhaustOffset or ZERO_OFF
end

local function getExhaustPoints(vehicle)
    local pts = {}

    for i = 1, (ECUConfig.MaxBoneCheck or 8) do
        local boneName = ECUConfig.ExhaustBones[i]
        if not boneName then break end
        local idx = GetEntityBoneIndexByName(vehicle, boneName)
        if idx > 0 then
            local adj = exhaustOffsetFor(vehicle, boneName)
            local ax, ay, az = adj.x or 0.0, adj.y or 0.0, adj.z or 0.0

            local bp  = GetWorldPositionOfEntityBone(vehicle, idx)
            local off = GetOffsetFromEntityGivenWorldCoords(vehicle, bp.x, bp.y, bp.z)
            pts[#pts + 1] = {
                bone = boneName,
                off  = vector3(off.x + ax, off.y + ay, off.z + az),
                adj  = { x = ax, y = ay, z = az },
            }
        end
    end
    return pts
end

local boneRotNative = nil

local function normDeg(v)
    v = v % 360.0
    if v > 180.0 then v = v - 360.0 end
    return v
end

local function getExhaustBoneRot(vehicle, boneName)
    if ECUConfig.PopFlameFollowExhaustAngle == false then return 0.0, 0.0, 0.0 end
    if not boneName or boneRotNative == false then return 0.0, 0.0, 0.0 end

    local idx = GetEntityBoneIndexByName(vehicle, boneName)
    if idx <= 0 then return 0.0, 0.0, 0.0 end

    local rx, ry, rz

    if boneRotNative == nil or boneRotNative == 'object' then
        local ok, x, y, z = pcall(function()
            local r = GetEntityBoneObjectRotation(vehicle, idx)
            return r.x, r.y, r.z
        end)
        if ok and x then
            boneRotNative = 'object'
            rx, ry, rz = x, y, z
        end
    end

    if not rx and (boneRotNative == nil or boneRotNative == 'world') then
        local ok, x, y, z = pcall(function()
            local r = GetEntityBoneRotation(vehicle, idx)
            local v = GetEntityRotation(vehicle, 2)
            return r.x - v.x, r.y - v.y, r.z - v.z
        end)
        if ok and x then
            boneRotNative = 'world'
            rx, ry, rz = normDeg(x), normDeg(y), normDeg(z)
        end
    end

    if not rx then
        boneRotNative = false
        return 0.0, 0.0, 0.0
    end

    local o = ECUConfig.PopFlameAngleOffset
    if type(o) == 'table' then
        rx = rx + (o.x or 0.0)
        ry = ry + (o.y or 0.0)
        rz = rz + (o.z or 0.0)
    end
    return rx + 0.0, ry + 0.0, rz + 0.0
end

local function valveStage(n)
    n = tonumber(n) or 2
    if n >= 3 and HRS_ValveClosed and HRS_ValveClosed() then return 2 end
    return n
end

local function playPopSound(vehicle, stageOverride, soundIdx, isRemote)
    local stIdx = stageOverride or ecuSettings.popsStage
    if not isRemote then stIdx = valveStage(stIdx) end
    local stage = ECUConfig.PopsStages[stIdx] or ECUConfig.PopsStages[2]

    if (not isRemote) and math.random() < stage.explosionChance then
        local ex, ey, ez
        for _, pt in ipairs(getExhaustPoints(vehicle)) do
            do
                local bp = GetOffsetFromEntityInWorldCoords(vehicle,
                    pt.off.x, pt.off.y, pt.off.z)
                ex, ey, ez = bp.x, bp.y, bp.z
                break
            end
        end
        if not ex then
            local pos = GetEntityCoords(vehicle)
            ex, ey, ez = pos.x, pos.y, pos.z + 0.8
        end
        AddExplosion(ex, ey, ez, 61, 0.0, true, true, 0.0, true)
    end

    for i = 1, stage.soundCount do
        local idx = soundIdx or math.random(1, #ECUConfig.PopSounds)
        if i > 1 then idx = math.random(1, #ECUConfig.PopSounds) end
        local snd = ECUConfig.PopSounds[idx] or ECUConfig.PopSounds[1]
        PlaySoundFromEntity(-1, snd, vehicle, 0, false, 0)
    end
end

local function calculateFlameSize(vehicle, rpm)
    local stage = ECUConfig.PopsStages[valveStage(ecuSettings.popsStage)] or ECUConfig.PopsStages[2]
    local baseSize = stage.flameSize

    if ecuSettings.megaFlameMode > 0 and featureUnlocked('megaflamme') then
        baseSize = baseSize * ECUConfig.MegaFlameMultiplier
    end

    local engineMod = GetVehicleMod(vehicle, 11)
    if engineMod > 0 then
        baseSize = baseSize + (engineMod * 0.15)
    end

    local turboPressure = GetVehicleTurboPressure(vehicle)
    if turboPressure > 0 then
        baseSize = baseSize + (turboPressure * 0.3)
    end

    local size = baseSize * rpm
    if ECUConfig.FlameVariation > 0 then
        size = size + (math.random(0, ECUConfig.FlameVariation) / 100)
    end

    return math.max(0, size)
end

local loadedAssets = {}

function hrsRandRange(v, def)
    if type(v) == 'table' then
        local a, b = tonumber(v[1]) or 0, tonumber(v[2]) or tonumber(v[1]) or 0
        return a + math.random() * (b - a)
    end
    return tonumber(v) or def
end

function hrsRandRot(j)
    if type(j) ~= 'table' then return 0.0, 0.0, 0.0 end
    local function r(m) m = tonumber(m) or 0.0 return (math.random() * 2.0 - 1.0) * m end
    return r(j[1]), r(j[2]), r(j[3])
end

local function forceUnloadPtfx(asset, maxTries)
    if not asset or asset == '' then return true end
    local n = 0
    while HasNamedPtfxAssetLoaded(asset) and n < (maxTries or 15) do
        RemoveNamedPtfxAsset(asset)
        n = n + 1
        Citizen.Wait(0)
    end
    loadedAssets[asset] = nil
    return not HasNamedPtfxAssetLoaded(asset)
end

local function ensureAssetLoaded(asset)
    if loadedAssets[asset] and HasNamedPtfxAssetLoaded(asset) then return end
    RequestNamedPtfxAsset(asset)
    local t = 0
    while not HasNamedPtfxAssetLoaded(asset) do
        Citizen.Wait(10)
        t = t + 1
        if t > 100 then return end
    end
    loadedAssets[asset] = true
end

local function isAssetReady(asset)
    if loadedAssets[asset] and HasNamedPtfxAssetLoaded(asset) then return true end
    if HasNamedPtfxAssetLoaded(asset) then
        loadedAssets[asset] = true
        return true
    end
    RequestNamedPtfxAsset(asset)
    return false
end

Citizen.CreateThread(function()
    ensureAssetLoaded('core')
    if ECUConfig.Particles then
        for _, group in pairs(ECUConfig.Particles) do
            for _, pd in ipairs(group) do
                if pd.Library then ensureAssetLoaded(pd.Library) end
            end
        end
    end
end)

function addonPopFile()
    local liste = ECUConfig.AddonPops or {}
    local pick  = ecuSettings.addonPopPick

    if pick then
        for _, s in ipairs(liste) do
            if s.key == pick then return s.file end
        end
    end
    if liste[1] then return liste[1].file end
    return ECUConfig.AddonPop and ECUConfig.AddonPop.file or nil
end

local soundGesperrtBis = 0

function smokeFaktor(vehicle)
    local meins = GetVehiclePedIsIn(PlayerPedId(), false)
    if meins ~= 0 and meins == vehicle then return 1.0 end
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle))
    if dist < 12.0 then return 0.6 end
    if dist < 25.0 then return 0.35 end
    return 0.2
end

local function fremdFaktor(vehicle, art)
    local meins = GetVehiclePedIsIn(PlayerPedId(), false)
    if meins ~= 0 and meins == vehicle then return 1.0 end
    local rv = ECUConfig.RemoteVolumes or {}
    return (art and rv[art]) or ECUConfig.RemoteSoundVolume or 0.1
end

local function playAusAuswahl(vehicle, liste, defs, lautstaerke, weite, art, festerKey)
    if not liste or #liste == 0 then return end

    if GetGameTimer() < soundGesperrtBis then return end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local maxD = weite or 60.0
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle))
    if dist > maxD then return end

    local vol = (lautstaerke or 0.7) * (1.0 - (dist / maxD)) * fremdFaktor(vehicle, art or 'pops')
    if vol <= 0.01 then return end

    local key = festerKey or liste[math.random(#liste)]
    for _, s in ipairs(defs or {}) do
        if s.key == key then
            local src = s.file
            if type(s.files) == 'table' and #s.files > 0 then
                src = s.files[math.random(#s.files)]
            end
            sendNUI({ type = 'addonPop', vol = vol, src = src })
            if s.gap then soundGesperrtBis = GetGameTimer() + s.gap end
            return
        end
    end
end

function playExhaustSound(vehicle)
    local v = ecuSettings.exhaustVol
    playAusAuswahl(vehicle, ecuSettings.exhaustSounds, ECUConfig.ExhaustSounds,
        v and (v / 100.0) or ECUConfig.ExhaustSoundVolume, ECUConfig.ExhaustSoundMaxDist, 'pops')
end

local function broadcastShift(vehicle, key, lautstaerke)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if not NetworkGetEntityIsNetworked(vehicle) then
        NetworkRegisterEntityAsNetworked(vehicle)
    end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if not netId or netId == 0 then return end
    local myc = GetEntityCoords(PlayerPedId())
    TriggerTokenEvent('sm_ecutuning:broadcastShift', netId, key, lautstaerke,
        { x = myc.x, y = myc.y, z = myc.z })
end

RegisterNetEvent('sm_ecutuning:playShift', function(netId, key, lautstaerke)
    if not netId or not key then return end
    if not NetworkDoesNetworkIdExist(netId) then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    playAusAuswahl(veh, { key }, ECUConfig.ShiftSounds, lautstaerke,
        ECUConfig.ShiftSoundMaxDist, 'shift', key)
end)

function playShiftSound(vehicle)
    local liste = ecuSettings.shiftSounds
    if not liste or #liste == 0 then return end
    local v = ecuSettings.shiftVol
    local lautstaerke = v and (v / 100.0) or ECUConfig.ShiftSoundVolume

    local key = liste[math.random(#liste)]
    playAusAuswahl(vehicle, liste, ECUConfig.ShiftSounds,
        lautstaerke, ECUConfig.ShiftSoundMaxDist, 'shift', key)
    broadcastShift(vehicle, key, lautstaerke)
end

function playAddonPop(vehicle)
    local cfg = ECUConfig.AddonPop
    local datei = addonPopFile()
    if not datei or datei == '' then return end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local maxD = cfg.maxDistance or 60.0
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle))
    if dist > maxD then return end
    local vol = (cfg.volume or 0.8) * (1.0 - (dist / maxD)) * fremdFaktor(vehicle, 'pops')
    if vol <= 0.01 then return end

    sendNUI({ type = 'addonPop', vol = vol, src = datei })
end

function ECU_PreloadSounds()
    for _, liste in ipairs({ ECUConfig.ExhaustSounds or {}, ECUConfig.ShiftSounds or {} }) do
        for _, s in ipairs(liste) do
            if s.file and s.file ~= '' then
                sendNUI({ type = 'addonPopInit', src = s.file })
            end
            for _, f in ipairs(s.files or {}) do
                sendNUI({ type = 'addonPopInit', src = f })
            end
        end
    end

    local liste = ECUConfig.AddonPops or {}
    if #liste > 0 then
        for _, s in ipairs(liste) do
            if s.file and s.file ~= '' then
                sendNUI({ type = 'addonPopInit', src = s.file })
            end
        end
    else
        local cfg = ECUConfig.AddonPop
        if cfg and cfg.file and cfg.file ~= '' then
            sendNUI({ type = 'addonPopInit', src = cfg.file })
        end
    end

    local ds = ECUConfig.DieselSound
    if ds and ds.file and ds.file ~= '' then
        sendNUI({ type = 'dieselSoundInit', src = ds.file })
    end
end

local function renderFlame(vehicle, fx, isRemote)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if fx.particles then
        for _, pf in ipairs(fx.particles) do
            local off = nil

            if pf.ox then
                off = vector3(pf.ox, pf.oy, pf.oz)
            elseif pf.bone then
                local boneIdx = GetEntityBoneIndexByName(vehicle, pf.bone)
                if boneIdx > 0 then
                    local bp = GetWorldPositionOfEntityBone(vehicle, boneIdx)
                    off = GetOffsetFromEntityGivenWorldCoords(vehicle, bp.x, bp.y, bp.z)
                end
            end

            if not off then
                local pts = getExhaustPoints(vehicle)
                off = pts[1] and pts[1].off or nil
            end

            local bi = pf.bone and GetEntityBoneIndexByName(vehicle, pf.bone) or -1

            local pk = nil
            for _, p in pairs(ECUConfig.FlamePacks or {}) do
                if p.library == pf.lib then
                    if p.name == pf.name then pk = p break end
                    for _, v in ipairs(p.variants or {}) do
                        if v == pf.name then pk = p break end
                    end
                    if pk then break end
                end
            end

            if (ECUConfig.PopUseBoneAttach ~= false or (pk and pk.boneAttach)) and bi > 0 then
                ensureAssetLoaded(pf.lib)
                if not HasNamedPtfxAssetLoaded(pf.lib) then goto nextParticle end
                local a = exhaustOffsetFor(vehicle, pf.bone)
                UseParticleFxAssetNextCall(pf.lib)
                local h = StartParticleFxLoopedOnEntityBone(
                    pf.name, vehicle,
                    a.x or 0.0, a.y or 0.0, a.z or 0.0,
                    pf.rx or 0.0, pf.ry or 0.0, pf.rz or 0.0,
                    bi, pf.size, false, false, false
                )
                if h and h ~= 0 then
                    local hard = (ECUConfig.PopHardStop == true)
                    local wait = math.floor(pf.burst
                        or hrsRandRange(pk and pk.burstMs, nil)
                        or ECUConfig.PopBurstMs or 0)
                    if wait > 0 then
                        Citizen.SetTimeout(wait, function()
                            StopParticleFxLooped(h, hard)
                        end)
                    else
                        StopParticleFxLooped(h, hard)
                    end
                end

            elseif off then
                ensureAssetLoaded(pf.lib)
                local rx, ry, rz = getExhaustBoneRot(vehicle, pf.bone)
                UseParticleFxAssetNextCall(pf.lib)
                StartParticleFxNonLoopedOnEntity(
                    pf.name, vehicle,
                    off.x, off.y, off.z,
                    rx + (pf.rx or 0.0), ry + (pf.ry or 0.0), rz + (pf.rz or 0.0),
                    pf.size,
                    false, false, false
                )
            end
            ::nextParticle::
        end
    end
    if fx.glow and type(fx.glow) == 'table' then
        local g = fx.glow
        Citizen.SetTimeout(g.delay or 0, function()
            if not DoesEntityExist(vehicle) then return end
            ensureAssetLoaded(g.lib)
            for _, pt in ipairs(getExhaustPoints(vehicle)) do
                local bi = pt.bone and GetEntityBoneIndexByName(vehicle, pt.bone) or -1
                UseParticleFxAssetNextCall(g.lib)
                local h
                if bi > 0 then
                    local a = pt.adj or { x = 0.0, y = 0.0, z = 0.0 }
                    h = StartParticleFxLoopedOnEntityBone(g.name, vehicle,
                        a.x or 0.0, a.y or 0.0, a.z or 0.0, 0.0, 0.0, 0.0,
                        bi, g.size or 1.0, false, false, false)
                else
                    h = StartParticleFxLoopedOnEntity(g.name, vehicle,
                        pt.off.x, pt.off.y, pt.off.z, 0.0, 0.0, 0.0,
                        g.size or 1.0, false, false, false)
                end
                if h and h ~= 0 then
                    Citizen.SetTimeout(g.dur or 600, function() StopParticleFxLooped(h, false) end)
                end
            end
        end)
    end
    popHeatActive = true
    popHeatUntil = GetGameTimer() + 2500

    playExhaustSound(vehicle)

    if fx.addonPop then
        playAddonPop(vehicle)
    end
    if fx.sound then
        playPopSound(vehicle, fx.stage, fx.soundIdx, isRemote)
        if fx.explosion and not isRemote then
            local ex, ey, ez
            if fx.particles and fx.particles[1] then
                local bi = GetEntityBoneIndexByName(vehicle, fx.particles[1].bone)
                if bi > 0 then
                    local bp = GetWorldPositionOfEntityBone(vehicle, bi)
                    ex, ey, ez = bp.x, bp.y, bp.z
                end
            end
            if not ex then
                local pos = GetEntityCoords(vehicle)
                ex, ey, ez = pos.x, pos.y, pos.z + 0.8
            end
            AddExplosion(ex, ey, ez, 61, 0.0, true, false, 0.0, true)
        end
    end
end

local addonArmed    = false

local function addonPopReady(rpm, gas, brake)
    if not ecuSettings.addonPop then return false end

    local mn = (ecuSettings.addonRpmMin or 0) / 100.0
    local mx = (ecuSettings.addonRpmMax or 100) / 100.0

    if rpm > mx then
        addonArmed = true
        return false
    end

    if addonArmed and rpm >= mn and not gas and not brake then
        addonArmed = false
        return true
    end

    if rpm < mn then
        addonArmed = false
    end
    return false
end

local function rollGlowAddon()
    local activePacks = ecuSettings.flamePacks
    if type(activePacks) ~= 'table' then return nil end
    for _, key in ipairs(activePacks) do
        local pack = ECUConfig.FlamePacks[key]
        if pack and pack.addon and pack.library and pack.name
           and math.random() < (pack.chance or 0.3) then
            return {
                lib   = pack.library, name = pack.name,
                size  = pack.scale or 1.0,
                delay = pack.delay or 100,
                dur   = pack.duration or 600,
            }
        end
    end
    return nil
end

local function buildAddonParticles(vehicle)
    local particles = {}
    local set = ECUConfig.Particles.Large or ECUConfig.Particles.Small
    if not set or #set == 0 then return nil end

    for _, pt in ipairs(getExhaustPoints(vehicle)) do
        local boneName = pt.bone
        do
            local pData = set[math.random(1, #set)]
            local libName, effName, sizeScale = pData.Library, pData.Name, 1.0
            local rx, ry, rz, burst = nil, nil, nil, nil

            local activePacks = ecuSettings.flamePacks
            if type(activePacks) == 'table' and #activePacks > 0 then
                local pack = ECUConfig.FlamePacks[activePacks[math.random(1, #activePacks)]]
                if pack and pack.library and pack.name and not pack.addon then
                    libName, effName, sizeScale = pack.library, pack.name, pack.scale or 1.0
                    if pack.variants and #pack.variants > 0 then
                        effName = pack.variants[math.random(1, #pack.variants)]
                    end
                    local sr = pack.scaleRandom
                    if sr then sizeScale = sizeScale * (sr[1] + math.random() * (sr[2] - sr[1])) end
                    if pack.rotJitter then rx, ry, rz = hrsRandRot(pack.rotJitter) end
                    if type(pack.burstMs) == 'table' then burst = math.floor(hrsRandRange(pack.burstMs, 0)) end
                end
            end

            particles[#particles + 1] = {
                bone = boneName, lib = libName, name = effName,
                ox = pt.off.x, oy = pt.off.y, oz = pt.off.z,
                size = (ECUConfig.AddonPopFlameSize or 1.3) * sizeScale,
                rx = rx, ry = ry, rz = rz, burst = burst,
            }
        end
    end
    return (#particles > 0) and particles or nil
end

local function tryAddonPop(vehicle, rpm, gas, brake)
    if not addonPopReady(rpm, gas, brake) then return end

    local fx = {
        addonPop  = true,
        particles = ECUConfig.AddonPopFlame and buildAddonParticles(vehicle) or nil,
        glow      = ECUConfig.AddonPopFlame and rollGlowAddon() or nil,
    }

    renderFlame(vehicle, fx)

    if not NetworkGetEntityIsNetworked(vehicle) then
        NetworkRegisterEntityAsNetworked(vehicle)
    end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId and netId ~= 0 then
        ECU_POP.push(netId, rpm, fx.addonPop and 1 or 0)
    end
end

spawnFlame = function(vehicle, rpm)
    local soundNeeded = false
    local particles = {}

    for _, pt in ipairs(getExhaustPoints(vehicle)) do
        local boneName = pt.bone
        do
            local flameSize = calculateFlameSize(vehicle, rpm)
            local particleSet = nil

            if ecuSettings.megaFlameMode == 100 then
                particleSet = ECUConfig.Particles.Mega
            elseif ecuSettings.megaFlameMode == 50 then
                if math.random() < 0.5 then
                    particleSet = ECUConfig.Particles.Mega
                elseif flameSize > ECUConfig.FlameThresholds.SmallFlame then
                    particleSet = ECUConfig.Particles.Large
                elseif flameSize > ECUConfig.FlameThresholds.JustSound then
                    particleSet = ECUConfig.Particles.Small
                end
            elseif flameSize > ECUConfig.FlameThresholds.SmallFlame then
                particleSet = ECUConfig.Particles.Large
            elseif flameSize > ECUConfig.FlameThresholds.JustSound then
                particleSet = ECUConfig.Particles.Small
            end

            if particleSet then
                local pData = particleSet[math.random(1, #particleSet)]
                local libName, effName, sizeScale = pData.Library, pData.Name, 1.0
                local rx, ry, rz, burst = nil, nil, nil, nil
                local activePacks = ecuSettings.flamePacks
                if type(activePacks) == 'table' and #activePacks > 0 then
                    local chosenKey = activePacks[math.random(1, #activePacks)]
                    local pack = ECUConfig.FlamePacks[chosenKey]
                    if pack and pack.library and pack.name and not pack.addon then
                        libName  = pack.library
                        effName  = pack.name
                        sizeScale = pack.scale or 1.0
                        if pack.variants and #pack.variants > 0 then
                            effName = pack.variants[math.random(1, #pack.variants)]
                        end
                        local sr = pack.scaleRandom
                        if sr then sizeScale = sizeScale * (sr[1] + math.random() * (sr[2] - sr[1])) end
                        if pack.rotJitter then rx, ry, rz = hrsRandRot(pack.rotJitter) end
                        if type(pack.burstMs) == 'table' then burst = math.floor(hrsRandRange(pack.burstMs, 0)) end
                    end
                end
                particles[#particles+1] = {
                    bone = boneName, lib = libName, name = effName,
                    ox = pt.off.x, oy = pt.off.y, oz = pt.off.z,
                    size = flameSize * sizeScale,
                    rx = rx, ry = ry, rz = rz, burst = burst,
                }
                soundNeeded = true
            elseif flameSize > ECUConfig.FlameThresholds.NoAction then
                soundNeeded = true
            end
        end
    end

    local fx = {
        particles = (#particles > 0) and particles or nil,
        sound     = soundNeeded,
        explosion = soundNeeded and ecuSettings.explosionKnall or false,
        stage     = valveStage(ecuSettings.popsStage),
        soundIdx  = soundNeeded and math.random(1, #ECUConfig.PopSounds) or nil,
        glow      = (#particles > 0) and rollGlowAddon() or nil,
    }

    renderFlame(vehicle, fx)

    if not HRS_LocalOnly and (soundNeeded or fx.particles) then
        if not NetworkGetEntityIsNetworked(vehicle) then
            NetworkRegisterEntityAsNetworked(vehicle)
        end
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        if netId and netId ~= 0 then
            ECU_POP.push(netId, rpm, fx.addonPop and 1 or 0)
        end
    end
end



local npcBlocked  = {}
local npcRefresh  = 0

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if popsEnabled then
            local now = GetGameTimer()

            if now > npcRefresh then
                npcRefresh = now + (ECUConfig.CalmNPCRefresh or 15000)
                npcBlocked = {}
            else
                for p in pairs(npcBlocked) do
                    if not DoesEntityExist(p) then npcBlocked[p] = nil end
                end
            end

            local ped    = PlayerPedId()
            local myc    = GetEntityCoords(ped)
            local radius = ECUConfig.CalmNPCRadius or 40.0

            for _, npc in ipairs(GetGamePool('CPed')) do
                if npc ~= ped and not npcBlocked[npc] and DoesEntityExist(npc)
                   and not IsPedAPlayer(npc)
                   and not IsPedDeadOrDying(npc, true)
                   and NetworkHasControlOfEntity(npc)
                   and #(myc - GetEntityCoords(npc)) < radius
                then
                    SetBlockingOfNonTemporaryEvents(npc, true)
                    npcBlocked[npc] = true
                end
            end
        end
    end
end)

---@return boolean available
---@return boolean enabled
function HRS_PopsState()
    if not isInVehicle or vehBlacklisted then return false, popsEnabled end
    if ecuSettings.exhaustMode ~= 'pops' then return false, popsEnabled end
    if ECUConfig.RequirePartsForFeatures and not featureUnlocked('popbang') then return false, popsEnabled end
    return true, popsEnabled
end

---@return boolean
function HRS_TogglePops()
    if not HRS_PopsState() then return false end

    popsEnabled = not popsEnabled
    notifyLocal(popsEnabled and 'ok' or 'warn', popsEnabled and 'pops_on' or 'pops_off')

    if not popsEnabled then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh ~= 0 and setSmoke then setSmoke(veh, false) end
    end
    updateUI()
    flashHud()
    return true
end



if ECUConfig.EnableDrift then


end

function switchToMap(slot, still)
    if not hasMapSwitch(menuParts) and not hasMapSwitch() then return false end
    slot = tonumber(slot) or 1
    if slot < 1 or slot > 3 then return false end

    ecuMaps[activeMap] = snapshotProfile()

    local ziel = ecuMaps[slot]
    if type(ziel) ~= 'table' then
        ziel = copyTable(ecuMaps[activeMap])
        ecuMaps[slot] = copyTable(ziel)
    end
    local roh = copyTable(ziel)
    roh.maps, roh.activeMap = nil, nil
    applySettingsTable(roh)
    activeMap = slot

    if currentPlate then
        TriggerTokenEvent('sm_ecutuning:saveSettings', currentPlate, json.encode(settingsToTable()))
        local v = GetVehiclePedIsIn(PlayerPedId(), false)
        if v ~= 0 then perfRequest(v) end
    end
    updateUI()
    if not still then notifyLocal('ok', 'map_switched', tostring(slot)) end
    return true
end

local mapDebug = false


local function cycleMap()
    if mapDebug then
        print(('^5[Debug MAP]^7 key pressed. in vehicle: %s, part: %s')
            :format(tostring(isInVehicle),
                    tostring(hasMapSwitch(menuParts) or hasMapSwitch())))
    end
    if not isInVehicle then return end
    if vehBlacklisted then notifyLocal('err', 'veh_blocked') return end
    if not hasMapSwitch(menuParts) and not hasMapSwitch() then
        notifyLocal('warn', 'map_no_part')
        return
    end
    local n = activeMap + 1
    if n > 3 then n = 1 end
    switchToMap(n)
end



interface.callback('selectMap', function(data, cb)
    cb('ok')
    local slot = tonumber(data.slot) or 1

    if type(data.settings) == 'table' then
        applyMenuSettings(data.settings)
    end
    if switchToMap(slot, true) then
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        if veh == 0 and bootVehicle and bootVehicle ~= 0 then veh = bootVehicle end
        local vlabel, vplate = getVehicleLabel(veh)
        sendMenuState(veh, vlabel, vplate)
    end
end)

local function getVehicleInFront()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then return veh end
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local dest = coords + forward * 5.0
    local ray = StartShapeTestRay(coords.x, coords.y, coords.z + 0.5, dest.x, dest.y, dest.z + 0.5, 10, ped, 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)
    if hit == 1 and entity and entity ~= 0 and IsEntityAVehicle(entity) then
        return entity
    end
    local nearest, nearestDist = 0, 5.0
    for veh2 in ecuEnumerateVehicles() do
        local vc = GetEntityCoords(veh2)
        local dist = #(coords - vc)
        if dist < nearestDist then
            nearest = veh2
            nearestDist = dist
        end
    end
    return nearest
end

RegisterCommand('checkcar', function()
    local veh = getVehicleInFront()
    if veh == 0 then
        notifyLocal('warn', 'search_no_vehicle')
        return
    end
    local vlabel, vplate = getVehicleLabel(veh)
    local ped = PlayerPedId()
    notifyLocal('ok', 'search_running')
    TriggerTokenEvent('sm_ecutuning:searchVehicle', vplate, vlabel)
end, false)
RegisterKeyMapping('checkcar', 'Search vehicle for tuning', 'keyboard', ECUConfig.SearchKey or '')

local hideLaeuft = false

RegisterNetEvent('sm_ecutuning:searchHideOffer', function(sucherSrc, plate, opt)
    if hideLaeuft then return end

    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local pos = GetEntityCoords(ped)
        local best, bestD = 0, (opt and opt.distance) or 12.0
        for _, v in ipairs(GetGamePool('CVehicle')) do
            if cleanPlate(GetVehicleNumberPlateText(v) or '') == plate then
                local d = #(pos - GetEntityCoords(v))
                if d < bestD then best, bestD = v, d end
            end
        end
        veh = best
    elseif cleanPlate(GetVehicleNumberPlateText(veh) or '') ~= plate then
        veh = 0
    end
    if veh == 0 then return end

    hideLaeuft = true
    interface.focus(false, false)
    sendNUI({ type = 'hideGame', opt = opt })
    playSound('Highlight_Move', 'DLC_HEIST_PLANNING_BOARD_SOUNDS')

    Citizen.CreateThread(function()
        while hideLaeuft do
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 76, true)
            if IsDisabledControlJustPressed(0, 22) or IsDisabledControlJustPressed(0, 76) then
                sendNUI({ type = 'hideGameHit' })
            end
            Citizen.Wait(0)
        end
    end)

    hideAntwortAn = sucherSrc
end)

interface.callback('hideGameDone', function(data, cb)
    cb('ok')
    hideLaeuft = false
    local treffer = tonumber(data and data.hits) or 0
    TriggerTokenEvent('sm_ecutuning:searchHideResult', hideAntwortAn, treffer)

    if treffer >= 3 then
        notifyLocal('ok', 'hide_ok')
    elseif treffer > 0 then
        notifyLocal('warn', 'hide_part', tostring(treffer))
    else
        notifyLocal('err', 'hide_fail')
    end
end)

RegisterNetEvent('sm_ecutuning:searchScan', function(vehLabel, dauer)
    sendNUI({ type = 'searchScan', label = vehLabel, duration = dauer or 6000 })
end)

RegisterNetEvent('sm_ecutuning:searchResult', function(report)
    if not report then return end
    interface.focus(true, true)
    sendNUI({ type = 'showSearchReport', report = report })
    playSound('Highlight_Move', 'DLC_HEIST_PLANNING_BOARD_SOUNDS')
end)

interface.callback('closeSearchReport', function(_, cb)
    interface.focus(false, false)
    playSound('Cancel', 'HUD_FRONTEND_DEFAULT_SOUNDSET')
    cb('ok')
end)

function ecuEnumerateVehicles()
    return coroutine.wrap(function()
        local handle, veh = FindFirstVehicle()
        if not veh or veh == 0 then EndFindVehicle(handle); return end
        local ok = true
        repeat
            coroutine.yield(veh)
            ok, veh = FindNextVehicle(handle)
        until not ok
        EndFindVehicle(handle)
    end)
end

function antilagShouldAbort(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return true end

    if not IsVehicleDriveable(veh, false) then return true end
    if GetVehicleEngineHealth(veh) <= 0.0 then return true end
    if not GetIsVehicleEngineRunning(veh) then return true end

    if IsControlPressed(0, 72) then return true end

    local roll = math.abs(GetEntityRoll(veh))
    if roll > 75.0 then return true end

    local spd  = GetEntitySpeed(veh)
    local body = GetVehicleBodyHealth(veh)

    if antilagLastBody >= 0.0 and (antilagLastBody - body) > 0.5 then
        antilagLastBody = body
        antilagLastSpd  = spd
        return true
    end
    if antilagLastSpd >= 0.0 and (antilagLastSpd - spd) > 2.5 then
        antilagLastSpd  = spd
        antilagLastBody = body
        return true
    end
    antilagLastSpd  = spd
    antilagLastBody = body

    if antilagCruise > 2.0 then
        if IsEntityInAir(veh) then return true end
        if spd < 2.0 then return true end
        local dropMs = ((ECUConfig.AntiLagMaxSpeedDrop or 15) / 3.6)
        if spd < (antilagCruise - dropMs) then return true end
    end

    local maxT = ECUConfig.AntiLagMaxArmTime or 20000
    if antilagArmedAt > 0 and (GetGameTimer() - antilagArmedAt) > maxT then return true end

    return false
end

CreateThread(function()
    local lastPop = 0
    local origPopsStage = nil
    while true do
        if antilagArmed then
            Wait(0)
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 or veh ~= antilagVehicle or GetPedInVehicleSeat(veh, -1) ~= ped then
                if origPopsStage then ecuSettings.popsStage = origPopsStage; origPopsStage = nil end
                armAntiLag(antilagVehicle ~= 0 and antilagVehicle or veh, false)
            elseif antilagShouldAbort(veh) then
                if origPopsStage then ecuSettings.popsStage = origPopsStage; origPopsStage = nil end
                armAntiLag(veh, false)
            else
                local maxPsi     = antilagMaxPsi()
                local rpmLock    = ecuSettings.antilag.rpmLock
                local gas        = IsControlPressed(0, 71)
                local handbrake  = IsControlPressed(0, 76)
                local speed      = GetEntitySpeed(veh)
                local rolling    = (antilagCruise > 2.0)
                local dt         = GetFrameTime()

                local buildCond
                if rolling then
                    buildCond = gas
                    if buildCond and (not IsEntityInAir(veh)) then
                        local vel = GetEntityVelocity(veh)
                        local hs  = math.sqrt(vel.x * vel.x + vel.y * vel.y)
                        if hs > 0.5 then
                            local f = antilagCruise / hs
                            SetEntityVelocity(veh, vel.x * f, vel.y * f, vel.z)
                        end
                    end
                else
                    buildCond = gas and handbrake
                end

                if buildCond then
                    antilagBuilding = true
                    local rpmTarget = math.min(1.0, rpmLock / 9000.0)
                    if antilagRpmCur <= 0.0 then
                        antilagRpmCur = math.max(GetVehicleCurrentRpm(veh), ECUConfig.AntiLagStartRpm)
                    end
                    if antilagRpmCur < rpmTarget then
                        antilagRpmCur = math.min(rpmTarget, antilagRpmCur + ECUConfig.AntiLagRpmRampPerSec * dt)
                    end
                    SetVehicleCurrentRpm(veh, antilagRpmCur)
                    local rpmReached = (antilagRpmCur >= rpmTarget - 0.03)
                    if rpmReached and antilagPsi < maxPsi then
                        local psiMin  = (ECUConfig.AntiLagLimits and ECUConfig.AntiLagLimits.psiMin) or 5
                        local psiMax2 = (ECUConfig.AntiLagLimits and ECUConfig.AntiLagLimits.psiMax) or 30
                        local tMin    = ECUConfig.AntiLagBuildTimeMin or 1.0
                        local tMax    = ECUConfig.AntiLagBuildTimeMax or 5.0
                        local ratio   = 0.0
                        if psiMax2 > psiMin then
                            ratio = (maxPsi - psiMin) / (psiMax2 - psiMin)
                        end
                        if ratio < 0.0 then ratio = 0.0 elseif ratio > 1.0 then ratio = 1.0 end
                        local buildTime = tMin + ratio * (tMax - tMin)
                        if buildTime < 0.2 then buildTime = 0.2 end
                        local psiPerSec = maxPsi / buildTime
                        antilagPsi = math.min(maxPsi, antilagPsi + psiPerSec * dt)
                    end
                    SetVehicleTurboPressure(veh, antilagPsi / 30.0)

                    if rpmReached then
                        if origPopsStage == nil then
                            origPopsStage = ecuSettings.popsStage
                            ecuSettings.popsStage = 3
                        end
                        local now = GetGameTimer()
                        if now - lastPop > ECUConfig.AntiLagPopInterval then
                            lastPop = now
                            if spawnFlame then spawnFlame(veh, ECUConfig.AntiLagFlameScale or 0.75) end
                        end
                    end

                    if antilagPsi >= maxPsi - 0.1 and not antilagReady then
                        antilagReady = true
                    end
                    if rolling and antilagReady then
                        antilagLaunch(veh, antilagPsi)
                        local bv, bp = veh, antilagPsi
                        CreateThread(function()
                            local t0 = GetGameTimer()
                            while GetGameTimer() - t0 < ECUConfig.AntiLagBoostHold do
                                Wait(0)
                                if DoesEntityExist(bv) then SetVehicleTurboPressure(bv, bp/30.0) end
                            end
                            if DoesEntityExist(bv) then SetVehicleTurboPressure(bv, 0.0) end
                        end)
                        if origPopsStage then ecuSettings.popsStage = origPopsStage; origPopsStage = nil end
                        armAntiLag(veh, false)
                    end

                    if antilagArmed then
                        sendNUI({ type = 'antilagHud', show = true,
                            psi = math.floor(antilagPsi + 0.5),
                            maxPsi = math.floor(maxPsi + 0.5),
                            pct = math.floor((antilagPsi / maxPsi) * 100 + 0.5),
                            ready = antilagReady,
                            mode = rolling and 'roll' or 'stand' })
                    end
                else
                    if antilagBuilding then
                        if (not rolling) and antilagReady and antilagPsi > 0 and not handbrake then
                            antilagLaunch(veh, antilagPsi)
                            local bv, bp = veh, antilagPsi
                            CreateThread(function()
                                local t0 = GetGameTimer()
                                while GetGameTimer() - t0 < ECUConfig.AntiLagBoostHold do
                                    Wait(0)
                                    if DoesEntityExist(bv) then SetVehicleTurboPressure(bv, bp/30.0) end
                                end
                                if DoesEntityExist(bv) then SetVehicleTurboPressure(bv, 0.0) end
                            end)
                            if origPopsStage then ecuSettings.popsStage = origPopsStage; origPopsStage = nil end
                            SetVehicleTurboPressure(veh, 0.0)
                            armAntiLag(veh, false)
                        else
                            if origPopsStage then ecuSettings.popsStage = origPopsStage; origPopsStage = nil end
                            antilagPsi = 0.0; antilagReady = false; antilagBuilding = false; antilagRpmCur = 0.0
                            SetVehicleTurboPressure(veh, 0.0)
                            sendNUI({ type = 'antilagHud', show = true, psi = 0,
                                maxPsi = math.floor(maxPsi+0.5), pct = 0, ready = false,
                                mode = rolling and 'roll' or 'stand' })
                        end
                    end
                end
            end
        else
            Wait(300)
        end
    end
end)

CreateThread(function()
    while true do
        if driftActive then
            Wait(0)
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 or veh ~= driftVehicle or GetPedInVehicleSeat(veh, -1) ~= ped then
                local dv = driftVehicle
                driftActive = false
                driftVehicle = 0
                if dv ~= 0 and DoesEntityExist(dv) then
                    restoreDriftOriginals(dv)
                end
                if ecuOpen then sendNUI({ type = 'driftState', active = false }) end
            else
                local biasFront = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveBiasFront')
                if biasFront == 0.0 then
                    SetVehicleEnginePowerMultiplier(veh, 190.0)
                else
                    SetVehicleEnginePowerMultiplier(veh, 100.0)
                end
                local vmaxKmh = ecuSettings.drift.vmax or ECUConfig.Drift.vmax or 250
                SetEntityMaxSpeed(veh, vmaxKmh / 3.6)
            end
        else
            Wait(500)
        end
    end
end)

local function vehicleInFront()
    local ped   = PlayerPedId()
    local from  = GetEntityCoords(ped)
    local fwd   = GetEntityForwardVector(ped)
    local reach = (ECUConfig.Boot and ECUConfig.Boot.reach) or 5.0
    local to    = from + (fwd * reach)

    local ray = StartShapeTestCapsule(from.x, from.y, from.z + 0.4,
                                      to.x, to.y, to.z + 0.4, 1.2, 2, ped, 7)
    local _, hit, _, _, ent = GetShapeTestResult(ray)
    if hit == 1 and ent and ent ~= 0 and IsEntityAVehicle(ent) then
        return ent
    end

    local best, bestD = nil, reach + 1.0
    for veh in ecuEnumerateVehicles() do
        local d = #(from - GetEntityCoords(veh))
        if d < bestD then best, bestD = veh, d end
    end
    return best
end

local bootRunning = false
local bootProp    = nil
local bootDoneOnce = false
local tabletWanted = false

bootCleanup = function()
    local ped = PlayerPedId()
    tabletWanted = false
    if bootProp and DoesEntityExist(bootProp) then
        DeleteEntity(bootProp)
    end
    bootProp = nil
    ClearPedTasks(ped)
    bootRunning = false
end

local function tabletAnimRunning(ped)
    local B = ECUConfig.Boot or {}
    if not B.animDict or not B.animName then return true end
    return IsEntityPlayingAnim(ped, B.animDict, B.animName, 3)
end

local function attachTablet(ped)
    local B = ECUConfig.Boot or {}

    if B.animDict and B.animName then
        RequestAnimDict(B.animDict)
        local t = GetGameTimer() + 2000
        while not HasAnimDictLoaded(B.animDict) and GetGameTimer() < t do Wait(0) end
        if HasAnimDictLoaded(B.animDict) then
            TaskPlayAnim(ped, B.animDict, B.animName, 3.0, -1.0, -1, 49, 0, false, false, false)
        end
    end

    if bootProp and DoesEntityExist(bootProp) then return end

    local mdl = GetHashKey(B.propModel or 'prop_cs_tablet')
    RequestModel(mdl)
    local t2 = GetGameTimer() + 2000
    while not HasModelLoaded(mdl) and GetGameTimer() < t2 do Wait(0) end
    if not HasModelLoaded(mdl) then return end

    local c = GetEntityCoords(ped)
    bootProp = CreateObject(mdl, c.x, c.y, c.z, true, true, false)

    local po = B.propOffset   or vector3(0.03, 0.00, -0.03)
    local pr = B.propRotation or vector3(20.0, 160.0, 0.0)

    AttachEntityToEntity(bootProp, ped,
        GetPedBoneIndex(ped, B.propBone or 28422),
        po.x, po.y, po.z,
        pr.x, pr.y, pr.z,
        true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(mdl)
end

CreateThread(function()
    while true do
        Wait(700)
        if tabletWanted then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                if bootProp and DoesEntityExist(bootProp) then DeleteEntity(bootProp) end
                bootProp = nil
            elseif (not bootProp) or (not DoesEntityExist(bootProp)) or (not tabletAnimRunning(ped)) then
                attachTablet(ped)
            end
        end
    end
end)

local function startBoot(veh, plate, modelName)
    if bootRunning then return end
    bootRunning = true

    local B   = ECUConfig.Boot or {}
    local ped = PlayerPedId()
    local inCar = IsPedInAnyVehicle(ped, false)

    if not inCar then
        if B.tablet then
            tabletWanted = true
            attachTablet(ped)
        end

        if B.hood and veh and veh ~= 0 and DoesEntityExist(veh) then
            SetVehicleDoorOpen(veh, 4, false, false)
        end
    end

    local dur = bootDoneOnce and (B.replayDuration or 1500) or (B.firstDuration or 10000)

    sendNUI({
        type     = 'ecuBoot',
        speed    = B.speed or 100,
        duration = dur,
        model    = modelName or '',
        plate    = plate or '',
    })

    if B.cancel then
        CreateThread(function()
            while bootRunning do
                Wait(0)
                DisableControlAction(0, 200, true)
                DisableControlAction(0, 322, true)
                if IsDisabledControlJustPressed(0, 200) or IsDisabledControlJustPressed(0, 322) then
                    sendNUI({ type = 'ecuBootStop' })
                    if veh and veh ~= 0 and DoesEntityExist(veh) then
                        SetVehicleDoorShut(veh, 4, false)
                    end
                    pendingOpen = false
                    bootCleanup()
                    return
                end
            end
        end)
    end
end

function ECU_OpenDenied()
    pendingOpen = false
    if bootCleanup then bootCleanup() end
    if bootVehicle and bootVehicle ~= 0 and DoesEntityExist(bootVehicle) then
        SetVehicleDoorShut(bootVehicle, 4, false)
    end
    bootVehicle = nil
end

RegisterNetEvent('sm_ecutuning:openDenied', function()
    if not ecuOpen then ECU_OpenDenied() end
end)

interface.callback('ecuBootDone', function(_, cb)
    cb('ok')
    bootRunning = false
    bootDoneOnce = true

    if pendingOpen then
        if not isInVehicle and bootPlate and bootPlate ~= '' then
            if currentPlate ~= bootPlate then
                currentPlate = bootPlate
                currentParts = {}
                vehBricked   = false
                loadSettingsForPlate(currentPlate)
                TriggerTokenEvent('sm_ecutuning:requestParts', currentPlate)
            end
        end
        (function()
        local v = bootVehicle or GetVehiclePedIsIn(PlayerPedId(), false)
        if v and v ~= 0 and ecuVehicleBlocked(v) then
            notifyLocal('err', 'veh_blocked')
            ECU_OpenDenied()
            return
        end
        TriggerTokenEvent('sm_ecutuning:requestOpen', bootPlate or '',
            (v and v ~= 0 and GetEntityArchetypeName) and GetEntityArchetypeName(v) or nil,
            (v and v ~= 0) and GetVehicleClass(v) or nil, (v and v ~= 0) and VehToNet(v) or 0)
    end)()
    end
end)

function ECU_OpenFromSpot()
    UI.spotRequest = true
    ExecuteCommand('ecutune')
    UI.spotRequest = false
end

RegisterCommand('ecutune', function()
    if ecuOpen then closeECUMenu() return end
    if bootRunning then return end
    UI.fromSpot = UI.spotRequest == true

    local ped   = PlayerPedId()
    local inCar = IsPedInAnyVehicle(ped, false)
    local veh   = inCar and GetVehiclePedIsIn(ped, false) or vehicleInFront()

    local plate = ''
    local mdl   = ''
    if veh and veh ~= 0 and DoesEntityExist(veh) then
        plate = cleanPlate(GetVehicleNumberPlateText(veh)) or ''
        mdl   = GetDisplayNameFromVehicleModel(GetEntityModel(veh)) or ''
    end

    if plate == '' then
        notifyLocal('warn', 'need_vehicle', ECU_LS('t_ecutune'))
        return
    end

    if UI.busy or lib.progressActive() then return end
    UI.busy = true
    local connected = lib.progressBar({
        duration = 2000,
        label = ECU_LS('pb_connect'),
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = not inCar and UI.scanAnim or nil,
        prop = not inCar and UI.scanProp or nil,
    })
    UI.busy = false
    if not connected then return end

    bootPlate   = plate
    bootVehicle = veh
    pendingOpen = true

    if not (ECUConfig.Boot and ECUConfig.Boot.enabled) then
        (function()
        local v = GetVehiclePedIsIn(PlayerPedId(), false)
        if v == 0 then v = bootVehicle or 0 end
        if v ~= 0 and ecuVehicleBlocked(v) then
            notifyLocal('err', 'veh_blocked')
            return
        end
        TriggerTokenEvent('sm_ecutuning:requestOpen', plate,
            (v ~= 0 and GetEntityArchetypeName) and GetEntityArchetypeName(v) or nil,
            v ~= 0 and GetVehicleClass(v) or nil, v ~= 0 and VehToNet(v) or 0)
    end)()
        return
    end

    startBoot(veh, plate, mdl)
end, false)


HRS_DynoBlock = false

function HRS_SetDynoMode(on)
    HRS_DynoBlock = on == true
end

HRS_Notify = notifyLocal
function HRS_GetBoost() return getTotalBoost() end
function HRS_GetParts() return currentParts or {} end

TriggerEvent('chat:addSuggestion', '/ecutune', 'Open the ECU Tune menu')

local lastRpm     = 0.0
local rpmHoldTime = 0

---@param vehicle number|false|nil
local function onVehicleChange(vehicle)
    local inVeh = vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) or false
    if inVeh == isInVehicle then return end
    isInVehicle = inVeh
    if not inVeh then
        rpmHoldTime  = 0
        currentPlate = nil
        currentParts = {}
        vehBricked   = false
        sendNUI({ type = 'forceHide' })
    else
        local plate = GetVehicleNumberPlateText(vehicle)
        if plate then
            currentPlate = cleanPlate(plate)
            currentParts = {}
            vehBricked   = false
            vehBlacklisted = ecuVehicleBlocked(vehicle)
            ecuSettings = defaultSettings()
            ecuMaps     = {}
            activeMap   = 1
            loadSettingsForPlate(currentPlate)
            TriggerTokenEvent('sm_ecutuning:requestParts', currentPlate)
        end
    end
    updateUI()
end

lib.onCache('vehicle', onVehicleChange)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    onVehicleChange(cache.vehicle)
end)

Citizen.CreateThread(function()
    while true do
        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local inVeh   = isInVehicle and vehicle ~= 0

        local popsAllowed = popsEnabled
                            and ecuSettings.exhaustMode == 'pops'
                            and not HRS_DynoBlock
                            and not vehBlacklisted
                            and not (ecuSettings.flammenwerfer.random
                                     and ecuSettings.flammenwerfer.enabled)
        if ECUConfig.RequirePartsForFeatures and not featureUnlocked('popbang') then
            popsAllowed = false
        end

        if not popsAllowed or not inVeh or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            Citizen.Wait(500)
            goto continue
        end

        local rpm   = GetVehicleCurrentRpm(vehicle)
        local gas   = IsControlPressed(0, 71)
        local brake = IsControlPressed(0, 72)
        local speed = GetEntitySpeed(vehicle)

        tryAddonPop(vehicle, rpm, gas, brake)

        local rpmMinF = ecuSettings.rpmMin / 100.0
        local rpmMaxF = ecuSettings.rpmMax / 100.0
        local activeStage = valveStage(ecuSettings.popsStage)
        local activeDuration = ecuSettings.popDuration
        local inRange = (rpm > rpmMinF and rpm < rpmMaxF)

        if not inRange and ecuSettings.pops2Enabled then
            local rpm2MinF = ecuSettings.rpm2Min / 100.0
            local rpm2MaxF = ecuSettings.rpm2Max / 100.0
            if rpm > rpm2MinF and rpm < rpm2MaxF then
                inRange = true
                activeStage = valveStage(ecuSettings.pops2Stage)
                activeDuration = ecuSettings.pop2Duration
            end
        end

        if not inRange and ecuSettings.pops3Enabled then
            local rpm3MinF = ecuSettings.rpm3Min / 100.0
            local rpm3MaxF = ecuSettings.rpm3Max / 100.0
            if rpm > rpm3MinF and rpm < rpm3MaxF then
                inRange = true
                activeStage = valveStage(ecuSettings.pops3Stage)
                activeDuration = ecuSettings.pop3Duration
            end
        end

        local stage = ECUConfig.PopsStages[activeStage] or ECUConfig.PopsStages[2]
        local roll = math.random() <= stage.probability

        if ecuSettings.standPops and gas and not brake and speed < 1.0 and inRange then
            local rpmDiff = math.abs(rpm - lastRpm)
            if rpmDiff < 0.02 then
                rpmHoldTime = rpmHoldTime + 1
            else
                rpmHoldTime = 0
            end

            if rpmHoldTime > 3 and roll then
                spawnFlame(vehicle, rpm)
                Citizen.Wait(activeDuration)
            else
                Citizen.Wait(ecuSettings.addonPop and 50 or 80)
            end
            lastRpm = rpm
            goto continue
        end

        if not gas and not brake then
            if inRange and roll then
                spawnFlame(vehicle, rpm)
                Citizen.Wait(activeDuration)
            else
                Citizen.Wait(ecuSettings.addonPop and 50 or 100)
            end
        else
            Citizen.Wait(ecuSettings.addonPop and 50 or 150)
        end

        ::continue::
    end
end)
local fwOffAt        = 0
local fwLastRpm      = 0.0
local fwRandNext     = 0
local fwRandOff      = 0
local fwRandSerie    = false
local fwRandFein     = false
local fwRandPopAt    = 0
local fwLastPopAt    = 0
local fwLongOn       = false
local fwLongDone     = false

local fwColorHandles = {}

local fwLive = {}

local function fwNoise(s, t)
    return (math.sin(t * s[1] + s[2]) * 0.5
          + math.sin(t * s[3] + s[4]) * 0.3
          + math.sin(t * s[5] + s[6]) * 0.2)
end

local function fwNoiseSeed(speed)
    local sp = speed or 1.0
    return { (2.0 + math.random() * 2.5) * sp, math.random() * 6.283,
             (5.0 + math.random() * 4.0) * sp, math.random() * 6.283,
             (11.0 + math.random() * 6.0) * sp, math.random() * 6.283 }
end

local function fwSpawnColorFlame(veh, asset, effName, nc, pt, rgb)
    local bi = pt.bone and GetEntityBoneIndexByName(veh, pt.bone) or -1
    local scale = hrsRandRange(nc and nc.scaleRandom, 1.0)
    local rx, ry, rz = hrsRandRot(nc and nc.rotJitter)
    local ox, oy, oz
    local h
    UseParticleFxAssetNextCall(asset)
    if bi > 0 then
        local a = pt.adj or { x = 0.0, y = 0.0, z = 0.0 }
        ox, oy, oz = a.x or 0.0, a.y or 0.0, a.z or 0.0
        h = StartParticleFxLoopedOnEntityBone(effName, veh, ox, oy, oz,
            rx, ry, rz, bi, scale, false, false, false)
    else
        ox, oy, oz = pt.off.x, pt.off.y, pt.off.z
        h = StartParticleFxLoopedOnEntity(effName, veh, ox, oy, oz,
            rx, ry, rz, scale, false, false, false)
    end
    if not h or h == 0 then return nil end

    if nc and nc.custom then
        local c = nitroRGBClean(rgb)
        SetParticleFxLoopedColour(h, c.r, c.g, c.b, false)
    end

    local w = nc and nc.wobble
    if type(w) == 'table' then
        fwLive[h] = {
            scale = scale, rx = rx, ry = ry, rz = rz, ox = ox, oy = oy, oz = oz,
            w = w, t0 = GetGameTimer(),
            nS = fwNoiseSeed(w.speed), nX = fwNoiseSeed(w.speed), nZ = fwNoiseSeed(w.speed),
            surgeUntil = 0, surgeAmp = 0.0,
        }
    end
    return h
end

local function fwForget(h)
    fwLive[h] = nil
end

Citizen.CreateThread(function()
    while true do
        if next(fwLive) == nil then
            Citizen.Wait(250)
        else
            Citizen.Wait(30)
            local now = GetGameTimer()
            for h, s in pairs(fwLive) do
                if not DoesParticleFxLoopedExist(h) then
                    fwLive[h] = nil
                else
                    local t = (now - s.t0) / 1000.0
                    local w = s.w
                    if now > s.surgeUntil and math.random() < (w.surge or 0.0) * 0.03 then
                        s.surgeUntil = now + math.random(90, 220)
                        s.surgeAmp = 0.25 + math.random() * 0.35
                    end
                    local surge = (now < s.surgeUntil) and s.surgeAmp or 0.0
                    local k = 1.0 + fwNoise(s.nS, t) * (w.scale or 0.0) + surge
                    if k < 0.3 then k = 0.3 end
                    SetParticleFxLoopedScale(h, s.scale * k)
                    local r = w.rot or 0.0
                    SetParticleFxLoopedOffsets(h, s.ox, s.oy, s.oz,
                        s.rx + fwNoise(s.nX, t) * r,
                        s.ry,
                        s.rz + fwNoise(s.nZ, t) * r)
                end
            end
        end
    end
end)

function nitroCustomEntry()
    local cc = ECUConfig.NitroCustomColor
    if not cc or cc.enabled == false or not cc.asset or not cc.name then return nil end
    return { label = 'Custom colour', asset = cc.asset, name = cc.name, custom = true }
end

function nitroRGBClean(rgb)
    local d = (ECUConfig.NitroCustomColor and ECUConfig.NitroCustomColor.default) or { r = 1.0, g = 0.45, b = 0.08 }
    if type(rgb) ~= 'table' then return { r = d.r, g = d.g, b = d.b } end
    local function c(v, def)
        v = tonumber(v)
        if not v then return def end
        if v < 0.0 then v = 0.0 elseif v > 1.0 then v = 1.0 end
        return v
    end
    return { r = c(rgb.r, d.r), g = c(rgb.g, d.g), b = c(rgb.b, d.b) }
end

function nitroColorEntry(key)
    if key == 'custom' then
        local ce = nitroCustomEntry()
        if ce then return ce, 'custom' end
    end
    local nc = key and ECUConfig.NitroColors[key]
    if nc then return nc, key end
    local d = ECUConfig.DefaultNitroColor
    if d and ECUConfig.NitroColors[d] then return ECUConfig.NitroColors[d], d end
    for _, k in ipairs(ECUConfig.NitroColorOrder or {}) do
        if ECUConfig.NitroColors[k] then return ECUConfig.NitroColors[k], k end
    end
    for k, v in pairs(ECUConfig.NitroColors) do return v, k end
    return nil, nil
end

local nitroConflictWarned = {}

local function loadNitroAssetExclusive(asset)
    if HasNamedPtfxAssetLoaded(asset) then
        loadedAssets[asset] = true
        return true
    end
    RequestNamedPtfxAsset(asset)
    local tries = 0
    while not HasNamedPtfxAssetLoaded(asset) do
        Citizen.Wait(10)
        tries = tries + 1
        if tries > 150 then return false end
    end
    loadedAssets[asset] = true
    return true
end


local function fwNachgluehen(vehicle)
    if not ecuSettings.flammenwerfer.gluehen then return end
    if not vehicle or vehicle == 0 then return end

    local pack = (ECUConfig.FlamePacks or {}).glut
    if not pack or not pack.library or not pack.name then return end
    if not ensureAssetLoaded(pack.library) then return end

    local dauer = pack.duration or 650
    for _, pt in ipairs(getExhaustPoints(vehicle)) do
        local bi = pt.bone and GetEntityBoneIndexByName(vehicle, pt.bone) or -1
        local a  = pt.adj or { x = 0.0, y = 0.0, z = 0.0 }
        UseParticleFxAssetNextCall(pack.library)

        local handle
        if bi ~= -1 then
            handle = StartNetworkedParticleFxLoopedOnEntityBone(pack.name, vehicle,
                a.x, a.y, a.z, 0.0, 0.0, 0.0, bi, pack.scale or 0.4)
        else
            handle = StartNetworkedParticleFxLoopedOnEntity(pack.name, vehicle,
                a.x, a.y, a.z, 0.0, 0.0, 0.0, pack.scale or 0.4)
        end

        if handle then
            Citizen.SetTimeout(dauer, function()
                if DoesParticleFxLoopedExist(handle) then
                    StopParticleFxLooped(handle, false)
                end
            end)
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        vehBlacklisted = (veh ~= 0) and ecuVehicleBlocked(veh) or false
    end
end)

local function fwFlackerPop(vehicle)
    local set = (ECUConfig.Particles or {}).Small
    local pf  = set and set[1]
    local geladen = pf and ensureAssetLoaded(pf.Library)

    local erster
    for _, pt in ipairs(getExhaustPoints(vehicle)) do
        local bi = pt.bone and GetEntityBoneIndexByName(vehicle, pt.bone) or -1
        local a  = pt.adj or { x = 0.0, y = 0.0, z = 0.0 }
        local c  = (bi ~= -1) and GetWorldPositionOfEntityBone(vehicle, bi)
                               or  GetOffsetFromEntityInWorldCoords(vehicle, a.x, a.y, a.z)
        erster = erster or c
        if geladen then
            local rx, ry, rz = getExhaustBoneRot(vehicle, pt.bone)
            UseParticleFxAssetNextCall(pf.Library)
            StartParticleFxNonLoopedOnEntity(pf.Name, vehicle,
                a.x, a.y, a.z, rx, ry, rz, 1.0, false, false, false)
        end
    end
    local c = erster or GetEntityCoords(vehicle)
    AddExplosion(c.x, c.y, c.z, 61, 0.0, true, true, 0.0, true)
    playAusAuswahl(vehicle, ecuSettings.exhaustSounds, ECUConfig.ExhaustSounds,
        (ecuSettings.exhaustVol and ecuSettings.exhaustVol / 100.0)
            or ECUConfig.ExhaustSoundVolume, ECUConfig.ExhaustSoundMaxDist)
end

local function fwKnall(vehicle)
    if not ecuSettings.flammenwerfer.knall then return end
    if not vehicle or vehicle == 0 then return end

    local set = (ECUConfig.Particles or {}).Mega or (ECUConfig.Particles or {}).Large
    local pf  = set and set[1]
    if not pf then return end
    if not ensureAssetLoaded(pf.Library) then return end

    for _, pt in ipairs(getExhaustPoints(vehicle)) do
        local bi = pt.bone and GetEntityBoneIndexByName(vehicle, pt.bone) or -1
        local a  = pt.adj or { x = 0.0, y = 0.0, z = 0.0 }
        local off = (bi ~= -1)
            and GetWorldPositionOfEntityBone(vehicle, bi)
            or  GetOffsetFromEntityInWorldCoords(vehicle, a.x, a.y, a.z)
        local rx, ry, rz = getExhaustBoneRot(vehicle, pt.bone)

        UseParticleFxAssetNextCall(pf.Library)
        StartParticleFxNonLoopedOnEntity(
            pf.Name, vehicle,
            off.x, off.y, off.z,
            rx, ry, rz,
            1.6,
            false, false, false
        )
    end

    playAusAuswahl(vehicle, ecuSettings.exhaustSounds, ECUConfig.ExhaustSounds,
        (ecuSettings.exhaustVol and ecuSettings.exhaustVol / 100.0)
            or ECUConfig.ExhaustSoundVolume, ECUConfig.ExhaustSoundMaxDist)
end

setFWNitro = function(vehicle, enable)
    if fwNitroActive == enable then return end
    fwNitroActive = enable

    if enable then
        local nc, ncKey = nitroColorEntry(ecuSettings.nitroColor)
        if not nc then return end
        ecuSettings.nitroColor = ncKey
        local asset = nc.asset
        local effName = (nc and nc.name) or 'veh_nitrous'
        local isStandard = (asset == 'veh_xs_vehicle_mods')

        if isStandard then
            loadNitroAssetExclusive(asset)
            SetVehicleNitroEnabled(vehicle, true)
            SetVehicleBoostActive(vehicle, true)
            EnableVehicleExhaustPops(vehicle, false)
        else
            if not loadNitroAssetExclusive(asset) then
                print(('[Debug EcuTuning] particle asset "%s.ypt" failed to load'):format(asset))
                fwNitroActive = false
                return
            end
            EnableVehicleExhaustPops(vehicle, false)
            fwColorHandles = {}
            for _, pt in ipairs(getExhaustPoints(vehicle)) do
                local h = fwSpawnColorFlame(vehicle, asset, effName, nc, pt, ecuSettings.nitroRGB)
                if h then fwColorHandles[#fwColorHandles+1] = h end
            end
        end
        lastNitroAsset = asset
    else
        for _, h in ipairs(fwColorHandles) do
            fwForget(h)
            StopParticleFxLooped(h, false)
        end
        fwColorHandles = {}
        SetVehicleNitroEnabled(vehicle, false)
        SetVehicleBoostActive(vehicle, false)
        EnableVehicleExhaustPops(vehicle, true)
        SetVehicleCheatPowerIncrease(vehicle, 1.0)

    end

    if ecuSettings.flammenwerfer.random then return end

    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        if not NetworkGetEntityIsNetworked(vehicle) then
            NetworkRegisterEntityAsNetworked(vehicle)
        end
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        if netId and netId ~= 0 then
            local myc = GetEntityCoords(PlayerPedId())
            TriggerTokenEvent('sm_ecutuning:broadcastFW', netId, enable,
                ecuSettings.nitroColor, { x = myc.x, y = myc.y, z = myc.z },
                ecuSettings.nitroRGB)
        end
    end
end

local function fwRandBroadcast(vehicle, an)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    if not NetworkGetEntityIsNetworked(vehicle) then
        NetworkRegisterEntityAsNetworked(vehicle)
    end
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if not netId or netId == 0 then return end
    local myc = GetEntityCoords(PlayerPedId())
    TriggerTokenEvent('sm_ecutuning:broadcastFWRandom', netId, an,
        ecuSettings.nitroColor, ecuSettings.flammenwerfer.randomPreset,
        { x = myc.x, y = myc.y, z = myc.z }, ecuSettings.nitroRGB)
end

local function remoteEntity(netId, e)
    if not e then return nil end
    local ent = e.ent
    if ent and ent ~= 0 and DoesEntityExist(ent) then return ent end

    local now = GetGameTimer()
    if (now - (e.lastLookup or 0)) < 1000 then return nil end
    e.lastLookup = now

    if NetworkDoesNetworkIdExist(netId) then
        local veh = NetworkGetEntityFromNetworkId(netId)
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            e.ent, e.missSince = veh, nil
            return veh
        end
    end

    e.ent = nil
    e.missSince = e.missSince or now
    return nil
end

local function remoteLost(e)
    return e and e.missSince and (GetGameTimer() - e.missSince) > 10000
end

local fwRemote = {}

local function stopRemoteFW(netId)
    local e = fwRemote[netId]
    if not e then return end
    for _, h in ipairs(e.handles or {}) do
        fwForget(h)
        StopParticleFxLooped(h, false)
    end
    if e.standard then
        local veh = e.ent
        if (not veh or not DoesEntityExist(veh)) and NetworkDoesNetworkIdExist(netId) then
            veh = NetworkGetEntityFromNetworkId(netId)
        end
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            SetVehicleNitroEnabled(veh, false)
        end
    end
    fwRemote[netId] = nil
end

local fwRandRemote = {}

RegisterNetEvent('sm_ecutuning:renderFWRandom', function(netId, an, colorKey, presetKey, rgb)
    if not netId then return end

    if not an then
        fwRandRemote[netId] = nil
        stopRemoteFW(netId)
        return
    end
    if fwRandRemote[netId] then return end
    fwRandRemote[netId] = true

    Citizen.CreateThread(function()
        local rc = {}
        for k, v in pairs(ECUConfig.FlameRandom or {}) do rc[k] = v end
        local pre = (ECUConfig.FlameRandomPresets or {})[presetKey or 'aggressiv']
        if pre then for k, v in pairs(pre) do rc[k] = v end end

        local function zufall(p, a, b)
            p = p or { a, b }
            return math.random(p[1], math.max(p[1], p[2]))
        end

        local an2, off, naechst, popAt = false, 0, 0, 0
        while fwRandRemote[netId] do
            if not NetworkDoesNetworkIdExist(netId) then break end
            local veh = NetworkGetEntityFromNetworkId(netId)
            if not veh or veh == 0 or not DoesEntityExist(veh) then break end
            if GetPedInVehicleSeat(veh, -1) == PlayerPedId() then break end

            local now = GetGameTimer()
            local v   = GetVehicleCurrentRpm(veh) * (rc.refRedline or 9000)

            local phase = 'aus'
            if v >= (rc.fastPopsAbove or 8000) then phase = 'schnell' end
            if v < (rc.flickerFrom or 8000) and v >= (rc.flickerTo or 6500) then phase = 'flacker'
            elseif v < (rc.flickerTo or 6500) and v >= (rc.longFrom or 5000) then phase = 'schnell'
            elseif v < (rc.longFrom or 5000) and v >= (rc.longTo or 4000) then phase = 'lang'
            elseif v < (rc.longTo or 4000) and v >= (rc.slowPopsDown or 3000) then phase = 'langsam'
            elseif v < (rc.slowPopsDown or 3000) then phase = 'aus' end

            if phase == 'lang' then
                if not an2 then
                    TriggerEvent('sm_ecutuning:renderFW', netId, true, colorKey, rgb)
                    an2 = true
                end
            elseif phase == 'flacker' then
                if an2 and now >= off then
                    TriggerEvent('sm_ecutuning:renderFW', netId, false, colorKey, rgb)
                    an2 = false
                    naechst = now + zufall(rc.gap, 180, 320)
                elseif not an2 and now >= naechst then
                    TriggerEvent('sm_ecutuning:renderFW', netId, true, colorKey, rgb)
                    an2 = true
                    off = now + zufall(rc.short, 80, 140)
                end
            else
                if an2 then
                    TriggerEvent('sm_ecutuning:renderFW', netId, false, colorKey, rgb)
                    an2 = false
                end
            end
            Citizen.Wait(0)
        end

        fwRandRemote[netId] = nil
        stopRemoteFW(netId)
    end)
end)

local fwRemoteToken = {}

RegisterNetEvent('sm_ecutuning:renderFW', function(netId, enable, colorKey, rgb)
    if not netId then return end
    if not enable then
        fwRemoteToken[netId] = (fwRemoteToken[netId] or 0) + 1
        stopRemoteFW(netId)
        return
    end
    if not NetworkDoesNetworkIdExist(netId) then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end

    if GetPedInVehicleSeat(veh, -1) == PlayerPedId() then return end

    stopRemoteFW(netId)

    local nc = nitroColorEntry(colorKey)
    if not nc then return end
    local asset   = nc.asset
    local effName = (nc and nc.name) or 'veh_nitrous'
    local isStandard = (asset == 'veh_xs_vehicle_mods')

    local token = (fwRemoteToken[netId] or 0) + 1
    fwRemoteToken[netId] = token
    if not HasNamedPtfxAssetLoaded(asset) then
        if not loadNitroAssetExclusive(asset) then return end
        if fwRemoteToken[netId] ~= token then return end
        if not DoesEntityExist(veh) then return end
    end

    if isStandard then
        SetVehicleNitroEnabled(veh, true)
        fwRemote[netId] = { handles = {}, standard = true, ent = veh }
    else
        local handles = {}
        for _, pt in ipairs(getExhaustPoints(veh)) do
            local h = fwSpawnColorFlame(veh, asset, effName, nc, pt, rgb)
            if h then handles[#handles+1] = h end
        end
        fwRemote[netId] = { handles = handles, standard = false, ent = veh }
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        for netId, e in pairs(fwRemote) do
            if not remoteEntity(netId, e) and remoteLost(e) then
                stopRemoteFW(netId)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(fwRandFein and 0 or 85)

        local fw = ecuSettings.flammenwerfer
        local anyFwOn = fw.enabled or ecuSettings.flammenwerfer2.enabled or ecuSettings.flammenwerfer3.enabled
        if HRS_DynoBlock then anyFwOn = false end
        if anyFwOn and HRS_ValveClosed and HRS_ValveClosed() then anyFwOn = false end
        if not anyFwOn or (ECUConfig.RequirePartsForFeatures and not featureUnlocked('flammenwerfer')) then
            if fwNitroActive then
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if veh ~= 0 then setFWNitro(veh, false) end
            end
            goto fwSkip
        end

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped
           or vehBlacklisted then
            if fwNitroActive then setFWNitro(vehicle, false) end
            goto fwSkip
        end

        if fw.random then
            local now = GetGameTimer()

            local rc = {}
            for k2, v2 in pairs(ECUConfig.FlameRandom or {}) do rc[k2] = v2 end
            local pre = (ECUConfig.FlameRandomPresets or {})[fw.randomPreset or 'aggressiv']
            if pre then
                for k2, v2 in pairs(pre) do rc[k2] = v2 end
            end
            local gas = IsControlPressed(0, 71)

            local ref = rc.refRedline or 9000
            local v   = GetVehicleCurrentRpm(vehicle) * ref

            local function zufall(paar, a, b)
                local p = paar or { a, b }
                return math.random(p[1], math.max(p[1], p[2]))
            end

            local phase = 'aus'
            if v >= (rc.fastPopsAbove or 8000) then
                phase = 'schnell'
            end
            if v < (rc.flickerFrom or 8000) and v >= (rc.flickerTo or 6500) then
                phase = 'flacker'
            elseif v < (rc.flickerTo or 6500) and v >= (rc.longFrom or 5000) then
                phase = 'schnell'
            elseif v < (rc.longFrom or 5000) and v >= (rc.longTo or 4000) then
                phase = 'lang'
            elseif v < (rc.longTo or 4000) and v >= (rc.slowPopsDown or 3000) then
                phase = 'langsam'
            elseif v < (rc.slowPopsDown or 3000) then
                phase = 'aus'
            end

            if not popsEnabled or gas then phase = 'aus' end

            local function pop()
                local alt = ecuSettings.flamePacks
                local altLokal = HRS_LocalOnly
                ecuSettings.flamePacks = rc.popPacks or { 'standard', 'small' }
                HRS_LocalOnly = true
                if spawnFlame then spawnFlame(vehicle, GetVehicleCurrentRpm(vehicle)) end
                HRS_LocalOnly = altLokal
                ecuSettings.flamePacks = alt
                fwLastPopAt = now
            end

            local ruhig = (now - fwLastPopAt) >= (rc.quietBefore or 150)

            if phase == 'aus' then
                if fwNitroActive then setFWNitro(vehicle, false) end
                if fwRandSerie then
                    fwNachgluehen(vehicle)
                    fwRandSerie = false
                    fwRandBroadcast(vehicle, false)
                end
                fwLongDone, fwRandNext, fwRandPopAt = false, 0, 0
                fwRandFein = false
                goto fwSkip
            end

            if not fwRandSerie then
                fwKnall(vehicle)
                fwRandSerie = true
                fwRandBroadcast(vehicle, true)
            end
            fwRandFein = true

            if phase == 'lang' then
                if not fwLongDone and not fwNitroActive and ruhig then
                    setFWNitro(vehicle, true)
                    fwLongOn = true
                end
            else
                if fwLongOn then
                    setFWNitro(vehicle, false)
                    fwNachgluehen(vehicle)
                    fwLongOn, fwLongDone = false, true
                end

                if phase == 'flacker' then
                    if fwNitroActive and now >= fwRandOff then
                        setFWNitro(vehicle, false)
                        fwRandNext  = now + zufall(rc.gap, 180, 320)
                        fwRandPopAt = now + 40
                    elseif not fwNitroActive and now >= fwRandNext and ruhig then
                        setFWNitro(vehicle, true)
                        fwRandOff = now + zufall(rc.short, 80, 140)
                    elseif not fwNitroActive and now >= fwRandPopAt
                           and now < fwRandNext - (rc.quietBefore or 150) then
                        pop()
                        fwRandPopAt = now + zufall(rc.popFast, 150, 180)
                    end
                else
                    if fwNitroActive then setFWNitro(vehicle, false) end
                    if now >= fwRandPopAt then
                        pop()
                        local takt = (phase == 'langsam') and rc.popSlow or rc.popFast
                        fwRandPopAt = now + zufall(takt,
                            phase == 'langsam' and 180 or 150,
                            phase == 'langsam' and 230 or 180)
                    end
                end
            end
            goto fwSkip
        end

        local rpm   = GetVehicleCurrentRpm(vehicle)
        local gas   = IsControlPressed(0, 71)
        local brake = IsControlPressed(0, 72)
        local speed = GetEntitySpeed(vehicle)
        local fwMin = fw.rpmMin / 100.0
        local fwMax = fw.rpmMax / 100.0

        local knallBei = (fw.rpmMax + 1) / 100.0
        local glutBei  = (fw.rpmMin - 1) / 100.0

        if fw.enabled and not gas then
            if fwLastRpm > knallBei and rpm <= knallBei then
                fwKnall(vehicle)
            end
            if fwLastRpm > glutBei and rpm <= glutBei then
                fwNachgluehen(vehicle)
            end
        end
        fwLastRpm = rpm

        local inFwRange = fw.enabled and (rpm >= fwMin and rpm <= fwMax)
        local activeFwDuration = fw.duration or 300
        if not inFwRange and ecuSettings.flammenwerfer2.enabled then
            local f2 = ecuSettings.flammenwerfer2
            if rpm >= (f2.rpmMin/100.0) and rpm <= (f2.rpmMax/100.0) then
                inFwRange = true
                activeFwDuration = f2.duration or 300
            end
        end
        if not inFwRange and ecuSettings.flammenwerfer3.enabled then
            local f3 = ecuSettings.flammenwerfer3
            if rpm >= (f3.rpmMin/100.0) and rpm <= (f3.rpmMax/100.0) then
                inFwRange = true
                activeFwDuration = f3.duration or 300
            end
        end

        if fw.standFlamme and gas and not brake and speed < 1.0 and inFwRange then
            setFWNitro(vehicle, true)
            fwOffAt = 0
        elseif not gas and inFwRange then
            setFWNitro(vehicle, true)
            fwOffAt = GetGameTimer() + activeFwDuration
        else
            if fwNitroActive then
                if fwOffAt > 0 and GetGameTimer() >= fwOffAt then
                    setFWNitro(vehicle, false)
                    fwOffAt = 0
                elseif fwOffAt == 0 then
                    setFWNitro(vehicle, false)
                end
            end
        end

        ::fwSkip::
    end
end)

local function turboFileFor(key)
    for _, s in ipairs(ECUConfig.TurboSounds or {}) do
        if s.key == key then return s.file end
    end
    local first = (ECUConfig.TurboSounds or {})[1]
    return first and first.file or nil
end

local function turboVolume()
    local v = ecuSettings.turboSound and ecuSettings.turboSound.volume
    if type(v) ~= 'number' then return ECUConfig.TurboSound.volume or 0.3 end
    return math.max(0.0, math.min(1.0, v / 100.0))
end

local function sfxAtVehicle(vehicle, src, baseVol)
    if not src or src == '' then return end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
    local cfg  = ECUConfig.TurboSound
    local maxD = cfg.maxDistance or 55.0
    local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle))
    if dist > maxD then return end
    local vol = (baseVol or turboVolume()) * (1.0 - (dist / maxD)) * fremdFaktor(vehicle)
    if vol <= 0.01 then return end
    sendNUI({ type = 'sfx', src = src, vol = vol })
end


Citizen.CreateThread(function()
    local gasSince   = 0
    local gasOffSince = 0
    local charged    = false
    local chargeMs   = 0

    local function dumpFactorFor(chargeMs)
        local cfg = ECUConfig.TurboSound
        local lo  = cfg.dumpChargeMin or 350
        local hi  = math.max(lo + 1, cfg.dumpChargeMax or 700)
        local t   = math.max(0.0, math.min(1.0, (chargeMs - lo) / (hi - lo)))
        return (cfg.dumpVolMin or 0.30) + t * ((cfg.dumpVolMax or 1.00) - (cfg.dumpVolMin or 0.30))
    end

    while true do
        Citizen.Wait(50)

        local ts = ecuSettings.turboSound
        if vehBlacklisted or not (ts.enabled or ts.dumpValve)
           or not featureUnlocked('turbosound') then
            gasSince, gasOffSince, charged, chargeMs = 0, 0, false, 0
            goto tsSkip
        end

        do
            local ped     = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
                gasSince, gasOffSince, charged, chargeMs = 0, 0, false, 0
                goto tsSkip
            end

            local gas = IsControlPressed(0, 71)
            local rpm = GetVehicleCurrentRpm(vehicle)
            local cfg = ECUConfig.TurboSound

            if gas then
                gasOffSince = 0
                if gasSince == 0 then gasSince = GetGameTimer() end
                local held = GetGameTimer() - gasSince

                if not charged
                    and held >= (cfg.spoolTime or 300)
                    and rpm >= ((cfg.minRpm or 30) / 100.0) then
                    charged = true
                end

                if charged then
                    chargeMs = held - (cfg.spoolTime or 300)
                end
            else
                if gasOffSince == 0 then gasOffSince = GetGameTimer() end
                local off = GetGameTimer() - gasOffSince

                if charged and off >= (cfg.liftDebounce or 250) then
                    local netId = NetworkGetEntityIsNetworked(vehicle)
                        and NetworkGetNetworkIdFromEntity(vehicle) or nil
                    local f = dumpFactorFor(chargeMs)
                    local v = vehicle

                    if ts.enabled then
                        local function whistle()
                            if DoesEntityExist(v) then
                                sfxAtVehicle(v, turboFileFor(ts.pick))
                            end
                        end
                        if (cfg.liftDelay or 0) > 0 then
                            Citizen.SetTimeout(cfg.liftDelay, whistle)
                        else
                            whistle()
                        end

                        if netId then ECU_POP.push(netId, turboVolume(), 2) end
                    end

                    if ts.dumpValve then
                        local wait = (cfg.liftDelay or 0) + (cfg.dumpAfter or 200)
                        Citizen.SetTimeout(wait, function()
                            if DoesEntityExist(v) then
                                sfxAtVehicle(v, cfg.dumpFile, turboVolume() * f)
                            end
                        end)
                        if netId then ECU_POP.push(netId, turboVolume() * f, 3) end
                    end

                    gasSince, gasOffSince, charged, chargeMs = 0, 0, false, 0
                end
            end
        end

        ::tsSkip::
    end
end)

local smokeHandles   = {}
local smokeVeh       = 0
local smokeRemote    = {}
local smokeActive    = false
local smokeOffAt     = 0
local smokeAsset     = nil
local smokeLastSound = 0
local smokeCurColor   = nil
local smokeCurDensity = nil

local function resolveSmokeEffect()
    if smokeAsset ~= nil then return smokeAsset end

    local fixed = ECUConfig.Diesel and ECUConfig.Diesel.effect
    if fixed and fixed.asset and fixed.name then
        RequestNamedPtfxAsset(fixed.asset)
        local t = GetGameTimer() + 1500
        while not HasNamedPtfxAssetLoaded(fixed.asset) and GetGameTimer() < t do
            Citizen.Wait(10)
        end
        if HasNamedPtfxAssetLoaded(fixed.asset) then
            smokeAsset = fixed
            return fixed
        end
    end

    for _, e in ipairs(ECUConfig.SmokeEffects or {}) do
        if e.asset and e.name then
            RequestNamedPtfxAsset(e.asset)
            local t = GetGameTimer() + 1500
            while not HasNamedPtfxAssetLoaded(e.asset) and GetGameTimer() < t do
                Citizen.Wait(10)
            end
            if HasNamedPtfxAssetLoaded(e.asset) then
                smokeAsset = e
                return e
            end
        end
    end
    smokeAsset = false
    return false
end

local function playDieselSound(vehicle)
    local cfg = ECUConfig.DieselSound
    if not cfg then return end

    local now = GetGameTimer()
    if (now - smokeLastSound) < (cfg.interval or 900) then return end
    smokeLastSound = now

    if cfg.file and cfg.file ~= '' then
        local maxD = cfg.maxDistance or 60.0
        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(vehicle))
        if dist > maxD then return end
        local vol = (cfg.volume or 0.5) * (1.0 - (dist / maxD)) * fremdFaktor(vehicle)
        if vol <= 0.01 then return end
        sendNUI({ type = 'dieselSound', vol = vol })
    elseif cfg.name and cfg.name ~= '' then
        PlaySoundFromEntity(-1, cfg.name, vehicle,
            (cfg.set ~= '' and cfg.set or nil), false, 0)
    end
end

local function smokeSpawnStep(vehicle, handles, colorKey)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local eff = resolveSmokeEffect()
    if not eff then return end

    local col = ECUConfig.SmokeColors[colorKey or ECUConfig.Diesel.color]
    if col and col.r == nil then col = nil end

    local sf   = smokeFaktor(vehicle)
    local maxP = math.floor((ECUConfig.Diesel.maxParticles or 250) * sf)
    if #handles >= maxP then return end

    local per   = math.max(1, math.floor((ECUConfig.Diesel.spawnPerTick or 2) * sf + 0.5))
    local scale = eff.scale or 1.0

    for _, pt in ipairs(getExhaustPoints(vehicle)) do
        local bi = pt.bone and GetEntityBoneIndexByName(vehicle, pt.bone) or -1
        local a  = pt.adj or { x = 0.0, y = 0.0, z = 0.0 }

        for _ = 1, per do
            if #handles >= maxP then break end

            UseParticleFxAssetNextCall(eff.asset)
            local h
            if bi > 0 then
                h = StartParticleFxLoopedOnEntityBone(
                    eff.name, vehicle,
                    a.x or 0.0, a.y or 0.0, a.z or 0.0,
                    0.0, 0.0, 0.0,
                    bi, scale, false, false, false)
            else
                h = StartParticleFxLoopedOnEntity(
                    eff.name, vehicle,
                    pt.off.x, pt.off.y, pt.off.z, 0.0, 0.0, 0.0,
                    scale, false, false, false)
            end

            if h then
                SetParticleFxLoopedEvolution(h, eff.name, scale, 0)

                if col then
                    SetParticleFxLoopedColour(h, col.r or 0.0, col.g or 0.0, col.b or 0.0, false)
                end
                if ECUConfig.Diesel.alpha then
                    SetParticleFxLoopedAlpha(h, ECUConfig.Diesel.alpha)
                end

                handles[#handles + 1] = h
            end
        end
    end
end

setSmoke = function(vehicle, on)
    if on then
        if smokeActive then return end
        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
        smokeVeh    = vehicle
        smokeActive = true
        smokeSpawnStep(vehicle, smokeHandles, ecuSettings.diesel.color)
    else
        for _, h in ipairs(smokeHandles) do
            StopParticleFxLooped(h, true)
        end
        smokeHandles = {}
        smokeActive  = false
        smokeVeh     = 0
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(ECUConfig.Diesel.tickMs or 50)

        if smokeActive then
            smokeSpawnStep(smokeVeh, smokeHandles, ecuSettings.diesel.color)
        end

        for netId, e in pairs(smokeRemote) do
            local veh = remoteEntity(netId, e)
            if veh then smokeSpawnStep(veh, e.handles, e.color) end
        end
    end
end)

local function stopRemoteSmoke(netId)
    local r = smokeRemote[netId]
    if r then
        for _, h in ipairs(r.handles or {}) do
            StopParticleFxLooped(h, true)
        end
    end
    smokeRemote[netId] = nil
end

RegisterNetEvent('sm_ecutuning:renderDiesel', function(netId, enable, colorKey, density)
    if not netId then return end
    if not enable then stopRemoteSmoke(netId) return end
    if not NetworkDoesNetworkIdExist(netId) then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    if GetPedInVehicleSeat(veh, -1) == PlayerPedId() then return end

    local vorhanden = smokeRemote[netId]
    if vorhanden and vorhanden.color == colorKey then
        vorhanden.ent = veh
        return
    end

    stopRemoteSmoke(netId)

    local handles = {}
    smokeRemote[netId] = { handles = handles, ent = veh, color = colorKey }
    smokeSpawnStep(veh, handles, colorKey)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        for netId, e in pairs(smokeRemote) do
            if not remoteEntity(netId, e) and remoteLost(e) then
                stopRemoteSmoke(netId)
            end
        end
    end
end)

Citizen.CreateThread(function()
    local lastBroadcast = nil
    local lastSentAt    = 0

    local function broadcast(vehicle, on)
        local now = GetGameTimer()
        local auffrischen = on and (now - lastSentAt) >= 3000
        if on == lastBroadcast and not auffrischen then return end

        if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end
        if not NetworkGetEntityIsNetworked(vehicle) then
            NetworkRegisterEntityAsNetworked(vehicle)
        end
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        if not netId or netId == 0 then return end

        local myc = GetEntityCoords(PlayerPedId())
        TriggerTokenEvent('sm_ecutuning:broadcastDiesel', netId, on,
            ecuSettings.diesel.color or 'original', nil,
            { x = myc.x, y = myc.y, z = myc.z })
        lastBroadcast = on
        lastSentAt    = now
    end

    while true do
        Citizen.Wait(90)

        local dz = ecuSettings.diesel

        local turboOk = (ECUConfig.Diesel.requiresTurbo ~= true) or featureUnlocked('turbosound')
        if ecuSettings.exhaustMode ~= 'diesel' or not popsEnabled or not turboOk then
            if smokeActive then
                local v = GetVehiclePedIsIn(PlayerPedId(), false)
                setSmoke(v, false)
                broadcast(v, false)
            end
            goto dzSkip
        end

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            if smokeActive then
                setSmoke(vehicle, false)
                broadcast(vehicle, false)
            end
            goto dzSkip
        end

        do
            local gas   = IsControlPressed(0, 71)
            local brake = IsControlPressed(0, 72)
            local speed = GetEntitySpeed(vehicle)

            local wantSmoke = gas and not brake
            if wantSmoke and speed < 1.0 and not dz.standSmoke then
                wantSmoke = false
            end

            if wantSmoke then
                if not smokeActive then
                    setSmoke(vehicle, true)
                end
                broadcast(vehicle, true)
                smokeOffAt = GetGameTimer() + (dz.duration or 400)
                if dz.sound then playDieselSound(vehicle) end
            elseif smokeActive then
                if smokeOffAt > 0 and GetGameTimer() >= smokeOffAt then
                    setSmoke(vehicle, false)
                    broadcast(vehicle, false)
                    smokeOffAt = 0
                end
            end
        end

        ::dzSkip::
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, h in ipairs(smokeHandles) do StopParticleFxLooped(h, false) end
    for netId in pairs(smokeRemote) do
        for _, h in ipairs(smokeRemote[netId].handles or {}) do
            StopParticleFxLooped(h, false)
        end
    end
end)

turboHeat           = 30.0
local HEAT = { driftTo = nil, driftAt = 0, settle = 0.0, reviveAt = 0, blowHandles = {}, blowAsset = nil, exhaustBlowAsset = nil }

function HRS_GetTurboHeat() return turboHeat end
function HRS_SetTurboHeat(v)
    local hi = (ECUConfig.TurboHeat and ECUConfig.TurboHeat.blowAt) or 140
    turboHeat = math.max(0.0, math.min(hi, tonumber(v) or turboHeat))
end


local function resolveBlowEffect()
    if HEAT.blowAsset ~= nil then return HEAT.blowAsset end
    for _, e in ipairs((ECUConfig.TurboHeat and ECUConfig.TurboHeat.smokeEffects) or {}) do
        if e.asset and e.name then
            RequestNamedPtfxAsset(e.asset)
            local t = GetGameTimer() + 1500
            while not HasNamedPtfxAssetLoaded(e.asset) and GetGameTimer() < t do
                Citizen.Wait(10)
            end
            if HasNamedPtfxAssetLoaded(e.asset) then
                HEAT.blowAsset = e
                return e
            end
        end
    end
    HEAT.blowAsset = false
    return false
end


local function resolveExhaustBlowEffect()
    if HEAT.exhaustBlowAsset ~= nil then return HEAT.exhaustBlowAsset end
    local e = ECUConfig.TurboHeat and ECUConfig.TurboHeat.exhaustEffect
    if e and e.asset and e.name then
        RequestNamedPtfxAsset(e.asset)
        local t = GetGameTimer() + 1500
        while not HasNamedPtfxAssetLoaded(e.asset) and GetGameTimer() < t do
            Citizen.Wait(10)
        end
        if HasNamedPtfxAssetLoaded(e.asset) then
            HEAT.exhaustBlowAsset = e
            return e
        end
    end
    HEAT.exhaustBlowAsset = resolveBlowEffect()
    return HEAT.exhaustBlowAsset
end

local function blowSmoke(vehicle, seconds)
    local eff = resolveBlowEffect()
    if not eff or not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    local cfg   = ECUConfig.TurboHeat
    local col   = ECUConfig.SmokeColors[cfg.smokeColor] or ECUConfig.SmokeColors.white
    local scale = math.max(0.2, (cfg.smokeDensity or 200) / 100.0)
    local mine  = {}

    local exEff = resolveExhaustBlowEffect() or eff

    for _, pt in ipairs(getExhaustPoints(vehicle)) do
        local bi = pt.bone and GetEntityBoneIndexByName(vehicle, pt.bone) or -1
        UseParticleFxAssetNextCall(exEff.asset)
        local h
        if bi > 0 then
            local a = pt.adj or { x = 0.0, y = 0.0, z = 0.0 }
            h = StartParticleFxLoopedOnEntityBone(
                exEff.name, vehicle, a.x or 0.0, a.y or 0.0, a.z or 0.0,
                0.0, 0.0, 0.0,
                bi, scale, false, false, false)
        else
            h = StartParticleFxLoopedOnEntity(
                exEff.name, vehicle, pt.off.x, pt.off.y, pt.off.z, 0.0, 0.0, 0.0,
                scale, false, false, false)
        end
        if h then
            SetParticleFxLoopedColour(h, col.r or 0.9, col.g or 0.9, col.b or 0.9, false)
            mine[#mine+1] = h
            HEAT.blowHandles[#HEAT.blowHandles+1] = h
        end
    end

    local hood = (ECUConfig.TurboHeat.hoodSmoke == true)
        and GetEntityBoneIndexByName(vehicle, 'bonnet') or -1
    if hood > 0 then
        UseParticleFxAssetNextCall(eff.asset)
        local h = StartParticleFxLoopedOnEntityBone(
            eff.name, vehicle, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            hood, scale, false, false, false)
        if h then
            SetParticleFxLoopedColour(h, col.r or 0.9, col.g or 0.9, col.b or 0.9, false)
            mine[#mine+1] = h
            HEAT.blowHandles[#HEAT.blowHandles+1] = h
        end
    end

    Citizen.SetTimeout((seconds or 25) * 1000, function()
        for _, h in ipairs(mine) do StopParticleFxLooped(h, false) end
    end)
end

RegisterNetEvent('sm_ecutuning:renderTurboBlow', function(netId)
    if not netId or not NetworkDoesNetworkIdExist(netId) then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    if GetPedInVehicleSeat(veh, -1) == PlayerPedId() then return end
    blowSmoke(veh, (ECUConfig.TurboHeat.smokeTime or 25000) / 1000)
end)

Citizen.CreateThread(function()
    if not (ECUConfig.TurboHeat and ECUConfig.TurboHeat.enabled) then return end
    local last = GetGameTimer()
    local hudOn = false

    while true do
        Citizen.Wait(120)

        local now = GetGameTimer()
        local dt  = (now - last) / 1000.0
        last = now

        local cfg = ECUConfig.TurboHeat
        if not cfg.enabled then
            if hudOn then sendNUI({ type = 'turboHeat', show = false }) hudOn = false end
            goto thSkip
        end

        do
            local ped     = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            local driving = vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped
            local hasTurbo = false
            if driving then
                if featureUnlocked('turboheat') then
                    hasTurbo = true
                elseif cfg.allCars ~= false and not vehBlacklisted then
                    local cls = GetVehicleClass(vehicle)
                    hasTurbo = cls ~= 13 and cls ~= 14 and cls ~= 15 and cls ~= 16 and cls ~= 21
                end
            end

            if not hasTurbo then
                local amb = cfg.ambient or 30
                if turboHeat > amb then
                    turboHeat = math.max(amb, turboHeat - (cfg.idleCool or 1.5) * dt)
                end
                if hudOn then sendNUI({ type = 'turboHeat', show = false }) hudOn = false end
                goto thSkip
            end

            if popHeatActive and GetGameTimer() > popHeatUntil then
                popHeatActive = false
            end

            local myPlate = cleanPlate(GetVehicleNumberPlateText(vehicle) or '')
            turboBlown = (myPlate ~= '' and blownPlates[myPlate] ~= nil)
            HEAT.reviveAt = turboBlown and blownPlates[myPlate] or 0

            if turboBlown and GetVehicleEngineHealth(vehicle) >= 990.0
               and GetVehicleBodyHealth(vehicle) >= 990.0 then
                blownPlates[myPlate] = nil
                turboBlown = false
                TriggerTokenEvent('sm_ecutuning:engineRepairedFree', myPlate)
                HRS_SetTurboHeat(cfg.heatAfterBlow or 105)
            end

            if turboBlown then
                SetVehicleEngineOn(vehicle, false, true, true)
                turboHeat = math.max(cfg.ambient or 30,
                                     turboHeat - (cfg.idleCool or 1.5) * dt)

                if not cfg.needsRepair and now >= HEAT.reviveAt then
                    turboBlown = false
                    blownPlates[myPlate] = nil
                    SetVehicleEngineHealth(vehicle, 1000.0)
                    SetVehicleUndriveable(vehicle, false)
                    turboHeat = cfg.heatAfterBlow or 105
                    notifyLocal('ok', 'turbo_cooled')
                end

                if cfg.showHud then
                    sendNUI({ type = 'turboHeat', show = true,
                              heat = math.floor(turboHeat),
                              state = cfg.needsRepair and 'dead' or 'blown',
                              lo = cfg.ambient or 30, hi = cfg.blowAt or 140,
                              secs = cfg.needsRepair and 0
                                     or math.max(0, math.ceil((HEAT.reviveAt - now) / 1000)) })
                    hudOn = true
                end
                goto thSkip
            end

            local onDyno = HRS_DynoHeatActive == true

            local rpm = GetVehicleCurrentRpm(vehicle) * 100.0
            local gas = IsControlPressed(0, 71)
            local running = GetIsVehicleEngineRunning(vehicle)

            local amb   = cfg.ambient      or 30
            local operLo = cfg.operatingMin or 94
            local operHi = cfg.operatingMax or 105

            if onDyno then
            elseif running and gas and rpm >= (cfg.heatFromRpm or 55) then
                local span   = math.max(1.0, 100.0 - (cfg.heatFromRpm or 55))
                local factor = math.min(1.0, (rpm - (cfg.heatFromRpm or 55)) / span + 0.35)

                local relMul = 1.0
                if perfCurrent and perfCurrent.rel and perfCurrent.rel < 100 then
                    local fehlt = (100 - perfCurrent.rel) / 50.0
                    relMul = 1.0 + fehlt * ((cfg.heatPerReliability or 2.0) - 1.0)
                end

                local stage = 0
                for _, p in ipairs(currentParts or {}) do
                    if p == 'ecustage3' then stage = 3
                    elseif p == 'ecustage2' and stage < 2 then stage = 2
                    elseif p == 'ecustage1' and stage < 1 then stage = 1 end
                end
                local stageMul = (cfg.stageHeat and cfg.stageHeat[stage]) or 1.0

                turboHeat = turboHeat + (cfg.heatPerSec or 1.2) * factor * relMul * stageMul * dt
                if popHeatActive then
                    local zu = (ecuSettings.exhaustMode == 'diesel')
                        and (cfg.popHeatDiesel or 0.6)
                        or  (cfg.popHeatPerSec or 0.9)
                    turboHeat = turboHeat + zu * dt
                end
                if stage == 0 and cfg.stockMaxHeat then
                    turboHeat = math.min(turboHeat, cfg.stockMaxHeat)
                end
                HEAT.settle = math.min(1.0, HEAT.settle + factor * dt / 6.0)
            elseif running then
                if popHeatActive then
                    local zu = (ecuSettings.exhaustMode == 'diesel')
                        and (cfg.popHeatDiesel or 0.6)
                        or  (cfg.popHeatPerSec or 0.9)
                    turboHeat = math.min((cfg.blowAt or 140), turboHeat + zu * dt)
                end

                if turboHeat < operLo then
                    turboHeat = math.min(operLo, turboHeat + (cfg.warmUpPerSec or 1.6) * dt)
                    HEAT.driftTo = nil
                elseif turboHeat > operHi then
                    local coolMul = 1.0
                    for _, p in ipairs(currentParts or {}) do
                        local b = cfg.coolBonusParts and cfg.coolBonusParts[p]
                        if b then coolMul = coolMul + b end
                    end
                    turboHeat = math.max(operHi, turboHeat - (cfg.coolPerSec or 3.0) * coolMul * dt)
                    HEAT.driftTo = nil
                else
                    HEAT.settle = math.max(0.0,
                        HEAT.settle - dt / math.max(1, cfg.settleSeconds or 90))

                    local baseLo = cfg.driftMin or operLo
                    local baseHi = cfg.driftMax or math.min(operHi, operLo + 7)
                    local hotLo  = math.max(baseLo, operHi - 5)
                    local hotHi  = operHi

                    local dLo   = baseLo + (hotLo - baseLo) * HEAT.settle
                    local dHi   = baseHi + (hotHi - baseHi) * HEAT.settle
                    local every = (cfg.driftEverySec or 6) * 1000

                    if not HEAT.driftTo or (now - HEAT.driftAt) > every then
                        HEAT.driftAt = now
                        HEAT.driftTo = dLo + math.random() * math.max(0.1, dHi - dLo)
                    end

                    local speed = cfg.driftSpeed or 0.8
                    if turboHeat < HEAT.driftTo then
                        turboHeat = math.min(HEAT.driftTo, turboHeat + speed * dt)
                    else
                        turboHeat = math.max(HEAT.driftTo, turboHeat - speed * dt)
                    end
                end
            else
                turboHeat = math.max(amb, turboHeat - (cfg.idleCool or 1.5) * dt)
            end
            turboHeat = math.max(0.0, math.min(cfg.blowAt or 140, turboHeat))

            if turboHeat >= (cfg.blowAt or 140) then
                turboBlown    = true
                HEAT.reviveAt = now + (cfg.deadTime or 25000)
                local bp = cleanPlate(GetVehicleNumberPlateText(vehicle) or '')
                if bp ~= '' then
                    blownPlates[bp] = HEAT.reviveAt
                    TriggerTokenEvent('sm_ecutuning:engineBlown', bp)
                end

                local c = GetEntityCoords(vehicle)
                AddExplosion(c.x, c.y, c.z + 0.5, 61, 0.0, true, true, 0.0, true)

                SetVehicleEngineHealth(vehicle, cfg.engineHealth or 120.0)
                SetVehicleEngineOn(vehicle, false, true, true)

                blowSmoke(vehicle, (cfg.smokeTime or 25000) / 1000)

                if NetworkGetEntityIsNetworked(vehicle) then
                    TriggerTokenEvent('sm_ecutuning:broadcastTurboBlow',
                        NetworkGetNetworkIdFromEntity(vehicle),
                        { x = c.x, y = c.y, z = c.z })
                end

                notifyLocal('warn', 'turbo_blown')
            end

            if cfg.showHud then
                local state = 'ok'
                if turboHeat >= (cfg.critAt or 130) then state = 'crit'
                elseif turboHeat > (cfg.greenMax or 115) then state = 'warn' end
                sendNUI({ type = 'turboHeat', show = true,
                          heat = math.floor(turboHeat), state = state,
                          lo = amb, hi = cfg.blowAt or 140 })
                hudOn = true
            end
        end

        ::thSkip::
    end
end)


local exhaustEditBone = '*'





Citizen.CreateThread(function()
    local lastGear = 0
    while true do
        Citizen.Wait(60)

        if not popsEnabled or not ecuSettings.schaltPop or (ECUConfig.RequirePartsForFeatures and not featureUnlocked('schaltpop')) then
            lastGear = 0
            goto spSkip
        end

        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            lastGear = 0
            goto spSkip
        end

        local gear = GetVehicleCurrentGear(vehicle)
        local rpm  = GetVehicleCurrentRpm(vehicle)
        local gas  = IsControlPressed(0, 71)

        if gear > lastGear and lastGear > 0 and gas and rpm > 0.3 then
            spawnFlame(vehicle, rpm)
            playShiftSound(vehicle)
        end

        lastGear = gear
        ::spSkip::
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    updateUI()
end)

Citizen.CreateThread(function()
    local sputterCd = 0
    while true do
        if vehBricked then
            Citizen.Wait(0)
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                local tryingStart = IsControlPressed(0, 71) or IsControlPressed(0, 72)
                local now = GetGameTimer()

                if tryingStart and now > sputterCd then
                    SetVehicleEngineOn(veh, true, false, true)
                    Citizen.Wait(math.random(120, 280))
                    SetVehicleEngineOn(veh, false, true, true)
                    local v = GetEntityVelocity(veh)
                    SetEntityVelocity(veh, v.x, v.y, v.z + 0.04)
                    sputterCd = now + math.random(600, 1100)
                else
                    SetVehicleEngineOn(veh, false, false, true)
                end
                SetVehicleUndriveable(veh, true)
            end
        else
            Citizen.Wait(500)
        end
    end
end)

Citizen.CreateThread(function()
    if not (ECUConfig.ShopBlip and ECUConfig.ShopBlip.enabled) then return end
    for _, loc in ipairs(ECUConfig.ShopLocations) do
        local blip = AddBlipForCoord(loc.x, loc.y, loc.z)
        SetBlipSprite(blip, ECUConfig.ShopBlip.sprite)
        SetBlipColour(blip, ECUConfig.ShopBlip.color)
        SetBlipScale(blip, ECUConfig.ShopBlip.scale or 0.9)
        SetBlipAlpha(blip, ECUConfig.ShopBlip.alpha or 255)
        SetBlipAsShortRange(blip, ECUConfig.ShopBlip.shortRange == true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(ECUConfig.ShopBlip.name)
        EndTextCommandSetBlipName(blip)
    end
end)

Citizen.CreateThread(function()
    local interact = exports.rhd_interact
    local locs = ECUConfig.ShopLocations
    local dist = ECUConfig.ShopInteractDistance or 2.0
    local shopJobs = {}
    for i = 1, #ECUConfig.MechanicJobs do shopJobs[ECUConfig.MechanicJobs[i]] = true end

    local function canUseShop()
        if shopOpen or cache.vehicle then return false end
        if ECUConfig.ShopAccess ~= 'mechanic' then return true end

        local job = QBPlayerData.job
        return job and shopJobs[job.name] or false
    end

    for i = 1, #locs do
        local loc = locs[i]
        interact:addCoords({
            id = 'sm_ecutuning_shop_' .. i,
            coords = vec3(loc.x, loc.y, loc.z),
            options = {
                {
                    label = 'Tuning Shop',
                    icon = 'wrench',
                    distance = dist,
                    canInteract = canUseShop,
                    onSelect = function() TriggerTokenEvent('sm_ecutuning:requestShop') end,
                },
            },
        })
    end
end)

ecuSealed = nil

function HRS_HearOthers()
    return GetResourceKvpString('hrs_ecutuning_hearothers') ~= '0'
end
interface.callback('setHearOthers', function(data, cb)
    SetResourceKvp('hrs_ecutuning_hearothers', (data and data.on == false) and '0' or '1')
    cb('ok')
end)
if (ECUConfig.EngineVolume or {}).hearCommand then
    RegisterCommand(ECUConfig.EngineVolume.hearCommand, function()
        local on = not HRS_HearOthers()
        SetResourceKvp('hrs_ecutuning_hearothers', on and '1' or '0')
        notifyLocal('ok', on and 'loudcars_on' or 'loudcars_off')
    end, false)
end

function HRS_ValveToggle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return end
    if vehBlacklisted then return end
    if not featureUnlocked('exhaustvalve') then notifyLocal('warn', 'valve_no_part') return end
    local closed = Entity(veh).state.hrsValve == 1
    if NetworkGetEntityIsNetworked(veh) then
        TriggerTokenEvent('sm_ecutuning:valveToggle', VehToNet(veh), not closed)
    end
    HRS_ValveLocal = (not closed) and 1 or 0
    local c = ECUConfig.EngineVolume or {}
    if c.sound then sendNUI({ type = 'sfx', src = 'sounds/' .. c.sound, vol = c.soundVol or 0.8 }) end
    notifyLocal('ok', closed and 'valve_opened' or 'valve_closed')
end

interface.callback('setDrift', function(data, cb)
    if data and (data.on == true) ~= (driftActive == true) then toggleDrift() end
    cb({ on = driftActive == true })
end)

interface.callback('setAntiLag', function(data, cb)
    if data and (data.on == true) ~= (antilagArmed == true) then toggleAntiLag() end
    cb({ on = antilagArmed == true })
end)

interface.callback('setValve', function(data, cb)
    local v = GetVehiclePedIsIn(PlayerPedId(), false)
    if v ~= 0 and data then
        local open = Entity(v).state.hrsValve ~= 1
        if (data.open == true) ~= open then HRS_ValveToggle() end
    end
    cb({ open = v == 0 or Entity(v).state.hrsValve ~= 1 })
end)

ECU_POP = { buf = {}, n = 0, net = 0, first = 0, armed = false }

function ECU_POP.flush()
    local q = ECU_POP
    q.armed = false
    if q.n == 0 then return end
    local b = q.buf
    for i = q.n + 1, #b do b[i] = nil end
    q.n = 0
    TriggerTokenEvent('sm_ecutuning:broadcastPop', q.net, b)
end

---@param netId number
---@param value number
---@param kind number
function ECU_POP.push(netId, value, kind)
    local q = ECU_POP
    if not netId or netId == 0 then return end
    if q.net ~= netId then
        if q.n > 0 then ECU_POP.flush() end
        q.net = netId
    end
    if q.n >= 18 then return end
    local now = GetGameTimer()
    if q.n == 0 then q.first = now end
    local b = q.buf
    b[q.n + 1] = math.min(400, now - q.first)
    b[q.n + 2] = math.floor(math.max(0.0, math.min(1.0, tonumber(value) or 0.0)) * 100 + 0.5)
    b[q.n + 3] = kind or 0
    q.n = q.n + 3
    if not q.armed then
        q.armed = true
        Citizen.SetTimeout(250, ECU_POP.flush)
    end
end

---@param set table?
---@param packs table
---@return string?, string?, number, number?, number?, number?, number?
function ECU_POP.pick(set, packs)
    if not set or #set == 0 then return nil, nil, 1.0 end
    local pData = set[math.random(1, #set)]
    local libName, effName, sizeScale = pData.Library, pData.Name, 1.0
    local rx, ry, rz, burst
    if #packs > 0 then
        local pack = ECUConfig.FlamePacks[packs[math.random(1, #packs)]]
        if pack and pack.library and pack.name and not pack.addon then
            libName, effName, sizeScale = pack.library, pack.name, pack.scale or 1.0
            if pack.variants and #pack.variants > 0 then
                effName = pack.variants[math.random(1, #pack.variants)]
            end
            local sr = pack.scaleRandom
            if sr then sizeScale = sizeScale * (sr[1] + math.random() * (sr[2] - sr[1])) end
            if pack.rotJitter then rx, ry, rz = hrsRandRot(pack.rotJitter) end
            if type(pack.burstMs) == 'table' then burst = math.floor(hrsRandRange(pack.burstMs, 0)) end
        end
    end
    return libName, effName, sizeScale, rx, ry, rz, burst
end

---@param packs table
---@return table?
function ECU_POP.glow(packs)
    for i = 1, #packs do
        local pack = ECUConfig.FlamePacks[packs[i]]
        if pack and pack.addon and pack.library and pack.name and math.random() < (pack.chance or 0.3) then
            return { lib = pack.library, name = pack.name, size = pack.scale or 1.0, delay = pack.delay or 100, dur = pack.duration or 600 }
        end
    end
    return nil
end

---@param veh number
---@param cfg table
---@param rpm number
---@param addon boolean
---@return table?
function ECU_POP.build(veh, cfg, rpm, addon)
    local packs = type(cfg.pk) == 'table' and cfg.pk or {}
    local pts = getExhaustPoints(veh)
    local particles = {}
    if addon then
        if ECUConfig.AddonPopFlame then
            local set = ECUConfig.Particles.Large or ECUConfig.Particles.Small
            for i = 1, #pts do
                local pt = pts[i]
                local libName, effName, sizeScale, rx, ry, rz, burst = ECU_POP.pick(set, packs)
                if libName then
                    particles[#particles + 1] = { bone = pt.bone, lib = libName, name = effName, ox = pt.off.x, oy = pt.off.y, oz = pt.off.z, size = (ECUConfig.AddonPopFlameSize or 1.3) * sizeScale, rx = rx, ry = ry, rz = rz, burst = burst }
                end
            end
        end
        return { addonPop = true, particles = #particles > 0 and particles or nil, glow = ECUConfig.AddonPopFlame and ECU_POP.glow(packs) or nil }
    end
    local stIdx = tonumber(cfg.st) or 2
    local stage = ECUConfig.PopsStages[stIdx] or ECUConfig.PopsStages[2]
    local base = stage.flameSize
    local mega = tonumber(cfg.mg) or 0
    if mega > 0 then base = base * ECUConfig.MegaFlameMultiplier end
    local engineMod = GetVehicleMod(veh, 11)
    if engineMod > 0 then base = base + engineMod * 0.15 end
    local turbo = GetVehicleTurboPressure(veh)
    if turbo > 0 then base = base + turbo * 0.3 end
    local th = ECUConfig.FlameThresholds
    local soundNeeded = false
    for i = 1, #pts do
        local pt = pts[i]
        local size = base * rpm
        if ECUConfig.FlameVariation > 0 then size = size + math.random(0, ECUConfig.FlameVariation) / 100 end
        size = math.max(0, size)
        local set
        if mega == 100 then
            set = ECUConfig.Particles.Mega
        elseif mega == 50 and math.random() < 0.5 then
            set = ECUConfig.Particles.Mega
        elseif size > th.SmallFlame then
            set = ECUConfig.Particles.Large
        elseif size > th.JustSound then
            set = ECUConfig.Particles.Small
        end
        if set then
            local libName, effName, sizeScale, rx, ry, rz, burst = ECU_POP.pick(set, packs)
            if libName then
                particles[#particles + 1] = { bone = pt.bone, lib = libName, name = effName, ox = pt.off.x, oy = pt.off.y, oz = pt.off.z, size = size * sizeScale, rx = rx, ry = ry, rz = rz, burst = burst }
            end
            soundNeeded = true
        elseif size > th.NoAction then
            soundNeeded = true
        end
    end
    if #particles == 0 and not soundNeeded then return nil end
    return {
        particles = #particles > 0 and particles or nil,
        sound = soundNeeded,
        stage = stIdx,
        soundIdx = soundNeeded and math.random(1, #ECUConfig.PopSounds) or nil,
        glow = #particles > 0 and ECU_POP.glow(packs) or nil,
    }
end

---@param veh number
---@param cfg table
---@param r number
---@param a number
function ECU_POP.play(veh, cfg, r, a)
    if not DoesEntityExist(veh) then return end
    local value = (tonumber(r) or 0) / 100
    if a == 2 or a == 3 then
        local tcfg = ECUConfig.TurboSound or {}
        if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(veh)) > (tcfg.maxDistance or 55.0) then return end
        if a == 2 and cfg.tp then
            sfxAtVehicle(veh, turboFileFor(cfg.tp), value)
        elseif a == 3 and cfg.td and tcfg.dumpFile then
            Citizen.SetTimeout(tcfg.dumpAfter or 200, function()
                if DoesEntityExist(veh) then sfxAtVehicle(veh, tcfg.dumpFile, value) end
            end)
        end
        return
    end
    if not cfg.st then return end
    local fx = ECU_POP.build(veh, cfg, value, a == 1)
    if fx then renderFlame(veh, fx, true) end
end

RegisterNetEvent('sm_ecutuning:renderPop', function(netId, arr)
    if type(arr) ~= 'table' or not netId or not NetworkDoesNetworkIdExist(netId) then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return end
    if GetPedInVehicleSeat(veh, -1) == PlayerPedId() then return end
    local cfg = Entity(veh).state.hrsFx
    if type(cfg) ~= 'table' then return end
    for i = 1, #arr - 2, 3 do
        local t, r, a = tonumber(arr[i]) or 0, arr[i + 1], arr[i + 2]
        if t <= 0 then
            ECU_POP.play(veh, cfg, r, a)
        else
            Citizen.SetTimeout(t, function() ECU_POP.play(veh, cfg, r, a) end)
        end
    end
end)

interface.callback('resetAll', function(_, cb)
    cb('ok')
    local plate = menuPlate or currentPlate
    local v = GetVehiclePedIsIn(PlayerPedId(), false)
    if v == 0 and bootVehicle and bootVehicle ~= 0 and DoesEntityExist(bootVehicle) then v = bootVehicle end
    if not plate or plate == '' or v == 0 then return end
    TriggerTokenEvent('sm_ecutuning:resetSettings', plate, VehToNet(v), GetEntityArchetypeName and GetEntityArchetypeName(v) or nil)
end)

RegisterNetEvent('sm_ecutuning:settingsReset', function(plate)
    if plate ~= currentPlate or not ecuOpen then return end
    local v = GetVehiclePedIsIn(PlayerPedId(), false)
    if v == 0 and bootVehicle and bootVehicle ~= 0 and DoesEntityExist(bootVehicle) then v = bootVehicle end
    local vlabel, vplate = getVehicleLabel(v)
    sendMenuState(v, vlabel, vplate)
end)

do
    local exportWrapper = require 'export_wrapper'
    local PART_BY_ITEM = {}
    for key, def in pairs(ECUConfig.Parts) do
        if def.item then PART_BY_ITEM[def.item] = key end
    end

    exportWrapper('sm_ecutuning', 'useObd', function()
        ExecuteCommand('ecutune')
    end)

    exportWrapper('sm_ecutuning', 'usePart', function(data)
        local key = data and PART_BY_ITEM[data.name]
        if key then TriggerEvent('sm_ecutuning:tryInstallFromItem', key) end
    end)

    exportWrapper('sm_ecutuning', 'useRepair', function()
        TriggerEvent('sm_ecutuning:tryRepairFromItem')
    end)

    exportWrapper('sm_ecutuning', 'getTuneStatus', function(vehicle)
        local st = UI.status
        if type(vehicle) ~= 'number' or vehicle == 0 or st.veh ~= vehicle or st.at == 0 then return nil end
        return { pops = st.pops, flame = st.flame, mode = st.label }
    end)
end

CreateThread(function()
    local IDLE = 30000
    while true do
        Wait(5000)
        if ECU_FrameMounted() and not isInVehicle and not ecuOpen and not shopOpen
            and not installing and not hideLaeuft and not bootRunning
            and not IsNuiFocused()
            and GetGameTimer() - ECU_FrameUsedAt() > IDLE
            and not (HRS_DynoBusy and HRS_DynoBusy()) then
            ECU_UnmountFrame()
        end
    end
end)
