local config = localmodule 'config'

interface.init(false)

local points = {}
local myBagId = nil
local outfitCache = nil
local originalLook = nil
local nuiOpen = false
local nextChangeAt = 0
local frameToken = 0

local function openFrame()
    frameToken += 1
    interface.show()
end

local function closeFrame()
    frameToken += 1
    local token = frameToken

    SetTimeout(400, function()
        if token == frameToken then
            interface.hide()
        end
    end)
end

local function notify(msg, kind)
    lib.notify({ description = msg, type = kind or 'inform', position = 'center-right' })
end

local function formatRemaining(ms)
    local totalSec = math.ceil(ms / 1000)
    local mins = math.floor(totalSec / 60)
    local secs = totalSec % 60
    if mins > 0 then
        return ('%d menit %d detik'):format(mins, secs)
    end
    return ('%d detik'):format(secs)
end

local function loadDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local deadline = GetGameTimer() + 3000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < deadline do
        Wait(10)
    end
    return HasAnimDictLoaded(dict)
end

local function playBagAnim()
    local ped = cache.ped
    local a = config.BagAnim
    if not loadDict(a.dict) then return end
    TaskPlayAnim(ped, a.dict, a.anim, 4.0, -4.0, config.DropAnimTime, a.flag, 0.0, false, false, false)
    Wait(config.DropAnimTime)
    ClearPedTasks(ped)
    RemoveAnimDict(a.dict)
end

local function bagTargetOptions(bagId)
    return {
        {
            name = 'sm_outfitbag_open',
            icon = 'fa-solid fa-shirt',
            label = config.Locale.open_label,
            distance = config.InteractDistance,
            onSelect = function() TriggerEvent('sm_outfitbag:client:openBag', bagId) end,
        },
        {
            name = 'sm_outfitbag_pickup',
            icon = 'fa-solid fa-hand',
            label = config.Locale.pickup_label,
            distance = config.InteractDistance,
            onSelect = function() TriggerEvent('sm_outfitbag:client:pickupBag', bagId) end,
        },
    }
end

local function spawnLocalProp(point)
    local model = config.BagProp
    if not lib.requestModel(model, 3000) then return end

    local c = point.coords
    local obj = CreateObject(model, c.x, c.y, c.z, false, false, false)
    SetEntityHeading(obj, point.heading or 0.0)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(model)

    point.object = obj

    if point.isOwner then
        ox_target:addLocalEntity(obj, bagTargetOptions(point.bagId))
    end
end

local function deleteLocalProp(point)
    if point.object and DoesEntityExist(point.object) then
        if point.isOwner then
            ox_target:removeLocalEntity(point.object, { 'sm_outfitbag_open', 'sm_outfitbag_pickup' })
        end
        DeleteObject(point.object)
    end
    point.object = nil
end

local function addBag(bagId, bag)
    if points[bagId] then return end

    points[bagId] = lib.points.new({
        coords = bag.coords,
        distance = config.SpawnRadius,
        bagId = bagId,
        heading = bag.heading,
        isOwner = bag.ownerSrc == GetPlayerServerId(PlayerId()),
        onEnter = spawnLocalProp,
        onExit = deleteLocalProp,
    })
end

local function removeBag(bagId)
    local point = points[bagId]
    if not point then return end
    deleteLocalProp(point)
    point:remove()
    points[bagId] = nil
end

RegisterNetEvent('sm_outfitbag:client:addBag', addBag)
RegisterNetEvent('sm_outfitbag:client:removeBag', function(bagId)
    if points[bagId] and points[bagId].isOwner then myBagId = nil end
    removeBag(bagId)
end)

RegisterNetEvent('sm_outfitbag:client:placeBag', function()
    if myBagId then
        notify(config.Locale.already_placed, 'error')
        return
    end

    if cache.vehicle then
        notify(config.Locale.in_vehicle, 'error')
        TriggerServerEvent('sm_outfitbag:server:cancelPlace')
        return
    end

    local ped = cache.ped
    local coords = GetEntityCoords(ped) + (GetEntityForwardVector(ped) * 0.6)
    local heading = GetEntityHeading(ped)

    playBagAnim()

    local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
    coords = vec3(coords.x, coords.y, found and groundZ or coords.z)

    myBagId = true
    TriggerServerEvent('sm_outfitbag:server:bagPlaced', coords, heading)
    notify(config.Locale.bag_placed, 'success')
end)

