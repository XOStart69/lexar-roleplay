local prisonJobsBlips = {}
local prisonJobsData = {}
local prisonJobsInteract = {}
local activePrisonLocation = nil

local prisonJobsConfig = localmodule 'config.prison_jobs'

local function loadAnimDict(dict)
    return safecall.fun(lib.requestAnimDict, dict, 15000)
end

local function loadModel(model)
    return safecall.fun(lib.requestModel, model, 15000)
end

local function createJobBlip(jobType, location, index, coords, config)
    local blipKey = string.format('%s_%s_%d', jobType, location, index)
    
    if prisonJobsBlips[blipKey] then
        return
    end
    
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, config.blipSprite)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, config.blipScale)
    SetBlipColour(blip, config.blipColor)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(config.label)
    EndTextCommandSetBlipName(blip)
    
    prisonJobsBlips[blipKey] = blip
end

local function removeJobBlip(jobType, location, index)
    local blipKey = string.format('%s_%s_%d', jobType, location, index)
    
    if prisonJobsBlips[blipKey] then
        RemoveBlip(prisonJobsBlips[blipKey])
        prisonJobsBlips[blipKey] = nil
    end
end

local function handleMoppingJob(jobType, location, index, config)
    local ped = PlayerPedId()
    local animConfig = config.animation
    
    loadAnimDict(animConfig.dict)
    local propHash = loadModel(animConfig.prop)
    
    local propCoords = GetEntityCoords(ped)
    local prop = CreateObject(propHash, propCoords.x, propCoords.y, propCoords.z, true, true, true)
    local boneIndex = GetPedBoneIndex(ped, animConfig.propBone)
    
    AttachEntityToEntity(
        prop, ped, boneIndex,
        animConfig.propPlacement[1], animConfig.propPlacement[2], animConfig.propPlacement[3],
        animConfig.propPlacement[4], animConfig.propPlacement[5], animConfig.propPlacement[6],
        true, true, false, true, 1, true
    )
    
    TaskPlayAnim(ped, animConfig.dict, animConfig.clip, 8.0, -8.0, -1, animConfig.flag, 0, false, false, false)
    
    local success = lib.progressBar({
        duration = config.progressDuration,
        label = 'Mengepel lantai...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            combat = true,
            car = true
        }
    })
    
    StopAnimTask(ped, animConfig.dict, animConfig.clip, 1.0)
    if DoesEntityExist(prop) then
        DeleteEntity(prop)
    end
    
    return success
end

local function handleCookingJob(jobType, location, index, config)
    local ped = PlayerPedId()
    local animConfig = config.animation
    
    TaskStartScenarioInPlace(ped, animConfig.scenario, 0, true)
    
    local success = lib.progressBar({
        duration = config.progressDuration,
        label = 'Memasak...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            combat = true,
            car = true
        }
    })
    
    ClearPedTasks(ped)
    
    return success
end

local function handleDishwashingJob(jobType, location, index, config)
    local ped = PlayerPedId()
    local animConfig = config.animation

    loadAnimDict(animConfig.dict)

    local success = lib.progressBar({
        duration = config.progressDuration,
        label = 'Mencuci piring...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            combat = true,
            car = true
        },
        anim = {
            dict = animConfig.dict,
            clip = animConfig.clip,
            flag = animConfig.flag,
        }
    })

    StopAnimTask(ped, animConfig.dict, animConfig.clip, 1.0)

    return success
end

local function handleElectricianJob(jobType, location, index, config)
    local ped = PlayerPedId()
    local animConfig = config.animation
    
    loadAnimDict(animConfig.dict)
    
    local success = lib.progressBar({
        duration = config.progressDuration,
        label = 'Memperbaiki Kabel...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            combat = true,
            car = true
        },
        anim = {
            dict = animConfig.dict,
            clip = animConfig.clip,
            flag = animConfig.flag,
        }
    })
    
    StopAnimTask(ped, animConfig.dict, animConfig.clip, 1.0)
    
    return success
end

