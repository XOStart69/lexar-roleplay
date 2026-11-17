local Config = localmodule 'config'

local Studios = Config.Studios
local Labels = Config.Labels
local Notify = Config.Notify
local Debug = Config.Debug
local Animations = Config.Animations

local GetEntityCoords = GetEntityCoords
local FreezeEntityPosition = FreezeEntityPosition
local Wait = Wait
local mathExp = math.exp
local mathAbs = math.abs

local activeStudio = nil
local computerOpen = false
local jobBusy = false
local releasePending = false
local onMic = false
local recording = false
local uploading = false
local speakerActive = false
local micSettingsOpen = false
local volumeLoop = false

local mounted = false
local frameAlive = false
local frameReady = false
local pending = {}

local tvProps = {}

local TV_URL = ('https://cfx-nui-%s/interface/sm_studio/web/build/index.html?tv=1'):format(cache.resource)
local TV_TXD = 'sm_studio_tv'
local TV_WIDTH = 1280
local TV_HEIGHT = 720
local tvDui = nil
local tvTxd = nil
local tvTexture = nil
local tvSerial = 0
local tvToken = 0
local tvReady = false
local tvQueue = {}
local tvTarget = nil
local tvOwnsTarget = false

local activeAnim = nil
local pendingAnim = nil
local animProp = nil
local animToken = 0

interface.init(false)

---@param key string
local function notify(key)
    local entry = Notify[key]
    if not entry then return end

    lib.notify({
        title = 'Studio',
        description = entry[1],
        type = entry[2],
        duration = entry[3],
    })
end

