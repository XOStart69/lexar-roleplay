local config = localmodule 'config'
local exportWrapper = require 'export_wrapper'
local infoui = exports.rhd_infoui

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetPlayerPed = GetPlayerPed
local GetPlayerServerId = GetPlayerServerId
local GetPlayerFromServerId = GetPlayerFromServerId
local GetEntityAttachedTo = GetEntityAttachedTo
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local IsEntityPlayingAnim = IsEntityPlayingAnim
local IsPedInAnyVehicle = IsPedInAnyVehicle
local TaskPlayAnim = TaskPlayAnim
local DisableControlAction = DisableControlAction
local EnableControlAction = EnableControlAction
local DisableAllControlActions = DisableAllControlActions

local CUFF_ITEMS = config.cuffItems
local KEY_ITEMS = config.keyItems
local CUFF_JOBS = config.cuffJobs
local HANDCUFF = config.handcuffItem
local CUFF_KEY = config.cuffKeyItem
local INTERACT_DISTANCE = config.interactDistance
local BREAKOUT = config.breakout
local BOLT = config.boltCutter
local LOCKPICK = config.lockpick
local FORCE_SEARCH_JOBS = config.search.forceJobs
local SEARCH_GRADES = config.search.jobGrades
local SEARCH_VIEW_JOBS = config.search.viewOnlyJobs
local DISABLE_SPRINT = config.disableSprintWhileEscorting

local ESCORT_INFO_ID = 'police_escort_release'
local SEARCH_DICT, SEARCH_CLIP = 'pazeee@sixzzq@animations', 'pazeee@sixzzq@clip'
local CUFF_BONE = 60309
local CUFF_OFFSETS = {
    front = { -0.058, 0.005, 0.090, 290.0, 95.0, 120.0 },
    back = { -0.055, 0.06, 0.04, 265.0, 155.0, 80.0 },
}
local CUFF_DICTS = { front = 'anim@move_m@prisoner_cuffed', back = 'mp_arresting' }
local CUFF_GROUPS = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 27, 2, 0 }
local CUFF_CONTROLS = { 24, 257, 25, 263, 45, 22, 44, 37, 23, 288, 289, 170, 167, 26, 73, 199, 59, 71, 72, 36, 264, 140, 141, 142, 143, 75, 75, 23, 47 }
local CUFF_CONTROL_COUNT = #CUFF_CONTROLS
local ESCORTED_ALLOWED = { 1, 2, 245, 38, 322, 249, 46 }
local ESCORTED_ALLOWED_COUNT = #ESCORTED_ALLOWED

---@type string?
local cuffItem
local cuffDict, cuffFlag
local cuffProp
---@type number?
local escortedBy
---@type number?
local escortTarget
local busy = false
local loopRunning = false
local nextReleaseAt = 0

exportWrapper('sm_policejob', 'IsHandcuffed', function() return cuffItem ~= nil end)
exportWrapper('sm_policejob', 'IsEscorted', function() return escortedBy ~= nil end)
exportWrapper('sm_policejob', 'IsEscortingPlayer', function() return escortTarget ~= nil end)
exportWrapper('sm_policejob', 'IsInEscort', function() return escortedBy ~= nil or escortTarget ~= nil end)

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ description = description, type = kind or 'error' })
end

---@return boolean
local function isDown()
    local meta = QBPlayerData.metadata
    return meta ~= nil and (meta.isdead or meta.inlaststand) or false
end

---@return boolean
local function canCuffJob()
    local job = QBPlayerData.job
    return job ~= nil and CUFF_JOBS[job.name] == true
end

---@param entity number
---@return number?
local function serverIdOf(entity)
    local index = NetworkGetPlayerIndexFromPed(entity)
    if index == -1 then return end
    return GetPlayerServerId(index)
end

---@param maxDistance number
---@return number? serverId
---@return number? ped
local function closestPlayer(maxDistance)
    local player, ped = lib.getClosestPlayer(GetEntityCoords(cache.ped), maxDistance, false)
    if not player then return end
    return GetPlayerServerId(player), ped
end

---@param serverId number
---@return string?
local function cuffOf(serverId)
    return Player(serverId).state.cuffed
end

local function clearCuffProp()
    if cuffProp then
        DeleteEntity(cuffProp)
        cuffProp = nil
    end
