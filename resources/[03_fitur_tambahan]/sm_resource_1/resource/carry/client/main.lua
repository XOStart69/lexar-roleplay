local MyAnimType
local MyCarry = false
local MySlot = 1

---@param pose CarryTypeConfig
---@param slot number
---@return CarryPoseConfig
local function getCarriedPose(pose, slot)
	if slot == 2 and pose.personCarried2 then
		return pose.personCarried2
	end

	return pose.personCarried
end

local carry = {
    InProgress = false,
    type = "",
}

local carryConfig = localmodule 'config.client'

local function isPlayerCuffed()
	local ok, cuffed = pcall(function() return exports.sm_policejob:IsHandcuffed() end)
	return ok and cuffed
end

local function CarrySleep()
	local sleep = 1000
	if carry.InProgress then
		local pose = carryConfig[MyAnimType]
		if carry.type == "beingcarried" then
			if cache.weapon then
				TriggerEvent('ox_inventory:disarm', true)
			end
			local part = getCarriedPose(pose, MySlot)

			if not IsEntityPlayingAnim(cache.ped, part.animDict, part.anim, 3) then
				TaskPlayAnim(cache.ped, part.animDict, part.anim, 8.0, -8.0, 100000, part.flag, 0, false, false, false)
			end
		elseif carry.type == "carrying" then
			if not IsEntityPlayingAnim(cache.ped, pose.personCarrying.animDict, pose.personCarrying.anim, 3) then
				TaskPlayAnim(cache.ped, pose.personCarrying.animDict, pose.personCarrying.anim, 8.0, -8.0, 100000, pose.personCarrying.flag, 0, false, false, false)
			end
		end
		sleep = 100
	end
	return sleep
end

local function clearCarryAnim()
	local pose = MyAnimType and carryConfig[MyAnimType]

	if pose then
		local part = MyCarry and pose.personCarrying or getCarriedPose(pose, MySlot)

		if IsEntityPlayingAnim(cache.ped, part.animDict, part.anim, 3) then
			StopAnimTask(cache.ped, part.animDict, part.anim, 1.0)
		end
	end

	ClearPedSecondaryTask(cache.ped)
	ClearPedTasks(cache.ped)
	DetachEntity(cache.ped, true, false)

	MyCarry = false
	MyAnimType = nil
	MySlot = 1
	carry.type = ""
end

local function stopCarry()
	if not carry.InProgress then
        return lib.notify({ title = 'Carry', description = 'kamu sedang tidak gendong siapa-siapa', type = 'error' })
	end

	TriggerServerEvent("sm_carry:server:stop")
	carry.InProgress = false
	clearCarryAnim()
end

RegisterNetEvent("sm_carry:client:start", function(otherSrc, command, isCarrier, slot)
    if source == '' then return end

	local pose = carryConfig[command]
	if not pose then return end

	MyAnimType = command
	MyCarry = isCarrier
	MySlot = slot or 1
	carry.InProgress = true

	if isCarrier then
		if isPlayerCuffed() then
			notifyError('Kamu tidak bisa menggendong saat sedang diborgol!')
			return stopCarry()
		end

		lib.requestAnimDict(pose.personCarrying.animDict)
		carry.type = "carrying"
		return
	end

    local playerId = GetPlayerFromServerId(otherSrc)
	local carrierPed = GetPlayerPed(playerId)
	local part = getCarriedPose(pose, MySlot)

	lib.requestAnimDict(part.animDict)
	local boneIndex = part.boneIndex or false --[[@as number]]

	if type(boneIndex) == 'number' then
		boneIndex = GetPedBoneIndex(cache.ped, boneIndex)
	end

	local fixedRot = part.fixedRot or false

	AttachEntityToEntity(cache.ped, carrierPed, boneIndex or 0,
		part.attachX,
		part.attachY,
		part.attachZ,
		part.rotX or 0.5,
		part.rotY or 0.5,
		part.rotZ or 180.0,
		false,
		false,
		false,
		fixedRot,
		2,
		fixedRot
	)

	carry.type = "beingcarried"
end)

RegisterNetEvent("sm_carry:client:stop", function()
    if source == '' then return end

	carry.InProgress = false
	clearCarryAnim()
end)

lib.addKeybind({
	name = 'stop_carry',
	description = 'Stop carry',
	defaultKey = 'X',
	onPressed = function()
		if not carry.InProgress then return end
		stopCarry()
	end
})

local exportWrapper = require 'export_wrapper'
exportWrapper('sm_carrysystem', "stopcarry", stopCarry)

exportWrapper('sm_carrysystem', "isCarrying", function()
	return carry.InProgress and MyCarry
end)

exportWrapper('sm_carrysystem', "isBeingCarried", function()
	return carry.InProgress and not MyCarry
end)

exportWrapper('sm_carrysystem', "isInCarry", function()
	return carry.InProgress == true
end)

CreateThread(function()
	while true do
		Wait(CarrySleep())
	end
end)