local function onJobSelect(jobType, location, index, config)
    if lib.progressActive() then return end
    
    local dataKey = string.format('%s_%s_%d', jobType, location, index)
    
    if prisonJobsData[dataKey] and prisonJobsData[dataKey].busy then
        lib.notify({
            description = 'Lokasi ini sedang tidak tersedia!',
            type = 'error'
        })
        return
    end
    
    local success = false
    
    if jobType == 'mopping' then
        success = handleMoppingJob(jobType, location, index, config)
    elseif jobType == 'cooking' then
        success = handleCookingJob(jobType, location, index, config)
    elseif jobType == 'dishwashing' then
        success = handleDishwashingJob(jobType, location, index, config)
    elseif jobType == 'electrician' then
        success = handleElectricianJob(jobType, location, index, config)
    end
    
    if success then
        lib.notify({
            description = config.label .. ' berhasil dikerjakan!',
            type = 'success'
        })
        
        TriggerTokenEvent('sm_prison:server:reduceTimeFromJob', jobType)
        
        if not prisonJobsData[dataKey] then
            prisonJobsData[dataKey] = {}
        end
        prisonJobsData[dataKey].busy = true
        
        removeJobBlip(jobType, location, index)
        
        SetTimeout(config.cooldown, function()
            if prisonJobsData[dataKey] then
                prisonJobsData[dataKey].busy = false
                -- Only restore the blip if the player is still jailed at this location.
                -- (interaction point is never removed, only gated by canInteract/busy)
                if activePrisonLocation == location and config.locations[location] and config.locations[location][index] then
                    createJobBlip(jobType, location, index, config.locations[location][index], config)
                end
            end
        end)
    end
end

local function createPrisonJobs(location)
    activePrisonLocation = location

    for jobType, config in pairs(prisonJobsConfig) do
        if config.enabled and config.locations and config.locations[location] then
            local locations = config.locations[location]
            
            if not prisonJobsInteract[jobType] then
                prisonJobsInteract[jobType] = {}
            end
            
            if not prisonJobsInteract[jobType][location] then
                prisonJobsInteract[jobType][location] = {}
            end
            
            for index, coords in ipairs(locations) do
                local dataKey = string.format('%s_%s_%d', jobType, location, index)
                
                if not prisonJobsData[dataKey] or not prisonJobsData[dataKey].busy then
                    createJobBlip(jobType, location, index, coords, config)
                end
                
                local capturedJobType = jobType
                local capturedLocation = location
                local capturedIndex = index
                local capturedConfig = config
                
                local interactId = exports.rhd_interact:addCoords({
                    coords = coords,
                    options = {
                        {
                            label = config.label,
                            icon = config.icon,
                            distance = config.interactionDistance,
                            onSelect = function(data)
                                onJobSelect(capturedJobType, capturedLocation, capturedIndex, capturedConfig)
                            end,
                            canInteract = function(entity, distance, coordsData, name)
                                local key = string.format('%s_%s_%d', capturedJobType, capturedLocation, capturedIndex)
                                return not prisonJobsData[key] or not prisonJobsData[key].busy
                            end
                        }
                    }
                })
                
                prisonJobsInteract[jobType][location][index] = interactId
            end
        end
    end
end

local function removePrisonJobs(location)
    if activePrisonLocation == location then
        activePrisonLocation = nil
    end

    for jobType, config in pairs(prisonJobsConfig) do
        if prisonJobsInteract[jobType] and prisonJobsInteract[jobType][location] then
            for index, interactId in pairs(prisonJobsInteract[jobType][location]) do
                if interactId then
                    exports.rhd_interact:removeCoords(interactId)
                end
                
                removeJobBlip(jobType, location, index)
            end
            
            prisonJobsInteract[jobType][location] = nil
        end
    end
    
    for key, _ in pairs(prisonJobsData) do
        if string.find(key, location) then
            prisonJobsData[key] = nil
        end
    end
end

return {
    createPrisonJobs = createPrisonJobs,
    removePrisonJobs = removePrisonJobs,
}