end

local function controlLoop()
    if loopRunning then return end
    loopRunning = true

    CreateThread(function()
        local nextAnimCheck = 0

        while cuffItem or escortedBy or (escortTarget and DISABLE_SPRINT) do
            if escortedBy then
                DisableAllControlActions(0)
                for i = 1, ESCORTED_ALLOWED_COUNT do
                    EnableControlAction(0, ESCORTED_ALLOWED[i], true)
                end
            end

            if escortTarget and DISABLE_SPRINT then
                DisableControlAction(0, 21, true)
                DisableControlAction(0, 22, true)
            end

            if cuffItem then
                for i = 1, CUFF_CONTROL_COUNT do
                    DisableControlAction(CUFF_GROUPS[i], CUFF_CONTROLS[i], true)
                end
                EnableControlAction(0, 249, true)
                EnableControlAction(0, 46, true)

                local now = GetGameTimer()
                if now >= nextAnimCheck then
                    nextAnimCheck = now + 500
                    local ped = cache.ped
                    if not isDown() and not IsEntityPlayingAnim(ped, cuffDict, 'idle', 3) then
                        TaskPlayAnim(ped, cuffDict, 'idle', 8.0, -8.0, -1, escortedBy and 49 or cuffFlag, 0, false, false, false)
                    end
                end
            end

            Wait(0)
        end

        loopRunning = false
    end)
end

local releaseKeybind = lib.addKeybind({
    name = 'police_escort_release',
    description = 'Lepas escort',
    defaultKey = 'E',
    disabled = true,
    onPressed = function()
        if not escortTarget then return end
        local now = GetGameTimer()
        if now < nextReleaseAt then return end
        nextReleaseAt = now + 1000
        TriggerTokenEvent('police:server:EscortPlayer')
    end,
})

local function stopEscortRelease()
    escortTarget = nil
    releaseKeybind:disable(true)
    infoui:remove(ESCORT_INFO_ID)
end

---@param targetId number
local function startEscortRelease(targetId)
    escortTarget = targetId
    releaseKeybind:disable(false)

    local key = releaseKeybind:getCurrentKey()
    if key == '' then key = 'E' end

    infoui:show({
        id = ESCORT_INFO_ID,
        title = 'Escort',
        icon = 'fas fa-user-group',
        description = ('[kbd]%s[/kbd] - Lepas escort'):format(key),
    })

    controlLoop()

    CreateThread(function()
        Wait(1500)
        local misses = 0
        while escortTarget == targetId do
            local player = GetPlayerFromServerId(targetId)
            local attached = player ~= -1 and GetEntityAttachedTo(GetPlayerPed(player)) == cache.ped
            misses = attached and 0 or misses + 1

            if isDown() or misses >= 3 then
                TriggerTokenEvent('police:server:EscortPlayer')
                break
            end

            Wait(500)
        end
    end)
end

---@param item string
---@param targetId? number
---@param targetPed? number
local function useCuffItem(item, targetId, targetPed)
    if busy or cuffItem or escortedBy or isDown() or IsPedRagdoll(cache.ped) then return end
    if not CUFF_ITEMS[item] and not KEY_ITEMS[item] then return end

    if not targetId then
        targetId, targetPed = closestPlayer(INTERACT_DISTANCE)
    end
    if not targetId then return notify('Tidak ada orang di sekitar!') end

    local state = cuffOf(targetId)
    if CUFF_ITEMS[item] then
        if state then return notify('Player sudah diborgol!') end
    elseif not state then
        return notify('Player tidak diborgol')
    end

    busy = true
    local ped = cache.ped
    TaskTurnPedToFaceEntity(ped, targetPed, 1000)
    local side = IsPedFacingPed(targetPed, ped, 60.0) and 'front' or 'back'
    TriggerTokenEvent('police:server:CuffPlayer', targetId, item, side)

    if lib.requestAnimDict('mp_arresting', 2000) then
        TaskPlayAnim(ped, 'mp_arresting', 'a_uncuff', 8.0, -8.0, -1, 49, 0, false, false, false)
        Wait(2000)
        StopAnimTask(ped, 'mp_arresting', 'a_uncuff', 1.0)
        RemoveAnimDict('mp_arresting')
    end
    busy = false
end

