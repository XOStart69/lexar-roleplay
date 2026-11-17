local config = localmodule 'config.shared'
local exportWrapper = require 'export_wrapper'
local infoui = exports.rhd_infoui
local hasFrame = interface.init(false)

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetWaterHeight = GetWaterHeight
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local DisableControlAction = DisableControlAction
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local random = math.random
local rad, cos, sin, abs = math.rad, math.cos, math.sin, math.abs

local IDLE_DICT, IDLE_CLIP = 'amb@world_human_stand_fishing@idle_a', 'idle_a'
local CAST_DICT, CAST_CLIP = 'throwing@animation', 'throwing_clip'
local FLOAT_MODEL = `prop_cs_burger_01`
local ROD_BONE = 18905
local STRIKE_CONTROL = config.strikeControl
local STRIKE_WINDOW = config.strikeWindow
local SEA_LEVELS = config.seaLevels
local SEA_LABELS = config.seaLevelLabels
local KEYS = config.keys
local GACOR_INFO = 'sm_netfish:gacor'
local IMAGE_PATH = 'nui://ox_inventory/web/images/%s.png'
local PROBE_ANGLES = { 0, 45, 90, 135, 180, 225, 270, 315 }
local PROBE_DISTANCES = { 30.0, 80.0, 200.0, 500.0 }
local MELEE_CONTROLS = { 24, 25, 140, 141, 142, 257, 263, 264 }
local WATER_OFFSETS = { { 0, 0 }, { 3, 0 }, { -3, 0 }, { 0, 3 }, { 0, -3 }, { 3, 3 }, { -3, -3 }, { 3, -3 }, { -3, 3 } }

local state = {
    phase = 'idle',
    rod = nil,
    rodCfg = nil,
    bait = nil,
    level = 1,
    catchBonus = 0,
    pole = nil,
    anchor = nil,
    rope = nil,
    fish = nil,
    origin = nil,
}

local ui = { mounted = false, ready = false, dashboard = false, dashboardData = nil }
local seaCache = { value = 'shore', coords = nil, at = 0 }
local staticData

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ title = 'Mancing', description = description, type = kind or 'inform' })
end

---@param action string
---@param data? table
local function send(action, data)
    if ui.ready then
        interface.send({ action = action, data = data or {} })
    end
end

local function ensureFrame()
    if not hasFrame or ui.mounted then return end
    ui.mounted = true
    interface.show()
end

local function releaseFrame()
    if state.phase ~= 'idle' or ui.dashboard or not ui.mounted then return end
    SetTimeout(100, function()
        if state.phase ~= 'idle' or ui.dashboard or not ui.mounted then return end
        ui.mounted = false
        ui.ready = false
        interface.hide()
    end)
end

---@param mode? 'keyboard'|'cursor'
local function setFocus(mode)
    if mode == 'cursor' then
        interface.focus(true, true)
    elseif mode == 'keyboard' then
        interface.focus(true, false)
    else
        interface.focus(false, false)
    end
end

---@return string
local function seaLevel()
    local coords = GetEntityCoords(cache.ped)
    local now = GetGameTimer()
    if seaCache.coords and now - seaCache.at < 30000 and #(coords - seaCache.coords) < 50.0 then
        return seaCache.value
    end

    local closest
    for i = 1, #PROBE_DISTANCES do
        local dist = PROBE_DISTANCES[i]
        for j = 1, #PROBE_ANGLES do
            local angle = rad(PROBE_ANGLES[j])
            local found, groundZ = GetGroundZFor_3dCoord(coords.x + cos(angle) * dist, coords.y + sin(angle) * dist, 1000.0, false)
            if found and groundZ > 0.1 then
                closest = dist
                break
            end
        end
        if closest then break end
    end

    closest = closest or 9999.0
    local value = closest >= SEA_LEVELS.deep_sea and 'deep_sea' or closest >= SEA_LEVELS.sea and 'sea' or 'shore'
    seaCache.value, seaCache.coords, seaCache.at = value, coords, now
    return value
