
local currentFish

local function setupFishAnimation(config)
    local model = lib.requestModel(config.model)

    local coords = GetEntityCoords(cache.ped)
    currentFish = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    FreezeEntityPosition(currentFish, true)
    SetEntityCollision(currentFish, false, false)
    SetModelAsNoLongerNeeded(model)

    AttachEntityToEntity(currentFish, cache.ped, GetPedBoneIndex(cache.ped, config.boneIndex), config.offset.x, config.offset.y, config.offset.z, config.rotation.x, config.rotation.y, config.rotation.z, false, false, false, false, 2, true)
    lib.playAnim(cache.ped, config.animation.dict, config.animation.name, 2.0, 2.0, -1, config.animation.flag, 0, false, false, false)

    infoUI.show({
        id = 'fishing_prop:info',
        title = 'Fishing',
        icon = 'fa-solid fa-fish',
        description = 'Tekan [kbd]G[/kbd] untuk menyimpan ikan',
    })

    CreateThread(function ()
        while currentFish and DoesEntityExist(currentFish) do

            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Jump
            DisableControlAction(0, 23, true) -- Enter Vehicle

            DisableControlAction(0, 47, true) -- G

            if IsDisabledControlJustPressed(0, 47) then
                DeleteEntity(currentFish)
                currentFish = nil
                break
            end

            if not IsEntityPlayingAnim(cache.ped, config.animation.dict, config.animation.name, 3) then
                lib.playAnim(cache.ped, config.animation.dict, config.animation.name, 2.0, 2.0, -1, config.animation.flag, 0, false, false, false)
            end

            Wait(10)
        end

        infoUI.remove('fishing_prop:info')
        StopAnimTask(cache.ped, config.animation.dict, config.animation.name, 1.0)
    end)

end

local items = localmodule 'config.shared'

RegisterNetEvent('fishingprop:onUse', function (item)
    if source == '' then return end

    local config = items[item]
    if not config then return end

    if currentFish and DoesEntityExist(currentFish) then
        DeleteEntity(currentFish)
        currentFish = nil
        Wait(500)
    end

    setupFishAnimation(config)
end)

AddEventHandler('onResourceStop', function (resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if currentFish and DoesEntityExist(currentFish) then
        DeleteEntity(currentFish)
        currentFish = nil
    end
end)