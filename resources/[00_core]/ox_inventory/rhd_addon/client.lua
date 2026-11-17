if not lib then return end

local inventoryColorThemeKvp = 'ox_inventory:colorTheme:v1'

RegisterNUICallback('getInventoryColorTheme', function(_, cb)
	local value = GetResourceKvpString(inventoryColorThemeKvp)

	if not value then return cb(false) end

	local success, theme = pcall(json.decode, value)
	cb(success and type(theme) == 'table' and theme or false)
end)

RegisterNUICallback('saveInventoryColorTheme', function(data, cb)
	if type(data) ~= 'table' then return cb(false) end

	SetResourceKvp(inventoryColorThemeKvp, json.encode(data))
	cb(true)
end)

RegisterNUICallback('resetInventoryColorTheme', function(_, cb)
	DeleteResourceKvp(inventoryColorThemeKvp)
	cb(true)
end)

RegisterNUICallback('craftQueueAdd', function(data, cb)
	cb(1)

	if not data?.id then return end

	lib.callback.await('ox_inventory:craftQueueAdd', false, data.id, data.index, data.recipeId, data.count, data.toSlot)
end)

RegisterNUICallback('craftQueueCancel', function(data, cb)
	cb(1)

	if not data?.entryId then return end

	lib.callback.await('ox_inventory:craftQueueCancel', false, data.entryId)
end)

RegisterNUICallback('craftQueueRequest', function(_, cb)
	cb(1)
	lib.callback.await('ox_inventory:craftQueueRequest', false)
end)

RegisterNetEvent('ox_inventory:craftQueue', function(entries)
	if source == '' then return end

	SendNUIMessage({ action = 'craftQueueState', data = entries })
end)
