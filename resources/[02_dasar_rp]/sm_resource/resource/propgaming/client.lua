local Config = localmodule 'config.shared'

local RENDER_DISTANCE = 25.0

local Players = {}

local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist

---@param serverId number
local function removeProps(serverId)
    local worn = Players[serverId]

    if not worn then return end

    for _, obj in pairs(worn) do
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
    end

    Players[serverId] = nil
end

---@param itemConfig table
---@param ped number
---@return number?
local function createProp(itemConfig, ped)
    local hash = joaat(itemConfig.model)

    if not lib.requestModel(hash, 5000) then return end

    if not DoesEntityExist(ped) then return end

    local coords = GetEntityCoords(ped)
    local obj = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)

    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(obj) then return end

    SetEntityCollision(obj, false, false)
    SetEntityCompletelyDisableCollision(obj, false, false)

    AttachEntityToEntity(
        obj, ped,
        GetPedBoneIndex(ped, itemConfig.bone),
        itemConfig.offset.x, itemConfig.offset.y, itemConfig.offset.z,
        itemConfig.rotation.x, itemConfig.rotation.y, itemConfig.rotation.z,
        true, true, false, true, itemConfig.rotationOrder or 1, true
    )

    return obj
end

---@param serverId number
---@return boolean
local function skipRender(serverId)
    return serverId ~= cache.serverId and LocalPlayer.state.prophide == true
end

---@param serverId number
---@param ped number
---@param items table?
local function renderPlayer(serverId, ped, items)
    removeProps(serverId)

    if not items then return end

    local hidden = skipRender(serverId)
    local worn

    for itemName in pairs(items) do
        local itemConfig = Config.Items[itemName]

        if itemConfig and (not hidden or itemConfig.ignoreHide) then
            local obj = createProp(itemConfig, ped)

            if obj then
                worn = worn or {}
                worn[itemName] = obj
            end
        end
    end

    Players[serverId] = worn
end

---@param ped number
---@return vector3
local function pedCoords(ped)
    local vehicle = GetVehiclePedIsIn(ped, false)

    return vehicle == 0 and GetEntityCoords(ped) or GetWorldPositionOfEntityBone(ped, 0)
end

---@param serverId number
---@return number ped 0 kalau ga ada atau kejauhan
local function getRenderablePed(serverId)
    local playerId = GetPlayerFromServerId(serverId)
    local ped = playerId ~= -1 and GetPlayerPed(playerId) or 0

    if ped <= 0 or not DoesEntityExist(ped) then return 0 end

    if serverId == cache.serverId then return ped end

    return #(pedCoords(cache.ped) - pedCoords(ped)) <= RENDER_DISTANCE and ped or 0
end

---@param serverId number
---@param items table?
local function sync(serverId, items)
    local ped = items and getRenderablePed(serverId) or 0

    if ped == 0 then
        return removeProps(serverId)
    end

    renderPlayer(serverId, ped, items)
end

---@param seen table<number, true>
local function removeUnseen(seen)
    local stale
    local amount = 0

    for serverId in pairs(Players) do
        if serverId ~= cache.serverId and not seen[serverId] then
            stale = stale or {}
            amount += 1
            stale[amount] = serverId
        end
    end

    for i = 1, amount do
        removeProps(stale[i])
    end
end

local function refreshAll()
    local seen = {}

    for _, playerId in ipairs(GetActivePlayers()) do
        local serverId = GetPlayerServerId(playerId)
        local items = Player(serverId).state.gaming_props

        seen[serverId] = true

        if items and not next(items) then
            items = nil
        end

        sync(serverId, items)
    end

    removeUnseen(seen)
end

AddStateBagChangeHandler('gaming_props', nil, function(bagName, _, value)
    local serverId = tonumber(bagName:gsub('player:', ''), 10)

    if not serverId then return end

    if value and not next(value) then
        value = nil
    end

    sync(serverId, value)
end)

AddStateBagChangeHandler('prophide', ('player:%s'):format(cache.serverId), refreshAll)

RegisterNetEvent('onPlayerDropped', function(serverId)
    removeProps(serverId)
end)

lib.onCache('ped', function()
    CreateThread(function()
        Wait(500)
        refreshAll()
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for serverId in pairs(Players) do
        removeProps(serverId)
    end
end)
