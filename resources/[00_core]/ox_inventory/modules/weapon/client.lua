if not lib then return end

local Weapon = {}
local Items = require 'modules.items.client'
local Utils = require 'modules.utils.client'
local driveby = require 'rhd_addon.driveby.client'

-- generic group animation data
local anims = {}
anims[`GROUP_MELEE`] = { 'rick3d@weapons', 'axedraw', 700, 'rick3d@weapons', 'axeholst', 950 }
anims[`GROUP_PISTOL`] = { 'rick3d@weapons', 'pistolfrontdraw', 800, 'rick3d@weapons', 'pistolfrontholst', 1100 }
anims[`GROUP_STUNGUN`] = { 'rick3d@weapons', 'taserdraw', 800, 'rick3d@weapons', 'taserholst', 1800 }
anims[`GROUP_SMG`] = { 'rick3d@weapons', 'smgdraw', 800, 'rick3d@weapons', 'smgholst', 900 }
anims[`GROUP_RIFLE`] = { 'rick3d@weapons', 'rifledraw', 800, 'rick3d@weapons', 'rifleholst', 900 }
anims[`GROUP_MG`] = anims[`GROUP_RIFLE`]
anims[`GROUP_SHOTGUN`] = anims[`GROUP_RIFLE`]
anims[`GROUP_SNIPER`] = anims[`GROUP_RIFLE`]
anims[`GROUP_HEAVY`] = anims[`GROUP_RIFLE`]

local IsEntityPlayingAnim = IsEntityPlayingAnim
local GetGameTimer = GetGameTimer
local DisablePlayerFiring = DisablePlayerFiring
local Wait = Wait

local drawStartGrace = 250

local function vehicleIsCycle(vehicle)
	local class = GetVehicleClass(vehicle)
	return class == 8 or class == 13
end

---@param ped number
---@param dict string
---@param name string
---@param duration number
---@return boolean
local function waitDrawAnim(ped, dict, name, duration)
	local playerId = cache.playerId
	local startAt = GetGameTimer()
	local endAt = startAt + duration
	local started = false

	while true do
		local now = GetGameTimer()

		if now >= endAt then
			return started
		end

		local playing = IsEntityPlayingAnim(ped, dict, name, 3)

		if playing then
			started = true
		end

		if started and not playing then
			return false
		end

		if not started and now - startAt > drawStartGrace then
			return false
		end

		DisablePlayerFiring(playerId, true)
		Wait(0)
	end
end

