local config = localmodule 'config.shared'

local itemByName = {}

for _, item in ipairs(config.items) do
    itemByName[item.name] = item
end

local RENDER_DISTANCE = 25.0

local Inventory = exports.ox_inventory:GetPlayerItems() or {}
local players = {}
local renderTokens = {}

local function loadModel(model)
    local hash = joaat(model)
    if not lib.requestModel(hash, 10000) then return nil end
    return hash
end

local function createProp(hash, ped)
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)

    SetEntityCollision(prop, false, false)

    return prop
end

local function attachProp(prop, ped, point)
    AttachEntityToEntity(
        prop, ped, GetPedBoneIndex(ped, point.bone),
        point.pos.x, point.pos.y, point.pos.z,
        point.rot.x, point.rot.y, point.rot.z,
        false, false, false, false, point.rotOrder, point.fixedRot
    )
end

local function removeProps(serverId)
    local worn = players[serverId]
    if not worn then return end

    for _, prop in pairs(worn) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end

    players[serverId] = nil
end

local function removeAll()
    for _, worn in pairs(players) do
        for _, prop in pairs(worn) do
            if DoesEntityExist(prop) then
                DeleteEntity(prop)
            end
        end
    end

    players = {}
    renderTokens = {}
end

---@param serverId number
---@param ped number
---@param item table
---@param token number penanda render, dibatalkan kalau ada render baru
local function wearProp(serverId, ped, item, token)
    local point = config.attachPoints[item.point]
    if not point then return end

    local hash = loadModel(item.model)
    if not hash then return end

    if renderTokens[serverId] ~= token or not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(hash)
        return
    end

    local prop = createProp(hash, ped)

    SetModelAsNoLongerNeeded(hash)

    if not DoesEntityExist(prop) then return end

    if renderTokens[serverId] ~= token then
        DeleteEntity(prop)
        return
    end

    attachProp(prop, ped, point)

    local worn = players[serverId]

    if not worn then
        worn = {}
        players[serverId] = worn
    end

    local previous = worn[item.point]

    if previous and previous ~= prop and DoesEntityExist(previous) then
        DeleteEntity(previous)
    end

    worn[item.point] = prop
end

local function findBagsInInventory()
    local found, slots = {}, {}

    for slot, data in pairs(Inventory) do
        local item = data and data.name and itemByName[data.name]

        if item and (not slots[item.point] or slot < slots[item.point]) then
            found[item.point] = item
            slots[item.point] = slot
        end
    end

    return found
end

local function propsHidden()
    local state = LocalPlayer.state
    return state.hide_props == true or state.hide_itemattach == true
end

local function syncProp()
    local bags = {}

    if not propsHidden() then
        for pointName, item in pairs(findBagsInInventory()) do
            bags[pointName] = item.name
        end
    end

    if lib.table.matches(LocalPlayer.state.trap_bags or {}, bags) then return end

    LocalPlayer.state:set('trap_bags', bags, true)
end

local function skipRender(serverId)
    return serverId ~= cache.serverId and LocalPlayer.state.prophide == true
end

local function renderPlayer(serverId, ped, bags)
    local token = (renderTokens[serverId] or 0) + 1
    renderTokens[serverId] = token

    removeProps(serverId)

    if not bags or skipRender(serverId) then return end

    for pointName, itemName in pairs(bags) do
        if renderTokens[serverId] ~= token then return end

        local item = itemByName[itemName]

        if item and item.point == pointName then
            wearProp(serverId, ped, item, token)
        end
    end
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

---@param seen table<number, true>
local function removeUnseen(seen)
    local stale
    local amount = 0

    for serverId in pairs(players) do
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

---@param serverId number
---@param bags table?
local function sync(serverId, bags)
    local ped = bags and next(bags) and getRenderablePed(serverId) or 0

    if ped == 0 then
        return removeProps(serverId)
    end

    renderPlayer(serverId, ped, bags)
end

AddEventHandler('ox_inventory:updateInventory', function(changes)
    if not changes then return end

    for slot, item in pairs(changes) do
        Inventory[slot] = item or nil
    end

    syncProp()
end)

RegisterNetEvent('ox_inventory:setPlayerInventory', function(_, inventory)
    Inventory = inventory or {}
    syncProp()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    Inventory = {}
    LocalPlayer.state:set('trap_bags', nil, true)
end)

AddStateBagChangeHandler('trap_bags', nil, function(bagName, _, value, _, replicated)
    if replicated then return end

    local serverId = tonumber(bagName:gsub('player:', ''), 10)
    if not serverId then return end

    sync(serverId, value)
end)

RegisterNetEvent('onPlayerDropped', function(serverId)
    removeProps(serverId)
end)

local function onHideStateChanged()
    syncProp()
end

AddStateBagChangeHandler('hide_props', ('player:%s'):format(cache.serverId), onHideStateChanged)
AddStateBagChangeHandler('hide_itemattach', ('player:%s'):format(cache.serverId), onHideStateChanged)

local function refreshAll()
    local seen = {}

    for _, playerId in ipairs(GetActivePlayers()) do
        local serverId = GetPlayerServerId(playerId)

        seen[serverId] = true

        sync(serverId, Player(serverId).state.trap_bags)
    end

    removeUnseen(seen)
end

AddStateBagChangeHandler('prophide', ('player:%s'):format(cache.serverId), refreshAll)

lib.onCache('ped', function()
    removeProps(cache.serverId)

    CreateThread(function()
        Wait(500)
        refreshAll()
    end)
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end

    CreateThread(function()
        Wait(500)
        Inventory = exports.ox_inventory:GetPlayerItems() or {}
        LocalPlayer.state:set('trap_bags', nil, true)
        syncProp()
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    removeAll()
end)
