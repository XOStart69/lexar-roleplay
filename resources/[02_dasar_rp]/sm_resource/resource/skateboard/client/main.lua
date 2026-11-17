local Skating = lib.class('Skating') ---@class Skating

local config = localmodule 'config.shared'

---@type Skating?
local activeSkate = nil

---@param model SkateModelHashes
---@return boolean
local function loadModels(model)
	local ok = pcall(function()
		lib.requestModel(model.bycicle)
		lib.requestModel(model.ped)
		lib.requestModel(model.board)
	end)

	return ok
end

---@param ped number
---@param bycicle number
---@return boolean
local function requestNetworkControl(ped, bycicle)
	if not NetworkHasControlOfEntity(ped) then
		NetworkRequestControlOfEntity(ped)
		return false
	end

	if not NetworkHasControlOfEntity(bycicle) then
		NetworkRequestControlOfEntity(bycicle)
		return false
	end

	return true
end

---@param model string
function Skating:constructor(model)
	self.entities = {}
	self.connected = false
	self.speed = 0
    self.fallStartZ = nil

	self.model = {
		board = joaat(model),
		ped = joaat('S_M_M_AutoShop_01'),
		bycicle = joaat('triBike3'),
	}

	if not loadModels(self.model) then
		error(('Skating: failed to load models for %s'):format(model))
	end
end

function Skating:setHandling()
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fSteeringLock", 9.0)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fDriveInertia", 0.05)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fMass", 1800.0)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fPercentSubmerged", 105.0)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fDriveBiasFront", 0.0)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fInitialDriveForce", 0.25)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fInitialDriveMaxFlatVel", 135.0)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fTractionCurveMax", 2.2)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fTractionCurveMin", 2.12)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fTractionCurveLateral", 22.5)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fTractionSpringDeltaMax", 0.1)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fLowSpeedTractionLossMult", 0.7)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fCamberStiffnesss", 0.0)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fTractionBiasFront", 0.478)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fTractionLossMult", 0.0)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fSuspensionForce", 5.2)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fSuspensionForce", 1.2)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fSuspensionReboundDamp", 1.7)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fSuspensionUpperLimit", 0.1	)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fSuspensionLowerLimit", -0.3)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fSuspensionRaise", 0.0)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fSuspensionBiasFront", 0.5)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fAntiRollBarForce", 0.0)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fAntiRollBarBiasFront", 0.65)
	SetVehicleHandlingFloat(self.entities.bycicle, "CHandlingData", "fBrakeForce", 0.53)
end

function Skating:prepare()
	local forward = GetEntityForwardVector(cache.ped)
	local spawnCoords = GetEntityCoords(cache.ped) + forward * 2.0
	local spawnHeading = GetEntityHeading(cache.ped)

	self.entities.bycicle = CreateVehicle(
		self.model.bycicle,
		spawnCoords.x, spawnCoords.y, spawnCoords.z,
		spawnHeading, true, false
	)

	self.entities.board = CreateObject(self.model.board, 0.0, 0.0, 0.0, true, true, true)

	lib.waitFor(function ()
		if DoesEntityExist(self.entities.bycicle) and DoesEntityExist(self.entities.board) then
			return true
		end
	end, 'Failed to create skateboard entities', 5000)

	self:setHandling()
	SetEntityNoCollisionEntity(self.entities.bycicle, cache.ped, false)
	SetEntityCollision(self.entities.bycicle, false, true)
	SetEntityVisible(self.entities.bycicle, false, false)

	AttachEntityToEntity(
		self.entities.board, self.entities.bycicle,
		GetPedBoneIndex(cache.ped, 28422),
		0.0, 0.0, -0.60, 0.0, 0.0, 90.0,
		false, true, true, true, 1, true
	)

	self.entities.ped = CreatePed(
		12, self.model.ped,
		spawnCoords.x, spawnCoords.y, spawnCoords.z,
		spawnHeading, true, true
	)

	SetEnableHandcuffs(self.entities.ped, true)
	SetEntityInvincible(self.entities.ped, true)
	SetEntityVisible(self.entities.ped, false, false)
	FreezeEntityPosition(self.entities.ped, true)
	TaskWarpPedIntoVehicle(self.entities.ped, self.entities.bycicle, -1)

	lib.waitFor(function ()
		return IsPedInVehicle(self.entities.ped, self.entities.bycicle, false)
	end, 'Failed to warp ped into vehicle', 5000)

	self.boardId = ObjToNet(self.entities.board)
	SetNetworkIdExistsOnAllMachines(self.boardId, true)
