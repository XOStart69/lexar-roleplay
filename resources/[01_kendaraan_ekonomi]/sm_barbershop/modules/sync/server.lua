local EVENT = 'sm_barbershop:sync'

local Sync = { revision = 0 }

---@type table<string, BarberShopSync>
local entries = {}

---@type table<number, boolean>
local served = {}

local started = false

---@return integer
function Sync.nextRevision()
    Sync.revision += 1

    return Sync.revision
end

---@param a table?
---@param b table?
---@return boolean
local function same(a, b)
    if type(a) ~= 'table' or type(b) ~= 'table' then return a == b end

    for key, value in pairs(a) do
        if b[key] ~= value then return false end
    end

    for key in pairs(b) do
        if a[key] == nil then return false end
    end

    return true
end

---@param shopId string
---@return BarberShopSync
local function entryOf(shopId)
    local entry = entries[shopId]

    if not entry then
        entry = { id = shopId, revision = 0, chairs = {}, portables = {} }
        entries[shopId] = entry
    end

    return entry
end

---@param entry BarberShopSync
local function publish(entry)
    entry.revision = Sync.nextRevision()

    if started then
        lib.latent.client(EVENT, -1, { entry })
    end
end

---@return BarberShopSync[]
local function snapshot()
    local list = {}

    for _, entry in pairs(entries) do
        list[#list + 1] = entry
    end

    return list
end

---@param shopId string
---@param state BarberShopState
function Sync.setState(shopId, state)
    local entry = entryOf(shopId)

    if same(entry.state, state) then return end

    entry.state = state
    publish(entry)
end

---@param shopId string
---@param chairs table<string, BarberChairStatus>
function Sync.setChairs(shopId, chairs)
    local entry = entryOf(shopId)

    if same(entry.chairs, chairs) then return end

    entry.chairs = chairs
    publish(entry)
end

---@param shopId string
---@param portables BarberPortableSync[]
function Sync.setPortables(shopId, portables)
    local entry = entryOf(shopId)

    entry.portables = portables
    publish(entry)
end

---@param shopId string
---@param index number|string
---@return BarberChairStatus?
function Sync.chairStatus(shopId, index)
    local entry = entries[shopId]

    return entry and entry.chairs[tostring(index)] or nil
end

function Sync.start()
    started = true
    lib.latent.client(EVENT, -1, snapshot())
end

RegisterNetEvent('sm_barbershop:sync:request', function()
    local source = source

    if not started or served[source] then return end

    served[source] = true
    lib.latent.client(EVENT, source, snapshot())
end)

AddEventHandler('playerDropped', function()
    served[source] = nil
end)

return Sync
