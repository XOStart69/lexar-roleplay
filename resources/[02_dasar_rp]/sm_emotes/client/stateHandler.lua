local cached = {}
PState = LocalPlayer.state

CreateThread(function()
    PState:set('canEmote', true, true)
    PState:set('currentEmote', nil, true)
    PState:set('isInAnimation', nil, false)
end)

local function request(asset)
    local ok, resp = pcall(lib.requestNamedPtfxAsset, asset)
    
    if not ok and resp then
        lib.print.warn(ok, resp)
    end

    return ok and resp
end


AddStateBagChangeHandler('emote_prop', nil, function(bagName, key, value, reserved, replicated)
    local player = GetPlayerFromStateBagName(bagName)

    if player == 0 then return end

    if replicated and player == PlayerId() then return end

    local ped = GetPlayerPed(player)
    local serverId = GetPlayerServerId(player)
    
    if not value then
        Wait(50)
        props.clear(serverId)
        return
    end

    local emote, variant = value.emote, value.variant
    
    if not DoesEntityExist(ped) then
        return
    end
    
    props.clear(serverId)
    
    props.add(ped, serverId, emote, variant)
end)

AddStateBagChangeHandler('emote_ptfx', '', function(bagName, key, value, _unused, replicated)
    local player = GetPlayerFromStateBagName(bagName)
    local serverId = GetPlayerServerId(player)

    if not cached.ptfx then
        cached.ptfx = {}
    end

    if (cached.ptfx[serverId] and value) or (not cached.ptfx[serverId] and not value) then
        return
    end

    local playerPed = GetPlayerPed(player)
    if not DoesEntityExist(playerPed) then return end
    
    local state = Player(serverId).state

    if state.ptfxData then
        if value then
            local asset, name, bone, color, offset, rotation, scale, prop in state.ptfxData 

            local boneIndex = bone and GetPedBoneIndex(playerPed, bone) or
                                GetEntityBoneIndexByName(name, "VFX")

            local entity = prop and props.get(serverId) or playerPed

            request(asset)
            UseParticleFxAsset(asset)

            cached.ptfx[serverId] = StartNetworkedParticleFxLoopedOnEntityBone(
                name, entity, offset.x, offset.y, offset.z,
                rotation.x, rotation.y, rotation.z, boneIndex,
                (scale or 1) + 0.0, false, false, false
            )

            if color then
                if color[1] and type(color[1]) == 'table' then
                    local randomIndex = math.random(1, #color)
                    color = color[randomIndex]
                end
                SetParticleFxLoopedAlpha(cached.ptfx[serverId], color.A)
                SetParticleFxLoopedColour(cached.ptfx[serverId], color.R / 255, color.G / 255, color.B / 255, false)
            end
            
            -- lib.print.info("Started PTFX: " .. cached.ptfx[serverId])
        else
            -- lib.print.info("Stopped PTFX: " .. cached.ptfx[serverId])
            StopParticleFxLooped(cached.ptfx[serverId], false)
            RemoveNamedPtfxAsset(state.ptfxData?.asset)
            cached.ptfx[serverId] = nil
        end
    end
end)

AddStateBagChangeHandler('inSharedEmote', nil, function(bagName, key, value, reserved, replicated)
    if replicated then return end

    local state = LocalPlayer.state
    local inSharedEmote = state.inSharedEmote

    if not inSharedEmote then return end

    local player = GetPlayerFromStateBagName(bagName)

    if player == 0 then return end

    local serverId = GetPlayerServerId(player)
    
    if not value and inSharedEmote == serverId then
        Emote.cancel()
    end
end)

AddStateBagChangeHandler('targetAnim', nil, function(bagName, key, value, reserved, replicated)
    if replicated or not value then return end

    local player = GetPlayerFromStateBagName(bagName)

    if player == 0 then return end

    local playerPed = GetPlayerPed(player)
    local freePosition = type(value) == 'table'
    local sourceId = freePosition and value.source or value

    if type(sourceId) ~= 'number' then return end

    local playerSource = GetPlayerFromServerId(sourceId)

    if not playerSource then
        return
    end

    local sourcePed = GetPlayerPed(playerSource)

    local emote = Player(sourceId).state.currentEmote
    if not emote then return end

    target_dance.sync(playerPed, sourcePed, emote, freePosition)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if PState.isInAnimation then
        PState:set('isInAnimation', false, false)
    end
    if PState.currentEmote then
        PState:set('currentEmote', nil, true)
    end
    if PState.emote_prop then
        PState:set('emote_prop', nil, true)
    end
    if PState.ptfxPrompt then
        PState:set('ptfxPrompt', nil, false)
    end
    if PState.emote_ptfx then
        PState:set('emote_ptfx', nil, true)
    end
    if PState.inSharedEmote then
        PState:set('inSharedEmote', nil, true)
    end

    ClearPedTasks(cache.ped)
end)