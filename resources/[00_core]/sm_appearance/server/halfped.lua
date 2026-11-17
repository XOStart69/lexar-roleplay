local storage = require "server.storage.halfped"
local validate = require "server.validate"
local cache = require "modules.cache"
local Net = require "modules.net"
local halfpedConfig = require "config.halfped"

local GENDERS = { male = true, female = true }
local EVENT = "rhd_appearance:halfped:data"

local peds = cache.new({ update = function() end, remove = storage.remove })
local grants = cache.new({ update = function() end, remove = storage.revoke })
local loaded = false

local halfped = {}

---@return boolean
function halfped.loaded()
    return loaded
end

---@param value any
---@return boolean
local function validName(value)
    return type(value) == "string" and #value > 0 and #value <= 50
end

---@param value any
---@return boolean
local function validExpiry(value)
    if value == nil then return true end

    return type(value) == "string" and value:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil
end

local function reload()
    peds:load(storage.all())
    grants:load(storage.allAccess())
    loaded = true
end

---@return HalfPed[]
function halfped.all()
    return peds:all()
end

---@return HalfPedAccess[]
function halfped.allAccess()
    return grants:all()
end

---@param identifier string?
function halfped.dropExpired(identifier)
    if not identifier then return end

    local today = os.date("%Y-%m-%d")
    local rows = grants:all()
    local expired = {}

    for i = 1, #rows do
        local row = rows[i]

        if type(row.expires) == "string" and row.expires < today and row.citizenid == identifier then
            expired[#expired + 1] = row.id
        end
    end

    for i = 1, #expired do
        grants:remove(expired[i])
    end
end

---@param identifier string?
function halfped.notifyOwner(identifier)
    if not identifier then return end

    local players = GetPlayers()

    for i = 1, #players do
        local target = tonumber(players[i])

        if target and Framework.GetIdentifier(target) == identifier then
            return halfped.publish(target)
        end
    end
end

---@param id number
---@return string? citizenid
function halfped.ownerOfAccess(id)
    local row = grants:find(id)

    return row and row.citizenid or nil
end

---@param identifier string?
---@param gender string
---@param drawable number
---@return boolean
function halfped.blockedFor(identifier, gender, drawable)
    local registered = peds:all()
    local listed = false

    for i = 1, #registered do
        local entry = registered[i]

        if entry.gender == gender and entry.drawable == drawable then
            listed = true
            break
        end
    end

    if not listed then return false end
    if not identifier then return true end

    local rows = grants:all()

    for i = 1, #rows do
        local row = rows[i]

        if row.citizenid == identifier and row.gender == gender and row.drawable == drawable then
            return false
        end
    end

    return true
end

---@param data any
---@return boolean
function halfped.validPed(data)
    return type(data) == "table"
        and validName(data.name)
        and GENDERS[data.gender] ~= nil
        and validate.number(data.drawable, 0, 4096)
end

---@param data any
---@return boolean
function halfped.validGrant(data)
    return type(data) == "table"
        and type(data.halfPedId) == "number"
        and validName(data.name)
        and validName(data.citizenid)
        and validExpiry(data.expires)
end

---@param data { name: string, gender: string, drawable: number }
---@return boolean
function halfped.register(data)
    peds:beforeInsert()

    local id = storage.register(data.name, data.gender, data.drawable)

    if not id then return false end

    peds:insert({ id = id, name = data.name, gender = data.gender, drawable = data.drawable })
    halfped.publishAll()

    return true
end

---@param id number
function halfped.remove(id)
    grants:forget(function(row) return row.halfPedId == id end)
    peds:remove(id)
    halfped.publishAll()
end

---@param data { halfPedId: number, name: string, citizenid: string, expires: string? }
---@return boolean
function halfped.grant(data)
    local owner = peds:find(data.halfPedId)

    if not owner then return false end

    grants:beforeInsert()

    local id = storage.grant(data.halfPedId, data.name, data.citizenid, data.expires)

    if not id then return false end

    grants:insert({
        id = id,
        halfPedId = data.halfPedId,
        name = data.name,
        citizenid = data.citizenid,
        expires = data.expires,
        gender = owner.gender,
        drawable = owner.drawable
    })

    halfped.notifyOwner(data.citizenid)

    return true
end

---@param id number
function halfped.revoke(id)
    local owner = halfped.ownerOfAccess(id)

    grants:remove(id)
    halfped.notifyOwner(owner)
end

---@param identifier string?
---@return table
local function payload(identifier)
    local blocked = { male = {}, female = {} }
    local granted = { male = {}, female = {} }
    local mine = {}

    local rows = grants:all()

    for i = 1, #rows do
        local row = rows[i]

        if row.citizenid == identifier and granted[row.gender] then
            local list = granted[row.gender]

            list[#list + 1] = row.drawable
            mine[row.gender .. row.drawable] = true
        end
    end

    local registered = peds:all()

    for i = 1, #registered do
        local entry = registered[i]
        local list = blocked[entry.gender]

        if list and not mine[entry.gender .. entry.drawable] then
            list[#list + 1] = entry.drawable
        end
    end

    return { blocked = blocked, granted = granted, disabledFace = halfpedConfig.disabledFace }
end

---@param source number
function halfped.publish(source)
    local identifier = Framework.GetIdentifier(source)

    if not identifier then return end

    halfped.dropExpired(identifier)
    Net.emitLatentClient(EVENT, source, payload(identifier))
end

function halfped.publishAll()
    local players = GetPlayers()

    for i = 1, #players do
        local target = tonumber(players[i])

        if target then halfped.publish(target) end
    end
end

CreateThread(reload)

return halfped