end

local function syncHud()
    send('hud', {
        fishing = state.phase ~= 'idle',
        phase = state.phase,
        rod = state.rodCfg and state.rodCfg.label,
        bait = state.bait,
        sea = state.phase ~= 'idle' and SEA_LABELS[seaLevel()] or nil,
        keys = KEYS,
    })
end

---@return boolean
local function nearWater()
    local coords = GetEntityCoords(cache.ped)
    for i = 1, #WATER_OFFSETS do
        local offset = WATER_OFFSETS[i]
        local found, waterZ = GetWaterHeight(coords.x + offset[1], coords.y + offset[2], coords.z)
        if found and abs(coords.z - waterZ) <= config.nearWaterDistance then return true end
    end
    return false
end

---@param ped number
---@return boolean
local function pedBusy(ped)
    return IsEntityDead(ped) or IsPedRagdoll(ped) or IsPedInAnyVehicle(ped, true) or IsPedSwimming(ped) or IsPedFalling(ped) or IsPedClimbing(ped)
end

local function playIdle()
    if pcall(lib.requestAnimDict, IDLE_DICT, 3000) then
        TaskPlayAnim(cache.ped, IDLE_DICT, IDLE_CLIP, 2.0, -2.0, -1, 51, 0, false, false, false)
    end
end

local function clearLine()
    if state.rope then
        DeleteRope(state.rope)
        state.rope = nil
    end
    if state.anchor and DoesEntityExist(state.anchor) then
        DeleteEntity(state.anchor)
    end
    state.anchor = nil
end

---@param stopServer boolean
local function stopFishing(stopServer)
    if state.phase == 'idle' then return end

    local token = state.fish and state.fish.token
    state.phase = 'idle'
    state.fish = nil
    clearLine()

    if state.pole and DoesEntityExist(state.pole) then
        DeleteEntity(state.pole)
    end
    state.pole = nil

    StopAnimTask(cache.ped, IDLE_DICT, IDLE_CLIP, 1.0)
    LocalPlayer.state.hide_itemattach = false
    StopGameplayCamShaking(true)
    setFocus()
    send('stop')
    syncHud()

    if stopServer then
        CreateThread(function()
            if token then lib.callback.await('sm_netfish:finish', false, token, 'fail') end
            lib.callback.await('sm_netfish:stop', false)
        end)
    end

    releaseFrame()
end

local function backToReady()
    if state.phase == 'idle' then return end
    state.fish = nil
    clearLine()
    setFocus()
    StopGameplayCamShaking(true)
    state.phase = 'ready'
    playIdle()
    syncHud()
end

local function watchSession()
    CreateThread(function()
        while state.phase ~= 'idle' do
            Wait(1000)
            local ped = cache.ped
            if state.phase == 'idle' then break end
            if pedBusy(ped) then
                stopFishing(true)
                break
            end
            if (state.phase == 'ready' or state.phase == 'waiting') and not IsEntityPlayingAnim(ped, IDLE_DICT, IDLE_CLIP, 3) then
                stopFishing(true)
                break
            end
        end
    end)
end

