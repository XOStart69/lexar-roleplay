if not interface.init(false) then
    return
end

local HIDE_DELAY_MS = 500
local MESSAGE_GRACE_MS = 300

local GetGameTimer = GetGameTimer

local composerOpen = false
local opening = false
local messageUntil = 0
local visible = false
local hideToken = 0

---@return boolean
local function ensureVisible()
    hideToken = hideToken + 1

    if visible then
        return true
    end

    if not interface.show() then
        return false
    end

    visible = true
    return true
end

local function releaseFrame()
    if not visible or composerOpen or GetGameTimer() < messageUntil then
        return
    end

    hideToken = hideToken + 1
    local token = hideToken

    SetTimeout(HIDE_DELAY_MS, function()
        if token ~= hideToken or composerOpen or GetGameTimer() < messageUntil then
            return
        end

        visible = false
        interface.hide()
    end)
end

---@param syncUi? boolean
local function closeComposer(syncUi)
    if not composerOpen then
        return
    end

    composerOpen = false

    if syncUi then
        interface.send({ action = 'closeComposer' })
    end

    interface.focus(false, false)
    releaseFrame()
end

RegisterCommand('adjudicator', function()
    if opening then
        return
    end

    opening = true
    local menu = lib.callback.await('adjudicator:getMenu', false)
    opening = false

    if not menu then
        closeComposer(true)

        return lib.notify({
            description = 'Kamu tidak memiliki akses untuk ini.',
            type = 'error',
            duration = 5000
        })
    end

    if not ensureVisible() then
        return
    end

    composerOpen = true

    interface.send({
        action = 'openComposer',
        data = menu
    })

    interface.focus(true, true)
end, false)

interface.callback('close', function(_, cb)
    cb({})
    closeComposer()
end)

interface.callback('send', function(data, cb)
    if not composerOpen or type(data) ~= 'table' then
        return cb({ ok = false, error = 'Menu sudah ditutup.' })
    end

    local result = lib.callback.await('adjudicator:send', false, data.target, data.message)

    if type(result) ~= 'table' then
        return cb({ ok = false, error = 'Server tidak merespons.' })
    end

    if not result.ok then
        return cb({ ok = false, error = result.error or 'Pesan gagal dikirim.' })
    end

    cb({ ok = true })
    closeComposer()

    lib.notify({
        description = result.sent > 0 and ('Pesan terkirim ke %d penerima.'):format(result.sent) or 'Pesan terkirim, tapi tidak ada penerima yang online.',
        type = result.sent > 0 and 'success' or 'warning',
        duration = 5000
    })
end)

AddEventHandler('adjudicator:client:forceClose', function()
    closeComposer(true)
end)

RegisterNetEvent('adjudicator:show', function(payload)
    if type(payload) ~= 'table' or type(payload.message) ~= 'string' or type(payload.duration) ~= 'number' then
        return
    end

    if not ensureVisible() then
        return
    end

    messageUntil = GetGameTimer() + payload.duration

    interface.send({
        action = 'showMessage',
        data = payload
    })

    SetTimeout(payload.duration + MESSAGE_GRACE_MS, releaseFrame)
end)
