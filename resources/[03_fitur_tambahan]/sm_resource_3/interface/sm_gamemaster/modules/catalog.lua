local type = type
local joaat = joaat
local slower = string.lower

local MASK = 0xFFFFFFFF
local DATA_PATH = 'interface/sm_gamemaster/web/build/data/%s'

local catalog = {}

---@type table<integer, string>?
local pedNames = nil
---@type table<integer, string>?
local vehicleNames = nil
---@type { m: string, l: string }[]?
local addons = nil

---@param file string
---@return table
local function read(file)
    local raw = LoadResourceFile(cache.resource, DATA_PATH:format(file))

    if not raw then return {} end

    return json.decode(raw) or {}
end

local function loadPeds()
    if pedNames then return end

    pedNames = {}

    local list = read('peds.json')

    for i = 1, #list do
        local name = slower(list[i].m)

        pedNames[joaat(name) & MASK] = name
    end
end

local function loadVehicles()
    if vehicleNames then return end

    vehicleNames = {}

    local list = read('vehicles.json')

    for i = 1, #list do
        local name = list[i]

        vehicleNames[joaat(name) & MASK] = name
    end
end

---@return { m: string, l: string }[]
function catalog.addons()
    if addons then return addons end

    local result = lib.callback.await('sm_gamemaster:server:catalog', false)

    if type(result) ~= 'table' or not result.ok or type(result.vehicles) ~= 'table' then
        return {}
    end

    addons = result.vehicles

    loadVehicles()

    for i = 1, #addons do
        local name = addons[i].m

        vehicleNames[joaat(name) & MASK] = name
    end

    return addons
end

---@param hash integer
---@return string?
function catalog.pedName(hash)
    loadPeds()

    return pedNames[hash & MASK]
end

---@param hash integer
---@return string?
function catalog.vehicleName(hash)
    loadVehicles()

    return vehicleNames[hash & MASK]
end

return catalog