RegisterNetEvent('sm_outfitbag:client:pickupBag', function(bagId)
    local point = points[bagId]
    if nuiOpen or not point or not point.isOwner then return end

    playBagAnim()
    TriggerServerEvent('sm_outfitbag:server:bagPicked')
    notify(config.Locale.bag_picked, 'success')
end)

local function closeNui()
    if not nuiOpen then return end
    nuiOpen = false
    interface.focus(false, false)
    interface.send({ action = 'closeMenu' })
    closeFrame()
end

RegisterNetEvent('sm_outfitbag:client:openBag', function(bagId)
    local point = points[bagId]
    if nuiOpen or not point or not point.isOwner then return end

    local remaining = nextChangeAt - GetGameTimer()
    if remaining > 0 then
        notify(config.Locale.cooldown:format(formatRemaining(remaining)), 'error')
        return
    end

    local outfits = lib.callback.await('illenium-appearance:server:getOutfits', false)
    if not outfits or #outfits == 0 then
        notify(config.Locale.no_outfits, 'error')
        return
    end

    outfitCache = outfits
    originalLook = {
        components = illenium_appearance:getPedComponents(cache.ped),
        props = illenium_appearance:getPedProps(cache.ped),
    }
    nuiOpen = true
    openFrame()
    interface.focus(true, true)
    interface.send({
        action = 'openMenu',
        outfits = outfits,
        owner = {
            cid = QBPlayerData and QBPlayerData.citizenid or nil,
            name = QBPlayerData and QBPlayerData.charinfo and
                ('%s %s'):format(QBPlayerData.charinfo.firstname or '', QBPlayerData.charinfo.lastname or '') or nil,
        },
    })
end)

local function findOutfit(outfitId)
    if not outfitId or not outfitCache then return nil end
    for i = 1, #outfitCache do
        if tostring(outfitCache[i].id) == tostring(outfitId) then
            return outfitCache[i]
        end
    end
end

local function applyLook(components, props)
    local ped = cache.ped
    illenium_appearance:setPedComponents(ped, components)
    illenium_appearance:setPedProps(ped, props)
end

interface.callback('previewOutfit', function(data, cb)
    cb({})
    local outfit = findOutfit(data.outfitId)
    if outfit then applyLook(outfit.components, outfit.props) end
end)

interface.callback('cancelPreview', function(_, cb)
    closeNui()
    cb({})
    if originalLook then
        applyLook(originalLook.components, originalLook.props)
        originalLook = nil
    end
end)

interface.callback('confirmOutfit', function(data, cb)
    closeNui()
    cb({})

    local outfit = findOutfit(data.outfitId)
    if not outfit then
        if originalLook then applyLook(originalLook.components, originalLook.props) end
        originalLook = nil
        return
    end
    originalLook = nil

    local ped = cache.ped
    local anim = config.ChangeOutfit
    if loadDict(anim.dict) then
        TaskPlayAnim(ped, anim.dict, anim.anim, 3.0, 3.0, anim.duration, anim.flag, 0.0, false, false, false)
        Wait(anim.duration // 2)
    end

    applyLook(outfit.components, outfit.props)

    if HasAnimDictLoaded(anim.dict) then
        Wait(anim.duration - (anim.duration // 2))
        ClearPedTasks(ped)
        RemoveAnimDict(anim.dict)
    end

    TriggerServerEvent('illenium-appearance:server:saveAppearance', illenium_appearance:getPedAppearance(ped))
    nextChangeAt = GetGameTimer() + (config.ChangeCooldown * 60000)
    notify(config.Locale.outfit_changed, 'success')
end)

local function syncBags()
    local mySrc = GetPlayerServerId(PlayerId())
    local current = lib.callback.await('sm_outfitbag:server:syncBags', false)
    if not current then return end
    for bagId, bag in pairs(current) do
        addBag(bagId, bag)
        if bag.ownerSrc == mySrc then myBagId = true end
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', syncBags)

AddEventHandler('onResourceStop', function(res)
    if res ~= cache.resource then return end
    for bagId in pairs(points) do
        removeBag(bagId)
    end
    interface.focus(false, false)
end)

CreateThread(function()
    Wait(1000)
    if LocalPlayer.state.isLoggedIn ~= false then syncBags() end
end)
