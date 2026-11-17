local ci = {}
local activeMission = nil
local fotoCount = 0
local fotoTargetName = nil

local sharedConfig = localmodule('config.shared')
local blipModule   = require 'modules.blipHandle.client'

interface.init(false)

local cleanDirCfg = {
    sampleStep = 2.0,
    arrowSpacing = 4.0,
    arrowLength = 1.2,
    arrowWidth = 0.6,
    routeHeight = 0.15,
    updateInterval = 150,
    routeColor = { r = 64, g = 200, b = 255, a = 180 },
    arrowColor = { r = 0, g = 255, b = 180, a = 220 },
    markerEnabled = true,
    markerType = 2,
    markerLift = 1.5,
    markerScale = { x = 3.0, y = 3.0, z = 2.9 },
    markerColor = { r = 0, g = 255, b = 180, a = 190 },
    minDrawDist = 1.5,
}

local cleanDir = {
    active = false,
    points = {},
    targetPos = nil,
    destinationMarkerPos = nil,
}

local function dirVecLength2(v)
    return (v.x * v.x) + (v.y * v.y) + (v.z * v.z)
end

local function dirVecNormalize2D(v)
    local mag = math.sqrt((v.x * v.x) + (v.y * v.y))
    if mag < 0.0001 then
        return vector3(0.0, 0.0, 0.0)
    end
    return vector3(v.x / mag, v.y / mag, 0.0)
end

local function dirRebuild()
    cleanDir.points = {}
    cleanDir.destinationMarkerPos = nil

    if not cleanDir.active or not cleanDir.targetPos then
        return
    end

    local playerPos = GetEntityCoords(PlayerPedId())
    local targetPos = cleanDir.targetPos
    local diff = targetPos - playerPos
    local dist2D = math.sqrt(diff.x * diff.x + diff.y * diff.y)

    if dist2D < cleanDirCfg.minDrawDist then
        return
    end

    local step = cleanDirCfg.sampleStep
    local count = math.max(2, math.ceil(dist2D / step))
    local points = {}

    for i = 0, count do
        local t = i / count
        points[#points + 1] = {
            pos = vector3(
                playerPos.x + diff.x * t,
                playerPos.y + diff.y * t,
                playerPos.z + diff.z * t + cleanDirCfg.routeHeight
            ),
        }
    end

    cleanDir.points = points
    cleanDir.destinationMarkerPos = vector3(
        targetPos.x,
        targetPos.y,
        targetPos.z + cleanDirCfg.markerLift
    )
end

local function dirDrawArrow(prevPos, pos, nextPos)
    local forward = dirVecNormalize2D(nextPos - prevPos)
    if dirVecLength2(forward) < 0.0001 then
        return
    end
    local side = vector3(-forward.y, forward.x, 0.0)
    local tip = pos + (forward * cleanDirCfg.arrowLength)
    local left = pos - (forward * (cleanDirCfg.arrowLength * 0.55)) + (side * cleanDirCfg.arrowWidth)
    local right = pos - (forward * (cleanDirCfg.arrowLength * 0.55)) - (side * cleanDirCfg.arrowWidth)
    local ac = cleanDirCfg.arrowColor
    DrawLine(left.x, left.y, left.z, tip.x, tip.y, tip.z, ac.r, ac.g, ac.b, ac.a)
    DrawLine(right.x, right.y, right.z, tip.x, tip.y, tip.z, ac.r, ac.g, ac.b, ac.a)
end

local function dirDrawRoute()
    local points = cleanDir.points
    if #points < 2 then
        return
    end
    local rc = cleanDirCfg.routeColor
    for i = 1, #points - 1 do
        local aPos = points[i].pos
        local bPos = points[i + 1].pos
        DrawLine(aPos.x, aPos.y, aPos.z, bPos.x, bPos.y, bPos.z, rc.r, rc.g, rc.b, rc.a)
    end
    local spacingCount = math.max(1, math.floor(cleanDirCfg.arrowSpacing / cleanDirCfg.sampleStep))
    for i = 2, #points - 1, spacingCount do
        dirDrawArrow(points[i - 1].pos, points[i].pos, points[i + 1].pos)
    end
end

local function dirDrawMarker()
    if not cleanDirCfg.markerEnabled or not cleanDir.destinationMarkerPos then
        return
    end
    local pos = cleanDir.destinationMarkerPos
    local s = cleanDirCfg.markerScale
    local c = cleanDirCfg.markerColor
    DrawMarker(
        cleanDirCfg.markerType,
        pos.x, pos.y, pos.z,
        0.0, 0.0, 0.0,
        180.0, 0.0, 0.0,
        s.x, s.y, s.z,
        c.r, c.g, c.b, c.a,
        false, false, 2, false, nil, nil, false
    )
