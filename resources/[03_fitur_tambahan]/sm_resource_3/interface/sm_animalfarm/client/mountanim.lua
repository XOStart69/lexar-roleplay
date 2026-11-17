local config = localmodule 'config'

local Wait = Wait
local GetGameTimer = GetGameTimer
local DoesEntityExist = DoesEntityExist
local GetEntityHeading = GetEntityHeading
local GetEntityCoords = GetEntityCoords
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local GetEntityAnimCurrentTime = GetEntityAnimCurrentTime
local IsEntityPlayingAnim = IsEntityPlayingAnim
local HasAnimDictLoaded = HasAnimDictLoaded
local floor = math.floor

local farm = SmAnimalFarm
local MOUNT = config.ride.mount
local BONE = config.ride.bone
local END_PHASE = 0.97

---@type table<string, integer>
local liftIndexes = {}

---@return boolean
local function loadDict()
    if HasAnimDictLoaded(MOUNT.dict) then return true end

    RequestAnimDict(MOUNT.dict)

    local deadline = GetGameTimer() + 2000

    while not HasAnimDictLoaded(MOUNT.dict) do
        if GetGameTimer() > deadline then return false end

        Wait(0)
    end

    return true
end

---@param ped integer
---@param host integer
local function walkToSide(ped, host)
    local spot = GetOffsetFromEntityInWorldCoords(host, MOUNT.side[1], MOUNT.side[2], 0.0)
    local deadline = GetGameTimer() + MOUNT.walkTimeout

    TaskGoStraightToCoord(ped, spot.x, spot.y, spot.z, 1.0, MOUNT.walkTimeout, GetEntityHeading(host) + MOUNT.sideYaw, 0.2)

    while GetGameTimer() < deadline do
        if not DoesEntityExist(host) then return end

        local coords = GetEntityCoords(ped)
        local dx, dy = coords.x - spot.x, coords.y - spot.y

        if dx * dx + dy * dy < 0.09 then return end

        Wait(50)
    end
end

---@param key string
---@param ped integer
---@return integer
local function liftIndex(key, ped)
    local cached = liftIndexes[key]

    if cached then return cached end

    Wait(0)

    local index = floor((GetEntityHeightAboveGround(ped) - MOUNT.pedHeight) / MOUNT.liftStep + 0.5)

    if index < 0 then
        index = 0
    elseif index > MOUNT.liftMax then
        index = MOUNT.liftMax
    end

    liftIndexes[key] = index

    return index
end

---@param ped integer
---@param host integer
local function standBeside(ped, host)
    local spot = GetPedBoneCoords(ped, 0, 0.0, 0.0, 0.0)
    local heading = DoesEntityExist(host) and GetEntityHeading(host) + MOUNT.sideYaw or GetEntityHeading(ped)
    local found, groundZ = GetGroundZFor_3dCoord(spot.x, spot.y, spot.z + 1.0, false)

    DetachEntity(ped, true, false)
    ClearPedTasksImmediately(ped)
    SetEntityCoordsNoOffset(ped, spot.x, spot.y, found and groundZ + MOUNT.pedHeight or spot.z, false, false, false)
    SetEntityHeading(ped, heading)
end

---@param ped integer
---@param host integer
---@param offset number[]
---@param kind 'getIn'|'getOut'
---@param key string
---@param walk? boolean
---@return boolean finished
function farm.seatTransition(ped, host, offset, kind, key, walk)
    if not MOUNT.enabled then return false end
    if not DoesEntityExist(host) or not loadDict() then return false end

    local entering = kind == 'getIn'

    if walk then
        walkToSide(ped, host)
    end

    if not DoesEntityExist(host) then return false end

    AttachEntityToEntity(
        ped, host, GetPedBoneIndex(host, BONE),
        offset[1], offset[2], offset[3],
        offset[4], offset[5], offset[6],
        false, true, false, true, 2, true
    )

    local clip = (entering and 'mount_%d' or 'dismount_%d'):format(liftIndex(key, ped))
    local deadline = GetGameTimer() + (entering and MOUNT.mountMs or MOUNT.dismountMs) + 1500
    local started = false
    local finished = false

    TaskPlayAnim(ped, MOUNT.dict, clip, entering and 8.0 or 1000.0, 4.0, -1, 2, 0.0, false, false, false)

    while GetGameTimer() < deadline do
        if not DoesEntityExist(host) then break end

        if IsEntityPlayingAnim(ped, MOUNT.dict, clip, 3) then
            started = true

            if GetEntityAnimCurrentTime(ped, MOUNT.dict, clip) >= END_PHASE then
                finished = true
                break
            end
        elseif started then
            break
        end

        Wait(0)
    end

    if not entering then
        standBeside(ped, host)
    end

    return finished
end
