local carryObject
local carrying = false
local carryThread
local actionBusy = false

local config = localmodule 'config'

local function showInstruction()
    infoUI.show({
        id = 'giftbox_instruction',
        title = 'Gift Box',
        description = [[
        [kbd]ESC[/kbd] Put back gift box
        [kbd]E[/kbd] Drop gift box
        [kbd]G[/kbd] Give gift box to nearest player
        ]]
    })
end

local function removeInstruction()
    infoUI.remove('giftbox_instruction')
end

local function playCarryAnim()
    local anim = config.PropsData.carry.animation
    lib.requestAnimDict(anim.dict)
    TaskPlayAnim(cache.ped, anim.dict, anim.clip or anim.name, 2.0, 2.0, -1, anim.flag or 51, 0, false, false, false)
    RemoveAnimDict(anim.dict)
end

local function deleteCarryObject()
    if carryObject and DoesEntityExist(carryObject) then
        DeleteEntity(carryObject)
    end

    carryObject = nil
end

local function createCarryObject()
    deleteCarryObject()

    local prop = config.PropsData.carry.props
    local model = joaat(prop.model)
    local offset = prop.position[1]
    local rotation = prop.position[2]

    lib.requestModel(model, 5000)
    carryObject = CreateObject(model, 0.0, 0.0, 0.0, true, true, false)
    AttachEntityToEntity(
        carryObject,
        cache.ped,
        GetPedBoneIndex(cache.ped, prop.bone),
        offset.x, offset.y, offset.z,
        rotation.x, rotation.y, rotation.z,
        true, true, false, true, 1, true
    )
    SetModelAsNoLongerNeeded(model)
end

local function getDropPosition()
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local target = coords + (forward * config.Drop.placeDistance)
    local found, groundZ = GetGroundZFor_3dCoord(target.x, target.y, target.z + 1.0, false)

    return {
        x = target.x,
        y = target.y,
        z = found and groundZ or target.z - 0.9,
    }, GetEntityHeading(ped)
end

local function getNearestPlayer(maxDistance)
    local myPed = cache.ped
    local myCoords = GetEntityCoords(myPed)
    local closestPlayer
    local closestDistance = maxDistance or 2.5

    local players = GetActivePlayers()
    for i = 1, #players do
        local player = players[i]
        if player ~= PlayerId() then
            local ped = GetPlayerPed(player)
            local distance = #(myCoords - GetEntityCoords(ped))

            if distance < closestDistance then
                closestDistance = distance
                closestPlayer = GetPlayerServerId(player)
            end
        end
    end

    return closestPlayer
end

local function stopCarry()
    carrying = false
    actionBusy = false
    removeInstruction()
    deleteCarryObject()
    ClearPedTasks(cache.ped)
    StopAnimTask(cache.ped, config.PropsData.carry.animation.dict, config.PropsData.carry.animation.clip, 3)
end

local function putBack()
    if actionBusy then return end
    actionBusy = true

    local success, message = lib.callback.await('rhd_giftbox:server:putBackCarry', false)

    if not success and message then
        lib.notify({ type = 'error', description = message })
    end

    actionBusy = false
end

local function dropCarry()
    if actionBusy then return end
    actionBusy = true

    local coords, heading = getDropPosition()
    local success, message = lib.callback.await('rhd_giftbox:server:dropCarry', false, coords, heading)

    if not success and message then
        lib.notify({ type = 'error', description = message })
    end

    actionBusy = false
end

local function giveCarry()
    if actionBusy then return end
    actionBusy = true

    local target = getNearestPlayer(2.5)
    if not target then
        lib.notify({ type = 'error', description = 'No player nearby' })
        actionBusy = false
        return
    end

    local confirm = lib.alertDialog({
        header = 'Give Gift Box',
        content = 'Give this gift box to the nearest player?',
        centered = true,
        cancel = true
    })

    if confirm ~= 'confirm' then
        actionBusy = false
        return
    end

    local success, message = lib.callback.await('rhd_giftbox:server:requestGiveCarry', false, target)
    lib.notify({
        type = success and 'success' or 'error',
        description = message or (success and 'Offer sent' or 'Failed to send offer')
    })

    actionBusy = false
end

local function disableInstructionControls()
    DisableControlAction(0, config.CarryControls.putBack, true)
    DisableControlAction(0, config.CarryControls.drop, true)
    DisableControlAction(0, config.CarryControls.give, true)
    DisableControlAction(2, config.CarryControls.putBack, true)
    DisableControlAction(2, config.CarryControls.drop, true)
    DisableControlAction(2, config.CarryControls.give, true)
end

local function isInstructionControlReleased(control)
    return IsDisabledControlJustReleased(0, control) or IsDisabledControlJustReleased(2, control)
end

local function startControlThread()
    if carryThread then return end

    carryThread = CreateThread(function()
        while carrying do
            disableInstructionControls()
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)

            if isInstructionControlReleased(config.CarryControls.putBack) then
                putBack()
            elseif isInstructionControlReleased(config.CarryControls.drop) then
                dropCarry()
            elseif isInstructionControlReleased(config.CarryControls.give) then
                giveCarry()
            end

            if not IsEntityPlayingAnim(cache.ped, config.PropsData.carry.animation.dict, config.PropsData.carry.animation.clip, 3) then
                playCarryAnim()
            end

            Wait(0)
        end

        stopCarry()
        carryThread = nil
    end)
end

RegisterNetEvent('rhd_giftbox:client:startCarry', function()
    if source == '' then return end

    carrying = true
    createCarryObject()
    playCarryAnim()
    showInstruction()
    startControlThread()
end)

RegisterNetEvent('rhd_giftbox:client:stopCarry', function()
    if source == '' then return end

    stopCarry()
end)

RegisterNetEvent('rhd_giftbox:client:confirmReceiveGift', function(token, giver, giverName)
    if source == '' then return end

    local result = lib.alertDialog({
        header = 'Receive Gift Box',
        content = ('%s wants to give you a gift box. Accept?'):format(giverName or ('Player %s'):format(giver)),
        centered = true,
        cancel = true
    })

    local success, message = lib.callback.await('rhd_giftbox:server:answerGiveCarry', false, token, result == 'confirm')
    if not success and message then
        lib.notify({ type = 'error', description = message })
    elseif result == 'confirm' then
        lib.notify({ type = 'success', description = 'You received a gift box.' })
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    stopCarry()
end)