end

local function dirSpawnThreads()
    CreateThread(function()
        while cleanDir.active do
            if #cleanDir.points >= 2 then
                dirDrawRoute()
                dirDrawMarker()
            end
            Wait(0)
        end
    end)

    CreateThread(function()
        while cleanDir.active do
            dirRebuild()
            Wait(cleanDirCfg.updateInterval)
        end
    end)
end

local function dirStart(pos)
    cleanDir.targetPos = vector3(pos.x, pos.y, pos.z)
    cleanDir.active = true
    cleanDir.points = {}
    cleanDir.destinationMarkerPos = nil
    dirSpawnThreads()
end

local function dirStop()
    cleanDir.active = false
    cleanDir.points = {}
    cleanDir.targetPos = nil
    cleanDir.destinationMarkerPos = nil
end

local function canUseBocahPass()
    local pData = QBPlayerData
    if not pData or not pData.job then return false end
    return pData.job.name == sharedConfig.job
end

local function cleanupActivity()
    if ci.actBlip then pcall(function() ci.actBlip:remove() end) ci.actBlip = nil end
    if ci.actInteract then
        pcall(function() exports.rhd_interact:removeCoords(ci.actInteract) end)
        ci.actInteract = nil
    end
end

local function cleanupCleaningTargets()
    if ci.cleanInteracts then
        for _, id in ipairs(ci.cleanInteracts) do
            pcall(function() exports.rhd_interact:removeCoords(id) end)
        end
        ci.cleanInteracts = nil
    end
    if ci.cleanBlips then
        for _, b in ipairs(ci.cleanBlips) do pcall(function() b:remove() end) end
        ci.cleanBlips = nil
    end
end

local function cleanup()
    cleanupActivity()
    cleanupCleaningTargets()
    dirStop()
    for _, instance in pairs(ci) do
        if instance and type(instance) == 'table' and instance.remove then
            pcall(function() instance:remove() end)
        end
    end
    ci = {}
    activeMission = nil
    fotoCount = 0
    if fotoTargetName then
        pcall(function() ox_target:removeGlobalPlayer(fotoTargetName) end)
        fotoTargetName = nil
    end
end

local function closeUI()
    interface.focus(false, false)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SetTimeout(50, function()
        interface.hide()
    end)
end

local function forceCloseUI()
    pcall(function() interface.send({ action = 'bocahpass:forceClose' }) end)
    pcall(function() closeUI() end)
end

RegisterNetEvent('bocahpass:resetActiveMission', function()
    cleanup()
    forceCloseUI()
    lib.notify({ description = 'Misi Bocah Pass telah diacak ulang!', type = 'inform', duration = 5000 })
end)

local function openBocahPassUI()
    local data = lib.callback.await('bocahpass:getData', false)
    if not data then return end
    interface.show() -- mount the frame and wait for it to be ready
    interface.focus(true, true)
    interface.send({
        action = 'bocahpass:open',
        data = {
            level = data.level,
            exp = data.exp,
            missions = data.missions,
            progress = data.progress,
            levels = sharedConfig.levels,
            claimed = data.claimed,
            dailyActivities = data.dailyActivities,
        },
    })
end

local function pickRandomCoord(coords)
    if not coords or #coords == 0 then return nil end
    return coords[math.random(#coords)]
end

local function attachProp(ped, prop, bone, placement)
    if not prop then return nil end
    lib.requestModel(prop)
    local obj = CreateObject(joaat(prop), 0.0, 0.0, 0.0, true, true, false)
    if not DoesEntityExist(obj) then return nil end
    SetEntityCollision(obj, false, false)
    AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, bone),
        placement[1], placement[2], placement[3],
        placement[4], placement[5], placement[6],
        true, true, false, true, 0, true)
    return obj
end