---@param item string
local function startFishing(item)
    local rodCfg = config.rods[item]
    if not rodCfg then return end

    local ped = cache.ped
    if IsPedInAnyVehicle(ped, false) then return notify('Tidak bisa memancing saat berkendara!', 'error') end
    if IsPedSwimming(ped) then return notify('Tidak bisa memancing saat berenang!', 'error') end
    if not nearWater() then return notify('Kamu harus berada dekat air untuk mancing!', 'error') end

    local ok, info, needLevel = lib.callback.await('sm_netfish:start', false, item)
    if not ok then
        if info == 'level' then notify(('Level kamu tidak mencukupi! (Butuh Lvl %d)'):format(needLevel), 'error') end
        return
    end

    if not pcall(lib.requestModel, rodCfg.model, 5000) then
        lib.callback.await('sm_netfish:stop', false)
        return notify('Model pancingan gagal dimuat.', 'error')
    end

    ClearPedTasks(ped)
    local coords = GetEntityCoords(ped)
    local pole = CreateObject(joaat(rodCfg.model), coords.x, coords.y, coords.z, true, false, false)
    SetModelAsNoLongerNeeded(rodCfg.model)
    AttachEntityToEntity(pole, ped, GetPedBoneIndex(ped, ROD_BONE), 0.1, 0.05, 0.0, 60.0, 70.0, 160.0, true, true, false, true, 1, true)

    state.rod, state.rodCfg, state.pole = item, rodCfg, pole
    state.level, state.catchBonus, state.bait = info.level, info.catchBonus or 0, info.bait
    state.phase = 'ready'
    LocalPlayer.state.hide_itemattach = true

    playIdle()
    ensureFrame()
    syncHud()
    watchSession()
    notify(('Tekan [%s] untuk melempar kail, [%s] untuk menyimpan pancingan.'):format(KEYS.cast, KEYS.hide))
end

---@return vector3
local function rodTip()
    local _, maxDim = GetModelDimensions(GetEntityModel(state.pole))
    return GetOffsetFromEntityInWorldCoords(state.pole, maxDim.x, maxDim.y, maxDim.z)
end

---@param target vector3
local function placeLine(target)
    if not pcall(lib.requestModel, FLOAT_MODEL, 3000) then return end
    local anchor = CreateObject(FLOAT_MODEL, target.x, target.y, target.z, false, false, false)
    SetModelAsNoLongerNeeded(FLOAT_MODEL)
    FreezeEntityPosition(anchor, true)
    SetEntityCollision(anchor, false, false)
    state.anchor = anchor

    if not RopeAreTexturesLoaded() then
        RopeLoadTextures()
        local deadline = GetGameTimer() + 3000
        while not RopeAreTexturesLoaded() and GetGameTimer() < deadline do Wait(0) end
    end

    local tip = rodTip()
    local length = #(tip - target)
    local rope = AddRope(tip.x, tip.y, tip.z, 0.0, 0.0, 0.0, length, 5, length, 1.0, 0, false, false, false, 1.0, false)
    AttachEntitiesToRope(rope, state.pole, anchor, tip.x, tip.y, tip.z, target.x, target.y, target.z, length, false, false, 0, 0)
    state.rope = rope
end

local finishCatch

---@param fish table
local function strike(fish)
    state.phase = 'bite'
    state.fish = fish
    syncHud()
    send('bite', { duration = STRIKE_WINDOW })
    ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.03)
    if fish.chance == 'Legendary' or fish.chance == 'Mythic' then
        notify('Ada yang besar menyambar!', 'warning')
    end

    local deadline = GetGameTimer() + STRIKE_WINDOW
    local struck = false
    while state.phase == 'bite' and GetGameTimer() < deadline do
        DisableControlAction(0, STRIKE_CONTROL, true)
        for i = 1, #MELEE_CONTROLS do
            DisableControlAction(0, MELEE_CONTROLS[i], true)
        end
        DisablePlayerFiring(cache.playerId, true)
        if IsDisabledControlJustPressed(0, STRIKE_CONTROL) then
            struck = true
            break
        end
        Wait(0)
    end
    StopGameplayCamShaking(true)

    if state.phase ~= 'bite' then return end
    if not struck then
        send('biteEnd')
        notify('Ikannya kabur, kamu terlambat menarik.', 'error')
        lib.callback.await('sm_netfish:finish', false, fish.token, 'fail')
        return backToReady()
    end

    state.phase = 'reel'
    syncHud()
    send('reel', { chance = fish.chance, minigame = fish.minigame })
    setFocus('keyboard')
end

