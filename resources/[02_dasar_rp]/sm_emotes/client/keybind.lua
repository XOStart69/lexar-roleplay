local config = require 'config.client'
local keybind = config.keybind
local crouch = config.crouchSetting
local crawl = config.crawlSetting

local function addBind(name, label, key, onPres, onRelease)
    local data = {
        name = name,
        description = label,
        defaultKey = key,
        onPressed = onPres,
        onReleased = onRelease
    }
    return lib.addKeybind(data)
end

if keybind.cancelEmote ~= '' then
    addBind('cancelemote', 'Cancel Emote', keybind.cancelEmote, Emote.cancel)
end

if keybind.callPtfxEmote ~= '' then
    addBind('callPtfxEmote', 'Ptfx Emote', keybind.callPtfxEmote, function (data)
        if not (PState.isInAnimation and PState.ptfxPrompt) then
            return
        end

        local ptfxData = PState.ptfxPrompt
    
        if data.busy then return end
        if not ptfxData then return end
        
        data.busy = true
        PState:set('emote_ptfx', true, true)
        
        Wait(ptfxData.holdTime)

        if ptfxData.canHold then
            while IsControlPressed(0, 47) and PState.isInAnimation do
                Wait(100)
            end
        end

        data.busy = false
        PState:set('emote_ptfx', nil, true)
    end)
end

if keybind.pointing ~= '' then
    local pointing = addBind('pointing', 'Pointing', keybind.pointing, pointing.enable)
    lib.onCache('weapon', function(v) pointing:disable(v and true or false) end)
end

if keybind.handsup ~= '' then
    addBind('handsup', 'Hands up', keybind.handsup, handsup.onPress, handsup.onRelease)
end

if crouch.enable and crouch.key ~= '' then
    addBind('crouch', locale('register_crouch'), crouch.key, stance.crouch)
end

if crawl.enable and crawl.key ~= '' then
    addBind('crawl', locale('register_crawl'), crawl.key, stance.crawl)
end

if keybind.ragdoll ~= '' then
    addBind('ragdoll', 'Ragdoll', keybind.ragdoll, ragdoll.toggle)
end

addBind('openemote', 'Open emote menu', 'F3', function ()
    exports.sm_emotes:OpenEmoteMenu()
end)