local Config = require "config.config"

local ipairs, pairs = ipairs, pairs
local GetGameTimer = GetGameTimer
local ceil = math.ceil

local Cooldowns = {}
local CooldownExpires = {}

for name, data in pairs(Config.Commands) do
    if data.cooldown and data.cooldown > 0 then
        Cooldowns[name] = data.cooldown * 1000
    end
end

---@param command string
---@return boolean
local function CheckCooldown(command)
    local duration = Cooldowns[command]
    if not duration then return true end

    local now = GetGameTimer()
    local expires = CooldownExpires[command]

    if expires and now < expires then
        lib.notify({
            title = 'Chat',
            description = ('Tunggu %d detik lagi untuk memakai /%s.'):format(ceil((expires - now) / 1000), command),
            type = 'error'
        })
        return false
    end

    CooldownExpires[command] = now + duration
    return true
end

local function BuildText(args)
    local text = ""
    for _, v in ipairs(args) do
        text = text .. " " .. v
    end
    return text
end

local function RegisterSimpleCommand(category, useMask)
    local command = Config.Commands[category].name

    RegisterCommand(command, function(source, args)
        local text = BuildText(args)
        if text:len() == 0 then return end
        if not CheckCooldown(command) then return end

        TriggerServerEvent('sm_chatheme:server:sendMessage', {
            category = category,
            message = text,
            isImage = false,
            mask = useMask and CheckMask() or false,
        })
    end, false)
end

RegisterSimpleCommand('311', false)
RegisterSimpleCommand('me', true)
RegisterSimpleCommand('do', true)
RegisterSimpleCommand('ooc', true)
RegisterSimpleCommand('oocl', true)
RegisterSimpleCommand('joba', false)
RegisterSimpleCommand('jobc', false)
RegisterSimpleCommand('iklan', false)
RegisterSimpleCommand('berita', false)

RegisterCommand(Config.Commands['dice'].name, function()
    lib.requestAnimDict("anim@mp_player_intcelebrationmale@wank")
    lib.playAnim(cache.ped, "anim@mp_player_intcelebrationmale@wank", "wank", 8.0, 1.0, -1, 49, 0, 0, 0, 0)
    Citizen.Wait(1500)
    ClearPedTasks(cache.ped)

    TriggerServerEvent('sm_chatheme:server:sendMessage', {
        category = "dice",
        message = "",
        isImage = false,
        mask = CheckMask(),
    })
end, false)

RegisterCommand(Config.Commands['rps'].name, function()
    lib.requestAnimDict("anim@mp_player_intcelebrationmale@wank")
    lib.playAnim(cache.ped, "anim@mp_player_intcelebrationmale@wank", "wank", 8.0, 1.0, -1, 49, 0, 0, 0, 0)
    Citizen.Wait(1500)
    ClearPedTasks(cache.ped)

    TriggerServerEvent('sm_chatheme:server:sendMessage', {
        category = "rps",
        message = "",
        isImage = false,
        mask = CheckMask(),
    })
end, false)

RegisterCommand('charinfo', function()
    TriggerServerEvent('sm_chatheme:server:sendMessage', {
        category = "charinfo",
        isImage = false,
        mask = false,
    })
end, false)

RegisterCommand(Config.Commands['clear'].name, function()
    SendVueMessage("CLEAR_CHAT", {})
end, false)

RegisterCommand(Config.Commands['clearallchat'].name, function()
    TriggerServerEvent('sm_chatheme:server:clearAllChat')
end, false)

RegisterNetEvent('sm_chatheme:client:clearAllChat', function()
    SendVueMessage("CLEAR_CHAT", {})
end)

local suggestions = {
    { cmd = '311',          params = {{ name = "text" }} },
    { cmd = 'clearallchat', params = {} },
    { cmd = 'iklan',        params = {{ name = "text" }} },
    { cmd = 'berita',       params = {{ name = "text" }} },
    { cmd = 'joba',         params = {{ name = "text" }} },
    { cmd = 'jobc',         params = {{ name = "text" }} },
    { cmd = 'me',           params = {{ name = "text" }} },
    { cmd = 'do',           params = {{ name = "text" }} },
    { cmd = 'ooc',          params = {{ name = "text" }} },
    { cmd = 'oocl',         params = {{ name = "text" }} },
    { cmd = 'adminchat',    params = {{ name = "text" }} },
    { cmd = 'dice',         params = {} },
    { cmd = 'rps',          params = {} },
    { cmd = 'charinfo',     params = {} },
    { cmd = 'clear',        params = {} },
}

for _, s in ipairs(suggestions) do
    local cmdConfig = Config.Commands[s.cmd]
    if cmdConfig then
        TriggerEvent('sm_chatheme:client:selfCommandSuggestion', cmdConfig.name, cmdConfig.description, s.params)
    end
end
