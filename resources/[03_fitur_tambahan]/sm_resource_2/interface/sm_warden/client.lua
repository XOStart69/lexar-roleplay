local config = localmodule 'config'
local infoui = exports.rhd_infoui
local hasFrame = interface.init(false)

local Wait = Wait
local GetGameTimer = GetGameTimer
local GetEntityCoords = GetEntityCoords
local GetActivePlayers = GetActivePlayers
local GetPlayerServerId = GetPlayerServerId
local GetPlayerPed = GetPlayerPed
local GetPedBoneIndex = GetPedBoneIndex
local GetEntityMatrix = GetEntityMatrix
local SetEntityMatrix = SetEntityMatrix
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local AttachEntityToEntity = AttachEntityToEntity
local DisableControlAction = DisableControlAction
local IsControlPressed = IsControlPressed
local IsDisabledControlPressed = IsDisabledControlPressed
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local pairs = pairs
local type = type
local sformat = string.format

---@param value number
---@param min number
---@param max number
---@return number
local function mclamp(value, min, max)
    return value < min and min or value > max and max or value
end

local MODEL = joaat(config.model)
local SELECT_DISTANCE = config.selectDistance
local SHOW_DURATION = config.showDuration
local STREAM_DISTANCE = config.streamDistance
local SCAN_INTERVAL = config.scanInterval
local WEAR_ANIM = config.wearAnim
local ACCESS_CARDS = config.accessCards
local INFO_ID = 'sm_warden:adjust'
local CARD_ANIM_DICT, CARD_ANIM_CLIP = 'cop_badge_1@dad', 'cop_badge_1_clip'
local CARD_PROP = `prop_franklin_dl`

local CONTROL_LEFT, CONTROL_RIGHT, CONTROL_UP, CONTROL_DOWN = 174, 175, 172, 173
local CONTROL_PGUP, CONTROL_PGDN, CONTROL_TAB = 10, 11, 37
local CONTROL_SCROLL_UP, CONTROL_SCROLL_DOWN = 241, 242
local CONTROL_SPRINT, CONTROL_ACCEPT, CONTROL_CANCEL = 21, 191, 177
local ADJUST_CONTROLS = { 10, 11, 14, 15, 16, 17, 37, 172, 173, 174, 175, 177, 191, 241, 242, 261, 262 }

---@type 'creator'|'card'|nil
local mode
---@type 'warden'|'seal'|nil
local creatorKind
local frameMounted = false
local frameReady = false
local pending
local creatorSlot
local cardToken = 0
local showingAnim = false
local cardProp
local adjusting = false

local DEFAULT_PLACEMENT = config.placement
local BONE = DEFAULT_PLACEMENT.bone

---@type table?
local previewPlacement
---@type table<number, { ped: number, proxy: number, object: number, placement: table }>
local displays = {}
local rendered, renderedCount = {}, 0
local syncing = false

---@param description string
---@param kind? string
local function notify(description, kind)
    lib.notify({ title = 'The Warden', description = description, type = kind or 'error' })
end

local function flush()
    if not pending then return end
    interface.send(pending)
    pending = nil
    if mode == 'creator' then
        interface.focus(true, true)
    end
end

---@param action string
---@param data table
local function openFrame(action, data)
    if not hasFrame then return end

    pending = { action = action, data = data }

    if frameReady then
        return flush()
    end

    if not frameMounted then
        frameMounted = true
        interface.show()
    end
end

local function closeFrame()
    mode = nil
    creatorSlot = nil
    creatorKind = nil
    pending = nil
    interface.focus(false, false)

    SetTimeout(50, function()
        if mode or not frameMounted then return end
        frameMounted = false
        frameReady = false
        interface.hide()
    end)
end

local function hideCard()
    if mode ~= 'card' then return end
    if frameReady then
        interface.send({ action = 'hideCard' })
    end
    closeFrame()
end

---@return table[]
local function fetchNearby()
    local nearby = lib.getNearbyPlayers(GetEntityCoords(cache.ped), SELECT_DISTANCE, true)
    local ids = {}
    for i = 1, #nearby do
        ids[i] = GetPlayerServerId(nearby[i].id)
    end
    return lib.callback.await('sm_warden:nearby', false, ids) or {}
