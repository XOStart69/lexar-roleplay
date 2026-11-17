lib.callback.register('sm_emote:invitePlayer', function(sender)

    PlaySoundFrontend(-1, 'NAV', 'HUD_AMMO_SHOP_SOUNDSET', false)

    local desc = [[
Pemain (%s) mengajak anda untuk
bergabung dengan group emote nya.

Tekan **Y** untuk menerima
Tekan **N** untuk menolak

sisa waktu %s detik
]]

    local terima = false
    local maxTime = 5
    local start = GetGameTimer()

    while true do
        Wait(0)

        local timer = GetGameTimer() - start
        local second = math.floor(timer / 1000)

        local remaining = maxTime - second
        if remaining < 0 then remaining = 0 end

        info.show({
            id = 'sm_emote:requestGroup',
            title = 'Group request',
            description = desc:format(sender, remaining)
        })

        if remaining <= 0 then
            break
        end

        -- Y
        if IsControlJustPressed(0, 246) then
            terima = true
            break
        end

        -- N
        if IsControlJustPressed(0, 306) then
            break
        end
    end

    info.remove('sm_emote:requestGroup')

    return terima
end)

RegisterNetEvent('sm_emote:playGroupEmote', function(_, command, texture)
    -- Server will send net id `65535` for events from the server
    if source ~= 65535 then return end

    if not command then return end
    Emote.playFromMenu(command, texture)
end)

RegisterNetEvent('sm_emote:updateGroup', function(data)
    -- Server will send net id `65535` for events from the server
    if source ~= 65535 then return end

    SendNUIMessage({
        action = 'updateGroups',
        data = { members = data}
    })
end)