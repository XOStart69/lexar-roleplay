local placement = {}

local placement_info = [[
Gunakan **[Up/Down Arrows]** untuk mengatur ketinggian
Gunakan **[Mouse Scroll]** untuk mengatur rotasi

Tekan **Enter** untuk konfirmasi
Tekan **Right Click** untuk membatalkan
]]

local placement_info_locked = [[
Gunakan **[Mouse Scroll]** untuk mengatur rotasi

Tekan **Enter** untuk konfirmasi
Tekan **Right Click** untuk membatalkan
]]

local placement_finish = [[
Force in %s
Tekan **Right Click** untuk membatalkan
]]

---Finish the emote placement
---@param location vector3
---@param heading number
---@param data table
---@param onPlayed? fun()
function placement.finish(location, heading, data, onPlayed)
    if DoesEntityExist(placement.ped) then DeleteEntity(placement.ped) end

    TaskGoToCoordAnyMeans(cache.ped, location.x, location.y, location.z, 1.0, 0, false, 786603, 0xbf800000)

    local coords = GetEntityCoords(cache.ped)
    local startTime = GetGameTimer()
    local timeout = 10000
    local lastUpdate = 0

    info.show({
        id = 'sm_emote:placement',
        title = 'Placement Info',
        description = placement_finish:format('10s')
    })

    while #(coords - location) > 1.5 do
        Wait(0)

        coords = GetEntityCoords(cache.ped)
        local elapsedTime = GetGameTimer() - startTime
        local remainingTime = math.ceil((timeout - elapsedTime) / 1000)

        if remainingTime ~= lastUpdate then
            lastUpdate = remainingTime
            info.show({
                id = 'sm_emote:placement',
                title = 'Placement Info',
                description = placement_finish:format(remainingTime .. 's')
            })
        end

        if elapsedTime >= timeout then
            ClearPedTasks(cache.ped)
            break
        end

        if IsControlJustPressed(0, 177) then
            lib.hideTextUI()
            ClearPedTasks(cache.ped)

            location = vec3(0)
            break
        end
    end

    info.remove('sm_emote:placement')

    if location ~= vec3(0) then
        SetEntityCoords(cache.ped, location.x, location.y, location.z, false, false, false, false)
        SetEntityHeading(cache.ped, heading)

        data.Advanced = {
            coords = location,
            heading = heading,
        }

        Emote.play(data)

        if onPlayed then
            onPlayed()
        end
    end
end

---@param emote string
---@param onPlayed? fun()
---@param lockHeight? boolean
function placement.start(emote, onPlayed, lockHeight)
    if placement.ped and DoesEntityExist(placement.ped) then return end

    placement.ped = ClonePed(cache.ped, false, false, true)

    local emote_data = utils.getEmote(emote)

    if not emote_data then
        DeleteEntity(placement.ped)

        return lib.notify({
            description = 'Emote tidak valid', type = 'error'
        })
    end

    FreezeEntityPosition(placement.ped, true)
    SetEntityAlpha(placement.ped, 0, false)

    local duration, movementFlag = nil, 0

    local dict, anim, AnimationOptions in emote_data
    local isValid = lib.requestAnimDict(dict)

    if not isValid then
        lib.notify({ description = 'Emote tidak valid', type = 'error' })
        DeleteEntity(placement.ped)
        return
    end

    local placementProps = {}

    if AnimationOptions then

        local Prop, EmoteDuration, Flag, onFootFlag, StartDelay in AnimationOptions

        if StartDelay then Wait(StartDelay) end

        if Flag or onFootFlag then
            movementFlag = Flag or onFootFlag or 0
        end

        if Prop then
            props.addLocal(placement.ped, emote)
        end

        duration = EmoteDuration
    end

    TaskPlayAnim(placement.ped, dict, anim, 2.0, 2.0, duration or -1, movementFlag, 0, false, false, false)
    RemoveAnimDict(dict)

    SetEntityCollision(placement.ped, false, false)
    SetEntityAlpha(placement.ped, 200, false)
    SetBlockingOfNonTemporaryEvents(placement.ped, true)

    local currentCoords = nil
    local heading = GetEntityHeading(cache.ped) + 90.0
    
    info.show({
        id = 'sm_emote:placement',
        title = 'Placement Info',
        description = lockHeight and placement_info_locked or placement_info
    })

    CreateThread(function()
        local offsetZ = 0.0
        local hit, _, endCoords

        CreateThread(function()
            while DoesEntityExist(placement.ped) do
                hit, _, endCoords = lib.raycast.cam(511, 15)
                Wait(5)
            end
        end)

        while DoesEntityExist(placement.ped) do
            Wait(0)

            DisableControlAction(0, 22, true)

            if hit then
                currentCoords = endCoords

                SetEntityCoords(placement.ped, currentCoords.x, currentCoords.y, currentCoords.z + offsetZ, false, false, false, false)
                SetEntityHeading(placement.ped, heading)
            end

            if IsDisabledControlJustPressed(0, 14) then
                heading += 5

                if heading > 360 then heading = 0.0 end
            elseif IsDisabledControlJustPressed(0, 15) then
                heading -= 5

                if heading < 0 then heading = 360.0 end
            elseif lockHeight then
                offsetZ = 0.0
            elseif IsDisabledControlPressed(0, 27) then
                offsetZ += 0.01

                if offsetZ > 1.0 then offsetZ = 1.0 end
            elseif IsDisabledControlPressed(0, 173) then
                offsetZ -= 0.01

                if offsetZ < -1.0 then offsetZ = -1.0 end
            end

            if IsControlJustPressed(0, 201) then
                local coords = GetEntityCoords(cache.ped)

                if not currentCoords then
                    lib.notify({ description = 'Arahkan ke permukaan dulu', type = 'error' })
                elseif #(coords - currentCoords) < 5.0 then
                    placement.finish(GetEntityCoords(placement.ped), GetEntityHeading(placement.ped), lib.table.deepclone(emote_data), onPlayed)
                else
                    lib.notify({ description = 'Terlalu jauh', type = 'error' })
                end
            elseif IsControlJustPressed(0, 177) then
                if DoesEntityExist(placement.ped) then DeleteEntity(placement.ped) end

                info.remove('sm_emote:placement')
            end
        end

        for i = 1, #placementProps do
            local entity = placementProps[i].entity
    
            if DoesEntityExist(entity) then
                DeleteEntity(entity)
            end
        end
    end)
end

_ENV.placement = placement