---@param targetId? number
---@param targetPed? number
local function useBoltCutter(targetId, targetPed)
    if busy or cuffItem or escortedBy or isDown() then return end

    if not targetId then
        targetId, targetPed = closestPlayer(INTERACT_DISTANCE)
    end
    if not targetId then return notify('Tidak ada orang di sekitar!') end
    if not cuffOf(targetId) then return notify('Player tidak diborgol') end

    busy = true
    local ok, reason = lib.callback.await('police:server:cutStart', false, targetId)
    if not ok then
        busy = false
        if reason then notify(reason) end
        return
    end

    TaskTurnPedToFaceEntity(cache.ped, targetPed, 1000)
    local done = lib.progressBar({
        duration = BOLT.duration,
        label = 'Memotong borgol...',
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'anim@scripted@heist@ig4_bolt_cutters@male@', clip = 'action_male', flag = 16 },
        prop = { model = `h4_prop_h4_bolt_cutter_01a`, bone = 28422, pos = vec3(-0.03, 0.0, 0.0), rot = vec3(0.0, -90.0, 0.0) },
    })

    if done then
        TriggerTokenEvent('police:server:cutFinish')
    else
        notify('Dibatalkan..')
    end
    busy = false
end

---@param targetId number
---@param targetPed number
local function lockpickCuff(targetId, targetPed)
    if busy or cuffItem or escortedBy or isDown() or IsPedInAnyVehicle(cache.ped, true) then return end

    busy = true
    local ok, reason = lib.callback.await('police:server:lockpickCuffStart', false, targetId)
    if not ok then
        busy = false
        if reason then notify(reason) end
        return
    end

    local ped = cache.ped
    TaskTurnPedToFaceEntity(ped, targetPed, 1000)
    Wait(1000)

    local hasDict = lib.requestAnimDict('mp_arresting', 2000)
    if hasDict then
        TaskPlayAnim(ped, 'mp_arresting', 'a_uncuff', 8.0, -8.0, -1, 49, 0, false, false, false)
    end

    local called, result = pcall(exports.sm_sidejob.startLockpick, exports.sm_sidejob, LOCKPICK.item, LOCKPICK.difficulty, LOCKPICK.pins)

    if hasDict then
        StopAnimTask(ped, 'mp_arresting', 'a_uncuff', 1.0)
        RemoveAnimDict('mp_arresting')
    end

    local released = lib.callback.await('police:server:lockpickCuffFinish', false, called and result == true)
    if released then
        notify('Borgol berhasil dibuka', 'success')
    else
        notify('Gagal membuka borgol')
    end
    busy = false
end

---@param rob boolean
---@param targetId? number
local function requestSearch(rob, targetId)
    if busy or cuffItem or escortedBy then return end
    local job = QBPlayerData.job
    local forced = job and FORCE_SEARCH_JOBS[job.name]
    if not forced and IsPedInAnyVehicle(cache.ped, true) then
        return notify('Tidak bisa menggeledah dari dalam kendaraan')
    end

    targetId = targetId or closestPlayer(INTERACT_DISTANCE)
    if not targetId then return notify('Tidak ada orang di sekitar!') end

    TriggerTokenEvent(rob and 'police:server:RobPlayer' or 'police:server:SearchPlayer', targetId)
end

---@param targetId? number
local function requestEscort(targetId)
    if escortTarget then
        return TriggerTokenEvent('police:server:EscortPlayer')
    end
    if cuffItem or escortedBy or isDown() then
        return notify('Kamu tidak bisa escort sekarang')
    end
    if IsPedInAnyVehicle(cache.ped, true) then
        return notify('Tidak bisa escort dari dalam kendaraan')
    end

    targetId = targetId or closestPlayer(INTERACT_DISTANCE)
    if not targetId then return notify('Tidak ada orang di sekitar!') end

    TriggerTokenEvent('police:server:EscortPlayer', targetId)
end

RegisterNetEvent('police:client:CuffPlayer', function(item)
    useCuffItem(item)
end)

RegisterNetEvent('police:client:useCuffCutter', function()
    useBoltCutter()
end)

RegisterNetEvent('police:client:EscortPlayer', function()
    requestEscort()
end)

RegisterNetEvent('police:client:SearchPlayer', function()
    requestSearch(false)
end)

RegisterNetEvent('police:client:RobPlayer', function()
    requestSearch(true)
end)

