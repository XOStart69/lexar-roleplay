local config = require 'config.shared'
local rooms = require 'data.rooms'
local doorModel = config.doorlock.doorModel

local phases = { 'door', 'stash', 'wardrobe' }
local phaseLabel = { door = 'pintu', stash = 'stash', wardrobe = 'wardrobe' }

local active = false
local cachedRooms = {}
local currentCoords = {}
local phaseIndex = 1

local function lastRoomNumber()
	local highest = 0

	for index = 1, #rooms do
		local number = tonumber(tostring(rooms[index].id):match('(%d+)$'))

		if number and number > highest then
			highest = number
		end
	end

	return highest
end

local idOffset = lastRoomNumber()

local function round(value)
	return math.floor((value * 1000) + 0.5) / 1000
end

local function drawEntityBoundingBox(entity, r, g, b, a)
	local min, max = GetModelDimensions(GetEntityModel(entity))
	local rightVector, forwardVector, upVector, position = GetEntityMatrix(entity)

	local dim = {
		x = 0.5 * (max.x - min.x),
		y = 0.5 * (max.y - min.y),
		z = 0.5 * (max.z - min.z),
	}

	local edges = {}
	edges[1] = position - dim.y * rightVector - dim.x * forwardVector - dim.z * upVector
	edges[2] = edges[1] + 2 * dim.y * rightVector
	edges[3] = edges[2] + 2 * dim.z * upVector
	edges[4] = edges[1] + 2 * dim.z * upVector
	edges[5] = position + dim.y * rightVector + dim.x * forwardVector + dim.z * upVector
	edges[6] = edges[5] - 2 * dim.y * rightVector
	edges[7] = edges[6] - 2 * dim.z * upVector
	edges[8] = edges[5] - 2 * dim.z * upVector

	for i = 1, 4 do
		local j = i % 4 + 1
		DrawLine(edges[i].x, edges[i].y, edges[i].z, edges[j].x, edges[j].y, edges[j].z, r, g, b, a)
		DrawLine(edges[i + 4].x, edges[i + 4].y, edges[i + 4].z, edges[j + 4].x, edges[j + 4].y, edges[j + 4].z, r, g, b, a)
		DrawLine(edges[i].x, edges[i].y, edges[i].z, edges[i + 4].x, edges[i + 4].y, edges[i + 4].z, r, g, b, a)
	end
end

local function rotationToDirection(rotation)
	local z = math.rad(rotation.z)
	local x = math.rad(rotation.x)
	local cosX = math.abs(math.cos(x))

	return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end

local function rayCastGameplayCamera(distance)
	local cameraCoord = GetGameplayCamCoord()
	local direction = rotationToDirection(GetGameplayCamRot(2))
	local destination = {
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance,
	}

	local _, hit, coords, _, entity = GetShapeTestResult(
		StartShapeTestRay(
			cameraCoord.x, cameraCoord.y, cameraCoord.z,
			destination.x, destination.y, destination.z,
			-1, PlayerPedId(), 0
		)
	)

	return hit, coords, entity
end

local function captureDoor(coords, entity)
	if entity and entity ~= 0 and IsEntityAnObject(entity) and GetEntityModel(entity) == doorModel then
		local doorCoords = GetEntityCoords(entity)

		return vector4(round(doorCoords.x), round(doorCoords.y), round(doorCoords.z), round(GetEntityHeading(entity)))
	end

	return vector4(round(coords.x), round(coords.y), round(coords.z), round(GetEntityHeading(cache.ped)))
end

local function captureAim(coords)
	return vector4(round(coords.x), round(coords.y), round(coords.z), round(GetEntityHeading(cache.ped)))
end