end

function Skating:clear()
	DetachEntity(self.entities.bycicle, true, true)

	for k, v in pairs(self.entities) do
		if DoesEntityExist(v) then
			DeleteEntity(v)
		end
	end

	self.fallStartZ = nil  -- reset titik mulai jatuh
	self.connected = false
	SetPedRagdollOnCollision(cache.ped, false)
end

function Skating:place()
	local bone = GetPedBoneIndex(cache.ped, 28422)

	AttachEntityToEntity(
		self.entities.bycicle, cache.ped, bone,
		-0.1, 0.0, -0.2, 70.0, 0.0, 270.0,
		true, true, false, false, 2, true
	)

	lib.playAnim(cache.ped, 'pickup_object', 'pickup_low', 8.0, -8.0, -1, 0, 0, false, false, false)
	Wait(800)

	PlaceObjectOnGroundProperly(self.entities.bycicle)
	DetachEntity(self.entities.bycicle, false, false)
end

function Skating:pickup()
	lib.playAnim(cache.ped, 'pickup_object', 'pickup_low', 8.0, -8.0, -1, 0, 0, false, false, false)

	Wait(600)
	local bone = GetPedBoneIndex(cache.ped, 28422)

	AttachEntityToEntity(
		self.entities.board, cache.ped, bone,
		-0.1, 0.0, -0.2, 70.0, 0.0, 270.0,
		true, true, false, false, 2, true
	)

	Wait(900)

	local success = lib.callback.await('skateboard:pickup')

	if not success then
		return
	end

	self:clear()
end

---@param toggle boolean
function Skating:connectPlayer(toggle)
	if toggle then
		lib.playAnim(cache.ped, 'move_strafe@stealth', 'idle', 8.0, 8.0, -1, 1, 1.0, false, false, false)

		AttachEntityToEntity(
			cache.ped, self.entities.bycicle, 20,
			0.0, 0.25, 0.0, 0.0, 0.0, -15.0,
			true, true, false, true, 1, true
		)

		SetEntityCollision(cache.ped, true, true)
	else
		DetachEntity(cache.ped, false, false)
		StopAnimTask(cache.ped, 'move_strafe@stealth', 'idle', 1.0)
		StopAnimTask(cache.ped, 'move_crouch_proto', 'idle_intro', 1.0)
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 3, 1)
	end

	self.connected = toggle
end

---@return boolean
function Skating:mustRagdoll()
    local rot = GetEntityRotation(self.entities.bycicle)
    local vel = GetEntityVelocity(self.entities.bycicle)
    local pos = GetEntityCoords(self.entities.bycicle)

    if IsEntityInAir(self.entities.bycicle) then
        if vel.z < -2.0 and not self.fallStartZ then
            self.fallStartZ = pos.z
        end
    else
        self.fallStartZ = nil
    end

    if self.fallStartZ and (self.fallStartZ - pos.z) > 4.0 then
        return true
    end

    if (rot.x < -60.0 or rot.x > 60.0) and IsEntityInAir(self.entities.bycicle) and self.speed < 5.0 then
        return true
    end

    if HasEntityCollidedWithAnything(cache.ped) and self.speed > 5.0 then
        return true
    end

    if IsPedDeadOrDying(cache.ped, false) then
        return true
    end

    return false
end

