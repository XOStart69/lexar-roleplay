local config = localmodule 'config'
local exportWrapper = require 'export_wrapper'
local interact = exports.rhd_interact
local infoui = exports.rhd_infoui
local hasFrame = interface.init(false)

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetPlayerServerId = GetPlayerServerId
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local IsControlJustPressed = IsControlJustPressed
local DrawMarker = DrawMarker
local tonumber = tonumber
local smatch = string.match

local PROP = joaat(config.prop)
local STREAM_DISTANCE = config.streamDistance
local READ_DISTANCE = config.readDistance
local GIVE_DISTANCE = config.giveDistance
local SELECT_TIMEOUT = config.selectTimeout
local EMOTE = config.emote
local INFO_ID = 'sm_notepad:give'
local GIVE_HINT = '[kbd]←[/kbd] [kbd]→[/kbd] Ganti penerima\n[kbd]ENTER[/kbd] Beri  [kbd]BACKSPACE[/kbd] Batal'
local CONTROL_LEFT, CONTROL_RIGHT, CONTROL_ACCEPT, CONTROL_CANCEL = 189, 190, 191, 194

local REASONS = {
    cooldown = 'Tunggu sebentar.',
    blank = 'Catatan masih kosong.',
    vehicle = 'Tidak bisa menjatuhkan catatan dari dalam kendaraan.',
    bucket = 'Tidak bisa menjatuhkan catatan di sini.',
    full = 'Tidak bisa menjatuhkan catatan lagi di kota ini.',
    limit = ('Kamu sudah menjatuhkan %d catatan.'):format(config.maxPerPlayer),
    distance = 'Penerima terlalu jauh.',
    target_full = 'Tas penerima penuh.',
    gone = 'Catatan sudah tidak ada.',
}

---@type { mode: 'edit'|'read', slot?: number, noteId?: number, text: string, font: string, emote: boolean }?
local session
local frameMounted = false
local frameReady = false
local selecting = false

---@type table<number, table>
local notes = {}

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ title = 'Catatan', description = description, type = kind or 'error' })
end

---@param reason? string
---@param fallback string
local function notifyFail(reason, fallback)
    notify(REASONS[reason] or fallback)
end

local function startEmote()
    return pcall(function() emotemenu:EmoteCommandStart(EMOTE) end)
end

local function stopEmote()
    pcall(function() emotemenu:EmoteCancel() end)
end

local function sendSession()
    if not session then return end
    interface.send({
        action = 'open',
        data = {
            mode = session.mode,
            text = session.text,
            font = session.font,
            maxLength = config.maxLength,
            fonts = config.fonts,
        },
    })
    interface.focus(true, true)
end

---@param data table
local function openFrame(data)
    if not hasFrame then return end

    session = data
    if data.mode == 'edit' then
        playerState.invBusy = true
    end

    if frameReady then
        return sendSession()
    end

    if not frameMounted then
        frameMounted = true
        interface.show()
    end
end

---@return table?
local function finishSession()
    local current = session
    if not current then return end

    session = nil
    interface.focus(false, false)

    if current.mode == 'edit' then
        playerState.invBusy = false
    end

    if current.emote then
        stopEmote()
    end

    SetTimeout(50, function()
        if session or not frameMounted then return end
        frameMounted = false
        frameReady = false
        interface.hide()
    end)

    return current
end

---@param label string
---@param duration number
---@return boolean
local function progress(label, duration)
    return lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = false },
    }) == true
end

---@param players table[]
---@param index number
local function showTarget(players, index)
    infoui:show({
        id = INFO_ID,
        title = ('Beri ke ID %d'):format(GetPlayerServerId(players[index].id)),
        icon = 'fa-solid fa-hand-holding',
        description = GIVE_HINT,
    })
end

---@return number?
local function selectTarget()
    local players = lib.getNearbyPlayers(GetEntityCoords(cache.ped), GIVE_DISTANCE, false)
    local count = #players

    if count == 0 then
        notify('Tidak ada orang di sekitarmu.')
        return
    end

    if count == 1 then
        return GetPlayerServerId(players[1].id)
    end

    selecting = true
    local index, chosen = 1, nil
    local deadline = GetGameTimer() + SELECT_TIMEOUT
    showTarget(players, index)

    while selecting and GetGameTimer() < deadline do
        local target = players[index]

        if IsControlJustPressed(0, CONTROL_LEFT) then
            index = index > 1 and index - 1 or count
            showTarget(players, index)
        elseif IsControlJustPressed(0, CONTROL_RIGHT) then
            index = index < count and index + 1 or 1
            showTarget(players, index)
        elseif IsControlJustPressed(0, CONTROL_ACCEPT) then
            chosen = GetPlayerServerId(target.id)
            break
        elseif IsControlJustPressed(0, CONTROL_CANCEL) then
            break
        end

        if DoesEntityExist(target.ped) then
            local coords = GetEntityCoords(target.ped)
            DrawMarker(0, coords.x, coords.y, coords.z + 1.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 0, 204, 201, 160, false, false, 0, false, false, false, false)
        end

        Wait(0)
    end

    selecting = false
    infoui:remove(INFO_ID)
    return chosen
end

---@param id number
local function readNote(id)
    if session or selecting then return end
    if not progress('Membaca Catatan...', config.readDuration) then return end

    local note = lib.callback.await('sm_notepad:read', false, id)
    if not note then return notify(REASONS.gone) end

    openFrame({ mode = 'read', noteId = id, text = note.text, font = note.font, emote = false })
end

