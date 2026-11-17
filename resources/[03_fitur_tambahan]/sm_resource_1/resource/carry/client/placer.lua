local pedBones = localmodule 'data.ped_bone'

local POSITION_STEP = 0.01
local ROTATION_STEP = 0.5
local STEP_INCREMENT = 0.01
local ROTATION_INCREMENT = 0.1
local MARKER_SIZE = 0.15

local CONTROLS = {
	COPY = 38,
	FINISH = 194,
	UP = 172,
	DOWN = 173,
	LEFT = 174,
	RIGHT = 175,
	SHIFT = 21,
	FWD = 162,
	BACK = 163,
	SWAP_FLAG = 47,
	STEP_UP = 81,
	STEP_DOWN = 82,
	SWAP_SLOT = 37,
}

local CONTROL_INSTRUCTIONS = [[
Slot    : %s (TAB ganti slot)
X       : ← →
Y       : 8 / 9
Z       : ↑↓
RX      : Shift + ←→
RY      : Shift + 8 / 9
RZ      : Shift + ↑↓
Step    : %s ( . / , )
Flag    : G (carried=%s carrying=%s)
Finish  : Backspace
Copy    : E
]]

local TABLE_TEMPLATE = [[
%s = {
    personCarrying = {
        animDict = "%s",
        anim = "%s",
        flag = %d,
    },
%s}
]]

local CARRIED_TEMPLATE = [[    %s = {
        animDict = "%s",
        anim = "%s",%s
        attachX = %.3f,
        attachY = %.3f,
        attachZ = %.3f,
        rotX = %.2f,
        rotY = %.2f,
        rotZ = %.2f,
        fixedRot = true,
        flag = %d,
    },
]]

local ANIM_FLAGS = { 33, 49, 1, 0, 17, 32 }

local placer = {
	busy = false,
	dummy = nil,
	model = nil,
	boneId = 0,
	bonePromise = nil,
	boneActive = false,
	category = nil,
}

---@param controls table
local function disableAllControls(controls)
	for _, id in pairs(controls) do
		DisableControlAction(0, id, true)
	end
end

---@param step number
---@param increment number
---@param minValue number
---@param maxValue number
---@return number
local function adjustStep(step, increment, minValue, maxValue)
	local value = step + increment
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

---@param ped number
---@param dict string
---@param anim string
---@param flag number
local function playLoop(ped, dict, anim, flag)
	if not dict or dict == '' or not anim or anim == '' then return end
	if not lib.requestAnimDict(dict, 2000) then
		lib.notify({ description = ('animDict tidak valid: %s'):format(dict), type = 'error' })
		return
	end
	TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, flag, 0, false, false, false)
end

local function cleanupDummy()
	for i = 1, 2 do
		local dummy = placer.dummies and placer.dummies[i]

		if dummy and DoesEntityExist(dummy) then
			DetachEntity(dummy, true, false)
			DeleteEntity(dummy)
		end
	end

	placer.dummies = nil
	placer.dummy = nil

	if placer.model then
		SetModelAsNoLongerNeeded(placer.model)
		placer.model = nil
	end
end