function Weapon.Equip(item, data, noWeaponAnim)
	local playerPed = cache.ped
	local coords = GetEntityCoords(playerPed, true)
    local sleep

	if client.weaponanims then
		if noWeaponAnim or (cache.vehicle and vehicleIsCycle(cache.vehicle)) then
			goto skipAnim
		end

		local anim = data.anim or anims[GetWeapontypeGroup(data.hash)]
		local dict = anim and anim[1] or 'reaction@intimidation@1h'
		local name = anim and anim[2] or 'intro'

		sleep = anim and anim[3] or 1200

		Utils.PlayAnimAdvanced(0, dict, name, coords.x, coords.y, coords.z, 0, 0, GetEntityHeading(playerPed), 8.0, 3.0, sleep*2, 50, 0.1)

		local completed = waitDrawAnim(playerPed, dict, name, sleep)

		if not completed and not cache.vehicle then
			TriggerServerEvent('ox_inventory:updateWeapon')
			lib.notify({ id = 'weapon_draw_interrupted', type = 'error', description = 'Mengeluarkan senjata dibatalkan' })
			return
		end
	end

	::skipAnim::

	item.hash = data.hash
	item.ammo = data.ammoname
	item.melee = GetWeaponDamageType(data.hash) == 2 and 0
	item.timer = 0
	item.throwable = data.throwable
	item.group = GetWeapontypeGroup(item.hash)

	GiveWeaponToPed(playerPed, data.hash, 0, false, true)

	if item.metadata.tint then SetPedWeaponTintIndex(playerPed, data.hash, item.metadata.tint) end

	if item.metadata.components then
		for i = 1, #item.metadata.components do
			local components = Items[item.metadata.components[i]].client.component
			for v=1, #components do
				local component = components[v]
				if DoesWeaponTakeWeaponComponent(data.hash, component) then
					if not HasPedGotWeaponComponent(playerPed, data.hash, component) then
						GiveWeaponComponentToPed(playerPed, data.hash, component)
					end
				end
			end
		end
	end

	if item.metadata.specialAmmo then
		local clipComponentKey = ('%s_CLIP'):format(data.model:gsub('WEAPON_', 'COMPONENT_'))
		local specialClip = ('%s_%s'):format(clipComponentKey, item.metadata.specialAmmo:upper())

		if DoesWeaponTakeWeaponComponent(data.hash, specialClip) then
			GiveWeaponComponentToPed(playerPed, data.hash, specialClip)
		end
	end

	local ammo = item.metadata.ammo or item.throwable and 1 or 0

	SetCurrentPedWeapon(playerPed, data.hash, true)
	SetPedCurrentWeaponVisible(playerPed, true, false, false, false)
	SetWeaponsNoAutoswap(true)
	SetPedAmmo(playerPed, data.hash, ammo)
	SetTimeout(0, function() RefillAmmoInstantly(playerPed) end)

	driveby.checkState(data.hash)

	if item.group == `GROUP_PETROLCAN` or item.group == `GROUP_FIREEXTINGUISHER` then
		item.metadata.ammo = item.metadata.durability
		SetPedInfiniteAmmo(playerPed, true, data.hash)
	end

	TriggerEvent('ox_inventory:currentWeapon', item)

	if client.weaponnotify then
		Utils.ItemNotify({ item, 'ui_equipped' })
	end

	return item, sleep
end

function Weapon.Disarm(currentWeapon, noAnim)
	if currentWeapon?.timer then
		currentWeapon.timer = nil

        TriggerServerEvent('ox_inventory:updateWeapon')
		SetPedAmmo(cache.ped, currentWeapon.hash, 0)

		if client.weaponanims and not noAnim then
			if cache.vehicle and vehicleIsCycle(cache.vehicle) then
				goto skipAnim
			end

			ClearPedSecondaryTask(cache.ped)

			local item = Items[currentWeapon.name]
			local coords = GetEntityCoords(cache.ped, true)
			local anim = item.anim or anims[GetWeapontypeGroup(currentWeapon.hash)]

			local sleep = anim and anim[6] or 1400

			Utils.PlayAnimAdvanced(sleep, anim and anim[4] or 'reaction@intimidation@1h', anim and anim[5] or 'outro', coords.x, coords.y, coords.z, 0, 0, GetEntityHeading(cache.ped), 8.0, 3.0, sleep, 50, 0)
		end

		::skipAnim::

		if client.weaponnotify then
			Utils.ItemNotify({ currentWeapon, 'ui_holstered' })
		end

		TriggerEvent('ox_inventory:currentWeapon')
	end

	SetPlayerCanDoDriveBy(cache.playerId --[[@as number]], true)
	Utils.WeaponWheel()
	RemoveAllPedWeapons(cache.ped, true)

	if client.parachute then
		local chute = `GADGET_PARACHUTE`
		GiveWeaponToPed(cache.ped, chute, 0, true, false)
		SetPedGadget(cache.ped, chute, true)
		SetPlayerParachuteTintIndex(PlayerData.id, client.parachute?[2] or -1)
	end
end

function Weapon.ClearAll(currentWeapon)
	Weapon.Disarm(currentWeapon)

	if client.parachute then
		local chute = `GADGET_PARACHUTE`
		GiveWeaponToPed(cache.ped, chute, 0, true, false)
		SetPedGadget(cache.ped, chute, true)
	end
end

Utils.Disarm = Weapon.Disarm
Utils.ClearWeapons = Weapon.ClearAll

return Weapon
