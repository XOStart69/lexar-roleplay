local wheelRot
local lastWheelAngle
local isSpinning = false
local cacheEntities = {}
local config = require 'casino.luckywheel.config'

---@class LW_Prize
---@field type string
---@field name string
---@field label string?
---@field count integer
---@field sound string
---@field chance number

local SCENE_OFFSETS <const> = {
    ['Enter_to_ArmRaisedIDLE'] = vector3(0.35699990391731, 1.5150065422058, 0.0),
    ['ArmRaisedIDLE'] = vector3(1.2720048427582, 0.62700039148331, 0.0),
    ['ArmRaisedIDLE_to_SpinReadyIDLE'] = vector3(1.296005, 0.621, 0.0),
    ['SpinReadyIDLE'] = vector3(1.281005, 0.63, 0.0),
    ['spinreadyidle_to_spinningidle_low'] = vector3(1.167004, 0.678001, 0.0),
    ['spinreadyidle_to_spinningidle_med'] = vector3(1.167004, 0.678001, 0.0),
    ['spinreadyidle_to_spinningidle_high'] = vector3(1.167004, 0.678001, 0.0),
    ['SpinningIDLE_Low'] = vector3(1.116004, 1.701008, 0.0),
    ['SpinningIDLE_Medium'] = vector3(1.116004, 1.701008, 0.0),
    ['SpinningIDLE_High'] = vector3(1.116004, 1.701008, 0.0),
    ['win'] = vector3(1.116004, 1.701008, 0.0),
    ['win_big'] = vector3(1.116004, 1.701008, 0.0),
    ['win_huge'] = vector3(1.116004, 1.701008, 0.0),
}
---@return string
local function getWheelDict()
    return IsPedMale(cache.ped)
        and 'anim_casino_a@amb@casino@games@lucky7wheel@male'
        or 'anim_casino_a@amb@casino@games@lucky7wheel@female'
end

---@param dict string anim dict yang sudah di-load
---@param animName string nama scene di SCENE_OFFSETS
---@param looped boolean|nil true untuk idle yang harus diulang (mempengaruhi holdLastFrame)
---@return integer? scene
local function playLuckyWheelScene(dict, animName, looped)
    if not DoesEntityExist(cacheEntities.baseEnt) then return end
    local offset = SCENE_OFFSETS[animName] or vector3(0.0, 0.0, 0.0)
    local baseCoords = GetEntityCoords(cacheEntities.baseEnt)
    local baseHeading = GetEntityHeading(cacheEntities.baseEnt)
    local baseRot = GetEntityRotation(cacheEntities.baseEnt)
    local targetPos = GetObjectOffsetFromCoords(
        baseCoords.x, baseCoords.y, baseCoords.z,
        baseHeading, offset.x, offset.y, -1.0
    )
    if animName == 'Enter_to_ArmRaisedIDLE' then
        baseRot = baseRot + vector3(0.0, 0.0, 44.498249)
    end
    local initPos = GetAnimInitialOffsetPosition(dict, animName, targetPos.x, targetPos.y, targetPos.z, baseRot.x, baseRot.y, baseRot.z, 0.0, 2)
    local initRot = GetAnimInitialOffsetRotation(dict, animName, targetPos.x, targetPos.y, targetPos.z, baseRot.x, baseRot.y, baseRot.z, 0.0, 2)
    local playerPos = GetEntityCoords(cache.ped)
    if #(playerPos - initPos) > 20.0 then
        initPos = baseCoords
    end
    local hold = looped and true or false
    local scene = NetworkCreateSynchronisedScene(
        initPos.x, initPos.y, initPos.z,
        initRot.x, initRot.y, initRot.z,
        0, false, hold, 1065353216, 0, 1065353216
    )
    NetworkAddPedToSynchronisedScene(cache.ped, scene, dict, animName, 2.0, -1.5, 13, 16, 1148846080, 0)
    NetworkStartSynchronisedScene(scene)
    return scene
end

---@param dict string
---@param animName string
---@param trim number?
local function waitSceneEnd(dict, animName, trim)
    local dur = GetAnimDuration(dict, animName) * 1000.0
    if trim then dur = dur - trim end
    if dur < 0 then dur = 0 end
    Wait(math.floor(dur))
end

