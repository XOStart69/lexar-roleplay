local config = localmodule 'config.shared'

local activeProps = {}
local activeAnimations = {}
local pendingRequests = {}
local isGiving = false

---@param itemName string
---@return table|nil
local function getItemConfig(itemName)
    return config.items[itemName]
end

---@param model string|number
---@return boolean
local function loadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model

    if not IsModelValid(hash) then
        return false
    end

    if HasModelLoaded(hash) then
        return true
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 5000

    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end

    return HasModelLoaded(hash)
end

---@param dict string
---@return boolean
local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then
        return true
    end

    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000

    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end

    return HasAnimDictLoaded(dict)
end

---@param itemConfig table
---@return number|nil
local function createProp(itemConfig)
    if not loadModel(itemConfig.prop) then
        lib.print.error('Failed to load model:', itemConfig.prop)
        return
    end

    local coords = GetEntityCoords(cache.ped)
    local prop = CreateObject(
        joaat(itemConfig.prop),
        coords.x, coords.y, coords.z,
        true, true, false
    )

    if not DoesEntityExist(prop) then
        return
    end

    SetEntityCollision(prop, false, false)
    SetEntityCompletelyDisableCollision(prop, false, false)

    local boneValue = itemConfig.boneIndex and GetPedBoneIndex(cache.ped, itemConfig.boneIndex)
        or itemConfig.boneId

    AttachEntityToEntity(
        prop, cache.ped, boneValue,
        itemConfig.pos.x, itemConfig.pos.y, itemConfig.pos.z,
        itemConfig.rot.x, itemConfig.rot.y, itemConfig.rot.z,
        true, true, false, true, 1, true
    )

    SetModelAsNoLongerNeeded(joaat(itemConfig.prop))

    return prop
end

---@param itemName string
local function removeProp(itemName)
    if activeProps[itemName] then
        if DoesEntityExist(activeProps[itemName]) then
            DeleteEntity(activeProps[itemName])
        end
        activeProps[itemName] = nil
    end
end

---@param itemName string
---@param itemConfig table
local function playAnimation(itemName, itemConfig)
    if not loadAnimDict(itemConfig.animation.dict) then
        lib.print.error('Failed to load anim dict:', itemConfig.animation.dict)
        return
    end

    TaskPlayAnim(
        cache.ped,
        itemConfig.animation.dict,
        itemConfig.animation.anim,
        8.0, -8.0, -1,
        itemConfig.animation.flag,
        0, false, false, false
    )

    activeAnimations[itemName] = true
end

---@param itemName string
local function stopAnimation(itemName)
    if activeAnimations[itemName] then
        ClearPedTasks(cache.ped)
        activeAnimations[itemName] = nil
    end
end

---@param itemName string
local function showInfoUI(itemName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end

    infoUI.show({
        id = 'merdeka:' .. itemName,
        title = itemConfig.infoUI.title,
        description = itemConfig.infoUI.description
    })
end

---@param itemName string
local function hideInfoUI(itemName)
    infoUI.remove('merdeka:' .. itemName)
end

---@param itemName string
local function activateMerdekaItem(itemName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end

    local prop = createProp(itemConfig)
    if not prop then return end

    activeProps[itemName] = prop

    playAnimation(itemName, itemConfig)
    showInfoUI(itemName)
end

---@param itemName string
local function deactivateMerdekaItem(itemName)
    removeProp(itemName)
    stopAnimation(itemName)
    hideInfoUI(itemName)
end

---@return number|nil targetId
local function getNearestPlayer()
    local players = GetActivePlayers()
    local playerCoords = GetEntityCoords(cache.ped)
    local nearestId, nearestDist

    for _, player in ipairs(players) do
        if player ~= cache.playerId then
            local targetPed = GetPlayerPed(player)

            if DoesEntityExist(targetPed) then
                local dist = #(playerCoords - GetEntityCoords(targetPed))

                if dist <= config.giveDistance then
                    if not nearestDist or dist < nearestDist then
                        nearestDist = dist
                        nearestId = GetPlayerServerId(player)
                    end
                end
            end
        end
    end

    return nearestId
end

---@param itemName string
local function giveToNearestPlayer(itemName)
    if isGiving then return end

    if not getItemConfig(itemName) then return end

    local targetId = getNearestPlayer()

    if not targetId then
        return lib.notify({
            description = config.messages.noPlayerNearby,
            type = 'error'
        })
    end

    isGiving = true

    TriggerServerEvent('merdeka:requestGive', targetId, itemName)

    SetTimeout(1000, function()
        isGiving = false
    end)
end

lib.addKeybind({
    name = 'merdeka_give',
    description = 'Memberikan prop merdeka ke player terdekat',
    defaultKey = config.giveKeybind,
    onPressed = function()
        for itemName in pairs(activeProps) do
            giveToNearestPlayer(itemName)
            break
        end
    end
})

lib.addKeybind({
    name = 'merdeka_cancel',
    description = 'Cancel/simpan prop merdeka',
    defaultKey = config.cancelKeybind,
    onPressed = function()
        for itemName in pairs(activeProps) do
            deactivateMerdekaItem(itemName)
            TriggerServerEvent('merdeka:cancelItem', itemName)

            lib.notify({
                description = config.messages.itemCancelled,
                type = 'info'
            })
            break
        end
    end
})

RegisterNetEvent('merdeka:receiveRequest', function(senderId, senderName, itemName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end

    if pendingRequests[senderId] then
        return
    end

    pendingRequests[senderId] = itemName

    local alert = lib.alertDialog({
        header = 'Hadiah Merdeka',
        content = config.messages.requestReceived:format(senderName, itemConfig.label),
        centered = true,
        cancel = true,
        labels = {
            cancel = 'Tolak',
            confirm = 'Terima'
        }
    })

    pendingRequests[senderId] = nil

    if alert == 'confirm' then
        TriggerServerEvent('merdeka:acceptGift', senderId, itemName)
    else
        TriggerServerEvent('merdeka:rejectGift', senderId, itemName)
    end
end)

RegisterNetEvent('merdeka:giftAccepted', function(itemName, receiverName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end

    lib.notify({
        description = config.messages.requestAccepted:format(receiverName, itemConfig.label),
        type = 'success'
    })

    deactivateMerdekaItem(itemName)
end)

RegisterNetEvent('merdeka:giftRejected', function(itemName, receiverName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end

    lib.notify({
        description = config.messages.requestRejected:format(receiverName, itemConfig.label),
        type = 'error'
    })
end)

RegisterNetEvent('merdeka:receiveGift', function(itemName, senderName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end

    lib.notify({
        description = config.messages.giftReceived:format(itemConfig.label, senderName),
        type = 'success'
    })

    Wait(500)
    activateMerdekaItem(itemName)
end)

RegisterNetEvent('merdeka:notify', function(message, msgType)
    lib.notify({
        description = message,
        type = msgType or 'info'
    })
end)

lib.callback.register('merdeka:activateItem', function(itemName)
    activateMerdekaItem(itemName)
    return true
end)

lib.callback.register('merdeka:deactivateItem', function(itemName)
    deactivateMerdekaItem(itemName)
    return true
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for itemName in pairs(activeProps) do
        deactivateMerdekaItem(itemName)
    end
end)
