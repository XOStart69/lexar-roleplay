local INFO_ID = 'carry_selector'
local CONFIRM = 38
local CANCEL = 202
local SELECT_RADIUS = 3.0

local selecting = false

local markerTop = lib.marker.new({
	type = 'ChevronUpx1',
	coords = vec3(0, 0, 0),
	width = 0.4,
	height = -0.4,
	direction = vec3(0, 0, 0),
	color = { r = 26, g = 161, b = 149, a = 120 }
})

local markerGround = lib.marker.new({
	type = 'HorizontalCircleSkinny',
	coords = vec3(0, 0, 0),
	width = 1.0,
	height = 1.0,
	color = { r = 26, g = 161, b = 149, a = 120 }
})

---@param picked number[]
---@param total number
local function showInfo(picked, total)
	local lines = {}

	for i = 1, total do
		lines[#lines + 1] = ('Orang %d: %s'):format(i, picked[i] and '✓ terpilih' or '- belum')
	end

	infoUI.show({
		id = INFO_ID,
		title = 'Pilih Orang Untuk Digendong',
		icon = 'fa-solid fa-people-carry-box',
		description = ('%s\n\n[kbd]E[/kbd] Pilih orang\n[kbd]BACKSPACE[/kbd] Batal'):format(
			table.concat(lines, '\n')
		)
	})
end

---@param exclude table<number, boolean>
---@return number? playerId
---@return vector3? coords
local function getClosestFree(exclude)
	local coords = GetEntityCoords(cache.ped)
	local closest, closestCoords, closestDist

	for _, playerId in ipairs(GetActivePlayers()) do
		if playerId ~= cache.playerId then
			local serverId = GetPlayerServerId(playerId)

			if not exclude[serverId] then
				local ped = GetPlayerPed(playerId)
				local vehicle = GetVehiclePedIsIn(ped, false)
				local targetCoords = vehicle == 0 and GetEntityCoords(ped) or GetWorldPositionOfEntityBone(ped, 0)
				local dist = #(coords - targetCoords)

				if dist <= SELECT_RADIUS and (not closestDist or dist < closestDist) then
					closest = playerId
					closestCoords = targetCoords
					closestDist = dist
				end
			end
		end
	end

	return closest, closestCoords
end

---@param total number
---@return number[]?
local function selectPlayers(total)
	if selecting then return end

	selecting = true

	local picked = {}
	local excluded = {}
	local cancelled = false

	showInfo(picked, total)

	while selecting and #picked < total do
		local playerId, targetCoords = getClosestFree(excluded)

		DisableControlAction(2, 200, true)

		if IsControlJustReleased(0, CANCEL) then
			cancelled = true
			break
		end

		if playerId then
			markerTop.coords = vec3(targetCoords.x, targetCoords.y, targetCoords.z + 1.2)
			markerGround.coords = vec3(targetCoords.x, targetCoords.y, targetCoords.z - 0.95)
			markerTop:draw()
			markerGround:draw()

			if IsControlJustReleased(0, CONFIRM) then
				local serverId = GetPlayerServerId(playerId)

				picked[#picked + 1] = serverId
				excluded[serverId] = true

				showInfo(picked, total)
			end
		elseif IsControlJustReleased(0, CONFIRM) then
			lib.notify({ description = 'Tidak ada pemain di dekatmu!', type = 'error' })
		end

		Wait(0)
	end

	selecting = false
	infoUI.remove(INFO_ID)

	if cancelled or #picked < total then
		return nil
	end

	return picked
end

RegisterNetEvent('sm_carry:client:selectTargets', function(command, total)
	if source == '' then return end

	local picked = selectPlayers(total)

	if not picked then
		return lib.notify({ description = 'Gendong dibatalkan.', type = 'error' })
	end

	TriggerServerEvent('sm_carry:server:targetsPicked', command, picked)
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end

	selecting = false
	infoUI.remove(INFO_ID)
end)