---@param action string
---@param data any
local function sendUI(action, data)
    if not mounted then return end

    local msg = { action = action, data = data }

    if frameReady then
        interface.send(msg)
    else
        pending[#pending + 1] = msg
    end
end

local function mountFrame()
    if mounted then return end
    mounted = true

    if frameAlive then
        frameReady = true
    else
        frameReady = false
        interface.show()
    end
end

local function unmountFrame()
    if not mounted then return end
    mounted = false
    frameReady = false
    table.wipe(pending)

    SetTimeout(50, function()
        if mounted then return end
        frameAlive = false
        interface.hide()
    end)
end

---@return boolean
local function isDead()
    local metadata = QBPlayerData.metadata
    return metadata ~= nil and (metadata.isdead or metadata.inlaststand) == true
end

---@param key string
---@return boolean
local function canUseComputer(key)
    local studio = Studios[key]
    if studio.forall then return true end

    local job = QBPlayerData.job
    local minGrade = job and studio.jobs and studio.jobs[job.name]
    if not minGrade then return false end

    local grade = job.grade
    return (tonumber(type(grade) == 'table' and grade.level or grade) or 0) >= minGrade
end

local function startVolumeLoop()
    if volumeLoop then return end
    volumeLoop = true

    CreateThread(function()
        local last = -1

        while activeStudio and speakerActive do
            if frameReady then
                local computer = Studios[activeStudio].computer
                local maxDistance = computer.maxVolumeDistance
                local distance = #(GetEntityCoords(cache.ped) - computer.coords)
                local volume = distance >= maxDistance and 0.0 or mathExp(-distance / (maxDistance * 2.25))

                if mathAbs(volume - last) >= 0.01 then
                    last = volume
                    interface.send({ action = 'speakerVolume', data = volume })
                end
            else
                last = -1
            end

            Wait(150)
        end

        volumeLoop = false
    end)
end

---@param payload table?
local function setSpeaker(payload)
    speakerActive = payload ~= nil
    sendUI('speaker', payload or false)
    if speakerActive then startVolumeLoop() end
end

local function stopAnim()
    animToken = animToken + 1
    pendingAnim = nil

    if animProp then
        if DoesEntityExist(animProp) then DeleteEntity(animProp) end
        animProp = nil
    end

    if not activeAnim then return end
    StopAnimTask(cache.ped, activeAnim.dict, activeAnim.clip, 1.0)
    RemoveAnimDict(activeAnim.dict)
    activeAnim = nil
end

---@param anim table
local function playAnim(anim)
    stopAnim()
    local token = animToken
    pendingAnim = anim

    CreateThread(function()
        lib.requestAnimDict(anim.dict)
        if anim.prop then lib.requestModel(anim.prop) end
        if token ~= animToken then return end
        pendingAnim = nil

        local ped = cache.ped
        TaskPlayAnim(ped, anim.dict, anim.clip, 3.0, 3.0, -1, anim.flag, 0, false, false, false)
        activeAnim = anim

        if anim.prop then
            local coords = GetEntityCoords(ped)
            local p = anim.placement
            animProp = CreateObject(anim.prop, coords.x, coords.y, coords.z + 0.2, true, true, false)
            SetEntityCollision(animProp, false, false)
            AttachEntityToEntity(animProp, ped, GetPedBoneIndex(ped, anim.bone), p[1], p[2], p[3], p[4], p[5], p[6], true, true, false, true, 1, true)
            SetModelAsNoLongerNeeded(anim.prop)
        end
    end)
end

---@param anim table
local function stopAnimIf(anim)
    if activeAnim == anim or pendingAnim == anim then stopAnim() end
end

local function closeComputer()
    if not computerOpen then return end
    computerOpen = false
    stopAnimIf(Animations.computer)

    interface.focus(false, false)
    sendUI('close', true)

    if jobBusy then
        releasePending = true
        return
    end

    TriggerTokenEvent('sm_studio:computer:release')
end

local function closeMicSettings()
    if not micSettingsOpen then return end
    micSettingsOpen = false
    sendUI('micSettings', false)
    interface.focus(false, false)
end

local function openMicSettings()
    if micSettingsOpen or computerOpen then return end
    micSettingsOpen = true
    sendUI('micSettings', true)
    interface.focus(true, true)
end

local function playerOnMic()
    onMic = true
    FreezeEntityPosition(cache.ped, true)
    sendUI('micPanel', true)
    notify('on_mic')
    openMicSettings()
end

local function playerOutMic()
    onMic = false
    recording = false
    stopAnimIf(Animations.microphone)
    FreezeEntityPosition(cache.ped, false)
    sendUI('micPanel', false)
    closeMicSettings()
    notify('out_mic')
end

---@param key string
local function spawnTelevision(key)
    local tv = Studios[key].television
    if not tv or tvProps[key] then return end

    lib.requestModel(tv.model)

    local coords, rotation = tv.coords, tv.rotation
    local object = CreateObject(tv.model, coords.x, coords.y, coords.z, false, false, false)
    SetModelAsNoLongerNeeded(tv.model)
    FreezeEntityPosition(object, true)
    SetEntityInvincible(object, true)
    SetEntityRotation(object, rotation.x, rotation.y, rotation.z, 0, true)

    tvProps[key] = object
end

---@param key string
local function deleteTelevision(key)
    local object = tvProps[key]
    if not object then return end

    if DoesEntityExist(object) then DeleteEntity(object) end
    tvProps[key] = nil
end

---@param action string
---@param data any
local function tvSend(action, data)
    if not tvDui then return end
    local message = json.encode({ action = action, data = data })
    if tvReady then
        SendDuiMessage(tvDui, message)
    else
        tvQueue[#tvQueue + 1] = message
    end
end

local function destroyTv()
    tvToken = tvToken + 1
    tvReady = false
    table.wipe(tvQueue)

    if tvDui then
        DestroyDui(tvDui)
        tvDui = nil
    end

    if tvOwnsTarget and tvTarget and IsNamedRendertargetRegistered(tvTarget) then
        ReleaseNamedRendertarget(tvTarget)
    end
    tvOwnsTarget = false
    tvTarget = nil
end

---@param key string
local function createTv(key)
    local tv = Studios[key].television
    if not tv or tvDui then return end

    tvToken = tvToken + 1
    local token = tvToken
    tvTarget = tv.target or 'tvscreen'

    local handle = CreateDui(TV_URL, TV_WIDTH, TV_HEIGHT)
    tvDui = handle

    CreateThread(function()
        local deadline = GetGameTimer() + 10000
        while not IsDuiAvailable(handle) and GetGameTimer() < deadline do
            Wait(50)
        end
        if token ~= tvToken then return end
        if not IsDuiAvailable(handle) then
            destroyTv()
            return
        end

        if not tvTxd then tvTxd = CreateRuntimeTxd(TV_TXD) end
        tvSerial = tvSerial + 1
        tvTexture = 'screen' .. tvSerial
        CreateRuntimeTextureFromDuiHandle(tvTxd, tvTexture, GetDuiHandle(handle))

        local target = tvTarget
        local model = tv.model
        local defaultId = GetDefaultScriptRendertargetRenderId()

        while token == tvToken do
            if not IsNamedRendertargetRegistered(target) then
                RegisterNamedRendertarget(target, false)
                tvOwnsTarget = true
            end
            if not IsNamedRendertargetLinked(model) then
                LinkNamedRendertarget(model)
            end

            SetTextRenderId(GetNamedRendertargetRenderId(target))
            SetScriptGfxDrawOrder(4)
            SetScriptGfxDrawBehindPausemenu(true)
            DrawSprite(TV_TXD, tvTexture, 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
            SetTextRenderId(defaultId)
            SetScriptGfxDrawBehindPausemenu(false)
            Wait(0)
        end
    end)
end

---@param key string
local function enterStudio(key)
    if activeStudio == key then return end
    activeStudio = key

    mountFrame()
    spawnTelevision(key)
    createTv(key)

    lib.callback('sm_studio:room:enter', false, function(data)
        if activeStudio ~= key then return end

        if not data then
            if Debug then lib.print.warn(('[sm_studio] server menolak masuk studio %s'):format(key)) end
            return
        end

        if data.speaker then setSpeaker(data.speaker) end
        tvSend('studio', data.label)
        if data.mirror then tvSend('mirror', data.mirror) end
    end, key)
end

---@param key string
local function exitStudio(key)
    if activeStudio ~= key then return end

    closeComputer()

    if onMic then
        lib.callback('sm_studio:mic:leave', false, function() end)
        playerOutMic()
    end

    TriggerTokenEvent('sm_studio:room:leave')
    destroyTv()
    deleteTelevision(key)

    activeStudio = nil
    speakerActive = false
    uploading = false

    unmountFrame()
end

---@param key string
local function openComputer(key)
    lib.callback('sm_studio:computer:open', false, function(result)
        if not result.status then
            return notify(result.message)
        end

        if activeStudio ~= key or isDead() then
            TriggerTokenEvent('sm_studio:computer:release')
            return
        end

        computerOpen = true
        releasePending = false
        playAnim(Animations.computer)
        result.status = nil
        sendUI('open', result)
        interface.focus(true, true)
    end)
end

local function toggleMic()
    if onMic then
        if uploading then return notify('record_uploading_wait') end

        lib.callback('sm_studio:mic:leave', false, function(success)
            if success then
                playerOutMic()
            else
                notify('went_wrong')
            end
        end)
        return
    end

    lib.callback('sm_studio:mic:take', false, function(success)
        if success then
            playerOnMic()
        else
            notify('microphone_busy')
        end
    end)
end

for key, studio in pairs(Studios) do
    local blip = studio.blip

    if blip then
        local handle = AddBlipForCoord(blip.coords.x, blip.coords.y, blip.coords.z)
        SetBlipSprite(handle, blip.sprite)
        SetBlipDisplay(handle, 4)
        SetBlipScale(handle, blip.scale)
        SetBlipColour(handle, blip.color)
        SetBlipAsShortRange(handle, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(blip.label)
        EndTextCommandSetBlipName(handle)
    end

    lib.zones.poly({
        points = studio.zone.points,
        thickness = studio.zone.height,
        debug = Debug,
        onEnter = function() enterStudio(key) end,
        onExit = function() exitStudio(key) end,
    })

    ox_target:addSphereZone({
        coords = studio.computer.coords,
        radius = studio.computer.radius,
        debug = Debug,
        options = {
            {
                name = 'sm_studio_computer',
                icon = 'fa-solid fa-computer',
                label = Labels.open_computer,
                canInteract = function()
                    return activeStudio == key and not computerOpen and not isDead() and canUseComputer(key)
                end,
                onSelect = function() openComputer(key) end,
            },
        },
    })

    ox_target:addSphereZone({
        coords = studio.microphone.coords,
        radius = studio.microphone.radius,
        debug = Debug,
        options = {
            {
                name = 'sm_studio_microphone',
                icon = 'fa-solid fa-microphone-lines',
                label = Labels.take_record,
                canInteract = function()
                    return activeStudio == key and not isDead()
                end,
                onSelect = toggleMic,
            },
            {
                name = 'sm_studio_mic_settings',
                icon = 'fa-solid fa-sliders',
                label = Labels.mic_settings,
                canInteract = function()
                    return activeStudio == key and onMic and not micSettingsOpen and not isDead()
                end,
                onSelect = openMicSettings,
            },
        },
    })
end

sm_core:registerHook('core:updatePlayerDataBykey', function(key)
    if (key ~= 'metadata' and key ~= 'all') or not isDead() then return end
    if computerOpen then closeComputer() end
    if activeAnim then stopAnim() end
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    if computerOpen and activeStudio and not canUseComputer(activeStudio) then
        closeComputer()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    if activeStudio then exitStudio(activeStudio) end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    if onMic then FreezeEntityPosition(cache.ped, false) end
    stopAnim()
    if computerOpen or micSettingsOpen then SetNuiFocus(false, false) end
    destroyTv()

    for key in pairs(tvProps) do
        deleteTelevision(key)
    end
end)

RegisterNetEvent('sm_studio:speaker', function(sender, payload)
    if sender == cache.serverId then return end
    setSpeaker(payload)
end)

RegisterNetEvent('sm_studio:mirror', function(state, files)
    tvSend('mirror', { state = state or false, files = files })
end)

RegisterNUICallback('sm_studio_tv_ready', function(_, cb)
    cb(true)
    if not tvDui or tvReady then return end
    tvReady = true
    for i = 1, #tvQueue do
        SendDuiMessage(tvDui, tvQueue[i])
    end
    table.wipe(tvQueue)
end)

interface.callback('mirror', function(data, cb)
    cb(true)
    TriggerTokenEvent('sm_studio:mirror:set', data)
end)

RegisterNetEvent('sm_studio:mic', function(occupied, isRecording)
    sendUI('micState', { occupied = occupied, recording = isRecording })
end)

RegisterNetEvent('sm_studio:file:added', function(file, offset, remote)
    sendUI('fileAdded', { file = file, offset = offset, remote = remote == true })
end)

RegisterNetEvent('sm_studio:record:start', function(offset, maxSeconds)
    if not onMic then return end
    recording = true
    playAnim(Animations.microphone)
    sendUI('recordStart', { offset = offset, maxSeconds = maxSeconds })
end)

RegisterNetEvent('sm_studio:record:stop', function(save)
    if not recording then return end
    recording = false
    uploading = save == true
    stopAnimIf(Animations.microphone)
    sendUI('recordStop', { save = save == true })
end)

interface.callback('ready', function(_, cb)
    cb(true)
    frameAlive = true
    if not mounted then return end

    frameReady = true

    for i = 1, #pending do
        interface.send(pending[i])
    end

    table.wipe(pending)
end)

interface.callback('micSettingsClose', function(_, cb)
    cb(true)
    closeMicSettings()
end)

interface.callback('jobState', function(data, cb)
    cb(true)
    jobBusy = data.busy == true

    if not jobBusy and releasePending and not computerOpen then
        releasePending = false
        TriggerTokenEvent('sm_studio:computer:release')
    end
end)

interface.callback('close', function(_, cb)
    cb(true)
    closeComputer()
end)

interface.callback('notify', function(data, cb)
    cb(true)
    lib.notify({ title = 'Studio', description = data.text, type = data.type or 'info', duration = 5000 })
end)

interface.callback('uploadUrl', function(_, cb)
    lib.callback('sm_studio:upload:url', false, function(url)
        cb({ url = url or false })
    end)
end)

interface.callback('saveFile', function(data, cb)
    lib.callback('sm_studio:file:save', false, function(file)
        if data.kind == 'record' then uploading = false end
        cb({ file = file or false })
    end, data)
end)

interface.callback('uploadFailed', function(_, cb)
    cb(true)
    uploading = false
end)

interface.callback('recordEnded', function(_, cb)
    cb(true)
    if not recording then return end
    recording = false
    uploading = true
    stopAnimIf(Animations.microphone)
    TriggerTokenEvent('sm_studio:record:ended')
end)

interface.callback('renameFile', function(data, cb)
    lib.callback('sm_studio:file:rename', false, function(ok) cb({ ok = ok == true }) end, data.id, data.name)
end)

interface.callback('deleteFile', function(data, cb)
    lib.callback('sm_studio:file:delete', false, function(ok) cb({ ok = ok == true }) end, data.id)
end)

local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local B64_PAIRS = {}
local B64_CHARS = {}

for i = 0, 63 do
    B64_CHARS[i] = B64:sub(i + 1, i + 1)
end

for i = 0, 4095 do
    B64_PAIRS[i] = B64_CHARS[i >> 6] .. B64_CHARS[i & 63]
end

local sbyte = string.byte
local tconcat = table.concat

---@param data string
---@return string
local function base64(data)
    local length = #data
    local full = length - length % 3
    local out = {}
    local n = 0

    for i = 1, full, 3 do
        local a, b, c = sbyte(data, i, i + 2)
        local value = (a << 16) | (b << 8) | c
        out[n + 1] = B64_PAIRS[value >> 12]
        out[n + 2] = B64_PAIRS[value & 4095]
        n = n + 2
        if n % 40000 == 0 then Wait(0) end
    end

    local rest = length - full
    if rest == 1 then
        local value = sbyte(data, length) << 16
        out[n + 1] = B64_PAIRS[value >> 12] .. '=='
    elseif rest == 2 then
        local a, b = sbyte(data, length - 1, length)
        local value = (a << 16) | (b << 8)
        out[n + 1] = B64_PAIRS[value >> 12] .. B64_CHARS[(value >> 6) & 63] .. '='
    end

    return tconcat(out)
end

RegisterNetEvent('sm_studio:export:chunk', function(req, index, total, part)
    if not computerOpen then return end
    sendUI('exportChunk', { req = req, index = index, total = total, data = base64(part) })
    if index < total then TriggerTokenEvent('sm_studio:export:next', req, index) end
end)

interface.callback('exportAck', function(data, cb)
    cb(true)
    TriggerTokenEvent('sm_studio:export:ack', data.req)
end)

interface.callback('exportFile', function(data, cb)
    lib.callback('sm_studio:export:file', false, function(result)
        cb(result or { error = 'Terjadi kesalahan.' })
    end, data.fileId)
end)

interface.callback('youtube', function(data, cb)
    lib.callback('sm_studio:youtube', false, function(result) cb(result or { error = 'Terjadi kesalahan.' }) end, data.url)
end)

interface.callback('saveSong', function(data, cb)
    lib.callback('sm_studio:song:save', false, function(song)
        cb({ song = song or false })
    end, data)
end)

interface.callback('deleteSong', function(data, cb)
    lib.callback('sm_studio:song:delete', false, function(ok) cb({ ok = ok == true }) end, data.id)
end)

interface.callback('speakerSet', function(data, cb)
    cb(true)
    TriggerTokenEvent('sm_studio:speaker:set', data)
end)

interface.callback('speakerStop', function(_, cb)
    cb(true)
    TriggerTokenEvent('sm_studio:speaker:stop')
end)

interface.callback('recordStart', function(data, cb)
    lib.callback('sm_studio:record:start', false, function(result)
        notify(result.message)
        cb({ ok = result.status == true })
    end, data.position)
end)

interface.callback('recordStop', function(data, cb)
    lib.callback('sm_studio:record:stop', false, function(result)
        notify(result.message)
        cb({ ok = result.status == true })
    end, data.save)
end)
