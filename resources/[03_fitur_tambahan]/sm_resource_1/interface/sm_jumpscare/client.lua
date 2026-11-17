if not interface.init(false) then
    return
end

local Config = localmodule 'config'

local DisplayDuration = Config.displayDuration
local LoadTimeout = Config.loadTimeout
local SoundVolume = Config.soundVolume

local showing = false
local mounted = false
local ready = false
local pending = nil
local generation = 0

local function finish()
    if not showing then return end

    showing = false
    pending = nil

    SetTimeout(50, function()
        if showing or not mounted then return end

        mounted = false
        ready = false
        interface.hide()
    end)
end

---@param payload table
local function display(payload)
    if ready then
        interface.send({ action = 'show', data = payload })
        return
    end

    pending = payload

    if not mounted then
        mounted = true
        interface.show()
    end
end

RegisterNetEvent('jumpscare:show', function(sound, url)
    if showing or type(url) ~= 'string' then return end

    showing = true
    generation += 1

    local current = generation

    if type(sound) == 'string' then
        TriggerEvent('InteractSound_CL:PlayOnOne', sound, SoundVolume)
    end

    display({ url = url, duration = DisplayDuration, timeout = LoadTimeout })

    SetTimeout(DisplayDuration + LoadTimeout + 2000, function()
        if current == generation then finish() end
    end)
end)

interface.callback('ready', function(_, cb)
    ready = true

    if pending then
        interface.send({ action = 'show', data = pending })
        pending = nil
    end

    cb('ok')
end)

interface.callback('closed', function(_, cb)
    cb('ok')
    finish()
end)

RegisterCommand(Config.command, function()
    if not lib.callback.await('sm_jumpscare:canUse', false) then
        return lib.notify({ description = 'Kamu tidak memiliki akses ke command ini.', type = 'error' })
    end

    local input = lib.inputDialog('Kirim Jumpscare', {
        { type = 'number', label = 'ID Player Target', required = true, min = 1, max = 9999 },
        { type = 'select', label = 'Sound', required = true, options = Config.sounds, default = Config.sounds[1].value },
        { type = 'input', label = 'URL Gambar', required = true, placeholder = 'https://i.imgur.com/example.png' },
    })

    if not input then return end

    local result = lib.callback.await('sm_jumpscare:send', false, input[1], input[2], input[3])

    if result then
        lib.notify({ description = result.message, type = result.success and 'success' or 'error' })
    end
end, false)
