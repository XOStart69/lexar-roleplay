local Sync = {}

---@type table<string, BarberShopSync>
local entries = {}

---@type BarberChairEntry[]
local portables = {}

---@type fun(list: BarberChairEntry[])[]
local listeners = {}

---@type fun(shopId: string, state: BarberShopState)[]
local shopListeners = {}

---@param shopId string
---@return BarberShopState?
function Sync.shop(shopId)
    local entry = entries[shopId]

    return entry and entry.state
end

---@param shopId string
---@param index number|string
---@return BarberChairStatus?
function Sync.chair(shopId, index)
    local entry = entries[shopId]

    return entry and entry.chairs[tostring(index)] or nil
end

---@return BarberChairEntry[]
function Sync.portables()
    return portables
end

---@param listener fun(shopId: string, state: BarberShopState)
function Sync.onShop(listener)
    shopListeners[#shopListeners + 1] = listener

    for shopId, entry in pairs(entries) do
        if entry.state then listener(shopId, entry.state) end
    end
end

---@param listener fun(list: BarberChairEntry[])
function Sync.onPortables(listener)
    listeners[#listeners + 1] = listener
    listener(portables)
end

local function rebuildPortables()
    ---@type BarberChairEntry[]
    local list = {}

    for shopId, entry in pairs(entries) do
        local placed = entry.portables or {}

        for i = 1, #placed do
            local chair = placed[i]

            list[#list + 1] = { shop = shopId, index = chair.id, coords = chair.coords, portable = true, ownerId = chair.ownerId }
        end
    end

    portables = list

    for i = 1, #listeners do
        listeners[i](list)
    end
end

RegisterNetEvent('sm_barbershop:sync', function(list)
    if source == '' or type(list) ~= 'table' then return end

    for i = 1, #list do
        local entry = list[i]
        local current = entries[entry.id]

        if not current or entry.revision > current.revision then
            entries[entry.id] = entry

            if entry.state then
                for j = 1, #shopListeners do
                    shopListeners[j](entry.id, entry.state)
                end
            end
        end
    end

    rebuildPortables()
end)

TriggerServerEvent('sm_barbershop:sync:request')

return Sync
