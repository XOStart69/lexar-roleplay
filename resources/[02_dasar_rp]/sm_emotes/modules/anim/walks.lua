local walkstyle = {}

function walkstyle.set(emote, save)
    local emote_data = require 'data.emotes'.shared[emote] ---@type CacheEmote

    if PState.healing_progress then
        if save then
            lib.notify({ description = 'Tidak bisa mengubah gaya jalan saat Anti Combat', type = 'error' })
        end

        return
    end

    if emote_data and emote_data.category == 'walks' and not PState.canEmote then
        lib.notify({ description = 'Tidak bisa mengubah gaya jalan saat ini', type = 'error' })
        return
    end

    if emote_data and emote_data.category == 'walks' then
        lib.requestAnimSet(emote_data.anim)
        SetPedMovementClipset(cache.ped, emote_data.anim, 0.2)
        PState.walkstyle = emote_data.anim

        if not save then return end
        kvp.update('walkstyle', emote_data.anim)
    else
        PState.walkstyle = nil
        ResetPedMovementClipset(cache.ped, 0.0)
        kvp.delete('walkstyle')
    end
end

function walkstyle.load()
    local walks = kvp.getString('walkstyle')

    if not walks then return end
    walkstyle.set(walks, false)
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        local walks = kvp.getString('walkstyle')

        if not walks then return end
        walkstyle.set(walks, false)
    end
end)

_ENV.walkstyle = walkstyle