---@param note table
local function despawnNote(note)
    local entity = note.entity
    if not entity then return end

    note.entity = nil
    interact:removeLocalEntity(entity)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

---@param note table
local function spawnNote(note)
    if note.entity or note.loading then return end
    note.loading = true

    local loaded = pcall(lib.requestModel, PROP, 5000)
    note.loading = false
    if not loaded or not note.inRange or note.removed then return end

    local coords = note.coords
    local entity = CreateObject(PROP, coords.x, coords.y, coords.z, false, false, false)
    SetModelAsNoLongerNeeded(PROP)
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)
    SetEntityCollision(entity, false, false)

    note.entity = entity
    interact:addLocalEntity(entity, note.options)
end

---@param data { id: number, x: number, y: number, z: number }
local function registerNote(data)
    local id = data.id
    if notes[id] then return end

    local note = { id = id, coords = vector3(data.x, data.y, data.z) }
    note.options = {
        {
            name = 'sm_notepad_read',
            label = 'Baca Catatan',
            icon = 'fa-solid fa-note-sticky',
            distance = READ_DISTANCE,
            onSelect = function() readNote(id) end,
        },
    }

    note.point = lib.points.new({
        coords = note.coords,
        distance = STREAM_DISTANCE,
        onEnter = function()
            note.inRange = true
            CreateThread(function() spawnNote(note) end)
        end,
        onExit = function()
            note.inRange = false
            despawnNote(note)
        end,
    })

    notes[id] = note
end

---@param id number
local function unregisterNote(id)
    local note = notes[id]
    if not note then return end

    notes[id] = nil
    note.removed = true
    note.point:remove()
    despawnNote(note)

    if session and session.noteId == id then
        if frameReady then
            interface.send({ action = 'close' })
        end
        finishSession()
        notify('Seseorang telah mengambil catatan ini.', 'inform')
    end
end

AddStateBagChangeHandler(nil, 'global', function(_, key, value)
    local id = tonumber(smatch(key, '^smnote:(%d+)$'))
    if not id then return end

    if value then
        registerNote(value)
    else
        unregisterNote(id)
    end
end)

CreateThread(function()
    local all = lib.callback.await('sm_notepad:getAll', false)
    if not all then return end
    for i = 1, #all do
        registerNote(all[i])
    end
end)

---@param data any
---@return string text
---@return string? font
local function readPayload(data)
    if type(data) ~= 'table' then return '' end
    return type(data.text) == 'string' and data.text or '', data.font
end

if hasFrame then
    interface.callback('ready', function(_, cb)
        frameReady = true
        if session then
            sendSession()
        end
        cb({})
    end)

    interface.callback('close', function(data, cb)
        cb({})
        local current = finishSession()
        if not current or current.mode ~= 'edit' then return end

        local text, font = readPayload(data)
        if text == current.text and font == current.font then return end

        CreateThread(function()
            if not lib.callback.await('sm_notepad:save', false, current.slot, text, font) then
                notify('Gagal menyimpan catatan.')
            end
        end)
    end)

    interface.callback('drop', function(data, cb)
        cb({})
        local current = finishSession()
        if not current or current.mode ~= 'edit' then return end

        local text, font = readPayload(data)
        CreateThread(function()
            local ok, reason = lib.callback.await('sm_notepad:drop', false, current.slot, text, font)
            if not ok then notifyFail(reason, 'Gagal menjatuhkan catatan.') end
        end)
    end)

    interface.callback('give', function(data, cb)
        cb({})
        local current = finishSession()
        if not current or current.mode ~= 'edit' then return end

        local text, font = readPayload(data)
        CreateThread(function()
            local target = selectTarget()
            if not target then return end

            local ok, reason = lib.callback.await('sm_notepad:give', false, current.slot, target, text, font)
            if not ok then return notifyFail(reason, 'Gagal memberikan catatan.') end

            lib.playAnim(cache.ped, 'mp_common', 'givetake1_a', 8.0, -8.0, 2000, 50)
        end)
    end)

    interface.callback('pickup', function(_, cb)
        cb({})
        local current = finishSession()
        if not current or current.mode ~= 'read' then return end

        CreateThread(function()
            local ok, reason = lib.callback.await('sm_notepad:pickup', false, current.noteId)
            if not ok then notifyFail(reason, 'Gagal mengambil catatan.') end
        end)
    end)
end

RegisterNetEvent('sm_notepad:client:received', function()
    if source == '' then return end
    notify('Kamu menerima sebuah catatan.', 'inform')
    lib.playAnim(cache.ped, 'mp_common', 'givetake1_a', 8.0, -8.0, 2000, 50)
end)

AddEventHandler('sm_notepad:client:forceClose', function()
    selecting = false
    if not session then return end
    if frameReady then
        interface.send({ action = 'close' })
    end
    finishSession()
end)

exportWrapper('sm_notepad', 'openNotepad', function(_, slot)
    if session or selecting or not slot or not slot.slot then return end

    local slotId = slot.slot
    local metadata = slot.metadata or {}

    CreateThread(function()
        local emote = startEmote()

        if session or not progress('Membuka Catatan...', config.openDuration) then
            if emote then stopEmote() end
            return
        end

        openFrame({
            mode = 'edit',
            slot = slotId,
            text = type(metadata.text) == 'string' and metadata.text or '',
            font = type(metadata.font) == 'string' and metadata.font or config.defaultFont,
            emote = emote,
        })
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    if session and session.mode == 'edit' then
        playerState.invBusy = false
    end
    for _, note in pairs(notes) do
        despawnNote(note)
    end
end)
