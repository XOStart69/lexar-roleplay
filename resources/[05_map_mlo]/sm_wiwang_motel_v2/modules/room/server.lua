local config = require 'config.shared'
local rooms = require 'data.rooms'
local Layout = require 'modules.layout'
local roomConfig = config.room

local roomById = {}
local registeredStashes = {}

for index = 1, #rooms do
	roomById[rooms[index].id] = rooms[index]
end

local function isNear(source, coords)
	local ped = GetPlayerPed(source)

	if ped == 0 then
		return false
	end

	local playerCoords = GetEntityCoords(ped)

	return #(playerCoords - vector3(coords.x, coords.y, coords.z)) <= roomConfig.interactDistance
end

local function canAccess(source, roomId)
	local citizenid = Core:GetCitizenId(source)

	if not citizenid then
		return false
	end

	if Staff.hasPermission(source, 'storageBypass') then
		return true
	end

	return Storage.canAccessRoom(roomId, citizenid)
end

local function openStash(source, room)
	local stashId = ('motel_%s'):format(room.id)

	if not registeredStashes[stashId] then
		local slots, weight = Layout.getStorage(room.id)

		Inventory:RegisterStash(stashId, ('Motel %s'):format(room.id), slots, weight, false)
		registeredStashes[stashId] = true
	end

	return { success = true, kind = 'stash', stashId = stashId }
end


local function getDoorOffsetCoords(coords)
    local x, y, z, w = table.unpack(coords)

    local offsetX = -0.5
    local offsetY = 0.7

    local rad = math.rad(w)

    local rotatedX = offsetX * math.cos(rad) - offsetY * math.sin(rad)
    local rotatedY = offsetX * math.sin(rad) + offsetY * math.cos(rad)

    return vector4(
        x - rotatedX,
        y - rotatedY,
        z - 1.0,
        w - 180.0
    )
end

local function getMotelSpawn(source)
    local citizenId = exports.sm_core:GetCitizenId(source)
    if not citizenId then return end

    local roomIds = Storage.getPlayerRoomId(citizenId)

	if not roomIds or not lib.array.isArray(roomIds) or #roomIds < 1 then
		return
	end

    local spawnData = {}

    for i=1, #roomIds do
		local roomid = roomIds[i]
		local doorCoords = lib.array.find(rooms, function (t)
			return t.id == roomid
		end)?.coords?.door

		if doorCoords and type(doorCoords) == 'vector4' then
			local room = roomid:match('_([^_]+)$')
			local spawnId = 'arm_room_' .. room

			spawnData[spawnId] = {
				coords = getDoorOffsetCoords(doorCoords),
				label = 'Avenue Royal Motel - Room ' .. room,
				skipScene = true
			}
		end
    end

	return spawnData
end

exports('getMotelSpawn', getMotelSpawn)

exports('isRentedRoom', function (source)
	local citizenid = Core:GetCitizenId(source)
	local playerRooms = Storage.getPlayerRoomId(citizenid)
	return playerRooms and #playerRooms > 0
end)

-- RegisterCommand('getmotelroom', function (source)
-- 	-- local door_coords = vec(-834.26300048828, -724.19000244141, 113.56800079346, 360.0)
-- 	-- local spawn_coords = getDoorFrontCoords(door_coords)

-- 	-- local ped = GetPlayerPed(source)
-- 	-- SetEntityCoords(ped, spawn_coords.x, spawn_coords.y, spawn_coords.z, false, false, false, false)
-- 	-- SetEntityHeading(ped, spawn_coords.w)

-- 	local spawnData = getMotelSpawn(source)
-- 	print(json.encode(spawnData, {indent =true}))
-- end, false)

lib.callback.register('rhd_motel:room:interact', function(source, payload)
	local kind = type(payload) == 'table' and payload.kind
	local room = type(payload) == 'table' and roomById[payload.roomId]

	if not room or (kind ~= 'stash' and kind ~= 'wardrobe') then
		return { success = false }
	end

	local coords = room.coords[kind]

	if not coords or not isNear(source, coords) then
		return { success = false, message = 'Kamu terlalu jauh.' }
	end

	if not canAccess(source, room.id) then
		return { success = false, message = 'Kamu tidak punya akses ke kamar ini.' }
	end

	if kind == 'wardrobe' then
		return { success = true, kind = 'wardrobe' }
	end

	return openStash(source, room)
end)
