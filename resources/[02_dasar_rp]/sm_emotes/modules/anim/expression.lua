

local expression = {}

function expression.set(emote, save)
    local emote_data = require 'data.emotes'.shared[emote] ---@type CacheEmote

    if emote_data and emote_data.category == 'expressions' then
        SetFacialIdleAnimOverride(cache.ped, emote_data.anim, 0)

        if not save then return end
        kvp.update('expression', emote_data.anim)
    else
        ClearFacialIdleAnimOverride(cache.ped)
        kvp.delete('expression')
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        local mood = kvp.getString('expression')
    
        if not mood then return end
        expression.set(mood, false)
    end
end)

_ENV.expression = expression