local pairs = pairs
local Wait = Wait
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local SetEntityAsMissionEntity = SetEntityAsMissionEntity

local GRANT_MS = 80000
local TIMEOUT_MS = 750

local control = {}

---@type table<integer, integer>
local granted = {}

---@param entity integer
function control.request(entity)
    if not NetworkHasControlOfEntity(entity) then
        NetworkRequestControlOfEntity(entity)
    end
end

---@param entities integer[]
function control.ensure(entities)
    local now = GetGameTimer()
    local netIds = {}
    local count = 0

    for i = 1, #entities do
        local entity = entities[i]

        if DoesEntityExist(entity) and NetworkGetEntityIsNetworked(entity) and not NetworkHasControlOfEntity(entity) then
            local untilAt = granted[entity]

            if not untilAt or untilAt <= now then
                count += 1
                netIds[count] = NetworkGetNetworkIdFromEntity(entity)
                granted[entity] = now + GRANT_MS
            end
        end
    end

    if count > 0 then
        lib.callback.await('sm_gamemaster:server:control', false, netIds)
    end

    local deadline = GetGameTimer() + TIMEOUT_MS
    local lastRequest = 0

    while true do
        local current = GetGameTimer()
        local pending = false
        local resend = current - lastRequest >= 100

        for i = 1, #entities do
            local entity = entities[i]

            if DoesEntityExist(entity) and not NetworkHasControlOfEntity(entity) then
                pending = true

                if resend then
                    NetworkRequestControlOfEntity(entity)
                end
            end
        end

        if resend then
            lastRequest = current
        end

        if not pending or current >= deadline then break end

        Wait(0)
    end

    for i = 1, #entities do
        local entity = entities[i]

        if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
            SetEntityAsMissionEntity(entity, true, false)
        end
    end
end

---@param entity integer
---@return boolean
function control.one(entity)
    control.ensure({ entity })

    return DoesEntityExist(entity) and NetworkHasControlOfEntity(entity)
end

function control.prune()
    for entity in pairs(granted) do
        if not DoesEntityExist(entity) then
            granted[entity] = nil
        end
    end
end

return control
