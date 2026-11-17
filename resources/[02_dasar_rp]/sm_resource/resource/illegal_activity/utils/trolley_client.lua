local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist
local NetToObj = NetToObj
local DoesEntityExist = DoesEntityExist
local NetworkHasControlOfEntity = NetworkHasControlOfEntity
local NetworkRequestControlOfEntity = NetworkRequestControlOfEntity
local PlaceObjectOnGroundProperly = PlaceObjectOnGroundProperly
local FreezeEntityPosition = FreezeEntityPosition
local GetGameTimer = GetGameTimer
local Wait = Wait

local trolley = {}

---@param netId number
---@return number
local function waitForObject(netId)
    local timeout = GetGameTimer() + 5000

    while GetGameTimer() < timeout do
        if NetworkDoesNetworkIdExist(netId) then
            local entity = NetToObj(netId)
            if entity ~= 0 and DoesEntityExist(entity) then
                return entity
            end
        end
        Wait(100)
    end

    return 0
end

---@param netIds number[]
---@return nil
function trolley.placeOnGround(netIds)
    if type(netIds) ~= 'table' then return end

    for i = 1, #netIds do
        local entity = waitForObject(netIds[i])

        if entity ~= 0 then
            local timeout = GetGameTimer() + 1500

            while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
                NetworkRequestControlOfEntity(entity)
                Wait(50)
            end

            if NetworkHasControlOfEntity(entity) then
                FreezeEntityPosition(entity, false)
                PlaceObjectOnGroundProperly(entity)
                FreezeEntityPosition(entity, true)
            end
        end
    end
end

return trolley
