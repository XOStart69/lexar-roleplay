local config = localmodule 'config'

local Wait = Wait
local DoesEntityExist = DoesEntityExist
local DoesRopeExist = DoesRopeExist
local DeleteRope = DeleteRope
local GetEntityCoords = GetEntityCoords
local GetPlayerFromServerId = GetPlayerFromServerId
local GetPlayerPed = GetPlayerPed
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetworkGetEntityFromNetworkId = NetworkGetEntityFromNetworkId
local GetGameTimer = GetGameTimer
local smatch = string.match
local tonumber, pairs, next = tonumber, pairs, next

local LEASH = config.lasso.leash
local RENDER = LEASH.renderDistance * LEASH.renderDistance
local FORGET_MS = 30000

---@class FarmLeash
---@field owner integer
---@field rope integer|nil
---@field animal integer
---@field hand integer
---@field missingSince integer|nil

---@type table<integer, FarmLeash>
local leashes = {}
local running = false

---@param entry FarmLeash
local function dropRope(entry)
    if entry.rope and DoesRopeExist(entry.rope) then
        DeleteRope(entry.rope)
    end

    entry.rope = nil

    if #GetAllRopes() == 0 then
        RopeUnloadTextures()
    end
end

---@param entry FarmLeash
---@param animal integer
---@param hand integer
local function makeRope(entry, animal, hand)
    if not RopeAreTexturesLoaded() then
        RopeLoadTextures()

        for _ = 1, 50 do
            if RopeAreTexturesLoaded() then break end

            Wait(20)
        end
    end

    local pos = GetEntityCoords(animal)
    local rope = AddRope(
        pos.x, pos.y, pos.z,
        0.0, 0.0, 0.0,
        LEASH.length, 4, LEASH.length,
        0.5, 0.5, false, false, false, 1.0, false
    )

    if not DoesRopeExist(rope) then return end

    AttachEntitiesToRope(
        rope, hand, animal,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        LEASH.length, false, false,
        LEASH.handBone, LEASH.animalBone
    )
    entry.rope = rope
    entry.animal = animal
    entry.hand = hand
end

local function watch()
    if running then return end

    running = true

    CreateThread(function()
        while next(leashes) do
            local me = GetEntityCoords(cache.ped)
            local now = GetGameTimer()

            for netId, entry in pairs(leashes) do
                local animal = NetworkDoesNetworkIdExist(netId) and NetworkGetEntityFromNetworkId(netId) or 0

                if animal == 0 then
                    entry.missingSince = entry.missingSince or now

                    if now - entry.missingSince > FORGET_MS then
                        dropRope(entry)
                        leashes[netId] = nil
                    end
                else
                    entry.missingSince = nil
                end

                local player = GetPlayerFromServerId(entry.owner)
                local hand = player ~= -1 and GetPlayerPed(player) or 0
                local visible = animal ~= 0 and hand ~= 0 and DoesEntityExist(animal) and DoesEntityExist(hand)

                if visible then
                    local pos = GetEntityCoords(animal)
                    local dx, dy = pos.x - me.x, pos.y - me.y

                    visible = dx * dx + dy * dy <= RENDER
                end

                if not visible then
                    dropRope(entry)
                elseif not entry.rope or entry.animal ~= animal or entry.hand ~= hand or not DoesRopeExist(entry.rope) then
                    dropRope(entry)
                    makeRope(entry, animal, hand)
                end
            end

            Wait(500)
        end

        running = false
    end)
end

AddStateBagChangeHandler('smFarmLeash', nil, function(bagName, _, value)
    local netId = tonumber(smatch(bagName, '^entity:(%d+)$'))

    if not netId then return end

    local entry = leashes[netId]

    if entry then
        dropRope(entry)
        leashes[netId] = nil
    end

    if type(value) ~= 'number' then return end

    leashes[netId] = { owner = value, animal = 0, hand = 0 }
    watch()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end

    for netId, entry in pairs(leashes) do
        dropRope(entry)
        leashes[netId] = nil
    end
end)
