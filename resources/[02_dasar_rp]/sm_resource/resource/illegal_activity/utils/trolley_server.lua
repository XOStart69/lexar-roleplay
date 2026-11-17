local CreateObjectNoOffset = CreateObjectNoOffset
local DoesEntityExist = DoesEntityExist
local DeleteEntity = DeleteEntity
local SetEntityHeading = SetEntityHeading
local FreezeEntityPosition = FreezeEntityPosition
local SetEntityOrphanMode = SetEntityOrphanMode
local NetworkGetNetworkIdFromEntity = NetworkGetNetworkIdFromEntity
local GetGameTimer = GetGameTimer
local Wait = Wait

local trolleyModel = `hei_prop_hei_cash_trolly_01`

local trolley = {}

---@param list number[]
---@return nil
function trolley.clear(list)
    for i = #list, 1, -1 do
        local entity = list[i]
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        list[i] = nil
    end
end

---@param list number[]
---@param trolleyConfig table
---@return number[]
function trolley.spawn(list, trolleyConfig)
    trolley.clear(list)

    local netIds = {}

    for i = 1, #trolleyConfig do
        local coords = trolleyConfig[i].coords
        local entity = CreateObjectNoOffset(trolleyModel, coords.x, coords.y, coords.z - 0.5, true, true, false)
        local timeout = GetGameTimer() + 3000

        while not DoesEntityExist(entity) and GetGameTimer() < timeout do
            Wait(0)
        end

        if DoesEntityExist(entity) then
            SetEntityOrphanMode(entity, 2)
            SetEntityHeading(entity, coords.w)
            FreezeEntityPosition(entity, true)
            list[#list + 1] = entity
            netIds[#netIds + 1] = NetworkGetNetworkIdFromEntity(entity)
        else
            print(('^1[trolley] gagal spawn trolley #%d di %.2f %.2f %.2f^0'):format(i, coords.x, coords.y, coords.z))
        end
    end

    return netIds
end

return trolley