local function startFotoMission(missionKey)
    local cfg = sharedConfig.missions[missionKey]
    activeMission = missionKey
    fotoCount = 0
    local targetName = 'bocahpass_' .. missionKey
    fotoTargetName = targetName
    lib.notify({ description = ('Cari %d %s dan ajak foto bersama!'):format(cfg.requiredCount, cfg.requiredJobLabel), type = 'inform', duration = 8000 })
    ox_target:addGlobalPlayer({
        {
            name     = targetName,
            label    = 'Ajak Foto Bersama',
            icon     = 'fas fa-camera',
            distance = 2.0,
            canInteract = function(entity)
                if not activeMission or activeMission ~= missionKey then return false end
                local serverId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
                if serverId <= 0 then return false end
                local targetJob = lib.callback.await('bocahpass:getPlayerJob', false, serverId)
                return targetJob == cfg.requiredJob
            end,
            onSelect = function(data)
                local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
                if targetServerId <= 0 then return end
                lib.notify({ description = 'Mengirim permintaan foto...', type = 'inform' })
                local accepted = lib.callback.await('bocahpass:requestFoto', false, targetServerId, missionKey)
                if not accepted then
                    lib.notify({ description = 'Permintaan foto ditolak!', type = 'error' })
                    return
                end
                lib.notify({ description = 'Permintaan diterima! Mulai foto...', type = 'success' })
                local anim = cfg.selfieAnim
                lib.requestAnimDict(anim.dict)
                local ped = cache.ped
                local propObj = attachProp(ped, anim.prop, anim.propBone, anim.propPlacement)
                local success = lib.progressBar({
                    duration = cfg.progressDuration,
                    label = 'Foto bersama...',
                    useWhileDead = false,
                    canCancel = true,
                    disable = { move = true, car = true, combat = true },
                    anim = { dict = anim.dict, clip = anim.clip, flag = anim.flag or 51 },
                })
                if propObj and DoesEntityExist(propObj) then DeleteEntity(propObj) end
                if not success then return end
                fotoCount = fotoCount + 1
                lib.notify({ description = ('Foto %d/%d selesai!'):format(fotoCount, cfg.requiredCount), type = 'success' })
                if fotoCount >= cfg.requiredCount then
                    ox_target:removeGlobalPlayer(targetName)
                    fotoTargetName = nil
                    TriggerTokenEvent('bocahpass:addRound', missionKey)
                    activeMission = nil
                    fotoCount = 0
                end
            end,
        },
    })
end

RegisterNetEvent('bocahpass:fotoRequest', function(requesterId, requesterName, missionKey)
    local cfg = sharedConfig.missions[missionKey]
    if not cfg then return end
    local alert = lib.alertDialog({
        header = 'Permintaan Foto Bersama',
        content = ('**%s** ingin mengajakmu foto bersama untuk misi **%s**!\n\nApakah kamu mau foto bareng?'):format(requesterName, cfg.label),
        centered = true,
        cancel = true,
        labels = { confirm = 'Mau!', cancel = 'Tidak' },
    })
    TriggerTokenEvent('bocahpass:fotoResponse', requesterId, alert == 'confirm')
end)

local setupActivityPoint

local function buildActivityData(cfg)
    if cfg.activityAction == 'bocahpass:startMath' or cfg.activityAction == 'bocahpass:startColor' or cfg.activityAction == 'bocahpass:startShape' then
        return { questionCount = cfg.questionCount, timePerQuestion = cfg.timePerQuestion }
    elseif cfg.activityAction == 'bocahpass:startWriting' then
        return { wordCount = cfg.wordCount, timePerWord = cfg.timePerWord }
    end
    return nil
end

local function createActivityInteract(coord, cfg, actionData)
    local icon = cfg.icon or 'fas fa-play'
    icon = string.gsub(icon, 'fas ', '')
    return exports.rhd_interact:addCoords({
        coords = coord,
        options = {
            {
                label = cfg.label,
                icon = icon,
                distance = 3.0,
                onSelect = function()
                    interface.show() -- mount the frame and wait for it to be ready
                    interface.focus(true, true)
                    local msg = { action = cfg.activityAction }
                    if actionData then msg.data = actionData end
                    interface.send(msg)
                end,
                canInteract = function()
                    return activeMission ~= nil
                end,
            },
        },
    })
end

local function startActivityMission(missionKey)
    activeMission = missionKey
    ci.activityContext = missionKey
    local cfg = sharedConfig.missions[missionKey]
    local coord = pickRandomCoord(cfg.activityCoords)
    if not coord then return end
    local remaining = lib.callback.await('bocahpass:getRemainingRounds', false, missionKey)
    local rounds = cfg.requiredRounds or 1
    local actionData = buildActivityData(cfg)
    lib.notify({ description = ('Mari mengerjakan %s! (Sisa %d/%d pengerjaan)'):format(cfg.label, remaining or rounds, rounds), type = 'inform' })
    ci.actBlip = blipModule:new({ coords = coord, label = 'Lokasi ' .. cfg.label, sprite = 1, color = 5, short = false })
    ci.actInteract = createActivityInteract(coord, cfg, actionData)
end

