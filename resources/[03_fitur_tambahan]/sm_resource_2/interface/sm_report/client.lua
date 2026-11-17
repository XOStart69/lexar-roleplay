local config = localmodule 'config.shared'
local hasFrame = interface.init(false)
local infoui = exports.rhd_infoui

local SPECTATE_INFO = 'sm_report:spectate'
local SPECTATE_DEPTH = 15.0
local CONTROL_STOP = 177

local open = false
local mounted = false
local ready = false
local pending

local ACTIONS = {
    mine = 'sm_report:mine',
    list = 'sm_report:list',
    create = 'sm_report:create',
    messages = 'sm_report:messages',
    send = 'sm_report:send',
    claim = 'sm_report:claim',
    unclaim = 'sm_report:unclaim',
    resolve = 'sm_report:resolve',
    delete = 'sm_report:delete',
    priority = 'sm_report:priority',
    action = 'sm_report:action',
    history = 'sm_report:history',
    logs = 'sm_report:logs',
    clearResolved = 'sm_report:clearResolved',
    setDuty = 'sm_report:setDuty',
    rate = 'sm_report:rate',
    leaderboard = 'sm_report:leaderboard',
}

---@param action string
---@param data? any
local function send(action, data)
    if ready then
        interface.send({ action = action, data = data })
    end
end

local function close()
    if not open then return end
    open = false
    pending = nil
    interface.focus(false, false)
    SetTimeout(100, function()
        if open or not mounted then return end
        mounted = false
        ready = false
        interface.hide()
    end)
end

local function openUI()
    if not hasFrame or open then return end

    local data = lib.callback.await('sm_report:init', false)
    if not data then
        return lib.notify({ title = 'Laporan', description = 'Data laporan belum siap, coba lagi.', type = 'error' })
    end

    open = true
    pending = data

    if ready then
        send('open', data)
        send('duty', GlobalState.reportDuty or {})
        pending = nil
        interface.focus(true, true)
    elseif not mounted then
        mounted = true
        interface.show()
    end
end

if hasFrame then
    interface.callback('ready', function(_, cb)
        ready = true
        cb({})
        if open and pending then
            send('open', pending)
            send('duty', GlobalState.reportDuty or {})
            pending = nil
            interface.focus(true, true)
        end
    end)

    interface.callback('close', function(_, cb)
        cb({})
        close()
    end)

    interface.callback('request', function(data, cb)
        local name = type(data) == 'table' and ACTIONS[data.name]
        if not name or not open then return cb({ ok = false, message = 'Permintaan tidak valid.' }) end

        local args = type(data.args) == 'table' and data.args or {}
        local first, second = lib.callback.await(name, false, args[1], args[2], args[3])

        if first == true or first == false then
            cb({ ok = first, data = second, message = type(second) == 'string' and second or nil })
        else
            cb({ ok = first ~= nil, data = first })
        end
    end)
end

AddStateBagChangeHandler('reportDuty', 'global', function(_, _, value)
    if open then
        send('duty', value or {})
    end
end)

RegisterNetEvent('sm_report:client:push', function(kind, payload)
    if source == '' or not open then return end
    send('push', { kind = kind, payload = payload })
end)

local SOUNDS = {
    report = { 'Event_Message_Purple', 'GTAO_FM_Events_Soundset' },
    message = { 'Text_Arrive_Tone', 'Phone_SoundSet_Default' },
}

RegisterNetEvent('sm_report:client:sound', function(kind)
    if source == '' then return end
    local sound = SOUNDS[kind]
    if sound then
        PlaySoundFrontend(-1, sound[1], sound[2], true)
    end
end)

RegisterNetEvent('sm_report:client:teleport', function(x, y, z)
    if source == '' then return end
    SetEntityCoords(cache.ped, x, y, z, false, false, false, false)
end)

local spectating = false

---@param ped number
---@param hidden boolean
local function hideSelf(ped, hidden)
    SetEntityVisible(ped, not hidden, false)
    SetEntityInvincible(ped, hidden)
    SetEntityCollision(ped, not hidden, not hidden)
    FreezeEntityPosition(ped, hidden)
end

---@param target number
---@return number?
local function targetPed(target)
    local player = GetPlayerFromServerId(target)
    if player == -1 then return end
    local ped = GetPlayerPed(player)
    if ped ~= 0 and DoesEntityExist(ped) then return ped end
end

RegisterNetEvent('sm_report:client:spectate', function(target, x, y, z)
    if source == '' or spectating then return end
    if open then
        send('close')
        close()
    end

    spectating = true
    local ped = cache.ped
    local origin = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    DoScreenFadeOut(300)
    Wait(300)
    hideSelf(ped, true)
    SetEntityCoords(ped, x, y, z - SPECTATE_DEPTH, false, false, false, false)

    local watched
    local deadline = GetGameTimer() + 5000
    while not watched and GetGameTimer() < deadline do
        watched = targetPed(target)
        Wait(100)
    end

    if watched then
        NetworkSetInSpectatorMode(true, watched)
        infoui:show({
            id = SPECTATE_INFO,
            title = ('Spectate ID %d'):format(target),
            icon = 'fa-solid fa-eye',
            description = '[kbd]BACKSPACE[/kbd] Berhenti spectate',
        })
    else
        spectating = false
        lib.notify({ title = 'Laporan', description = 'Pemain tidak bisa di-spectate.', type = 'error' })
    end
    DoScreenFadeIn(300)

    local nextFollow = 0
    while spectating do
        DisableControlAction(0, CONTROL_STOP, true)
        if IsDisabledControlJustPressed(0, CONTROL_STOP) then
            spectating = false
        end

        local now = GetGameTimer()
        if spectating and now >= nextFollow then
            nextFollow = now + 500
            local current = targetPed(target)
            if not current then
                spectating = false
                lib.notify({ title = 'Laporan', description = 'Pemain keluar dari jangkauan.', type = 'inform' })
            else
                if current ~= watched then
                    watched = current
                    NetworkSetInSpectatorMode(true, watched)
                end
                local coords = GetEntityCoords(watched)
                SetEntityCoords(ped, coords.x, coords.y, coords.z - SPECTATE_DEPTH, false, false, false, false)
            end
        end
        Wait(0)
    end

    infoui:remove(SPECTATE_INFO)
    DoScreenFadeOut(300)
    Wait(300)
    NetworkSetInSpectatorMode(false, ped)
    SetEntityCoords(ped, origin.x, origin.y, origin.z, false, false, false, false)
    SetEntityHeading(ped, heading)
    hideSelf(ped, false)
    lib.callback.await('sm_report:spectateEnd', false)
    DoScreenFadeIn(300)
end)

AddEventHandler('sm_report:client:forceClose', function()
    spectating = false
    if open then
        send('close')
        close()
    end
end)

RegisterCommand(config.command, function()
    if open then
        send('close')
        close()
    else
        openUI()
    end
end, false)

RegisterKeyMapping(config.command, 'Buka menu laporan', 'keyboard', '')
