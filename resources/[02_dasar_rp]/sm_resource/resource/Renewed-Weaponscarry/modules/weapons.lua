local Items = localmodule 'data.items'
local Utils = localmodule 'modules.utils'
local Prophide = localmodule 'modules.prophide'

local Players = {}
local RENDER_DISTANCE = 10.0

SetFlashLightKeepOnWhileMoving(true)

---Removes the current player from the table and deletes the entities
---@param serverId number
local function removePlayer(serverId)
    local Player = Players[serverId]

    if Player and table.type(Player) ~= 'empty' then
        Utils.removeEntities(Player)
        Players[serverId] = nil
    end
end

RegisterNetEvent('onPlayerDropped', function(serverId)
    removePlayer(serverId)
end)

---Formats the players inventory to only have items that are in the config
---@param inventory table
---@param currentWeapon table | nil
---@return table
local function formatPlayerInventory(inventory, currentWeapon)
    local items = {}
    local amount = 0

    Utils.resetSlots()

    for _, itemData in pairs(inventory) do
        local name = itemData and itemData.name:lower()

        if currentWeapon and itemData and currentWeapon.name == itemData.name and lib.table.matches(itemData.metadata.components, currentWeapon.metadata.components) then
            currentWeapon = nil
        elseif name and Items[name] then
            local formatted = Utils.formatData(itemData, Items[name])

            if formatted then
                amount += 1
                items[amount] = formatted
            end
        end
    end

    if amount > 1 then
        table.sort(items, function(a, b)
            return a.serial < b.serial
        end)
    end

    return items
end

---Creates all the objects for the player
---@param pedHandle number
---@param addItems table
---@param currentTable table
---@param amount number
local function createAllObjects(pedHandle, addItems, currentTable, amount)
    for i = 1, #addItems do
        local item = addItems[i]
        local name = item.name:lower()

        if Items[name] then
            local object = Utils.getEntity(item)

            if object > 0 then
                Utils.AttachEntityToPlayer(item, object, pedHandle)
                SetEntityCompletelyDisableCollision(object, false, true)

                amount += 1
                currentTable[amount] = {
                    name = item.name,
                    entity = object,
                }
            end
        end
    end
end

---@param serverId number
---@param pedHandle number
---@param value table | nil
local function renderPlayer(serverId, pedHandle, value)
    local currentTable = Players[serverId] or {}
    local amount = #currentTable

    if amount > 0 then
        Utils.removeEntities(currentTable)
        table.wipe(currentTable)
        amount = 0
    end

    local skip = serverId ~= cache.serverId and Prophide.isEnabled()

    if not skip and value and table.type(value) ~= 'empty' then
        createAllObjects(pedHandle, value, currentTable, amount)
    end

    Players[serverId] = currentTable
end

AddStateBagChangeHandler('weapons_carry', nil, function(bagName, keyName, value, _, replicated)
    if replicated then
        return
    end

    local serverId, pedHandle = Utils.getEntityFromStateBag(bagName, keyName)

    if serverId and serverId ~= cache.serverId and pedHandle == cache.ped then
        return
    end

    if serverId and not value then
        return removePlayer(serverId)
    end

    if pedHandle ~= 0 and DoesEntityExist(pedHandle) then
        -- Distance check untuk player lain
        if serverId and serverId ~= cache.serverId then
            local dist = #(GetEntityCoords(cache.ped) - GetEntityCoords(pedHandle))

            if dist > RENDER_DISTANCE then
                return
            end
        end

        renderPlayer(serverId, pedHandle, value)
    end
end)

Prophide.onChange(function()
    local coords = GetEntityCoords(cache.ped)

    for _, playerId in ipairs(GetActivePlayers()) do
        local pedHandle = GetPlayerPed(playerId)
        local serverId = GetPlayerServerId(playerId)

        if pedHandle > 0 and DoesEntityExist(pedHandle) then
            if #(coords - GetEntityCoords(pedHandle)) <= RENDER_DISTANCE then
                renderPlayer(serverId, pedHandle, Player(serverId).state.weapons_carry)
            else
                removePlayer(serverId)
            end
        else
            removePlayer(serverId)
        end
    end
end)

local playerState = LocalPlayer.state

---Updates the weapons_carry state for the player
---@param inventory table
---@param currentWeapon table
local function updateState(inventory, currentWeapon)
    while playerState.weapons_carry == nil do
        Wait(0)
    end

    local items = formatPlayerInventory(inventory, currentWeapon)

    if not playerState.hide_props and not playerState.hide_itemattach and not lib.table.matches(items, playerState.weapons_carry or {}) then
        playerState:set('weapons_carry', items, true)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        for _, v in pairs(Players) do
            if v then
                Utils.removeEntities(v)
            end
        end
    end
end)

---Refreshes the props for the player
---@param items table
---@param weapon table | nil
local function refreshProps(items, weapon)
    if Players[cache.serverId] then
        Utils.removeEntities(Players[cache.serverId])
        table.wipe(Players[cache.serverId])

        local formattedItems = formatPlayerInventory(items, weapon)

        createAllObjects(cache.ped, formattedItems, Players[cache.serverId], 0)
    end
end

---Loops the current flashlight to keep it enabled while the player is not aiming
---@param serial string
local function flashLightLoop(serial)
    serial = serial or 'scratched'

    local flashState = playerState.flashState?[serial]

    if flashState then
        SetFlashLightEnabled(cache.ped, true)
    end

    while cache.weapon do
        local currentState = IsFlashLightOn(cache.ped)

        if currentState ~= flashState then
            flashState = currentState
        end

        Wait(100)
    end

    playerState.flashState = flashState and {
        [serial] = flashState
    }
end

return {
    updateWeapons = updateState,
    loopFlashlight = flashLightLoop,
    refreshProps = refreshProps,
}