local function playSpinAnim()
    if not DoesEntityExist(cacheEntities.baseEnt) then return end
    local dict = getWheelDict()
    if not lib.requestAnimDict(dict, 5000) then
        isSpinning = false
        return
    end
    local baseCoords = GetEntityCoords(cacheEntities.baseEnt)
    local baseHeading = GetEntityHeading(cacheEntities.baseEnt)
    local walkTo = GetObjectOffsetFromCoords(
        baseCoords.x, baseCoords.y, baseCoords.z,
        baseHeading, -1.386006, -1.083004, 0.0
    )
    TaskGoStraightToCoord(cache.ped, walkTo.x, walkTo.y, walkTo.z, 1.0, 3000, baseHeading, 0.0)
    local timeout = GetGameTimer() + 5000
    repeat
        Wait(50)
        local dist = #(GetEntityCoords(cache.ped) - walkTo)
        if GetGameTimer() > timeout then break end
    until dist < 1.5
    SetCurrentPedWeapon(cache.ped, `weapon_unarmed`, true)
    CreateThread(function()
        playLuckyWheelScene(dict, 'Enter_to_ArmRaisedIDLE')
        waitSceneEnd(dict, 'Enter_to_ArmRaisedIDLE', 250)
        playLuckyWheelScene(dict, 'ArmRaisedIDLE_to_SpinReadyIDLE')
        waitSceneEnd(dict, 'ArmRaisedIDLE_to_SpinReadyIDLE', 250)
        playLuckyWheelScene(dict, 'spinreadyidle_to_spinningidle_med')
        waitSceneEnd(dict, 'spinreadyidle_to_spinningidle_med', 250)
        playLuckyWheelScene(dict, 'SpinningIDLE_Medium', true)
        local watchdog = GetGameTimer() + 25000
        while isSpinning and GetGameTimer() < watchdog do
            Wait(250)
        end
        playLuckyWheelScene(dict, 'win')
        waitSceneEnd(dict, 'win', 250)
        ClearPedTasks(cache.ped)
        RemoveAnimDict(dict)
    end)
end

---@param soundName string
---@param entity integer
local function playSound(soundName, entity)
    local soundId = GetSoundId()
    PlaySoundFromEntity(soundId, soundName, entity, 'dlc_vw_casino_lucky_wheel_sounds', false, 10)
    ReleaseSoundId(soundId)
end

---Animates the wheel to land on the given prize index.
---@param prizeIndex integer
---@param prize LW_Prize
---@param checkReward boolean
---@param jitter number?
local function animateWheel(prizeIndex, prize, checkReward, jitter)
    if not DoesEntityExist(cacheEntities.wheelEnt) then return end
    local targetAngle = (prizeIndex - 1) * 18 + (config.WheelOffset or 0)
    playSound('Spin_Start', cacheEntities.wheelEnt)
    local j = 360.0
    for i = 1, 1100 do
        local step
        if i < 50 then step = 1.5
        elseif i < 100 then step = 2.0
        elseif i < 150 then step = 2.5
        elseif i > 1060 then step = 0.3
        elseif i > 1030 then step = 0.6
        elseif i > 1000 then step = 0.9
        elseif i > 970 then step = 1.2
        elseif i > 940 then step = 1.5
        elseif i > 910 then step = 1.8
        elseif i > 880 then step = 2.1
        elseif i > 850 then step = 2.4
        elseif i > 820 then step = 2.7
        else step = 3.0
        end
        j = j - step
        if i == 850 then
            local snapTarget = (targetAngle + 327.0) % 360
            j = snapTarget + (jitter or 0)
            if j < 0 then j = j + 360 end
            if j > 360 then j = j - 360 end
        end
        if j < 0 then j = j + 360 end
        if j > 360 then j = j - 360 end
        SetEntityRotation(cacheEntities.wheelEnt, wheelRot.x, j, wheelRot.z, 0, false)
        Wait(0)
    end
    Wait(300)
    local sound = (prize and prize.sound) or 'win'
    if sound == 'car' then playSound('Win_Car', cacheEntities.wheelEnt)
    elseif sound == 'cash' then playSound('Win_Cash', cacheEntities.wheelEnt)
    elseif sound == 'chips' then playSound('Win_Chips', cacheEntities.wheelEnt)
    elseif sound == 'clothes' then playSound('Win_Clothes', cacheEntities.wheelEnt)
    elseif sound == 'mystery' then playSound('Win_Mystery', cacheEntities.wheelEnt)
    else playSound('Win', cacheEntities.wheelEnt) end
    if checkReward and isSpinning then
        SetTimeout(500, function()
            lib.callback.await('rhd_casino_luckywheel:callback:claimPrize', false)
            isSpinning = false
        end)
    end
    Wait(1000)
end

CreateThread(function()
    lib.requestAudioBank('DLC_VINEWOOD\\CASINO_GENERAL')
    local mWheel = joaat('vw_prop_vw_luckywheel_02a')
    local mBase = joaat('vw_prop_vw_luckywheel_01a')
    lib.requestModel(mWheel)
    lib.requestModel(mBase)
    local pos = config.WheelPos
    ClearArea(pos.x, pos.y, pos.z, 5.0, true, false, false, false)
    cacheEntities.wheelEnt = CreateObject(mWheel, pos.x, pos.y, pos.z, false, false, true)
    SetEntityHeading(cacheEntities.wheelEnt, pos.w)
    FreezeEntityPosition(cacheEntities.wheelEnt, true)
    SetModelAsNoLongerNeeded(mWheel)
    cacheEntities.baseEnt = CreateObject(mBase, pos.x, pos.y, pos.z - 0.26, false, false, true)
    SetEntityHeading(cacheEntities.baseEnt, pos.w)
    FreezeEntityPosition(cacheEntities.baseEnt, true)
    SetModelAsNoLongerNeeded(mBase)
    wheelRot = GetEntityRotation(cacheEntities.wheelEnt)
end)

