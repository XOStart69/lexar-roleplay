local Config = localmodule 'config'
local isOpened = false

-- Register the frame unmounted: it holds no GPU surface until first opened.
-- openScoreboard calls show() to mount it; the iframe boots, fires 'ready',
-- and we push everything from there so we never race the React mount.
interface.init(false)

---@return table
local function buildData()
    local data = lib.callback.await('sm_scoreboard:getServerData', false)

    if data.groups then
        local groups = {}
        for index, group in ipairs(Config.groups) do
            groups[index] = {
                label = group.label,
                count = data.groups[index],
                icon = group.icon,
            }
        end
        data.groups = groups
    end

    if data.statusIndicators then
        local indicators = {}
        for index, indicator in ipairs(Config.statusIndicators) do
            indicators[index] = {
                label = indicator.label,
                icon = indicator.icon,
                state = data.statusIndicators[index],
            }
        end
        data.statusIndicators = indicators
    end

    if data.footer then
        data.footer.serverId = cache.serverId
    end

    return data
end

-- Fired by the app after it has mounted (and frame init completed). Because the
-- frame is created fresh on each open, this runs every open and is the safe
-- point to push config + data + make it visible.
interface.callback('ready', function(_, cb)
    cb(1)

    interface.send({ action = 'setConfig', data = Config.settings })
    interface.send({ action = 'setLocales', data = Config.locales })

    if not isOpened then return end

    interface.send({ action = 'setData', data = buildData() })

    interface.focus(true, true, true)
    SetCursorLocation(Config.settings.side == 'right' and 0.8 or 0.2, 0.5)

    interface.send({ action = 'setVisible', data = true })
end)

interface.callback('close', function(_, cb)
    cb(1)
    isOpened = false
end)

interface.callback('copyServerId', function(_, cb)
    cb(1)
    lib.setClipboard(tostring(cache.serverId))
end)

local function openScoreboard()
    if isOpened then
        isOpened = false
        interface.send({ action = 'setVisible', data = false })
        interface.focus(false, false)
        -- The originally-running open coroutine exits its loop and unmounts the
        -- frame at the end of this function; don't hide() here or we'd race it.
        return
    end

    isOpened = true

    -- Mount the iframe; data/visibility are pushed from the 'ready' callback
    -- once the freshly mounted app reports in.
    interface.show()

    while isOpened do
        HudWeaponWheelIgnoreSelection()
        DisablePlayerFiring(cache.playerId, true)
        DisableControlAction(0, 1, true) -- INPUT_LOOK_LR
        DisableControlAction(0, 2, true) -- INPUT_LOOK_UD
        DisableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE_ALTERNATE
        Wait(0)
    end

    while IsDisabledControlPressed(0, 200) do
        DisableControlAction(0, 200, true)
        Wait(0)
    end

    interface.focus(false, false)
    interface.hide() -- single close chokepoint: unmount and free the GPU surface
end

TriggerEvent('chat:addSuggestion', ('/%s'):format(Config.commandName), 'Opens the scoreboard UI')
RegisterCommand(Config.commandName, openScoreboard, false)

if Config.commandKey then
    RegisterKeyMapping(Config.commandName, 'Open scoreboard UI', 'keyboard', Config.commandKey)
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource and isOpened then
        interface.focus(false, false)
    end
end)
