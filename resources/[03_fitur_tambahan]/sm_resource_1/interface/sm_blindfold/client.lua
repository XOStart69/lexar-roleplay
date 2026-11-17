if not interface.init(false) then
    return
end

local Config = localmodule 'config'

local Item = Config.item
local TargetDistance = Config.targetDistance
local InstallDuration = Config.installDuration
local RemoveDuration = Config.removeDuration
local PropModel = Config.prop
local Bone = Config.bone
local Offset = Config.offset
local Rotation = Config.rotation

local Wait = Wait
local Player = Player
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local GetPlayerServerId = GetPlayerServerId

local pState = LocalPlayer.state
local bag = nil
local overlay = false
local generation = 0
local phoneCheck = nil

---@param entity number
---@return number?
local function serverIdFromPed(entity)
    local player = NetworkGetPlayerIndexFromPed(entity)
    if player == -1 then return end

    return GetPlayerServerId(player)
end

local function phoneRunning()
    return GetResourceState('lb-phone') == 'started'
end

local function closePhone()
    if phoneRunning() and exports['lb-phone']:IsOpen() then
        exports['lb-phone']:ToggleOpen(false)
    end
end

local function blindfoldPhoneCheck()
    return not pState.blindfolded
end

local function addPhoneCheck()
    return exports['lb-phone']:AddCheck('openPhone', blindfoldPhoneCheck)
end

local function registerPhoneCheck()
    CreateThread(function()
        for _ = 1, 30 do
            if phoneCheck then return end

            if phoneRunning() then
                local ok, id = pcall(addPhoneCheck)
                if ok then
                    phoneCheck = id
                    return
                end
            end

            Wait(1000)
        end
    end)
end

local function removeBag()
    if bag and DoesEntityExist(bag) then
        DeleteEntity(bag)
    end

    bag = nil
end

local function attachBag()
    if bag or not pcall(lib.requestModel, PropModel, 5000) then return end

    local ped = cache.ped
    local coords = GetEntityCoords(ped)

    bag = CreateObject(PropModel, coords.x, coords.y, coords.z, true, true, false)
    SetModelAsNoLongerNeeded(PropModel)

    if bag == 0 then
        bag = nil
        return
    end

    AttachEntityToEntity(bag, ped, GetPedBoneIndex(ped, Bone), Offset.x, Offset.y, Offset.z, Rotation.x, Rotation.y, Rotation.z, true, true, false, true, 1, true)
    TriggerTokenEvent('sm_blindfold:server:prop', ObjToNet(bag))
end

---@param state boolean
local function setOverlay(state)
    if overlay == state then return end

    overlay = state

    if state then
        interface.show()
    else
        interface.hide()
    end
end

AddStateBagChangeHandler('blindfolded', ('player:%s'):format(cache.serverId), function(_, _, value)
    generation += 1
    local current = generation

    if value then
        closePhone()
    end

    CreateThread(function()
        Wait(value and InstallDuration or RemoveDuration)
        if current ~= generation then return end

        if not value then
            removeBag()
            setOverlay(false)
            return
        end

        attachBag()

        if current ~= generation then
            removeBag()
            return
        end

        closePhone()
        setOverlay(true)
    end)
end)

RegisterNetEvent('sm_blindfold:client:act', function(label, duration)
    local ped = cache.ped

    lib.requestAnimDict('mini@repair', 1000)
    TaskPlayAnim(ped, 'mini@repair', 'fixing_a_ped', 8.0, -8.0, -1, 0, 0, false, false, false)

    lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = false,
        disable = { car = true, move = true, combat = true },
    })

    ClearPedTasks(ped)
    RemoveAnimDict('mini@repair')
end)

ox_target:addGlobalPlayer({
    {
        name = 'sm_blindfold:put',
        icon = 'fa-solid fa-eye-slash',
        label = 'Put Blindfold',
        distance = TargetDistance,
        canInteract = function(entity, distance)
            if distance > TargetDistance then return false end

            local serverId = serverIdFromPed(entity)
            if not serverId or Player(serverId).state.blindfolded then return false end

            return ox_inventory:Search('count', Item) > 0
        end,
        onSelect = function(data)
            local serverId = serverIdFromPed(data.entity)
            if serverId then
                TriggerTokenEvent('sm_blindfold:server:put', serverId)
            end
        end
    },
    {
        name = 'sm_blindfold:remove',
        icon = 'fa-solid fa-eye',
        label = 'Remove Blindfold',
        distance = TargetDistance,
        canInteract = function(entity, distance)
            if distance > TargetDistance then return false end

            local serverId = serverIdFromPed(entity)
            return serverId ~= nil and Player(serverId).state.blindfolded == true
        end,
        onSelect = function(data)
            local serverId = serverIdFromPed(data.entity)
            if serverId then
                TriggerTokenEvent('sm_blindfold:server:remove', serverId)
            end
        end
    }
})

registerPhoneCheck()

AddEventHandler('onClientResourceStart', function(resource)
    if resource == 'lb-phone' then
        registerPhoneCheck()
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == 'lb-phone' then
        phoneCheck = nil
        return
    end

    if resource ~= cache.resource then return end

    removeBag()

    if phoneCheck and phoneRunning() then
        exports['lb-phone']:RemoveCheck(phoneCheck)
    end
end)