---@param power number
local function castLine(power)
    if state.phase ~= 'aiming' then return end
    state.phase = 'casting'
    syncHud()

    local ped = cache.ped
    if pcall(lib.requestAnimDict, CAST_DICT, 3000) then
        TaskPlayAnim(ped, CAST_DICT, CAST_CLIP, 2.0, 1.0, 1800, 48, 0, false, false, false)
    end
    Wait(1500)
    if state.phase ~= 'casting' then return end

    local minDist, maxDist = config.castDistance[1], config.castDistance[2]
    local distance = minDist + (maxDist - minDist) * math.min(1.0, math.max(0.0, (tonumber(power) or 0) / 100))
    local coords = GetEntityCoords(ped)
    local target = coords + GetEntityForwardVector(ped) * distance
    local found, waterZ = GetWaterHeight(target.x, target.y, coords.z)

    if not found then
        notify('Kail tidak jatuh ke air. Coba arah lain.', 'error')
        return backToReady()
    end

    placeLine(vector3(target.x, target.y, waterZ))
    playIdle()
    state.phase = 'waiting'
    state.origin = coords
    syncHud()

    local waitTime = random(config.waitTime[1], config.waitTime[2]) / state.rodCfg.timeMultiplier * (1 - state.catchBonus / 100)
    local startAt = GetGameTimer()

    while state.phase == 'waiting' and GetGameTimer() - startAt < waitTime do
        if #(GetEntityCoords(cache.ped) - state.origin) > 2.5 then
            notify('Kamu bergerak, kail ditarik kembali.', 'error')
            return backToReady()
        end
        Wait(250)
    end
    if state.phase ~= 'waiting' then return end

    local fish = lib.callback.await('sm_netfish:roll', false, seaLevel())
    if state.phase ~= 'waiting' then return end
    if not fish then
        notify('Tidak ada ikan yang menyambar.', 'error')
        state.bait = nil
        return backToReady()
    end

    state.bait = nil
    strike(fish)
end

---@param outcome 'keep'|'release'
finishCatch = function(outcome)
    local fish = state.fish
    if not fish then return backToReady() end

    local ok, result = lib.callback.await('sm_netfish:finish', false, fish.token, outcome)
    if ok and result then
        if fish.notAFish then
            notify(('Kamu memancing %s!'):format(fish.label), 'warning')
        elseif outcome == 'keep' then
            notify(('%s disimpan (+%d XP).'):format(fish.label, result.exp), 'success')
        else
            notify(('%s dilepas (+%d XP).'):format(fish.label, result.exp), 'inform')
        end
        if result.full then notify('Tas kamu penuh, tangkapan tidak masuk.', 'error') end
        if result.best then notify('Rekor ikan terbaik baru!', 'success') end
    elseif not ok then
        notify('Tangkapan tidak valid.', 'error')
    end
    backToReady()
end

