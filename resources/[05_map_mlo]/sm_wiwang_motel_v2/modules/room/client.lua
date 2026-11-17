local config = require 'config.shared'
local rooms = require 'data.rooms'
local roomConfig = config.room

local points = {}
local textVisible = false
local displayedLabel

local labels = {
	stash = '[E] Buka stash',
	wardrobe = '[E] Buka wardrobe',
}

for index = 1, #rooms do
	local room = rooms[index]

	if room.coords.stash then
		points[#points + 1] = {
			roomId = room.id,
			kind = 'stash',
			coords = vector3(room.coords.stash.x, room.coords.stash.y, room.coords.stash.z),
		}
	end

	if room.coords.wardrobe then
		points[#points + 1] = {
			roomId = room.id,
			kind = 'wardrobe',
			coords = vector3(room.coords.wardrobe.x, room.coords.wardrobe.y, room.coords.wardrobe.z),
		}
	end
end

local function showHint(label)
	if textVisible and displayedLabel == label then
		return
	end

	lib.showTextUI(label)
	textVisible = true
	displayedLabel = label
end

local function hideHint()
	if not textVisible then
		return
	end

	lib.hideTextUI()
	textVisible = false
	displayedLabel = nil
end

local function interact(point)
	local result = lib.callback.await('rhd_motel:room:interact', false, {
		roomId = point.roomId,
		kind = point.kind,
	})

	if not result or not result.success then
		if result and result.message then
			lib.notify({ type = 'error', description = result.message })
		end
		return
	end

	if result.kind == 'wardrobe' then
		TriggerEvent('illenium-appearance:client:openOutfitMenu')
	elseif result.kind == 'stash' then
		Inventory:openInventory('stash', result.stashId)
	end
end

CreateThread(function()
	while true do
		local wait = 750
		local nearest
		local nearestDistance = roomConfig.interactDistance

		if #points > 0 then
			local playerCoords = GetEntityCoords(cache.ped)

			for index = 1, #points do
				local distance = #(playerCoords - points[index].coords)

				if distance <= nearestDistance then
					nearest = points[index]
					nearestDistance = distance
				end
			end
		end

		if nearest then
			wait = 0
			showHint(labels[nearest.kind])

			if IsControlJustReleased(0, 38) then
				interact(nearest)
			end
		else
			hideHint()
		end

		Wait(wait)
	end
end)
