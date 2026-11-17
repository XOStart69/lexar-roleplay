local areaHooks = {}
local interiorHooks = {}

local currentData = {
    inArea = false,
    currentRoom = nil
}

local casinoZone = lib.zones.poly(shared.casinoCoords.bigArea)

function casinoZone:roomChange()
    TriggerServerEvent('rhd_casino:onRoom', currentData.currentRoom)

    for i = 1, #interiorHooks do
        CreateThread(function ()
            interiorHooks[i](currentData.currentRoom)
        end)
    end
end

function casinoZone:onAreaChange(state)
    TriggerServerEvent('rhd_casino:interior', state)

    for i = 1, #areaHooks do
        CreateThread(function ()
            areaHooks[i](currentData.inArea)
        end)
    end
end

function casinoZone:inside()
    if not playerState.isLoggedIn then return end

    local coords1 = shared.casinoCoords.area[1]
    local coords2 = shared.casinoCoords.area[2]

    local interiorId = GetInteriorFromEntity(cache.ped)

    local closest = IsEntityInArea(
        cache.ped, coords1.x, coords1.y, coords1.z, coords2.x, coords2.y, coords2.z, false, true, 0)

    if currentData.inArea ~= closest then
        currentData.inArea = closest
        self:onAreaChange(currentData.inArea)
    end

    if interiorId ~= 0 then
        local roomHash = GetRoomKeyFromEntity(cache.ped)
        local roomId = GetInteriorRoomIndexByHash(interiorId, roomHash)
        local roomName = roomId ~= -1 and GetInteriorRoomName(interiorId, roomId) or 'unknown'

        if currentData.currentRoom ~= roomName then
            currentData.currentRoom = roomName
            self:roomChange()
        end
    else
        if currentData.currentRoom then
            currentData.currentRoom = nil
            self:roomChange()
        end
    end

    Wait(500)
end

function casinoZone:onExit()
    currentData.inArea = false
    currentData.currentRoom = nil

    self:roomChange()
    self:onAreaChange(false)
end

-- CreateThread(function ()
--     while true do
--         local changed = false

--         local coords1 = casinoArea[1]
--         local coords2 = casinoArea[2]

--         local closest = IsEntityInArea(
--             cache.ped, coords1.x, coords1.y, coords1.z, coords2.x, coords2.y, coords2.z, false, true, 0)

--         if currentData.inArea ~= closest then
--             currentData.inArea = closest
--             TriggerServerEvent('rhd_casino:interior', closest, currentData.currentRoom)

--             for i = 1, #areaHooks do
--                 CreateThread(function ()
--                     areaHooks[i](currentData.inArea)
--                 end)
--             end
--         end

--         if closest and playerState.isLoggedIn then
--             local interiorId = GetInteriorFromEntity(cache.ped)

--             if interiorId ~= 0 then
--                 local roomHash = GetRoomKeyFromEntity(cache.ped)
--                 local roomId = GetInteriorRoomIndexByHash(interiorId, roomHash)
--                 local roomName = roomId ~= -1 and GetInteriorRoomName(interiorId, roomId) or 'unknown'

--                 if currentData.currentRoom ~= roomName then
--                     currentData.currentRoom = roomName
--                     changed = true
--                 end
--             else
--                 if currentData.currentRoom then
--                     currentData.currentRoom = nil
--                     changed = true
--                 end
--             end
--         else
--             if currentData.currentRoom then
--                 currentData.currentRoom = nil
--                 changed = true
--             end
--         end

--         if changed then
--             for i = 1, #interiorHooks do
--                 CreateThread(function ()
--                     interiorHooks[i](currentData.currentRoom)
--                 end)
--             end
--             TriggerServerEvent('rhd_casino:onRoom', currentData.currentRoom)
--         end
--         Wait(500)
--     end
-- end)

---@param cb fun(inArea: boolean)
---@diagnostic disable-next-line: lowercase-global
function useAreaHooks(cb)
    areaHooks[#areaHooks + 1] = cb
end

---@param cb fun(roomName: string?)
---@diagnostic disable-next-line: lowercase-global
function useInteriorRoom(cb)
    interiorHooks[#interiorHooks + 1] = cb
end