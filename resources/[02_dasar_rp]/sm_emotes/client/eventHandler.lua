RegisterNetEvent("sn_emote:client:syncEmote", function(sender, senderEmote, targetEmote)
    -- Server will send net id `65535` for events from the server
    if source ~= 65535 then return end
    
    local senderData = utils.getEmote(senderEmote)
    local targetData = utils.getEmote(targetEmote)

    if not (senderData and targetData) then return end

    local isValid = lib.requestAnimDict(targetData?.dict)

    if not isValid then
        return lib.notify({
            description = 'Emote tidak valid', type = 'error'
        })
    end

    Emote.cancel()
    Wait(300)

    local playerId = GetPlayerFromServerId(sender)
    local playerPed = GetPlayerPed(playerId)

    if cache.vehicle or IsPedInAnyVehicle(playerPed, true) then
        return lib.notify({ description = 'Tidak bisa melakukan emote di dalam kendaraan', type = 'error' })
    end

    if not targetData then
        lib.print.error("rpemotes:client:syncEmote : Emote not found")
        return
    end

    local options = targetData.AnimationOptions
    local options2 = senderData.AnimationOptions

    if options and options.Attachto and not options2?.Attachto then
        AttachEntityToEntity(cache.ped, playerPed,
            GetPedBoneIndex(playerPed, options.bone or -1),
            options.pos.x, options.pos.y, options.pos.z,
            options.rot.x, options.rot.y, options.rot.z,
            false, false, false, true, 1, true
        )
    end

    Emote.play(targetData)
    LocalPlayer.state:set('inSharedEmote', sender, true)
end)

RegisterNetEvent("sm_emote:client:syncEmoteSource", function(target, senderEmote)
    -- Server will send net id `65535` for events from the server
    if source ~= 65535 then return end
    
    local senderData = utils.getEmote(senderEmote)

    if not senderData then return end

    local isValid = lib.requestAnimDict(senderData.dict)

    if not isValid then
        return lib.notify({
            description = 'Emote tidak valid',
            type = 'error'
        })
    end

    Emote.cancel()
    Wait(300)

    local playerId = GetPlayerFromServerId(target)
    local playerPed = GetPlayerPed(playerId)

    if cache.vehicle or IsPedInAnyVehicle(playerPed, true) then
        return lib.notify({ description = 'Tidak bisa melakukan emote di dalam kendaraan', type = 'error' })
    end

    local options = senderData and senderData.AnimationOptions

    if options and options.Attachto then
        AttachEntityToEntity(
            cache.ped, playerPed, GetPedBoneIndex(playerPed, options.bone or -1),
            options.pos.x, options.pos.y, options.pos.z,
            options.rot.x, options.rot.y, options.rot.z,
            false, false, false, true, 1, true
        )
    end

    local coords = GetOffsetFromEntityInWorldCoords(
        playerPed,
        (options and options.SyncOffsetSide or 0) + 0.0,
        (options and options.SyncOffsetFront or 1) + 0.0,
        (options and options.SyncOffsetHeight or 0) + 0.0
    )

    local heading = GetEntityHeading(playerPed)
    SetEntityHeading(cache.ped, heading - (options and options.SyncOffsetHeading or 180) + 0.0)
    SetEntityCoordsNoOffset(cache.ped, coords.x, coords.y, coords.z, false, false, false)

    Emote.play(senderData)
    LocalPlayer.state:set('inSharedEmote', target, true)
end)

RegisterNetEvent('sm_emote:client:requestShared', function(sender, senderEmote)
    -- Server will send net id `65535` for events from the server
    if source ~= 65535 then return end
    if PState.naikSapi then return end

    local senderData = utils.getEmote(senderEmote)

    if not senderData then return end
    local targetEmote = senderData?.secondPlayersAnim and utils.getEmote(senderData?.secondPlayersAnim)
    if not targetEmote then return end

    PlaySoundFrontend(-1, 'NAV', 'HUD_AMMO_SHOP_SOUNDSET', false)
    
local desc = [[
Pemain (%s) mengajak anda untuk
melakukan emote (%s) bersama

Tekan **Y** untuk menerima
Tekan **N** untuk menolak
]]
    info.show({
        id = 'sm_emote:request',
        title = 'Emote request',
        description = desc:format(sender, targetEmote?.label)
    })

    while true do
        Wait(0)
        if IsControlJustPressed(0, 246) then
            TriggerServerEvent('sm_emote:server:confirmShared', sender, senderEmote)
            break
        elseif IsControlJustPressed(0, 306) then
            break
        end
    end

    info.remove('sm_emote:request')
end)

RegisterNetEvent('sm_emote:client:playEmoteCommand', function(emote, variant)
    -- Server will send net id `65535` for events from the server
    if source ~= 65535 then return end

    if emote == 'c' then
        ---@diagnostic disable-next-line: redundant-return-value
        return PState.isInAnimation and Emote.cancel() or false
    end

    Emote.playFromMenu(emote, variant)
end)

RegisterNetEvent('sm_emote:client:playWalkstyle', function(emote, variant)
    -- Server will send net id `65535` for events from the server
    if source ~= 65535 then return end

    walkstyle.set(emote, true)
end)
