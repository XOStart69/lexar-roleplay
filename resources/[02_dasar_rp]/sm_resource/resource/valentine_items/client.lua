local config = localmodule 'config.shared'
local itemModule = require 'modules.items.client'

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

---@param itemName string
---@param itemConfig table
---@return number|nil
local function createProp(itemName, itemConfig)
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
    
    local boneIndex = GetPedBoneIndex(cache.ped, itemConfig.bone)
    
    AttachEntityToEntity(
        prop, cache.ped, boneIndex,
        itemConfig.placement[1], itemConfig.placement[2], itemConfig.placement[3],
        itemConfig.placement[4], itemConfig.placement[5], itemConfig.placement[6],
        true, true, false, true, 0, true
    )
    
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
        id = 'valentine:' .. itemName,
        title = itemConfig.infoUI.title,
        description = itemConfig.infoUI.description
    })
end

---@param itemName string
local function hideInfoUI(itemName)
    infoUI.remove('valentine:' .. itemName)
end

---@param itemName string
local function activateValentineItem(itemName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end
    
    -- Create prop
    local prop = createProp(itemName, itemConfig)
    if not prop then return end
    
    activeProps[itemName] = prop
    
    -- Play animation
    playAnimation(itemName, itemConfig)
    
    -- Show UI
    showInfoUI(itemName)
end

---@param itemName string
local function deactivateValentineItem(itemName)
    removeProp(itemName)
    stopAnimation(itemName)
    hideInfoUI(itemName)
end

---@return number|nil targetId, number|nil distance
local function getNearestPlayer()
    local players = GetActivePlayers()
    local playerPed = cache.ped
    local playerCoords = GetEntityCoords(playerPed)
    local nearestId, nearestDist
    
    for _, player in ipairs(players) do
        if player ~= cache.playerId then
            local targetPed = GetPlayerPed(player)
            
            if DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local dist = #(playerCoords - targetCoords)
                
                if dist <= config.giveDistance then
                    if not nearestDist or dist < nearestDist then
                        nearestDist = dist
                        nearestId = GetPlayerServerId(player)
                    end
                end
            end
        end
    end
    
    return nearestId, nearestDist
end

---@param itemName string
local function giveToNearestPlayer(itemName)
    if isGiving then return end
    
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end
    
    local targetId, distance = getNearestPlayer()
    
    if not targetId then
        return lib.notify({
            description = config.messages.noPlayerNearby,
            type = 'error'
        })
    end
    
    isGiving = true
    
    TriggerServerEvent('valentine:requestGive', targetId, itemName)
    
    SetTimeout(1000, function()
        isGiving = false
    end)
end

-- Keybind untuk memberikan item
lib.addKeybind({
    name = 'valentine_give',
    description = 'Memberikan valentine item ke player terdekat',
    defaultKey = config.giveKeybind,
    onPressed = function()
        -- Check if player has any active valentine item
        for itemName, _ in pairs(activeProps) do
            giveToNearestPlayer(itemName)
            break
        end
    end
})

-- Keybind untuk cancel/deactivate item
lib.addKeybind({
    name = 'valentine_cancel',
    description = 'Cancel/deactivate valentine item',
    defaultKey = config.cancelKeybind,
    onPressed = function()
        -- Check if player has any active valentine item
        for itemName, _ in pairs(activeProps) do
            deactivateValentineItem(itemName)
            TriggerServerEvent('valentine:cancelItem', itemName)
            
            lib.notify({
                description = config.messages.itemCancelled,
                type = 'info'
            })
            break
        end
    end
})

-- Handle request dari player lain
RegisterNetEvent('valentine:receiveRequest', function(senderId, senderName, itemName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end
    
    -- Check if already has pending request
    if pendingRequests[senderId] then
        return
    end
    
    pendingRequests[senderId] = itemName
    
    local alert = lib.alertDialog({
        header = 'Valentine Gift',
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
        TriggerServerEvent('valentine:acceptGift', senderId, itemName)
    else
        TriggerServerEvent('valentine:rejectGift', senderId, itemName)
    end
end)

-- Handle gift accepted
RegisterNetEvent('valentine:giftAccepted', function(itemName, receiverName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end
    
    lib.notify({
        description = config.messages.requestAccepted:format(receiverName, itemConfig.label),
        type = 'success'
    })
    
    -- Deactivate item
    deactivateValentineItem(itemName)
end)

-- Handle gift rejected
RegisterNetEvent('valentine:giftRejected', function(itemName, receiverName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end
    
    lib.notify({
        description = config.messages.requestRejected:format(receiverName, itemConfig.label),
        type = 'error'
    })
end)

-- Handle received gift
RegisterNetEvent('valentine:receiveGift', function(itemName, senderName)
    local itemConfig = getItemConfig(itemName)
    if not itemConfig then return end
    
    lib.notify({
        description = config.messages.giftReceived:format(itemConfig.label, senderName),
        type = 'success'
    })
    
    -- Auto-activate item untuk penerima
    Wait(500) -- Small delay untuk smooth transition
    activateValentineItem(itemName)
end)

-- Handle notification
RegisterNetEvent('valentine:notify', function(message, msgType)
    lib.notify({
        description = message,
        type = msgType or 'info'
    })
end)

-- Callback untuk aktivasi item
lib.callback.register('valentine:activateItem', function(itemName)
    activateValentineItem(itemName)
    return true
end)

-- Callback untuk deaktivasi item
lib.callback.register('valentine:deactivateItem', function(itemName)
    deactivateValentineItem(itemName)
    return true
end)

-- Cleanup saat resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    
    for itemName, _ in pairs(activeProps) do
        deactivateValentineItem(itemName)
    end
end)