end

local function stopCardAnim()
    showingAnim = false
end

local function startCardAnim()
    if showingAnim then return end
    showingAnim = true

    CreateThread(function()
        local ped = cache.ped
        if pcall(lib.requestModel, CARD_PROP, 5000) then
            local coords = GetEntityCoords(ped)
            cardProp = CreateObject(CARD_PROP, coords.x, coords.y, coords.z + 0.2, true, true, true)
            AttachEntityToEntity(cardProp, ped, GetPedBoneIndex(ped, 28422), 0.084, 0.02, -0.026, -173.85, -88.02, 63.06, true, true, false, false, 1, true)
            SetModelAsNoLongerNeeded(CARD_PROP)
        end

        local deadline = GetGameTimer() + SHOW_DURATION
        while showingAnim and GetGameTimer() < deadline do
            if not IsEntityPlayingAnim(ped, CARD_ANIM_DICT, CARD_ANIM_CLIP, 3) then
                pcall(lib.playAnim, ped, CARD_ANIM_DICT, CARD_ANIM_CLIP, 3.0, 3.0, -1, 51, 0, false, false, false)
            end
            Wait(500)
        end

        showingAnim = false
        StopAnimTask(ped, CARD_ANIM_DICT, CARD_ANIM_CLIP, 1.0)
        if cardProp then
            DeleteEntity(cardProp)
            cardProp = nil
        end
    end)
end

---@param value any
---@return table
local function resolvePlacement(value)
    return type(value) == 'table' and value or DEFAULT_PLACEMENT
end

---@param entity number
---@param ped number
---@param p table
local function attach(entity, ped, p)
    AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, BONE), p.x, p.y, p.z, p.rx, p.ry, p.rz, true, true, false, false, 2, true)
end

---@param sid number
---@param p table
local function applyPlacement(sid, p)
    local display = displays[sid]
    if not display then return end

    display.placement = p
    if DoesEntityExist(display.proxy) and DoesEntityExist(display.ped) then
        attach(display.proxy, display.ped, p)
    end
end

local function rebuildRendered()
    local n = 0
    for _, display in pairs(displays) do
        n = n + 1
        rendered[n] = display
    end
    for i = n + 1, renderedCount do
        rendered[i] = nil
    end
    renderedCount = n
end

---@param sid number
local function removeDisplay(sid)
    local display = displays[sid]
    if not display then return end

    displays[sid] = nil
    if DoesEntityExist(display.proxy) then DeleteEntity(display.proxy) end
    if DoesEntityExist(display.object) then DeleteEntity(display.object) end
end

---@param sid number
---@param ped number
---@param p table
local function createDisplay(sid, ped, p)
    local coords = GetEntityCoords(ped)

    local proxy = CreateObject(MODEL, coords.x, coords.y, coords.z, false, false, false)
    SetEntityCollision(proxy, false, false)
    SetEntityVisible(proxy, false, false)
    attach(proxy, ped, p)

    local object = CreateObject(MODEL, coords.x, coords.y, coords.z, false, false, false)
    SetEntityCollision(object, false, false)
    FreezeEntityPosition(object, true)

    displays[sid] = { ped = ped, proxy = proxy, object = object, placement = p }
end

local seen = {}

local function sync()
    if syncing then return end
    syncing = true

    local myPlayer = cache.playerId
    local myCoords = GetEntityCoords(cache.ped)
    local players = GetActivePlayers()
    local changed = false

    for i = 1, #players do
        local pid = players[i]
        local sid = GetPlayerServerId(pid)
        local preview = pid == myPlayer and previewPlacement
        local wanted = preview or Player(sid).state.wardenPin

        if wanted then
            local ped = GetPlayerPed(pid)
            if ped ~= 0 and #(myCoords - GetEntityCoords(ped)) <= STREAM_DISTANCE then
                seen[sid] = true

                local display = displays[sid]
                if display and (display.ped ~= ped or not DoesEntityExist(display.proxy) or not DoesEntityExist(display.object)) then
                    removeDisplay(sid)
                    display = nil
                    changed = true
                end

                if not display and pcall(lib.requestModel, MODEL, 5000) then
                    createDisplay(sid, ped, preview or resolvePlacement(wanted))
                    changed = true
                end
            end
        end
    end

    for sid in pairs(displays) do
        if not seen[sid] then
            removeDisplay(sid)
            changed = true
        end
    end

    for sid in pairs(seen) do
        seen[sid] = nil
    end

    if changed then
        rebuildRendered()
    end

    syncing = false
