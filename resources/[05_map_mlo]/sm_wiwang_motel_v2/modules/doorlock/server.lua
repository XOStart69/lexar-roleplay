local doorStates = {}
local doorPositions = {}

local config = require 'config.shared'
local rooms = require 'data.rooms'
local doorConfig = config.doorlock

local function copyDoorStates()
	local states = {}

	for doorId, locked in pairs(doorStates) do
		states[doorId] = locked
	end

	return states
end

local function registerDoors()
	for index = 1, #rooms do
		local room = rooms[index]
		local door = room.coords.door

		if door then
			doorStates[room.id] = doorConfig.defaultLocked == true
			doorPositions[room.id] = door
		end
	end
end

local function canUseDoorlock(source, doorId)
	local citizenid = Core:GetCitizenId(source)
	if not citizenid then return end

	if Staff.hasPermission(source, 'doorlockBypass') then
		return true
	end

	return Storage.canAccessRoom(doorId, citizenid)
end

local function isPlayerNearDoor(source, doorId)
	local doorPosition = doorPositions[doorId]

	if not doorPosition then
		return false
	end

	local playerPed = GetPlayerPed(source)

	if playerPed == 0 then
		return false
	end

	local playerCoords = GetEntityCoords(playerPed)
    local doorCoords = vector3(doorPosition.x, doorPosition.y, doorPosition.z)

    local distance = #(playerCoords - doorCoords)
    local maxDistance = doorConfig.maxSetStateDistance or doorConfig.interactDistance

	return distance <= maxDistance
end

local function setDoorState(doorId, locked)
	if type(doorId) ~= 'string' or type(locked) ~= 'boolean' then
		return false
	end

	if doorStates[doorId] == nil then
		return false
	end

	if doorStates[doorId] == locked then
		return true
	end

	doorStates[doorId] = locked
	TriggerClientEvent('rhd_motel:doorlock:updateState', -1, doorId, locked)

	return true
end

registerDoors()

lib.callback.register('rhd_motel:doorlock:getStates', function()
	return copyDoorStates()
end)

RegisterNetEvent('rhd_motel:doorlock:setState', function(doorId, locked)
	local source = source

	if type(doorId) ~= 'string' or type(locked) ~= 'boolean' then
		return
	end

	if doorStates[doorId] == nil then
		return
	end

	if not isPlayerNearDoor(source, doorId) then
		lib.notify(source, {
			type = 'error',
			description = 'You are too far from this door.',
			duration = 5000,
		})
		return
	end

	if not canUseDoorlock(source, doorId) then
		lib.notify(source, {
			type = 'error',
			description = 'You do not have access to the doorlock.',
			duration = 5000,
		})
		return
	end

	setDoorState(doorId, locked)
end)

AddEventHandler('rhd_motel:doorlock:setStateInternal', function(doorId, locked)
	setDoorState(doorId, locked)
end)
