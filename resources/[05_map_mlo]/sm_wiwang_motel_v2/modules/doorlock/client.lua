local doors = {}
local doorStates = {}
local closestDoor
local textVisible = false
local displayedDoorId
local displayedLocked

local config = require 'config.shared'
local rooms = require 'data.rooms'
local doorConfig = config.doorlock

local function getDoorHash(doorId)
	return joaat(('rhd_motel:%s'):format(doorId))
end

local function buildDoors()
	for index = 1, #rooms do
		local room = rooms[index]
		local door = room.coords.door

		if door then
			doors[#doors + 1] = {
				id = room.id,
				hash = getDoorHash(room.id),
				model = doorConfig.doorModel,
				coords = vector3(door.x, door.y, door.z),
				heading = door.w,
			}

			doorStates[room.id] = doorConfig.defaultLocked == true
		end
	end
end

local function applyDoorState(door, locked)
	DoorSystemSetDoorState(door.hash, locked and 1 or 0, false, true)
	DoorSystemSetAutomaticRate(door.hash, locked and 100.0 or 0.0, true, true)
end

local function registerDoor(door)
	if not IsDoorRegisteredWithSystem(door.hash) then
		AddDoorToSystem(
			door.hash, door.model,
			door.coords.x, door.coords.y, door.coords.z,
			false, false, false
		)
	end
end

local function registerAllDoors()
	for index = 1, #doors do
		registerDoor(doors[index])
	end
end

local function syncDoorStates()
	for index = 1, #doors do
		local door = doors[index]

		if IsDoorRegisteredWithSystem(door.hash) and DoorSystemGetIsPhysicsLoaded(door.hash) then
			local locked = doorStates[door.id] == true

			if DoorSystemGetDoorState(door.hash) ~= (locked and 1 or 0) then
				applyDoorState(door, locked)
			end
		end
	end
end

local function getClosestDoor()
	local playerCoords = GetEntityCoords(cache.ped)

	local nearestDoor
	local nearestDistance = doorConfig.interactDistance

	for index = 1, #doors do
		local door = doors[index]
		local distance = #(playerCoords - door.coords)

		if distance <= nearestDistance then
			nearestDoor = door
			nearestDistance = distance
		end
	end

	return nearestDoor
end

local function hideTextUI()
	if not textVisible then
		return
	end

	lib.hideTextUI()
	textVisible = false
	displayedDoorId = nil
	displayedLocked = nil
end

local function showDoorText(door)
	local locked = doorStates[door.id] == true

	if textVisible and displayedDoorId == door.id and displayedLocked == locked then
		return
	end

	local label = locked and 'Unlock Door' or 'Lock Door'

	lib.showTextUI(('[E] %s'):format(label), {
		icon = locked and 'lock' or 'unlock'
	})

	textVisible = true
	displayedDoorId = door.id
	displayedLocked = locked
end

local function setDoorState(doorId, locked)
	doorStates[doorId] = locked

	for index = 1, #doors do
		local door = doors[index]

		if door.id == doorId then
			applyDoorState(door, locked)
			return
		end
	end
end

local function requestDoorStates()
	local states = lib.callback.await('rhd_motel:doorlock:getStates', false)

	if type(states) ~= 'table' then
		return
	end

	doorStates = states
	registerAllDoors()
end

local function toggleClosestDoor()
	if not closestDoor then
		return
	end

	TriggerServerEvent('rhd_motel:doorlock:setState', closestDoor.id, doorStates[closestDoor.id] ~= true)
end

RegisterNetEvent('rhd_motel:doorlock:updateState', function(doorId, locked)
    if source == '' then return end

	setDoorState(doorId, locked)

	if closestDoor and closestDoor.id == doorId then
		showDoorText(closestDoor)
	end
end)

lib.addKeybind({
    name = 'motel_doorlock_toggle',
    description = 'Toggle motel door lock',
    defaultKey = 'E',
    onPressed = toggleClosestDoor,
})

buildDoors()

CreateThread(function()
	requestDoorStates()
end)

CreateThread(function()
	while true do
		syncDoorStates()
		Wait(1000)
	end
end)

CreateThread(function()
	while true do
		closestDoor = getClosestDoor()

		if closestDoor then
			showDoorText(closestDoor)
			Wait(250)
		else
			hideTextUI()
			Wait(750)
		end
	end
end)
