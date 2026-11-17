if not lib then return end

local Backpacks = lib.load('rhd_addon.data.backpack') or {}

local Backpack = {}
local current

-- deferred so the displayMetadata export is registered before it gets called
CreateThread(function()
	exports.ox_inventory:displayMetadata('backpackId', 'ID Backpack')
end)

---@param itemName? string
---@return boolean
function Backpack.isItem(itemName)
	return itemName ~= nil and Backpacks[itemName] ~= nil
end

---@return table?
function Backpack.get()
	return current
end

---@return table?
function Backpack.getInventory()
	return current and current.inventory or nil
end

---@param slot number
---@param id string
---@param inventory table
function Backpack.set(slot, id, inventory)
	current = {
		slot = slot,
		id = id,
		inventory = inventory
	}

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			backpackInventory = inventory
		}
	})
end

---@param notifyServer? boolean
function Backpack.close(notifyServer)
	current = nil

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			backpackInventory = false
		}
	})

	if notifyServer then
		TriggerServerEvent('ox_inventory:closeBackpack')
	end
end

RegisterNetEvent('ox_inventory:closeBackpack', function()
	Backpack.close(false)
end)

return Backpack