end

CreateThread(function()
    while true do
        sync()
        Wait(SCAN_INTERVAL)
    end
end)

CreateThread(function()
    while true do
        local sleep = 500

        if renderedCount > 0 then
            sleep = 0
            for i = 1, renderedCount do
                local display = rendered[i]
                local s = display.placement.scale
                local f, r, u, p = GetEntityMatrix(display.proxy)
                SetEntityMatrix(display.object, f.x * s, f.y * s, f.z * s, r.x * s, r.y * s, r.z * s, u.x * s, u.y * s, u.z * s, p.x, p.y, p.z)
            end
        end

        Wait(sleep)
    end
end)

AddStateBagChangeHandler('wardenPin', nil, function(bagName, _, value)
    if not value then return end

    local player = GetPlayerFromStateBagName(bagName)
    if player == 0 then return end
    if player == cache.playerId and previewPlacement then return end

    applyPlacement(GetPlayerServerId(player), resolvePlacement(value))
end)

---@param label string
---@param duration number
---@return boolean
local function progress(label, duration)
    return lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, combat = true, car = true },
        anim = { dict = WEAR_ANIM.dict, clip = WEAR_ANIM.clip, flag = WEAR_ANIM.flag },
    }) == true
end

---@param slot number
local function wearPin(slot)
    if not progress('Memasang Pin...', config.wearDuration) then return end

    local ok, reason = lib.callback.await('sm_warden:wear', false, slot)
    if not ok then return notify(reason or 'Gagal memasang pin.') end

    notify('Pin terpasang.', 'success')
    CreateThread(sync)
end

local function removePin()
    if not progress('Melepas Pin...', 1500) then return end
    lib.callback.await('sm_warden:unwear', false)
    CreateThread(sync)
end

---@param slot number
local function showToNearby(slot)
    if showingAnim then return end

    local ok, reason = lib.callback.await('sm_warden:show', false, slot)
    if not ok then return notify(reason or 'Gagal menunjukkan kartu.') end

    startCardAnim()
end

RegisterNetEvent('sm_warden:client:menu', function(slot)
    if source == '' or adjusting then return end

    local wearing = LocalPlayer.state.wardenPin

    lib.registerContext({
        id = 'sm_warden_menu',
        title = 'The Warden',
        options = {
            {
                title = 'Tunjukkan ke Sekitar',
                description = ('Perlihatkan kartu ke orang dalam radius %d meter'):format(config.showDistance),
                icon = 'id-card',
                onSelect = function() showToNearby(slot) end,
            },
            {
                title = wearing and 'Lepas Pin' or 'Gunakan Pin',
                description = wearing and 'Lepas pin dari badan' or 'Pasang pin The Warden di badan',
                icon = 'thumbtack',
                onSelect = function()
                    if wearing then
                        removePin()
                    else
                        wearPin(slot)
                    end
                end,
            },
        },
    })

    lib.showContext('sm_warden_menu')
end)

RegisterNetEvent('sm_warden:client:creator', function(slot)
    if source == '' or mode or adjusting then return end

    mode = 'creator'
    creatorKind = 'warden'
    creatorSlot = slot

    local players = fetchNearby()
    if mode ~= 'creator' then return end

    openFrame('openCreator', {
        players = players,
        minDays = config.minDays,
        maxDays = config.maxDays,
    })
end)

RegisterNetEvent('sm_warden:client:sealCreator', function(slot, issuer)
    if source == '' or mode or adjusting or type(issuer) ~= 'table' then return end

    mode = 'creator'
    creatorKind = 'seal'
    creatorSlot = slot

    local players = fetchNearby()
    if mode ~= 'creator' then return end

    openFrame('openSealCreator', {
        players = players,
        job = issuer.job,
        signature = issuer.signature,
    })
end)