local points = lib.points.new(config.InteractPos.xyz, 2.0)
function points:onEnter()
    if not self.showTextui then
        infoUI:show({
            id = 'luckywheel_info',
            title = 'Lucky Wheel',
            icon = 'fa-solid fa-dharmachakra',
            description = [[
                [kbd]E[/kbd] Putar Lucky Wheel
            ]]
        })
        self.showTextui = true
    end
end

function points:onExit()
    if self.showTextui then
        infoUI:remove('luckywheel_info')
    end
    self.showTextui = false
end

function points:nearby()
    if isSpinning then return end
    if IsControlJustPressed(0, 38) then
        local info = lib.callback.await('rhd_casino_luckywheel:callback:canSpin', false)
        if not info then return end
        if lastWheelAngle and DoesEntityExist(cacheEntities.wheelEnt) and wheelRot then
            SetEntityRotation(cacheEntities.wheelEnt, wheelRot.x, lastWheelAngle, wheelRot.z, 0, false)
        end
        if not info.allowed then return end
        local content
        if info.freeSpin then
            content = '🎁 Kamu punya **free spin** hari ini!\nPutar roda sekarang?'
        else
            local hoursLeft = math.ceil(info.cooldownLeft / 3600)
            content = ('Spin seharga **$%s**.\n_(Free spin tersedia dalam %s jam lagi)_\n\nLanjutkan?')
                :format(info.spinPrice, hoursLeft)
        end
        local confirm = lib.alertDialog({
            header = 'Lucky Wheel',
            content = content,
            centered = true,
            cancel = true,
        })
        if confirm ~= 'confirm' then return end
        isSpinning = true
        local success = lib.callback.await('rhd_casino_luckywheel:callback:startSpin', false)
        if not success then
            isSpinning = false
        end
    end
end

RegisterNetEvent('rhd_casino_luckywheel:client:spinWheel', function(from, index, jitter)
    if source == '' then return end
    if from == cache.serverId then
        playSpinAnim()
    end
    Wait(3600)
    animateWheel(index, config.Prizes[index], from == cache.serverId, jitter)
end)

RegisterNetEvent('rhd_casino_luckywheel:client:syncAngle', function(angle)
    if source == '' then return end
    if not DoesEntityExist(cacheEntities.wheelEnt) or not wheelRot then return end
    lastWheelAngle = angle
    SetEntityRotation(cacheEntities.wheelEnt, wheelRot.x, lastWheelAngle, wheelRot.z, 0, false)
end)

useInteriorRoom(function(roomName)
    if not roomName then return end
    local createVeh = not cacheEntities.previewVehicle or not DoesEntityExist(cacheEntities.previewVehicle)
    if roomName == 'rm_GamingFloor_01' and createVeh then
        local coords = config.Vehicle.previewLoc
        lib.requestModel(config.Vehicle.model, 1500)
        cacheEntities.previewVehicle = CreateVehicle(
            config.Vehicle.model,
            coords.x, coords.y, coords.z, coords.w,
            false, false
        )
        FreezeEntityPosition(cacheEntities.previewVehicle, true)
        SetVehicleOnGroundProperly(cacheEntities.previewVehicle)
        SetVehicleEngineOn(cacheEntities.previewVehicle, false, true, false)
        SetVehicleDoorsLockedForAllPlayers(cacheEntities.previewVehicle, true)
        SetVehicleFixed(cacheEntities.previewVehicle)
        SetEntityCollision(cacheEntities.previewVehicle, false, false)
        local vehColor = config.Vehicle.color
        local paintType = vehColor?.type or 1
        if vehColor?.primary then
            local color = lib.math.tovector(vehColor.primary)
            SetVehicleCustomPrimaryColour(cacheEntities.previewVehicle, color.x, color.y, color.z)
            SetVehicleModColor_1(cacheEntities.previewVehicle, paintType, 0, 0)
        end
        if vehColor?.secondary then
            local color = lib.math.tovector(vehColor.secondary)
            SetVehicleCustomSecondaryColour(cacheEntities.previewVehicle, color.x, color.y, color.z)
            SetVehicleModColor_2(cacheEntities.previewVehicle, paintType, 0)
        end
        if config.Vehicle.rotation then
            local preview = cacheEntities.previewVehicle
            local podium = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, `vw_prop_vw_casino_podium_01a`, false, false, false)
            if DoesEntityExist(podium) then
                preview = podium
                AttachEntityToEntity(
                    cacheEntities.previewVehicle, preview, 0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 0, true)
            end
            CreateThread(function()
                local heading = GetEntityHeading(preview)
                while DoesEntityExist(preview) do
                    Wait(25)
                    heading = (heading + 0.5) % 360
                    SetEntityHeading(preview, heading)
                end
            end)
        end
    end
end)
AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        for _, v in pairs(cacheEntities) do
            pcall(DeleteEntity, v)
        end
    end
end)
