local interiorData = {}

CreateThread(function()
    while true do
        
        if playerState.isLoggedIn then
            local change = false
            local interiorId = GetInteriorFromEntity(cache.ped)

            if interiorId ~= 0 then
                local roomHash = GetRoomKeyFromEntity(cache.ped)
                local roomId = GetInteriorRoomIndexByHash(interiorId, roomHash)

                local x, y, z = GetInteriorPosition(interiorId)
                local roomName = roomId ~= -1 and GetInteriorRoomName(interiorId, roomId) or 'unknown'

                if interiorData.id ~= interiorId then
                    interiorData.id = interiorId
                    interiorData.coords = vector3(x, y, z)

                    interiorData.roomId = roomId
                    interiorData.roomName = roomName

                    change = true
                elseif interiorData.roomName ~= roomName then
                    interiorData.roomId = roomId
                    interiorData.roomName = roomName
                    change = true
                end
            else
                if interiorData.id then
                    interiorData = {}
                    change = true
                end
            end

            if change then
                local args
                if interiorData.id then
                    args = {
                        interiorData.coords.x,
                        interiorData.id,
                        interiorData.coords.y,
                        interiorData.roomName,
                        interiorData.coords.z
                    }
                end
                TriggerServerEvent('rhd_bucketArea:ocitr', args)
            end
        end

        Wait(1000) -- Check every second
    end
end)