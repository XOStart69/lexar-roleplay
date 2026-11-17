local BLIP_SPRITE <const> = 1
local BLIP_CATEGORY <const> = 7

local showBlips = false
local stamp = 0

---@class AdminPlayerBlip
---@field handle number
---@field name? string
---@field stamp number

---@type table<number, AdminPlayerBlip>
local blips = {}

---@type table<number, string>
local names = {}

local DoesBlipExist = DoesBlipExist
local RemoveBlip = RemoveBlip
local AddBlipForCoord = AddBlipForCoord
local SetBlipCoords = SetBlipCoords
local SetBlipSprite = SetBlipSprite
local SetBlipCategory = SetBlipCategory
local SetBlipColour = SetBlipColour
local SetBlipDisplay = SetBlipDisplay
local BeginTextCommandSetBlipName = BeginTextCommandSetBlipName
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local EndTextCommandSetBlipName = EndTextCommandSetBlipName
local pairs = pairs

---@param x number
---@param y number
---@return number handle
local function createBlip(x, y)
    local handle = AddBlipForCoord(x, y, 0.0)

    SetBlipSprite(handle, BLIP_SPRITE)
    SetBlipCategory(handle, BLIP_CATEGORY)
    SetBlipColour(handle, 0)
    SetBlipDisplay(handle, 6)

    return handle
end

---@param id number
local function dropBlip(id)
    local handle = blips[id].handle

    if DoesBlipExist(handle) then
        RemoveBlip(handle)
    end

    blips[id] = nil
end

local function clearBlips()
    for id in pairs(blips) do
        dropBlip(id)
    end

    for id in pairs(names) do
        names[id] = nil
    end
end

---@param id number
---@param x number
---@param y number
local function syncBlip(id, x, y)
    local entry = blips[id]

    if entry and DoesBlipExist(entry.handle) then
        SetBlipCoords(entry.handle, x, y, 0.0)
    else
        entry = { handle = createBlip(x, y), stamp = stamp }
        blips[id] = entry
    end

    local name = names[id] or ''

    if entry.name ~= name then
        entry.name = name
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(name)
        EndTextCommandSetBlipName(entry.handle)
    end

    entry.stamp = stamp
end

RegisterNetEvent('sm_admin:blips:update', function(coords, nameData)
    if not showBlips then return end

    if nameData then
        for id, name in pairs(nameData) do
            names[id] = name
        end
    end

    stamp = stamp + 1

    local selfId = cache.serverId

    for i = 1, #coords, 3 do
        local id = coords[i]

        if id ~= selfId then
            syncBlip(id, coords[i + 1] + 0.0, coords[i + 2] + 0.0)
        end
    end

    for id, entry in pairs(blips) do
        if entry.stamp ~= stamp then
            dropBlip(id)
            names[id] = nil
        end
    end
end)

return {
    toggle = function()
        showBlips = not showBlips

        if not showBlips then
            clearBlips()
        end

        TriggerServerEvent('sm_admin:blips:subscribe', showBlips)
        lib.notify({ description = showBlips and 'Player blip active' or 'Player blip non active' })
    end
}