setupActivityPoint = function(missionKey)
    if activeMission ~= missionKey then return end
    cleanupActivity()
    ci.activityContext = missionKey
    local cfg = sharedConfig.missions[missionKey]
    local coord = pickRandomCoord(cfg.activityCoords)
    if not coord then return end
    local remaining = lib.callback.await('bocahpass:getRemainingRounds', false, missionKey)
    if activeMission ~= missionKey then return end
    local rounds = cfg.requiredRounds or 1
    local actionData = buildActivityData(cfg)
    lib.notify({ description = ('Bagus! Lanjut pengerjaan berikutnya. (Sisa %d/%d)'):format(remaining or rounds, rounds), type = 'inform', duration = 5000 })
    ci.actBlip = blipModule:new({ coords = coord, label = 'Lokasi ' .. cfg.label, sprite = 1, color = 5, short = false })
    ci.actInteract = createActivityInteract(coord, cfg, actionData)
end

local startCleaningMission

local function setupCleaningTask(missionKey, taskIndex)
    cleanupCleaningTargets()
    local cfg = sharedConfig.missions[missionKey]
    local task = cfg.cleaningTasks[taskIndex]
    if not task then return end

    local coord = task.coords[math.random(#task.coords)]

    ci.cleanBlips = {}
    ci.cleanInteracts = {}
    ci.cleanBlips[1] = blipModule:new({
        coords = vec3(coord.x, coord.y, coord.z),
        label = task.label,
        sprite = 1,
        color = 2,
        short = false,
    })

    dirStart(vec3(coord.x, coord.y, coord.z))

    local icon = task.icon or 'fas fa-broom'
    icon = string.gsub(icon, 'fas ', '')

    ci.cleanInteracts[1] = exports.rhd_interact:addCoords({
        coords = coord,
        options = {
            {
                label = task.label,
                icon = icon,
                distance = 2.5,
                onSelect = function()
                    if ci.cleaningBusy then return end
                    ci.cleaningBusy = true
                    lib.requestAnimDict(task.dict)
                    local ped = cache.ped
                    if coord.w then SetEntityHeading(ped, coord.w) end
                    local propObj = attachProp(ped, task.prop, task.propBone, task.propPlacement)
                    local success = lib.progressBar({
                        duration = task.duration,
                        label = task.label .. '...',
                        useWhileDead = false,
                        canCancel = true,
                        disable = { move = true, car = true, combat = true },
                        anim = { dict = task.dict, clip = task.clip, flag = task.flag or 51 },
                    })
                    if propObj and DoesEntityExist(propObj) then DeleteEntity(propObj) end
                    ci.cleaningBusy = false
                    if not success then return end

                    lib.notify({ description = task.label .. ' selesai!', type = 'success' })

                    local nextIndex = taskIndex + 1
                    if nextIndex <= #cfg.cleaningTasks then
                        lib.notify({
                            description = ('Selanjutnya: %s (%d/%d)'):format(
                                cfg.cleaningTasks[nextIndex].label, nextIndex, #cfg.cleaningTasks
                            ),
                            type = 'inform',
                            duration = 4000,
                        })
                        setupCleaningTask(missionKey, nextIndex)
                    else
                        dirStop()
                        cleanupCleaningTargets()
                        activeMission = nil
                        TriggerTokenEvent('bocahpass:addRound', missionKey)
                        Wait(500)
                        local rem = lib.callback.await('bocahpass:getRemainingRounds', false, missionKey)
                        if rem and rem > 0 then
                            startCleaningMission(missionKey)
                        end
                    end
                end,
                canInteract = function()
                    return activeMission == missionKey and not ci.cleaningBusy
                end,
            },
        },
    })
end

startCleaningMission = function(missionKey)
    activeMission = missionKey
    local cfg = sharedConfig.missions[missionKey]
    local remaining = lib.callback.await('bocahpass:getRemainingRounds', false, missionKey)
    local rounds = cfg.requiredRounds or 1
    ci.cleaningBusy = false

    lib.notify({
        description = ('Bantu bersihkan kelas! (Sisa %d/%d)'):format(remaining or rounds, rounds),
        type = 'inform',
        duration = 6000,
    })

    setupCleaningTask(missionKey, 1)
end

local function startMission(missionKey)
    if activeMission then
        lib.notify({ description = 'Kamu masih punya misi aktif!', type = 'error' })
        return
    end
    local canStart = lib.callback.await('bocahpass:canStartMission', false, missionKey)
    if not canStart then
        lib.notify({ description = 'Misi ini sudah selesai atau tidak tersedia hari ini!', type = 'error' })
        return
    end
    local cfg = sharedConfig.missions[missionKey]
    if cfg.missionType == 'foto' then
        startFotoMission(missionKey)
    elseif cfg.missionType == 'activity' then
        startActivityMission(missionKey)
    elseif cfg.missionType == 'cleaning' then
        startCleaningMission(missionKey)
    end
end

local function handleActivityComplete(missionKey)
    if activeMission ~= missionKey then return end
    TriggerTokenEvent('bocahpass:addRound', missionKey)
    Wait(700)
    if activeMission ~= missionKey then return end
    local remaining = lib.callback.await('bocahpass:getRemainingRounds', false, missionKey)
    if activeMission ~= missionKey then return end
    if remaining and remaining > 0 then
        setupActivityPoint(missionKey)
    else
        cleanupActivity()
        ci.activityContext = nil
        activeMission = nil
    end
end

interface.callback('close', function(_, cb)
    cb('ok')
    closeUI()
end)

interface.callback('selectMission', function(data, cb)
    cb('ok')
    closeUI()
    Wait(200)
    startMission(data.mission)
end)

interface.callback('drawingCancel', function(_, cb) cb('ok') closeUI() end)
interface.callback('drawingComplete', function(_, cb)
    cb('ok') closeUI()
    if activeMission == 'menggambar' then handleActivityComplete(activeMission) end
end)

interface.callback('mathCancel', function(_, cb) cb('ok') closeUI() end)
interface.callback('mathComplete', function(data, cb)
    cb('ok')
    closeUI()
    if activeMission == 'belajar_hitung' and data.passed then
        handleActivityComplete(activeMission)
    elseif activeMission == 'belajar_hitung' then
        lib.notify({ description = 'Jawaban kurang tepat, coba lagi ya!', type = 'error' })
    end
end)

interface.callback('colorCancel', function(_, cb) cb('ok') closeUI() end)
interface.callback('colorComplete', function(data, cb)
    cb('ok') closeUI()
    if activeMission == 'pilih_warna' and data.passed then handleActivityComplete(activeMission)
    elseif activeMission == 'pilih_warna' then lib.notify({ description = 'Jawaban kurang tepat, coba lagi ya!', type = 'error' }) end
end)

interface.callback('shapeCancel', function(_, cb) cb('ok') closeUI() end)
interface.callback('shapeComplete', function(data, cb)
    cb('ok') closeUI()
    if activeMission == 'pilih_bentuk' and data.passed then handleActivityComplete(activeMission)
    elseif activeMission == 'pilih_bentuk' then lib.notify({ description = 'Jawaban kurang tepat, coba lagi ya!', type = 'error' }) end
end)

interface.callback('puzzleCancel', function(_, cb) cb('ok') closeUI() end)
interface.callback('puzzleComplete', function(data, cb)
    cb('ok') closeUI()
    if activeMission == 'puzzle' and data.passed then handleActivityComplete(activeMission) end
end)

interface.callback('writingCancel', function(_, cb) cb('ok') closeUI() end)
interface.callback('writingComplete', function(data, cb)
    cb('ok') closeUI()
    if activeMission == 'menulis' and data.passed then handleActivityComplete(activeMission)
    elseif activeMission == 'menulis' then lib.notify({ description = 'Tulisan kurang tepat, coba lagi ya!', type = 'error' }) end
end)

interface.callback('claimReward', function(data, cb)
    local success = lib.callback.await('bocahpass:claimReward', false, data.level)
    cb(success and 'ok' or 'fail')
end)

CreateThread(function()
    local deadline = GetGameTimer() + 60000
    while GetResourceState('sm_resource_2') ~= 'started' do
        if GetGameTimer() > deadline then
            return lib.print.error('bocahpass: sm_resource_2 tidak jalan, NPC misi tidak dibuat')
        end
        Wait(500)
    end

    for k, v in pairs(sharedConfig.missions) do
        if v.npc then
            exports.sm_resource_2:addPed({
                model = v.npc.model,
                coords = v.npc.coords,
                scenario = v.npc.scenario,
                renderDistance = v.npc.renderDistance,
                interactOptions = {
                    {
                        icon = v.icon,
                        label = v.label,
                        onSelect = function()
                            if not canUseBocahPass() then
                                lib.notify({ description = 'Kamu bukan bocah!', type = 'error' })
                                return
                            end
                            startMission(k)
                        end,
                    },
                },
            })
        end
    end
end)

exports('openBocahPass', function()
    if not canUseBocahPass() then
        lib.notify({ description = 'Kamu bukan bocah!', type = 'error' })
        return
    end
    openBocahPassUI()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    cleanup()
    forceCloseUI()
end)