---@param distance number
function Skating:handleKeys(distance)

	local forward = IsControlPressed(0, 32)
	local backward = IsControlPressed(0, 33)
	local left = IsControlPressed(0, 34)
	local right = IsControlPressed(0, 35)

	if distance <= 1.5 and IsControlJustPressed(0, 38) then
		self:pickup()
		return
	end

	if distance <= 1.5 and IsControlJustReleased(0, 113) then
		if self.connected then
			self:connectPlayer(false)
		elseif not IsPedRagdoll(cache.ped) then
			Wait(200)
			self:connectPlayer(true)
		end
	end

	if distance >= config.loseConnectionDistance or not self.connected then return end

	local bmxSpeed = GetEntitySpeed(self.entities.bycicle) * 3.6
	local overSpeed = bmxSpeed > config.maxSpeed

	TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 1, 1)
	ForceVehicleEngineAudio(self.entities.bycicle, '')

	CreateThread(function()
		Wait(1)

		SetEntityInvincible(self.entities.bycicle, true)
		StopCurrentPlayingAmbientSpeech(self.entities.ped)

		if self.connected then
			self.speed = bmxSpeed

			if self:mustRagdoll() then
				local vel = GetEntityVelocity(self.entities.bycicle)
				local fallSpeed = math.abs(math.min(vel.z, 0.0))

				self:connectPlayer(false)
				SetPedToRagdoll(cache.ped, 5000, 4000, 0, true, true, false)

				if fallSpeed > 5.0 then
					CreateThread(function()
						local timeout = 3000
						while IsEntityInAir(cache.ped) and timeout > 0 do
							Wait(50)
							timeout = timeout - 50
						end

						Wait(100)

						local damage = math.floor(math.min(fallSpeed * 4.5, 200.0))
						ApplyDamageToPed(cache.ped, damage, true)
					end)
				end

				self.fallStartZ = nil
			end
		end
	end)

	if forward and not backward and not overSpeed then
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 9, 1)
	end

	if forward and left and not overSpeed then
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 7, 1)
	elseif forward and right and not overSpeed then
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 8, 1)
	end

	if backward and not forward and not overSpeed then
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 22, 1)
	end

	if backward and left and not overSpeed then
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 13, 1)
	elseif backward and right and not overSpeed then
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 14, 1)
	end

	if forward and backward and not overSpeed then
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 30, 100)
	end

	if left and not forward and not backward and not overSpeed then
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 4, 1)
	elseif right and not forward and not backward and not overSpeed then
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 5, 1)
	end

	if (IsControlJustReleased(0, 32) or IsControlJustReleased(0, 33)) and not overSpeed then
		TaskVehicleTempAction(self.entities.ped, self.entities.bycicle, 6, 2500)
	end

	if IsControlPressed(0, 22) and self.connected and not IsEntityInAir(self.entities.bycicle) then
		local vel = GetEntityVelocity(self.entities.bycicle)

		lib.playAnim(cache.ped, 'move_crouch_proto', 'idle_intro', 5.0, 8.0, -1, 0, 0, false, false, false)

		local duration = 0

		while IsControlPressed(0, 22) do
			Wait(10)
			duration = duration + 10.0
		end

		local boost = math.min(config.maxJump * duration / 250.0, config.maxJump)

		StopAnimTask(cache.ped, 'move_crouch_proto', 'idle_intro', 1.0)

		if self.connected then
			SetEntityVelocity(self.entities.bycicle, vel.x, vel.y, vel.z + boost)
			lib.playAnim(cache.ped, 'move_strafe@stealth', 'idle', 8.0, 2.0, -1, 1, 1.0, false, false, false)
		end
	end
end

local function startSkating()
	while activeSkate and DoesEntityExist(activeSkate.entities.bycicle) and DoesEntityExist(activeSkate.entities.ped) do
		Wait(5)

		if IsPedDeadOrDying(cache.ped, true) or (playerState and playerState.isdead) or LocalPlayer.state.isdead then
			local skate = activeSkate
			skate:connectPlayer(false)
			local success = lib.callback.await('skateboard:pickup', true)
			if success then
				skate:clear()
			end
			break
		end

		local pedCoords = GetEntityCoords(cache.ped)
		local distance = #(pedCoords - GetEntityCoords(activeSkate.entities.bycicle))

		activeSkate:handleKeys(distance)

		if distance <= config.loseConnectionDistance then
			requestNetworkControl(activeSkate.entities.ped, activeSkate.entities.bycicle)
		else
			TaskVehicleTempAction(activeSkate.entities.ped, activeSkate.entities.bycicle, 6, 2500)
		end
	end
	activeSkate = nil
end

lib.callback.register('skateboard:start', function(model)
	if activeSkate then
		activeSkate:clear()
		activeSkate = nil
	end

	Wait(100)

	---@diagnostic disable-next-line: undefined-field
	activeSkate = Skating:new(model)

	activeSkate:prepare()
	activeSkate:place()

	CreateThread(function()
		startSkating()
	end)

	return activeSkate.boardId
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	if not activeSkate then return end

	activeSkate:clear()
end)