RegisterNetEvent('sm_warden:client:show', function(card)
    if source == '' or type(card) ~= 'table' or mode == 'creator' or adjusting then return end
    if card.image and not ACCESS_CARDS[card.image] then return end
    if card.seal and (type(card.faction) ~= 'string' or type(card.signature) ~= 'string') then return end

    local wasShowing = mode == 'card'
    mode = 'card'
    cardToken = cardToken + 1
    local token = cardToken

    openFrame('showCard', card)

    SetTimeout(SHOW_DURATION, function()
        if cardToken == token then
            hideCard()
        end
    end)

    if wasShowing then return end

    CreateThread(function()
        while mode == 'card' do
            DisableControlAction(0, CONTROL_CANCEL, true)
            if IsDisabledControlJustPressed(0, CONTROL_CANCEL) then
                hideCard()
            end
            Wait(0)
        end
    end)
end)

RegisterNetEvent('sm_warden:client:cardAnim', function()
    if source == '' then return end
    startCardAnim()
end)

---@param value number
---@return number
local function wrapAngle(value)
    if value > 180.0 then return value - 360.0 end
    if value < -180.0 then return value + 360.0 end
    return value
end

---@param edit table
---@param rotMode boolean
local function showAdjustHint(edit, rotMode)
    infoui:show({
        id = INFO_ID,
        title = rotMode and 'Warden Pin - Rotasi' or 'Warden Pin - Posisi',
        icon = 'fa-solid fa-thumbtack',
        description = sformat(
            'X %.3f  Y %.3f  Z %.3f\nRX %.1f  RY %.1f  RZ %.1f  Skala %.3f\n[kbd]←[/kbd][kbd]→[/kbd] %s  [kbd]↑[/kbd][kbd]↓[/kbd] %s  [kbd]PgUp[/kbd][kbd]PgDn[/kbd] %s\n[kbd]Scroll[/kbd] Skala  [kbd]TAB[/kbd] Ganti mode  [kbd]SHIFT[/kbd] Cepat\n[kbd]ENTER[/kbd] Simpan  [kbd]BACKSPACE[/kbd] Batal',
            edit.x, edit.y, edit.z, edit.rx, edit.ry, edit.rz, edit.scale,
            rotMode and 'RX' or 'X', rotMode and 'RY' or 'Y', rotMode and 'RZ' or 'Z'
        ),
    })
end

---@param saved? table
local function stopAdjust(saved)
    adjusting = false
    previewPlacement = nil
    infoui:remove(INFO_ID)

    applyPlacement(cache.serverId, saved or resolvePlacement(LocalPlayer.state.wardenPin))
end

---@param edit table
---@param save boolean
local function finishAdjust(edit, save)
    if save then
        local ok, reason = lib.callback.await('sm_warden:place', false, edit)
        if not ok then
            notify(reason or 'Gagal menyimpan posisi pin.')
            return
        end
        notify('Posisi pin tersimpan di kartu.', 'success')
    end

    stopAdjust(save and edit or nil)
    sync()
end