local function showHint()
	local phase = phases[phaseIndex]

	lib.showTextUI(
		('[E] Tetapkan lokasi %s — Room %s\n/saverooms simpan • /cancelrooms batal'):format(phaseLabel[phase], idOffset + #cachedRooms + 1),
		{ position = 'left-center' }
	)
end

local function setPhase(coords)
	currentCoords[phases[phaseIndex]] = coords

	if phaseIndex < #phases then
		phaseIndex = phaseIndex + 1
	else
		cachedRooms[#cachedRooms + 1] = {
			door = currentCoords.door,
			stash = currentCoords.stash,
			wardrobe = currentCoords.wardrobe,
		}

		currentCoords = {}
		phaseIndex = 1

		lib.notify({ description = ('Room %s tersimpan ke cache.'):format(idOffset + #cachedRooms), type = 'success' })
	end

	showHint()
end

local function formatVec4(coords)
	return ('vec4(%s, %s, %s, %s)'):format(coords.x, coords.y, coords.z, coords.w)
end

local function buildOutput(list)
	local lines = { '{' }

	for index = 1, #list do
		local room = list[index]

		lines[#lines + 1] = '    {'
		lines[#lines + 1] = ("        id = 'room_%s',"):format(idOffset + index)
		lines[#lines + 1] = '        coords = {'
		lines[#lines + 1] = ('            door = %s,'):format(formatVec4(room.door))
		lines[#lines + 1] = ('            stash = %s,'):format(formatVec4(room.stash))
		lines[#lines + 1] = ('            wardrobe = %s,'):format(formatVec4(room.wardrobe))
		lines[#lines + 1] = '        }'
		lines[#lines + 1] = index < #list and '    },' or '    }'
	end

	lines[#lines + 1] = '}'

	return table.concat(lines, '\n')
end

RegisterCommand('setuprooms', function()
	if active then
		return
	end

	active = true
	cachedRooms = {}
	currentCoords = {}
	phaseIndex = 1

	showHint()

	CreateThread(function()
		while active do
			local phase = phases[phaseIndex]
			local position = GetEntityCoords(PlayerPedId())
			local hit, coords, entity = rayCastGameplayCamera(1000.0)

			DisableControlAction(0, 38, true)

			if hit and (IsEntityAVehicle(entity) or IsEntityAPed(entity) or IsEntityAnObject(entity)) then
				local onDoor = phase == 'door' and IsEntityAnObject(entity) and GetEntityModel(entity) == doorModel
				local r = onDoor and 80 or 255
				local g = 255
				local b = onDoor and 120 or 255

				drawEntityBoundingBox(entity, r, g, b, 200)
				DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, r, g, b, 200)

				if IsDisabledControlJustReleased(0, 38) then
					setPhase(phase == 'door' and captureDoor(coords, entity) or captureAim(coords))
				end
			elseif coords and coords.x ~= 0.0 and coords.y ~= 0.0 then
				DrawLine(position.x, position.y, position.z, coords.x, coords.y, coords.z, 255, 255, 255, 200)
				---@diagnostic disable-next-line: param-type-mismatch
				DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, 255, 255, 255, 200, false, true, 2, nil, nil, nil, false)

				if IsDisabledControlJustReleased(0, 38) then
					setPhase(captureAim(coords))
				end
			end

			Wait(0)
		end
	end)
end, false)

RegisterCommand('saverooms', function()
	if not active then
		return
	end

	active = false
	lib.hideTextUI()

	if #cachedRooms == 0 then
		lib.print.warn('[rhd_motel] Tidak ada room yang disetup.')
		return
	end

	local output = buildOutput(cachedRooms)

	lib.print.info(output)
	lib.setClipboard(output)
	lib.notify({ description = ('%s room disalin ke clipboard.'):format(#cachedRooms), type = 'success' })
end, false)

RegisterCommand('cancelrooms', function()
	if not active then
		return
	end

	active = false
	cachedRooms = {}
	currentCoords = {}
	lib.hideTextUI()
	lib.notify({ description = 'Setup rooms dibatalkan.', type = 'info' })
end, false)

local roomsPerFloor = math.max(1, tonumber(config.management.roomsPerFloor) or 12)

local cloneActive = false
local clonedRooms = {}

local function drawText3D(coords, text)
	SetDrawOrigin(coords.x, coords.y, coords.z, 0)
	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextColour(255, 255, 255, 215)
	SetTextCentre(true)
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.0, 0.0)
	ClearDrawOrigin()
end

local function cloneLastFloor(zOffset)
	local total = #rooms
	local count = math.min(roomsPerFloor, total)
	local result = {}

	for index = total - count + 1, total do
		local coords = rooms[index].coords

		result[#result + 1] = {
			door = vector4(coords.door.x, coords.door.y, round(coords.door.z + zOffset), coords.door.w),
			stash = vector4(coords.stash.x, coords.stash.y, round(coords.stash.z + zOffset), coords.stash.w),
			wardrobe = vector4(coords.wardrobe.x, coords.wardrobe.y, round(coords.wardrobe.z + zOffset), coords.wardrobe.w),
		}
	end

	return result
end

RegisterCommand('clonefloors', function(_, args)
	if active or cloneActive then
		return
	end

	local zOffset = tonumber(args[1])

	if not zOffset then
		lib.notify({ description = 'Gunakan /clonefloors [offset z]', type = 'error' })
		return
	end

	if #rooms == 0 then
		lib.notify({ description = 'Data rooms kosong.', type = 'error' })
		return
	end

	clonedRooms = cloneLastFloor(zOffset)
	cloneActive = true

	lib.showTextUI(
		('Clone %s room (z %+g)\n/saveclone simpan • /cancelclone batal'):format(#clonedRooms, zOffset),
		{ position = 'left-center' }
	)

	CreateThread(function()
		while cloneActive do
			for index = 1, #clonedRooms do
				local room = clonedRooms[index]

				---@diagnostic disable-next-line: param-type-mismatch
				DrawMarker(28, room.door.x, room.door.y, room.door.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 80, 80, 200, false, false, 2, false, nil, nil, false)
				---@diagnostic disable-next-line: param-type-mismatch
				DrawMarker(28, room.stash.x, room.stash.y, room.stash.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 80, 255, 120, 200, false, false, 2, false, nil, nil, false)
				---@diagnostic disable-next-line: param-type-mismatch
				DrawMarker(28, room.wardrobe.x, room.wardrobe.y, room.wardrobe.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 80, 160, 255, 200, false, false, 2, false, nil, nil, false)
				drawText3D(room.door, ('room_%s'):format(idOffset + index))
			end

			Wait(0)
		end
	end)
end, false)

RegisterCommand('saveclone', function()
	if not cloneActive then
		return
	end

	cloneActive = false
	lib.hideTextUI()

	if #clonedRooms == 0 then
		lib.print.warn('[rhd_motel] Tidak ada room hasil clone.')
		return
	end

	local output = buildOutput(clonedRooms)

	lib.print.info(output)
	lib.setClipboard(output)
	lib.notify({ description = ('%s room hasil clone disalin ke clipboard.'):format(#clonedRooms), type = 'success' })
end, false)

RegisterCommand('cancelclone', function()
	if not cloneActive then
		return
	end

	cloneActive = false
	clonedRooms = {}
	lib.hideTextUI()
	lib.notify({ description = 'Clone floors dibatalkan.', type = 'info' })
end, false)
