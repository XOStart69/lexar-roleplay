local driveby = {}
local weapons = require 'rhd_addon.data.driveby_weapons'

local function vehicleIsHeli(vehicle)
	return GetVehicleClass(vehicle) == 15
end

function driveby.checkState(weapon)
	if cache.vehicle and weapon then
		local canDriveby = lib.array.includes(weapons, weapon) and not vehicleIsHeli(cache.vehicle)
		SetPlayerCanDoDriveBy(cache.playerId --[[@as number]], canDriveby --[[@as boolean]])
	else
		SetPlayerCanDoDriveBy(cache.playerId --[[@as number]], true)
	end
end

function driveby.canDriveby(weapon)
    return lib.array.includes(weapons, weapon) and not vehicleIsHeli(cache.vehicle)
end

lib.onCache('vehicle', function(vehicle)
	if vehicle then
		CreateThread(function()
			while cache.vehicle do
				local currentWeapon = exports.ox_inventory:getCurrentWeapon()
				if currentWeapon and currentWeapon.hash then
					local canDriveby = driveby.canDriveby(currentWeapon.hash)
					SetPlayerCanDoDriveBy(cache.playerId --[[@as number]], canDriveby --[[@as boolean]])
				end
				Wait(200)
			end
		end)
	else
		SetPlayerCanDoDriveBy(cache.playerId --[[@as number]], true)
	end
end)

return driveby