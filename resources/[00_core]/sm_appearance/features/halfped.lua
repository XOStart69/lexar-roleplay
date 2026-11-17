local ped = require "core.ped"
local Net = require "modules.net"
local events = require "modules.events"

local DECALS = 10
local EMPTY = {}
local UNKNOWN = { blocked = EMPTY, granted = EMPTY, disabledFace = EMPTY }

---@type { blocked: table<string, number[]>, granted: table<string, number[]>, disabledFace: table<string, number> }?
local state

local halfped = {}

---@param data table?
local function accept(data)
    data = data or EMPTY

    state = {
        blocked = data.blocked or EMPTY,
        granted = data.granted or EMPTY,
        disabledFace = data.disabledFace or EMPTY
    }
end

---@return { blocked: table<string, number[]>, granted: table<string, number[]>, disabledFace: table<string, number> }
local function fetch()
    if state then return state end

    Net.awaitPush(function() return state end)

    return state or UNKNOWN
end

---@return boolean
function halfped.ready()
    return state ~= nil
end

---@param gender string
---@return number?
function halfped.disabledFace(gender)
    return fetch().disabledFace[gender]
end

---@param gender string
---@return number[]
function halfped.blockedDecals(gender)
    return fetch().blocked[gender] or EMPTY
end

---@param gender string
---@param drawable number
---@return boolean
function halfped.allowed(gender, drawable)
    local list = fetch().granted[gender]

    for i = 1, list and #list or 0 do
        if list[i] == drawable then return true end
    end

    return false
end

---@param gender string
---@return number?
function halfped.grantedDecal(gender)
    local list = fetch().granted[gender]

    return list and list[1] or nil
end

---@param gender string
---@param drawable number
---@return boolean
function halfped.registered(gender, drawable)
    if halfped.allowed(gender, drawable) then return true end

    local blocked = fetch().blocked[gender] or EMPTY

    for i = 1, #blocked do
        if blocked[i] == drawable then return true end
    end

    return false
end

---@param components PedComponent[]
---@param gender string
---@return PedComponent[]
function halfped.strip(components, gender)
    local result = table.create(#components, 0)

    fetch()

    local known = halfped.ready()

    for i = 1, #components do
        local piece = components[i]

        if piece.component_id ~= DECALS or (known and not halfped.registered(gender, piece.drawable)) then
            result[#result + 1] = piece
        end
    end

    return result
end

---@param gender string
---@return boolean
function halfped.hasAnyAccess(gender)
    return halfped.grantedDecal(gender) ~= nil
end

---@param entity number
---@return boolean
function halfped.wearingGranted(entity)
    if not ped.isFreemode(entity) then return false end

    return halfped.allowed(ped.gender(entity), GetPedDrawableVariation(entity, DECALS))
end

RegisterNetEvent("rhd_appearance:halfped:data", function(data)
    if source == '' then return end

    accept(data)

    events.emit("rhd_appearance:halfped:applied")
end)

---@param entity number
---@param index number
local function setFace(entity, index)
    local blend = ped.getHeadBlend(entity)

    blend.shapeFirst = index
    blend.shapeMix = 0.0

    ped.setHeadBlend(entity, blend)
end

---@param entity number
---@return number
local function currentFace(entity)
    return ped.getHeadBlend(entity).shapeFirst
end

---@param entity number
function halfped.clear(entity)
    setFace(entity, 0)
    ped.setComponent(entity, { component_id = DECALS, drawable = 0, texture = 0 })
end

---@param entity number
---@return boolean changed
function halfped.refresh(entity)
    if not ped.isFreemode(entity) then return false end

    fetch()

    if not halfped.ready() then return false end

    local gender = ped.gender(entity)
    local disabled = halfped.disabledFace(gender)

    if not disabled or currentFace(entity) ~= disabled then return false end

    if halfped.allowed(gender, GetPedDrawableVariation(entity, DECALS)) then return false end

    halfped.clear(entity)

    return true
end

---@param entity number
---@param componentId number
---@return boolean changed
function halfped.sync(entity, componentId)
    if componentId ~= DECALS then return false end

    local gender = ped.gender(entity)
    local disabled = halfped.disabledFace(gender)

    if not disabled then return false end

    if halfped.allowed(gender, GetPedDrawableVariation(entity, DECALS)) then return false end

    if currentFace(entity) ~= disabled then return false end

    setFace(entity, 0)

    return true
end

return halfped
