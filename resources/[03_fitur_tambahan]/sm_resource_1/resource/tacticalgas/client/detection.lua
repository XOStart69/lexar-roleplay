local config = localmodule 'config.shared'

local grenades = config.grenades

local GetSelectedPedWeapon = GetSelectedPedWeapon
local GetGamePool = GetGamePool
local GetEntityModel = GetEntityModel
local GetEntityCoords = GetEntityCoords
local DoesEntityExist = DoesEntityExist
local IsEntityAttachedToAnyPed = IsEntityAttachedToAnyPed
local IsControlJustReleased = IsControlJustReleased
local GetGameTimer = GetGameTimer
local TriggerServerEvent = TriggerServerEvent
local CreateThread = CreateThread
local Wait = Wait

local ATTACK_CONTROL = 24
local SEARCH_RADIUS = 60.0
local SEARCH_RADIUS_SQ = SEARCH_RADIUS * SEARCH_RADIUS
local SEARCH_ATTEMPTS = 60
local SEARCH_INTERVAL = 50
local SEARCH_DELAY = 100
local TRACK_INTERVAL = 50
local TRACK_ATTEMPTS = 120
local SETTLE_DISTANCE_SQ = 0.08 * 0.08
local SETTLE_DURATION = 150
local CLAIM_TTL = 15000
local IDLE_WAIT = 500

local weaponToGrenade = {}
local propByKey = {}

for key, grenade in pairs(grenades) do
    weaponToGrenade[grenade.weapon] = key
    propByKey[key] = grenade.prop
    AddTextEntry(grenade.label.id, grenade.label.text)
end

CreateThread(function()
    for _, grenade in pairs(grenades) do
        SetWeaponDamageModifier(grenade.weapon, 0.0)
    end
end)

local claimed = {}
local existing = {}

---@param ax number
---@param ay number
---@param az number
---@param bx number
---@param by number
---@param bz number
---@return number
local function distanceSq(ax, ay, az, bx, by, bz)
    local dx, dy, dz = ax - bx, ay - by, az - bz

    return dx * dx + dy * dy + dz * dz
end

---@param object integer
---@return boolean
local function isClaimed(object)
    local claimedAt = claimed[object]

    if not claimedAt then return false end

    if GetGameTimer() - claimedAt > CLAIM_TTL then
        claimed[object] = nil

        return false
    end

    return true
end

---@param prop integer
local function snapshotExisting(prop)
    for object in pairs(existing) do
        existing[object] = nil
    end

    local pool = GetGamePool('CObject')

    for i = 1, #pool do
        local object = pool[i]

        if GetEntityModel(object) == prop and not IsEntityAttachedToAnyPed(object) then
            existing[object] = true
        end
    end
end

---@param prop integer
---@return integer? entity
local function findThrownProp(prop)
    for _ = 1, SEARCH_ATTEMPTS do
        Wait(SEARCH_INTERVAL)

        local playerCoords = GetEntityCoords(cache.ped)
        local px, py, pz = playerCoords.x, playerCoords.y, playerCoords.z
        local pool = GetGamePool('CObject')
        local closest, closestDistance

        for i = 1, #pool do
            local object = pool[i]

            if GetEntityModel(object) == prop and not existing[object] and not isClaimed(object)
                and not IsEntityAttachedToAnyPed(object) then
                local coords = GetEntityCoords(object)
                local distance = distanceSq(coords.x, coords.y, coords.z, px, py, pz)

                if distance < SEARCH_RADIUS_SQ and (not closestDistance or distance < closestDistance) then
                    closest, closestDistance = object, distance
                end
            end
        end

        if closest then
            claimed[closest] = GetGameTimer()

            return closest
        end
    end
end

---@param key string
local function trackThrow(key)
    local prop = propByKey[key]

    snapshotExisting(prop)

    Wait(SEARCH_DELAY)

    local entity = findThrownProp(prop)
    if not entity then return end

    local landed = GetEntityCoords(entity)
    local lx, ly, lz = landed.x, landed.y, landed.z
    local stillFor = 0

    for _ = 1, TRACK_ATTEMPTS do
        Wait(TRACK_INTERVAL)

        if not DoesEntityExist(entity) then break end

        local current = GetEntityCoords(entity)
        local cx, cy, cz = current.x, current.y, current.z

        if distanceSq(cx, cy, cz, lx, ly, lz) < SETTLE_DISTANCE_SQ then
            stillFor = stillFor + TRACK_INTERVAL
        else
            stillFor = 0
        end

        landed, lx, ly, lz = current, cx, cy, cz

        if stillFor >= SETTLE_DURATION then break end
    end

    TriggerServerEvent('tacticalgas:throw', key, landed)
end

CreateThread(function()
    local tracking = false

    while true do
        local key = weaponToGrenade[GetSelectedPedWeapon(cache.ped)]

        if key then
            if not tracking and IsControlJustReleased(0, ATTACK_CONTROL) then
                tracking = true

                CreateThread(function()
                    trackThrow(key)
                    tracking = false
                end)
            end

            Wait(0)
        else
            Wait(IDLE_WAIT)
        end
    end
end)