RegisterNetEvent('police:client:PutPlayerInVehicle', function()
    if cuffItem or escortedBy then return end

    local targetId = escortTarget or closestPlayer(INTERACT_DISTANCE)
    if not targetId then return notify('Tidak ada orang di sekitar!') end

    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, false)
    if not vehicle then return notify('Tidak ada kendaraan terdekat (terlalu jauh)') end

    TriggerTokenEvent('police:server:PutPlayerInVehicle', targetId, VehToNet(vehicle))
end)

RegisterNetEvent('police:client:SetPlayerOutVehicle', function()
    if cuffItem or escortedBy then return end

    local targetId, targetPed = closestPlayer(4.0)
    if not targetId then return notify('Tidak ada orang di sekitar!') end
    if not IsPedInAnyVehicle(targetPed, false) then
        return notify('Pemain tidak berada di dalam kendaraan')
    end

    TriggerTokenEvent('police:server:SetPlayerOutVehicle', targetId)
end)

RegisterNetEvent('police:client:Breakout', function()
    if source ~= 65535 then return end
    local ok = lib.skillCheck(BREAKOUT.difficulty, BREAKOUT.inputs)
    TriggerTokenEvent('police:server:BreakoutResult', ok == true)
end)

RegisterNetEvent('police:client:SetCuffed', function(item, side)
    if source ~= 65535 then return end
    local ped = cache.ped

    if not item then
        cuffItem, cuffDict, cuffFlag = nil, nil, nil
        clearCuffProp()
        TriggerEvent('police:client:SetCuffState', false)
        if not isDown() then ClearPedTasks(ped) end
        notify('Borgol kamu telah dilepas', 'success')
        return
    end

    local cuff = CUFF_ITEMS[item]
    if not cuff then return end

    side = CUFF_DICTS[side] and side or 'back'
    cuffItem, cuffDict, cuffFlag = item, CUFF_DICTS[side], cuff.flag
    TriggerEvent('police:client:SetCuffState', true)

    if GetSelectedPedWeapon(ped) ~= `WEAPON_UNARMED` then
        SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
    end

    lib.requestAnimDict(cuffDict, 2000)
    controlLoop()

    clearCuffProp()
    local model = lib.requestModel(cuff.prop, 5000)
    if not model or cuffItem ~= item then return end

    local coords = GetEntityCoords(ped)
    cuffProp = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
    SetModelAsNoLongerNeeded(model)

    local netId = ObjToNet(cuffProp)
    SetNetworkIdCanMigrate(netId, false)

    local o = CUFF_OFFSETS[side]
    AttachEntityToEntity(cuffProp, ped, GetPedBoneIndex(ped, CUFF_BONE), o[1], o[2], o[3], o[4], o[5], o[6], true, false, false, false, 0, true)
end)

RegisterNetEvent('police:client:SetEscorted', function(dragger)
    if source ~= 65535 then return end
    local ped = cache.ped

    if dragger then
        local player = GetPlayerFromServerId(dragger)
        if player == -1 then return end

        local draggerPed = GetPlayerPed(player)
        escortedBy = dragger
        SetEntityCoords(ped, GetOffsetFromEntityInWorldCoords(draggerPed, 0.0, 0.45, 0.0))
        AttachEntityToEntity(ped, draggerPed, 11816, 0.30, 0.40, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        controlLoop()
    else
        escortedBy = nil
        DetachEntity(ped, true, false)
        if cuffItem then
            TaskPlayAnim(ped, cuffDict, 'idle', 8.0, -8.0, -1, cuffFlag, 0, false, false, false)
        elseif not isDown() then
            ClearPedTasks(ped)
        end
    end

    TriggerEvent('hospital:client:isEscorted', escortedBy ~= nil)
end)

RegisterNetEvent('police:client:SetEscorting', function(target)
    if source ~= 65535 then return end
    if target then
        startEscortRelease(target)
    else
        stopEscortRelease()
    end
end)

RegisterNetEvent('police:client:PutInVehicle', function(netId)
    if source ~= 65535 then return end

    local vehicle = NetToVeh(netId)
    if vehicle == 0 then return end

    local ped = cache.ped
    for seat = GetVehicleMaxNumberOfPassengers(vehicle) - 1, 0, -1 do
        if IsVehicleSeatFree(vehicle, seat) then
            DetachEntity(ped, true, false)
            SetPedIntoVehicle(ped, vehicle, seat)
            return
        end
    end
end)

RegisterNetEvent('police:client:SetOutVehicle', function()
    if source ~= 65535 then return end
    local ped = cache.ped
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        TaskLeaveVehicle(ped, vehicle, 16)
    end
end)

RegisterNetEvent('police:client:BeingSearched', function()
    if source ~= 65535 then return end
    notify('Kamu sedang digeledah', 'inform')
end)

RegisterNetEvent('police:client:StartSearch', function(_, duration, label)
    if source ~= 65535 or busy then return end

    busy = true
    local done = lib.progressBar({
        duration = duration,
        label = label,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = SEARCH_DICT, clip = SEARCH_CLIP, flag = 16 },
    })
    busy = false

    if done then
        TriggerTokenEvent('police:server:OpenSearch')
    else
        notify('Dibatalkan..')
    end
end)