function placer:openBoneCategoryMenu()
	local options = {}

	for category in pairs(pedBones) do
		options[#options + 1] = { label = category, args = { category = category } }
	end

	options[#options + 1] = { label = 'Input Bone ID Manual', args = { manual = true } }

	self.bonePromise = promise.new()
	self.boneActive = true

	CreateThread(function()
		while self.boneActive do
			if self.bonePreview then
				DrawMarker(
					28,
					self.bonePreview.x, self.bonePreview.y, self.bonePreview.z,
					0.0, 0.0, 0.0,
					0.0, 0.0, 0.0,
					MARKER_SIZE, MARKER_SIZE, MARKER_SIZE,
					255, 42, 24, 100,
					false, false, 0, true, false, false, false
				)
			end
			Wait(1)
		end

		self.bonePreview = nil
	end)

	lib.registerMenu({
		id = 'carry_bone_category',
		title = 'Pilih Kategori Bone',
		position = 'top-right',
		onClose = function()
			if self.boneActive then
				self.boneActive = false
				self.bonePromise:resolve(false)
			end
		end,
		options = options
	}, function(_, _, args)
		if args.manual then
			local input = lib.inputDialog('Bone ID', {
				{ type = 'number', label = 'Bone ID (contoh 24818)', required = true }
			})

			if not input or not input[1] then
				lib.showMenu('carry_bone_category')
				return
			end

			self.boneId = input[1]
			self.boneActive = false
			self.bonePromise:resolve(true)
			return
		end

		self.category = args.category
		self:openBoneListMenu()
	end)

	lib.showMenu('carry_bone_category')

	return Citizen.Await(self.bonePromise)
end

function placer:openBoneListMenu()
	local bones = pedBones[self.category]
	local options = {}

	for i = 1, #bones do
		options[#options + 1] = {
			label = bones[i].label,
			description = ('ID: %s'):format(bones[i].id),
			args = { id = bones[i].id }
		}
	end

	lib.registerMenu({
		id = 'carry_bone_list',
		title = self.category,
		position = 'top-right',
		onClose = function()
			self.bonePreview = nil
			lib.showMenu('carry_bone_category')
		end,
		onSelected = function(_, _, args)
			local boneIndex = GetPedBoneIndex(cache.ped, args.id)

			if boneIndex and boneIndex ~= -1 then
				self.bonePreview = GetWorldPositionOfEntityBone(cache.ped, boneIndex)
			end
		end,
		options = options
	}, function(_, _, args)
		self.boneId = args.id
		self.boneActive = false
		self.bonePromise:resolve(true)
	end)

	lib.showMenu('carry_bone_list')
end

---@param data table
function placer:start(data)
	local ped = cache.ped
	local coords = GetEntityCoords(ped)

	if not lib.requestModel(data.pedModel, 5000) then
		return lib.notify({ description = 'Model ped tidak tersedia', type = 'error' })
	end

	self.model = data.pedModel
	self.dummies = {}

	for i = 1, 2 do
		local dummy = CreatePed(4, data.pedModel, coords.x, coords.y, coords.z, GetEntityHeading(ped), false, false)

		SetEntityInvincible(dummy, true)
		SetBlockingOfNonTemporaryEvents(dummy, true)
		SetPedCanRagdoll(dummy, false)
		FreezeEntityPosition(dummy, false)
		SetEntityCollision(dummy, false, false)
		SetEntityVisible(dummy, i == 1, false)

		self.dummies[i] = dummy
	end

	self.dummy = self.dummies[1]

	local slot = 1
	local slotData = {
		[1] = {
			position = { x = data.attachX, y = data.attachY, z = data.attachZ },
			rotation = { x = data.rotX, y = data.rotY, z = data.rotZ },
			boneId = self.boneId
		},
		[2] = {
			position = { x = -data.attachX, y = data.attachY, z = data.attachZ },
			rotation = { x = data.rotX, y = data.rotY, z = -data.rotZ },
			boneId = self.boneId
		}
	}

	local position = slotData[1].position
	local rotation = slotData[1].rotation
	local carriedFlagIndex = 1
	local carryingFlagIndex = 2

	for i = 1, #ANIM_FLAGS do
		if ANIM_FLAGS[i] == data.carriedFlag then carriedFlagIndex = i end
		if ANIM_FLAGS[i] == data.carryingFlag then carryingFlagIndex = i end
	end

	self.positionStep = POSITION_STEP
	self.rotationStep = ROTATION_STEP
	self.busy = true

	local function refreshUI()
		if not self.busy then return end

		lib.showTextUI(
			CONTROL_INSTRUCTIONS:format(
				slot,
				('%.3f'):format(self.positionStep),
				ANIM_FLAGS[carriedFlagIndex],
				ANIM_FLAGS[carryingFlagIndex]
			),
			{ position = 'right-center' }
		)
	end

	local function switchSlot()
		slotData[slot].boneId = self.boneId

		slot = slot == 1 and 2 or 1

		position = slotData[slot].position
		rotation = slotData[slot].rotation
		self.boneId = slotData[slot].boneId
		self.dummy = self.dummies[slot]

		SetEntityVisible(self.dummies[2], true, false)

		refreshUI()
	end

	local function replayAnims()
		playLoop(ped, data.carryingDict, data.carryingAnim, ANIM_FLAGS[carryingFlagIndex])
		playLoop(self.dummy, data.carriedDict, data.carriedAnim, ANIM_FLAGS[carriedFlagIndex])
	end

	refreshUI()
	replayAnims()

	CreateThread(function()
		while self.busy do
			disableAllControls(CONTROLS)

			local shift = IsDisabledControlPressed(0, CONTROLS.SHIFT)

			if IsDisabledControlJustPressed(0, CONTROLS.STEP_UP) then
				self.positionStep = adjustStep(self.positionStep, STEP_INCREMENT, 0.001, 1.0)
				self.rotationStep = adjustStep(self.rotationStep, ROTATION_INCREMENT, 0.1, 10.0)
				refreshUI()
			elseif IsDisabledControlJustPressed(0, CONTROLS.STEP_DOWN) then
				self.positionStep = adjustStep(self.positionStep, -STEP_INCREMENT, 0.001, 1.0)
				self.rotationStep = adjustStep(self.rotationStep, -ROTATION_INCREMENT, 0.1, 10.0)
				refreshUI()
			end

			if not shift then
				local step = self.positionStep
				if IsDisabledControlPressed(0, CONTROLS.LEFT) then position.x = position.x - step end
				if IsDisabledControlPressed(0, CONTROLS.RIGHT) then position.x = position.x + step end
				if IsDisabledControlPressed(0, CONTROLS.UP) then position.z = position.z + step end
				if IsDisabledControlPressed(0, CONTROLS.DOWN) then position.z = position.z - step end
				if IsDisabledControlPressed(0, CONTROLS.FWD) then position.y = position.y + step end
				if IsDisabledControlPressed(0, CONTROLS.BACK) then position.y = position.y - step end
			else
				local step = self.rotationStep
				if IsDisabledControlPressed(0, CONTROLS.LEFT) then rotation.x = rotation.x + step end
				if IsDisabledControlPressed(0, CONTROLS.RIGHT) then rotation.x = rotation.x - step end
				if IsDisabledControlPressed(0, CONTROLS.UP) then rotation.z = rotation.z + step end
				if IsDisabledControlPressed(0, CONTROLS.DOWN) then rotation.z = rotation.z - step end
				if IsDisabledControlPressed(0, CONTROLS.FWD) then rotation.y = rotation.y + step end
				if IsDisabledControlPressed(0, CONTROLS.BACK) then rotation.y = rotation.y - step end
			end

			if IsDisabledControlJustPressed(0, CONTROLS.SWAP_SLOT) then
				switchSlot()
			end

			if IsDisabledControlJustPressed(0, CONTROLS.SWAP_FLAG) then
				if shift then
					carryingFlagIndex = carryingFlagIndex % #ANIM_FLAGS + 1
				else
					carriedFlagIndex = carriedFlagIndex % #ANIM_FLAGS + 1
				end
				refreshUI()
				replayAnims()
			end

			if DoesEntityExist(self.dummy) then
				AttachEntityToEntity(
					self.dummy, ped, GetPedBoneIndex(ped, self.boneId),
					position.x, position.y, position.z,
					rotation.x, rotation.y, rotation.z,
					false, false, false, true, 2, true
				)

				local other = slot == 1 and 2 or 1
				local otherDummy = self.dummies[other]

				if DoesEntityExist(otherDummy) and IsEntityVisible(otherDummy) then
					local otherData = slotData[other]

					AttachEntityToEntity(
						otherDummy, ped, GetPedBoneIndex(ped, otherData.boneId),
						otherData.position.x, otherData.position.y, otherData.position.z,
						otherData.rotation.x, otherData.rotation.y, otherData.rotation.z,
						false, false, false, true, 2, true
					)

					if not IsEntityPlayingAnim(otherDummy, data.carriedDict, data.carriedAnim, 3) then
						playLoop(otherDummy, data.carriedDict, data.carriedAnim, ANIM_FLAGS[carriedFlagIndex])
					end
				end

				if not IsEntityPlayingAnim(ped, data.carryingDict, data.carryingAnim, 3) then
					playLoop(ped, data.carryingDict, data.carryingAnim, ANIM_FLAGS[carryingFlagIndex])
				end

				if not IsEntityPlayingAnim(self.dummy, data.carriedDict, data.carriedAnim, 3) then
					playLoop(self.dummy, data.carriedDict, data.carriedAnim, ANIM_FLAGS[carriedFlagIndex])
				end
			end

			if IsDisabledControlJustPressed(0, CONTROLS.COPY) then
				slotData[slot].boneId = self.boneId

				local blocks = ''

				for i = 1, 2 do
					if i == 1 or IsEntityVisible(self.dummies[2]) then
						local entry = slotData[i]
						local boneLine = entry.boneId ~= 0 and ('\n            boneIndex = %d,'):format(entry.boneId) or ''

						blocks = blocks .. CARRIED_TEMPLATE:format(
							i == 1 and 'personCarried' or 'personCarried2',
							data.carriedDict, data.carriedAnim, boneLine,
							entry.position.x, entry.position.y, entry.position.z,
							entry.rotation.x, entry.rotation.y, entry.rotation.z,
							ANIM_FLAGS[carriedFlagIndex]
						)
					end
				end

				lib.setClipboard(TABLE_TEMPLATE:format(
					data.name,
					data.carryingDict, data.carryingAnim, ANIM_FLAGS[carryingFlagIndex],
					blocks
				))

				lib.notify({ description = 'Config carry disalin ke clipboard!', type = 'success' })
			end

			if IsDisabledControlJustPressed(0, CONTROLS.FINISH) then
				self.busy = false
				break
			end

			Wait(0)
		end

		ClearPedTasks(ped)
		cleanupDummy()
		lib.hideTextUI()
	end)
end

RegisterNetEvent('sm_carry:client:openPlacer', function()
	if placer.busy then
		return lib.notify({ description = 'Placer sedang aktif', type = 'error' })
	end

	local carryConfig = localmodule 'config.client'
	local presets = { 'Buat Baru (kosong)' }
	local presetNames = {}

	for name in pairs(carryConfig) do
		presets[#presets + 1] = name
		presetNames[#presetNames + 1] = name
	end

	local picked = lib.inputDialog('Carry Placer', {
		{ type = 'input', label = 'Nama Config', description = 'contoh: gendongbocil3', required = true },
		{ type = 'input', label = 'Model Ped', description = 'contoh: a_c_chimp atau ig_tracydisanto', required = true, default = 'a_f_y_topless_01' },
		{ type = 'select', label = 'Mulai Dari Preset', options = (function()
			local opts = {}
			for i = 1, #presets do opts[i] = { value = presets[i], label = presets[i] } end
			return opts
		end)(), default = presets[1] },
	})

	if not picked then return end

	local base = carryConfig[picked[3]]

	local data = {
		name = picked[1],
		pedModel = picked[2],
		carryingDict = base and base.personCarrying.animDict or 'missfinale_c2mcs_1',
		carryingAnim = base and base.personCarrying.anim or 'fin_c2_mcs_1_camman',
		carryingFlag = base and base.personCarrying.flag or 49,
		carriedDict = base and base.personCarried.animDict or 'nm',
		carriedAnim = base and base.personCarried.anim or 'firemans_carry',
		carriedFlag = base and base.personCarried.flag or 33,
		attachX = base and base.personCarried.attachX or 0.0,
		attachY = base and base.personCarried.attachY or 0.0,
		attachZ = base and base.personCarried.attachZ or 0.0,
		rotX = base and base.personCarried.rotX or 0.0,
		rotY = base and base.personCarried.rotY or 0.0,
		rotZ = base and base.personCarried.rotZ or 0.0,
	}

	local anims = lib.inputDialog('Animasi Carry', {
		{ type = 'input', label = 'Carrier animDict', required = true, default = data.carryingDict },
		{ type = 'input', label = 'Carrier anim', required = true, default = data.carryingAnim },
		{ type = 'input', label = 'Carried animDict', required = true, default = data.carriedDict },
		{ type = 'input', label = 'Carried anim', required = true, default = data.carriedAnim },
	})

	if not anims then return end

	data.carryingDict, data.carryingAnim = anims[1], anims[2]
	data.carriedDict, data.carriedAnim = anims[3], anims[4]

	placer.boneId = base and base.personCarried.boneIndex or 0

	if not placer:openBoneCategoryMenu() then return end

	placer:start(data)
end)

AddEventHandler('onResourceStop', function(resource)
	if resource ~= GetCurrentResourceName() then return end
	placer.busy = false
	cleanupDummy()
end)