---@return table
local function buildStatic()
    if staticData then return staticData end

    local special = config.baits[config.specialBait]
    local fishes = {}
    for i = 1, #config.fishes do
        local fish = config.fishes[i]
        if not fish.notAFish then
            local isSpecial = fish.chance == 'Legendary' or fish.chance == 'Mythic'
            fishes[#fishes + 1] = {
                label = fish.label,
                chance = fish.chance,
                image = fish.item and IMAGE_PATH:format(fish.item),
                sea = fish.seaLevel and SEA_LABELS[fish.seaLevel] or 'Semua',
                bait = isSpecial and special.label or 'Apa saja',
            }
        end
    end

    local shop = {}
    for item, rod in pairs(config.rods) do
        shop[#shop + 1] = { item = item, label = rod.label, price = rod.price, level = rod.level, kind = 'rod', image = IMAGE_PATH:format(item) }
    end
    for item, bait in pairs(config.baits) do
        if bait.price then
            shop[#shop + 1] = { item = item, label = bait.label .. ' Bait', price = bait.price, level = bait.level or 1, kind = 'bait', image = IMAGE_PATH:format(item) }
        end
    end
    table.sort(shop, function(a, b)
        if a.kind ~= b.kind then return a.kind == 'rod' end
        if a.level ~= b.level then return a.level < b.level end
        return a.price < b.price
    end)

    staticData = {
        fishes = fishes,
        shop = shop,
        upgrades = config.upgrades,
        quests = config.quests,
        rarities = config.rarities,
        rarityLabels = config.rarityLabels,
        maxQuantity = config.shopMaxQuantity,
    }
    return staticData
end

local function openDashboard()
    if state.phase ~= 'idle' then return notify('Simpan pancinganmu dulu.', 'error') end
    if ui.dashboard then return end

    local data = lib.callback.await('sm_netfish:dashboard', false)
    if not data then return end

    ui.dashboard = true
    ui.dashboardData = data
    ensureFrame()
    send('dashboard', { profile = data, static = buildStatic() })
    setFocus('cursor')
end

local function closeDashboard()
    if not ui.dashboard then return end
    ui.dashboard = false
    ui.dashboardData = nil
    setFocus()
    send('closeDashboard')
    releaseFrame()
end

if hasFrame then
    interface.callback('ready', function(_, cb)
        ui.ready = true
        cb({})
        syncHud()
        if ui.dashboard and ui.dashboardData then
            send('dashboard', { profile = ui.dashboardData, static = buildStatic() })
            setFocus('cursor')
        end
    end)

    interface.callback('cast', function(data, cb)
        cb({})
        if state.phase == 'aiming' then
            CreateThread(function() castLine(type(data) == 'table' and data.power or 0) end)
        end
    end)

    interface.callback('reelResult', function(data, cb)
        cb({})
        if state.phase ~= 'reel' then return end
        setFocus()

        local fish = state.fish
        if not (type(data) == 'table' and data.win) then
            notify('Ikannya lepas!', 'error')
            CreateThread(function()
                lib.callback.await('sm_netfish:finish', false, fish.token, 'fail')
                backToReady()
            end)
            return
        end

        if fish.notAFish then
            CreateThread(function() finishCatch('keep') end)
            return
        end

        state.phase = 'result'
        syncHud()
        send('result', {
            label = fish.label,
            chance = fish.chance,
            weight = fish.weight,
            length = fish.length,
            image = fish.item and IMAGE_PATH:format(fish.item),
            exp = math.floor(config.baseExp * (config.expMultiplier[fish.chance] or 1)),
        })
        setFocus('cursor')
    end)

    interface.callback('resolve', function(data, cb)
        cb({})
        if state.phase ~= 'result' then return end
        setFocus()
        local keep = type(data) == 'table' and data.keep == true
        CreateThread(function() finishCatch(keep and 'keep' or 'release') end)
    end)

    interface.callback('closeDashboard', function(_, cb)
        cb({})
        closeDashboard()
    end)

    interface.callback('buy', function(data, cb)
        if type(data) ~= 'table' then return cb({ ok = false }) end
        local ok, message = lib.callback.await('sm_netfish:buy', false, data.item, data.quantity, data.method)
        cb({ ok = ok == true, message = message })
    end)

    interface.callback('buyUpgrade', function(data, cb)
        if type(data) ~= 'table' then return cb({ ok = false }) end
        local ok, result = lib.callback.await('sm_netfish:buyUpgrade', false, data.name, data.method)
        if ok then
            ui.dashboardData = result
            cb({ ok = true, profile = result })
        else
            cb({ ok = false, message = result })
        end
    end)
end

RegisterCommand('netfish_cast', function()
    if state.phase == 'ready' then
        if not state.bait then return notify('Pasang umpan dulu sebelum melempar!', 'error') end
        state.phase = 'aiming'
        syncHud()
        send('aim')
    elseif state.phase == 'aiming' then
        send('aimRelease')
    end
end, false)

RegisterCommand('netfish_hide', function()
    if state.phase == 'ready' or state.phase == 'aiming' or state.phase == 'waiting' then
        stopFishing(true)
    end
end, false)

RegisterCommand('netfish_removebait', function()
    if state.phase ~= 'ready' or not state.bait then return end
    CreateThread(function()
        if lib.callback.await('sm_netfish:removeBait', false) then
            state.bait = nil
            syncHud()
            notify('Kamu melepas umpanmu.')
        end
    end)
end, false)

RegisterKeyMapping('netfish_cast', 'Mancing: lempar kail', 'keyboard', KEYS.cast)
RegisterKeyMapping('netfish_hide', 'Mancing: simpan pancingan', 'keyboard', KEYS.hide)
RegisterKeyMapping('netfish_removebait', 'Mancing: lepas umpan', 'keyboard', KEYS.removeBait)

exportWrapper('sm_netfish', 'rod', function(data)
    if state.phase ~= 'idle' then return stopFishing(true) end
    local item = type(data) == 'table' and data.name
    if item then CreateThread(function() startFishing(item) end) end
end)

exportWrapper('sm_netfish', 'bait', function(data)
    if state.phase == 'idle' then return notify('Pegang pancingan dulu!', 'error') end
    if state.bait then return notify('Umpan masih terpasang.', 'error') end
    local item = type(data) == 'table' and data.name
    if not item then return end

    CreateThread(function()
        local ok, label = lib.callback.await('sm_netfish:equipBait', false, item)
        if ok then
            state.bait = label
            syncHud()
            notify(('Umpan %s terpasang.'):format(label), 'success')
        elseif label == 'has_bait' then
            notify('Umpan masih terpasang.', 'error')
        end
    end)
end)

exportWrapper('sm_netfish', 'GetSeaLevel', function()
    seaCache.at = 0
    notify(('Tingkat air saat ini: %s'):format(SEA_LABELS[seaLevel()]))
end)

exportWrapper('sm_netfish', 'isFishing', function() return state.phase ~= 'idle' end)
exportWrapper('sm_netfish', 'getPlayerFishingLvl', function() return state.level end)

RegisterNetEvent('sm_netfish:client:levelUp', function(level)
    if source == '' then return end
    state.level = level
    send('levelUp', { level = level })
    notify(('Naik level mancing! Sekarang level %d.'):format(level), 'success')
end)

AddEventHandler('baseevents:onPlayerDied', function()
    stopFishing(true)
end)

AddEventHandler('sm_netfish:client:forceClose', function()
    stopFishing(true)
    closeDashboard()
end)

CreateThread(function()
    local blip = config.blip
    for i = 1, #config.peds do
        local ped = config.peds[i]
        local mapBlip = AddBlipForCoord(ped.coords.x, ped.coords.y, ped.coords.z)
        SetBlipSprite(mapBlip, blip.sprite)
        SetBlipScale(mapBlip, blip.scale)
        SetBlipColour(mapBlip, blip.color)
        SetBlipAsShortRange(mapBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(blip.label)
        EndTextCommandSetBlipName(mapBlip)

        exports[cache.resource]:addPed({
            model = ped.model,
            coords = { ped.coords },
            renderDistance = 40.0,
            scenario = 'WORLD_HUMAN_GUARD_STAND',
            targetOptions = {
                {
                    name = 'sm_netfish_dashboard',
                    icon = 'fas fa-fish',
                    label = 'Buka Dashboard Mancing',
                    distance = 2.0,
                    onSelect = openDashboard,
                },
            },
        })
    end

    for i = 1, #config.gacorSpots do
        local spot = config.gacorSpots[i]
        lib.points.new({
            coords = spot.coords,
            distance = spot.radius,
            onEnter = function()
                infoui:show({ id = GACOR_INFO, title = 'Spot Mancing Gacor', icon = 'fa-solid fa-fish', description = 'Peluang ikan langka lebih tinggi di sini.' })
            end,
            onExit = function()
                infoui:remove(GACOR_INFO)
            end,
        })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    if state.phase ~= 'idle' then
        clearLine()
        if state.pole and DoesEntityExist(state.pole) then DeleteEntity(state.pole) end
        LocalPlayer.state.hide_itemattach = false
    end
    infoui:remove(GACOR_INFO)
end)
