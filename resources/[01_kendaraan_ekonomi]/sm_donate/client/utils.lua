QBCore = exports['qb-core']:GetCoreObject()

uiOpen = false

function isPointInPolygon(point, polygon)
    if not polygon or not polygon.points or #polygon.points == 0 then return true end

    local x, y = point.x, point.y
    local inside = false
    local j = #polygon.points

    for i = 1, #polygon.points do
        local xi, yi = polygon.points[i].x, polygon.points[i].y
        local xj, yj = polygon.points[j].x, polygon.points[j].y
        local intersect = ((yi > y) ~= (yj > y))
            and (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
        if intersect then inside = not inside end
        j = i
    end

    if inside and polygon.thickness then
        local baseZ = polygon.points[1].z
        if point.z < baseZ - 20.0 or point.z > baseZ + polygon.thickness + 20.0 then
            inside = false
        end
    end

    return inside
end

local TABLET_DICT = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a'
local TABLET_ANIM = 'idle_a'
local TABLET_PROP = 'prop_cs_tablet'

local tabletProp = nil

function playTabletAnimation()
    local playerPed = PlayerPedId()

    if tabletProp and DoesEntityExist(tabletProp) then
        DeleteEntity(tabletProp)
        tabletProp = nil
    end

    RequestAnimDict(TABLET_DICT)
    while not HasAnimDictLoaded(TABLET_DICT) do Wait(0) end

    local propHash = GetHashKey(TABLET_PROP)
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do Wait(0) end

    local coords = GetEntityCoords(playerPed)
    tabletProp = CreateObject(propHash, coords.x, coords.y, coords.z, true, true, false)
    SetEntityAsMissionEntity(tabletProp, true, true)
    AttachEntityToEntity(tabletProp, playerPed, GetPedBoneIndex(playerPed, 28422), -0.05, 0.0, 0.0, 0.0, -90.0, 0.0, true, true, false, true, 1, true)

    TaskPlayAnim(playerPed, TABLET_DICT, TABLET_ANIM, 3.0, 3.0, -1, 49, 0, false, false, false)

    SetModelAsNoLongerNeeded(propHash)
end

function stopTabletAnimation()
    local playerPed = PlayerPedId()

    StopAnimTask(playerPed, TABLET_DICT, TABLET_ANIM, 1.0)

    if tabletProp then
        if DoesEntityExist(tabletProp) then
            DetachEntity(tabletProp, true, true)
            DeleteEntity(tabletProp)
        end
        tabletProp = nil
    end

    RemoveAnimDict(TABLET_DICT)
end

function closeDonateUI()
    uiOpen = false
    SetNuiFocus(false, false)
    stopTabletAnimation()
    SendNUIMessage({ action = 'forceClose' })
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    SetNuiFocus(false, false)

    local playerPed = PlayerPedId()
    StopAnimTask(playerPed, TABLET_DICT, TABLET_ANIM, 1.0)

    local tabletHash = GetHashKey(TABLET_PROP)
    for _, object in ipairs(GetGamePool('CObject')) do
        if GetEntityModel(object) == tabletHash and IsEntityAttachedToEntity(object, playerPed) then
            DetachEntity(object, true, true)
            DeleteEntity(object)
        end
    end
end)

RegisterNUICallback('closeMenu', function(_, cb)
    closeDonateUI()
    cb('ok')
end)