ox_target:addGlobalPlayer({
    {
        name = 'geledah_player',
        icon = 'fas fa-mask',
        label = 'Geledah',
        distance = 1.5,
        onSelect = function(data)
            local job = QBPlayerData.job
            local jobType = job and job.type
            local range = job and SEARCH_GRADES[job.name]
            local gradeAllowed = range and job.grade.level >= range[1] and job.grade.level <= range[2]
            local viewAllowed = job and SEARCH_VIEW_JOBS[job.name] and job.onduty
            local targetId = serverIdOf(data.entity)
            if jobType == 'leo' or gradeAllowed or viewAllowed or ox_inventory:GetItemCount('badgepaspampres') > 0 then
                requestSearch(false, targetId)
            elseif jobType == 'badside' then
                requestSearch(true, targetId)
            else
                notify('Tidak memiliki akses untuk menggeledah')
            end
        end,
    },
    {
        name = 'cuff_player',
        icon = 'fas fa-handcuffs',
        label = 'Cuff',
        distance = 1.5,
        canInteract = function(entity)
            if not canCuffJob() or ox_inventory:GetItemCount(HANDCUFF) <= 0 then return false end
            local targetId = serverIdOf(entity)
            return targetId ~= nil and not cuffOf(targetId)
        end,
        onSelect = function(data)
            useCuffItem(HANDCUFF, serverIdOf(data.entity), data.entity)
        end,
    },
    {
        name = 'uncuff_player',
        icon = 'fas fa-unlock',
        label = 'Uncuff',
        distance = 1.5,
        canInteract = function(entity)
            if not canCuffJob() or ox_inventory:GetItemCount(CUFF_KEY) <= 0 then return false end
            local targetId = serverIdOf(entity)
            return targetId ~= nil and cuffOf(targetId) == HANDCUFF
        end,
        onSelect = function(data)
            useCuffItem(CUFF_KEY, serverIdOf(data.entity), data.entity)
        end,
    },
    {
        name = 'lockpick_cuff',
        icon = 'fas fa-key',
        label = 'Lockpick Borgol',
        distance = 1.5,
        canInteract = function(entity)
            if busy or cuffItem or ox_inventory:GetItemCount(LOCKPICK.item) <= 0 then return false end
            local targetId = serverIdOf(entity)
            local state = targetId and cuffOf(targetId)
            return state ~= nil and LOCKPICK.cuffs[state] == true
        end,
        onSelect = function(data)
            local targetId = serverIdOf(data.entity)
            if targetId then lockpickCuff(targetId, data.entity) end
        end,
    },
    {
        name = 'escort_player',
        icon = 'fas fa-user-group',
        label = 'Escort',
        distance = 1.5,
        onSelect = function(data)
            requestEscort(serverIdOf(data.entity))
        end,
    },
})

local function resetLocal()
    local ped = cache.ped
    clearCuffProp()
    if cuffItem then
        TriggerEvent('police:client:SetCuffState', false)
    end
    if escortedBy then
        DetachEntity(ped, true, false)
        TriggerEvent('hospital:client:isEscorted', false)
    end
    cuffItem, cuffDict, cuffFlag, escortedBy = nil, nil, nil, nil
    if escortTarget then stopEscortRelease() end
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', resetLocal)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then resetLocal() end
end)
