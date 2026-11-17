local tabletOpen = false
local invoiceOpen = false
local selfServiceOpen = false

local point
local config = require 'config.shared'
local selfservice = config.self_service

local function updateNuiFocus()
    local focused = tabletOpen or invoiceOpen or selfServiceOpen
    SetNuiFocus(focused, focused)
end

local function setTabletVisible(visible)
    tabletOpen = visible == true
    updateNuiFocus()
    SendNUIMessage({
        action = 'hotel:management:setVisible',
        data = {
            visible = tabletOpen,
        },
    })
end

local function setSelfServiceVisible(visible)
    selfServiceOpen = visible == true
    updateNuiFocus()
    SendNUIMessage({
        action = 'hotel:selfservice:setVisible',
        data = {
            visible = selfServiceOpen,
        },
    })
end

local function closeInvoice(status)
    invoiceOpen = false
    updateNuiFocus()
    SendNUIMessage({
        action = 'hotel:invoice:closed',
        data = {
            status = status,
        },
    })
end

local function serverAwait(name, payload)
    return lib.callback.await(('rhd_motel:management:%s'):format(name), false, payload)
end

local function registerNui(name, handler)
    RegisterNUICallback(name, function(payload, cb)
        local ok, result = pcall(handler, payload or {})

        if not ok then
            lib.print.error(('[rhd_motel] management nui callback failed: %s - %s'):format(name, result))
            cb({})
            return
        end

        cb(result or {})
    end)
end

local function getInputPlayers()
    local coords = GetEntityCoords(cache.ped)
    local players = lib.getNearbyPlayers(coords, 5.0, true)

    local playerList = {}

    for i=1, #players do
        local player = players[i]
        local serverId = GetPlayerServerId(player.id)

        playerList[#playerList+1] = {
            value = serverId,
            label = 'Player ' .. serverId,
            name = Player(serverId).state.name
        }
    end

    return playerList
end

local function removePed()
    if not point or not point.entity then return end

    if DoesEntityExist(point.entity) then
        exports.ox_target:removeLocalEntity(point.entity)
        DeleteEntity(point.entity)
    end
    point.entity = nil
end

local function createPed()
    if not point or point.entity then return end
    if not pcall(lib.requestModel, selfservice.ped.model, 5000) then return end

    local coords = selfservice.ped.coords
    local ped = CreatePed(0, joaat(selfservice.ped.model), coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityProofs(ped, true, true, true, true, true, false, false, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    SetPedCanRagdoll(ped, false)

    point.entity = ped
    exports.ox_target:addLocalEntity(ped, {
        {
            label = 'Open motel self service',
            icon = 'fas fa-bell-concierge',
            distance = 1.5,
            onSelect = function()
                local selfServiceStatus = serverAwait('selfServiceStatus')

                if not selfServiceStatus then
                    lib.notify({
                        title = 'Motel Self-Service',
                        description = 'The self-service kiosk is currently unavailable. Please contact the hotel staff for assistance.',
                        type = 'error',
                    })
                    return
                end

                setSelfServiceVisible(true)
            end,
        },
    })
    SetModelAsNoLongerNeeded(joaat(selfservice.ped.model))
end

local function applyState(state)
    SendNUIMessage({
        action = 'hotel:management:sync',
        data = { selfService = state },
    })
end

point = lib.points.new(selfservice.ped.coords.xyz, 25.0)

function point:onEnter()
    createPed()
end

function point:onExit()
    removePed()
end

exports.ox_target:addSphereZone({
    coords = vector3(-824.1004, -698.6276, 28.1564),
    radius = 0.6,
    options = {
        {
            label = 'Hotel Menu',
            icon = 'fas fa-hotel',
            distance = 1.5,
            groups = config.motelJob,
            onSelect = function ()
                setTabletVisible(true)
            end
        }
    }
})

registerNui('exit', function()
    setTabletVisible(false)
    setSelfServiceVisible(false)
    if invoiceOpen then
        closeInvoice('dismissed')
    end
    return true
end)

registerNui('hotel:management:bootstrap', function()
    return serverAwait('bootstrap')
end)

registerNui('hotel:management:getTargetPlayers', function()
    return getInputPlayers()
end)

registerNui('hotel:management:getLogs', function(payload)
    return serverAwait('getLogs', payload)
end)

registerNui('hotel:management:sendInvoice', function(payload)
    return serverAwait('sendInvoice', payload)
end)

registerNui('hotel:management:addOccupant', function(payload)
    return serverAwait('addOccupant', payload)
end)

registerNui('hotel:management:removeOccupant', function(payload)
    return serverAwait('removeOccupant', payload)
end)

registerNui('hotel:management:setRoomPrice', function(payload)
    return serverAwait('setRoomPrice', payload)
end)

registerNui('hotel:management:setFloorPrice', function(payload)
    return serverAwait('setFloorPrice', payload)
end)

registerNui('hotel:management:forceCheckout', function(payload)
    return serverAwait('forceCheckout', payload)
end)

registerNui('hotel:management:extendStay', function(payload)
    return serverAwait('extendStay', payload)
end)

registerNui('hotel:management:rentSelfService', function(payload)
    return serverAwait('rentSelfService', payload)
end)

registerNui('hotel:management:setSelfServicePaused', function(payload)
    return serverAwait('setSelfServicePaused', payload)
end)

registerNui('hotel:selfservice:getData', function()
    return lib.callback.await('rhd_motel:selfservice:getData', false)
end)

registerNui('hotel:selfservice:close', function()
    setSelfServiceVisible(false)
    return true
end)

registerNui('hotel:selfservice:sendInvoice', function(payload)
    return lib.callback.await('rhd_motel:selfservice:sendInvoice', false, payload)
end)

registerNui('hotel:invoice:pay', function(payload)
    return lib.callback.await('rhd_motel:invoice:pay', false, payload)
end)

registerNui('hotel:invoice:decline', function(payload)
    return lib.callback.await('rhd_motel:invoice:decline', false, payload)
end)

RegisterNetEvent('rhd_motel:management:openTablet', function()
    if source == '' then return end
    setTabletVisible(true)
end)

RegisterNetEvent('rhd_motel:management:sync', function(payload)
    if source == '' then return end
    if not tabletOpen then
        return
    end

    SendNUIMessage({
        action = 'hotel:management:sync',
        data = payload,
    })
end)

RegisterNetEvent('rhd_motel:invoice:open', function(payload)
    if source == '' then return end
    invoiceOpen = true
    updateNuiFocus()
    SendNUIMessage({
        action = 'hotel:invoice:open',
        data = payload,
    })
end)

RegisterNetEvent('rhd_motel:invoice:closed', function(payload)
    if source == '' then return end
    closeInvoice(payload and payload.status)
end)

RegisterNetEvent('rhd_motel:selfservice:stateChanged', function(payload)
    if source == '' or not tabletOpen then return end
    SendNUIMessage({
        action = 'hotel:management:sync',
        data = { selfService = payload },
    })
end)

RegisterNetEvent('rhd_motel:management:toggleTablet', function()
    if source == '' then return end
    setTabletVisible(not tabletOpen)
end)

RegisterNetEvent('rhd_motel:selfservice:stateChanged', function(state)
    if source == '' then return end
    applyState(state)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then removePed() end
end)
