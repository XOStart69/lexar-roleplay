local default = require 'data.default'

local appearance = exports.sm_appearance

local utils = {}

local sin, cos, rad = math.sin, math.cos, math.rad

local MODEL_TIMEOUT <const> = 30000
local PLAYER_TIMEOUT <const> = 300000
local ANIM_TIMEOUT <const> = 30000
local FADE_GRACE <const> = 1000
local WORLD_TIMEOUT <const> = 5000
local COLLISION_TIMEOUT <const> = 15000

---@param ms number
function utils.fadeOut(ms)
    if IsScreenFadedOut() then return end

    DoScreenFadeOut(ms)

    local deadline = GetGameTimer() + ms + FADE_GRACE

    while not IsScreenFadedOut() and GetGameTimer() < deadline do
        Wait(0)
    end
end

---@param model number|string
---@param timeout? number
---@return number?
function utils.loadModel(model, timeout)
    local ok, result = pcall(lib.requestModel, model, timeout or MODEL_TIMEOUT)

    if ok then return result end

    lib.print.warn(result)
end

---@param dict string
---@param timeout? number
---@return boolean
function utils.loadAnimDict(dict, timeout)
    local ok, result = pcall(lib.requestAnimDict, dict, timeout or ANIM_TIMEOUT)

    if not ok then
        lib.print.warn(result)
    end

    return ok
end

---@param ms number
function utils.fadeIn(ms)
    DoScreenFadeIn(ms)
end

---@param coords vector4
---@param offset vector3
---@return vector3
function utils.offsetToWorld(coords, offset)
    local angle = rad(coords.w)

    return vec3(
        coords.x + cos(angle) * offset.x - sin(angle) * offset.y,
        coords.y + sin(angle) * offset.x + cos(angle) * offset.y,
        coords.z + offset.z
    )
end

---@param ped number
---@param coords vector4
local function waitWorld(ped, coords)
    local timeout = GetGameTimer() + WORLD_TIMEOUT

    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        Wait(0)
    end

    if not HasCollisionLoadedAroundEntity(ped) then
        lib.print.warn(('lokasi: collision belum termuat setelah %d ms'):format(WORLD_TIMEOUT))
    end

    local interior = GetInteriorAtCoords(coords.x, coords.y, coords.z)

    if interior == 0 then return end

    timeout = GetGameTimer() + WORLD_TIMEOUT
    PinInteriorInMemory(interior)

    while not IsInteriorReady(interior) and GetGameTimer() < timeout do
        Wait(0)
    end
end

---@param ped number
local function waitCollision(ped)
    local ok = pcall(lib.waitFor, function()
        return HasCollisionLoadedAroundEntity(ped) or nil
    end, nil, COLLISION_TIMEOUT)

    if not ok then
        lib.print.warn(('collision belum termuat setelah %d ms'):format(COLLISION_TIMEOUT))
    end
end

---@param ped number
---@param coords vector4
---@param waitScene? boolean
function utils.teleport(ped, coords, waitScene)
    FreezeEntityPosition(ped, true)
    SetFocusPosAndVel(coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.w)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    if waitScene then
        waitWorld(ped, coords)
    else
        waitCollision(ped)
    end

    ClearFocus()
end

---@param raw string|false|nil
---@return table?
function utils.decodeSkin(raw)
    if type(raw) ~= 'string' then return end

    local ok, skin = pcall(json.decode, raw)
    if not ok or type(skin) ~= 'table' or not skin.model then return end

    return skin
end

---@param gender 'male'|'female'
---@return table
function utils.defaultAppearance(gender)
    return default.appearance[gender == 'female' and 2 or 1]
end

---@param ped number
---@param skin table
function utils.applyPed(ped, skin)
    local ok, result = pcall(function()
        appearance:applyAppearance(ped, skin)
    end)

    if not ok then
        lib.print.warn(('gagal menerapkan appearance: %s'):format(result))
    end
end

---@param skin table
---@param gender? 'male'|'female'
---@return number ped
function utils.applyPlayer(skin, gender)
    local model = utils.loadModel(skin.model, PLAYER_TIMEOUT)

    if not model and gender then
        skin = utils.defaultAppearance(gender)
        model = utils.loadModel(skin.model, PLAYER_TIMEOUT)
    end

    if not model then return PlayerPedId() end

    SetPlayerModel(cache.playerId, model)
    SetModelAsNoLongerNeeded(model)

    local ped = PlayerPedId()

    SetPedDefaultComponentVariation(ped)
    utils.applyPed(ped, skin)

    return ped
end

---@param model number|string
---@param coords vector4
---@param timeout? number
---@return number?
function utils.createPed(model, coords, timeout)
    local hash = utils.loadModel(model, timeout)
    if not hash then return end

    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z, coords.w, false, false)

    SetModelAsNoLongerNeeded(hash)

    if ped == 0 or not DoesEntityExist(ped) then return end

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDefaultComponentVariation(ped)

    return ped
end

---@param model number|string
---@param coords vector3|vector4
---@param timeout? number
---@return number?
function utils.createObject(model, coords, timeout)
    local hash = utils.loadModel(model, timeout)
    if not hash then return end

    local object = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)

    SetModelAsNoLongerNeeded(hash)

    if object == 0 or not DoesEntityExist(object) then return end

    SetEntityCollision(object, false, false)

    return object
end

---@param entities number[]
function utils.deleteAll(entities)
    for i = #entities, 1, -1 do
        local entity = entities[i]

        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end

        entities[i] = nil
    end
end

return utils