RegisterNetEvent('sm_warden:client:adjust', function(current)
    if source == '' or adjusting or mode then return end

    adjusting = true

    local base = resolvePlacement(current)
    local edit = {
        x = base.x, y = base.y, z = base.z,
        rx = base.rx, ry = base.ry, rz = base.rz,
        scale = base.scale,
    }
    previewPlacement = edit

    sync()
    applyPlacement(cache.serverId, edit)

    local maxOffset = config.maxOffset

    local rotMode = false
    local lastHint = 0
    local minScale, maxScale = config.minScale, config.maxScale
    local controlCount = #ADJUST_CONTROLS
    showAdjustHint(edit, rotMode)

    while adjusting do
        for i = 1, controlCount do
            DisableControlAction(0, ADJUST_CONTROLS[i], true)
        end

        local fast = IsControlPressed(0, CONTROL_SPRINT)
        local changed = false

        if IsDisabledControlJustPressed(0, CONTROL_TAB) then
            rotMode = not rotMode
            changed = true
        end

        local dx = (IsDisabledControlPressed(0, CONTROL_RIGHT) and 1 or 0) - (IsDisabledControlPressed(0, CONTROL_LEFT) and 1 or 0)
        local dy = (IsDisabledControlPressed(0, CONTROL_UP) and 1 or 0) - (IsDisabledControlPressed(0, CONTROL_DOWN) and 1 or 0)
        local dz = (IsDisabledControlPressed(0, CONTROL_PGUP) and 1 or 0) - (IsDisabledControlPressed(0, CONTROL_PGDN) and 1 or 0)

        if dx ~= 0 or dy ~= 0 or dz ~= 0 then
            if rotMode then
                local step = fast and 2.0 or 0.4
                edit.rx = wrapAngle(edit.rx + dx * step)
                edit.ry = wrapAngle(edit.ry + dy * step)
                edit.rz = wrapAngle(edit.rz + dz * step)
            else
                local step = fast and 0.004 or 0.0008
                edit.x = mclamp(edit.x + dx * step, -maxOffset, maxOffset)
                edit.y = mclamp(edit.y + dy * step, -maxOffset, maxOffset)
                edit.z = mclamp(edit.z + dz * step, -maxOffset, maxOffset)
            end
            changed = true
        end

        local ds = (IsDisabledControlJustPressed(0, CONTROL_SCROLL_UP) and 1 or 0) - (IsDisabledControlJustPressed(0, CONTROL_SCROLL_DOWN) and 1 or 0)
        if ds ~= 0 then
            edit.scale = mclamp(edit.scale + ds * (fast and 0.02 or 0.005), minScale, maxScale)
            changed = true
        end

        if changed then
            applyPlacement(cache.serverId, edit)
            local now = GetGameTimer()
            if now - lastHint > 120 then
                lastHint = now
                showAdjustHint(edit, rotMode)
            end
        end

        if IsDisabledControlJustPressed(0, CONTROL_ACCEPT) then
            finishAdjust(edit, true)
        elseif IsDisabledControlJustPressed(0, CONTROL_CANCEL) then
            finishAdjust(edit, false)
        end

        Wait(0)
    end
end)

if hasFrame then
    interface.callback('ready', function(_, cb)
        frameReady = true
        flush()
        cb({})
    end)

    interface.callback('refresh', function(_, cb)
        if mode ~= 'creator' then return cb({ players = {} }) end
        cb({ players = fetchNearby() })
    end)

    interface.callback('create', function(data, cb)
        local slot = creatorSlot
        if mode ~= 'creator' or creatorKind ~= 'warden' or not slot or type(data) ~= 'table' then
            return cb({ ok = false })
        end

        local ok, reason = lib.callback.await('sm_warden:create', false, slot, data.target, data.ends)
        cb({ ok = ok == true })

        if ok then
            closeFrame()
            notify('Kartu The Warden berhasil dibuat.', 'success')
        else
            notify(reason or 'Gagal membuat kartu.')
        end
    end)

    interface.callback('createSeal', function(data, cb)
        local slot = creatorSlot
        if mode ~= 'creator' or creatorKind ~= 'seal' or not slot or type(data) ~= 'table' then
            return cb({ ok = false })
        end

        local ok, reason = lib.callback.await('sm_warden:sealCreate', false, slot, data.target)
        cb({ ok = ok == true })

        if ok then
            closeFrame()
            notify('Seal of Protection berhasil dibuat.', 'success')
        else
            notify(reason or 'Gagal membuat kartu.')
        end
    end)

    interface.callback('close', function(_, cb)
        cb({})
        if mode == 'creator' then
            closeFrame()
        end
    end)
end

AddEventHandler('sm_warden:client:forceClose', function()
    stopCardAnim()
    if adjusting then
        stopAdjust()
    end
    if not mode then return end
    if frameReady then
        interface.send({ action = 'close' })
    end
    closeFrame()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    if adjusting then
        infoui:remove(INFO_ID)
    end
    if cardProp then
        DeleteEntity(cardProp)
    end
    for sid in pairs(displays) do
        removeDisplay(sid)
    end
end)
